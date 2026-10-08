import { useState, type FormEvent } from 'react';
import { useAuth } from '../context/AuthContext';

interface Props {
  onNavigate?: (path: string) => void;
}

export function AdminLoginPage({ onNavigate }: Props) {
  const { loginByRole, loading, error: authError } = useAuth();
  const [loginId, setLoginId] = useState('dev-admin-1');
  const [password, setPassword] = useState('admin@123');
  const [submitting, setSubmitting] = useState(false);
  const [formError, setFormError] = useState<string | null>(null);

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    if (!loginId.trim()) {
      setFormError('Please enter your Administrator Login ID');
      return;
    }
    if (!password.trim()) {
      setFormError('Please enter your Password');
      return;
    }
    setSubmitting(true);
    setFormError(null);
    try {
      const ok = await loginByRole('ADMIN', loginId, password);
      if (!ok) {
        setFormError('Invalid administrator credentials or account not found.');
      }
    } catch (err: any) {
      setFormError(err.message || 'Login failed. Please check connection.');
    } finally {
      setSubmitting(false);
    }
  };

  const handlePortalSwitch = (path: string) => {
    if (onNavigate) {
      onNavigate(path);
    } else {
      window.location.href = path;
    }
  };

  return (
    <div className="role-login-bg role-login-admin">
      {/* Left panel — institutional branding */}
      <div className="rll-panel admin-panel">
        <div className="rll-govt-tag">
          🏛️ Government of Gujarat • Municipal Administration
        </div>
        <div className="rll-brand">
          <div className="rll-brand-icon">⚙️</div>
          <h1 className="rll-brand-title">Administrative Portal</h1>
          <p className="rll-brand-sub">
            Administrative console for municipal supervisory staff.<br />
            Configure offices, service windows, queue policies and monitor analytics.
          </p>
          <ul className="rll-feature-list">
            <li>🏢 Office &amp; Counter configuration</li>
            <li>⚙️ Dynamic service window &amp; SLA tunables</li>
            <li>📊 Real-time queue telemetry &amp; wait time stats</li>
            <li>🧪 High-scale queue virtual simulator control</li>
          </ul>
        </div>
        <div className="rll-panel-watermark">ADMIN</div>
      </div>

      {/* Right panel — credentials login form */}
      <div className="rll-form-panel">
        <div className="rll-form-card">
          <div className="rll-form-header admin-header">
            <span className="rll-role-badge admin-badge">ADMIN CONSOLE</span>
            <h2 className="rll-form-title">Admin Sign In</h2>
            <p className="rll-form-hint">Enter your Administrator ID and password to access settings</p>
          </div>

          {(formError || authError) && (
            <div className="rll-error" role="alert">
              ⚠️ {formError || authError}
            </div>
          )}

          <form onSubmit={handleSubmit} className="rll-credential-form">
            <div className="rll-input-group">
              <label htmlFor="admin-id" className="rll-label">Administrator Login ID</label>
              <div className="rll-input-wrapper">
                <span className="rll-input-icon">badge</span>
                <input
                  id="admin-id"
                  name="admin-id"
                  type="text"
                  className="rll-input"
                  placeholder="e.g. dev-admin-1 or admin"
                  value={loginId}
                  onChange={(e) => setLoginId(e.target.value)}
                  autoComplete="username"
                  required
                />
              </div>
            </div>

            <div className="rll-input-group">
              <label htmlFor="admin-pass" className="rll-label">Password</label>
              <div className="rll-input-wrapper">
                <span className="rll-input-icon">lock</span>
                <input
                  id="admin-pass"
                  name="admin-pass"
                  type="password"
                  className="rll-input"
                  placeholder="Enter admin password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  autoComplete="current-password"
                  required
                />
              </div>
            </div>

            <div className="rll-quick-demo">
              <span className="rll-demo-label">Demo credentials:</span>
              <button
                type="button"
                className="rll-demo-pill admin-pill"
                onClick={() => { setLoginId('dev-admin-1'); setPassword('admin@123'); }}
              >
                Auto-fill: <strong>dev-admin-1</strong> / <strong>••••••••</strong>
              </button>
            </div>

            <button
              id="admin-login-btn"
              type="submit"
              disabled={submitting || loading}
              className="rll-submit-btn admin-submit-btn"
            >
              {submitting ? 'Authenticating…' : 'Sign In to Admin Dashboard →'}
            </button>
          </form>

          <div className="rll-portal-links">
            <span className="rll-portal-links-title">Switch Staff Portal:</span>
            <div className="rll-portal-links-row">
              <button
                type="button"
                className="rll-link-btn"
                onClick={() => handlePortalSwitch('/officer')}
              >
                👮 Officer Portal (/officer)
              </button>
              <button
                type="button"
                className="rll-link-btn"
                onClick={() => handlePortalSwitch('/desk')}
              >
                🪑 Help Desk Portal (/desk)
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
