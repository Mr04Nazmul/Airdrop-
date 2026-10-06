-- NAZU Testnet production-oriented schema.
create extension if not exists pgcrypto;

create table if not exists public.users (
  id uuid primary key default gen_random_uuid(),
  wallet_address text unique not null,
  points bigint not null default 0,
  node_status text not null default 'offline' check (node_status in ('offline','online')),
  uptime_seconds bigint not null default 0,
  total_heartbeats bigint not null default 0,
  last_heartbeat timestamptz,
  eligible boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.auth_challenges (
  id uuid primary key default gen_random_uuid(), wallet_address text not null,
  nonce text unique not null, message text not null,
  expires_at timestamptz not null, used_at timestamptz, created_at timestamptz not null default now()
);

create table if not exists public.sessions (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references public.users(id) on delete cascade,
  token_hash text unique not null, expires_at timestamptz not null, revoked_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.heartbeats (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references public.users(id) on delete cascade,
  received_at timestamptz not null default now(), points_awarded bigint not null default 0,
  uptime_awarded_seconds bigint not null default 0
);
create index if not exists heartbeats_user_time_idx on public.heartbeats(user_id, received_at desc);
create index if not exists users_last_heartbeat_idx on public.users(last_heartbeat desc);

create table if not exists public.airdrop_allocations (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references public.users(id) on delete cascade,
  points_snapshot bigint not null, allocation_amount numeric(38,18) not null default 0,
  status text not null default 'pending', created_at timestamptz not null default now()
);


create table if not exists public.reward_config (
  id integer primary key default 1 check (id=1),
  points_per_minute numeric(20,6) not null default 1,
  eligibility_points bigint not null default 1000,
  airdrop_enabled boolean not null default false,
  snapshot_version text,
  updated_at timestamptz not null default now()
);
insert into public.reward_config(id) values (1) on conflict (id) do nothing;

create table if not exists public.sybil_flags (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.users(id) on delete cascade,
  reason text not null,
  severity text not null default 'review',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index if not exists sybil_flags_user_idx on public.sybil_flags(user_id, created_at desc);

create table if not exists public.admin_audit_logs (
  id uuid primary key default gen_random_uuid(), admin_wallet text, action text not null,
  target_user_id uuid, old_value jsonb, new_value jsonb, created_at timestamptz not null default now()
);

alter table public.users enable row level security;
alter table public.auth_challenges enable row level security;
alter table public.sessions enable row level security;
alter table public.heartbeats enable row level security;
alter table public.airdrop_allocations enable row level security;
alter table public.admin_audit_logs enable row level security;

-- No public policies: all application writes/reads go through Edge Functions using service_role.
-- Never expose SUPABASE_SERVICE_ROLE_KEY in browser code.
