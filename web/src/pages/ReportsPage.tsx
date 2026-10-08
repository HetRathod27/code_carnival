import { useState, useEffect, useCallback } from 'react';
import { useTranslation } from 'react-i18next';
import { useAuth } from '../context/AuthContext';
import {
  fetchReportSummary,
  fetchReportLoadByHour,
  fetchReportEtaAccuracy,
  type SummaryReportOut,
  type LoadByHourOut,
  type EtaAccuracyOut,
} from '../api/client';

export function ReportsPage() {
  const { t } = useTranslation();
  const { persona, token } = useAuth();
  const officeId = persona?.office_id || 'ward-central-01';

  const [reportDate, setReportDate] = useState<string>(() => {
    return new Date().toISOString().split('T')[0];
  });

  const [summary, setSummary] = useState<SummaryReportOut | null>(null);
  const [loadByHour, setLoadByHour] = useState<LoadByHourOut | null>(null);
  const [etaAccuracy, setEtaAccuracy] = useState<EtaAccuracyOut | null>(null);

  const [loading, setLoading] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  const loadReports = useCallback(async () => {
    if (!token) return;
    setLoading(true);
    setError(null);
    try {
      const [sumRes, loadRes, etaRes] = await Promise.all([
        fetchReportSummary(token, officeId, reportDate).catch(() => null),
        fetchReportLoadByHour(token, officeId, reportDate).catch(() => null),
        fetchReportEtaAccuracy(token, officeId, reportDate).catch(() => null),
      ]);
      setSummary(sumRes);
      setLoadByHour(loadRes);
      setEtaAccuracy(etaRes);
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Failed to load reports';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, [token, officeId, reportDate]);

  useEffect(() => {
    loadReports();
  }, [loadReports]);

  // Aggregate totals from summary
  const totalServed = summary?.services.reduce((acc, s) => acc + s.served, 0) ?? 0;
  const totalCancelled = summary?.services.reduce((acc, s) => acc + s.cancelled, 0) ?? 0;
  const totalNoShow = summary?.services.reduce((acc, s) => acc + s.no_show, 0) ?? 0;
  const totalExpired = summary?.services.reduce((acc, s) => acc + s.expired, 0) ?? 0;
  const totalWaiting = summary?.services.reduce((acc, s) => acc + s.waiting, 0) ?? 0;

  const validWaits = summary?.services.map((s) => s.avg_wait_minutes).filter((w): w is number => w != null) ?? [];
  const overallAvgWait = validWaits.length > 0 ? (validWaits.reduce((a, b) => a + b, 0) / validWaits.length).toFixed(1) : '—';

  // Live engine MAE vs Naive MAE
  const liveRow = etaAccuracy?.engines.find((e) => e.engine === 'live_adjusted');
  const liveMae = liveRow?.mae_minutes != null ? liveRow.mae_minutes : null;
  const naiveMae = etaAccuracy?.naive_mae != null ? etaAccuracy.naive_mae : null;
  const withinRangePct = liveRow?.within_range_pct != null ? liveRow.within_range_pct : null;

  return (
    <div className="officer-page">
      {/* Top Header */}
      <div className="page-header-row">
        <div className="page-header-left">
          <h1>{t('reports.title')}</h1>
          <p>{t('reports.subtitle')}</p>
        </div>

        <div className="page-header-actions">
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <label style={{ fontSize: 'var(--font-sm)', fontWeight: 600 }}>{t('reports.select_date')}:</label>
            <input
              type="date"
              className="form-input"
              style={{ height: '38px' }}
              value={reportDate}
              onChange={(e) => setReportDate(e.target.value)}
            />
            <button
              type="button"
              className="action-btn btn-secondary"
              style={{ height: '38px', padding: '0 16px' }}
              onClick={loadReports}
              disabled={loading}
            >
              <span className="material-symbols-outlined icon-sm">refresh</span>
              {t('reports.refresh_btn')}
            </button>
          </div>
        </div>
      </div>

      {error && <div className="login-error">{error}</div>}

      {/* KPI Cards Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: 'var(--space-md)' }}>
        <div className="card" style={{ padding: 'var(--space-md)', textAlign: 'center' }}>
          <div style={{ fontSize: 'var(--font-xs)', fontWeight: 700, textTransform: 'uppercase', color: 'var(--color-success)' }}>
            {t('reports.total_served')}
          </div>
          <div style={{ fontSize: '36px', fontWeight: 800, color: 'var(--color-text-primary)', marginTop: '4px' }}>
            {totalServed}
          </div>
        </div>

        <div className="card" style={{ padding: 'var(--space-md)', textAlign: 'center' }}>
          <div style={{ fontSize: 'var(--font-xs)', fontWeight: 700, textTransform: 'uppercase', color: 'var(--color-primary)' }}>
            {t('reports.avg_wait')}
          </div>
          <div style={{ fontSize: '36px', fontWeight: 800, color: 'var(--color-text-primary)', marginTop: '4px' }}>
            {overallAvgWait} <span style={{ fontSize: '16px', fontWeight: 500 }}>min</span>
          </div>
        </div>

        <div className="card" style={{ padding: 'var(--space-md)', textAlign: 'center' }}>
          <div style={{ fontSize: 'var(--font-xs)', fontWeight: 700, textTransform: 'uppercase', color: 'var(--color-warning)' }}>
            {t('reports.total_no_show')}
          </div>
          <div style={{ fontSize: '36px', fontWeight: 800, color: 'var(--color-text-primary)', marginTop: '4px' }}>
            {totalNoShow}
          </div>
        </div>

        <div className="card" style={{ padding: 'var(--space-md)', textAlign: 'center' }}>
          <div style={{ fontSize: 'var(--font-xs)', fontWeight: 700, textTransform: 'uppercase', color: 'var(--color-danger)' }}>
            {t('reports.total_cancelled')}
          </div>
          <div style={{ fontSize: '36px', fontWeight: 800, color: 'var(--color-text-primary)', marginTop: '4px' }}>
            {totalCancelled}
          </div>
        </div>

        <div className="card" style={{ padding: 'var(--space-md)', textAlign: 'center' }}>
          <div style={{ fontSize: 'var(--font-xs)', fontWeight: 700, textTransform: 'uppercase', color: 'var(--color-primary)' }}>
            Waiting in Queue
          </div>
          <div style={{ fontSize: '36px', fontWeight: 800, color: 'var(--color-primary)', marginTop: '4px' }}>
            {totalWaiting}
          </div>
        </div>

        <div className="card" style={{ padding: 'var(--space-md)', textAlign: 'center' }}>
          <div style={{ fontSize: 'var(--font-xs)', fontWeight: 700, textTransform: 'uppercase', color: 'var(--color-text-muted)' }}>
            {t('reports.total_expired')}
          </div>
          <div style={{ fontSize: '36px', fontWeight: 800, color: 'var(--color-text-primary)', marginTop: '4px' }}>
            {totalExpired}
          </div>
        </div>
      </div>

      {/* ETA Engine Accuracy Benchmark Card */}
      <div className="card">
        <div className="card-header">
          <div className="card-title-group">
            <span className="material-symbols-outlined" style={{ color: 'var(--color-primary)' }}>
              speed
            </span>
            <span className="card-title">{t('reports.eta_accuracy_title')}</span>
          </div>
          {liveMae != null && naiveMae != null && liveMae <= naiveMae && (
            <span style={{ fontSize: 'var(--font-xs)', fontWeight: 700, color: 'var(--color-success)', backgroundColor: 'var(--color-success-soft)', padding: '4px 12px', borderRadius: 'var(--radius-full)' }}>
              {t('reports.accuracy_superior')}
            </span>
          )}
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: 'var(--space-lg)', padding: 'var(--space-sm) 0' }}>
          <div style={{ backgroundColor: 'var(--color-surface-dim)', padding: 'var(--space-md)', borderRadius: 'var(--radius-md)' }}>
            <div style={{ fontSize: 'var(--font-xs)', fontWeight: 700, textTransform: 'uppercase', color: 'var(--color-primary)' }}>
              {t('reports.live_engine')}
            </div>
            <div style={{ fontSize: '32px', fontWeight: 800, color: 'var(--color-primary)', marginTop: '4px' }}>
              {liveMae != null ? `${liveMae}m` : 'Evaluating…'}
            </div>
            <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-muted)', marginTop: '4px' }}>
              Live counter state + overrun rule (Section 19.3)
            </div>
          </div>

          <div style={{ backgroundColor: 'var(--color-secondary-canvas)', padding: 'var(--space-md)', borderRadius: 'var(--radius-md)' }}>
            <div style={{ fontSize: 'var(--font-xs)', fontWeight: 700, textTransform: 'uppercase', color: 'var(--color-text-secondary)' }}>
              {t('reports.naive_engine')}
            </div>
            <div style={{ fontSize: '32px', fontWeight: 800, color: 'var(--color-text-secondary)', marginTop: '4px' }}>
              {naiveMae != null ? `${naiveMae}m` : 'Evaluating…'}
            </div>
            <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-muted)', marginTop: '4px' }}>
              Static queue index * prior mean / open counters
            </div>
          </div>

          <div style={{ backgroundColor: 'var(--color-surface-tint)', padding: 'var(--space-md)', borderRadius: 'var(--radius-md)' }}>
            <div style={{ fontSize: 'var(--font-xs)', fontWeight: 700, textTransform: 'uppercase', color: 'var(--color-accent)' }}>
              {t('reports.within_range_pct')}
            </div>
            <div style={{ fontSize: '32px', fontWeight: 800, color: 'var(--color-accent)', marginTop: '4px' }}>
              {withinRangePct != null ? `${withinRangePct}%` : 'Evaluating…'}
            </div>
            <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-muted)', marginTop: '4px' }}>
              Actual service wait within [p25, p75] confidence bounds
            </div>
          </div>
        </div>
      </div>

      {/* Hourly Queue Load (Booked vs Served) Chart */}
      <div className="card">
        <div className="card-header">
          <div className="card-title-group">
            <span className="material-symbols-outlined" style={{ color: 'var(--color-primary)' }}>
              bar_chart
            </span>
            <span className="card-title">{t('reports.hourly_load_title')}</span>
          </div>
        </div>

        {loadByHour?.hourly && loadByHour.hourly.length > 0 ? (
          <div style={{ overflowX: 'auto', padding: 'var(--space-md) 0' }}>
            {/* Responsive visual bar chart */}
            <div style={{ display: 'flex', alignItems: 'flex-end', gap: '20px', minWidth: '600px', height: '180px', paddingBottom: '30px', borderBottom: '1px solid var(--color-border)', position: 'relative' }}>
              {loadByHour.hourly.map((item, idx) => {
                const hourLabel = item.hour_bucket
                  ? new Date(item.hour_bucket).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
                  : `H${idx + 1}`;
                const maxVal = Math.max(
                  ...loadByHour.hourly.map((h) => Math.max(h.tokens_booked, h.tokens_served)),
                  1
                );
                const bookedHeight = Math.max((item.tokens_booked / maxVal) * 120, 6);
                const servedHeight = Math.max((item.tokens_served / maxVal) * 120, 6);

                return (
                  <div key={idx} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '4px' }}>
                    <div style={{ display: 'flex', alignItems: 'flex-end', gap: '4px', height: '120px' }}>
                      {/* Booked bar */}
                      <div
                        title={`Booked: ${item.tokens_booked}`}
                        style={{
                          width: '16px',
                          height: `${bookedHeight}px`,
                          backgroundColor: 'var(--color-accent)',
                          borderRadius: '4px 4px 0 0',
                          transition: 'height 0.3s ease',
                        }}
                      />
                      {/* Served bar */}
                      <div
                        title={`Served: ${item.tokens_served}`}
                        style={{
                          width: '16px',
                          height: `${servedHeight}px`,
                          backgroundColor: 'var(--color-success)',
                          borderRadius: '4px 4px 0 0',
                          transition: 'height 0.3s ease',
                        }}
                      />
                    </div>
                    <span style={{ fontSize: '11px', color: 'var(--color-text-secondary)', marginTop: '8px', whiteSpace: 'nowrap' }}>
                      {hourLabel}
                    </span>
                  </div>
                );
              })}
            </div>
            {/* Chart Legend */}
            <div style={{ display: 'flex', justifyContent: 'center', gap: '24px', marginTop: '16px', fontSize: 'var(--font-xs)', fontWeight: 600 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                <span style={{ width: '12px', height: '12px', backgroundColor: 'var(--color-accent)', borderRadius: '2px' }} />
                <span>Tokens Booked</span>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                <span style={{ width: '12px', height: '12px', backgroundColor: 'var(--color-success)', borderRadius: '2px' }} />
                <span>Tokens Served</span>
              </div>
            </div>
          </div>
        ) : (
          <div className="empty-state">
            <span className="material-symbols-outlined empty-icon">analytics</span>
            <p>No hourly queue load records for the selected date.</p>
          </div>
        )}
      </div>

      {/* Service Breakdown Table */}
      <div className="card">
        <div className="card-header">
          <div className="card-title-group">
            <span className="material-symbols-outlined" style={{ color: 'var(--color-primary)' }}>
              table_chart
            </span>
            <span className="card-title">Service Level Breakdown</span>
          </div>
        </div>

        <table className="queue-table">
          <thead>
            <tr>
              <th>Service</th>
              <th>Served</th>
              <th>Cancelled</th>
              <th>No-Show</th>
              <th>Avg Wait</th>
              <th>P90 Wait</th>
              <th>Avg Service</th>
              <th>Priority Ratio</th>
            </tr>
          </thead>
          <tbody>
            {summary?.services.map((svc) => (
              <tr key={svc.service_id}>
                <td><strong>{svc.service_id}</strong></td>
                <td>{svc.served}</td>
                <td>{svc.cancelled}</td>
                <td>{svc.no_show}</td>
                <td>{svc.avg_wait_minutes != null ? `${svc.avg_wait_minutes}m` : '—'}</td>
                <td>{svc.p90_wait_minutes != null ? `${svc.p90_wait_minutes}m` : '—'}</td>
                <td>{svc.avg_service_minutes != null ? `${svc.avg_service_minutes}m` : '—'}</td>
                <td>
                  <span className="badge-category">
                    {svc.priority_count} ({svc.priority_rejected} rejected)
                  </span>
                </td>
              </tr>
            ))}
            {(!summary?.services || summary.services.length === 0) && (
              <tr>
                <td colSpan={8} style={{ textAlign: 'center', padding: 'var(--space-lg)', color: 'var(--color-text-muted)' }}>
                  No service records recorded for {reportDate}
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
