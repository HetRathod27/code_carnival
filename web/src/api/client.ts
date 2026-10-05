/**
 * Thin API client — all HTTP calls go through this module.
 * Core Rule 1: The API owns all business logic; the web only calls generated API clients.
 * We use fetch() wrapping the OpenAPI contract (types from openapi.json schema).
 */

const BASE = import.meta.env.VITE_API_URL ?? 'http://localhost:8000';
const INTERNAL_SECRET = import.meta.env.VITE_INTERNAL_SECRET ?? 'default_dev_tick_secret';

function authHeaders(token?: string): HeadersInit {
  const h: HeadersInit = { 'Content-Type': 'application/json' };
  if (token) h['Authorization'] = `Bearer ${token}`;
  return h;
}

async function req<T>(
  method: string,
  path: string,
  token?: string,
  body?: unknown,
  extraHeaders?: HeadersInit,
): Promise<T> {
  const res = await fetch(`${BASE}${path}`, {
    method,
    headers: { ...authHeaders(token), ...(extraHeaders ?? {}) },
    body: body !== undefined ? JSON.stringify(body) : undefined,
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({ detail: res.statusText }));
    throw new Error(err?.error?.message ?? err?.detail ?? `HTTP ${res.status}`);
  }
  // 204 No Content
  if (res.status === 204) return undefined as T;
  return res.json() as Promise<T>;
}

// ─── Types ──────────────────────────────────────────────────────────────────

export interface DevPersona {
  token: string;
  role: string;
  office_id: string | null;
  name: string | null;
  phone: string | null;
}

export interface QueueItem {
  id: string;
  seq: number;
  display_code: string;
  category: string;
  priority_status: string;
  state: string;
  arrived: boolean;
  arrived_at: string | null;
  pass_over_count: number;
  masked_phone: string | null;
  beneficiary_name: string | null;
  waiting_minutes: number;
}

export interface TokenOut {
  id: string;
  office_id: string;
  service_id: string;
  business_date: string;
  seq: number;
  display_code: string;
  state: string;
  category: string;
  priority_status: string;
  created_via: string;
  phone: string | null;
  beneficiary_name: string | null;
  counter_id: string | null;
  counter_label: string | null;
  arrived_at: string | null;
  called_at: string | null;
  grace_deadline: string | null;
  serving_started_at: string | null;
  completed_at: string | null;
  last_eta_minutes: number | null;
  last_eta_reason: string | null;
  eta_low: number | null;
  eta_high: number | null;
  waiting_ahead: number;
  now_serving: string | null;
  server_time: string;
}

export interface CounterStatusResult {
  counter_id: string;
  status: string;
}

export interface ServiceOut {
  id: string;
  office_id: string;
  code: string;
  names: Record<string, string>;
  prior_avg_minutes: number;
  required_docs: Array<{
    id: string;
    name_en?: string;
    name_gu?: string;
    name_hi?: string;
  }>;
  priority_allowed: boolean;
  requires_physical_visit: boolean;
  online_alternative_url?: string | null;
  location_hint?: Record<string, string> | null;
  indicative_wait_minutes?: number | null;
}

export interface OfficeOut {
  id: string;
  name: string;
  address: string;
  timezone: string;
  open_time: string;
  close_time: string;
}

// ─── Auth ───────────────────────────────────────────────────────────────────

export async function fetchDevTokens(): Promise<Record<string, DevPersona>> {
  const res = await req<{ dev_tokens: Record<string, DevPersona> }>(
    'POST',
    '/internal/dev-token',
    undefined,
    undefined,
    { 'X-Internal-Secret': INTERNAL_SECRET },
  );
  return res.dev_tokens;
}

// ─── Citizen / Public ───────────────────────────────────────────────────────

export async function fetchOffices(): Promise<OfficeOut[]> {
  return req<OfficeOut[]>('GET', '/v1/citizen/offices');
}

export async function fetchServices(officeId: string): Promise<ServiceOut[]> {
  return req<ServiceOut[]>('GET', `/v1/citizen/offices/${officeId}/services`);
}

// ─── Officer ────────────────────────────────────────────────────────────────

export async function fetchQueue(
  token: string,
  counterId: string,
): Promise<QueueItem[]> {
  return req<QueueItem[]>('GET', `/v1/officer/counters/${counterId}/queue`, token);
}

export async function updateCounterStatus(
  token: string,
  counterId: string,
  status: 'OPEN' | 'BREAK' | 'CLOSED',
): Promise<CounterStatusResult> {
  return req<CounterStatusResult>(
    'POST',
    `/v1/officer/counters/${counterId}/status`,
    token,
    { status },
  );
}

export async function callNext(
  token: string,
  counterId: string,
  serviceId?: string,
): Promise<TokenOut | null> {
  return req<TokenOut | null>(
    'POST',
    `/v1/officer/counters/${counterId}/call-next`,
    token,
    serviceId ? { service_id: serviceId } : {},
  );
}

export async function startServing(token: string, tokenId: string): Promise<TokenOut> {
  return req<TokenOut>('POST', `/v1/officer/tokens/${tokenId}/start`, token, {});
}

export async function completeServing(
  token: string,
  tokenId: string,
  outcomeCode: string,
  note?: string,
): Promise<TokenOut> {
  return req<TokenOut>('POST', `/v1/officer/tokens/${tokenId}/complete`, token, {
    outcome_code: outcomeCode,
    note: note || undefined,
  });
}

export async function markNoShow(
  token: string,
  tokenId: string,
  note?: string,
): Promise<TokenOut> {
  return req<TokenOut>('POST', `/v1/officer/tokens/${tokenId}/no-show`, token, {
    note: note || undefined,
  });
}

export async function releaseToken(
  token: string,
  tokenId: string,
  note?: string,
): Promise<TokenOut> {
  return req<TokenOut>('POST', `/v1/officer/tokens/${tokenId}/release`, token, {
    note: note || undefined,
  });
}

export async function transferToken(
  token: string,
  tokenId: string,
  targetServiceId: string,
  note?: string,
): Promise<TokenOut> {
  return req<TokenOut>('POST', `/v1/officer/tokens/${tokenId}/transfer`, token, {
    target_service_id: targetServiceId,
    note: note || undefined,
  });
}

export async function priorityCheck(
  token: string,
  tokenId: string,
  docType: string,
  result: 'VERIFIED' | 'REJECTED',
  note?: string,
): Promise<TokenOut> {
  return req<TokenOut>('POST', `/v1/officer/tokens/${tokenId}/priority-check`, token, {
    doc_type: docType,
    result,
    note: note || undefined,
  });
}

// ─── Desk & Physical Turn Slips ─────────────────────────────────────────────

export interface DeskBookIn {
  office_id: string;
  service_id: string;
  category?: string;
  phone?: string | null;
  citizen_name?: string | null;
  created_via?: string;
  override_reason?: string | null;
}

export interface DeskSlipOut {
  token: TokenOut;
  printable_code: string;
  qr_data: string;
}

export async function deskCreateToken(token: string, payload: DeskBookIn): Promise<DeskSlipOut> {
  return req<DeskSlipOut>('POST', '/v1/desk/tokens', token, payload);
}

export async function deskManualCheckIn(token: string, tokenId: string): Promise<TokenOut> {
  return req<TokenOut>('POST', `/v1/desk/tokens/${tokenId}/check-in`, token, {});
}

export async function deskGetTokenSlip(token: string, tokenId: string): Promise<DeskSlipOut> {
  return req<DeskSlipOut>('GET', `/v1/desk/tokens/${tokenId}/slip`, token);
}

// ─── Public Lobby Display Board ─────────────────────────────────────────────

export interface DisplayCounterOut {
  counter_label: string;
  now_serving: string | null;
}

export interface DisplayBoardOut {
  office_id: string;
  office_name: string;
  counters: DisplayCounterOut[];
}

export async function fetchDisplayBoard(officeId: string): Promise<DisplayBoardOut> {
  return req<DisplayBoardOut>('GET', `/v1/display/${officeId}`);
}

// ─── Admin Management ───────────────────────────────────────────────────────

export interface OfficeDetailOut {
  id: string;
  name: string;
  address: string;
  timezone: string;
  open_time: string;
  close_time: string;
  active: boolean;
}

export interface OfficeSettingsOut {
  office_id: string;
  grace_minutes: number;
  priority_every_n: number;
  requeue_offset: number;
  max_requeues: number;
  close_grace_minutes: number;
  max_active_tokens_per_phone: number;
  strike_limit: number;
  dispatch_window: number;
  max_pass_overs: number;
  max_waiting_per_service: number;
  on_my_way_extension_minutes: number;
  retention_days: number;
}

export interface ServiceCreateIn {
  id: string;
  office_id: string;
  code: string;
  names: Record<string, string>;
  prior_avg_minutes: number;
  required_docs?: Array<{ id: string; name_en?: string; name_gu?: string; name_hi?: string }>;
  priority_allowed?: boolean;
  requires_physical_visit?: boolean;
  online_alternative_url?: string | null;
  location_hint?: Record<string, string> | null;
}

export interface CounterOut {
  id: string;
  office_id: string;
  label: string;
  status: string;
  officer_id?: string | null;
}

export interface CounterCreateIn {
  id: string;
  office_id: string;
  label: string;
}

export async function fetchAdminOffices(token: string): Promise<OfficeDetailOut[]> {
  return req<OfficeDetailOut[]>('GET', '/v1/admin/offices', token);
}

export async function fetchOfficeSettings(token: string, officeId: string): Promise<OfficeSettingsOut> {
  return req<OfficeSettingsOut>('GET', `/v1/admin/offices/${officeId}/settings`, token);
}

export async function updateOfficeSettings(
  token: string,
  officeId: string,
  payload: Partial<OfficeSettingsOut>,
): Promise<OfficeSettingsOut> {
  return req<OfficeSettingsOut>('PATCH', `/v1/admin/offices/${officeId}/settings`, token, payload);
}

export async function createAdminService(token: string, payload: ServiceCreateIn): Promise<ServiceOut> {
  return req<ServiceOut>('POST', '/v1/admin/services', token, payload);
}

export async function updateAdminService(
  token: string,
  serviceId: string,
  payload: Partial<ServiceCreateIn> & { active?: boolean },
): Promise<ServiceOut> {
  return req<ServiceOut>('PATCH', `/v1/admin/services/${serviceId}`, token, payload);
}

export async function deleteAdminService(token: string, serviceId: string): Promise<{ message: string }> {
  return req<{ message: string }>('DELETE', `/v1/admin/services/${serviceId}`, token);
}

export async function pauseQueueBooking(token: string, serviceId: string, reason: string): Promise<{ message: string }> {
  return req<{ message: string }>('POST', `/v1/queues/${serviceId}/pause?reason=${encodeURIComponent(reason)}`, token);
}

export async function resumeQueueBooking(token: string, serviceId: string): Promise<{ message: string }> {
  return req<{ message: string }>('DELETE', `/v1/queues/${serviceId}/pause`, token);
}

export async function fetchAdminCounters(token: string, counterIds: string[]): Promise<CounterOut[]> {
  const promises = counterIds.map((id) =>
    req<CounterOut>('GET', `/v1/admin/counters/${id}`, token).catch(() => null),
  );
  const results = await Promise.all(promises);
  return results.filter((c): c is CounterOut => c !== null);
}

export async function createAdminCounter(token: string, payload: CounterCreateIn): Promise<CounterOut> {
  return req<CounterOut>('POST', '/v1/admin/counters', token, payload);
}

export async function updateAdminCounter(
  token: string,
  counterId: string,
  payload: { label?: string; status?: string },
): Promise<CounterOut> {
  return req<CounterOut>('PATCH', `/v1/admin/counters/${counterId}`, token, payload);
}

export async function deleteAdminCounter(token: string, counterId: string): Promise<{ message: string }> {
  return req<{ message: string }>('DELETE', `/v1/admin/counters/${counterId}`, token);
}

export async function mapCounterService(
  token: string,
  counterId: string,
  serviceId: string,
): Promise<{ message: string }> {
  return req<{ message: string }>('POST', '/v1/admin/counter-services', token, {
    counter_id: counterId,
    service_id: serviceId,
  });
}

export async function unmapCounterService(
  token: string,
  counterId: string,
  serviceId: string,
): Promise<{ message: string }> {
  return req<{ message: string }>('DELETE', '/v1/admin/counter-services', token, {
    counter_id: counterId,
    service_id: serviceId,
  });
}

export async function generateEntranceQr(
  token: string,
  officeId: string,
): Promise<{ office_id: string; business_date: string; qr_payload: string }> {
  return req<{ office_id: string; business_date: string; qr_payload: string }>(
    'POST',
    `/v1/admin/offices/${officeId}/qr`,
    token,
  );
}

// ─── Reports & Analytics ────────────────────────────────────────────────────

export interface ServiceReportRow {
  service_id: string;
  served: number;
  cancelled: number;
  expired: number;
  no_show: number;
  waiting: number;
  avg_wait_minutes: number | null;
  p90_wait_minutes: number | null;
  avg_service_minutes: number | null;
  priority_count: number;
  priority_rejected: number;
}

export interface SummaryReportOut {
  office_id: string;
  date: string;
  services: ServiceReportRow[];
}

export interface HourlyLoadItem {
  service_id: string;
  hour_bucket: string | null;
  tokens_booked: number;
  tokens_served: number;
}

export interface LoadByHourOut {
  office_id: string;
  date: string;
  hourly: HourlyLoadItem[];
}

export interface EngineAccuracyRow {
  engine: string;
  n: number;
  mae_minutes: number | null;
  within_range_pct: number | null;
}

export interface EtaAccuracyOut {
  office_id: string;
  date: string;
  engines: EngineAccuracyRow[];
  naive_mae: number | null;
}

export async function fetchReportSummary(
  token: string,
  officeId: string,
  dateStr: string,
): Promise<SummaryReportOut> {
  return req<SummaryReportOut>(
    'GET',
    `/v1/admin/reports/${officeId}/summary?report_date=${dateStr}`,
    token,
  );
}

export async function fetchReportLoadByHour(
  token: string,
  officeId: string,
  dateStr: string,
): Promise<LoadByHourOut> {
  return req<LoadByHourOut>(
    'GET',
    `/v1/admin/reports/${officeId}/load-by-hour?report_date=${dateStr}`,
    token,
  );
}

export async function fetchReportEtaAccuracy(
  token: string,
  officeId: string,
  dateStr: string,
): Promise<EtaAccuracyOut> {
  return req<EtaAccuracyOut>(
    'GET',
    `/v1/admin/reports/${officeId}/eta-accuracy?report_date=${dateStr}`,
    token,
  );
}

// ─── Simulation Control ─────────────────────────────────────────────────────

export interface SimStatusOut {
  office_id: string;
  status: 'NOT_STARTED' | 'RUNNING' | 'COMPLETED' | 'FAILED';
  tokens_booked?: number;
  tokens_served?: number;
  tokens_no_show?: number;
  tokens_cancelled?: number;
  mae_live?: number;
  mae_naive?: number;
  within_range_pct?: number;
  tick_count?: number;
  error?: string;
}

export async function startSimulation(
  token: string,
  officeId: string,
): Promise<{ status: string; office_id: string }> {
  return req<{ status: string; office_id: string }>(
    'POST',
    `/v1/admin/sim/${officeId}/start`,
    token,
  );
}

export async function getSimulationStatus(
  token: string,
  officeId: string,
): Promise<SimStatusOut> {
  return req<SimStatusOut>('GET', `/v1/admin/sim/${officeId}/status`, token);
}

