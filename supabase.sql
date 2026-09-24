-- TradeVault production-oriented starter schema
-- Run this entire file in Supabase SQL Editor.
-- NEVER put a Supabase service_role key in index.html.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  first_name text,
  middle_name text,
  surname text,
  phone text,
  workspace_name text default 'My Trading',
  avatar_url text,
  timezone text default 'Africa/Lagos',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.trading_accounts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  account_type text not null default 'personal',
  firm_name text,
  currency text default 'USD',
  starting_balance numeric(14,2) default 10000,
  daily_loss_limit numeric(14,2),
  max_drawdown numeric(14,2),
  profit_target numeric(14,2),
  risk_per_trade numeric(6,3),
  created_at timestamptz default now()
);

create table if not exists public.trades (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  account_id uuid references public.trading_accounts(id) on delete set null,
  symbol text not null,
  direction text not null,
  pnl numeric(14,2) default 0,
  r_multiple numeric(8,3) default 0,
  setup text,
  session text,
  emotion text,
  notes text,
  screenshot_url text,
  trade_date timestamptz default now(),
  created_at timestamptz default now()
);

create table if not exists public.journals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  journal_date date default current_date,
  title text,
  body text,
  mood text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.playbook_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  category text,
  rules text,
  checklist jsonb default '[]'::jsonb,
  active boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  plan text not null default 'free',
  status text not null default 'active',
  provider text,
  provider_customer_id text,
  provider_subscription_id text,
  current_period_end timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(user_id)
);

create table if not exists public.coupon_redemptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  code text not null,
  provider text,
  redeemed_at timestamptz default now(),
  unique(user_id, code)
);

alter table public.profiles enable row level security;
alter table public.trading_accounts enable row level security;
alter table public.trades enable row level security;
alter table public.journals enable row level security;
alter table public.playbook_entries enable row level security;
alter table public.subscriptions enable row level security;
alter table public.coupon_redemptions enable row level security;

drop policy if exists "profiles own rows" on public.profiles;
create policy "profiles own rows" on public.profiles for all using (auth.uid()=id) with check (auth.uid()=id);

drop policy if exists "accounts own rows" on public.trading_accounts;
create policy "accounts own rows" on public.trading_accounts for all using (auth.uid()=user_id) with check (auth.uid()=user_id);

drop policy if exists "trades own rows" on public.trades;
create policy "trades own rows" on public.trades for all using (auth.uid()=user_id) with check (auth.uid()=user_id);

drop policy if exists "journals own rows" on public.journals;
create policy "journals own rows" on public.journals for all using (auth.uid()=user_id) with check (auth.uid()=user_id);

drop policy if exists "playbook own rows" on public.playbook_entries;
create policy "playbook own rows" on public.playbook_entries for all using (auth.uid()=user_id) with check (auth.uid()=user_id);

drop policy if exists "subscription own read" on public.subscriptions;
create policy "subscription own read" on public.subscriptions for select using (auth.uid()=user_id);

drop policy if exists "coupon own read" on public.coupon_redemptions;
create policy "coupon own read" on public.coupon_redemptions
for select using (auth.uid()=user_id);

drop policy if exists "coupon own insert" on public.coupon_redemptions;
create policy "coupon own insert" on public.coupon_redemptions
for insert with check (auth.uid()=user_id);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path=public
as $$
begin
  insert into public.profiles(id, first_name, middle_name, surname, phone)
  values (
    new.id,
    new.raw_user_meta_data->>'first_name',
    new.raw_user_meta_data->>'middle_name',
    new.raw_user_meta_data->>'surname',
    new.raw_user_meta_data->>'phone'
  )
  on conflict (id) do nothing;

  insert into public.subscriptions(user_id, plan, status)
  values(new.id,'free','active')
  on conflict (user_id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

create index if not exists trades_user_date_idx on public.trades(user_id, trade_date desc);
create index if not exists trades_user_setup_idx on public.trades(user_id, setup);
create index if not exists accounts_user_idx on public.trading_accounts(user_id);
create index if not exists journals_user_date_idx on public.journals(user_id, journal_date desc);

-- Storage bucket for future trade screenshots.
insert into storage.buckets (id,name,public)
values ('trade-screenshots','trade-screenshots',false)
on conflict (id) do nothing;

drop policy if exists "trade screenshots own read" on storage.objects;
create policy "trade screenshots own read"
on storage.objects for select
to authenticated
using (bucket_id='trade-screenshots' and (storage.foldername(name))[1]=auth.uid()::text);

drop policy if exists "trade screenshots own insert" on storage.objects;
create policy "trade screenshots own insert"
on storage.objects for insert
to authenticated
with check (bucket_id='trade-screenshots' and (storage.foldername(name))[1]=auth.uid()::text);

drop policy if exists "trade screenshots own delete" on storage.objects;
create policy "trade screenshots own delete"
on storage.objects for delete
to authenticated
using (bucket_id='trade-screenshots' and (storage.foldername(name))[1]=auth.uid()::text);
