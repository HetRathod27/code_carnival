import { useState, type FormEvent } from 'react';
import { useAuth } from '../context/AuthContext';

interface Props {
  onNavigate?: (path: string) => void;
}

export function OfficerLoginPage({ onNavigate }: Props) {
  const { loginByRole, loading, error: authError } = useAuth();
  const [loginId, setLoginId] = useState('dev-officer-1');
  const [password, setPassword] = useState('officer@123');
  const [submitting, setSubmitting] = useState(false);
  const [formError, setFormError] = useState<string | null>(null);

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    if (!loginId.trim()) {
      setFormError('Please enter your Officer Login ID');
      return;
    }
    if (!password.trim()) {
      setFormError('Please enter your Password');
      return;
    }
    setSubmitting(true);
    setFormError(null);
    try {
      const ok = await loginByRole('OFFICER', loginId, password);
      if (!ok) {
        setFormError('Invalid officer credentials or account not found.');
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
    <div className="role-login-bg role-login-officer">
      {/* Left panel — institutional branding */}
      <div className="rll-panel">
        <div className="rll-govt-tag">
          🏛️ Government of Gujarat • Urban Development
        </div>
        <div className="rll-brand">
          <div className="rll-brand-icon">👮</div>
          <h1 className="rll-brand-title">Department Officer Portal</h1>
          <p className="rll-brand-sub">
            Direct staff terminal for municipal counter officers.<br />
            Manage live queue flow, call citizens and record counter operations.
          </p>
          <ul className="rll-feature-list">
            <li>📋 Call next citizen from live priority queue</li>
            <li>⏱️ Start &amp; complete service time tracking</li>
            <li>🔄 Counter transfer &amp; pass-over handling</li>
            <li>⭐ Dedicated VIP / Senior Citizen priority queue</li>
          </ul>
        </div>
        <div className="rll-panel-watermark">OFFICER</div>
      </div>

      {/* Right panel — credentials login form */}
      <div className="rll-form-panel">
        <div className="rll-form-card">
          <div className="rll-form-header officer-header">
            <span className="rll-role-badge officer-badge">OFFICER TERMINAL</span>
            <h2 className="rll-form-title">Officer Sign In</h2>
            <p className="rll-form-hint">Enter your Officer ID and password to access the dashboard</p>
          </div>

          {(formError || authError) && (
            <div className="rll-error" role="alert">
              ⚠️ {formError || authError}
            </div>
          )}

          <form onSubmit={handleSubmit} className="rll-credential-form">
            <div className="rll-input-group">
              <label htmlFor="officer-id" className="rll-label">Officer Login ID</label>
              <div className="rll-input-wrapper">
                <span className="rll-input-icon">badge</span>
                <input
                  id="officer-id"
                  name="officer-id"
                  type="text"
                  className="rll-input"
                  placeholder="e.g. dev-officer-1 or officer"
                  value={loginId}
                  onChange={(e) => setLoginId(e.target.value)}
                  autoComplete="username"
                  required
                />
              </div>
            </div>

            <div className="rll-input-group">
              <label htmlFor="officer-pass" className="rll-label">Password</label>
              <div className="rll-input-wrapper">
                <span className="rll-input-icon">lock</span>
                <input
                  id="officer-pass"
                  name="officer-pass"
                  type="password"
                  className="rll-input"
                  placeholder="Enter officer password"
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
                className="rll-demo-pill officer-pill"
                onClick={() => { setLoginId('dev-officer-1'); setPassword('officer@123'); }}
              >
                Auto-fill: <strong>dev-officer-1</strong> / <strong>••••••••</strong>
              </button>
            </div>

            <button
              id="officer-login-btn"
              type="submit"
              disabled={submitting || loading}
              className="rll-submit-btn officer-submit-btn"
            >
              {submitting ? 'Authenticating…' : 'Sign In to Officer Dashboard →'}
            </button>
          </form>

          <div className="rll-portal-links">
            <span className="rll-portal-links-title">Switch Staff Portal:</span>
            <div className="rll-portal-links-row">
              <button
                type="button"
                className="rll-link-btn"
                onClick={() => handlePortalSwitch('/desk')}
              >
                🪑 Help Desk Portal (/desk)
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
