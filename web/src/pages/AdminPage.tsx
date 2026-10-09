import { useState, useEffect, useCallback } from 'react';
import { useTranslation } from 'react-i18next';
import { useAuth } from '../context/AuthContext';
import type { NavTabId } from '../components/navConfig';
import { getHumanOfficeName } from '../utils/officeNames';
import {
  fetchOfficeSettings,
  updateOfficeSettings,
  fetchServices,
  fetchOfficeCounters,
  createAdminCounter,
  updateAdminCounter,
  deleteAdminCounter,
  pauseQueueBooking,
  resumeQueueBooking,
  generateEntranceQr,
  type OfficeSettingsOut,
  type ServiceOut,
  type CounterOut,
} from '../api/client';

export interface AdminPageProps {
  activeNav?: NavTabId;
  onNavChange?: (tab: NavTabId) => void;
}

type AdminTab = 'overview' | 'counters_services' | 'settings' | 'qr';

export function AdminPage({ activeNav, onNavChange }: AdminPageProps) {
  const { t, i18n } = useTranslation();
  const { persona, token } = useAuth();
  const officeId = persona?.office_id || 'ward-central-01';
  const humanOffice = getHumanOfficeName(officeId);

  // Sync activeTab with activeNav prop
  const getInitialTab = (): AdminTab => {
    if (activeNav === 'admin_counters') return 'counters_services';
    if (activeNav === 'admin_settings') return 'settings';
    return 'overview';
  };

  const [activeTab, setActiveTab] = useState<AdminTab>(getInitialTab);
  const [subTab, setSubTab] = useState<'counters' | 'services'>('counters');

  const [settingsData, setSettingsData] = useState<OfficeSettingsOut | null>(null);
  const [services, setServices] = useState<ServiceOut[]>([]);
  const [counters, setCounters] = useState<CounterOut[]>([]);
  const [qrCodeData, setQrCodeData] = useState<{ office_id: string; business_date: string; qr_payload: string } | null>(null);

  const [loading, setLoading] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  // Add counter modal state
  const [showAddCounterModal, setShowAddCounterModal] = useState<boolean>(false);
  const [newCounterId, setNewCounterId] = useState<string>('');
  const [newCounterLabel, setNewCounterLabel] = useState<string>('');

  // Pause service modal state
  const [pauseServiceId, setPauseServiceId] = useState<string | null>(null);
  const [pauseReason, setPauseReason] = useState<string>('Operational maintenance');

  // React to changes in activeNav from the sidebar
  useEffect(() => {
    if (activeNav === 'admin_counters') {
      setActiveTab('counters_services');
    } else if (activeNav === 'admin_settings') {
      setActiveTab('settings');
    } else if (activeNav === 'admin') {
      setActiveTab('overview');
    }
  }, [activeNav]);

  const handleTabSwitch = (tab: AdminTab) => {
    setActiveTab(tab);
    setError(null);
    setSuccess(null);
    if (tab === 'counters_services') {
      onNavChange?.('admin_counters');
    } else if (tab === 'settings' || tab === 'qr') {
      onNavChange?.('admin_settings');
    } else if (tab === 'overview') {
      onNavChange?.('admin');
    }
  };

  const loadData = useCallback(async () => {
    if (!token) return;
    setLoading(true);
    setError(null);
    try {
      const [sData, svcList, cntList] = await Promise.all([
        fetchOfficeSettings(token, officeId).catch(() => null),
        fetchServices(officeId).catch(() => []),
        fetchOfficeCounters(token, officeId).catch(() => []),
      ]);
      if (sData) setSettingsData(sData);
      setServices(svcList);
      setCounters(cntList);
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Failed to load admin data';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, [token, officeId]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  const handleSaveSettings = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!token || !settingsData) return;

    setLoading(true);
    setError(null);
    setSuccess(null);
    try {
      const updated = await updateOfficeSettings(token, officeId, settingsData);
      setSettingsData(updated);
      setSuccess(t('admin.saved_success', 'Office settings updated successfully'));
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Failed to update settings';
      setError(msg);
    } finally {
      setLoading(false);
    }
  };

  const handleCreateCounter = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!token || !newCounterId.trim() || !newCounterLabel.trim()) return;

    setLoading(true);
    setError(null);
    setSuccess(null);
    try {
      await createAdminCounter(token, {
        id: newCounterId.trim().toLowerCase(),
        office_id: officeId,
        label: newCounterLabel.trim(),
      });
      setSuccess(`Counter "${newCounterLabel.trim()}" created successfully`);
      setShowAddCounterModal(false);
      setNewCounterId('');
      setNewCounterLabel('');
      await loadData();
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Failed to create counter';
      setError(msg);
    } finally {
      setLoading(false);
    }
  };

  const handleUpdateCounterStatus = async (counterId: string, newStatus: 'OPEN' | 'BREAK' | 'CLOSED') => {
    if (!token) return;
    setLoading(true);
    setError(null);
    try {
      await updateAdminCounter(token, counterId, { status: newStatus });
      setSuccess(`Counter ${counterId} status updated to ${newStatus}`);
      await loadData();
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Failed to update counter status';
      setError(msg);
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteCounter = async (counterId: string, counterLabel: string) => {
    if (!token) return;
    if (!window.confirm(`Are you sure you want to delete ${counterLabel} (${counterId})?`)) return;

    setLoading(true);
    setError(null);
    try {
      await deleteAdminCounter(token, counterId);
      setSuccess(`Counter "${counterLabel}" deleted successfully`);
      await loadData();
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Failed to delete counter';
      setError(msg);
    } finally {
      setLoading(false);
    }
  };

  const handlePauseQueue = async () => {
    if (!token || !pauseServiceId || !pauseReason.trim()) return;

    setLoading(true);
    setError(null);
    try {
      await pauseQueueBooking(token, pauseServiceId, pauseReason.trim());
      setSuccess(`Booking paused for service ${pauseServiceId}`);
      setPauseServiceId(null);
      await loadData();
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Failed to pause booking';
      setError(msg);
    } finally {
      setLoading(false);
    }
  };

  const handleResumeQueue = async (serviceId: string) => {
    if (!token) return;

    setLoading(true);
    setError(null);
    try {
      await resumeQueueBooking(token, serviceId);
      setSuccess(`Booking resumed for service ${serviceId}`);
      await loadData();
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Failed to resume booking';
      setError(msg);
    } finally {
      setLoading(false);
    }
  };

  const handleGenerateQr = async () => {
    if (!token) return;
    setLoading(true);
    try {
      const qr = await generateEntranceQr(token, officeId);
      setQrCodeData(qr);
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Failed to generate QR';
      setError(msg);
    } finally {
      setLoading(false);
    }
  };

  const openCountersCount = counters.filter((c) => c.status === 'OPEN').length;
  const breakCountersCount = counters.filter((c) => c.status === 'BREAK').length;
  const closedCountersCount = counters.filter((c) => c.status === 'CLOSED').length;

  return (
    <div className="officer-page">
      {/* Header */}
      <div className="page-header-row">
        <div className="page-header-left">
          <h1>{t('admin.title', 'Office & System Administration')}</h1>
          <p>{t('admin.subtitle', 'Configure center parameters, services, counters, and daily QR access')}</p>
        </div>

        <div className="page-header-actions">
          <div className="counter-status-toggle">
            <button
              type="button"
              className={`status-btn${activeTab === 'overview' ? ' open active' : ''}`}
              onClick={() => handleTabSwitch('overview')}
            >
              <span className="material-symbols-outlined icon-sm">dashboard</span>{' '}
              {t('nav.overview', 'Overview')}
            </button>
            <button
              type="button"
              className={`status-btn${activeTab === 'counters_services' ? ' open active' : ''}`}
              onClick={() => handleTabSwitch('counters_services')}
            >
              <span className="material-symbols-outlined icon-sm">meeting_room</span>{' '}
              {t('nav.counters_services', 'Counters and services')}
            </button>
            <button
              type="button"
              className={`status-btn${activeTab === 'settings' ? ' open active' : ''}`}
              onClick={() => handleTabSwitch('settings')}
            >
              <span className="material-symbols-outlined icon-sm">settings</span>{' '}
              {t('admin.tab_settings', 'Office Settings')}
            </button>
            <button
              type="button"
              className={`status-btn${activeTab === 'qr' ? ' open active' : ''}`}
              onClick={() => {
                handleTabSwitch('qr');
                if (!qrCodeData) handleGenerateQr();
              }}
            >
              <span className="material-symbols-outlined icon-sm">qr_code</span>{' '}
              {t('admin.tab_qr', 'Entrance QR Code')}
            </button>
          </div>
        </div>
      </div>

      {error && <div className="login-error" style={{ marginBottom: 'var(--space-md)' }}>{error}</div>}
      {success && (
        <div
          style={{
            padding: 'var(--space-md)',
            backgroundColor: 'var(--color-success-soft)',
            color: 'var(--color-success)',
            borderRadius: 'var(--radius-md)',
            marginBottom: 'var(--space-md)',
            fontWeight: 500,
          }}
        >
          {success}
        </div>
      )}

      {/* ─────────────────────────────────────────────────────────────
          TAB 1: OVERVIEW DASHBOARD
         ───────────────────────────────────────────────────────────── */}
      {activeTab === 'overview' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-lg)' }}>
          {/* Facility Identity Banner */}
          <div className="card" style={{ padding: 'var(--space-lg)', borderLeft: '4px solid var(--color-primary)' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 'var(--space-md)' }}>
              <div>
                <div style={{ fontSize: 'var(--font-xs)', textTransform: 'uppercase', letterSpacing: '0.05em', color: 'var(--color-text-muted)' }}>
                  Active Civic Facility
                </div>
                <h2 style={{ margin: '4px 0 2px 0', fontSize: '20px', color: 'var(--color-text-primary)' }}>
                  {humanOffice}
                </h2>
                <div style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-secondary)' }}>
                  Office ID: <code>{officeId}</code>
                </div>
              </div>
              <div style={{ display: 'flex', gap: 'var(--space-sm)' }}>
                <button
                  type="button"
                  className="action-btn btn-start"
                  style={{ width: 'auto', padding: '0 16px' }}
                  onClick={() => handleTabSwitch('counters_services')}
                >
                  <span className="material-symbols-outlined icon-sm">meeting_room</span>
                  Manage Counters & Services
                </button>
                <button
                  type="button"
                  className="action-btn btn-secondary"
                  style={{ width: 'auto', padding: '0 16px' }}
                  onClick={() => handleTabSwitch('settings')}
                >
                  <span className="material-symbols-outlined icon-sm">tune</span>
                  Configure Settings
                </button>
              </div>
            </div>
          </div>

          {/* KPI Summary Cards Grid */}
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(260px, 1fr))', gap: 'var(--space-md)' }}>
            {/* Card 1: Counters Summary */}
            <div className="card">
              <div className="card-header">
                <div className="card-title-group">
                  <span className="material-symbols-outlined" style={{ color: 'var(--color-primary)' }}>
                    meeting_room
                  </span>
                  <span className="card-title">Counters</span>
                </div>
                <span className="badge-count">{counters.length} Total</span>
              </div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', padding: '8px 0' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 'var(--font-sm)' }}>
                  <span>Open Counters:</span>
                  <strong style={{ color: 'var(--color-success)' }}>{openCountersCount}</strong>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 'var(--font-sm)' }}>
                  <span>On Break:</span>
                  <strong style={{ color: 'var(--color-warning)' }}>{breakCountersCount}</strong>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 'var(--font-sm)' }}>
                  <span>Closed:</span>
                  <strong style={{ color: 'var(--color-text-muted)' }}>{closedCountersCount}</strong>
                </div>
              </div>
              <button
                type="button"
                className="action-btn btn-secondary"
                style={{ marginTop: 'auto', width: '100%' }}
                onClick={() => {
                  setSubTab('counters');
                  handleTabSwitch('counters_services');
                }}
              >
                View Counter Roster
              </button>
            </div>

            {/* Card 2: Services Summary */}
            <div className="card">
              <div className="card-header">
                <div className="card-title-group">
                  <span className="material-symbols-outlined" style={{ color: 'var(--color-primary)' }}>
                    apps
                  </span>
                  <span className="card-title">Services</span>
                </div>
                <span className="badge-count">{services.length} Total</span>
              </div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', padding: '8px 0' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 'var(--font-sm)' }}>
                  <span>Configured Services:</span>
                  <strong>{services.length}</strong>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 'var(--font-sm)' }}>
                  <span>Mandatory Visit:</span>
                  <strong>{services.filter((s) => s.requires_physical_visit).length}</strong>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 'var(--font-sm)' }}>
                  <span>Online Alternative:</span>
                  <strong>{services.filter((s) => !s.requires_physical_visit).length}</strong>
                </div>
              </div>
              <button
                type="button"
                className="action-btn btn-secondary"
                style={{ marginTop: 'auto', width: '100%' }}
                onClick={() => {
                  setSubTab('services');
                  handleTabSwitch('counters_services');
                }}
              >
                Manage Services & Pausing
              </button>
            </div>

            {/* Card 3: Settings Parameters */}
            <div className="card">
              <div className="card-header">
                <div className="card-title-group">
                  <span className="material-symbols-outlined" style={{ color: 'var(--color-primary)' }}>
                    tune
                  </span>
                  <span className="card-title">Queue Rules</span>
                </div>
              </div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', padding: '8px 0' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 'var(--font-sm)' }}>
                  <span>Grace Window:</span>
                  <strong>{settingsData?.grace_minutes ?? 5} min</strong>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 'var(--font-sm)' }}>
                  <span>Priority Frequency:</span>
                  <strong>Every {settingsData?.priority_every_n ?? 3}th</strong>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 'var(--font-sm)' }}>
                  <span>Max Tokens/Phone:</span>
                  <strong>{settingsData?.max_active_tokens_per_phone ?? 1}</strong>
                </div>
              </div>
              <button
                type="button"
                className="action-btn btn-secondary"
                style={{ marginTop: 'auto', width: '100%' }}
                onClick={() => handleTabSwitch('settings')}
              >
                Modify Parameters
              </button>
            </div>

            {/* Card 4: Daily QR Code */}
            <div className="card">
              <div className="card-header">
                <div className="card-title-group">
                  <span className="material-symbols-outlined" style={{ color: 'var(--color-primary)' }}>
                    qr_code_2
                  </span>
                  <span className="card-title">Daily Check-In</span>
                </div>
              </div>
              <p style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-secondary)', margin: '8px 0' }}>
                Secure cryptographic entrance code for citizen arrival verification.
              </p>
              <button
                type="button"
                className="action-btn btn-start"
                style={{ marginTop: 'auto', width: '100%' }}
                onClick={() => {
                  handleTabSwitch('qr');
                  if (!qrCodeData) handleGenerateQr();
                }}
              >
                <span className="material-symbols-outlined icon-sm">qr_code</span>
                Generate & Print QR
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ─────────────────────────────────────────────────────────────
          TAB 2: COUNTERS & SERVICES
         ───────────────────────────────────────────────────────────── */}
      {activeTab === 'counters_services' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-md)' }}>
          {/* Sub-navigation pill toggle between Counters and Services */}
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 'var(--space-md)' }}>
            <div className="counter-status-toggle">
              <button
                type="button"
                className={`status-btn${subTab === 'counters' ? ' open active' : ''}`}
                onClick={() => setSubTab('counters')}
              >
                <span className="material-symbols-outlined icon-sm">meeting_room</span>
                Counters ({counters.length})
              </button>
              <button
                type="button"
                className={`status-btn${subTab === 'services' ? ' open active' : ''}`}
                onClick={() => setSubTab('services')}
              >
                <span className="material-symbols-outlined icon-sm">apps</span>
                Services & Pausing ({services.length})
              </button>
            </div>

            {subTab === 'counters' && (
              <button
                type="button"
                className="action-btn btn-start"
                style={{ width: 'auto', padding: '0 16px' }}
                onClick={() => setShowAddCounterModal(true)}
              >
                <span className="material-symbols-outlined icon-sm">add</span>
                {t('admin.add_counter_btn', '+ Add Counter')}
              </button>
            )}
          </div>

          {/* Subtab: Counters Roster */}
          {subTab === 'counters' && (
            <div className="card">
              <div className="card-header">
                <div className="card-title-group">
                  <span className="material-symbols-outlined" style={{ color: 'var(--color-primary)' }}>
                    meeting_room
                  </span>
                  <span className="card-title">Counters Management — {humanOffice}</span>
                </div>
                <span className="badge-count">{counters.length} Configured</span>
              </div>

              {counters.length === 0 ? (
                <div style={{ padding: 'var(--space-xl)', textAlign: 'center', color: 'var(--color-text-secondary)' }}>
                  No counters configured for this facility yet. Click "+ Add Counter" to create one.
                </div>
              ) : (
                <table className="queue-table">
                  <thead>
                    <tr>
                      <th>Counter ID</th>
                      <th>Label</th>
                      <th>Status</th>
                      <th>Assigned Officer</th>
                      <th>Mapped Services</th>
                      <th>Status Actions</th>
                      <th>Manage</th>
                    </tr>
                  </thead>
                  <tbody>
                    {counters.map((cnt) => (
                      <tr key={cnt.id} className="queue-row">
                        <td>
                          <code>{cnt.id}</code>
                        </td>
                        <td>
                          <strong>{cnt.label}</strong>
                        </td>
                        <td>
                          <span
                            className={`badge-status ${
                              cnt.status === 'OPEN' ? 'arrived' : cnt.status === 'BREAK' ? 'called' : 'waiting'
                            }`}
                          >
                            {cnt.status}
                          </span>
                        </td>
                        <td>
                          {cnt.officer_id ? (
                            <span style={{ color: 'var(--color-primary)', fontWeight: 500 }}>{cnt.officer_id}</span>
                          ) : (
                            <span style={{ color: 'var(--color-text-muted)', fontStyle: 'italic' }}>Unassigned</span>
                          )}
                        </td>
                        <td>
                          {cnt.service_ids && cnt.service_ids.length > 0 ? (
                            <div style={{ display: 'flex', gap: '4px', flexWrap: 'wrap' }}>
                              {cnt.service_ids.map((sid) => (
                                <span
                                  key={sid}
                                  style={{
                                    fontSize: '11px',
                                    background: 'var(--color-secondary-canvas)',
                                    padding: '2px 6px',
                                    borderRadius: '4px',
                                    border: '1px solid var(--color-border)',
                                  }}
                                >
                                  {sid}
                                </span>
                              ))}
                            </div>
                          ) : (
                            <span style={{ fontSize: '12px', color: 'var(--color-text-muted)' }}>All Facility Services</span>
                          )}
                        </td>
                        <td>
                          <div style={{ display: 'flex', gap: '4px' }}>
                            <button
                              type="button"
                              className={`status-btn${cnt.status === 'OPEN' ? ' active' : ''}`}
                              style={{ padding: '4px 8px', fontSize: '11px', minWidth: 'auto' }}
                              onClick={() => handleUpdateCounterStatus(cnt.id, 'OPEN')}
                              disabled={loading || cnt.status === 'OPEN'}
                              title="Set status to Open"
                            >
                              OPEN
                            </button>
                            <button
                              type="button"
                              className={`status-btn${cnt.status === 'BREAK' ? ' active' : ''}`}
                              style={{ padding: '4px 8px', fontSize: '11px', minWidth: 'auto' }}
                              onClick={() => handleUpdateCounterStatus(cnt.id, 'BREAK')}
                              disabled={loading || cnt.status === 'BREAK'}
                              title="Set status to Break"
                            >
                              BREAK
                            </button>
                            <button
                              type="button"
                              className={`status-btn${cnt.status === 'CLOSED' ? ' active' : ''}`}
                              style={{ padding: '4px 8px', fontSize: '11px', minWidth: 'auto' }}
                              onClick={() => handleUpdateCounterStatus(cnt.id, 'CLOSED')}
                              disabled={loading || cnt.status === 'CLOSED'}
                              title="Set status to Closed"
                            >
                              CLOSED
                            </button>
                          </div>
                        </td>
                        <td>
                          <button
                            type="button"
                            className="status-btn cancel"
                            style={{ padding: '4px 8px', fontSize: '12px' }}
                            onClick={() => handleDeleteCounter(cnt.id, cnt.label)}
                            disabled={loading}
                            title="Delete counter"
                          >
                            <span className="material-symbols-outlined icon-xs">delete</span>
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              )}
            </div>
          )}

          {/* Subtab: Services & Pausing */}
          {subTab === 'services' && (
            <div className="card">
              <div className="card-header">
                <div className="card-title-group">
                  <span className="material-symbols-outlined" style={{ color: 'var(--color-primary)' }}>
                    miscellaneous_services
                  </span>
                  <span className="card-title">{t('admin.tab_services', 'Services & Pausing')}</span>
                </div>
                <span className="badge-count">{services.length} Configured</span>
              </div>

              <table className="queue-table">
                <thead>
                  <tr>
                    <th>Service Code</th>
                    <th>Name ({i18n.language.toUpperCase()})</th>
                    <th>Avg Duration</th>
                    <th>Physical Visit</th>
                    <th>Booking Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {services.map((svc) => (
                    <tr key={svc.id}>
                      <td>
                        <strong>{svc.code}</strong>
                      </td>
                      <td>{svc.names[i18n.language] || svc.names['en']}</td>
                      <td>~{svc.prior_avg_minutes} min</td>
                      <td>
                        <span className={`badge-status ${svc.requires_physical_visit ? 'arrived' : 'called'}`}>
                          {svc.requires_physical_visit ? 'Mandatory' : 'Optional'}
                        </span>
                      </td>
                      <td>
                        <div style={{ display: 'flex', gap: '8px' }}>
                          <button
                            type="button"
                            className="status-btn break"
                            onClick={() => setPauseServiceId(svc.id)}
                          >
                            {t('admin.pause_booking', 'Pause Booking')}
                          </button>
                          <button
                            type="button"
                            className="status-btn open"
                            onClick={() => handleResumeQueue(svc.id)}
                          >
                            {t('admin.resume_booking', 'Resume Booking')}
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}

      {/* ─────────────────────────────────────────────────────────────
          TAB 3: OFFICE SETTINGS
         ───────────────────────────────────────────────────────────── */}
      {activeTab === 'settings' && settingsData && (
        <div className="card" style={{ maxWidth: '800px', margin: '0 auto' }}>
          <div className="card-header">
            <div className="card-title-group">
              <span className="material-symbols-outlined" style={{ color: 'var(--color-primary)' }}>
                tune
              </span>
              <span className="card-title">
                {t('admin.tab_settings', 'Office Settings')} — {settingsData.office_id}
              </span>
            </div>
          </div>

          <form onSubmit={handleSaveSettings} style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 'var(--space-md)' }}>
            <div className="form-field">
              <label className="form-label">Grace Window (Minutes)</label>
              <input
                type="number"
                className="form-input"
                value={settingsData.grace_minutes}
                onChange={(e) => setSettingsData({ ...settingsData, grace_minutes: parseInt(e.target.value) || 0 })}
                min={1}
                required
              />
            </div>

            <div className="form-field">
              <label className="form-label">Priority Ratio (Every Nth Token)</label>
              <input
                type="number"
                className="form-input"
                value={settingsData.priority_every_n}
                onChange={(e) => setSettingsData({ ...settingsData, priority_every_n: parseInt(e.target.value) || 0 })}
                min={1}
                required
              />
            </div>

            <div className="form-field">
              <label className="form-label">Max Requeues on No-Show</label>
              <input
                type="number"
                className="form-input"
                value={settingsData.max_requeues}
                onChange={(e) => setSettingsData({ ...settingsData, max_requeues: parseInt(e.target.value) || 0 })}
                min={0}
                required
              />
            </div>

            <div className="form-field">
              <label className="form-label">Requeue Offset (Spots)</label>
              <input
                type="number"
                className="form-input"
                value={settingsData.requeue_offset}
                onChange={(e) => setSettingsData({ ...settingsData, requeue_offset: parseInt(e.target.value) || 0 })}
                min={1}
                required
              />
            </div>

            <div className="form-field">
              <label className="form-label">Close Grace Period (Minutes)</label>
              <input
                type="number"
                className="form-input"
                value={settingsData.close_grace_minutes}
                onChange={(e) => setSettingsData({ ...settingsData, close_grace_minutes: parseInt(e.target.value) || 0 })}
                min={0}
                required
              />
            </div>

            <div className="form-field">
              <label className="form-label">Max Active Tokens Per Phone</label>
              <input
                type="number"
                className="form-input"
                value={settingsData.max_active_tokens_per_phone}
                onChange={(e) =>
                  setSettingsData({ ...settingsData, max_active_tokens_per_phone: parseInt(e.target.value) || 0 })
                }
                min={1}
                required
              />
            </div>

            <div className="form-field">
              <label className="form-label">Max Waiting Per Service</label>
              <input
                type="number"
                className="form-input"
                value={settingsData.max_waiting_per_service}
                onChange={(e) =>
                  setSettingsData({ ...settingsData, max_waiting_per_service: parseInt(e.target.value) || 0 })
                }
                min={1}
                required
              />
            </div>

            <div className="form-field">
              <label className="form-label">Data Retention (Days)</label>
              <input
                type="number"
                className="form-input"
                value={settingsData.retention_days}
                onChange={(e) => setSettingsData({ ...settingsData, retention_days: parseInt(e.target.value) || 0 })}
                min={1}
                required
              />
            </div>

            <div style={{ gridColumn: 'span 2', marginTop: 'var(--space-md)' }}>
              <button type="submit" className="action-btn btn-start" disabled={loading} style={{ width: '100%' }}>
                <span className="material-symbols-outlined">save</span>
                {loading ? t('status.loading', 'Saving...') : t('admin.save_settings', 'Save Settings')}
              </button>
            </div>
          </form>
        </div>
      )}

      {/* ─────────────────────────────────────────────────────────────
          TAB 4: DAILY ENTRANCE QR
         ───────────────────────────────────────────────────────────── */}
      {activeTab === 'qr' && (
        <div className="card" style={{ maxWidth: '540px', margin: '0 auto', textAlign: 'center' }}>
          <div className="card-header">
            <div className="card-title-group" style={{ margin: '0 auto' }}>
              <span className="material-symbols-outlined" style={{ color: 'var(--color-primary)' }}>
                qr_code_2
              </span>
              <span className="card-title">{t('admin.qr_generator_title', 'Entrance QR Check-In Code')}</span>
            </div>
          </div>

          <p style={{ color: 'var(--color-text-secondary)', fontSize: 'var(--font-sm)', marginBottom: 'var(--space-md)' }}>
            {t(
              'admin.qr_instructions',
              'Print this daily signed QR code and place it at the office entrance for citizen arrival verification.',
            )}
          </p>

          {qrCodeData ? (
            <div
              style={{
                border: '2px dashed var(--color-border)',
                borderRadius: 'var(--radius-lg)',
                padding: 'var(--space-xl)',
                backgroundColor: 'var(--color-surface)',
              }}
            >
              <div style={{ fontSize: '18px', fontWeight: 700, color: 'var(--color-primary)' }}>
                {qrCodeData.office_id}
              </div>
              <div style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-secondary)', marginBottom: 'var(--space-md)' }}>
                Valid for Date: <strong>{qrCodeData.business_date}</strong>
              </div>

              {/* Render visual QR simulation block */}
              <div
                style={{
                  width: '200px',
                  height: '200px',
                  margin: '0 auto',
                  backgroundColor: '#0f172a',
                  color: '#ffffff',
                  display: 'flex',
                  flexDirection: 'column',
                  alignItems: 'center',
                  justifyContent: 'center',
                  borderRadius: '12px',
                  padding: '16px',
                  wordBreak: 'break-all',
                  fontSize: '11px',
                }}
              >
                <span className="material-symbols-outlined" style={{ fontSize: '64px', marginBottom: '8px' }}>
                  qr_code
                </span>
                <span style={{ opacity: 0.8, fontSize: '10px' }}>HMAC SIGNED QR</span>
              </div>

              <div style={{ marginTop: 'var(--space-md)', fontSize: '11px', color: 'var(--color-text-muted)' }}>
                HMAC Payload: <code>{qrCodeData.qr_payload.substring(0, 36)}…</code>
              </div>

              <button
                type="button"
                className="action-btn btn-start"
                style={{ margin: 'var(--space-md) auto 0', width: 'auto', padding: '0 24px' }}
                onClick={() => window.print()}
              >
                <span className="material-symbols-outlined">print</span>
                Print Daily Entrance Code
              </button>
            </div>
          ) : (
            <button type="button" className="action-btn btn-start" onClick={handleGenerateQr} disabled={loading}>
              Generate Daily QR
            </button>
          )}
        </div>
      )}

      {/* ─────────────────────────────────────────────────────────────
          MODAL: ADD COUNTER
         ───────────────────────────────────────────────────────────── */}
      {showAddCounterModal && (
        <div className="modal-overlay">
          <div className="modal-content">
            <h3 className="modal-title">Create New Service Counter</h3>
            <p className="modal-body" style={{ marginBottom: '16px' }}>
              Add an authorized service desk or counter for <strong>{humanOffice}</strong>.
            </p>
            <form onSubmit={handleCreateCounter}>
              <div className="form-field" style={{ marginBottom: '12px' }}>
                <label className="form-label">Counter ID (e.g. cnt-4)</label>
                <input
                  type="text"
                  className="form-input"
                  value={newCounterId}
                  onChange={(e) => setNewCounterId(e.target.value)}
                  placeholder="cnt-4"
                  required
                />
              </div>
              <div className="form-field" style={{ marginBottom: '16px' }}>
                <label className="form-label">Display Label (e.g. Counter 4)</label>
                <input
                  type="text"
                  className="form-input"
                  value={newCounterLabel}
                  onChange={(e) => setNewCounterLabel(e.target.value)}
                  placeholder="Counter 4"
                  required
                />
              </div>
              <div className="modal-actions">
                <button
                  type="button"
                  className="action-btn btn-secondary"
                  onClick={() => {
                    setShowAddCounterModal(false);
                    setNewCounterId('');
                    setNewCounterLabel('');
                  }}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="action-btn btn-start"
                  disabled={loading || !newCounterId.trim() || !newCounterLabel.trim()}
                >
                  {loading ? 'Creating...' : 'Create Counter'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ─────────────────────────────────────────────────────────────
          MODAL: PAUSE SERVICE BOOKING
         ───────────────────────────────────────────────────────────── */}
      {pauseServiceId && (
        <div className="modal-overlay">
          <div className="modal-content">
            <h3 className="modal-title">{t('admin.pause_modal_title', 'Pause Online & Desk Booking')}</h3>
            <p className="modal-body">
              Service: <strong>{pauseServiceId}</strong>
            </p>
            <div className="form-field">
              <label className="form-label">
                {t('admin.pause_reason_label', 'Reason for Pausing (e.g., Network Downtime, Staff Lunch)')}
              </label>
              <input
                type="text"
                className="form-input"
                value={pauseReason}
                onChange={(e) => setPauseReason(e.target.value)}
                required
              />
            </div>
            <div className="modal-actions">
              <button type="button" className="action-btn btn-secondary" onClick={() => setPauseServiceId(null)}>
                Cancel
              </button>
              <button
                type="button"
                className="action-btn btn-complete"
                onClick={handlePauseQueue}
                disabled={loading || !pauseReason.trim()}
              >
                {t('admin.confirm_pause', 'Confirm Pause')}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
