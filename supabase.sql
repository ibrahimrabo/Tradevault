-- TradeVault Cloud V2 - Supabase database setup
-- Run this entire file once in Supabase SQL Editor.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  full_name text,
  created_at timestamptz not null default now()
);

create table if not exists public.trades (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  symbol text not null,
  direction text not null check (direction in ('Long','Short')),
  entry numeric,
  stop numeric,
  target numeric,
  size numeric,
  risk_percent numeric default 0,
  pnl numeric default 0,
  result text default 'Open' check (result in ('Open','Win','Loss','BE')),
  setup text,
  session text,
  psychology text,
  notes text,
  screenshot_url text,
  trade_date date default current_date,
  created_at timestamptz not null default now()
);

create table if not exists public.journals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  journal_date date not null default current_date,
  title text,
  content text,
  mood text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists trades_user_id_idx on public.trades(user_id);
create index if not exists trades_trade_date_idx on public.trades(trade_date);
create index if not exists journals_user_id_idx on public.journals(user_id);
create index if not exists journals_journal_date_idx on public.journals(journal_date);

alter table public.profiles enable row level security;
alter table public.trades enable row level security;
alter table public.journals enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own" on public.profiles for select to authenticated using (id = auth.uid());

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own" on public.profiles for insert to authenticated with check (id = auth.uid());

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own" on public.profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

drop policy if exists "trades_select_own" on public.trades;
create policy "trades_select_own" on public.trades for select to authenticated using (user_id = auth.uid());

drop policy if exists "trades_insert_own" on public.trades;
create policy "trades_insert_own" on public.trades for insert to authenticated with check (user_id = auth.uid());

drop policy if exists "trades_update_own" on public.trades;
create policy "trades_update_own" on public.trades for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "trades_delete_own" on public.trades;
create policy "trades_delete_own" on public.trades for delete to authenticated using (user_id = auth.uid());

drop policy if exists "journals_select_own" on public.journals;
create policy "journals_select_own" on public.journals for select to authenticated using (user_id = auth.uid());

drop policy if exists "journals_insert_own" on public.journals;
create policy "journals_insert_own" on public.journals for insert to authenticated with check (user_id = auth.uid());

drop policy if exists "journals_update_own" on public.journals;
create policy "journals_update_own" on public.journals for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "journals_delete_own" on public.journals;
create policy "journals_delete_own" on public.journals for delete to authenticated using (user_id = auth.uid());

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email)
  values (new.id, new.email)
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

insert into storage.buckets (id, name, public)
values ('trade-screenshots', 'trade-screenshots', true)
on conflict (id) do nothing;

drop policy if exists "trade_screenshots_insert_own" on storage.objects;
create policy "trade_screenshots_insert_own" on storage.objects for insert to authenticated
with check (bucket_id = 'trade-screenshots' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "trade_screenshots_select_own" on storage.objects;
create policy "trade_screenshots_select_own" on storage.objects for select to authenticated
using (bucket_id = 'trade-screenshots' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "trade_screenshots_update_own" on storage.objects;
create policy "trade_screenshots_update_own" on storage.objects for update to authenticated
using (bucket_id = 'trade-screenshots' and (storage.foldername(name))[1] = auth.uid()::text)
with check (bucket_id = 'trade-screenshots' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "trade_screenshots_delete_own" on storage.objects;
create policy "trade_screenshots_delete_own" on storage.objects for delete to authenticated
using (bucket_id = 'trade-screenshots' and (storage.foldername(name))[1] = auth.uid()::text);
