import { useState } from 'react';
import { useAuth } from './context/AuthContext';
import { LoginPage } from './pages/LoginPage';
import { OfficerQueuePage } from './pages/OfficerQueuePage';
import { AppShell } from './components/AppShell';

export function App() {
  const { persona } = useAuth();
  const [activeNav, setActiveNav] = useState<'queue' | 'reports'>('queue');

  // If not signed in with any persona, render the DevAuth Login Page
  if (!persona) {
    return <LoginPage />;
  }

  return (
    <AppShell activeNav={activeNav} onNavChange={setActiveNav}>
      {activeNav === 'queue' ? (
        <OfficerQueuePage />
      ) : (
        <div className="card" style={{ maxWidth: '800px', margin: '0 auto', textAlign: 'center', padding: 'var(--space-xl)' }}>
          <span className="material-symbols-outlined" style={{ fontSize: '48px', color: 'var(--color-primary)' }}>
            insights
          </span>
          <h2 style={{ margin: 'var(--space-md) 0 var(--space-xs)' }}>Administrative & Analytics Reports</h2>
          <p style={{ color: 'var(--color-text-secondary)', marginBottom: 'var(--space-md)' }}>
            Summary metrics, load-by-hour curves, and ETA accuracy are available to administrators. (Expanded in Milestone M6b)
          </p>
          <button
            type="button"
            className="action-btn btn-secondary"
            style={{ width: 'auto', margin: '0 auto', padding: '0 24px' }}
            onClick={() => setActiveNav('queue')}
          >
            Return to Active Queue
          </button>
        </div>
      )}
    </AppShell>
  );
}

export default App;
