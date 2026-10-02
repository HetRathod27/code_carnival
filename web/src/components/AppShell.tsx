import React from 'react';
import { useTranslation } from 'react-i18next';
import { useAuth } from '../context/AuthContext';

interface AppShellProps {
  children: React.ReactNode;
  activeNav?: 'queue' | 'reports';
  onNavChange?: (nav: 'queue' | 'reports') => void;
}

export function AppShell({ children, activeNav = 'queue', onNavChange }: AppShellProps) {
  const { t, i18n } = useTranslation();
  const { persona, logout } = useAuth();

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
          <button
            type="button"
            className={`nav-tab${activeNav === 'queue' ? ' active' : ''}`}
            onClick={() => onNavChange?.('queue')}
          >
            <span className="material-symbols-outlined icon-sm">queue</span>
            <span>{t('nav.queue')}</span>
          </button>
          <button
            type="button"
            className={`nav-tab${activeNav === 'reports' ? ' active' : ''}`}
            onClick={() => onNavChange?.('reports')}
          >
            <span className="material-symbols-outlined icon-sm">bar_chart</span>
            <span>{t('nav.reports')}</span>
          </button>
        </nav>

        {/* User Persona & Language / Logout */}
        <div className="header-right">
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
