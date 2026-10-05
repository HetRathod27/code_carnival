import React from 'react';
import { useTranslation } from 'react-i18next';
import { useAuth } from '../context/AuthContext';

export type NavTab = 'queue' | 'desk' | 'admin' | 'reports' | 'sim';

interface AppShellProps {
  children: React.ReactNode;
  activeNav?: NavTab;
  onNavChange?: (nav: NavTab) => void;
  onOpenDisplay?: () => void;
}

export function AppShell({ children, activeNav = 'queue', onNavChange, onOpenDisplay }: AppShellProps) {
  const { t, i18n } = useTranslation();
  const { persona, logout } = useAuth();
  const role = persona?.role || 'OFFICER';

  const showQueue = role === 'OFFICER' || role === 'ADMIN' || role === 'SUPER_ADMIN' || role === 'DESK';
  const showDesk = role === 'DESK' || role === 'ADMIN' || role === 'SUPER_ADMIN';
  const showAdmin = role === 'ADMIN' || role === 'SUPER_ADMIN';
  const showReports = role === 'ADMIN' || role === 'SUPER_ADMIN' || role === 'OFFICER';
  const showSim = role === 'ADMIN' || role === 'SUPER_ADMIN';

  return (
    <div className="app-layout">
      {/* Institutional Top Header */}
      <header className="app-header">
        <div className="header-left">
          <div className="brand-logo">
            <span className="brand-icon">🎟️</span>
            <span className="brand-title">QueueLess</span>
          </div>
          <div className="header-divider" />
          <div className="office-badge">
            <span className="material-symbols-outlined icon-sm">account_balance</span>
            <span className="office-name">
              {persona?.office_id ? `Ward Office (${persona.office_id})` : 'Central Municipal Office'}
            </span>
          </div>
        </div>

        {/* Center Navigation */}
        <nav className="header-nav">
          {showQueue && (
            <button
              type="button"
              className={`nav-tab${activeNav === 'queue' ? ' active' : ''}`}
              onClick={() => onNavChange?.('queue')}
            >
              <span className="material-symbols-outlined icon-sm">queue</span>
              <span>{t('nav.queue')}</span>
            </button>
          )}

          {showDesk && (
            <button
              type="button"
              className={`nav-tab${activeNav === 'desk' ? ' active' : ''}`}
              onClick={() => onNavChange?.('desk')}
            >
              <span className="material-symbols-outlined icon-sm">receipt_long</span>
              <span>{t('nav.desk')}</span>
            </button>
          )}

          {showAdmin && (
            <button
              type="button"
              className={`nav-tab${activeNav === 'admin' ? ' active' : ''}`}
              onClick={() => onNavChange?.('admin')}
            >
              <span className="material-symbols-outlined icon-sm">admin_panel_settings</span>
              <span>{t('nav.admin')}</span>
            </button>
          )}

          {showReports && (
            <button
              type="button"
              className={`nav-tab${activeNav === 'reports' ? ' active' : ''}`}
              onClick={() => onNavChange?.('reports')}
            >
              <span className="material-symbols-outlined icon-sm">bar_chart</span>
              <span>{t('nav.reports')}</span>
            </button>
          )}

          {showSim && (
            <button
              type="button"
              className={`nav-tab${activeNav === 'sim' ? ' active' : ''}`}
              onClick={() => onNavChange?.('sim')}
            >
              <span className="material-symbols-outlined icon-sm">science</span>
              <span>{t('nav.sim')}</span>
            </button>
          )}
        </nav>

        {/* User Persona & Language / Display / Logout */}
        <div className="header-right">
          {onOpenDisplay && (
            <button
              type="button"
              className="action-btn btn-secondary"
              style={{ height: '36px', padding: '0 12px', fontSize: 'var(--font-xs)', fontWeight: 600 }}
              onClick={onOpenDisplay}
              title="Open Public Lobby Display"
            >
              <span className="material-symbols-outlined icon-sm">tv</span>
              <span>{t('nav.display')}</span>
            </button>
          )}

          <div className="user-profile">
            <div className="avatar-chip">
              <span className="material-symbols-outlined icon-sm">person</span>
            </div>
            <div className="user-details">
              <span className="user-name">{persona?.name || 'Staff User'}</span>
              <span className="user-role-badge">{persona?.role || 'OFFICER'}</span>
            </div>
          </div>

          <div className="header-divider" />

          {/* Language Switcher */}
          <div className="lang-switcher">
            {(['en', 'gu', 'hi'] as const).map((lng) => (
              <button
                key={lng}
                type="button"
                className={`lang-pill${i18n.language === lng ? ' active' : ''}`}
                onClick={() => {
                  i18n.changeLanguage(lng);
                  localStorage.setItem('ql_lang', lng);
                }}
              >
                {lng.toUpperCase()}
              </button>
            ))}
          </div>

          <button
            type="button"
            className="btn-logout"
            onClick={logout}
            title={t('nav.sign_out')}
          >
            <span className="material-symbols-outlined icon-sm">logout</span>
            <span>{t('nav.sign_out')}</span>
          </button>
        </div>
      </header>

      {/* Main Content Area */}
      <main className="app-main">
        {children}
      </main>
    </div>
  );
}
