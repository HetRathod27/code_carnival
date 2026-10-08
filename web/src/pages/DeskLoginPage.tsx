import { useState, type FormEvent } from 'react';
import { useAuth } from '../context/AuthContext';

interface Props {
  onNavigate?: (path: string) => void;
}

export function DeskLoginPage({ onNavigate }: Props) {
  const { loginByRole, loading, error: authError } = useAuth();
  const [loginId, setLoginId] = useState('dev-desk-1');
  const [password, setPassword] = useState('desk@123');
  const [submitting, setSubmitting] = useState(false);
  const [formError, setFormError] = useState<string | null>(null);

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    if (!loginId.trim()) {
      setFormError('Please enter your Help Desk Login ID');
      return;
    }
    if (!password.trim()) {
      setFormError('Please enter your Password');
      return;
    }
    setSubmitting(true);
    setFormError(null);
    try {
      const ok = await loginByRole('DESK', loginId, password);
      if (!ok) {
        setFormError('Invalid help desk credentials or account not found.');
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
    <div className="role-login-bg role-login-desk">
      {/* Left panel — institutional branding */}
      <div className="rll-panel desk-panel">
        <div className="rll-govt-tag">
          🏛️ Government of Gujarat • Citizen Services Desk
        </div>
        <div className="rll-brand">
          <div className="rll-brand-icon">🪑</div>
          <h1 className="rll-brand-title">Help Desk Portal</h1>
          <p className="rll-brand-sub">
            Direct staff terminal for reception &amp; help desk staff.<br />
            Issue walk-in tokens, assist citizens, and print queue tokens.
          </p>
          <ul className="rll-feature-list">
            <li>🎫 Instant walk-in token generation</li>
            <li>🖨️ Physical thermal slip printing with QR code</li>
            <li>👥 Assisted citizen booking for all departments</li>
            <li>🔍 Real-time token status verification</li>
          </ul>
        </div>
        <div className="rll-panel-watermark">DESK</div>
      </div>

      {/* Right panel — credentials login form */}
      <div className="rll-form-panel">
        <div className="rll-form-card">
          <div className="rll-form-header desk-header">
            <span className="rll-role-badge desk-badge">HELP DESK TERMINAL</span>
            <h2 className="rll-form-title">Desk Staff Sign In</h2>
            <p className="rll-form-hint">Enter your Desk ID and password to access the help desk</p>
          </div>

          {(formError || authError) && (
            <div className="rll-error" role="alert">
              ⚠️ {formError || authError}
            </div>
          )}

          <form onSubmit={handleSubmit} className="rll-credential-form">
            <div className="rll-input-group">
              <label htmlFor="desk-id" className="rll-label">Desk Staff Login ID</label>
              <div className="rll-input-wrapper">
                <span className="rll-input-icon">badge</span>
                <input
                  id="desk-id"
                  name="desk-id"
                  type="text"
                  className="rll-input"
                  placeholder="e.g. dev-desk-1 or desk"
                  value={loginId}
                  onChange={(e) => setLoginId(e.target.value)}
                  autoComplete="username"
                  required
                />
              </div>
            </div>

            <div className="rll-input-group">
              <label htmlFor="desk-pass" className="rll-label">Password</label>
              <div className="rll-input-wrapper">
                <span className="rll-input-icon">lock</span>
                <input
                  id="desk-pass"
                  name="desk-pass"
                  type="password"
                  className="rll-input"
                  placeholder="Enter desk staff password"
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
                className="rll-demo-pill desk-pill"
                onClick={() => { setLoginId('dev-desk-1'); setPassword('desk@123'); }}
              >
                Auto-fill: <strong>dev-desk-1</strong> / <strong>••••••••</strong>
              </button>
            </div>

            <button
              id="desk-login-btn"
              type="submit"
              disabled={submitting || loading}
              className="rll-submit-btn desk-submit-btn"
            >
              {submitting ? 'Authenticating…' : 'Sign In to Help Desk Dashboard →'}
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
                onClick={() => handlePortalSwitch('/admin')}
              >
                ⚙️ Admin Portal (/admin)
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
