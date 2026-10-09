import React, { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { useAuth } from '../context/AuthContext';
import { CivicCrest } from './CivicCrest';
import { getNavigationForRole, type NavTabId } from './navConfig';
import { getHumanOfficeName } from '../utils/officeNames';

export type NavTab = NavTabId;

interface AppShellProps {
  children: React.ReactNode;
  activeNav?: NavTab;
  onNavChange?: (nav: NavTab) => void;
  onOpenDisplay?: () => void;
  onNavigateUrl?: (path: string) => void;
}

export function AppShell({
  children,
  activeNav = 'queue',
  onNavChange,
  onOpenDisplay,
}: AppShellProps) {
  const { t, i18n } = useTranslation();
  const { persona, logout } = useAuth();

  // Desktop sidebar open/closed state (persisted in localStorage)
  const [sidebarOpen, setSidebarOpen] = useState<boolean>(() => {
    return localStorage.getItem('ql_sidebar_open') !== 'false';
  });
  // Mobile drawer open state (<1024px)
  const [mobileDrawerOpen, setMobileDrawerOpen] = useState(false);
  const [showSignOutConfirm, setShowSignOutConfirm] = useState(false);

  const toggleSidebar = () => {
    if (window.innerWidth < 1024) {
      setMobileDrawerOpen((prev) => !prev);
    } else {
      setSidebarOpen((prev) => {
        const next = !prev;
        localStorage.setItem('ql_sidebar_open', String(next));
        return next;
      });
    }
  };

  // Live Clock & Sync timestamp
  const [currentTime, setCurrentTime] = useState<string>(() => {
    return new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' });
  });
  const [currentDate, setCurrentDate] = useState<string>(() => {
    return new Date().toLocaleDateString(undefined, { weekday: 'short', day: '2-digit', month: 'short', year: 'numeric' });
  });
  const [lastSyncTime, setLastSyncTime] = useState<string>(() => {
    return new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' });
  });

  // Keep clock running live
  useEffect(() => {
    const timer = setInterval(() => {
      const d = new Date();
      setCurrentTime(d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' }));
      setCurrentDate(d.toLocaleDateString(undefined, { weekday: 'short', day: '2-digit', month: 'short', year: 'numeric' }));
    }, 1000);
    return () => clearInterval(timer);
  }, []);

  // Update sync indicator periodically
  useEffect(() => {
    const syncTimer = setInterval(() => {
      setLastSyncTime(new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' }));
    }, 15000);
    return () => clearInterval(syncTimer);
  }, []);

  const role = persona?.role || 'OFFICER';
  const humanOffice = getHumanOfficeName(persona?.office_id);
  const navSections = getNavigationForRole(role);

  // Resolve active nav item title for breadcrumb
  let activeItemLabel = t('nav.my_queue', 'My queue');
  for (const sec of navSections) {
    const found = sec.items.find((item) => item.id === activeNav);
    if (found) {
      activeItemLabel = t(found.labelKey, found.defaultLabel);
      break;
    }
  }

  const roleDisplay =
    role === 'OFFICER'
      ? 'Officer Portal'
      : role === 'DESK'
      ? 'Help Desk Portal'
      : role === 'ADMIN' || role === 'SUPER_ADMIN'
      ? 'Admin Portal'
      : 'Staff Portal';

  const handleNavClick = (itemId: NavTabId, isExternal?: boolean) => {
    if (isExternal && itemId === 'display') {
      if (onOpenDisplay) {
        onOpenDisplay();
      } else {
        const off = persona?.office_id || 'ward-central-01';
        window.open(`/display/${off}`, '_blank');
      }
      return;
    }

    if (itemId === 'account') {
      onNavChange?.('account');
      setMobileDrawerOpen(false);
      return;
    }

    onNavChange?.(itemId);
    setMobileDrawerOpen(false);
  };

  return (
    <div className="gov-app-shell">
      {/* 1. Very Top 4px Institutional Primary Strip */}
      <div className="top-gov-strip" aria-hidden="true" />

      {/* 2. Main Outer Layout: Sidebar + Main Stage */}
      <div className="gov-shell-layout">
        {/* Mobile Backdrop Overlay (<1024px) */}
        {mobileDrawerOpen && (
          <div
            className="gov-drawer-backdrop"
            onClick={() => setMobileDrawerOpen(false)}
            aria-hidden="true"
          />
        )}

        {/* 3. Left Sidebar (260px wide, can be closed and opened by user) */}
        <aside
          className={`gov-sidebar${!sidebarOpen ? ' closed' : ''}${mobileDrawerOpen ? ' drawer-open' : ''}`}
          aria-label="Staff Navigation Sidebar"
        >
          {/* Top Brand & Office Identity */}
          <div className="sidebar-brand-block">
            <div className="crest-and-title">
              <CivicCrest size={40} />
              <div className="brand-text-wrap">
                <div className="brand-app-name">QueueLess</div>
                <div className="brand-sub-badge">Civic Governance</div>
              </div>
              {/* Close Sidebar Button */}
              <button
                type="button"
                className="btn-sidebar-toggle-close"
                onClick={toggleSidebar}
                title="Close sidebar"
                aria-label="Close navigation sidebar"
              >
                <span className="material-symbols-outlined icon-sm">menu_open</span>
              </button>
            </div>

            {/* Office Human Name (Never internal ID like ward-central-01) */}
            <div className="sidebar-office-card" title={humanOffice}>
              <span className="material-symbols-outlined icon-sm civic-office-icon">
                account_balance
              </span>
              <span className="sidebar-office-text">{humanOffice}</span>
            </div>
          </div>

          {/* Navigation Sections */}
          <nav className="sidebar-nav-container">
            {navSections.map((section) => (
              <div key={section.sectionKey} className="nav-section-group">
                <div className="nav-section-header">
                  {t(section.sectionKey, section.defaultTitle)}
                </div>
                <div className="nav-section-items">
                  {section.items.map((item) => {
                    const isActive = activeNav === item.id;
                    return (
                      <button
                        key={item.id}
                        type="button"
                        className={`sidebar-nav-item${isActive ? ' active' : ''}`}
                        onClick={() => handleNavClick(item.id, item.isExternalTab)}
                        title={t(item.labelKey, item.defaultLabel)}
                      >
                        <span className="material-symbols-outlined nav-item-icon">
                          {item.icon}
                        </span>
                        <span className="nav-item-label">
                          {t(item.labelKey, item.defaultLabel)}
                        </span>
                        {item.isExternalTab && (
                          <span className="material-symbols-outlined icon-xs external-tab-icon">
                            open_in_new
                          </span>
                        )}
                      </button>
                    );
                  })}
                </div>
              </div>
            ))}
          </nav>

          {/* Bottom Sidebar Footer: User Card, Language Switcher, Sign Out */}
          <div className="sidebar-bottom-block">
            {/* User Card: clicking opens My Account */}
            <button
              type="button"
              className={`sidebar-user-card${activeNav === 'account' ? ' active' : ''}`}
              onClick={() => {
                onNavChange?.('account');
                setMobileDrawerOpen(false);
              }}
              title="Open My Account"
            >
              <div className="user-avatar-pill">
                <span className="material-symbols-outlined icon-sm">person</span>
              </div>
              <div className="user-info-col">
                <div className="user-card-name">{persona?.name || 'Authorized Staff'}</div>
                <div className="user-card-meta">
                  <span className="user-role-tag">{role}</span>
                  <span className="user-office-brief">{humanOffice.split('(')[0]}</span>
                </div>
              </div>
            </button>

            {/* Language Switcher */}
            <div className="sidebar-lang-strip" aria-label="Select interface language">
              {(
                [
                  { code: 'en', label: 'EN' },
                  { code: 'gu', label: 'ગુજરાતી' },
                  { code: 'hi', label: 'हिन्दी' },
                ] as const
              ).map(({ code, label }) => (
                <button
                  key={code}
                  type="button"
                  className={`lang-btn${i18n.language === code ? ' active' : ''}`}
                  onClick={() => {
                    i18n.changeLanguage(code);
                    localStorage.setItem('ql_lang', code);
                  }}
                >
                  {label}
                </button>
              ))}
            </div>

            {/* Sign Out Button with Confirm Dialog */}
            <button
              type="button"
              className="sidebar-signout-btn"
              onClick={() => setShowSignOutConfirm(true)}
            >
              <span className="material-symbols-outlined icon-sm">logout</span>
              <span className="signout-label">{t('nav.sign_out', 'Sign out')}</span>
            </button>
          </div>
        </aside>

        {/* 4. Right Content Column */}
        <div className="gov-main-column">
          {/* Slim Top Bar: Breadcrumb, Live Clock, Sync status */}
          <header className="gov-slim-topbar">
            <div className="topbar-left">
              {/* Universal Sidebar Toggle Button (Click to Open/Close Sidebar) */}
              <button
                type="button"
                className="btn-sidebar-toggle"
                onClick={toggleSidebar}
                title={sidebarOpen ? 'Close sidebar' : 'Open sidebar'}
                aria-label="Toggle navigation sidebar"
                aria-expanded={sidebarOpen}
              >
                <span className="material-symbols-outlined icon-md">
                  {sidebarOpen ? 'menu_open' : 'menu'}
                </span>
              </button>

              {/* Breadcrumb Hierarchy */}
              <nav className="topbar-breadcrumbs" aria-label="Breadcrumb">
                <span className="breadcrumb-root">QueueLess</span>
                <span className="breadcrumb-separator">/</span>
                <span className="breadcrumb-role">{roleDisplay}</span>
                <span className="breadcrumb-separator">/</span>
                <span className="breadcrumb-current">{activeItemLabel}</span>
              </nav>
            </div>

            <div className="topbar-right">
              {/* Office Name Chip */}
              <div className="topbar-office-chip" title={humanOffice}>
                <span className="material-symbols-outlined icon-xs">location_on</span>
                <span>{humanOffice}</span>
              </div>

              {/* Live Server / Local Date and Time */}
              <div className="topbar-live-clock" title={`${currentDate} · Indian Standard Time`}>
                <span className="material-symbols-outlined icon-xs">schedule</span>
                <span className="clock-text">{currentTime}</span>
              </div>

              {/* Sync Indicator */}
              <div className="topbar-sync-indicator" title={`System status synchronized with server`}>
                <span className="sync-pulse-dot" />
                <span className="sync-text">Updated {lastSyncTime}</span>
              </div>
            </div>
          </header>

          {/* Main Workplace Stage */}
          <main className="gov-workplace-stage">
            {children}
          </main>

          {/* Slim Footer */}
          <footer className="gov-slim-footer">
            <div className="footer-contact">
              <span className="material-symbols-outlined icon-xs">headset_mic</span>
              <span>Civic Help Desk: 1800-233-0000 · support@queueless.gov.in</span>
            </div>
            <div className="footer-version">
              QueueLess Staff Portal v1.4.0 (Institutional Civic Edition)
            </div>
            <div className="footer-sync">
              Synced: {lastSyncTime}
            </div>
          </footer>
        </div>
      </div>

      {/* Sign Out Confirmation Modal */}
      {showSignOutConfirm && (
        <div className="modal-overlay" style={{ zIndex: 1200 }}>
          <div className="modal-content" style={{ maxWidth: '440px' }}>
            <h2 className="modal-title" style={{ color: 'var(--color-danger)' }}>
              {t('nav.confirm_sign_out', 'Confirm Sign Out')}
            </h2>
            <div className="modal-body">
              <p style={{ fontSize: 'var(--font-body)', color: 'var(--color-text-secondary)' }}>
                {t(
                  'nav.confirm_sign_out_desc',
                  'Are you sure you want to sign out from the staff portal? Your active session credentials will be cleared.',
                )}
              </p>
            </div>
            <div className="modal-actions" style={{ display: 'flex', justifyContent: 'flex-end', gap: '8px', marginTop: '16px' }}>
              <button
                type="button"
                className="action-btn btn-secondary"
                style={{ minHeight: '44px', padding: '0 16px' }}
                onClick={() => setShowSignOutConfirm(false)}
              >
                Cancel
              </button>
              <button
                type="button"
                style={{
                  minHeight: '44px',
                  padding: '0 18px',
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
                Sign Out
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
