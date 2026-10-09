import { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { useAuth } from '../context/AuthContext';
import { getHumanOfficeName } from '../utils/officeNames';
import { isSoundEnabled, setSoundEnabled, playCheckinChime } from '../utils/audio';

export function MyAccountPage({ onSignOutRequested }: { onSignOutRequested?: () => void }) {
  const { t, i18n } = useTranslation();
  const { persona, logout } = useAuth();

  const [soundActive, setSoundActive] = useState<boolean>(() => isSoundEnabled());
  const [textSize, setTextSize] = useState<'normal' | 'large'>(() => {
    return (localStorage.getItem('ql_text_size') as 'normal' | 'large') || 'normal';
  });
  const [defaultCounter, setDefaultCounter] = useState<string>(() => {
    return localStorage.getItem('ql_default_counter') || 'cnt-1';
  });
  const [showSignOutConfirm, setShowSignOutConfirm] = useState(false);

  // Apply text size changes to html element
  useEffect(() => {
    if (textSize === 'large') {
      document.documentElement.classList.add('font-large');
      document.documentElement.style.setProperty('--font-body', '17px');
      document.documentElement.style.setProperty('--font-h1', '26px');
    } else {
      document.documentElement.classList.remove('font-large');
      document.documentElement.style.removeProperty('--font-body');
      document.documentElement.style.removeProperty('--font-h1');
    }
    localStorage.setItem('ql_text_size', textSize);
  }, [textSize]);

  const handleToggleSound = (enabled: boolean) => {
    setSoundEnabled(enabled);
    setSoundActive(enabled);
    if (enabled) {
      playCheckinChime();
    }
  };

  const handleDefaultCounterChange = (cnt: string) => {
    setDefaultCounter(cnt);
    localStorage.setItem('ql_default_counter', cnt);
  };

  const role = persona?.role || 'OFFICER';
  const humanOffice = getHumanOfficeName(persona?.office_id, undefined, i18n.language);

  const getDesignation = () => {
    if (role === 'OFFICER') return t('account.desig_officer', 'Gazetted Queue Operations Officer');
    if (role === 'DESK') return t('account.desig_desk', 'Citizen Assistance Desk Officer');
    if (role === 'ADMIN' || role === 'SUPER_ADMIN') return t('account.desig_admin', 'Zonal System & Civic Administrator');
    return t('account.desig_staff', 'Civic Staff Member');
  };

  const maskedPhone = persona?.phone
    ? persona.phone.replace(/(\+\d{2})(\d{3})\d{4}(\d{3})/, '$1 $2••••$3')
    : '+91 9988••••01';

  const userEmail = persona?.name
    ? `${persona.name.toLowerCase().replace(/[^a-z0-9]/g, '.')}@queueless.gov.in`
    : `staff.${persona?.id || 'officer'}@queueless.gov.in`;

  return (
    <div className="account-page" style={{ padding: 'var(--space-lg)', maxWidth: '1080px', margin: '0 auto' }}>
      {/* Title */}
      <div style={{ marginBottom: 'var(--space-lg)' }}>
        <h1 style={{ fontSize: 'var(--font-h1)', fontWeight: 700, color: 'var(--color-primary)', marginBottom: '4px' }}>
          {t('account.title', 'My Account')}
        </h1>
        <p style={{ fontSize: 'var(--font-body)', color: 'var(--color-text-secondary)' }}>
          {t('account.subtitle', 'Official staff identity credentials, workstation preferences, and security controls.')}
        </p>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))', gap: 'var(--space-lg)' }}>
        {/* Left Column: Official Profile Card */}
        <div
          className="card"
          style={{
            backgroundColor: 'var(--color-surface)',
            border: '1px solid var(--color-border)',
            borderRadius: 'var(--radius-md)',
            padding: 'var(--space-lg)',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-md)', marginBottom: 'var(--space-lg)' }}>
            <div
              style={{
                width: '64px',
                height: '64px',
                borderRadius: '50%',
                backgroundColor: 'var(--color-primary-soft)',
                border: '2px solid var(--color-primary)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: 'var(--color-primary)',
                fontSize: '28px',
                fontWeight: 700,
              }}
            >
              {persona?.name ? persona.name.charAt(0).toUpperCase() : 'O'}
            </div>
            <div>
              <h2 style={{ fontSize: 'var(--font-h2)', fontWeight: 700, color: 'var(--color-text-primary)' }}>
                {persona?.name || t('shell.authorized_staff', 'Authorized Staff')}
              </h2>
              <div style={{ display: 'flex', gap: '6px', alignItems: 'center', marginTop: '4px' }}>
                <span
                  style={{
                    backgroundColor: 'var(--color-primary-soft)',
                    color: 'var(--color-primary)',
                    fontSize: 'var(--font-xs)',
                    fontWeight: 700,
                    padding: '2px 8px',
                    borderRadius: 'var(--radius-sm)',
                  }}
                >
                  {role}
                </span>
                <span style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-muted)' }}>
                  ID: EMP-{(persona?.id || 'OFF-01').toUpperCase()}
                </span>
              </div>
            </div>
          </div>

          {/* Managed Notice Banner */}
          <div
            style={{
              padding: '10px 14px',
              backgroundColor: 'var(--color-secondary-canvas)',
              border: '1px solid var(--color-border)',
              borderRadius: 'var(--radius-sm)',
              fontSize: 'var(--font-xs)',
              color: 'var(--color-text-secondary)',
              display: 'flex',
              alignItems: 'center',
              gap: '8px',
              marginBottom: 'var(--space-lg)',
            }}
          >
            <span className="material-symbols-outlined icon-sm" style={{ color: 'var(--color-primary)' }}>
              shield
            </span>
            <span>
              {t('account.managed_notice', 'Managed by your office admin. Role assignment and center allocation cannot be edited directly.')}
            </span>
          </div>

          {/* Identity Grid */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-md)', fontSize: 'var(--font-body)' }}>
            <div>
              <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-muted)', fontWeight: 600 }}>
                {t('account.designation_label', 'Official Designation')}
              </div>
              <div style={{ fontWeight: 600, color: 'var(--color-text-primary)' }}>{getDesignation()}</div>
            </div>

            <div>
              <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-muted)', fontWeight: 600 }}>
                {t('account.assigned_office_label', 'Assigned Civic Office')}
              </div>
              <div style={{ fontWeight: 600, color: 'var(--color-text-primary)' }}>{humanOffice}</div>
            </div>

            <div>
              <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-muted)', fontWeight: 600 }}>
                {t('account.dept_label', 'Department')}
              </div>
              <div style={{ fontWeight: 600, color: 'var(--color-text-primary)' }}>
                {t('account.dept_val', 'Citizen Facilitation, Revenue & Public Grievance')}
              </div>
            </div>

            <div>
              <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-muted)', fontWeight: 600 }}>
                {t('account.shift_label', 'Workstation Shift Timing')}
              </div>
              <div style={{ fontWeight: 600, color: 'var(--color-text-primary)' }}>
                {t('account.shift_val', '09:00 AM – 05:00 PM (Standard Indian Civic Hours)')}
              </div>
            </div>

            <div>
              <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-muted)', fontWeight: 600 }}>
                {t('account.email_label', 'Official Email')}
              </div>
              <div style={{ fontWeight: 500, color: 'var(--color-text-primary)', fontVariantNumeric: 'tabular-nums' }}>
                {userEmail}
              </div>
            </div>

            <div>
              <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-muted)', fontWeight: 600 }}>
                {t('account.contact_label', 'Registered Contact')}
              </div>
              <div style={{ fontWeight: 500, color: 'var(--color-text-primary)', fontVariantNumeric: 'tabular-nums' }}>
                {maskedPhone}
              </div>
            </div>

            <div>
              <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-muted)', fontWeight: 600 }}>
                {t('account.session_label', 'Active Session')}
              </div>
              <div style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-secondary)' }}>
                {t('account.session_val', 'Authenticated via DevAuth Provider · Session Active')}
              </div>
            </div>
          </div>
        </div>

        {/* Right Column: Preferences & Security */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-lg)' }}>
          {/* Preferences Card */}
          <div
            className="card"
            style={{
              backgroundColor: 'var(--color-surface)',
              border: '1px solid var(--color-border)',
              borderRadius: 'var(--radius-md)',
              padding: 'var(--space-lg)',
            }}
          >
            <h2 style={{ fontSize: 'var(--font-h2)', fontWeight: 700, color: 'var(--color-text-primary)', marginBottom: 'var(--space-md)' }}>
              {t('account.pref_title', 'Workstation Preferences')}
            </h2>

            {/* Language Selection */}
            <div style={{ marginBottom: 'var(--space-lg)' }}>
              <label style={{ display: 'block', fontSize: 'var(--font-sm)', fontWeight: 700, marginBottom: '8px' }}>
                {t('account.lang_label', 'Display Language')}
              </label>
              <div style={{ display: 'flex', gap: '8px' }}>
                {(['en', 'gu', 'hi'] as const).map((lng) => {
                  const label = lng === 'en' ? 'English' : lng === 'gu' ? 'ગુજરાતી' : 'हिन्दी';
                  const active = i18n.language === lng;
                  return (
                    <button
                      key={lng}
                      type="button"
                      onClick={() => {
                        i18n.changeLanguage(lng);
                        localStorage.setItem('ql_lang', lng);
                      }}
                      style={{
                        minHeight: '48px',
                        padding: '0 16px',
                        borderRadius: 'var(--radius-sm)',
                        fontSize: 'var(--font-body)',
                        fontWeight: 600,
                        border: '1px solid',
                        borderColor: active ? 'var(--color-primary)' : 'var(--color-border)',
                        backgroundColor: active ? 'var(--color-primary-soft)' : 'var(--color-surface)',
                        color: active ? 'var(--color-primary)' : 'var(--color-text-primary)',
                      }}
                    >
                      {label}
                    </button>
                  );
                })}
              </div>
            </div>

            {/* Text Size Scale */}
            <div style={{ marginBottom: 'var(--space-lg)' }}>
              <label style={{ display: 'block', fontSize: 'var(--font-sm)', fontWeight: 700, marginBottom: '8px' }}>
                {t('account.text_size_label', 'Text Size Accessibility')}
              </label>
              <div style={{ display: 'flex', gap: '8px' }}>
                <button
                  type="button"
                  onClick={() => setTextSize('normal')}
                  style={{
                    minHeight: '48px',
                    padding: '0 16px',
                    borderRadius: 'var(--radius-sm)',
                    fontSize: '15px',
                    fontWeight: 600,
                    border: '1px solid',
                    borderColor: textSize === 'normal' ? 'var(--color-primary)' : 'var(--color-border)',
                    backgroundColor: textSize === 'normal' ? 'var(--color-primary-soft)' : 'var(--color-surface)',
                    color: textSize === 'normal' ? 'var(--color-primary)' : 'var(--color-text-primary)',
                  }}
                >
                  {t('account.text_normal', 'Normal (15px)')}
                </button>
                <button
                  type="button"
                  onClick={() => setTextSize('large')}
                  style={{
                    minHeight: '48px',
                    padding: '0 16px',
                    borderRadius: 'var(--radius-sm)',
                    fontSize: '17px',
                    fontWeight: 700,
                    border: '1px solid',
                    borderColor: textSize === 'large' ? 'var(--color-primary)' : 'var(--color-border)',
                    backgroundColor: textSize === 'large' ? 'var(--color-primary-soft)' : 'var(--color-surface)',
                    color: textSize === 'large' ? 'var(--color-primary)' : 'var(--color-text-primary)',
                  }}
                >
                  {t('account.text_large', 'Large (17px High-Legibility)')}
                </button>
              </div>
            </div>

            {/* Check-in Audio Chime */}
            <div style={{ marginBottom: 'var(--space-lg)' }}>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '8px' }}>
                <div>
                  <div style={{ fontSize: 'var(--font-sm)', fontWeight: 700 }}>
                    {t('account.chime_label', 'Arrival & Check-in Chime')}
                  </div>
                  <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-muted)' }}>
                    {t('account.chime_desc', 'Play acoustic chime notification when citizen checks in at counter')}
                  </div>
                </div>
                <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
                  <button
                    type="button"
                    onClick={() => handleToggleSound(!soundActive)}
                    style={{
                      minHeight: '44px',
                      padding: '0 14px',
                      borderRadius: 'var(--radius-sm)',
                      fontSize: 'var(--font-sm)',
                      fontWeight: 600,
                      border: '1px solid var(--color-border)',
                      backgroundColor: soundActive ? 'var(--color-success-soft)' : 'var(--color-secondary-canvas)',
                      color: soundActive ? 'var(--color-success)' : 'var(--color-text-muted)',
                    }}
                  >
                    {soundActive ? t('common.sound_on', 'Sound On') : t('common.sound_off', 'Sound Off')}
                  </button>
                  {soundActive && (
                    <button
                      type="button"
                      onClick={() => playCheckinChime()}
                      title="Test Audio Chime"
                      style={{
                        minHeight: '44px',
                        padding: '0 10px',
                        borderRadius: 'var(--radius-sm)',
                        border: '1px solid var(--color-border)',
                        backgroundColor: 'var(--color-surface)',
                      }}
                    >
                      <span className="material-symbols-outlined icon-sm">volume_up</span>
                    </button>
                  )}
                </div>
              </div>
            </div>

            {/* Default Counter Remembered */}
            <div>
              <label style={{ display: 'block', fontSize: 'var(--font-sm)', fontWeight: 700, marginBottom: '8px' }}>
                {t('account.default_counter_label', 'Default Assigned Counter')}
              </label>
              <select
                aria-label="Default assigned counter"
                value={defaultCounter}
                onChange={(e) => handleDefaultCounterChange(e.target.value)}
                style={{
                  width: '100%',
                  minHeight: '48px',
                  padding: '8px 12px',
                  borderRadius: 'var(--radius-sm)',
                  border: '1px solid var(--color-border)',
                  fontSize: 'var(--font-body)',
                  backgroundColor: 'var(--color-surface)',
                }}
              >
                <option value="cnt-1">{t('account.counter_1_opt', 'Counter 1 · Birth & Death Certificate')}</option>
                <option value="cnt-2">{t('account.counter_2_opt', 'Counter 2 · Property Tax Payment & Assessment')}</option>
                <option value="cnt-3">{t('account.counter_3_opt', 'Counter 3 · Property Tax Assessment & Payment')}</option>
                <option value="cnt-4">{t('account.counter_4_opt', 'Counter 4 · Trade License & Shop Registration')}</option>
                <option value="cnt-5">{t('account.counter_5_opt', 'Counter 5 · RTI Application & Civic Grievances')}</option>
              </select>
            </div>
          </div>

          {/* Security Card */}
          <div
            className="card"
            style={{
              backgroundColor: 'var(--color-surface)',
              border: '1px solid var(--color-border)',
              borderRadius: 'var(--radius-md)',
              padding: 'var(--space-lg)',
            }}
          >
            <h2 style={{ fontSize: 'var(--font-h2)', fontWeight: 700, color: 'var(--color-text-primary)', marginBottom: 'var(--space-md)' }}>
              {t('account.sec_title', 'Security & Session')}
            </h2>

            {/* Password Management */}
            <div style={{ marginBottom: 'var(--space-lg)' }}>
              <div style={{ fontSize: 'var(--font-sm)', fontWeight: 700, marginBottom: '4px' }}>
                {t('account.pwd_label', 'Change Password')}
              </div>
              <p style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-muted)', marginBottom: '8px' }}>
                {t('account.pwd_desc', 'Password updates are locked in local development mode (DevAuth active). In production, Supabase Auth manages staff passwords.')}
              </p>
              <button
                type="button"
                disabled
                style={{
                  minHeight: '48px',
                  padding: '0 16px',
                  borderRadius: 'var(--radius-sm)',
                  fontSize: 'var(--font-sm)',
                  border: '1px solid var(--color-border)',
                  backgroundColor: 'var(--color-secondary-canvas)',
                  color: 'var(--color-text-muted)',
                  cursor: 'not-allowed',
                }}
              >
                {t('account.pwd_btn_disabled', 'Change Password (Disabled in Dev)')}
              </button>
            </div>

            {/* Sign Out */}
            <div>
              <div style={{ fontSize: 'var(--font-sm)', fontWeight: 700, marginBottom: '4px' }}>
                {t('account.term_label', 'Session Termination')}
              </div>
              <p style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-muted)', marginBottom: '8px' }}>
                {t('account.term_desc', 'End this session and return to the role authentication portal.')}
              </p>
              <button
                type="button"
                onClick={() => {
                  if (onSignOutRequested) {
                    onSignOutRequested();
                  } else {
                    setShowSignOutConfirm(true);
                  }
                }}
                style={{
                  minHeight: '48px',
                  padding: '0 18px',
                  borderRadius: 'var(--radius-sm)',
                  fontSize: 'var(--font-body)',
                  fontWeight: 600,
                  border: '1px solid var(--color-danger-border)',
                  backgroundColor: 'var(--color-danger-soft)',
                  color: 'var(--color-danger)',
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: '8px',
                }}
              >
                <span className="material-symbols-outlined icon-sm">logout</span>
                {t('account.signout_device', 'Sign out of this device')}
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Sign Out Confirm Modal */}
      {showSignOutConfirm && (
        <div className="modal-overlay" style={{ zIndex: 1000 }}>
          <div className="modal-content" style={{ maxWidth: '440px' }}>
            <h2 className="modal-title" style={{ color: 'var(--color-danger)' }}>
              {t('account.confirm_signout_title', 'Confirm Staff Sign Out')}
            </h2>
            <div className="modal-body">
              <p style={{ fontSize: 'var(--font-body)', color: 'var(--color-text-secondary)' }}>
                {t('account.confirm_signout_body', 'Are you sure you want to sign out from the civic staff workstation? Any active token state will remain preserved in the queue system.')}
              </p>
            </div>
            <div className="modal-actions" style={{ display: 'flex', justifyContent: 'flex-end', gap: '8px', marginTop: '16px' }}>
              <button
                type="button"
                className="action-btn btn-secondary"
                style={{ minHeight: '44px', padding: '0 16px' }}
                onClick={() => setShowSignOutConfirm(false)}
              >
                {t('common.cancel', 'Cancel')}
              </button>
              <button
                type="button"
                style={{
                  minHeight: '44px',
                  padding: '0 16px',
                  backgroundColor: 'var(--color-danger)',
                  color: '#fff',
                  borderRadius: 'var(--radius-sm)',
                  fontWeight: 600,
                }}
                onClick={() => {
                  setShowSignOutConfirm(false);
                  logout();
                }}
              >
                {t('nav.sign_out', 'Confirm Sign Out')}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
