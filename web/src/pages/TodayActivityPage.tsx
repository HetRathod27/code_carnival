import { useState, useMemo, useEffect, useCallback } from 'react';
import { useTranslation } from 'react-i18next';
import { useAuth } from '../context/AuthContext';
import { fetchServices, fetchCounterActivity, type ServiceOut, type CounterActivityItem } from '../api/client';

export interface CompletedTokenRecord {
  id: string;
  display_code: string;
  service_id: string;
  service_name: string;
  counter_id?: string | null;
  beneficiary_name?: string | null;
  outcome_code: string;
  duration_seconds: number;
  completed_at: string;
  officer_note?: string | null;
  group_size?: number;
  served_count?: number;
}

const STORAGE_ACTIVITY_PREFIX = 'ql_today_activity_';

export function getTodayActivityRecords(officeId: string, counterId: string): CompletedTokenRecord[] {
  try {
    const todayStr = new Date().toISOString().slice(0, 10);
    if (counterId === 'all') {
      const all: CompletedTokenRecord[] = [];
      const seenIds = new Set<string>();
      for (let i = 1; i <= 5; i++) {
        const cKey = `${STORAGE_ACTIVITY_PREFIX}${officeId}_cnt-${i}_${todayStr}`;
        const raw = localStorage.getItem(cKey);
        if (raw) {
          try {
            const list: CompletedTokenRecord[] = JSON.parse(raw);
            list.forEach((item) => {
              if (!seenIds.has(item.id)) {
                seenIds.add(item.id);
                all.push(item);
              }
            });
          } catch {}
        }
      }
      return all.sort((a, b) => new Date(b.completed_at).getTime() - new Date(a.completed_at).getTime());
    }

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
    // Dispatch custom event for immediate reactive refresh across the portal
    window.dispatchEvent(new CustomEvent('today-activity-updated', { detail: { counterId, record } }));
  } catch (e) {
    console.debug('Failed to save activity record:', e);
  }
}

export function TodayActivityPage({ counterId: initialCounterId }: { counterId?: string }) {
  const { t, i18n } = useTranslation();
  const { token, persona } = useAuth();
  const officeId = persona?.office_id || 'ward-central-01';

  // Workstation counter selector state
  const [selectedCounter, setSelectedCounter] = useState<string>(() => {
    return initialCounterId || localStorage.getItem('ql_default_counter') || 'cnt-1';
  });

  const [records, setRecords] = useState<CompletedTokenRecord[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [outcomeFilter, setOutcomeFilter] = useState<string>('ALL');
  const [servicesMap, setServicesMap] = useState<Record<string, string>>({});
  const [lastRefreshedAt, setLastRefreshedAt] = useState<Date>(new Date());
  const [isRefreshing, setIsRefreshing] = useState(false);

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

  // Load records from local storage and backend API
  const loadRecords = useCallback(async () => {
    setIsRefreshing(true);
    try {
      // 1. Immediately read local cache
      const localRecs = getTodayActivityRecords(officeId, selectedCounter);
      const localMap = new Map<string, CompletedTokenRecord>();
      localRecs.forEach((r) => localMap.set(r.id, r));

      // 2. Fetch live from backend API if authenticated
      if (token) {
        try {
          const apiRecs: CounterActivityItem[] = await fetchCounterActivity(token, selectedCounter);
          apiRecs.forEach((ar) => {
            const existing = localMap.get(ar.id);
            localMap.set(ar.id, {
              id: ar.id,
              display_code: ar.display_code,
              service_id: ar.service_id,
              service_name: ar.service_name,
              counter_id: ar.counter_id || selectedCounter,
              beneficiary_name: ar.beneficiary_name || existing?.beneficiary_name || null,
              outcome_code: ar.outcome_code,
              duration_seconds: ar.duration_seconds || existing?.duration_seconds || 0,
              completed_at: ar.completed_at,
              officer_note: ar.officer_note || existing?.officer_note || null,
              group_size: ar.group_size || existing?.group_size || 1,
              served_count: ar.served_count || existing?.served_count || 1,
            });
          });
        } catch (apiErr) {
          console.debug('Backend activity fetch failed, relying on local records:', apiErr);
        }
      }

      const merged = Array.from(localMap.values()).sort(
        (a, b) => new Date(b.completed_at).getTime() - new Date(a.completed_at).getTime(),
      );

      setRecords(merged);
      setLastRefreshedAt(new Date());

      // Persist merged cache locally if a single counter is selected
      if (selectedCounter !== 'all' && merged.length > 0) {
        const todayStr = new Date().toISOString().slice(0, 10);
        const key = `${STORAGE_ACTIVITY_PREFIX}${officeId}_${selectedCounter}_${todayStr}`;
        localStorage.setItem(key, JSON.stringify(merged));
      }
    } finally {
      setIsRefreshing(false);
    }
  }, [officeId, selectedCounter, token]);

  // Initial load and reload upon counter switch
  useEffect(() => {
    loadRecords();
  }, [loadRecords]);

  // Listen to live events dispatched when a token is completed or updated
  useEffect(() => {
    const handleUpdate = (e: Event) => {
      const customEvent = e as CustomEvent;
      if (!customEvent.detail || customEvent.detail.counterId === selectedCounter || selectedCounter === 'all') {
        loadRecords();
      }
    };

    window.addEventListener('today-activity-updated', handleUpdate);
    window.addEventListener('storage', handleUpdate);
    const interval = setInterval(loadRecords, 15000);

    return () => {
      window.removeEventListener('today-activity-updated', handleUpdate);
      window.removeEventListener('storage', handleUpdate);
      clearInterval(interval);
    };
  }, [loadRecords, selectedCounter]);

  // Handle counter switch
  const handleCounterChange = (newCounter: string) => {
    setSelectedCounter(newCounter);
    if (newCounter !== 'all') {
      localStorage.setItem('ql_default_counter', newCounter);
    }
  };

  // Summary Metrics for this counter
  const metrics = useMemo(() => {
    const servedList = records.filter((r) => r.outcome_code === 'SERVED');
    const noShowList = records.filter((r) => r.outcome_code === 'NO_SHOW');
    const otherList = records.filter((r) => r.outcome_code !== 'SERVED' && r.outcome_code !== 'NO_SHOW');
    const totalDuration = servedList.reduce((acc, r) => acc + (r.duration_seconds || 0), 0);
    const avgSeconds = servedList.length > 0 ? Math.round(totalDuration / servedList.length) : 0;

    const mins = Math.floor(avgSeconds / 60);
    const secs = avgSeconds % 60;
    const avgFormatted = `${mins}m ${secs.toString().padStart(2, '0')}s`;

    const totalHours = Math.floor(totalDuration / 3600);
    const totalMins = Math.floor((totalDuration % 3600) / 60);
    const totalTimeFormatted = totalHours > 0 ? `${totalHours}h ${totalMins}m` : `${totalMins}m ${totalDuration % 60}s`;

    const validDurations = servedList.map((r) => r.duration_seconds).filter((s) => s > 0);
    const fastestSeconds = validDurations.length > 0 ? Math.min(...validDurations) : 0;
    const fastestFormatted = fastestSeconds > 0 ? `${Math.floor(fastestSeconds / 60)}m ${fastestSeconds % 60}s` : '—';

    return {
      servedCount: servedList.length,
      noShowCount: noShowList.length,
      otherCount: otherList.length,
      totalCount: records.length,
      avgServiceTime: avgFormatted,
      totalServingTime: totalTimeFormatted,
      fastestServiceTime: fastestFormatted,
    };
  }, [records]);

  // Hourly Performance Breakdown Report (Time of Day distribution)
  const hourlyReport = useMemo(() => {
    // Generate buckets from 09:00 to 18:00
    const buckets: { hour: number; label: string; served: number; noShow: number; total: number }[] = [];
    for (let h = 9; h <= 18; h++) {
      const nextH = h + 1;
      const formatH = (hour: number) => {
        const period = hour >= 12 ? 'PM' : 'AM';
        const displayH = hour % 12 === 0 ? 12 : hour % 12;
        return `${displayH}:00 ${period}`;
      };
      buckets.push({
        hour: h,
        label: `${formatH(h)} - ${formatH(nextH)}`,
        served: 0,
        noShow: 0,
        total: 0,
      });
    }

    records.forEach((r) => {
      try {
        const d = new Date(r.completed_at);
        const h = d.getHours();
        const bucket = buckets.find((b) => b.hour === h);
        if (bucket) {
          bucket.total += 1;
          if (r.outcome_code === 'SERVED') bucket.served += 1;
          if (r.outcome_code === 'NO_SHOW') bucket.noShow += 1;
        }
      } catch {}
    });

    const maxVolume = Math.max(1, ...buckets.map((b) => b.total));

    // Return buckets that either have activity or are within typical core civic hours (9 to 17)
    return {
      slots: buckets.filter((b) => b.total > 0 || (b.hour >= 9 && b.hour <= 17)),
      maxVolume,
      hasAnyActivity: buckets.some((b) => b.total > 0),
    };
  }, [records]);

  // Filtered List for Table
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

  // Export shift report as CSV
  const handleExportCSV = () => {
    if (records.length === 0) return;
    const header = ['Token Code', 'Citizen Name', 'Service', 'Counter', 'Outcome', 'Duration Seconds', 'Completed Time', 'Officer Note'];
    const rows = records.map((r) => [
      `"${r.display_code}"`,
      `"${r.beneficiary_name || ''}"`,
      `"${r.service_name}"`,
      `"${r.counter_id || selectedCounter}"`,
      `"${r.outcome_code}"`,
      r.duration_seconds || 0,
      `"${r.completed_at}"`,
      `"${(r.officer_note || '').replace(/"/g, '""')}"`,
    ]);
    const csvContent = 'data:text/csv;charset=utf-8,' + [header.join(','), ...rows.map((e) => e.join(','))].join('\n');
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement('a');
    link.setAttribute('href', encodedUri);
    link.setAttribute('download', `shift_report_${selectedCounter}_${new Date().toISOString().slice(0, 10)}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  const getCounterLabel = (cid: string) => {
    if (cid === 'cnt-1') return t('officer.counter_1_opt', 'Counter 1 · Birth & Death Certificate');
    if (cid === 'cnt-2') return t('officer.counter_2_opt', 'Counter 2 · Property Tax Payment & Assessment');
    if (cid === 'cnt-3') return t('officer.counter_3_opt', 'Counter 3 · Property Tax Assessment & Payment');
    if (cid === 'cnt-4') return t('officer.counter_4_opt', 'Counter 4 · Trade License & Shop Registration');
    if (cid === 'cnt-5') return t('officer.counter_5_opt', 'Counter 5 · RTI Application & Civic Grievances');
    if (cid === 'all') return t('activity.all_counters', 'All Counters (Facility Summary)');
    return cid;
  };

  return (
    <div className="activity-page" style={{ padding: 'var(--space-lg)', maxWidth: '1280px', margin: '0 auto' }}>
      {/* Top Header & Workstation Counter Selector */}
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'flex-start',
          flexWrap: 'wrap',
          gap: 'var(--space-md)',
          marginBottom: 'var(--space-lg)',
        }}
      >
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '4px' }}>
            <h1 style={{ fontSize: 'var(--font-h1)', fontWeight: 700, color: 'var(--color-primary)', margin: 0 }}>
              {t('activity.title', "Today's Counter Activity & Reports")}
            </h1>
            <span
              style={{
                backgroundColor: 'var(--color-primary-soft)',
                color: 'var(--color-primary)',
                fontSize: 'var(--font-xs)',
                fontWeight: 700,
                padding: '2px 8px',
                borderRadius: 'var(--radius-full)',
                display: 'inline-flex',
                alignItems: 'center',
                gap: '4px',
              }}
            >
              <span className="material-symbols-outlined" style={{ fontSize: '14px' }}>point_of_sale</span>
              {selectedCounter === 'all' ? 'All Counters' : selectedCounter.toUpperCase()}
            </span>
          </div>
          <p style={{ fontSize: 'var(--font-body)', color: 'var(--color-text-secondary)', margin: 0 }}>
            {t('activity.subtitle', 'Real-time audit log of tokens handled, service durations, and operational reports for this workstation.')}
          </p>
        </div>

        {/* Counter Dropdown & Action Controls */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px', flexWrap: 'wrap' }}>
          {/* Specific Counter Selector */}
          <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
            <label htmlFor="counter-select-activity" style={{ fontSize: 'var(--font-sm)', fontWeight: 600, color: 'var(--color-text-secondary)' }}>
              {t('activity.select_counter', 'Counter')}:
            </label>
            <select
              id="counter-select-activity"
              value={selectedCounter}
              onChange={(e) => handleCounterChange(e.target.value)}
              style={{
                height: '40px',
                padding: '0 12px',
                borderRadius: 'var(--radius-sm)',
                border: '1px solid var(--color-border)',
                backgroundColor: 'var(--color-surface)',
                fontSize: 'var(--font-body)',
                fontWeight: 600,
                color: 'var(--color-text-primary)',
                outline: 'none',
                cursor: 'pointer',
              }}
            >
              <option value="cnt-1">{t('officer.counter_1_opt', 'Counter 1 · Birth & Death Certificate')}</option>
              <option value="cnt-2">{t('officer.counter_2_opt', 'Counter 2 · Property Tax Payment & Assessment')}</option>
              <option value="cnt-3">{t('officer.counter_3_opt', 'Counter 3 · Property Tax Assessment & Payment')}</option>
              <option value="cnt-4">{t('officer.counter_4_opt', 'Counter 4 · Trade License & Shop Registration')}</option>
              <option value="cnt-5">{t('officer.counter_5_opt', 'Counter 5 · RTI Application & Civic Grievances')}</option>
              <option value="all">{t('activity.all_counters', 'All Counters (Facility Summary)')}</option>
            </select>
          </div>

          {/* Refresh Button */}
          <button
            type="button"
            onClick={loadRecords}
            disabled={isRefreshing}
            title={t('activity.refresh_data', 'Refresh Data')}
            style={{
              height: '40px',
              padding: '0 14px',
              borderRadius: 'var(--radius-sm)',
              border: '1px solid var(--color-border)',
              backgroundColor: 'var(--color-surface)',
              fontSize: 'var(--font-sm)',
              fontWeight: 600,
              color: 'var(--color-text-primary)',
              display: 'inline-flex',
              alignItems: 'center',
              gap: '6px',
              cursor: isRefreshing ? 'wait' : 'pointer',
            }}
          >
            <span
              className="material-symbols-outlined icon-sm"
              style={{
                animation: isRefreshing ? 'spin 1s linear infinite' : 'none',
              }}
            >
              refresh
            </span>
            <span>{t('activity.refresh_data', 'Refresh')}</span>
          </button>

          {/* Export CSV Button */}
          <button
            type="button"
            onClick={handleExportCSV}
            disabled={records.length === 0}
            title={t('activity.export_report', 'Export Shift Report (CSV)')}
            style={{
              height: '40px',
              padding: '0 14px',
              borderRadius: 'var(--radius-sm)',
              border: '1px solid var(--color-primary)',
              backgroundColor: records.length > 0 ? 'var(--color-primary-soft)' : 'var(--color-surface)',
              fontSize: 'var(--font-sm)',
              fontWeight: 600,
              color: 'var(--color-primary)',
              display: 'inline-flex',
              alignItems: 'center',
              gap: '6px',
              cursor: records.length === 0 ? 'not-allowed' : 'pointer',
              opacity: records.length === 0 ? 0.6 : 1,
            }}
          >
            <span className="material-symbols-outlined icon-sm">download</span>
            <span>{t('activity.export_report', 'Export Report')}</span>
          </button>
        </div>
      </div>

      {/* Summary KPI Tiles for this Specific Counter */}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(210px, 1fr))',
          gap: 'var(--space-md)',
          marginBottom: 'var(--space-xl)',
        }}
      >
        {/* Tokens Served Tile */}
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
            {metrics.totalCount > 0
              ? `${Math.round((metrics.servedCount / metrics.totalCount) * 100)}% of handled tokens`
              : t('activity.completed_desc', 'Completed counter services')}
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
            {t('activity.target_benchmark', 'Target: 10m 00s benchmark')}
          </div>
        </div>

        {/* Total Active Serving Time Tile */}
        <div className="kpi-card" style={{ backgroundColor: 'var(--color-surface)', border: '1px solid var(--color-border)', borderRadius: 'var(--radius-md)', padding: 'var(--space-md)' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '8px' }}>
            <span style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-muted)', fontWeight: 600 }}>
              {t('activity.kpi_total_time', 'Total Serving Time')}
            </span>
            <span className="material-symbols-outlined icon-md" style={{ color: 'var(--color-secondary)' }}>
              hourglass_bottom
            </span>
          </div>
          <div style={{ fontSize: 'var(--font-display)', fontWeight: 700, color: 'var(--color-text-primary)' }}>
            {metrics.totalServingTime}
          </div>
          <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-muted)', marginTop: '4px' }}>
            {t('activity.kpi_fastest', 'Fastest')}: {metrics.fastestServiceTime}
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
            {t('activity.noshow_desc', 'Citizens failed to appear')}
          </div>
        </div>

        {/* Total Handled Tile */}
        <div className="kpi-card" style={{ backgroundColor: 'var(--color-surface)', border: '1px solid var(--color-border)', borderRadius: 'var(--radius-md)', padding: 'var(--space-md)' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '8px' }}>
            <span style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-muted)', fontWeight: 600 }}>
              {t('activity.kpi_total_handled', 'Total Handled')}
            </span>
            <span className="material-symbols-outlined icon-md" style={{ color: 'var(--color-text-secondary)' }}>
              summarize
            </span>
          </div>
          <div style={{ fontSize: 'var(--font-display)', fontWeight: 700, color: 'var(--color-text-primary)' }}>
            {metrics.totalCount}
          </div>
          <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-muted)', marginTop: '4px' }}>
            {t('activity.last_refreshed', 'Last updated')}: {formatTimeOnly(lastRefreshedAt.toISOString())}
          </div>
        </div>
      </div>

      {/* Hourly Service Timeline & Time-of-Day Distribution Report */}
      <div
        className="card"
        style={{
          backgroundColor: 'var(--color-surface)',
          border: '1px solid var(--color-border)',
          borderRadius: 'var(--radius-md)',
          padding: 'var(--space-lg)',
          marginBottom: 'var(--space-xl)',
        }}
      >
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 'var(--space-md)' }}>
          <div>
            <h2 style={{ fontSize: 'var(--font-h3)', fontWeight: 700, color: 'var(--color-text-primary)', margin: 0 }}>
              {t('activity.hourly_breakdown', 'Hourly Service Breakdown & Timeline')}
            </h2>
            <p style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-muted)', margin: '4px 0 0 0' }}>
              {t('activity.hourly_breakdown_desc', "Volume of citizens served per hour throughout today's shift for ")}
              <strong>{getCounterLabel(selectedCounter)}</strong>
            </p>
          </div>
        </div>

        {!hourlyReport.hasAnyActivity ? (
          <div style={{ padding: 'var(--space-md)', textAlign: 'center', color: 'var(--color-text-muted)', fontSize: 'var(--font-sm)' }}>
            <span className="material-symbols-outlined" style={{ fontSize: '24px', opacity: 0.5, verticalAlign: 'middle', marginRight: '6px' }}>
              schedule
            </span>
            No completed turns recorded during shift hours yet today.
          </div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
            {hourlyReport.slots.map((slot) => {
              const pct = Math.round((slot.total / hourlyReport.maxVolume) * 100);
              return (
                <div
                  key={slot.hour}
                  style={{
                    display: 'grid',
                    gridTemplateColumns: '150px 1fr 100px 90px',
                    alignItems: 'center',
                    gap: '12px',
                    padding: '8px 12px',
                    borderRadius: 'var(--radius-sm)',
                    backgroundColor: slot.total > 0 ? 'var(--color-secondary-canvas)' : 'transparent',
                    border: '1px solid',
                    borderColor: slot.total > 0 ? 'var(--color-border-subtle)' : 'transparent',
                  }}
                >
                  <div style={{ fontSize: 'var(--font-sm)', fontWeight: 600, color: 'var(--color-text-primary)' }}>
                    {slot.label}
                  </div>
                  {/* Progress volume bar */}
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                    <div
                      style={{
                        flex: 1,
                        height: '10px',
                        backgroundColor: 'var(--color-border-subtle)',
                        borderRadius: 'var(--radius-full)',
                        overflow: 'hidden',
                      }}
                    >
                      <div
                        style={{
                          height: '100%',
                          width: `${pct}%`,
                          backgroundColor: slot.served > 0 ? 'var(--color-primary)' : 'var(--color-text-muted)',
                          borderRadius: 'var(--radius-full)',
                          transition: 'width 0.3s ease',
                        }}
                      />
                    </div>
                  </div>
                  <div style={{ fontSize: 'var(--font-sm)', fontWeight: 600, textAlign: 'right', color: 'var(--color-text-primary)' }}>
                    {slot.served} {t('activity.hour_served', 'served')}
                  </div>
                  <div style={{ fontSize: 'var(--font-sm)', color: slot.noShow > 0 ? 'var(--color-danger)' : 'var(--color-text-muted)', textAlign: 'right' }}>
                    {slot.noShow > 0 ? `${slot.noShow} no-show` : '0 no-show'}
                  </div>
                </div>
              );
            })}
          </div>
        )}
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
          {(['ALL', 'SERVED', 'NO_SHOW', 'MISSING_DOCS', 'WRONG_SERVICE'] as const).map((code) => {
            const label =
              code === 'ALL'
                ? t('activity.all_outcomes', 'All Outcomes')
                : code === 'SERVED'
                ? t('officer.served', 'Served')
                : code === 'NO_SHOW'
                ? t('officer.no_show', 'No-Show')
                : code === 'MISSING_DOCS'
                ? t('officer.missing_docs', 'Missing Docs')
                : code === 'WRONG_SERVICE'
                ? t('officer.wrong_service', 'Wrong Service')
                : code;
            return (
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
                  cursor: 'pointer',
                }}
              >
                {label}
              </button>
            );
          })}
        </div>
      </div>

      {/* Detailed Activity Table */}
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
          <div style={{ padding: 'var(--space-xxl)', textAlign: 'center', color: 'var(--color-text-muted)' }}>
            <span className="material-symbols-outlined icon-lg" style={{ fontSize: '56px', marginBottom: '12px', opacity: 0.4 }}>
              history_toggle_off
            </span>
            <p style={{ fontSize: 'var(--font-h3)', fontWeight: 700, color: 'var(--color-text-primary)', marginBottom: '6px' }}>
              {records.length === 0
                ? t('activity.no_records_counter', 'No service activity recorded yet for this counter today.')
                : t('activity.no_records', 'No activity records match your filter.')}
            </p>
            <p style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-muted)', maxWidth: '500px', margin: '0 auto' }}>
              {records.length === 0
                ? t('activity.no_records_hint', 'Tokens called, served, completed, or marked no-show at this counter will be permanently stored and reflected here.')
                : 'Try adjusting your search query or outcome filter.'}
            </p>
          </div>
        ) : (
          <div style={{ overflowX: 'auto' }}>
            <table className="queue-table" style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
              <thead>
                <tr style={{ borderBottom: '1px solid var(--color-border)', backgroundColor: 'var(--color-secondary-canvas)' }}>
                  <th style={{ padding: '14px 16px', fontSize: 'var(--font-sm)', fontWeight: 700 }}>{t('activity.col_token', 'Token / Citizen')}</th>
                  <th style={{ padding: '14px 16px', fontSize: 'var(--font-sm)', fontWeight: 700 }}>{t('activity.col_service', 'Service')}</th>
                  <th style={{ padding: '14px 16px', fontSize: 'var(--font-sm)', fontWeight: 700 }}>{t('activity.col_counter', 'Counter')}</th>
                  <th style={{ padding: '14px 16px', fontSize: 'var(--font-sm)', fontWeight: 700 }}>{t('activity.col_outcome', 'Outcome')}</th>
                  <th style={{ padding: '14px 16px', fontSize: 'var(--font-sm)', fontWeight: 700 }}>{t('activity.col_duration', 'Duration')}</th>
                  <th style={{ padding: '14px 16px', fontSize: 'var(--font-sm)', fontWeight: 700 }}>{t('activity.col_time', 'Completed At')}</th>
                  <th style={{ padding: '14px 16px', fontSize: 'var(--font-sm)', fontWeight: 700 }}>{t('activity.col_notes', 'Note / Details')}</th>
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
                        <div style={{ fontWeight: 700, color: 'var(--color-primary)', fontSize: 'var(--font-h4)' }}>
                          {r.display_code}
                        </div>
                        {r.beneficiary_name && (
                          <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-secondary)', marginTop: '2px' }}>
                            {r.beneficiary_name}
                          </div>
                        )}
                      </td>
                      <td style={{ padding: '14px 16px', color: 'var(--color-text-primary)', fontWeight: 500 }}>
                        {sName}
                      </td>
                      <td style={{ padding: '14px 16px' }}>
                        <span
                          style={{
                            padding: '3px 8px',
                            borderRadius: 'var(--radius-sm)',
                            fontSize: 'var(--font-xs)',
                            fontWeight: 600,
                            backgroundColor: 'var(--color-secondary-canvas)',
                            border: '1px solid var(--color-border)',
                            color: 'var(--color-text-secondary)',
                          }}
                        >
                          {(r.counter_id || selectedCounter).toUpperCase()}
                        </span>
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
                          {r.outcome_code === 'SERVED'
                            ? t('officer.served', 'SERVED')
                            : r.outcome_code === 'NO_SHOW'
                            ? t('officer.no_show', 'NO_SHOW')
                            : r.outcome_code === 'MISSING_DOCS'
                            ? t('officer.missing_docs', 'MISSING_DOCS')
                            : r.outcome_code === 'WRONG_SERVICE'
                            ? t('officer.wrong_service', 'WRONG_SERVICE')
                            : r.outcome_code}
                          {r.group_size && r.group_size > 1 && (
                            <span style={{ opacity: 0.9 }}>
                              ({r.served_count ?? r.group_size}/{r.group_size})
                            </span>
                          )}
                        </span>
                      </td>
                      <td style={{ padding: '14px 16px', fontVariantNumeric: 'tabular-nums', color: 'var(--color-text-secondary)', fontWeight: 600 }}>
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
