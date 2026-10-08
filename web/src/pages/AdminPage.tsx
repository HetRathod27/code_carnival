import { useState, useEffect, useCallback } from 'react';
import { useTranslation } from 'react-i18next';
import { useAuth } from '../context/AuthContext';
import {
  fetchOfficeSettings,
  updateOfficeSettings,
  fetchServices,
  pauseQueueBooking,
  resumeQueueBooking,
  generateEntranceQr,
  type OfficeSettingsOut,
  type ServiceOut,
} from '../api/client';

export function AdminPage() {
  const { t, i18n } = useTranslation();
  const { persona, token } = useAuth();
  const officeId = persona?.office_id || 'ward-central-01';

  const [activeTab, setActiveTab] = useState<'settings' | 'services' | 'qr'>('settings');
  const [settingsData, setSettingsData] = useState<OfficeSettingsOut | null>(null);
  const [services, setServices] = useState<ServiceOut[]>([]);
  const [qrCodeData, setQrCodeData] = useState<{ office_id: string; business_date: string; qr_payload: string } | null>(null);

  const [loading, setLoading] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  // Pause modal state
  const [pauseServiceId, setPauseServiceId] = useState<string | null>(null);
  const [pauseReason, setPauseReason] = useState<string>('Operational maintenance');

  const loadData = useCallback(async () => {
    if (!token) return;
    setLoading(true);
    setError(null);
    try {
      const [sData, svcList] = await Promise.all([
        fetchOfficeSettings(token, officeId).catch(() => null),
        fetchServices(officeId).catch(() => []),
      ]);
      if (sData) setSettingsData(sData);
      setServices(svcList);
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
      setSuccess(t('admin.saved_success'));
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Failed to update settings';
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
      loadData();
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
      loadData();
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

  return (
    <div className="officer-page">
      {/* Header */}
      <div className="page-header-row">
        <div className="page-header-left">
          <h1>{t('admin.title')}</h1>
          <p>{t('admin.subtitle')}</p>
        </div>

        <div className="page-header-actions">
          <div className="counter-status-toggle">
            <button
              type="button"
              className={`status-btn${activeTab === 'settings' ? ' open active' : ''}`}
              onClick={() => setActiveTab('settings')}
            >
              <span className="material-symbols-outlined icon-sm">settings</span>{' '}
              {t('admin.tab_settings')}
            </button>
            <button
              type="button"
              className={`status-btn${activeTab === 'services' ? ' open active' : ''}`}
              onClick={() => setActiveTab('services')}
            >
              <span className="material-symbols-outlined icon-sm">apps</span>{' '}
              {t('admin.tab_services')}
            </button>
            <button
              type="button"
              className={`status-btn${activeTab === 'qr' ? ' open active' : ''}`}
              onClick={() => {
                setActiveTab('qr');
                if (!qrCodeData) handleGenerateQr();
              }}
            >
              <span className="material-symbols-outlined icon-sm">qr_code</span>{' '}
              {t('admin.tab_qr')}
            </button>
          </div>
        </div>
      </div>

      {error && <div className="login-error">{error}</div>}
      {success && (
        <div style={{ padding: 'var(--space-md)', backgroundColor: 'var(--color-success-soft)', color: 'var(--color-success)', borderRadius: 'var(--radius-md)' }}>
          {success}
        </div>
      )}

      {/* Tab 1: Office Settings */}
      {activeTab === 'settings' && settingsData && (
        <div className="card" style={{ maxWidth: '800px', margin: '0 auto' }}>
          <div className="card-header">
            <div className="card-title-group">
              <span className="material-symbols-outlined" style={{ color: 'var(--color-primary)' }}>
                tune
              </span>
              <span className="card-title">{t('admin.tab_settings')} — {settingsData.office_id}</span>
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
                onChange={(e) => setSettingsData({ ...settingsData, max_active_tokens_per_phone: parseInt(e.target.value) || 0 })}
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
                onChange={(e) => setSettingsData({ ...settingsData, max_waiting_per_service: parseInt(e.target.value) || 0 })}
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
              <button
                type="submit"
                className="action-btn btn-start"
                disabled={loading}
                style={{ width: '100%' }}
              >
                <span className="material-symbols-outlined">save</span>
                {loading ? t('status.loading') : t('admin.save_settings')}
              </button>
            </div>
          </form>
        </div>
      )}

      {/* Tab 2: Services & Pausing */}
      {activeTab === 'services' && (
        <div className="card">
          <div className="card-header">
            <div className="card-title-group">
              <span className="material-symbols-outlined" style={{ color: 'var(--color-primary)' }}>
                miscellaneous_services
              </span>
              <span className="card-title">{t('admin.tab_services')}</span>
            </div>
          </div>

          <table className="queue-table">
            <thead>
              <tr>
                <th>Service Code</th>
                <th>Name ({i18n.language.toUpperCase()})</th>
                <th>Avg Duration</th>
                <th>Physical Visit</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {services.map((svc) => (
                <tr key={svc.id}>
                  <td><strong>{svc.code}</strong></td>
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
                        {t('admin.pause_booking')}
                      </button>
                      <button
                        type="button"
                        className="status-btn open"
                        onClick={() => handleResumeQueue(svc.id)}
                      >
                        {t('admin.resume_booking')}
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* Tab 3: Daily Entrance QR */}
      {activeTab === 'qr' && (
        <div className="card" style={{ maxWidth: '540px', margin: '0 auto', textAlign: 'center' }}>
          <div className="card-header">
            <div className="card-title-group" style={{ margin: '0 auto' }}>
              <span className="material-symbols-outlined" style={{ color: 'var(--color-primary)' }}>
                qr_code_2
              </span>
              <span className="card-title">{t('admin.qr_generator_title')}</span>
            </div>
          </div>

          <p style={{ color: 'var(--color-text-secondary)', fontSize: 'var(--font-sm)', marginBottom: 'var(--space-md)' }}>
            {t('admin.qr_instructions')}
          </p>

          {qrCodeData ? (
            <div style={{ border: '2px dashed var(--color-border)', borderRadius: 'var(--radius-lg)', padding: 'var(--space-xl)', backgroundColor: 'var(--color-surface)' }}>
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
            <button
              type="button"
              className="action-btn btn-start"
              onClick={handleGenerateQr}
              disabled={loading}
            >
              Generate Daily QR
            </button>
          )}
        </div>
      )}

      {/* Pause Modal */}
      {pauseServiceId && (
        <div className="modal-overlay">
          <div className="modal-content">
            <h3 className="modal-title">{t('admin.pause_modal_title')}</h3>
            <p className="modal-body">
              Service: <strong>{pauseServiceId}</strong>
            </p>
            <div className="form-field">
              <label className="form-label">{t('admin.pause_reason_label')}</label>
              <input
                type="text"
                className="form-input"
                value={pauseReason}
                onChange={(e) => setPauseReason(e.target.value)}
                required
              />
            </div>
            <div className="modal-actions">
              <button
                type="button"
                className="action-btn btn-secondary"
                onClick={() => setPauseServiceId(null)}
              >
                Cancel
              </button>
              <button
                type="button"
                className="action-btn btn-complete"
                onClick={handlePauseQueue}
                disabled={loading || !pauseReason.trim()}
              >
                {t('admin.confirm_pause')}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
