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

