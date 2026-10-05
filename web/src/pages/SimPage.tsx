import { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { useAuth } from '../context/AuthContext';
import { startSimulation, getSimulationStatus, type SimStatusOut } from '../api/client';

export function SimPage() {
  const { t } = useTranslation();
  const { persona, token } = useAuth();
  const officeId = persona?.office_id || 'ward-central-01';

  const [simStatus, setSimStatus] = useState<SimStatusOut | null>(null);
  const [loading, setLoading] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  // Poll simulation status if running
  useEffect(() => {
    if (!token) return;
    let timer: ReturnType<typeof setTimeout>;

    const checkStatus = async () => {
      try {
        const res = await getSimulationStatus(token, officeId);
        setSimStatus(res);
        if (res.status === 'RUNNING') {
          timer = setTimeout(checkStatus, 2000);
        }
      } catch (err: unknown) {
        console.error('Sim poll error:', err);
      }
    };

    checkStatus();
    return () => clearTimeout(timer);
  }, [token, officeId]);

  const handleStartSim = async () => {
    if (!token) return;
    setLoading(true);
    setError(null);
    try {
      await startSimulation(token, officeId);
      setSimStatus({ office_id: officeId, status: 'RUNNING' });
      // Poll after 1.5s
      setTimeout(async () => {
        const res = await getSimulationStatus(token, officeId);
        setSimStatus(res);
      }, 1500);
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Failed to launch simulation';
      setError(msg);
    } finally {
      setLoading(false);
    }
  };

  const isRunning = simStatus?.status === 'RUNNING';

  return (
    <div className="officer-page">
      {/* Header */}
      <div className="page-header-row">
        <div className="page-header-left">
          <h1>{t('sim.title')}</h1>
          <p>{t('sim.subtitle')}</p>
        </div>

        <div className="page-header-actions">
          <button
            type="button"
            className="btn-call-next"
            onClick={handleStartSim}
            disabled={loading || isRunning}
          >
            <span className="material-symbols-outlined">
              {isRunning ? 'autorenew' : 'play_arrow'}
            </span>
            {isRunning ? t('sim.sim_running') : t('sim.start_sim_btn')}
          </button>
        </div>
      </div>

      {error && <div className="login-error">{error}</div>}

      {/* Simulator Status Overview */}
      <div className="card" style={{ maxWidth: '840px', margin: '0 auto' }}>
        <div className="card-header">
          <div className="card-title-group">
            <span className="material-symbols-outlined" style={{ color: 'var(--color-primary)' }}>
              science
            </span>
            <span className="card-title">Virtual Office Simulation State</span>
          </div>

          <span
            className={`badge-status ${
              isRunning
                ? 'serving'
                : simStatus?.status === 'COMPLETED'
                ? 'arrived'
                : simStatus?.status === 'FAILED'
                ? 'no-show'
                : 'called'
            }`}
            style={{ textTransform: 'uppercase', fontWeight: 700 }}
          >
            {simStatus?.status || 'NOT_STARTED'}
          </span>
        </div>

        {isRunning && (
          <div style={{ textAlign: 'center', padding: 'var(--space-xl) 0' }}>
            <span
              className="material-symbols-outlined"
              style={{
                fontSize: '56px',
                color: 'var(--color-primary)',
                animation: 'spin 1.5s linear infinite',
              }}
            >
              sync
            </span>
            <h3 style={{ marginTop: 'var(--space-md)' }}>Simulating Full Civic Day…</h3>
            <p style={{ color: 'var(--color-text-secondary)', fontSize: 'var(--font-sm)', marginTop: '4px' }}>
              Virtual clock is executing arrival curves, counter breaks, priority requests, and ETA recalculations.
            </p>
          </div>
        )}

        {simStatus?.status === 'COMPLETED' && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-lg)' }}>
            <div style={{ backgroundColor: 'var(--color-success-soft)', color: 'var(--color-success)', padding: 'var(--space-md)', borderRadius: 'var(--radius-md)', fontWeight: 600, display: 'flex', alignItems: 'center', gap: '8px' }}>
              <span className="material-symbols-outlined">check_circle</span>
              {t('sim.sim_completed')} ({simStatus.tick_count} virtual ticks executed)
            </div>

            {/* Metrics Grid */}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 'var(--space-md)' }}>
              <div style={{ backgroundColor: 'var(--color-canvas)', border: '1px solid var(--color-border)', borderRadius: 'var(--radius-md)', padding: 'var(--space-md)', textAlign: 'center' }}>
                <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-muted)', textTransform: 'uppercase', fontWeight: 600 }}>
                  {t('sim.tokens_booked')}
                </div>
                <div style={{ fontSize: '28px', fontWeight: 800, color: 'var(--color-text-primary)', marginTop: '4px' }}>
                  {simStatus.tokens_booked ?? 0}
                </div>
              </div>

              <div style={{ backgroundColor: 'var(--color-canvas)', border: '1px solid var(--color-border)', borderRadius: 'var(--radius-md)', padding: 'var(--space-md)', textAlign: 'center' }}>
                <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-muted)', textTransform: 'uppercase', fontWeight: 600 }}>
                  {t('sim.tokens_served')}
                </div>
                <div style={{ fontSize: '28px', fontWeight: 800, color: 'var(--color-success)', marginTop: '4px' }}>
                  {simStatus.tokens_served ?? 0}
                </div>
              </div>

              <div style={{ backgroundColor: 'var(--color-canvas)', border: '1px solid var(--color-border)', borderRadius: 'var(--radius-md)', padding: 'var(--space-md)', textAlign: 'center' }}>
                <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-muted)', textTransform: 'uppercase', fontWeight: 600 }}>
                  {t('sim.tokens_no_show')}
                </div>
                <div style={{ fontSize: '28px', fontWeight: 800, color: 'var(--color-warning)', marginTop: '4px' }}>
                  {simStatus.tokens_no_show ?? 0}
                </div>
              </div>

              <div style={{ backgroundColor: 'var(--color-canvas)', border: '1px solid var(--color-border)', borderRadius: 'var(--radius-md)', padding: 'var(--space-md)', textAlign: 'center' }}>
                <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-muted)', textTransform: 'uppercase', fontWeight: 600 }}>
                  {t('sim.tokens_cancelled')}
                </div>
                <div style={{ fontSize: '28px', fontWeight: 800, color: 'var(--color-danger)', marginTop: '4px' }}>
                  {simStatus.tokens_cancelled ?? 0}
                </div>
              </div>
            </div>

            {/* Regression Proof Accuracy Comparison */}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 'var(--space-md)' }}>
              <div style={{ backgroundColor: 'var(--color-surface-dim)', border: '1px solid var(--color-border)', borderRadius: 'var(--radius-md)', padding: 'var(--space-md)', textAlign: 'center' }}>
                <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-primary)', textTransform: 'uppercase', fontWeight: 700 }}>
                  {t('sim.mae_live')}
                </div>
                <div style={{ fontSize: '32px', fontWeight: 900, color: 'var(--color-primary)', marginTop: '4px' }}>
                  {simStatus.mae_live != null ? `${simStatus.mae_live}m` : '—'}
                </div>
                <div style={{ fontSize: '11px', color: 'var(--color-text-muted)', marginTop: '4px' }}>
                  Live greedy simulation engine
                </div>
              </div>

              <div style={{ backgroundColor: 'var(--color-secondary-canvas)', border: '1px solid var(--color-border)', borderRadius: 'var(--radius-md)', padding: 'var(--space-md)', textAlign: 'center' }}>
                <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-secondary)', textTransform: 'uppercase', fontWeight: 700 }}>
                  {t('sim.mae_naive')}
                </div>
                <div style={{ fontSize: '32px', fontWeight: 900, color: 'var(--color-text-secondary)', marginTop: '4px' }}>
                  {simStatus.mae_naive != null ? `${simStatus.mae_naive}m` : '—'}
                </div>
                <div style={{ fontSize: '11px', color: 'var(--color-text-muted)', marginTop: '4px' }}>
                  Static queue baseline
                </div>
              </div>

              <div style={{ backgroundColor: 'var(--color-surface-tint)', border: '1px solid var(--color-border)', borderRadius: 'var(--radius-md)', padding: 'var(--space-md)', textAlign: 'center' }}>
                <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-accent)', textTransform: 'uppercase', fontWeight: 700 }}>
                  {t('sim.within_range')}
                </div>
                <div style={{ fontSize: '32px', fontWeight: 900, color: 'var(--color-accent)', marginTop: '4px' }}>
                  {simStatus.within_range_pct != null ? `${simStatus.within_range_pct}%` : '—'}
                </div>
                <div style={{ fontSize: '11px', color: 'var(--color-text-muted)', marginTop: '4px' }}>
                  Tokens called within predicted interval
                </div>
              </div>
            </div>
          </div>
        )}

        {(!simStatus || simStatus.status === 'NOT_STARTED') && (
          <div className="empty-state">
            <span className="material-symbols-outlined empty-icon">play_circle</span>
            <p>No simulation active. Click <strong>Launch Full-Day Simulation</strong> to simulate an 8-hour civic day.</p>
          </div>
        )}
      </div>
    </div>
  );
}
