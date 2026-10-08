import { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { useAuth } from '../context/AuthContext';
import {
  fetchServices,
  deskCreateToken,
  deskManualCheckIn,
  type ServiceOut,
  type DeskSlipOut,
} from '../api/client';

export function DeskPage() {
  const { t, i18n } = useTranslation();
  const { persona, token } = useAuth();

  const officeId = persona?.office_id || 'ward-central-01';

  const [activeTab, setActiveTab] = useState<'issue' | 'checkin'>('issue');
  const [services, setServices] = useState<ServiceOut[]>([]);
  const [selectedServiceId, setSelectedServiceId] = useState<string>('');
  const [citizenName, setCitizenName] = useState<string>('');
  const [citizenPhone, setCitizenPhone] = useState<string>('');
  const [noPhone, setNoPhone] = useState<boolean>(false);
  const [category, setCategory] = useState<string>('NORMAL');
  const [mode, setMode] = useState<'WALKIN' | 'ASSISTED'>('WALKIN');
  const [overrideCapacity, setOverrideCapacity] = useState<boolean>(false);
  const [overrideReason, setOverrideReason] = useState<string>('CAPACITY_OVERRIDE_EMERGENCY');

  // Manual Check-In
  const [checkInTokenId, setCheckInTokenId] = useState<string>('');
  const [checkInStatus, setCheckInStatus] = useState<string | null>(null);

  // Issued Slip Modal
  const [issuedSlip, setIssuedSlip] = useState<DeskSlipOut | null>(null);
  const [issuedAt, setIssuedAt] = useState<string>('');
  const [loading, setLoading] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);

  useEffect(() => {
    fetchServices(officeId)
      .then((data) => {
        setServices(data);
        if (data.length > 0) setSelectedServiceId(data[0].id);
      })
      .catch((err) => {
        console.error('Failed to load services:', err);
      });
  }, [officeId]);

  const handleIssueSlip = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!token || !selectedServiceId) return;

    setLoading(true);
    setError(null);
    try {
      const res = await deskCreateToken(token, {
        office_id: officeId,
        service_id: selectedServiceId,
        category,
        phone: noPhone ? null : (citizenPhone.trim() || null),
        citizen_name: citizenName.trim() || null,
        created_via: mode,
        override_reason: overrideCapacity ? overrideReason : null,
      });
      setIssuedSlip(res);
      setIssuedAt(new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }));
      setSuccessMsg(`Token ${res.token.display_code} issued successfully!`);
      // Reset form
      setCitizenName('');
      setCitizenPhone('');
      setNoPhone(false);
      setOverrideCapacity(false);
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Failed to issue token';
      setError(msg);
    } finally {
      setLoading(false);
    }
  };

  const handleManualCheckIn = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!token || !checkInTokenId.trim()) return;

    setLoading(true);
    setCheckInStatus(null);
    try {
      const res = await deskManualCheckIn(token, checkInTokenId.trim());
      setCheckInStatus(`Arrival confirmed for Token ${res.display_code} (${res.id})`);
      setCheckInTokenId('');
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Check-in failed';
      setCheckInStatus(`Error: ${msg}`);
    } finally {
      setLoading(false);
    }
  };

  const handlePrintSlip = () => {
    window.print();
  };

  // Helper to get localized service name
  const getServiceName = (svcId: string): string => {
    const svc = services.find((s) => s.id === svcId);
    if (!svc) return svcId;
    const langKey = i18n.language;
    return svc.names[langKey] || svc.names['en'] || svc.code || svcId;
  };

  // Format estimated turn time
  const formatEstimatedTurn = (slip: DeskSlipOut): string => {
    const t = slip.token;
    if (t.eta_low != null && t.eta_high != null) {
      return `~${Math.round(t.eta_low)} – ${Math.round(t.eta_high)} min`;
    }
    if (t.last_eta_minutes != null) {
      return `~${Math.round(t.last_eta_minutes)} min`;
    }
    return '15 – 25 min';
  };

  return (
    <div className="officer-page">
      {/* Header Row */}
      <div className="page-header-row">
        <div className="page-header-left">
          <h1>{t('desk.title')}</h1>
          <p>{t('desk.subtitle')}</p>
        </div>

        <div className="page-header-actions">
          <div className="counter-status-toggle">
            <button
              type="button"
              className={`status-btn open${activeTab === 'issue' ? ' active' : ''}`}
              onClick={() => setActiveTab('issue')}
            >
              <span className="material-symbols-outlined icon-sm">receipt_long</span>{' '}
              {t('desk.issue_slip_tab')}
            </button>
            <button
              type="button"
              className={`status-btn break${activeTab === 'checkin' ? ' active' : ''}`}
              onClick={() => setActiveTab('checkin')}
            >
              <span className="material-symbols-outlined icon-sm">how_to_reg</span>{' '}
              {t('desk.manual_checkin_tab')}
            </button>
          </div>
        </div>
      </div>

      {error && <div className="login-error">{error}</div>}
      {successMsg && !issuedSlip && (
        <div style={{ padding: 'var(--space-md)', backgroundColor: 'var(--color-success-soft)', color: 'var(--color-success)', borderRadius: 'var(--radius-md)' }}>
          {successMsg}
        </div>
      )}

      {/* Main Content Area */}
      {activeTab === 'issue' ? (
        <div className="officer-grid">
          {/* Issue Form */}
          <div className="card">
            <div className="card-header">
              <div className="card-title-group">
                <span className="material-symbols-outlined" style={{ color: 'var(--color-primary)' }}>
                  add_circle
                </span>
                <span className="card-title">{t('desk.issue_slip_tab')}</span>
              </div>
            </div>

            <form onSubmit={handleIssueSlip} style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-md)' }}>
              {/* Service Selection */}
              <div className="form-field">
                <label className="form-label">{t('desk.service_label')}</label>
                <select
                  className="form-select"
                  value={selectedServiceId}
                  onChange={(e) => setSelectedServiceId(e.target.value)}
                  required
                >
                  {services.map((svc) => (
                    <option key={svc.id} value={svc.id}>
                      {svc.names[i18n.language] || svc.names['en']} ({svc.code}) — ~{svc.prior_avg_minutes}m
                    </option>
                  ))}
                </select>
              </div>

              {/* Citizen Name */}
              <div className="form-field">
                <label className="form-label">{t('desk.citizen_name_label')}</label>
                <input
                  type="text"
                  className="form-input"
                  placeholder="e.g. Ramesh Patel"
                  value={citizenName}
                  onChange={(e) => setCitizenName(e.target.value)}
                />
              </div>

              {/* Phone & No-Phone Toggle */}
              <div className="form-field">
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <label className="form-label">{t('desk.citizen_phone_label')}</label>
                  <label style={{ fontSize: 'var(--font-xs)', display: 'flex', alignItems: 'center', gap: '4px', cursor: 'pointer' }}>
                    <input
                      type="checkbox"
                      checked={noPhone}
                      onChange={(e) => setNoPhone(e.target.checked)}
                    />
                    {t('desk.no_phone_toggle')}
                  </label>
                </div>
                {!noPhone && (
                  <input
                    type="tel"
                    className="form-input"
                    placeholder="+91 98765 43210"
                    value={citizenPhone}
                    onChange={(e) => setCitizenPhone(e.target.value)}
                  />
                )}
              </div>

              {/* Category Picker */}
              <div className="form-field">
                <label className="form-label">{t('desk.category_label')}</label>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 'var(--space-xs)' }}>
                  {(['NORMAL', 'SENIOR', 'PREGNANT', 'DISABILITY'] as const).map((cat) => (
                    <button
                      key={cat}
                      type="button"
                      className={`status-btn${category === cat ? ' open active' : ''}`}
                      style={{ border: '1px solid var(--color-border)', textAlign: 'center', padding: '8px 4px' }}
                      onClick={() => setCategory(cat)}
                    >
                      {cat}
                    </button>
                  ))}
                </div>
              </div>

              {/* Mode Selection */}
              <div className="form-field">
                <label className="form-label">{t('desk.mode_label')}</label>
                <div style={{ display: 'flex', gap: 'var(--space-md)' }}>
                  <label style={{ display: 'flex', alignItems: 'center', gap: '6px', cursor: 'pointer' }}>
                    <input
                      type="radio"
                      name="mode"
                      value="WALKIN"
                      checked={mode === 'WALKIN'}
                      onChange={() => setMode('WALKIN')}
                    />
                    <strong>{t('desk.walkin_mode')}</strong>
                  </label>
                  <label style={{ display: 'flex', alignItems: 'center', gap: '6px', cursor: 'pointer' }}>
                    <input
                      type="radio"
                      name="mode"
                      value="ASSISTED"
                      checked={mode === 'ASSISTED'}
                      onChange={() => setMode('ASSISTED')}
                    />
                    <span>{t('desk.assisted_mode')}</span>
                  </label>
                </div>
              </div>

              {/* Capacity Override */}
              <div style={{ backgroundColor: 'var(--color-secondary-canvas)', padding: 'var(--space-md)', borderRadius: 'var(--radius-md)', display: 'flex', flexDirection: 'column', gap: 'var(--space-xs)' }}>
                <label style={{ display: 'flex', alignItems: 'center', gap: '8px', cursor: 'pointer', fontWeight: 600, fontSize: 'var(--font-sm)' }}>
                  <input
                    type="checkbox"
                    checked={overrideCapacity}
                    onChange={(e) => setOverrideCapacity(e.target.checked)}
                  />
                  {t('desk.override_box')}
                </label>
                {overrideCapacity && (
                  <div className="form-field" style={{ marginTop: 'var(--space-xs)' }}>
                    <label className="form-label">{t('desk.override_reason_label')}</label>
                    <input
                      type="text"
                      className="form-input"
                      value={overrideReason}
                      onChange={(e) => setOverrideReason(e.target.value)}
                      required
                    />
                  </div>
                )}
              </div>

              <button
                type="submit"
                className="action-btn btn-start"
                disabled={loading}
                style={{ marginTop: 'var(--space-sm)' }}
              >
                <span className="material-symbols-outlined">print</span>
                {loading ? t('status.loading') : t('desk.issue_btn')}
              </button>
            </form>
          </div>

          {/* Live Preview / Info Card */}
          <div className="card">
            <div className="card-header">
              <span className="card-title">Help Desk Operational Guidance</span>
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-md)', color: 'var(--color-text-secondary)', fontSize: 'var(--font-sm)' }}>
              <div style={{ display: 'flex', gap: 'var(--space-sm)', alignItems: 'flex-start' }}>
                <span className="material-symbols-outlined" style={{ color: 'var(--color-primary)' }}>info</span>
                <div>
                  <strong>Spec v3 Super-Seding Rule:</strong> Physical citizens receive a printed turn slip with an estimated turn time based on live queue conditions.
                </div>
              </div>
              <div style={{ display: 'flex', gap: 'var(--space-sm)', alignItems: 'flex-start' }}>
                <span className="material-symbols-outlined" style={{ color: 'var(--color-success)' }}>check_circle</span>
                <div>
                  <strong>Immediate Officer Dispatch:</strong> Officers may serve physical tokens whenever an online user is absent and the officer has capacity. There is <em>no requirement to wait for 3 missed users</em>.
                </div>
              </div>
              <div style={{ display: 'flex', gap: 'var(--space-sm)', alignItems: 'flex-start' }}>
                <span className="material-symbols-outlined" style={{ color: 'var(--color-warning)' }}>lock</span>
                <div>
                  <strong>Privacy Rule:</strong> Public lobby displays show Token Number and Counter only. Citizen names and phones are strictly protected.
                </div>
              </div>
            </div>
          </div>
        </div>
      ) : (
        /* Manual Check-In Tab */
        <div className="card" style={{ maxWidth: '640px', margin: '0 auto' }}>
          <div className="card-header">
            <div className="card-title-group">
              <span className="material-symbols-outlined" style={{ color: 'var(--color-primary)' }}>
                qr_code_scanner
              </span>
              <span className="card-title">{t('desk.manual_checkin_tab')}</span>
            </div>
          </div>

          <p style={{ color: 'var(--color-text-secondary)', marginBottom: 'var(--space-md)' }}>
            {t('desk.checkin_prompt')}
          </p>

          <form onSubmit={handleManualCheckIn} style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-md)' }}>
            <div className="form-field">
              <label className="form-label">{t('desk.token_id_label')}</label>
              <input
                type="text"
                className="form-input"
                placeholder="e.g. tok_..."
                value={checkInTokenId}
                onChange={(e) => setCheckInTokenId(e.target.value)}
                required
              />
            </div>

            <button
              type="submit"
              className="action-btn btn-start"
              disabled={loading || !checkInTokenId.trim()}
            >
              <span className="material-symbols-outlined">how_to_reg</span>
              {loading ? t('status.loading') : t('desk.checkin_btn')}
            </button>

            {checkInStatus && (
              <div
                style={{
                  padding: 'var(--space-md)',
                  borderRadius: 'var(--radius-md)',
                  backgroundColor: checkInStatus.startsWith('Error')
                    ? 'var(--color-danger-soft)'
                    : 'var(--color-success-soft)',
                  color: checkInStatus.startsWith('Error')
                    ? 'var(--color-danger)'
                    : 'var(--color-success)',
                  fontWeight: 600,
                  fontSize: 'var(--font-sm)',
                }}
              >
                {checkInStatus}
              </div>
            )}
          </form>
        </div>
      )}

      {/* Printable Slip Modal */}
      {issuedSlip && (
        <div className="modal-overlay">
          <div className="modal-content" style={{ maxWidth: '420px', textAlign: 'center', border: '2px dashed var(--color-border)' }}>
            <div style={{ padding: 'var(--space-sm) 0', borderBottom: '1px solid var(--color-border)', marginBottom: 'var(--space-md)' }}>
              <h2 style={{ fontSize: '22px', fontWeight: 800, color: 'var(--color-primary)', letterSpacing: '1px' }}>
                QueueLess
              </h2>
              <div style={{ fontSize: 'var(--font-xs)', textTransform: 'uppercase', color: 'var(--color-text-secondary)', letterSpacing: '0.5px' }}>
                Civic Services Administration
              </div>
              <div style={{ fontSize: 'var(--font-sm)', fontWeight: 600, marginTop: '4px' }}>
                {getServiceName(issuedSlip.token.service_id)}
              </div>
            </div>

            {/* Token Big Display */}
            <div style={{ padding: 'var(--space-md) 0' }}>
              <div style={{ fontSize: 'var(--font-xs)', textTransform: 'uppercase', color: 'var(--color-text-muted)' }}>
                {t('officer.token')}
              </div>
              <div style={{ fontSize: '56px', fontWeight: 900, color: 'var(--color-text-primary)', letterSpacing: '2px', lineHeight: 1.1 }}>
                {issuedSlip.printable_code}
              </div>
              <span className="badge-category" style={{ marginTop: 'var(--space-xs)' }}>
                {issuedSlip.token.category}
              </span>
            </div>

            {/* Estimated Turn Time */}
            <div style={{ backgroundColor: 'var(--color-surface-dim)', padding: 'var(--space-md)', borderRadius: 'var(--radius-md)', margin: 'var(--space-sm) 0' }}>
              <div style={{ fontSize: 'var(--font-xs)', fontWeight: 700, textTransform: 'uppercase', color: 'var(--color-primary)' }}>
                {t('desk.estimated_turn')}
              </div>
              <div style={{ fontSize: '20px', fontWeight: 800, color: 'var(--color-primary)', marginTop: '2px' }}>
                {formatEstimatedTurn(issuedSlip)}
              </div>
              <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-muted)', marginTop: '2px' }}>
                {t('desk.slip_sub')}
              </div>
            </div>

            {/* Details */}
            <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-secondary)', display: 'flex', flexDirection: 'column', gap: '4px', textAlign: 'left', padding: '0 var(--space-md)' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <span>{t('desk.waiting_ahead')}:</span>
                <strong>{issuedSlip.token.waiting_ahead} citizens</strong>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <span>Issued at:</span>
                <span>{issuedAt || 'Just now'}</span>
              </div>
            </div>

            <p style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-muted)', fontStyle: 'italic', margin: 'var(--space-md) 0 var(--space-sm)' }}>
              {t('desk.tv_notice')}
            </p>

            {/* Actions */}
            <div className="action-grid" style={{ marginTop: 'var(--space-sm)' }}>
              <button
                type="button"
                className="action-btn btn-start"
                onClick={handlePrintSlip}
              >
                <span className="material-symbols-outlined">print</span>
                {t('desk.print_btn')}
              </button>
              <button
                type="button"
                className="action-btn btn-secondary"
                onClick={() => setIssuedSlip(null)}
              >
                {t('desk.issue_another')}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
