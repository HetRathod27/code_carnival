import { useState, useEffect } from 'react';
import { useAuth } from './context/AuthContext';
import { LoginPage } from './pages/LoginPage';
import { OfficerQueuePage } from './pages/OfficerQueuePage';
import { DeskPage } from './pages/DeskPage';
import { AdminPage } from './pages/AdminPage';
import { ReportsPage } from './pages/ReportsPage';
import { SimPage } from './pages/SimPage';
import { DisplayPage } from './pages/DisplayPage';
import { AppShell, type NavTab } from './components/AppShell';

export function App() {
  const { persona } = useAuth();
  const [activeNav, setActiveNav] = useState<NavTab>('queue');
  const [isDisplayRoute, setIsDisplayRoute] = useState<boolean>(false);
  const [displayOfficeId, setDisplayOfficeId] = useState<string>('ward-central-01');

  // Check URL pathname / hash on load and change
  useEffect(() => {
    const checkRoute = () => {
      const path = window.location.pathname;
      const hash = window.location.hash;
      const full = path + hash;

      if (full.includes('/display')) {
        setIsDisplayRoute(true);
        const match = full.match(/\/display\/([^/?#]+)/);
        if (match && match[1]) {
          setDisplayOfficeId(match[1]);
        }
      } else {
        setIsDisplayRoute(false);
      }
    };

    checkRoute();
    window.addEventListener('popstate', checkRoute);
    window.addEventListener('hashchange', checkRoute);
    return () => {
      window.removeEventListener('popstate', checkRoute);
      window.removeEventListener('hashchange', checkRoute);
    };
  }, []);

  // If viewing public display lobby board, no auth required
  if (isDisplayRoute) {
    return <DisplayPage officeId={displayOfficeId} />;
  }

  // If not signed in with any persona, render the DevAuth Login Page
  if (!persona) {
    return <LoginPage />;
  }

  const handleOpenDisplay = () => {
    const offId = persona.office_id || 'ward-central-01';
    window.open(`/display/${offId}`, '_blank');
  };

  return (
    <AppShell
      activeNav={activeNav}
      onNavChange={setActiveNav}
      onOpenDisplay={handleOpenDisplay}
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
