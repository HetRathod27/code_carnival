import { useState, useEffect, useCallback } from 'react';
import { useAuth } from './context/AuthContext';
import { OfficerLoginPage } from './pages/OfficerLoginPage';
import { DeskLoginPage } from './pages/DeskLoginPage';
import { AdminLoginPage } from './pages/AdminLoginPage';
import { OfficerQueuePage } from './pages/OfficerQueuePage';
import { TodayActivityPage } from './pages/TodayActivityPage';
import { MyAccountPage } from './pages/MyAccountPage';
import { DeskPage } from './pages/DeskPage';
import { AdminPage } from './pages/AdminPage';
import { ReportsPage } from './pages/ReportsPage';
import { SimPage } from './pages/SimPage';
import { DisplayPage } from './pages/DisplayPage';
import { AppShell, type NavTab } from './components/AppShell';

export function App() {
  const { persona, logout } = useAuth();
  const [currentPath, setCurrentPath] = useState<string>(() => window.location.pathname);
  const [activeNav, setActiveNav] = useState<NavTab>('queue');
  const [displayOfficeId, setDisplayOfficeId] = useState<string>('ward-central-01');

  // Navigation helper that updates both window history and state
  const navigate = useCallback((path: string) => {
    window.history.pushState({}, '', path);
    setCurrentPath(path);
  }, []);

  // Sync route on popstate and hashchange
  useEffect(() => {
    const handleLocationChange = () => {
      const path = window.location.pathname;
      setCurrentPath(path);
      const match = path.match(/\/display\/([^/?#]+)/);
      if (match && match[1]) {
        setDisplayOfficeId(match[1]);
      }
    };

    window.addEventListener('popstate', handleLocationChange);
    window.addEventListener('hashchange', handleLocationChange);
    handleLocationChange();

    return () => {
      window.removeEventListener('popstate', handleLocationChange);
      window.removeEventListener('hashchange', handleLocationChange);
    };
  }, []);

  // Sync activeNav with URL path whenever URL or persona changes
  useEffect(() => {
    if (currentPath.startsWith('/desk')) {
      setActiveNav('desk');
    } else if (currentPath.startsWith('/admin')) {
      setActiveNav('admin');
    } else if (currentPath.startsWith('/officer')) {
      setActiveNav('queue');
    } else if (currentPath === '/' || currentPath === '') {
      if (persona?.role === 'DESK') {
        setActiveNav('desk');
      } else if (persona?.role === 'ADMIN' || persona?.role === 'SUPER_ADMIN') {
        setActiveNav('admin');
      } else {
        setActiveNav('queue');
      }
    }
  }, [currentPath, persona]);

  // If viewing public display lobby board, no auth required
  if (currentPath.includes('/display')) {
    return <DisplayPage officeId={displayOfficeId} />;
  }

  // --- 1. HELP DESK PORTAL (/desk) ---
  if (currentPath.startsWith('/desk')) {
    if (!persona) {
      return <DeskLoginPage onNavigate={navigate} />;
    }
    // Route guard: Officer cannot access Desk portal
    if (persona.role === 'OFFICER') {
      return (
        <div style={{ padding: '40px', textAlign: 'center', fontFamily: 'var(--font-family)' }}>
          <div style={{ maxWidth: '480px', margin: '0 auto', background: '#fff', border: '1px solid var(--color-border)', borderRadius: '8px', padding: '32px' }}>
            <span className="material-symbols-outlined" style={{ fontSize: '48px', color: 'var(--color-danger)' }}>
              lock
            </span>
            <h2 style={{ color: 'var(--color-danger)', margin: '16px 0 8px 0' }}>Access Restricted</h2>
            <p style={{ color: 'var(--color-text-secondary)', marginBottom: '24px' }}>
              Your account has the <strong>OFFICER</strong> role. Desk booking privileges are restricted to Help Desk and Admin staff.
            </p>
            <button
              type="button"
              onClick={() => navigate('/officer')}
              style={{ padding: '12px 24px', background: 'var(--color-primary)', color: '#fff', borderRadius: '4px', fontWeight: 600, border: 'none', cursor: 'pointer' }}
            >
              Return to Officer Queue
            </button>
          </div>
        </div>
      );
    }
    return (
      <AppShell
        activeNav={activeNav}
        onNavChange={setActiveNav}
        onOpenDisplay={() => window.open(`/display/${persona.office_id || 'ward-central-01'}`, '_blank')}
      >
        {activeNav === 'desk' && <DeskPage />}
        {activeNav === 'desk_queue' && <OfficerQueuePage />}
        {activeNav === 'account' && <MyAccountPage onSignOutRequested={logout} />}
        {activeNav === 'admin' && <AdminPage />}
        {activeNav === 'reports' && <ReportsPage />}
        {activeNav === 'sim' && <SimPage />}
      </AppShell>
    );
  }

  // --- 2. ADMIN PORTAL (/admin) ---
  if (currentPath.startsWith('/admin')) {
    if (!persona) {
      return <AdminLoginPage onNavigate={navigate} />;
    }
    // Route Guard: Officers cannot open Admin routes
    if (persona.role === 'OFFICER' || persona.role === 'DESK') {
      return (
        <div style={{ padding: '40px', textAlign: 'center', fontFamily: 'var(--font-family)' }}>
          <div style={{ maxWidth: '480px', margin: '0 auto', background: '#fff', border: '1px solid var(--color-border)', borderRadius: '8px', padding: '32px' }}>
            <span className="material-symbols-outlined" style={{ fontSize: '48px', color: 'var(--color-danger)' }}>
              gpp_bad
            </span>
            <h2 style={{ color: 'var(--color-danger)', margin: '16px 0 8px 0' }}>Unauthorized Access</h2>
            <p style={{ color: 'var(--color-text-secondary)', marginBottom: '24px' }}>
              Your account with role <strong>{persona.role}</strong> does not have administrative privileges to access the Admin Management Portal.
            </p>
            <button
              type="button"
              onClick={() => navigate(persona.role === 'DESK' ? '/desk' : '/officer')}
              style={{ padding: '12px 24px', background: 'var(--color-primary)', color: '#fff', borderRadius: '4px', fontWeight: 600, border: 'none', cursor: 'pointer' }}
            >
              Return to Staff Portal
            </button>
          </div>
        </div>
      );
    }
    return (
      <AppShell
        activeNav={activeNav}
        onNavChange={setActiveNav}
        onOpenDisplay={() => window.open(`/display/${persona.office_id || 'ward-central-01'}`, '_blank')}
      >
        {(activeNav === 'admin' || activeNav === 'admin_counters' || activeNav === 'admin_settings') && <AdminPage />}
        {activeNav === 'reports' && <ReportsPage />}
        {activeNav === 'sim' && <SimPage />}
        {activeNav === 'account' && <MyAccountPage onSignOutRequested={logout} />}
        {activeNav === 'queue' && <OfficerQueuePage />}
        {activeNav === 'desk' && <DeskPage />}
      </AppShell>
    );
  }

  // --- 3. DEPARTMENT OFFICER PORTAL (/officer or default /) ---
  if (!persona) {
    return <OfficerLoginPage onNavigate={navigate} />;
  }

  return (
    <AppShell
      activeNav={activeNav}
      onNavChange={setActiveNav}
      onOpenDisplay={() => window.open(`/display/${persona?.office_id || 'ward-central-01'}`, '_blank')}
    >
      {activeNav === 'queue' && <OfficerQueuePage />}
      {activeNav === 'activity' && <TodayActivityPage />}
      {activeNav === 'account' && <MyAccountPage onSignOutRequested={logout} />}
      {/* Desk and Admin tabs fallbacks for universal view if permitted */}
      {activeNav === 'desk' && (persona.role !== 'OFFICER' ? <DeskPage /> : <OfficerQueuePage />)}
      {activeNav === 'admin' && (persona.role === 'ADMIN' || persona.role === 'SUPER_ADMIN' ? <AdminPage /> : <OfficerQueuePage />)}
      {activeNav === 'reports' && (persona.role === 'ADMIN' || persona.role === 'SUPER_ADMIN' ? <ReportsPage /> : <TodayActivityPage />)}
      {activeNav === 'sim' && (persona.role === 'ADMIN' || persona.role === 'SUPER_ADMIN' ? <SimPage /> : <OfficerQueuePage />)}
    </AppShell>
  );
}

export default App;
