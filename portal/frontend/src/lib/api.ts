const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080/api';

interface RequestOptions {
  method?: string;
  body?: unknown;
  headers?: Record<string, string>;
}

async function request<T>(endpoint: string, options: RequestOptions = {}): Promise<T> {
  const token = typeof window !== 'undefined' ? localStorage.getItem('token') : null;

  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...options.headers,
  };

  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  const response = await fetch(`${API_BASE}${endpoint}`, {
    method: options.method || 'GET',
    headers,
    body: options.body ? JSON.stringify(options.body) : undefined,
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({ error: 'Request failed' }));
    throw new Error(error.error || 'Request failed');
  }

  return response.json();
}

// Auth
export const auth = {
  me: () => request<User>('/auth/me'),
  logout: () => request<{ message: string }>('/auth/logout', { method: 'POST' }),
};

// Environments
export const environments = {
  list: () => request<Environment[]>('/environments'),
  get: (id: string) => request<Environment>(`/environments/${id}`),
};

// Resource Types
export const resourceTypes = {
  list: () => request<ResourceType[]>('/resource-types'),
  get: (id: string) => request<ResourceType>(`/resource-types/${id}`),
  getSchema: (id: string) => request<Record<string, unknown>>(`/resource-types/${id}/schema`),
};

// Requests
export const requests = {
  list: (params?: { status?: string; environment_id?: string }) => {
    const searchParams = new URLSearchParams();
    if (params?.status) searchParams.set('status', params.status);
    if (params?.environment_id) searchParams.set('environment_id', params.environment_id);
    const query = searchParams.toString();
    return request<Request[]>(`/requests${query ? `?${query}` : ''}`);
  },
  get: (id: string) => request<Request>(`/requests/${id}`),
  create: (data: CreateRequestInput) => request<Request>('/requests', { method: 'POST', body: data }),
  update: (id: string, data: Partial<CreateRequestInput>) =>
    request<Request>(`/requests/${id}`, { method: 'PUT', body: data }),
  delete: (id: string) => request<{ message: string }>(`/requests/${id}`, { method: 'DELETE' }),
  submit: (id: string) => request<Request>(`/requests/${id}/submit`, { method: 'POST' }),
};

// Approvals
export const approvals = {
  list: (status?: string) => {
    const query = status ? `?status=${status}` : '';
    return request<Approval[]>(`/approvals${query}`);
  },
  get: (id: string) => request<Approval>(`/approvals/${id}`),
  approve: (id: string, comment?: string) =>
    request<Approval>(`/approvals/${id}/approve`, { method: 'POST', body: { comment } }),
  reject: (id: string, comment?: string) =>
    request<Approval>(`/approvals/${id}/reject`, { method: 'POST', body: { comment } }),
};

// Types
export interface User {
  id: string;
  email: string;
  name: string;
  role: string;
  avatar_url?: string;
  created_at: string;
}

export interface Environment {
  id: string;
  name: string;
  display_name: string;
  description?: string;
  gcp_project_id?: string;
  region: string;
  requires_approval: boolean;
  is_active: boolean;
}

export interface ResourceType {
  id: string;
  name: string;
  display_name: string;
  description?: string;
  module_path: string;
  config_schema: Record<string, unknown>;
  base_cost: number;
  is_active: boolean;
}

export interface Request {
  id: string;
  title: string;
  description?: string;
  requester_id: string;
  requester?: User;
  environment_id: string;
  environment?: Environment;
  resource_type_id: string;
  resource_type?: ResourceType;
  configuration: Record<string, unknown>;
  terraform_plan?: string;
  estimated_cost: number;
  status: string;
  priority: string;
  created_at: string;
  updated_at: string;
  submitted_at?: string;
  completed_at?: string;
}

export interface Approval {
  id: string;
  request_id: string;
  request?: Request;
  approver_id: string;
  approver?: User;
  status: string;
  comment?: string;
  approved_at?: string;
  created_at: string;
}

export interface CreateRequestInput {
  title: string;
  description?: string;
  environment_id: string;
  resource_type_id: string;
  configuration: Record<string, unknown>;
  priority?: string;
}
