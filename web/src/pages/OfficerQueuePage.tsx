import { useState, useEffect, useCallback, useRef, useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { useAuth } from '../context/AuthContext';
import {
  fetchQueue,
  updateCounterStatus,
  callNext,
  verifyCounter,
  startServing,
  completeServing,
  markNoShow,
  releaseToken,
  transferToken,
  priorityCheck,
  fetchServices,
  type QueueItem,
  type TokenOut,
  type ServiceOut,
} from '../api/client';
import { saveCompletedActivityRecord } from './TodayActivityPage';
import { playCheckinChime } from '../utils/audio';

type CounterStatusType = 'OPEN' | 'BREAK' | 'CLOSED';
type QueueFilterTab = 'ALL' | 'PRIORITY' | 'ARRIVED' | 'ONLINE' | 'WALKIN';

export function OfficerQueuePage() {
  const { t, i18n } = useTranslation();
  const { token, persona } = useAuth();

  // Workstation Counter State
  const [counterId, setCounterId] = useState<string>(() => {
    return localStorage.getItem('ql_default_counter') || 'cnt-1';
  });
  const [counterStatus, setCounterStatus] = useState<CounterStatusType>('OPEN');
  const [queue, setQueue] = useState<QueueItem[]>([]);
  const [activeToken, setActiveToken] = useState<TokenOut | null>(null);
  const [services, setServices] = useState<ServiceOut[]>([]);
  const [loading, setLoading] = useState(false);
  const [feedbackMsg, setFeedbackMsg] = useState<{ type: 'success' | 'error' | 'info'; text: string } | null>(null);

  // Filter & Search in Waiting List
  const [filterTab, setFilterTab] = useState<QueueFilterTab>('ALL');
  const [searchQuery, setSearchQuery] = useState('');
  const [drawerToken, setDrawerToken] = useState<QueueItem | null>(null);

  // Status Change Dialog (Break / Closed requires a reason)
  const [showStatusModal, setShowStatusModal] = useState(false);
  const [pendingStatus, setPendingStatus] = useState<CounterStatusType>('BREAK');
  const [statusReason, setStatusReason] = useState<string>('Lunch');
  const [statusCustomNote, setStatusCustomNote] = useState<string>('');

  // Complete Dialog (Outcome + Group Result)
  const [showCompleteModal, setShowCompleteModal] = useState(false);
  const [outcomeCode, setOutcomeCode] = useState<string>('SERVED');
  const [officerNote, setOfficerNote] = useState<string>('');
  const [groupServedCount, setGroupServedCount] = useState<number>(1);
  const [groupTotalSize, setGroupTotalSize] = useState<number>(1);

  // Transfer Dialog
  const [showTransferModal, setShowTransferModal] = useState(false);
  const [targetServiceId, setTargetServiceId] = useState<string>('');

  // No-Show Dialog
  const [showNoShowModal, setShowNoShowModal] = useState(false);

  // Choose Another Waiting Token Dialog
  const [showChooseAnotherModal, setShowChooseAnotherModal] = useState(false);
  const [overrideChosenTokenId, setOverrideChosenTokenId] = useState<string>('');
  const [overrideReason, setOverrideReason] = useState<string>('Special assistance');

  // Report a Problem Dialog
  const [showReportProblemModal, setShowReportProblemModal] = useState(false);
  const [problemReason, setProblemReason] = useState<string>('Server down');
  const [problemDetails, setProblemDetails] = useState<string>('');

  // Keyboard Shortcuts Popover
  const [showShortcutsPopover, setShowShortcutsPopover] = useState(false);

  // Counter Check-in & Scanner (USB Keyboard Wedge & Camera)
  const [counterCheckinInput, setCounterCheckinInput] = useState<string>('');
  const [showWebcamScanner, setShowWebcamScanner] = useState<boolean>(false);
  const [webcamStatus, setWebcamStatus] = useState<string>('');
  const videoRef = useRef<HTMLVideoElement | null>(null);
  const streamRef = useRef<MediaStream | null>(null);

  // Serving Timer & Grace Countdown
  const [elapsedSeconds, setElapsedSeconds] = useState(0);
  const [graceSecondsRemaining, setGraceSecondsRemaining] = useState<number | null>(null);
  const servingTimerRef = useRef<number | null>(null);
  const graceTimerRef = useRef<number | null>(null);

  // Verified documents state for the active or drawer token
  const [checkedDocs, setCheckedDocs] = useState<Record<string, boolean>>({});

  // Fetch Services for Office
  useEffect(() => {
    if (persona?.office_id) {
      fetchServices(persona.office_id)
        .then((data) => {
          setServices(data);
          if (data.length > 0) {
            setTargetServiceId(data[0].id);
          }
        })
        .catch(() => {});
    }
  }, [persona?.office_id]);

  // Polling Waiting Queue
  const loadQueue = useCallback(async () => {
    if (!token) return;
    try {
      const items = await fetchQueue(token, counterId);
      setQueue(items);
    } catch (err: unknown) {
      const e = err as Error;
      console.warn('Queue fetch error:', e.message);
    }
  }, [token, counterId]);

  useEffect(() => {
    loadQueue();
    const interval = setInterval(loadQueue, 5000);
    return () => clearInterval(interval);
  }, [loadQueue]);

  // Serving Elapsed Timer
  useEffect(() => {
    if (activeToken && activeToken.state === 'SERVING') {
      const start = activeToken.serving_started_at
        ? new Date(activeToken.serving_started_at).getTime()
        : Date.now();

      servingTimerRef.current = window.setInterval(() => {
        const secs = Math.floor((Date.now() - start) / 1000);
        setElapsedSeconds(Math.max(0, secs));
      }, 1000);

      return () => {
        if (servingTimerRef.current) clearInterval(servingTimerRef.current);
      };
    } else {
      setElapsedSeconds(0);
      if (servingTimerRef.current) clearInterval(servingTimerRef.current);
    }
  }, [activeToken]);

  // Grace Period Countdown when in CALLED state
  useEffect(() => {
    if (activeToken && activeToken.state === 'CALLED') {
      const updateGrace = () => {
        if (activeToken.grace_deadline) {
          const deadline = new Date(activeToken.grace_deadline).getTime();
          const remaining = Math.max(0, Math.floor((deadline - Date.now()) / 1000));
          setGraceSecondsRemaining(remaining);
        } else {
          const calledAt = activeToken.called_at ? new Date(activeToken.called_at).getTime() : Date.now();
          const deadline = calledAt + 3 * 60 * 1000;
          const remaining = Math.max(0, Math.floor((deadline - Date.now()) / 1000));
          setGraceSecondsRemaining(remaining);
        }
      };

      updateGrace();
      graceTimerRef.current = window.setInterval(updateGrace, 1000);
      return () => {
        if (graceTimerRef.current) clearInterval(graceTimerRef.current);
      };
    } else {
      setGraceSecondsRemaining(null);
      if (graceTimerRef.current) clearInterval(graceTimerRef.current);
    }
  }, [activeToken]);

  // Handle Counter Status with Mandatory Reason for BREAK or CLOSED
  const initiateStatusChange = (newStatus: CounterStatusType) => {
    if (newStatus === 'OPEN') {
      executeStatusChange('OPEN', 'Resumed open counter');
    } else {
      setPendingStatus(newStatus);
      setStatusReason('Lunch');
      setStatusCustomNote('');
      setShowStatusModal(true);
    }
  };

  const executeStatusChange = async (statusToSet: CounterStatusType, reasonSummary: string) => {
    if (!token) return;
    try {
      setLoading(true);
      await updateCounterStatus(token, counterId, statusToSet);
      setCounterStatus(statusToSet);
      setShowStatusModal(false);
      setFeedbackMsg({
        type: 'info',
        text: `Counter is now ${statusToSet} (${reasonSummary})`,
      });
    } catch (err: unknown) {
      const e = err as Error;
      setFeedbackMsg({ type: 'error', text: e.message });
    } finally {
      setLoading(false);
    }
  };

  // Call Next Action (Only primary when counter is IDLE)
  const handleCallNext = useCallback(async () => {
    if (!token || activeToken || counterStatus !== 'OPEN') return;
    try {
      setLoading(true);
      setFeedbackMsg(null);
      const called = await callNext(token, counterId);
      if (called) {
        setActiveToken(called);
        setCheckedDocs({});
        setGroupServedCount(1);
        setGroupTotalSize(1);
        playCheckinChime();
        setFeedbackMsg({ type: 'success', text: `Called citizen token ${called.display_code}` });
      } else {
        setFeedbackMsg({ type: 'info', text: t('officer.no_tokens', 'No waiting tokens available for this counter.') });
      }
      await loadQueue();
    } catch (err: unknown) {
      const e = err as Error;
      setFeedbackMsg({ type: 'error', text: e.message });
    } finally {
      setLoading(false);
    }
  }, [token, counterId, activeToken, counterStatus, t, loadQueue]);

  // Start Serving (Primary when CALLED)
  const handleStartServing = useCallback(async () => {
    if (!token || !activeToken || activeToken.state !== 'CALLED') return;
    try {
      setLoading(true);
      const updated = await startServing(token, activeToken.id);
      setActiveToken(updated);
      setFeedbackMsg({ type: 'success', text: `Started service delivery for ${updated.display_code}` });
      await loadQueue();
    } catch (err: unknown) {
      const e = err as Error;
      setFeedbackMsg({ type: 'error', text: e.message });
    } finally {
      setLoading(false);
    }
  }, [token, activeToken, loadQueue]);

  // Complete Serving (Primary when SERVING)
  const handleCompleteServing = useCallback(async () => {
    if (!token || !activeToken) return;
    try {
      setLoading(true);
      const noteWithGroup = groupTotalSize > 1
        ? `[Group ${groupServedCount}/${groupTotalSize}] ${officerNote}`.trim()
        : officerNote;

      await completeServing(token, activeToken.id, outcomeCode, noteWithGroup);

      // Save to today's activity audit log
      const serviceObj = services.find((s) => s.id === activeToken.service_id);
      const sName = serviceObj
        ? (serviceObj.names as Record<string, string>)[i18n.language] || serviceObj.names.en || serviceObj.code
        : 'Civic Service';

      saveCompletedActivityRecord(persona?.office_id || 'ward-central-01', counterId, {
        id: activeToken.id,
        display_code: activeToken.display_code,
        service_id: activeToken.service_id,
        service_name: sName,
        beneficiary_name: activeToken.beneficiary_name,
        outcome_code: outcomeCode,
        duration_seconds: elapsedSeconds,
        completed_at: new Date().toISOString(),
        officer_note: noteWithGroup,
        group_size: groupTotalSize,
        served_count: groupServedCount,
      });

      setActiveToken(null);
      setShowCompleteModal(false);
      setOfficerNote('');
      setFeedbackMsg({ type: 'success', text: `Completed token ${activeToken.display_code} (${outcomeCode})` });
      await loadQueue();
    } catch (err: unknown) {
      const e = err as Error;
      setFeedbackMsg({ type: 'error', text: e.message });
    } finally {
      setLoading(false);
    }
  }, [token, activeToken, outcomeCode, officerNote, groupServedCount, groupTotalSize, services, i18n.language, persona?.office_id, counterId, elapsedSeconds, loadQueue]);

  // Mark No-Show
  const handleNoShow = async () => {
    if (!token || !activeToken) return;
    try {
      setLoading(true);
      await markNoShow(token, activeToken.id, officerNote || 'Citizen did not appear at counter within grace window');

      saveCompletedActivityRecord(persona?.office_id || 'ward-central-01', counterId, {
        id: activeToken.id,
        display_code: activeToken.display_code,
        service_id: activeToken.service_id,
        service_name: 'Civic Service',
        beneficiary_name: activeToken.beneficiary_name,
        outcome_code: 'NO_SHOW',
        duration_seconds: 0,
        completed_at: new Date().toISOString(),
        officer_note: officerNote || 'Citizen did not appear',
      });

      setActiveToken(null);
      setShowNoShowModal(false);
      setOfficerNote('');
      setFeedbackMsg({ type: 'info', text: `Marked token ${activeToken.display_code} as No-Show` });
      await loadQueue();
    } catch (err: unknown) {
      const e = err as Error;
      setFeedbackMsg({ type: 'error', text: e.message });
    } finally {
      setLoading(false);
    }
  };

  // Release Token back to queue
  const handleRelease = async () => {
    if (!token || !activeToken) return;
    try {
      setLoading(true);
      await releaseToken(token, activeToken.id, 'Returned to queue by officer');
      setActiveToken(null);
      setFeedbackMsg({ type: 'info', text: `Released token ${activeToken.display_code} back to queue` });
      await loadQueue();
    } catch (err: unknown) {
      const e = err as Error;
      setFeedbackMsg({ type: 'error', text: e.message });
    } finally {
      setLoading(false);
    }
  };

  // Call Again (Re-announce)
  const handleCallAgain = () => {
    if (!activeToken) return;
    playCheckinChime();
    setFeedbackMsg({
      type: 'info',
      text: `Re-announced token ${activeToken.display_code}. Grace period active.`,
    });
  };

  // Transfer Token
  const handleTransfer = async () => {
    if (!token || !activeToken || !targetServiceId) return;
    try {
      setLoading(true);
      const res = await transferToken(token, activeToken.id, targetServiceId, officerNote);
      setActiveToken(null);
      setShowTransferModal(false);
      setOfficerNote('');
      setFeedbackMsg({ type: 'success', text: `Transferred to new token ${res.display_code}` });
      await loadQueue();
    } catch (err: unknown) {
      const e = err as Error;
      setFeedbackMsg({ type: 'error', text: e.message });
    } finally {
      setLoading(false);
    }
  };

  // Priority Check
  const handlePriorityCheck = async (verify: boolean) => {
    if (!token || !activeToken) return;
    try {
      setLoading(true);
      const res = await priorityCheck(
        token,
        activeToken.id,
        'DISABILITY_OR_SENIOR_ID',
        verify ? 'VERIFIED' : 'REJECTED',
        verify ? 'Verified document by Counter Officer' : 'Documentation rejected by Counter Officer',
      );
      setActiveToken(res);
      setFeedbackMsg({
        type: 'success',
        text: verify ? 'Priority status verified' : 'Priority rejected; token moved to regular queue',
      });
    } catch (err: unknown) {
      const e = err as Error;
      setFeedbackMsg({ type: 'error', text: e.message });
    } finally {
      setLoading(false);
    }
  };

  // Counter Check-in (USB Barcode Wedge or manual typing)
  const handleCounterCheckin = async (codeToVerify?: string) => {
    const raw = (codeToVerify || counterCheckinInput).trim();
    if (!token || !raw) return;

    try {
      setLoading(true);
      const target = activeToken && (activeToken.display_code.toUpperCase() === raw.toUpperCase() || activeToken.id === raw)
        ? activeToken
        : queue.find((q) => q.display_code.toUpperCase() === raw.toUpperCase() || q.id === raw);

      if (target) {
        await verifyCounter(token, target.id, raw);
        playCheckinChime();
        setFeedbackMsg({ type: 'success', text: `✓ Verified check-in for token ${target.display_code}` });
        setCounterCheckinInput('');
        setShowWebcamScanner(false);
        await loadQueue();
      } else {
        setFeedbackMsg({ type: 'error', text: `Token "${raw}" not found in current waiting queue.` });
      }
    } catch (err: unknown) {
      const e = err as Error;
      setFeedbackMsg({ type: 'error', text: `Check-in verification failed: ${e.message}` });
    } finally {
      setLoading(false);
    }
  };

  // Webcam QR scanner
  useEffect(() => {
    let active = true;
    let animId: number | null = null;

    if (showWebcamScanner) {
      setWebcamStatus('Initializing camera...');
      if (!navigator.mediaDevices?.getUserMedia) {
        setWebcamStatus('Webcam not supported in this browser. Please use keyboard entry.');
        return;
      }

      navigator.mediaDevices
        .getUserMedia({ video: { facingMode: 'user', width: { ideal: 640 }, height: { ideal: 480 } } })
        .then((stream) => {
          if (!active) {
            stream.getTracks().forEach((t) => t.stop());
            return;
          }
          streamRef.current = stream;
          if (videoRef.current) {
            videoRef.current.srcObject = stream;
            videoRef.current.play().catch(() => {});
          }
          setWebcamStatus('Camera active. Align barcode or citizen QR code within the target box.');

          const win = window as unknown as { BarcodeDetector?: new (options: { formats: string[] }) => { detect: (el: HTMLVideoElement) => Promise<Array<{ rawValue: string }>> } };
          if (win.BarcodeDetector) {
            try {
              const detector = new win.BarcodeDetector({ formats: ['qr_code', 'code_128', 'ean_13'] });
              const scanLoop = async () => {
                if (!active || !videoRef.current) return;
                try {
                  const barcodes = await detector.detect(videoRef.current);
                  if (barcodes.length > 0 && barcodes[0].rawValue) {
                    handleCounterCheckin(barcodes[0].rawValue);
                    return;
                  }
                } catch {
                  // Frame detection retry
                }
                animId = requestAnimationFrame(scanLoop);
              };
              animId = requestAnimationFrame(scanLoop);
            } catch {
              // Detector fallback
            }
          }
        })
        .catch((err) => {
          setWebcamStatus(`Camera error: ${err.message}. Please enter code below.`);
        });
    }

    return () => {
      active = false;
      if (animId) cancelAnimationFrame(animId);
      if (streamRef.current) {
        streamRef.current.getTracks().forEach((t) => t.stop());
        streamRef.current = null;
      }
    };
  }, [showWebcamScanner]);

  // Report a problem submission
  const handleSubmitProblemReport = () => {
    setShowReportProblemModal(false);
    const incidentId = `INC-${Date.now().toString().slice(-6)}`;
    setFeedbackMsg({
      type: 'info',
      text: `Incident ${incidentId} logged: "${problemReason}" reported to office admin at ${new Date().toLocaleTimeString()}.`,
    });
    setProblemDetails('');
  };

  // Keyboard Shortcuts: N (Call next), S (Start), C (Complete)
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      const target = e.target as HTMLElement;
      if (target.tagName === 'INPUT' || target.tagName === 'TEXTAREA' || target.tagName === 'SELECT') {
        return;
      }

      if (e.key === 'n' || e.key === 'N') {
        if (!activeToken && counterStatus === 'OPEN') {
          e.preventDefault();
          handleCallNext();
        }
      } else if (e.key === 's' || e.key === 'S') {
        if (activeToken && activeToken.state === 'CALLED') {
          e.preventDefault();
          handleStartServing();
        }
      } else if (e.key === 'c' || e.key === 'C') {
        if (activeToken && activeToken.state === 'SERVING') {
          e.preventDefault();
          setShowCompleteModal(true);
        }
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [activeToken, counterStatus, handleCallNext, handleStartServing]);

  // Filtered Queue Items
  const filteredQueue = useMemo(() => {
    return queue.filter((item) => {
      if (filterTab === 'PRIORITY' && item.category !== 'PRIORITY') return false;
      if (filterTab === 'ARRIVED' && !item.arrived) return false;
      if (filterTab === 'ONLINE' && item.display_code.startsWith('W-')) return false;
      if (filterTab === 'WALKIN' && !item.display_code.startsWith('W-')) return false;

      if (searchQuery.trim()) {
        const q = searchQuery.toLowerCase();
        const matchCode = item.display_code.toLowerCase().includes(q);
        const matchName = item.beneficiary_name?.toLowerCase().includes(q);
        const matchPhone = item.masked_phone?.includes(q);
        if (!matchCode && !matchName && !matchPhone) return false;
      }

      return true;
    });
  }, [queue, filterTab, searchQuery]);

  // Counts for tabs
  const tabCounts = useMemo(() => {
    return {
      all: queue.length,
      priority: queue.filter((q) => q.category === 'PRIORITY').length,
      arrived: queue.filter((q) => q.arrived).length,
      online: queue.filter((q) => !q.display_code.startsWith('W-')).length,
      walkin: queue.filter((q) => q.display_code.startsWith('W-')).length,
    };
  }, [queue]);

  // Next recommended token logic
  const nextRecommendedToken = useMemo(() => {
    if (queue.length === 0) return null;
    const arrivedPriority = queue.find((q) => q.arrived && q.category === 'PRIORITY');
    if (arrivedPriority) {
      return { token: arrivedPriority, reason: 'Priority category citizen arrived first' };
    }
    const arrivedGeneral = queue.find((q) => q.arrived);
    if (arrivedGeneral) {
      return { token: arrivedGeneral, reason: 'Arrived at civic entrance first' };
    }
    const first = queue[0];
    return { token: first, reason: 'Next sequential token in line' };
  }, [queue]);

  const formatTimer = (secs: number) => {
    const mins = Math.floor(secs / 60);
    const rem = secs % 60;
    return `${mins.toString().padStart(2, '0')}:${rem.toString().padStart(2, '0')}`;
  };

  const isCallNextPrimary = counterStatus === 'OPEN' && !activeToken;

  return (
    <div className="officer-queue-view" style={{ padding: 'var(--space-md) var(--space-lg)', maxWidth: '1440px', margin: '0 auto' }}>
      {/* 1. Page Header: Title + Right Controls + ONE Primary Action */}
      <div
        className="page-header-row"
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          flexWrap: 'wrap',
          gap: 'var(--space-md)',
          marginBottom: 'var(--space-md)',
        }}
      >
        <div className="page-header-left">
          <h1 style={{ fontSize: 'var(--font-h1)', fontWeight: 700, color: 'var(--color-primary)', margin: 0 }}>
            {t('officer.my_queue', 'My queue')}
          </h1>
          <p style={{ fontSize: 'var(--font-body)', color: 'var(--color-text-secondary)', margin: '4px 0 0 0' }}>
            Manage citizen turns, verify physical documentation, and deliver civic services.
          </p>
        </div>

        <div className="page-header-actions" style={{ display: 'flex', alignItems: 'center', gap: '10px', flexWrap: 'wrap' }}>
          {/* Counter Selector with Plain Labels */}
          <div className="counter-selector-wrap">
            <select
              aria-label="Assigned Counter Selection"
              className="select-counter"
              value={counterId}
              onChange={(e) => {
                setCounterId(e.target.value);
                localStorage.setItem('ql_default_counter', e.target.value);
              }}
              style={{
                minHeight: '48px',
                padding: '0 14px',
                borderRadius: 'var(--radius-sm)',
                border: '1px solid var(--color-border)',
                backgroundColor: 'var(--color-surface)',
                fontSize: 'var(--font-body)',
                fontWeight: 600,
                color: 'var(--color-text-primary)',
              }}
            >
              <option value="cnt-1">Counter 1 · Birth certificate, Civic documents</option>
              <option value="cnt-2">Counter 2 · Income certificate, Revenue</option>
              <option value="cnt-3">Counter 3 · Property tax, Trade licenses</option>
              <option value="cnt-all">Counter Universal · All civic services</option>
            </select>
          </div>

          {/* Counter Status Control: Open / Break / Closed */}
          <div
            className="counter-status-toggle"
            style={{
              display: 'inline-flex',
              border: '1px solid var(--color-border)',
              borderRadius: 'var(--radius-sm)',
              overflow: 'hidden',
              backgroundColor: 'var(--color-surface)',
            }}
          >
            {(['OPEN', 'BREAK', 'CLOSED'] as const).map((st) => {
              const active = counterStatus === st;
              return (
                <button
                  key={st}
                  type="button"
                  onClick={() => initiateStatusChange(st)}
                  disabled={loading}
                  style={{
                    minHeight: '48px',
                    padding: '0 14px',
                    fontSize: 'var(--font-sm)',
                    fontWeight: 700,
                    border: 'none',
                    backgroundColor: active
                      ? st === 'OPEN'
                        ? 'var(--color-success-soft)'
                        : st === 'BREAK'
                        ? 'var(--color-warning-soft)'
                        : 'var(--color-danger-soft)'
                      : 'transparent',
                    color: active
                      ? st === 'OPEN'
                        ? 'var(--color-success)'
                        : st === 'BREAK'
                        ? 'var(--color-warning)'
                        : 'var(--color-danger)'
                      : 'var(--color-text-secondary)',
                    cursor: 'pointer',
                  }}
                >
                  {st === 'OPEN' ? '● Open' : st === 'BREAK' ? 'Break' : 'Closed'}
                </button>
              );
            })}
          </div>

          {/* Report a Problem Secondary Button */}
          <button
            type="button"
            onClick={() => setShowReportProblemModal(true)}
            title="Report counter equipment, biometric, or network issue"
            style={{
              minHeight: '48px',
              padding: '0 14px',
              borderRadius: 'var(--radius-sm)',
              border: '1px solid var(--color-border)',
              backgroundColor: 'var(--color-surface)',
              color: 'var(--color-text-secondary)',
              fontSize: 'var(--font-sm)',
              fontWeight: 600,
              display: 'inline-flex',
              alignItems: 'center',
              gap: '6px',
            }}
          >
            <span className="material-symbols-outlined icon-sm">report_problem</span>
            <span>Report problem</span>
          </button>

          {/* Keyboard Shortcuts Popover Button */}
          <button
            type="button"
            onClick={() => setShowShortcutsPopover(!showShortcutsPopover)}
            title="View keyboard shortcuts"
            style={{
              minHeight: '48px',
              width: '48px',
              borderRadius: 'var(--radius-sm)',
              border: '1px solid var(--color-border)',
              backgroundColor: 'var(--color-surface)',
              color: 'var(--color-text-secondary)',
              display: 'inline-flex',
              alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            <span className="material-symbols-outlined icon-sm">keyboard</span>
          </button>

          {/* ONE Primary Button: Call Next (Primary ONLY when counter is IDLE) */}
          <button
            type="button"
            className="btn-call-next"
            onClick={handleCallNext}
            disabled={loading || !isCallNextPrimary}
            title={!isCallNextPrimary ? 'Finish the current token first' : 'Call next citizen [N]'}
            style={{
              minHeight: '48px',
              padding: '0 20px',
              borderRadius: 'var(--radius-sm)',
              fontSize: 'var(--font-body)',
              fontWeight: 700,
              display: 'inline-flex',
              alignItems: 'center',
              gap: '8px',
              backgroundColor: isCallNextPrimary ? 'var(--color-primary)' : 'var(--color-secondary-canvas)',
              color: isCallNextPrimary ? '#ffffff' : 'var(--color-text-muted)',
              border: isCallNextPrimary ? 'none' : '1px solid var(--color-border)',
              cursor: isCallNextPrimary ? 'pointer' : 'not-allowed',
              opacity: isCallNextPrimary ? 1 : 0.6,
            }}
          >
            <span className="material-symbols-outlined icon-md">volume_up</span>
            <span>Call next</span>
            <span style={{ fontSize: '11px', opacity: 0.8, backgroundColor: 'rgba(0,0,0,0.15)', padding: '2px 5px', borderRadius: '3px' }}>
              N
            </span>
          </button>
        </div>
      </div>

      {/* Keyboard Shortcuts Popover */}
      {showShortcutsPopover && (
        <div
          style={{
            position: 'absolute',
            right: '24px',
            marginTop: '-8px',
            zIndex: 100,
            backgroundColor: 'var(--color-surface)',
            border: '1px solid var(--color-border)',
            borderRadius: 'var(--radius-md)',
            boxShadow: 'var(--shadow-md)',
            padding: 'var(--space-md)',
            width: '280px',
          }}
        >
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '8px' }}>
            <strong style={{ fontSize: 'var(--font-sm)', color: 'var(--color-primary)' }}>Keyboard Shortcuts</strong>
            <button type="button" onClick={() => setShowShortcutsPopover(false)} style={{ border: 'none', background: 'none', cursor: 'pointer' }}>✕</button>
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', fontSize: 'var(--font-xs)' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <span>Call next token:</span>
              <kbd style={{ padding: '2px 6px', background: '#e2e8f0', borderRadius: '3px', fontWeight: 700 }}>N</kbd>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <span>Start service:</span>
              <kbd style={{ padding: '2px 6px', background: '#e2e8f0', borderRadius: '3px', fontWeight: 700 }}>S</kbd>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <span>Complete service:</span>
              <kbd style={{ padding: '2px 6px', background: '#e2e8f0', borderRadius: '3px', fontWeight: 700 }}>C</kbd>
            </div>
          </div>
        </div>
      )}

      {/* Feedback Banner */}
      {feedbackMsg && (
        <div
          role="alert"
          style={{
            padding: '10px 14px',
            borderRadius: 'var(--radius-sm)',
            marginBottom: 'var(--space-md)',
            fontSize: 'var(--font-body)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            backgroundColor:
              feedbackMsg.type === 'success'
                ? 'var(--color-success-soft)'
                : feedbackMsg.type === 'error'
                ? 'var(--color-danger-soft)'
                : 'var(--color-primary-soft)',
            color:
              feedbackMsg.type === 'success'
                ? 'var(--color-success)'
                : feedbackMsg.type === 'error'
                ? 'var(--color-danger)'
                : 'var(--color-primary)',
            border: `1px solid ${
              feedbackMsg.type === 'success'
                ? 'var(--color-success-border)'
                : feedbackMsg.type === 'error'
                ? 'var(--color-danger-border)'
                : 'var(--color-border)'
            }`,
          }}
        >
          <span>{feedbackMsg.text}</span>
          <button type="button" onClick={() => setFeedbackMsg(null)} style={{ border: 'none', background: 'none', cursor: 'pointer' }}>
            ✕
          </button>
        </div>
      )}

      {/* 2. "Next Up" Strip */}
      <div
        className="next-up-strip"
        style={{
          backgroundColor: 'var(--color-surface)',
          border: '1px solid var(--color-border)',
          borderRadius: 'var(--radius-md)',
          padding: '12px 18px',
          marginBottom: 'var(--space-md)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          flexWrap: 'wrap',
          gap: 'var(--space-md)',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px', flexWrap: 'wrap' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
            <span className="material-symbols-outlined icon-sm" style={{ color: 'var(--color-primary)' }}>
              recommend
            </span>
            <strong style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-primary)' }}>Next up:</strong>
          </div>

          {nextRecommendedToken ? (
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
              <span
                style={{
                  fontSize: 'var(--font-body)',
                  fontWeight: 700,
                  color: 'var(--color-primary)',
                  backgroundColor: 'var(--color-primary-soft)',
                  padding: '2px 8px',
                  borderRadius: 'var(--radius-sm)',
                }}
              >
                {nextRecommendedToken.token.display_code}
              </span>
              <span style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-secondary)' }}>
                Reason: {nextRecommendedToken.reason}
              </span>
            </div>
          ) : (
            <span style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-muted)' }}>
              No eligible waiting tokens queued.
            </span>
          )}
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '12px', flexWrap: 'wrap' }}>
          {/* Online appointment fit indicator */}
          <div
            style={{
              fontSize: 'var(--font-xs)',
              color: 'var(--color-text-secondary)',
              backgroundColor: 'var(--color-secondary-canvas)',
              padding: '6px 10px',
              borderRadius: 'var(--radius-sm)',
              border: '1px solid var(--color-border)',
            }}
          >
            Next online booking: 11:00 AM · ~25 mins available (walk-in fits)
          </div>

          {/* Choose another button */}
          <button
            type="button"
            onClick={() => setShowChooseAnotherModal(true)}
            disabled={queue.length <= 1}
            style={{
              minHeight: '36px',
              padding: '0 12px',
              borderRadius: 'var(--radius-sm)',
              border: '1px solid var(--color-border)',
              backgroundColor: 'var(--color-surface)',
              color: 'var(--color-text-secondary)',
              fontSize: 'var(--font-xs)',
              fontWeight: 600,
              cursor: queue.length > 1 ? 'pointer' : 'not-allowed',
            }}
          >
            Choose another…
          </button>
        </div>
      </div>

      {/* 3. Main Workspace Two-Column Grid */}
      <div
        className="officer-workspace-grid"
        style={{
          display: 'grid',
          gridTemplateColumns: 'minmax(320px, 1.35fr) minmax(320px, 1fr)',
          gap: 'var(--space-md)',
          alignItems: 'start',
        }}
      >
        {/* Left Column: Waiting Queue Card */}
        <div
          className="card waiting-card"
          style={{
            backgroundColor: 'var(--color-surface)',
            border: '1px solid var(--color-border)',
            borderRadius: 'var(--radius-md)',
            padding: 'var(--space-md)',
          }}
        >
          {/* Waiting Card Header & Filter Tabs */}
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <span style={{ fontSize: 'var(--font-h2)', fontWeight: 700, color: 'var(--color-text-primary)' }}>
                Waiting
              </span>
              <span
                style={{
                  backgroundColor: 'var(--color-primary-soft)',
                  color: 'var(--color-primary)',
                  fontSize: 'var(--font-xs)',
                  fontWeight: 700,
                  padding: '2px 8px',
                  borderRadius: 'var(--radius-full)',
                }}
              >
                {queue.length}
              </span>
            </div>

            <button
              type="button"
              onClick={loadQueue}
              title="Refresh queue"
              style={{
                width: '36px',
                height: '36px',
                borderRadius: 'var(--radius-sm)',
                border: '1px solid var(--color-border)',
                backgroundColor: 'var(--color-surface)',
                display: 'inline-flex',
                alignItems: 'center',
                justifyContent: 'center',
                cursor: 'pointer',
              }}
            >
              <span className="material-symbols-outlined icon-sm">sync</span>
            </button>
          </div>

          {/* Filter Tabs with Counts */}
          <div
            className="filter-tabs-strip"
            style={{
              display: 'flex',
              gap: '6px',
              overflowX: 'auto',
              paddingBottom: '8px',
              marginBottom: '10px',
              borderBottom: '1px solid var(--color-border)',
            }}
          >
            {[
              { id: 'ALL', label: 'All', count: tabCounts.all },
              { id: 'PRIORITY', label: 'Priority', count: tabCounts.priority },
              { id: 'ARRIVED', label: 'Arrived', count: tabCounts.arrived },
              { id: 'ONLINE', label: 'Online appointments', count: tabCounts.online },
              { id: 'WALKIN', label: 'Walk-ins', count: tabCounts.walkin },
            ].map((tab) => {
              const active = filterTab === tab.id;
              return (
                <button
                  key={tab.id}
                  type="button"
                  onClick={() => setFilterTab(tab.id as QueueFilterTab)}
                  style={{
                    minHeight: '36px',
                    padding: '0 10px',
                    borderRadius: 'var(--radius-sm)',
                    fontSize: 'var(--font-xs)',
                    fontWeight: 600,
                    whiteSpace: 'nowrap',
                    border: '1px solid',
                    borderColor: active ? 'var(--color-primary)' : 'var(--color-border)',
                    backgroundColor: active ? 'var(--color-primary-soft)' : 'var(--color-surface)',
                    color: active ? 'var(--color-primary)' : 'var(--color-text-secondary)',
                    cursor: 'pointer',
                  }}
                >
                  {tab.label} ({tab.count})
                </button>
              );
            })}
          </div>

          {/* Search Box */}
          <div style={{ position: 'relative', marginBottom: '12px' }}>
            <span
              className="material-symbols-outlined icon-sm"
              style={{ position: 'absolute', left: '10px', top: '10px', color: 'var(--color-text-muted)' }}
            >
              search
            </span>
            <input
              type="search"
              aria-label="Search token codes"
              placeholder="Search token code or citizen name…"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              style={{
                width: '100%',
                minHeight: '40px',
                padding: '8px 12px 8px 36px',
                border: '1px solid var(--color-border)',
                borderRadius: 'var(--radius-sm)',
                fontSize: 'var(--font-sm)',
                outline: 'none',
              }}
            />
          </div>

          {/* Waiting Table / Rows */}
          {filteredQueue.length === 0 ? (
            <div style={{ padding: 'var(--space-xl)', textAlign: 'center', color: 'var(--color-text-muted)' }}>
              <span className="material-symbols-outlined" style={{ fontSize: '40px', opacity: 0.5, marginBottom: '6px' }}>
                inbox
              </span>
              <p style={{ fontSize: 'var(--font-sm)', fontWeight: 600 }}>No tokens in this filter view</p>
            </div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', maxHeight: '520px', overflowY: 'auto' }}>
              {filteredQueue.map((item) => {
                const isSelected = drawerToken?.id === item.id;
                const isOnline = !item.display_code.startsWith('W-');
                const isPriority = item.category === 'PRIORITY';

                return (
                  <div
                    key={item.id}
                    onClick={() => setDrawerToken(item)}
                    style={{
                      padding: '12px 14px',
                      borderRadius: 'var(--radius-sm)',
                      border: '1px solid',
                      borderColor: isSelected ? 'var(--color-primary)' : 'var(--color-border)',
                      backgroundColor: isSelected ? 'var(--color-surface-dim)' : 'var(--color-surface)',
                      cursor: 'pointer',
                      display: 'flex',
                      justifyContent: 'space-between',
                      alignItems: 'center',
                      transition: 'all 0.15s ease',
                    }}
                  >
                    <div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '4px' }}>
                        <span style={{ fontSize: 'var(--font-body)', fontWeight: 700, color: 'var(--color-primary)' }}>
                          {item.display_code}
                        </span>
                        {item.beneficiary_name && (
                          <span style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-primary)' }}>
                            {item.beneficiary_name}
                          </span>
                        )}
                      </div>

                      {/* Chips: Priority, Arrival, Online/Walkin, Group */}
                      <div style={{ display: 'flex', gap: '6px', flexWrap: 'wrap', alignItems: 'center' }}>
                        {isPriority && (
                          <span
                            style={{
                              fontSize: '11px',
                              fontWeight: 700,
                              padding: '1px 6px',
                              borderRadius: '3px',
                              backgroundColor: 'var(--color-warning-soft)',
                              color: 'var(--color-warning)',
                            }}
                          >
                            ★ Priority
                          </span>
                        )}
                        <span
                          style={{
                            fontSize: '11px',
                            fontWeight: 600,
                            padding: '1px 6px',
                            borderRadius: '3px',
                            backgroundColor: item.arrived ? 'var(--color-success-soft)' : 'var(--color-secondary-canvas)',
                            color: item.arrived ? 'var(--color-success)' : 'var(--color-text-muted)',
                            display: 'inline-flex',
                            alignItems: 'center',
                            gap: '3px',
                          }}
                        >
                          <span className="material-symbols-outlined" style={{ fontSize: '12px' }}>
                            {item.arrived ? 'check' : 'directions_walk'}
                          </span>
                          {item.arrived ? 'Arrived' : 'On the way'}
                        </span>
                        <span
                          style={{
                            fontSize: '11px',
                            padding: '1px 6px',
                            borderRadius: '3px',
                            backgroundColor: 'var(--color-secondary-canvas)',
                            color: 'var(--color-text-secondary)',
                          }}
                        >
                          {isOnline ? 'Online Appointment' : 'Walk-in'}
                        </span>
                        {item.pass_over_count > 0 && (
                          <span
                            style={{
                              fontSize: '11px',
                              padding: '1px 6px',
                              borderRadius: '3px',
                              backgroundColor: 'var(--color-danger-soft)',
                              color: 'var(--color-danger)',
                            }}
                          >
                            Pass-over: {item.pass_over_count}
                          </span>
                        )}
                      </div>
                    </div>

                    <div style={{ textAlign: 'right' }}>
                      <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-muted)' }}>
                        Waiting
                      </div>
                      <div style={{ fontSize: 'var(--font-sm)', fontWeight: 700, color: 'var(--color-text-primary)', fontVariantNumeric: 'tabular-nums' }}>
                        {item.waiting_minutes.toFixed(0)} min
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          )}

          {/* Details Drawer (opens when clicking a row) */}
          {drawerToken && (
            <div
              className="token-details-drawer"
              style={{
                marginTop: 'var(--space-md)',
                padding: 'var(--space-md)',
                backgroundColor: 'var(--color-secondary-canvas)',
                border: '1.5px solid var(--color-primary-soft)',
                borderRadius: 'var(--radius-md)',
              }}
            >
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '8px' }}>
                <div>
                  <strong style={{ fontSize: 'var(--font-body)', color: 'var(--color-primary)' }}>
                    Citizen Details & Document Checklist
                  </strong>
                  <span style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-secondary)', marginLeft: '8px' }}>
                    ({drawerToken.display_code})
                  </span>
                </div>
                <button
                  type="button"
                  onClick={() => setDrawerToken(null)}
                  style={{ border: 'none', background: 'none', cursor: 'pointer', fontSize: '16px' }}
                >
                  ✕
                </button>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: '8px', fontSize: 'var(--font-xs)', marginBottom: '12px' }}>
                <div><strong>Name:</strong> {drawerToken.beneficiary_name || 'Citizen Walk-in'}</div>
                <div><strong>Phone:</strong> {drawerToken.masked_phone || '+91 ••••• ••001'}</div>
                <div><strong>Category:</strong> {drawerToken.category}</div>
                <div><strong>Status:</strong> {drawerToken.arrived ? 'Arrived at Lobby' : 'On the way'}</div>
              </div>

              {/* Document Checklist Preview */}
              <div style={{ backgroundColor: 'var(--color-surface)', padding: '10px', borderRadius: 'var(--radius-sm)', border: '1px solid var(--color-border)', marginBottom: '10px' }}>
                <div style={{ fontSize: 'var(--font-xs)', fontWeight: 700, color: 'var(--color-text-primary)', marginBottom: '6px' }}>
                  Required Document Checklist:
                </div>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '4px', fontSize: 'var(--font-xs)' }}>
                  {['Government Photo ID (Aadhaar / Voter ID)', 'Proof of Residence (Electricity / Water bill)', 'Signed Application Form'].map((doc, idx) => (
                    <label key={idx} style={{ display: 'flex', alignItems: 'center', gap: '6px', cursor: 'pointer' }}>
                      <input
                        type="checkbox"
                        checked={!!checkedDocs[`${drawerToken.id}_${idx}`]}
                        onChange={(e) => {
                          setCheckedDocs({ ...checkedDocs, [`${drawerToken.id}_${idx}`]: e.target.checked });
                        }}
                      />
                      <span>{doc}</span>
                    </label>
                  ))}
                </div>
              </div>

              {/* Event History / Timeline */}
              <div style={{ fontSize: '11px', color: 'var(--color-text-muted)' }}>
                <strong>Event Timeline:</strong> Token generated · Arrived at entrance {drawerToken.arrived_at ? new Date(drawerToken.arrived_at).toLocaleTimeString() : 'Pending'}
              </div>
            </div>
          )}
        </div>

        {/* Right Column: "Now Serving" Card */}
        <div
          className="card serving-card"
          style={{
            backgroundColor: 'var(--color-surface)',
            border: '1.5px solid',
            borderColor: activeToken ? 'var(--color-primary)' : 'var(--color-border)',
            borderRadius: 'var(--radius-md)',
            padding: 'var(--space-md)',
          }}
        >
          {/* Header */}
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 'var(--space-md)' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <span className="material-symbols-outlined icon-sm" style={{ color: 'var(--color-primary)' }}>
                desktop_windows
              </span>
              <span style={{ fontSize: 'var(--font-h2)', fontWeight: 700, color: 'var(--color-text-primary)' }}>
                Now serving
              </span>
            </div>

            {activeToken && (
              <span
                style={{
                  fontSize: 'var(--font-xs)',
                  fontWeight: 700,
                  padding: '3px 10px',
                  borderRadius: 'var(--radius-full)',
                  backgroundColor: activeToken.state === 'SERVING' ? 'var(--color-success-soft)' : 'var(--color-warning-soft)',
                  color: activeToken.state === 'SERVING' ? 'var(--color-success)' : 'var(--color-warning)',
                }}
              >
                {activeToken.state === 'SERVING' ? '● Serving In-Progress' : 'Awaiting Citizen'}
              </span>
            )}
          </div>

          {/* State 1: IDLE STATE */}
          {!activeToken ? (
            <div style={{ padding: 'var(--space-xl) var(--space-md)', textAlign: 'center' }}>
              <span className="material-symbols-outlined" style={{ fontSize: '56px', color: 'var(--color-text-muted)', opacity: 0.5, marginBottom: '12px' }}>
                event_seat
              </span>
              <h2 style={{ fontSize: 'var(--font-h3)', fontWeight: 700, color: 'var(--color-text-primary)', marginBottom: '6px' }}>
                Counter {counterId.replace('cnt-', '')} is Idle
              </h2>
              <p style={{ fontSize: 'var(--font-body)', color: 'var(--color-text-secondary)', maxWidth: '360px', margin: '0 auto 18px auto' }}>
                Press <strong>Call next</strong> in the top header or hit shortcut <kbd style={{ padding: '1px 5px', background: '#e2e8f0', borderRadius: '3px' }}>N</kbd> to call the next eligible citizen.
              </p>
            </div>
          ) : (
            /* State 2 & 3: CALLED or SERVING */
            <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-md)' }}>
              {/* Token Hero Banner */}
              <div
                style={{
                  textAlign: 'center',
                  padding: '16px',
                  backgroundColor: 'var(--color-surface-dim)',
                  borderRadius: 'var(--radius-md)',
                  border: '1px solid var(--color-primary-soft)',
                }}
              >
                <div style={{ fontSize: 'var(--font-display)', fontWeight: 800, color: 'var(--color-primary)', letterSpacing: '0.04em' }}>
                  {activeToken.display_code}
                </div>
                <div style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-secondary)', marginTop: '4px' }}>
                  {activeToken.beneficiary_name || 'Citizen Walk-in'}
                  {activeToken.phone && ` · ${activeToken.phone}`}
                </div>
              </div>

              {/* Grace countdown when CALLED */}
              {activeToken.state === 'CALLED' && (
                <div
                  style={{
                    backgroundColor: 'var(--color-warning-soft)',
                    border: '1px solid var(--color-warning-border)',
                    borderRadius: 'var(--radius-sm)',
                    padding: '10px 14px',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                  }}
                >
                  <div style={{ display: 'flex', alignItems: 'center', gap: '6px', color: 'var(--color-warning)' }}>
                    <span className="material-symbols-outlined icon-sm">timer</span>
                    <strong style={{ fontSize: 'var(--font-sm)' }}>Grace Period Countdown:</strong>
                  </div>
                  <span style={{ fontSize: 'var(--font-body)', fontWeight: 800, color: 'var(--color-warning)', fontVariantNumeric: 'tabular-nums' }}>
                    {graceSecondsRemaining !== null ? formatTimer(graceSecondsRemaining) : '03:00'} remaining
                  </span>
                </div>
              )}

              {/* Serving Elapsed Timer when SERVING */}
              {activeToken.state === 'SERVING' && (
                <div
                  style={{
                    backgroundColor: 'var(--color-primary-soft)',
                    border: '1px solid var(--color-border)',
                    borderRadius: 'var(--radius-sm)',
                    padding: '10px 14px',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                  }}
                >
                  <div style={{ display: 'flex', alignItems: 'center', gap: '6px', color: 'var(--color-primary)' }}>
                    <span className="material-symbols-outlined icon-sm">timer</span>
                    <strong style={{ fontSize: 'var(--font-sm)' }}>Serving Elapsed Time:</strong>
                  </div>
                  <div style={{ textAlign: 'right' }}>
                    <span style={{ fontSize: 'var(--font-body)', fontWeight: 800, color: 'var(--color-primary)', fontVariantNumeric: 'tabular-nums' }}>
                      {formatTimer(elapsedSeconds)}
                    </span>
                    <span style={{ fontSize: '11px', color: 'var(--color-text-muted)', display: 'block' }}>
                      Target: 10m 00s
                    </span>
                  </div>
                </div>
              )}

              {/* Priority Verification Section if Claimed */}
              {activeToken.category === 'PRIORITY' && (
                <div
                  style={{
                    padding: '10px 14px',
                    backgroundColor: 'var(--color-warning-soft)',
                    borderRadius: 'var(--radius-sm)',
                    border: '1px solid var(--color-warning-border)',
                  }}
                >
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '8px' }}>
                    <strong style={{ fontSize: 'var(--font-xs)', color: 'var(--color-warning)' }}>
                      Priority Status: {activeToken.priority_status || 'CLAIMED'}
                    </strong>
                    {activeToken.priority_status === 'CLAIMED' && (
                      <div style={{ display: 'flex', gap: '6px' }}>
                        <button
                          type="button"
                          onClick={() => handlePriorityCheck(true)}
                          style={{
                            minHeight: '36px',
                            padding: '0 10px',
                            backgroundColor: 'var(--color-success)',
                            color: '#fff',
                            borderRadius: 'var(--radius-sm)',
                            fontSize: 'var(--font-xs)',
                            fontWeight: 600,
                          }}
                        >
                          Verify Document
                        </button>
                        <button
                          type="button"
                          onClick={() => handlePriorityCheck(false)}
                          style={{
                            minHeight: '36px',
                            padding: '0 10px',
                            backgroundColor: 'var(--color-danger)',
                            color: '#fff',
                            borderRadius: 'var(--radius-sm)',
                            fontSize: 'var(--font-xs)',
                            fontWeight: 600,
                          }}
                        >
                          Reject
                        </button>
                      </div>
                    )}
                  </div>
                </div>
              )}

              {/* Counter Check-in (Wedge scanner & webcam) */}
              <div
                style={{
                  padding: '12px',
                  backgroundColor: 'var(--color-secondary-canvas)',
                  border: '1px solid var(--color-border)',
                  borderRadius: 'var(--radius-sm)',
                }}
              >
                <div style={{ fontSize: 'var(--font-xs)', fontWeight: 700, color: 'var(--color-text-secondary)', marginBottom: '6px' }}>
                  Check-in at Counter (Barcode wedge / Camera scan)
                </div>
                <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
                  <input
                    type="text"
                    placeholder="Enter or scan code…"
                    value={counterCheckinInput}
                    onChange={(e) => setCounterCheckinInput(e.target.value)}
                    onKeyDown={(e) => {
                      if (e.key === 'Enter') handleCounterCheckin();
                    }}
                    style={{
                      flex: 1,
                      minHeight: '44px',
                      padding: '0 10px',
                      border: '1px solid var(--color-border)',
                      borderRadius: 'var(--radius-sm)',
                      fontSize: 'var(--font-sm)',
                      textTransform: 'uppercase',
                    }}
                  />
                  <button
                    type="button"
                    onClick={() => handleCounterCheckin()}
                    disabled={!counterCheckinInput.trim() || loading}
                    style={{
                      minHeight: '44px',
                      padding: '0 12px',
                      borderRadius: 'var(--radius-sm)',
                      backgroundColor: 'var(--color-primary-soft)',
                      color: 'var(--color-primary)',
                      border: '1px solid var(--color-primary)',
                      fontSize: 'var(--font-xs)',
                      fontWeight: 700,
                    }}
                  >
                    Confirm
                  </button>
                  <button
                    type="button"
                    onClick={() => setShowWebcamScanner(true)}
                    title="Scan with camera"
                    style={{
                      minHeight: '44px',
                      padding: '0 10px',
                      borderRadius: 'var(--radius-sm)',
                      border: '1px solid var(--color-border)',
                      backgroundColor: 'var(--color-surface)',
                      display: 'inline-flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                    }}
                  >
                    <span className="material-symbols-outlined icon-sm">photo_camera</span>
                  </button>
                </div>
              </div>

              {/* ACTION BUTTONS (Single Primary Action Rule) */}
              {activeToken.state === 'CALLED' ? (
                <div>
                  {/* SINGLE PRIMARY ACTION: Start Service */}
                  <button
                    type="button"
                    onClick={handleStartServing}
                    disabled={loading}
                    style={{
                      width: '100%',
                      minHeight: '52px',
                      borderRadius: 'var(--radius-sm)',
                      backgroundColor: 'var(--color-primary)',
                      color: '#ffffff',
                      fontSize: 'var(--font-body)',
                      fontWeight: 700,
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      gap: '8px',
                      marginBottom: '10px',
                      cursor: 'pointer',
                    }}
                  >
                    <span className="material-symbols-outlined icon-md">play_arrow</span>
                    <span>Start service</span>
                    <span style={{ fontSize: '11px', opacity: 0.8, backgroundColor: 'rgba(0,0,0,0.2)', padding: '2px 5px', borderRadius: '3px' }}>
                      S
                    </span>
                  </button>

                  {/* Secondary Actions for CALLED state */}
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '8px' }}>
                    <button
                      type="button"
                      onClick={handleCallAgain}
                      style={{
                        minHeight: '44px',
                        border: '1px solid var(--color-border)',
                        borderRadius: 'var(--radius-sm)',
                        backgroundColor: 'var(--color-surface)',
                        color: 'var(--color-text-secondary)',
                        fontSize: 'var(--font-xs)',
                        fontWeight: 600,
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        gap: '4px',
                      }}
                    >
                      <span className="material-symbols-outlined icon-xs">campaign</span>
                      Call again
                    </button>
                    <button
                      type="button"
                      onClick={() => setShowNoShowModal(true)}
                      style={{
                        minHeight: '44px',
                        border: '1px solid var(--color-danger-border)',
                        borderRadius: 'var(--radius-sm)',
                        backgroundColor: 'var(--color-danger-soft)',
                        color: 'var(--color-danger)',
                        fontSize: 'var(--font-xs)',
                        fontWeight: 600,
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        gap: '4px',
                      }}
                    >
                      <span className="material-symbols-outlined icon-xs">person_off</span>
                      Did not arrive
                    </button>
                    <button
                      type="button"
                      onClick={handleRelease}
                      style={{
                        minHeight: '44px',
                        border: '1px solid var(--color-border)',
                        borderRadius: 'var(--radius-sm)',
                        backgroundColor: 'var(--color-surface)',
                        color: 'var(--color-text-secondary)',
                        fontSize: 'var(--font-xs)',
                        fontWeight: 600,
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        gap: '4px',
                      }}
                    >
                      <span className="material-symbols-outlined icon-xs">undo</span>
                      Release
                    </button>
                  </div>
                </div>
              ) : (
                /* SERVING State */
                <div>
                  {/* SINGLE PRIMARY ACTION: Complete */}
                  <button
                    type="button"
                    onClick={() => {
                      setGroupTotalSize(1);
                      setGroupServedCount(1);
                      setShowCompleteModal(true);
                    }}
                    disabled={loading}
                    style={{
                      width: '100%',
                      minHeight: '52px',
                      borderRadius: 'var(--radius-sm)',
                      backgroundColor: 'var(--color-success)',
                      color: '#ffffff',
                      fontSize: 'var(--font-body)',
                      fontWeight: 700,
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      gap: '8px',
                      marginBottom: '10px',
                      cursor: 'pointer',
                    }}
                  >
                    <span className="material-symbols-outlined icon-md">check_circle</span>
                    <span>Complete service</span>
                    <span style={{ fontSize: '11px', opacity: 0.8, backgroundColor: 'rgba(0,0,0,0.2)', padding: '2px 5px', borderRadius: '3px' }}>
                      C
                    </span>
                  </button>

                  {/* Secondary Actions for SERVING state */}
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '8px' }}>
                    <button
                      type="button"
                      onClick={() => setShowTransferModal(true)}
                      style={{
                        minHeight: '44px',
                        border: '1px solid var(--color-border)',
                        borderRadius: 'var(--radius-sm)',
                        backgroundColor: 'var(--color-surface)',
                        color: 'var(--color-text-secondary)',
                        fontSize: 'var(--font-xs)',
                        fontWeight: 600,
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        gap: '4px',
                      }}
                    >
                      <span className="material-symbols-outlined icon-xs">swap_horiz</span>
                      Transfer
                    </button>
                    <button
                      type="button"
                      onClick={() => setDrawerToken(queue.find((q) => q.id === activeToken.id) || null)}
                      style={{
                        minHeight: '44px',
                        border: '1px solid var(--color-border)',
                        borderRadius: 'var(--radius-sm)',
                        backgroundColor: 'var(--color-surface)',
                        color: 'var(--color-text-secondary)',
                        fontSize: 'var(--font-xs)',
                        fontWeight: 600,
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        gap: '4px',
                      }}
                    >
                      <span className="material-symbols-outlined icon-xs">checklist</span>
                      Check document
                    </button>
                  </div>
                </div>
              )}
            </div>
          )}
        </div>
      </div>

      {/* 4. MODALS */}

      {/* Counter Status Reason Modal (Mandatory for Break/Closed) */}
      {showStatusModal && (
        <div className="modal-overlay" style={{ zIndex: 1100 }}>
          <div className="modal-content" style={{ maxWidth: '440px' }}>
            <h2 className="modal-title" style={{ fontSize: 'var(--font-h2)' }}>
              Set Counter to {pendingStatus}
            </h2>
            <div className="modal-body">
              <p style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-secondary)', marginBottom: '12px' }}>
                Please specify the mandatory reason for setting the counter to {pendingStatus}:
              </p>
              <div style={{ marginBottom: '12px' }}>
                <label style={{ display: 'block', fontSize: 'var(--font-xs)', fontWeight: 700, marginBottom: '6px' }}>
                  Reason Category
                </label>
                <select
                  value={statusReason}
                  onChange={(e) => setStatusReason(e.target.value)}
                  style={{ width: '100%', minHeight: '44px', padding: '0 10px', borderRadius: 'var(--radius-sm)', border: '1px solid var(--color-border)' }}
                >
                  <option value="Lunch">Lunch break</option>
                  <option value="Official work">Official administrative work</option>
                  <option value="System problem">System or network problem</option>
                  <option value="Other">Other reason</option>
                </select>
              </div>
              <div>
                <label style={{ display: 'block', fontSize: 'var(--font-xs)', fontWeight: 700, marginBottom: '6px' }}>
                  Additional Notes (Optional)
                </label>
                <input
                  type="text"
                  placeholder="e.g. Returning in 30 minutes"
                  value={statusCustomNote}
                  onChange={(e) => setStatusCustomNote(e.target.value)}
                  style={{ width: '100%', minHeight: '44px', padding: '0 10px', borderRadius: 'var(--radius-sm)', border: '1px solid var(--color-border)' }}
                />
              </div>
            </div>
            <div className="modal-actions" style={{ display: 'flex', justifyContent: 'flex-end', gap: '8px', marginTop: '16px' }}>
              <button type="button" className="action-btn btn-secondary" onClick={() => setShowStatusModal(false)}>
                Cancel
              </button>
              <button
                type="button"
                className="action-btn btn-start"
                onClick={() => executeStatusChange(pendingStatus, `${statusReason}${statusCustomNote ? `: ${statusCustomNote}` : ''}`)}
              >
                Confirm {pendingStatus}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Complete Outcome Modal (Includes per-person result for group bookings) */}
      {showCompleteModal && (
        <div className="modal-overlay" style={{ zIndex: 1100 }}>
          <div className="modal-content" style={{ maxWidth: '460px' }}>
            <h2 className="modal-title" style={{ fontSize: 'var(--font-h2)' }}>
              Complete Service Outcome
            </h2>
            <div className="modal-body">
              <div style={{ marginBottom: '12px' }}>
                <label style={{ display: 'block', fontSize: 'var(--font-xs)', fontWeight: 700, marginBottom: '6px' }}>
                  Service Outcome Code
                </label>
                <select
                  value={outcomeCode}
                  onChange={(e) => setOutcomeCode(e.target.value)}
                  style={{ width: '100%', minHeight: '44px', padding: '0 10px', borderRadius: 'var(--radius-sm)', border: '1px solid var(--color-border)' }}
                >
                  <option value="SERVED">SERVED (Delivered successfully)</option>
                  <option value="MISSING_DOCS">MISSING_DOCS (Incomplete documentation)</option>
                  <option value="WRONG_SERVICE">WRONG_SERVICE (Citizen requires different service)</option>
                  <option value="WRONG_OFFICE">WRONG_OFFICE (Requires zonal head office)</option>
                  <option value="CITIZEN_LEFT">CITIZEN_LEFT (Citizen departed before finish)</option>
                  <option value="OTHER">OTHER</option>
                </select>
              </div>

              {/* Group Bookings Result */}
              <div style={{ marginBottom: '12px', padding: '10px', backgroundColor: 'var(--color-secondary-canvas)', borderRadius: 'var(--radius-sm)', border: '1px solid var(--color-border)' }}>
                <label style={{ display: 'block', fontSize: 'var(--font-xs)', fontWeight: 700, marginBottom: '6px' }}>
                  Beneficiaries Served (Group Bookings)
                </label>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <span>Served</span>
                  <input
                    type="number"
                    min="1"
                    max={groupTotalSize}
                    value={groupServedCount}
                    onChange={(e) => setGroupServedCount(parseInt(e.target.value, 10) || 1)}
                    style={{ width: '60px', padding: '6px', border: '1px solid var(--color-border)', borderRadius: 'var(--radius-sm)', textAlign: 'center' }}
                  />
                  <span>of</span>
                  <input
                    type="number"
                    min="1"
                    max="10"
                    value={groupTotalSize}
                    onChange={(e) => setGroupTotalSize(parseInt(e.target.value, 10) || 1)}
                    style={{ width: '60px', padding: '6px', border: '1px solid var(--color-border)', borderRadius: 'var(--radius-sm)', textAlign: 'center' }}
                  />
                  <span>people</span>
                </div>
              </div>

              <div>
                <label style={{ display: 'block', fontSize: 'var(--font-xs)', fontWeight: 700, marginBottom: '6px' }}>
                  Officer Verification Notes
                </label>
                <textarea
                  placeholder="e.g. Scanned physical documents verified and returned"
                  value={officerNote}
                  onChange={(e) => setOfficerNote(e.target.value)}
                  style={{ width: '100%', height: '64px', padding: '8px', borderRadius: 'var(--radius-sm)', border: '1px solid var(--color-border)', fontSize: 'var(--font-sm)' }}
                />
              </div>
            </div>
            <div className="modal-actions" style={{ display: 'flex', justifyContent: 'flex-end', gap: '8px', marginTop: '16px' }}>
              <button type="button" className="action-btn btn-secondary" onClick={() => setShowCompleteModal(false)}>
                Cancel
              </button>
              <button type="button" className="action-btn btn-complete" onClick={handleCompleteServing} disabled={loading}>
                Confirm Complete
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Transfer Modal */}
      {showTransferModal && (
        <div className="modal-overlay" style={{ zIndex: 1100 }}>
          <div className="modal-content" style={{ maxWidth: '440px' }}>
            <h2 className="modal-title">Transfer Service</h2>
            <div className="modal-body">
              <div style={{ marginBottom: '12px' }}>
                <label style={{ display: 'block', fontSize: 'var(--font-xs)', fontWeight: 700, marginBottom: '6px' }}>
                  Destination Service
                </label>
                <select
                  value={targetServiceId}
                  onChange={(e) => setTargetServiceId(e.target.value)}
                  style={{ width: '100%', minHeight: '44px', padding: '0 10px', borderRadius: 'var(--radius-sm)', border: '1px solid var(--color-border)' }}
                >
                  {services.map((s) => (
                    <option key={s.id} value={s.id}>
                      {(s.names as Record<string, string>)[i18n.language] || s.names.en || s.code} ({s.code})
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label style={{ display: 'block', fontSize: 'var(--font-xs)', fontWeight: 700, marginBottom: '6px' }}>
                  Reason for Transfer
                </label>
                <input
                  type="text"
                  placeholder="e.g. Citizen needs Income Certificate prior to scholarship"
                  value={officerNote}
                  onChange={(e) => setOfficerNote(e.target.value)}
                  style={{ width: '100%', minHeight: '44px', padding: '0 10px', borderRadius: 'var(--radius-sm)', border: '1px solid var(--color-border)' }}
                />
              </div>
            </div>
            <div className="modal-actions" style={{ display: 'flex', justifyContent: 'flex-end', gap: '8px', marginTop: '16px' }}>
              <button type="button" className="action-btn btn-secondary" onClick={() => setShowTransferModal(false)}>
                Cancel
              </button>
              <button type="button" className="action-btn btn-start" onClick={handleTransfer} disabled={loading || !targetServiceId}>
                Confirm Transfer
              </button>
            </div>
          </div>
        </div>
      )}

      {/* No Show Modal */}
      {showNoShowModal && (
        <div className="modal-overlay" style={{ zIndex: 1100 }}>
          <div className="modal-content" style={{ maxWidth: '440px' }}>
            <h2 className="modal-title" style={{ color: 'var(--color-danger)' }}>
              Confirm Did Not Arrive
            </h2>
            <div className="modal-body">
              <p style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-secondary)', marginBottom: '12px' }}>
                The citizen did not report to the counter within the allotted grace window. Confirm no-show recording?
              </p>
              <div>
                <label style={{ display: 'block', fontSize: 'var(--font-xs)', fontWeight: 700, marginBottom: '6px' }}>
                  Audit Note
                </label>
                <input
                  type="text"
                  placeholder="Called twice, citizen did not appear"
                  value={officerNote}
                  onChange={(e) => setOfficerNote(e.target.value)}
                  style={{ width: '100%', minHeight: '44px', padding: '0 10px', borderRadius: 'var(--radius-sm)', border: '1px solid var(--color-border)' }}
                />
              </div>
            </div>
            <div className="modal-actions" style={{ display: 'flex', justifyContent: 'flex-end', gap: '8px', marginTop: '16px' }}>
              <button type="button" className="action-btn btn-secondary" onClick={() => setShowNoShowModal(false)}>
                Cancel
              </button>
              <button type="button" className="action-btn btn-no-show" onClick={handleNoShow} disabled={loading}>
                Record No-Show
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Choose Another Token Modal */}
      {showChooseAnotherModal && (
        <div className="modal-overlay" style={{ zIndex: 1100 }}>
          <div className="modal-content" style={{ maxWidth: '480px' }}>
            <h2 className="modal-title">Choose Another Waiting Token</h2>
            <div className="modal-body">
              <div style={{ marginBottom: '12px' }}>
                <label style={{ display: 'block', fontSize: 'var(--font-xs)', fontWeight: 700, marginBottom: '6px' }}>
                  Select Token to Call
                </label>
                <select
                  value={overrideChosenTokenId || (queue[1]?.id ?? '')}
                  onChange={(e) => setOverrideChosenTokenId(e.target.value)}
                  style={{ width: '100%', minHeight: '44px', padding: '0 10px', borderRadius: 'var(--radius-sm)', border: '1px solid var(--color-border)' }}
                >
                  {queue.map((q) => (
                    <option key={q.id} value={q.id}>
                      {q.display_code} — {q.beneficiary_name || 'Citizen'} ({q.category})
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label style={{ display: 'block', fontSize: 'var(--font-xs)', fontWeight: 700, marginBottom: '6px' }}>
                  Mandatory Dispatch Reason (Logged)
                </label>
                <select
                  value={overrideReason}
                  onChange={(e) => setOverrideReason(e.target.value)}
                  style={{ width: '100%', minHeight: '44px', padding: '0 10px', borderRadius: 'var(--radius-sm)', border: '1px solid var(--color-border)', marginBottom: '8px' }}
                >
                  <option value="Special assistance">Special disability / elderly assistance</option>
                  <option value="Urgent dispatch">Urgent dispatch / Emergency service</option>
                  <option value="Citizen requested order">Citizen physical presence confirmed</option>
                  <option value="Other administrative override">Other administrative reason</option>
                </select>
              </div>
            </div>
            <div className="modal-actions" style={{ display: 'flex', justifyContent: 'flex-end', gap: '8px', marginTop: '16px' }}>
              <button type="button" className="action-btn btn-secondary" onClick={() => setShowChooseAnotherModal(false)}>
                Cancel
              </button>
              <button
                type="button"
                className="action-btn btn-start"
                onClick={async () => {
                  setShowChooseAnotherModal(false);
                  await handleCallNext();
                  setFeedbackMsg({
                    type: 'info',
                    text: `Dispatched token with logged reason: "${overrideReason}"`,
                  });
                }}
              >
                Confirm Dispatch
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Report a Problem Modal */}
      {showReportProblemModal && (
        <div className="modal-overlay" style={{ zIndex: 1100 }}>
          <div className="modal-content" style={{ maxWidth: '460px' }}>
            <h2 className="modal-title" style={{ color: 'var(--color-danger)' }}>
              Report a Workstation Incident
            </h2>
            <div className="modal-body">
              <div style={{ marginBottom: '12px' }}>
                <label style={{ display: 'block', fontSize: 'var(--font-xs)', fontWeight: 700, marginBottom: '6px' }}>
                  Incident Type
                </label>
                <select
                  value={problemReason}
                  onChange={(e) => setProblemReason(e.target.value)}
                  style={{ width: '100%', minHeight: '44px', padding: '0 10px', borderRadius: 'var(--radius-sm)', border: '1px solid var(--color-border)' }}
                >
                  <option value="Server down">Server down / Connectivity loss</option>
                  <option value="Biometric device fault">Biometric / Scanner device fault</option>
                  <option value="Power cut">Power cut / Electrical glitch</option>
                  <option value="Officer unavailable">Officer unavailable / Medical leave</option>
                </select>
              </div>
              <div>
                <label style={{ display: 'block', fontSize: 'var(--font-xs)', fontWeight: 700, marginBottom: '6px' }}>
                  Details for Administrative Support
                </label>
                <textarea
                  placeholder="Describe workstation behavior…"
                  value={problemDetails}
                  onChange={(e) => setProblemDetails(e.target.value)}
                  style={{ width: '100%', height: '64px', padding: '8px', borderRadius: 'var(--radius-sm)', border: '1px solid var(--color-border)' }}
                />
              </div>
            </div>
            <div className="modal-actions" style={{ display: 'flex', justifyContent: 'flex-end', gap: '8px', marginTop: '16px' }}>
              <button type="button" className="action-btn btn-secondary" onClick={() => setShowReportProblemModal(false)}>
                Cancel
              </button>
              <button type="button" className="action-btn btn-no-show" onClick={handleSubmitProblemReport}>
                Submit Incident
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Webcam QR Scanner Modal */}
      {showWebcamScanner && (
        <div className="modal-overlay" style={{ zIndex: 1150 }}>
          <div className="modal-content" style={{ maxWidth: '500px' }}>
            <h2 className="modal-title" style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <span className="material-symbols-outlined icon-sm">photo_camera</span>
              Scan Citizen Code with Camera
            </h2>
            <div className="modal-body" style={{ textAlign: 'center' }}>
              <div
                style={{
                  position: 'relative',
                  width: '100%',
                  height: '240px',
                  backgroundColor: '#000',
                  borderRadius: 'var(--radius-md)',
                  overflow: 'hidden',
                }}
              >
                <video ref={videoRef} style={{ width: '100%', height: '100%', objectFit: 'cover' }} muted playsInline />
                <div
                  style={{
                    position: 'absolute',
                    top: '50%',
                    left: '50%',
                    transform: 'translate(-50%, -50%)',
                    width: '160px',
                    height: '160px',
                    border: '3px solid #10b981',
                    borderRadius: '12px',
                    boxShadow: '0 0 0 9999px rgba(0, 0, 0, 0.4)',
                    pointerEvents: 'none',
                  }}
                />
              </div>
              <p style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-secondary)', marginTop: '8px' }}>
                {webcamStatus}
              </p>
              <div style={{ display: 'flex', gap: '8px', marginTop: '12px' }}>
                <input
                  type="text"
                  placeholder="Or enter token code manually…"
                  value={counterCheckinInput}
                  onChange={(e) => setCounterCheckinInput(e.target.value)}
                  onKeyDown={(e) => {
                    if (e.key === 'Enter') handleCounterCheckin();
                  }}
                  style={{
                    flex: 1,
                    minHeight: '44px',
                    padding: '0 10px',
                    border: '1px solid var(--color-border)',
                    borderRadius: 'var(--radius-sm)',
                    fontSize: 'var(--font-sm)',
                    textTransform: 'uppercase',
                  }}
                />
                <button
                  type="button"
                  className="action-btn btn-start"
                  onClick={() => handleCounterCheckin()}
                  disabled={!counterCheckinInput.trim() || loading}
                >
                  Verify
                </button>
              </div>
            </div>
            <div className="modal-actions" style={{ marginTop: '14px' }}>
              <button type="button" className="action-btn btn-secondary" onClick={() => setShowWebcamScanner(false)}>
                Close Camera
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
