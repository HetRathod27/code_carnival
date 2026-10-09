import { useState, useMemo, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { useAuth } from '../context/AuthContext';
import { fetchServices, type ServiceOut } from '../api/client';

export interface CompletedTokenRecord {
  id: string;
  display_code: string;
  service_id: string;
  service_name: string;
  beneficiary_name?: string | null;
  outcome_code: string;
  duration_seconds: number;
  completed_at: string;
  officer_note?: string;
  group_size?: number;
  served_count?: number;
}

const STORAGE_ACTIVITY_PREFIX = 'ql_today_activity_';

export function getTodayActivityRecords(officeId: string, counterId: string): CompletedTokenRecord[] {
  try {
    const todayStr = new Date().toISOString().slice(0, 10);
    const key = `${STORAGE_ACTIVITY_PREFIX}${officeId}_${counterId}_${todayStr}`;
    const raw = localStorage.getItem(key);
    if (raw) {
      return JSON.parse(raw);
    }
  } catch (e) {
    console.debug('Failed to load activity records:', e);
  }
  return [];
}

export function saveCompletedActivityRecord(
  officeId: string,
  counterId: string,
  record: CompletedTokenRecord,
): void {
  try {
    const todayStr = new Date().toISOString().slice(0, 10);
    const key = `${STORAGE_ACTIVITY_PREFIX}${officeId}_${counterId}_${todayStr}`;
    const list = getTodayActivityRecords(officeId, counterId);
    // Unshift newest first, deduplicate by id
    const updated = [record, ...list.filter((r) => r.id !== record.id)];
    localStorage.setItem(key, JSON.stringify(updated));
  } catch (e) {
    console.debug('Failed to save activity record:', e);
  }
}

export function TodayActivityPage({ counterId = 'cnt-1' }: { counterId?: string }) {
  const { t, i18n } = useTranslation();
  const { persona } = useAuth();
  const [records, setRecords] = useState<CompletedTokenRecord[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [outcomeFilter, setOutcomeFilter] = useState<string>('ALL');
  const [servicesMap, setServicesMap] = useState<Record<string, string>>({});

  const officeId = persona?.office_id || 'ward-central-01';

  // Load services for localized naming
  useEffect(() => {
    fetchServices(officeId)
      .then((srvs: ServiceOut[]) => {
        const map: Record<string, string> = {};
        srvs.forEach((s) => {
          const names = s.names as Record<string, string>;
          map[s.id] = names[i18n.language] || names['en'] || s.code;
        });
        setServicesMap(map);
      })
      .catch(() => {});
  }, [officeId, i18n.language]);

  // Load records from local storage or initial seeded sample for today
  useEffect(() => {
    let recs = getTodayActivityRecords(officeId, counterId);
    if (recs.length === 0) {
      // Provide initial realistic records so the officer can inspect the screen immediately
      const now = new Date();
      recs = [
        {
          id: 'act-101',
          display_code: 'BC-01',
          service_id: 'srv-bc',
          service_name: 'Birth Certificate',
          beneficiary_name: 'Ramesh Patel',
          outcome_code: 'SERVED',
          duration_seconds: 254,
          completed_at: new Date(now.getTime() - 48 * 60000).toISOString(),
          officer_note: 'Verified original documents and issued physical stamp.',
          group_size: 1,
          served_count: 1,
        },
        {
          id: 'act-102',
          display_code: 'IT-02',
          service_id: 'srv-it',
          service_name: 'Income Certificate',
          beneficiary_name: 'Sunita Sharma',
          outcome_code: 'SERVED',
          duration_seconds: 320,
          completed_at: new Date(now.getTime() - 26 * 60000).toISOString(),
          officer_note: 'Salary certificate cross-checked with IT return copy.',
          group_size: 2,
          served_count: 2,
        },
        {
          id: 'act-103',
          display_code: 'BC-03',
          service_id: 'srv-bc',
          service_name: 'Birth Certificate',
          beneficiary_name: 'Karan Dave',
          outcome_code: 'NO_SHOW',
          duration_seconds: 0,
          completed_at: new Date(now.getTime() - 12 * 60000).toISOString(),
          officer_note: 'Called twice, citizen did not appear at counter.',
        },
      ];
      // Save initial records
      const todayStr = new Date().toISOString().slice(0, 10);
      const key = `${STORAGE_ACTIVITY_PREFIX}${officeId}_${counterId}_${todayStr}`;
      localStorage.setItem(key, JSON.stringify(recs));
    }
    setRecords(recs);
  }, [officeId, counterId]);

  // Summary Metrics
  const metrics = useMemo(() => {
    const servedList = records.filter((r) => r.outcome_code === 'SERVED');
    const noShowList = records.filter((r) => r.outcome_code === 'NO_SHOW');
    const totalDuration = servedList.reduce((acc, r) => acc + (r.duration_seconds || 0), 0);
    const avgSeconds = servedList.length > 0 ? Math.round(totalDuration / servedList.length) : 0;

    const mins = Math.floor(avgSeconds / 60);
    const secs = avgSeconds % 60;
    const avgFormatted = `${mins}m ${secs.toString().padStart(2, '0')}s`;

    return {
      servedCount: servedList.length,
      noShowCount: noShowList.length,
      totalCount: records.length,
      avgServiceTime: avgFormatted,
    };
  }, [records]);

  // Filtered List
  const filteredRecords = useMemo(() => {
    return records.filter((r) => {
      const matchSearch =
        r.display_code.toLowerCase().includes(searchTerm.toLowerCase()) ||
        (r.beneficiary_name && r.beneficiary_name.toLowerCase().includes(searchTerm.toLowerCase())) ||
        r.service_name.toLowerCase().includes(searchTerm.toLowerCase());

      const matchOutcome = outcomeFilter === 'ALL' || r.outcome_code === outcomeFilter;

      return matchSearch && matchOutcome;
    });
  }, [records, searchTerm, outcomeFilter]);

  const formatTimeOnly = (iso: string) => {
    try {
      const d = new Date(iso);
      return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' });
    } catch {
      return iso;
    }
  };

  const formatDuration = (seconds: number) => {
    if (!seconds || seconds <= 0) return '—';
    const m = Math.floor(seconds / 60);
    const s = seconds % 60;
    return `${m}m ${s.toString().padStart(2, '0')}s`;
  };

  return (
    <div className="activity-page" style={{ padding: 'var(--space-lg)', maxWidth: '1280px', margin: '0 auto' }}>
      {/* Header */}
      <div style={{ marginBottom: 'var(--space-lg)' }}>
        <h1 style={{ fontSize: 'var(--font-h1)', fontWeight: 700, color: 'var(--color-primary)', marginBottom: '4px' }}>
          {t('activity.title', "Today's Activity")}
        </h1>
        <p style={{ fontSize: 'var(--font-body)', color: 'var(--color-text-secondary)' }}>
          {t('activity.subtitle', "Comprehensive audit log of tokens handled and service outcomes delivered at your counter today.")}
        </p>
      </div>

      {/* Summary KPI Tiles */}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))',
          gap: 'var(--space-md)',
          marginBottom: 'var(--space-xl)',
        }}
      >
        {/* Served Tile */}
        <div className="kpi-card" style={{ backgroundColor: 'var(--color-surface)', border: '1px solid var(--color-border)', borderRadius: 'var(--radius-md)', padding: 'var(--space-md)' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '8px' }}>
            <span style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-muted)', fontWeight: 600 }}>
              {t('activity.kpi_served', 'Tokens Served')}
            </span>
            <span className="material-symbols-outlined icon-md" style={{ color: 'var(--color-success)' }}>
              check_circle
            </span>
          </div>
          <div style={{ fontSize: 'var(--font-display)', fontWeight: 700, color: 'var(--color-text-primary)' }}>
            {metrics.servedCount}
          </div>
          <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-muted)', marginTop: '4px' }}>
            Completed counter services
          </div>
        </div>

        {/* Average Service Time Tile */}
        <div className="kpi-card" style={{ backgroundColor: 'var(--color-surface)', border: '1px solid var(--color-border)', borderRadius: 'var(--radius-md)', padding: 'var(--space-md)' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '8px' }}>
            <span style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-muted)', fontWeight: 600 }}>
              {t('activity.kpi_avg_time', 'Average Service Time')}
            </span>
            <span className="material-symbols-outlined icon-md" style={{ color: 'var(--color-primary)' }}>
              timer
            </span>
          </div>
          <div style={{ fontSize: 'var(--font-display)', fontWeight: 700, color: 'var(--color-text-primary)' }}>
            {metrics.avgServiceTime}
          </div>
          <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-muted)', marginTop: '4px' }}>
            Target: 10m 00s benchmark
          </div>
        </div>

        {/* No-Shows Tile */}
        <div className="kpi-card" style={{ backgroundColor: 'var(--color-surface)', border: '1px solid var(--color-border)', borderRadius: 'var(--radius-md)', padding: 'var(--space-md)' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '8px' }}>
            <span style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-muted)', fontWeight: 600 }}>
              {t('activity.kpi_noshow', 'No-Shows')}
            </span>
            <span className="material-symbols-outlined icon-md" style={{ color: 'var(--color-danger)' }}>
              person_off
            </span>
          </div>
          <div style={{ fontSize: 'var(--font-display)', fontWeight: 700, color: 'var(--color-text-primary)' }}>
            {metrics.noShowCount}
          </div>
          <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-muted)', marginTop: '4px' }}>
            Citizen failed to appear within grace period
          </div>
        </div>
      </div>

      {/* Filter and Search Bar */}
      <div
        className="card"
        style={{
          backgroundColor: 'var(--color-surface)',
          border: '1px solid var(--color-border)',
          borderRadius: 'var(--radius-md)',
          padding: 'var(--space-md)',
          marginBottom: 'var(--space-md)',
          display: 'flex',
          gap: 'var(--space-md)',
          alignItems: 'center',
          flexWrap: 'wrap',
          justifyContent: 'space-between',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px', flex: '1 1 300px' }}>
          <span className="material-symbols-outlined icon-sm" style={{ color: 'var(--color-text-muted)' }}>
            search
          </span>
          <input
            type="search"
            aria-label="Search today's activity tokens"
            placeholder={t('activity.search_placeholder', 'Search by token code, citizen name or service…')}
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            style={{
              width: '100%',
              padding: '10px 14px',
              border: '1px solid var(--color-border)',
              borderRadius: 'var(--radius-sm)',
              fontSize: 'var(--font-body)',
              outline: 'none',
            }}
          />
        </div>

        {/* Outcome Filter Pills */}
        <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap' }}>
          {(['ALL', 'SERVED', 'NO_SHOW', 'MISSING_DOCS', 'WRONG_SERVICE'] as const).map((code) => (
            <button
              key={code}
              type="button"
              onClick={() => setOutcomeFilter(code)}
              style={{
                height: '40px',
                padding: '0 14px',
                borderRadius: 'var(--radius-sm)',
                fontSize: 'var(--font-sm)',
                fontWeight: 600,
                border: '1px solid',
                borderColor: outcomeFilter === code ? 'var(--color-primary)' : 'var(--color-border)',
                backgroundColor: outcomeFilter === code ? 'var(--color-primary-soft)' : 'var(--color-surface)',
                color: outcomeFilter === code ? 'var(--color-primary)' : 'var(--color-text-secondary)',
              }}
            >
              {code === 'ALL' ? 'All Outcomes' : code}
            </button>
          ))}
        </div>
      </div>

      {/* Activity Table */}
      <div
        className="card"
        style={{
          backgroundColor: 'var(--color-surface)',
          border: '1px solid var(--color-border)',
          borderRadius: 'var(--radius-md)',
          overflow: 'hidden',
        }}
      >
        {filteredRecords.length === 0 ? (
          <div style={{ padding: 'var(--space-xl)', textAlign: 'center', color: 'var(--color-text-muted)' }}>
            <span className="material-symbols-outlined icon-lg" style={{ fontSize: '48px', marginBottom: '8px', opacity: 0.5 }}>
              inbox
            </span>
            <p style={{ fontSize: 'var(--font-body)', fontWeight: 600 }}>
              {t('activity.no_records', 'No activity records match your filter.')}
            </p>
          </div>
        ) : (
          <div style={{ overflowX: 'auto' }}>
            <table className="queue-table" style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
              <thead>
                <tr style={{ borderBottom: '1px solid var(--color-border)', backgroundColor: 'var(--color-secondary-canvas)' }}>
                  <th style={{ padding: '14px 16px', fontSize: 'var(--font-sm)', fontWeight: 700 }}>Token</th>
                  <th style={{ padding: '14px 16px', fontSize: 'var(--font-sm)', fontWeight: 700 }}>Service</th>
                  <th style={{ padding: '14px 16px', fontSize: 'var(--font-sm)', fontWeight: 700 }}>Outcome</th>
                  <th style={{ padding: '14px 16px', fontSize: 'var(--font-sm)', fontWeight: 700 }}>Duration</th>
                  <th style={{ padding: '14px 16px', fontSize: 'var(--font-sm)', fontWeight: 700 }}>Time</th>
                  <th style={{ padding: '14px 16px', fontSize: 'var(--font-sm)', fontWeight: 700 }}>Note / Details</th>
                </tr>
              </thead>
              <tbody>
                {filteredRecords.map((r) => {
                  const sName = servicesMap[r.service_id] || r.service_name;
                  const isServed = r.outcome_code === 'SERVED';
                  const isNoShow = r.outcome_code === 'NO_SHOW';

                  return (
                    <tr
                      key={r.id}
                      style={{
                        borderBottom: '1px solid var(--color-border-subtle)',
                        fontSize: 'var(--font-body)',
                      }}
                    >
                      <td style={{ padding: '14px 16px' }}>
                        <div style={{ fontWeight: 700, color: 'var(--color-primary)' }}>{r.display_code}</div>
                        {r.beneficiary_name && (
                          <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-muted)' }}>
                            {r.beneficiary_name}
                          </div>
                        )}
                      </td>
                      <td style={{ padding: '14px 16px', color: 'var(--color-text-primary)' }}>
                        {sName}
                      </td>
                      <td style={{ padding: '14px 16px' }}>
                        <span
                          style={{
                            display: 'inline-flex',
                            alignItems: 'center',
                            gap: '4px',
                            padding: '4px 10px',
                            borderRadius: 'var(--radius-sm)',
                            fontSize: 'var(--font-xs)',
                            fontWeight: 700,
                            backgroundColor: isServed
                              ? 'var(--color-success-soft)'
                              : isNoShow
                              ? 'var(--color-danger-soft)'
                              : 'var(--color-warning-soft)',
                            color: isServed
                              ? 'var(--color-success)'
                              : isNoShow
                              ? 'var(--color-danger)'
                              : 'var(--color-warning)',
                          }}
                        >
                          <span className="material-symbols-outlined" style={{ fontSize: '13px' }}>
                            {isServed ? 'check_circle' : isNoShow ? 'person_off' : 'info'}
                          </span>
                          {r.outcome_code}
                          {r.group_size && r.group_size > 1 && (
                            <span style={{ opacity: 0.9 }}>
                              ({r.served_count ?? r.group_size}/{r.group_size})
                            </span>
                          )}
                        </span>
                      </td>
                      <td style={{ padding: '14px 16px', fontVariantNumeric: 'tabular-nums', color: 'var(--color-text-secondary)' }}>
                        {formatDuration(r.duration_seconds)}
                      </td>
                      <td style={{ padding: '14px 16px', fontVariantNumeric: 'tabular-nums', color: 'var(--color-text-muted)' }}>
                        {formatTimeOnly(r.completed_at)}
                      </td>
                      <td style={{ padding: '14px 16px', color: 'var(--color-text-secondary)', fontSize: 'var(--font-sm)', maxWidth: '280px' }}>
                        {r.officer_note || '—'}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}
