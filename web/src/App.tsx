import { useState, useEffect, useCallback } from 'react';
import { useAuth } from './context/AuthContext';
import { OfficerLoginPage } from './pages/OfficerLoginPage';
import { DeskLoginPage } from './pages/DeskLoginPage';
import { AdminLoginPage } from './pages/AdminLoginPage';
import { OfficerQueuePage } from './pages/OfficerQueuePage';
import { DeskPage } from './pages/DeskPage';
import { AdminPage } from './pages/AdminPage';
import { ReportsPage } from './pages/ReportsPage';
import { SimPage } from './pages/SimPage';
import { DisplayPage } from './pages/DisplayPage';
import { AppShell, type NavTab } from './components/AppShell';

export function App() {
  const { persona } = useAuth();
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
    return (
      <AppShell
        activeNav={activeNav}
        onNavChange={setActiveNav}
        onOpenDisplay={() => window.open(`/display/${persona.office_id || 'ward-central-01'}`, '_blank')}
      >
        {activeNav === 'desk' && <DeskPage />}
        {activeNav === 'queue' && <OfficerQueuePage />}
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
    return (
      <AppShell
        activeNav={activeNav}
        onNavChange={setActiveNav}
        onOpenDisplay={() => window.open(`/display/${persona.office_id || 'ward-central-01'}`, '_blank')}
      >
        {activeNav === 'admin' && <AdminPage />}
        {activeNav === 'reports' && <ReportsPage />}
        {activeNav === 'sim' && <SimPage />}
        {activeNav === 'queue' && <OfficerQueuePage />}
        {activeNav === 'desk' && <DeskPage />}
      </AppShell>
    );
  }

  // --- 3. DEPARTMENT OFFICER PORTAL (/officer or default /) ---
  if (!persona) {
    // If not signed in on /officer or root /, show Officer Login Page
    return <OfficerLoginPage onNavigate={navigate} />;
  }

  return (
    <AppShell
      activeNav={activeNav}
      onNavChange={setActiveNav}
      onOpenDisplay={() => window.open(`/display/${persona?.office_id || 'ward-central-01'}`, '_blank')}
    >
      {activeNav === 'queue' && <OfficerQueuePage />}
      {activeNav === 'desk' && <DeskPage />}
      {activeNav === 'admin' && <AdminPage />}
      {activeNav === 'reports' && <ReportsPage />}
      {activeNav === 'sim' && <SimPage />}
    </AppShell>
  );
}

export default App;
