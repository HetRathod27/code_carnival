import { useState, useEffect, useCallback, useRef } from 'react';
import { useTranslation } from 'react-i18next';
import { useAuth } from '../context/AuthContext';
import {
  fetchQueue,
  updateCounterStatus,
  callNext,
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

export function OfficerQueuePage() {
  const { t } = useTranslation();
  const { token, persona } = useAuth();

  // State
  const [counterId, setCounterId] = useState<string>('cnt-1');
  const [counterStatus, setCounterStatus] = useState<'OPEN' | 'BREAK' | 'CLOSED'>('OPEN');
  const [queue, setQueue] = useState<QueueItem[]>([]);
  const [activeToken, setActiveToken] = useState<TokenOut | null>(null);
  const [selectedQueueItem, setSelectedQueueItem] = useState<QueueItem | null>(null);
  const [services, setServices] = useState<ServiceOut[]>([]);
  const [loading, setLoading] = useState(false);
  const [feedbackMsg, setFeedbackMsg] = useState<{ type: 'success' | 'error'; text: string } | null>(null);

  // Dialog Modals
  const [showCompleteModal, setShowCompleteModal] = useState(false);
  const [outcomeCode, setOutcomeCode] = useState<string>('SERVED');
  const [officerNote, setOfficerNote] = useState<string>('');

  const [showTransferModal, setShowTransferModal] = useState(false);
  const [targetServiceId, setTargetServiceId] = useState<string>('');

  const [showNoShowModal, setShowNoShowModal] = useState(false);

  // Serving Timer
  const [elapsedSeconds, setElapsedSeconds] = useState(0);
  const timerRef = useRef<number | null>(null);

  // Load available services for the office
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

  // Polling queue & counter status
  const loadQueue = useCallback(async () => {
    if (!token) return;
    try {
      const items = await fetchQueue(token, counterId);
      setQueue(items);
    } catch (err: unknown) {
      const e = err as Error;
      // If 404 counter not found or status issue
      console.warn('Queue fetch error:', e.message);
    }
  }, [token, counterId]);

  useEffect(() => {
    loadQueue();
    const interval = setInterval(loadQueue, 5000);
    return () => clearInterval(interval);
  }, [loadQueue]);

  // Handle elapsed timer when serving
  useEffect(() => {
    if (activeToken && activeToken.state === 'SERVING') {
      const start = activeToken.serving_started_at
        ? new Date(activeToken.serving_started_at).getTime()
        : Date.now();

      timerRef.current = window.setInterval(() => {
        const secs = Math.floor((Date.now() - start) / 1000);
        setElapsedSeconds(Math.max(0, secs));
      }, 1000);

      return () => {
        if (timerRef.current) clearInterval(timerRef.current);
      };
    } else {
      setElapsedSeconds(0);
      if (timerRef.current) clearInterval(timerRef.current);
    }
  }, [activeToken]);

  // Counter status handler
  const handleStatusChange = async (newStatus: 'OPEN' | 'BREAK' | 'CLOSED') => {
    if (!token) return;
    try {
      setLoading(true);
      await updateCounterStatus(token, counterId, newStatus);
      setCounterStatus(newStatus);
      setFeedbackMsg({ type: 'success', text: `Counter is now ${newStatus}` });
    } catch (err: unknown) {
      const e = err as Error;
      setFeedbackMsg({ type: 'error', text: e.message });
    } finally {
      setLoading(false);
    }
  };

  // Call Next Action
  const handleCallNext = async () => {
    if (!token) return;
    try {
      setLoading(true);
      setFeedbackMsg(null);
      const called = await callNext(token, counterId);
      if (called) {
        setActiveToken(called);
        setFeedbackMsg({ type: 'success', text: `Called ${called.display_code}` });
      } else {
        setFeedbackMsg({ type: 'error', text: t('officer.no_tokens') });
      }
      await loadQueue();
    } catch (err: unknown) {
      const e = err as Error;
      setFeedbackMsg({ type: 'error', text: e.message });
    } finally {
      setLoading(false);
    }
  };

  // Start Serving
  const handleStartServing = async () => {
    if (!token || !activeToken) return;
    try {
      setLoading(true);
      const updated = await startServing(token, activeToken.id);
      setActiveToken(updated);
      setFeedbackMsg({ type: 'success', text: `Started serving ${updated.display_code}` });
      await loadQueue();
    } catch (err: unknown) {
      const e = err as Error;
      setFeedbackMsg({ type: 'error', text: e.message });
    } finally {
      setLoading(false);
    }
  };

  // Complete Service
  const handleCompleteServing = async () => {
    if (!token || !activeToken) return;
    try {
      setLoading(true);
      await completeServing(token, activeToken.id, outcomeCode, officerNote);
      setActiveToken(null);
      setShowCompleteModal(false);
      setOfficerNote('');
      setFeedbackMsg({ type: 'success', text: t('officer.action_success') });
      await loadQueue();
    } catch (err: unknown) {
      const e = err as Error;
      setFeedbackMsg({ type: 'error', text: e.message });
    } finally {
      setLoading(false);
    }
  };

  // Mark No-Show
  const handleNoShow = async () => {
    if (!token || !activeToken) return;
    try {
      setLoading(true);
      await markNoShow(token, activeToken.id, officerNote);
      setActiveToken(null);
      setShowNoShowModal(false);
      setOfficerNote('');
      setFeedbackMsg({ type: 'success', text: `Marked ${activeToken.display_code} as No-Show` });
      await loadQueue();
    } catch (err: unknown) {
      const e = err as Error;
      setFeedbackMsg({ type: 'error', text: e.message });
    } finally {
      setLoading(false);
    }
  };

  // Release Token
  const handleRelease = async () => {
    if (!token || !activeToken) return;
    try {
      setLoading(true);
      await releaseToken(token, activeToken.id, 'Officer released token');
      setActiveToken(null);
      setFeedbackMsg({ type: 'success', text: `Released ${activeToken.display_code} back to queue` });
      await loadQueue();
    } catch (err: unknown) {
      const e = err as Error;
      setFeedbackMsg({ type: 'error', text: e.message });
    } finally {
      setLoading(false);
    }
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
        'DISABILITY_ID',
        verify ? 'VERIFIED' : 'REJECTED',
        verify ? 'Verified by Officer' : 'Documentation rejected',
      );
      setActiveToken(res);
      setFeedbackMsg({
        type: 'success',
        text: verify ? 'Priority verified' : 'Priority rejected',
      });
    } catch (err: unknown) {
      const e = err as Error;
      setFeedbackMsg({ type: 'error', text: e.message });
    } finally {
      setLoading(false);
    }
  };

  const formatTimer = (secs: number) => {
    const mins = Math.floor(secs / 60);
    const rem = secs % 60;
    return `${mins.toString().padStart(2, '0')}:${rem.toString().padStart(2, '0')}`;
  };

  return (
    <div className="officer-page">
      {/* Top Header Row with Counter Controls and Call Next */}
      <div className="page-header-row">
        <div className="page-header-left">
          <h1>{t('officer.queue_title')}</h1>
          <p>{t('officer.call_next_desc')}</p>
        </div>

        <div className="page-header-actions">
          {/* Counter Selector */}
          <div className="counter-selector-wrap">
            <select
              className="select-counter"
              value={counterId}
              onChange={(e) => setCounterId(e.target.value)}
            >
              <option value="cnt-1">Counter 1 (Certificates & Civic)</option>
              <option value="cnt-2">Counter 2 (Property Tax)</option>
              <option value="cnt-3">Counter 3 (Trade & RTI)</option>
            </select>
          </div>

          {/* Counter Status Toggle */}
          <div className="counter-status-toggle">
            {(['OPEN', 'BREAK', 'CLOSED'] as const).map((st) => (
              <button
                key={st}
                type="button"
                className={`status-btn ${st.toLowerCase()}${counterStatus === st ? ' active' : ''}`}
                onClick={() => handleStatusChange(st)}
                disabled={loading}
              >
                {st === 'OPEN' && '● '}
                {t(`officer.${st.toLowerCase()}`)}
              </button>
            ))}
          </div>

          {/* Call Next Button (Dominant Action) */}
          <button
            type="button"
            className="btn-call-next"
            onClick={handleCallNext}
            disabled={loading || counterStatus !== 'OPEN' || !!activeToken}
            title={activeToken ? 'Complete or release current token first' : 'Call next citizen'}
          >
            <span className="material-symbols-outlined icon-lg">volume_up</span>
            <span>{t('officer.call_next')}</span>
          </button>
        </div>
      </div>

      {/* Feedback Alert */}
      {feedbackMsg && (
        <div
          className={`login-error`}
          style={{
            backgroundColor: feedbackMsg.type === 'success' ? 'var(--color-success-soft)' : 'var(--color-danger-soft)',
            color: feedbackMsg.type === 'success' ? 'var(--color-success)' : 'var(--color-danger)',
            border: `1px solid ${feedbackMsg.type === 'success' ? 'var(--color-success-border)' : 'var(--color-danger-border)'}`,
          }}
        >
          {feedbackMsg.text}
        </div>
      )}

      {/* Workspace Grid */}
      <div className="officer-grid">
        {/* Left Column: Waiting Queue (Stitch Layout 60%) */}
        <div className="card">
          <div className="card-header">
            <div className="card-title-group">
              <span className="card-title">{t('officer.waiting')}</span>
              <span className="badge-count">{queue.length}</span>
            </div>
            <button
              type="button"
              className="btn-tertiary"
              onClick={loadQueue}
              title={t('officer.refresh')}
            >
              <span className="material-symbols-outlined icon-sm">sync</span>
            </button>
          </div>

          {queue.length === 0 ? (
            <div className="empty-state">
              <span className="material-symbols-outlined empty-icon">group</span>
              <p>{t('officer.no_tokens')}</p>
            </div>
          ) : (
            <table className="queue-table">
              <thead>
                <tr>
                  <th>{t('officer.token')}</th>
                  <th>{t('officer.category')}</th>
                  <th>{t('officer.arrived')}</th>
                  <th>Wait</th>
                </tr>
              </thead>
              <tbody>
                {queue.map((item) => (
                  <tr
                    key={item.id}
                    className={`queue-row${selectedQueueItem?.id === item.id ? ' selected' : ''}`}
                    onClick={() => setSelectedQueueItem(item)}
                  >
                    <td>
                      <div className="token-code">{item.display_code}</div>
                      <div style={{ fontSize: '13px', color: 'var(--color-text-secondary)' }}>
                        {item.beneficiary_name || item.masked_phone || `Seq #${item.seq}`}
                      </div>
                    </td>
                    <td>
                      <span
                        className={`token-category-badge ${item.category === 'PRIORITY' ? 'priority' : 'normal'}`}
                      >
                        {item.category === 'PRIORITY' ? '★ Priority' : 'Normal'}
                      </span>
                    </td>
                    <td>
                      <span
                        className={`arrival-badge ${item.arrived ? 'arrived' : 'on-the-way'}`}
                      >
                        {item.arrived ? (
                          <>
                            <span className="material-symbols-outlined" style={{ fontSize: '14px' }}>check</span>
                            {t('officer.arrived')}
                          </>
                        ) : (
                          <>
                            <span className="material-symbols-outlined" style={{ fontSize: '14px' }}>directions_walk</span>
                            {t('officer.on_the_way')}
                          </>
                        )}
                      </span>
                    </td>
                    <td style={{ fontVariantNumeric: 'tabular-nums', color: 'var(--color-text-muted)' }}>
                      {item.waiting_minutes.toFixed(0)} min
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}

          {/* Citizen Details Drawer Preview if a row is selected */}
          {selectedQueueItem && (
            <div style={{ marginTop: 'var(--space-md)', padding: 'var(--space-md)', backgroundColor: 'var(--color-secondary-canvas)', borderRadius: 'var(--radius-md)', border: '1px solid var(--color-border)' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 'var(--space-xs)' }}>
                <span style={{ fontWeight: 700, color: 'var(--color-primary)' }}>
                  {t('officer.citizen_details')}: {selectedQueueItem.display_code}
                </span>
                <button type="button" className="btn-tertiary" onClick={() => setSelectedQueueItem(null)}>✕</button>
              </div>
              <div style={{ fontSize: '13px', color: 'var(--color-text-secondary)' }}>
                {selectedQueueItem.beneficiary_name && <div><strong>Name:</strong> {selectedQueueItem.beneficiary_name}</div>}
                {selectedQueueItem.masked_phone && <div><strong>Phone:</strong> {selectedQueueItem.masked_phone}</div>}
                <div><strong>Pass-Over Count:</strong> {selectedQueueItem.pass_over_count}</div>
              </div>
            </div>
          )}
        </div>

        {/* Right Column: Active Now Serving Workspace */}
        <div className={`card ${activeToken ? 'card-serving' : ''}`}>
          <div className="card-header">
            <div className="card-title-group">
              <span className="material-symbols-outlined icon-sm" style={{ color: 'var(--color-primary)' }}>
                desktop_windows
              </span>
              <span className="card-title">{t('officer.now_serving')}</span>
            </div>
            {activeToken && (
              <span className={`token-hero-state ${activeToken.state === 'SERVING' ? 'serving' : 'called'}`}>
                <span className="material-symbols-outlined" style={{ fontSize: '14px' }}>
                  {activeToken.state === 'SERVING' ? 'radio_button_checked' : 'ring_volume'}
                </span>
                {activeToken.state === 'SERVING' ? t('officer.in_progress') : t('officer.awaiting_citizen')}
              </span>
            )}
          </div>

          {!activeToken ? (
            <div className="empty-state">
              <span className="material-symbols-outlined empty-icon">event_seat</span>
              <p>{t('officer.no_active_token')}</p>
              <button
                type="button"
                className="btn-call-next"
                style={{ marginTop: 'var(--space-sm)' }}
                onClick={handleCallNext}
                disabled={loading || counterStatus !== 'OPEN'}
              >
                <span className="material-symbols-outlined icon-sm">volume_up</span>
                <span>{t('officer.call_next')}</span>
              </button>
            </div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-md)' }}>
              {/* Token Hero */}
              <div className="serving-hero">
                <span className="token-hero-num">{activeToken.display_code}</span>
                <span style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-muted)' }}>
                  Seq #{activeToken.seq}
                </span>
              </div>

              {/* Citizen Information */}
              <div className="citizen-info-block">
                <span className="citizen-name">
                  {activeToken.beneficiary_name || 'Citizen Walk-in / App User'}
                </span>
                <div className="citizen-meta">
                  {activeToken.phone && (
                    <span>
                      <span className="material-symbols-outlined icon-sm">call</span>{' '}
                      {activeToken.phone}
                    </span>
                  )}
                  <span
                    className={`token-category-badge ${activeToken.category === 'PRIORITY' ? 'priority' : 'normal'}`}
                  >
                    {activeToken.category === 'PRIORITY' ? '★ Priority Citizen' : 'Standard Queue'}
                  </span>
                </div>
              </div>

              {/* Serving Timer Banner */}
              {activeToken.state === 'SERVING' ? (
                <div className="serving-timer-banner">
                  <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-xs)' }}>
                    <span className="material-symbols-outlined icon-sm">timer</span>
                    <span>{t('officer.serving_time')}: <strong>{formatTimer(elapsedSeconds)}</strong></span>
                  </div>
                  <span style={{ fontSize: '13px', opacity: 0.85 }}>{t('officer.target_time')}</span>
                </div>
              ) : (
                <div
                  style={{
                    backgroundColor: 'var(--color-warning-soft)',
                    border: '1px solid var(--color-warning-border)',
                    color: 'var(--color-warning)',
                    padding: 'var(--space-md)',
                    borderRadius: 'var(--radius-md)',
                    fontSize: '14px',
                    display: 'flex',
                    alignItems: 'center',
                    gap: 'var(--space-xs)',
                  }}
                >
                  <span className="material-symbols-outlined icon-sm">notifications_active</span>
                  <span>{t('officer.awaiting_citizen')}</span>
                </div>
              )}

              {/* Priority Check Action if Citizen is PRIORITY */}
              {activeToken.category === 'PRIORITY' && activeToken.priority_status === 'CLAIMED' && (
                <div style={{ padding: 'var(--space-sm)', backgroundColor: 'var(--color-warning-soft)', borderRadius: 'var(--radius-md)' }}>
                  <p style={{ fontSize: '13px', fontWeight: 600, marginBottom: '6px' }}>
                    {t('priority.verify_doc')}
                  </p>
                  <div style={{ display: 'flex', gap: 'var(--space-xs)' }}>
                    <button
                      type="button"
                      className="btn-complete"
                      style={{ height: '36px', fontSize: '13px', padding: '0 12px' }}
                      onClick={() => handlePriorityCheck(true)}
                    >
                      {t('priority.verified')}
                    </button>
                    <button
                      type="button"
                      className="btn-no-show"
                      style={{ height: '36px', fontSize: '13px', padding: '0 12px' }}
                      onClick={() => handlePriorityCheck(false)}
                    >
                      {t('priority.reject_priority')}
                    </button>
                  </div>
                </div>
              )}

              {/* Action Buttons depending on State */}
              {activeToken.state === 'CALLED' ? (
                <div className="action-grid">
                  <button
                    type="button"
                    className="action-btn btn-start"
                    onClick={handleStartServing}
                    disabled={loading}
                  >
                    <span className="material-symbols-outlined icon-sm">play_arrow</span>
                    <span>{t('officer.start_serving')}</span>
                  </button>
                  <button
                    type="button"
                    className="action-btn btn-no-show"
                    onClick={() => setShowNoShowModal(true)}
                    disabled={loading}
                  >
                    <span className="material-symbols-outlined icon-sm">person_off</span>
                    <span>{t('officer.no_show')}</span>
                  </button>
                </div>
              ) : (
                <div className="action-grid">
                  <button
                    type="button"
                    className="action-btn btn-complete"
                    onClick={() => setShowCompleteModal(true)}
                    disabled={loading}
                  >
                    <span className="material-symbols-outlined icon-sm">check_circle</span>
                    <span>{t('officer.complete')}</span>
                  </button>
                  <button
                    type="button"
                    className="action-btn btn-secondary"
                    onClick={() => setShowTransferModal(true)}
                    disabled={loading}
                  >
                    <span className="material-symbols-outlined icon-sm">swap_horiz</span>
                    <span>{t('officer.transfer')}</span>
                  </button>
                </div>
              )}

              {/* Release / Fallback action */}
              <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: 'var(--space-xs)' }}>
                <button
                  type="button"
                  className="btn-tertiary"
                  onClick={handleRelease}
                  disabled={loading}
                  title="Return token back to waiting queue"
                >
                  <span className="material-symbols-outlined icon-sm">undo</span>
                  <span>{t('officer.release')}</span>
                </button>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Complete Serving Dialog */}
      {showCompleteModal && (
        <div className="modal-overlay">
          <div className="modal-content">
            <h2 className="modal-title">{t('officer.confirm_complete')}</h2>
            <div className="modal-body">
              <div className="form-field">
                <label className="form-label">{t('officer.select_outcome')}</label>
                <select
                  className="form-select"
                  value={outcomeCode}
                  onChange={(e) => setOutcomeCode(e.target.value)}
                >
                  <option value="SERVED">{t('officer.served')}</option>
                  <option value="MISSING_DOCS">{t('officer.missing_docs')}</option>
                  <option value="WRONG_SERVICE">{t('officer.wrong_service')}</option>
                  <option value="WRONG_OFFICE">{t('officer.wrong_office')}</option>
                  <option value="CITIZEN_LEFT">{t('officer.citizen_left')}</option>
                  <option value="OTHER">{t('officer.other')}</option>
                </select>
              </div>
              <div className="form-field">
                <label className="form-label">{t('officer.optional_note')}</label>
                <textarea
                  className="form-input"
                  style={{ height: '72px', padding: '8px' }}
                  value={officerNote}
                  onChange={(e) => setOfficerNote(e.target.value)}
                  placeholder="e.g. Verified photocopies of Aadhaar and utility bill"
                />
              </div>
            </div>
            <div className="modal-actions">
              <button
                type="button"
                className="action-btn btn-secondary"
                onClick={() => setShowCompleteModal(false)}
              >
                Cancel
              </button>
              <button
                type="button"
                className="action-btn btn-complete"
                onClick={handleCompleteServing}
                disabled={loading}
              >
                {t('officer.complete')}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Transfer Service Dialog */}
      {showTransferModal && (
        <div className="modal-overlay">
          <div className="modal-content">
            <h2 className="modal-title">{t('officer.transfer_service')}</h2>
            <div className="modal-body">
              <div className="form-field">
                <label className="form-label">{t('officer.select_service')}</label>
                <select
                  className="form-select"
                  value={targetServiceId}
                  onChange={(e) => setTargetServiceId(e.target.value)}
                >
                  {services.map((s) => (
                    <option key={s.id} value={s.id}>
                      {s.names.en || s.code} ({s.code})
                    </option>
                  ))}
                </select>
              </div>
              <div className="form-field">
                <label className="form-label">{t('officer.optional_note')}</label>
                <textarea
                  className="form-input"
                  style={{ height: '72px', padding: '8px' }}
                  value={officerNote}
                  onChange={(e) => setOfficerNote(e.target.value)}
                  placeholder="Reason for transfer"
                />
              </div>
            </div>
            <div className="modal-actions">
              <button
                type="button"
                className="action-btn btn-secondary"
                onClick={() => setShowTransferModal(false)}
              >
                Cancel
              </button>
              <button
                type="button"
                className="action-btn btn-start"
                onClick={handleTransfer}
                disabled={loading || !targetServiceId}
              >
                {t('officer.transfer')}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* No Show Confirmation Dialog */}
      {showNoShowModal && (
        <div className="modal-overlay">
          <div className="modal-content">
            <h2 className="modal-title">{t('officer.no_show')}</h2>
            <div className="modal-body">
              <p>{t('officer.confirm_no_show')}</p>
              <div className="form-field">
                <label className="form-label">{t('officer.optional_note')}</label>
                <input
                  type="text"
                  className="form-input"
                  value={officerNote}
                  onChange={(e) => setOfficerNote(e.target.value)}
                  placeholder="Called twice, citizen did not appear"
                />
              </div>
            </div>
            <div className="modal-actions">
              <button
                type="button"
                className="action-btn btn-secondary"
                onClick={() => setShowNoShowModal(false)}
              >
                Cancel
              </button>
              <button
                type="button"
                className="action-btn btn-no-show"
                onClick={handleNoShow}
                disabled={loading}
              >
                {t('officer.no_show')}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
