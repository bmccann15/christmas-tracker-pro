-- Run once in Supabase SQL Editor. All tables are protected by RLS.
create extension if not exists pgcrypto;
create table public.households(id uuid primary key default gen_random_uuid(), name text not null, invite_code text not null unique default encode(gen_random_bytes(18),'hex'), created_at timestamptz not null default now());
create table public.memberships(household_id uuid not null references public.households(id) on delete cascade, user_id uuid not null references auth.users(id) on delete cascade, primary key(household_id,user_id));
create table public.recipients(id uuid primary key default gen_random_uuid(),household_id uuid not null references public.households(id) on delete cascade,name text not null, created_at timestamptz not null default now());
create table public.gifts(id uuid primary key default gen_random_uuid(),household_id uuid not null references public.households(id) on delete cascade,recipient_id uuid not null references public.recipients(id) on delete cascade,year integer not null check(year between 2000 and 2100),name text not null,price numeric(12,2) not null default 0 check(price>=0),status text not null default 'idea' check(status in ('idea','purchased','delivered','wrapped','given')),url text,notes text,private boolean not null default false,created_by uuid not null references auth.users(id),created_at timestamptz not null default now());
create index gifts_household_year on public.gifts(household_id,year);
create index gifts_recipient on public.gifts(recipient_id);
create index memberships_user on public.memberships(user_id);
create or replace function public.is_member(h uuid) returns boolean language sql stable security definer set search_path='' as $$ select exists(select 1 from public.memberships m where m.household_id=h and m.user_id=(select auth.uid())) $$;
create or replace function public.create_household(household_name text) returns uuid language plpgsql security definer set search_path='' as $$ declare h uuid; begin if auth.uid() is null then raise exception 'Not authenticated'; end if; insert into public.households(name) values(trim(household_name)) returning id into h; insert into public.memberships(household_id,user_id) values(h,auth.uid()); return h; end $$;
create or replace function public.join_household(code text) returns uuid language plpgsql security definer set search_path='' as $$ declare h uuid; begin if auth.uid() is null then raise exception 'Not authenticated'; end if; select id into h from public.households where invite_code=trim(code); if h is null then raise exception 'Invalid invite code'; end if; insert into public.memberships(household_id,user_id) values(h,auth.uid()) on conflict do nothing; return h; end $$;
revoke all on function public.create_household(text) from public;
revoke all on function public.join_household(text) from public;
grant execute on function public.create_household(text),public.join_household(text) to authenticated;
alter table public.households enable row level security;
alter table public.memberships enable row level security;
alter table public.recipients enable row level security;
alter table public.gifts enable row level security;
create policy household_read on public.households for select to authenticated using(public.is_member(id));
create policy memberships_read on public.memberships for select to authenticated using(public.is_member(household_id));
create policy recipients_read on public.recipients for select to authenticated using(public.is_member(household_id));
create policy recipients_insert on public.recipients for insert to authenticated with check(public.is_member(household_id));
create policy recipients_update on public.recipients for update to authenticated using(public.is_member(household_id)) with check(public.is_member(household_id));
create policy recipients_delete on public.recipients for delete to authenticated using(public.is_member(household_id));
create policy gifts_read on public.gifts for select to authenticated using(public.is_member(household_id) and (not private or created_by=(select auth.uid())));
create policy gifts_insert on public.gifts for insert to authenticated with check(public.is_member(household_id) and created_by=(select auth.uid()) and exists(select 1 from public.recipients r where r.id=recipient_id and r.household_id=household_id));
create policy gifts_update on public.gifts for update to authenticated using(public.is_member(household_id) and (not private or created_by=(select auth.uid()))) with check(public.is_member(household_id) and (not private or created_by=(select auth.uid())) and exists(select 1 from public.recipients r where r.id=recipient_id and r.household_id=household_id));
create policy gifts_delete on public.gifts for delete to authenticated using(public.is_member(household_id) and (not private or created_by=(select auth.uid())));
-- Prevent a shared gift from being edited into a private gift owned by someone else.
create or replace function public.guard_gift_identity() returns trigger language plpgsql as $$ begin if new.created_by<>old.created_by or new.household_id<>old.household_id then raise exception 'Gift ownership cannot change'; end if; return new; end $$;
create trigger guard_gift_identity before update on public.gifts for each row execute function public.guard_gift_identity();
-- Realtime: RLS still applies to row delivery. Refresh the client after changes.
alter publication supabase_realtime add table public.recipients;
alter publication supabase_realtime add table public.gifts;
