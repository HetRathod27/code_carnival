import { useTranslation } from 'react-i18next';
import { useAuth } from '../context/AuthContext';

const ROLE_ICONS: Record<string, string> = {
  OFFICER: '👮',
  DESK: '🪑',
  ADMIN: '⚙️',
  CITIZEN: '🧑',
};

const ROLE_DESC: Record<string, string> = {
  OFFICER: 'Call tokens, manage serving',
  DESK: 'Assisted booking',
  ADMIN: 'Office settings, reports',
  CITIZEN: 'Book & track tokens',
};

export function LoginPage() {
  const { t, i18n } = useTranslation();
  const { personas, loading, error, login } = useAuth();

  return (
    <div className="login-bg">
      <div className="login-card">
        <div className="login-logo">🎟️</div>
        <h1 className="login-title">{t('login.title')}</h1>
        <p className="login-sub">{t('login.subtitle')}</p>

        <div className="lang-picker">
          {(['en', 'gu', 'hi'] as const).map((lng) => (
            <button
              key={lng}
              id={`lang-${lng}`}
              type="button"
              className={`lang-btn${i18n.language === lng ? ' active' : ''}`}
              onClick={() => {
                i18n.changeLanguage(lng);
                localStorage.setItem('ql_lang', lng);
              }}
            >
              {lng.toUpperCase()}
            </button>
          ))}
        </div>

        {loading && <p className="login-hint">{t('login.signing_in')}</p>}
        {error && <p className="login-error">{t('login.error')}<br /><code>{error}</code></p>}

        {personas && (
          <>
            <p className="login-hint">{t('login.select_role')}</p>
            <div className="persona-grid">
              {Object.entries(personas).map(([id, p]) => (
                <button
                  key={id}
                  id={`persona-${id}`}
                  type="button"
                  className="persona-card"
                  onClick={() => login(id)}
                >
                  <span className="persona-icon">{ROLE_ICONS[p.role] ?? '👤'}</span>
                  <span className="persona-role">{p.role}</span>
                  <span className="persona-name">{p.name ?? id}</span>
                  <span className="persona-desc">{ROLE_DESC[p.role] ?? ''}</span>
                  {p.office_id && (
                    <span className="persona-office">{p.office_id}</span>
                  )}
                </button>
              ))}
            </div>
          </>
        )}
      </div>
    </div>
  );
}
