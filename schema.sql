-- One row per trader. Guests write their own row by id; anyone can read the board.
create table if not exists public.entries (
  id text primary key,
  name text not null default '',
  picks jsonb not null default '{}'::jsonb,
  created_at bigint not null
);

-- One row, id "exchange": date, closing times, closed/resolved markets, reveal flag.
create table if not exists public.config (
  id text primary key,
  data jsonb not null default '{}'::jsonb
);

alter table public.entries enable row level security;
alter table public.config enable row level security;

-- Party game: the anon key may read and write, never delete.
create policy "anon read entries"   on public.entries for select to anon using (true);
create policy "anon insert entries" on public.entries for insert to anon with check (true);
create policy "anon update entries" on public.entries for update to anon using (true) with check (true);
create policy "anon read config"    on public.config  for select to anon using (true);
create policy "anon insert config"  on public.config  for insert to anon with check (true);
create policy "anon update config"  on public.config  for update to anon using (true) with check (true);

alter publication supabase_realtime add table public.entries, public.config;

insert into public.config (id, data) values ('exchange', '{}'::jsonb) on conflict (id) do nothing;

-- Reset for the exchange controls. Runs with owner rights so the anon key can clear
-- the board without holding a delete policy; gated on the same key as the admin panel.
create or replace function public.reset_exchange(key text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if key is distinct from 'centreleftdads' then
    raise exception 'wrong key';
  end if;
  delete from public.entries where id is not null;
  update public.config set data = '{}'::jsonb where id = 'exchange';
end
$$;
revoke all on function public.reset_exchange(text) from public;
grant execute on function public.reset_exchange(text) to anon;
