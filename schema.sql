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
