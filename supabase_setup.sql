-- BTCL Complaint Management System
-- Supabase SQL Editor-এ পুরো script চালান।
create extension if not exists pgcrypto;

create table if not exists public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 full_name text not null,
 phone text,
 role text not null default 'staff' check (role in ('admin','staff')),
 created_at timestamptz not null default now()
);

create table if not exists public.customers (
 id uuid primary key default gen_random_uuid(),
 customer_code text not null unique,
 full_name text not null,
 phone text not null,
 phone2 text,
 service_number text,
 connection_type text,
 district text,
 upazila text,
 address text,
 notes text,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create index if not exists customers_phone_idx on public.customers(phone);
create index if not exists customers_name_idx on public.customers using gin(to_tsvector('simple',full_name));

create table if not exists public.complaints (
 id uuid primary key default gen_random_uuid(),
 ticket_no bigint generated always as identity unique,
 customer_id uuid not null references public.customers(id),
 category text not null,
 received_at timestamptz not null default now(),
 channel text not null default 'ফোন',
 problem text not null,
 priority text not null default 'সাধারণ',
 assigned_to uuid references public.profiles(id),
 assigned_at timestamptz,
 status text not null default 'নতুন' check(status in ('নতুন','দায়িত্ব দেওয়া হয়েছে','কাজ চলছে','সমাধান হয়েছে','বাতিল')),
 solved_at timestamptz,
 resolution text,
 notes text,
 created_by uuid references public.profiles(id),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create index if not exists complaints_customer_idx on public.complaints(customer_id,received_at desc);
create index if not exists complaints_assigned_idx on public.complaints(assigned_to,status);
create index if not exists complaints_received_idx on public.complaints(received_at);

create table if not exists public.complaint_events (
 id uuid primary key default gen_random_uuid(),
 complaint_id uuid not null references public.complaints(id) on delete cascade,
 actor_id uuid references public.profiles(id),
 event_type text not null,
 details text,
 created_at timestamptz not null default now()
);

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path=public
as $$ select exists(select 1 from public.profiles where id=auth.uid() and role='admin') $$;

alter table public.profiles enable row level security;
alter table public.customers enable row level security;
alter table public.complaints enable row level security;
alter table public.complaint_events enable row level security;

drop policy if exists "profiles read self or admin" on public.profiles;
create policy "profiles read self or admin" on public.profiles for select using (id=auth.uid() or public.is_admin());
drop policy if exists "admin manages profiles" on public.profiles;
create policy "admin manages profiles" on public.profiles for all using(public.is_admin()) with check(public.is_admin());

drop policy if exists "admin manages customers" on public.customers;
create policy "admin manages customers" on public.customers for all using(public.is_admin()) with check(public.is_admin());
drop policy if exists "staff reads customers on assigned tickets" on public.customers;
create policy "staff reads customers on assigned tickets" on public.customers for select
using(exists(select 1 from public.complaints c where c.customer_id=customers.id and c.assigned_to=auth.uid()));


drop policy if exists "admin all complaints" on public.complaints;
create policy "admin all complaints" on public.complaints for all using(public.is_admin()) with check(public.is_admin());
drop policy if exists "staff reads assigned complaints" on public.complaints;
create policy "staff reads assigned complaints" on public.complaints for select using(assigned_to=auth.uid());

drop policy if exists "admin reads events" on public.complaint_events;
create policy "admin reads events" on public.complaint_events for select using(public.is_admin());
drop policy if exists "staff reads own complaint events" on public.complaint_events;
create policy "staff reads own complaint events" on public.complaint_events for select using(exists(select 1 from public.complaints c where c.id=complaint_id and c.assigned_to=auth.uid()));
drop policy if exists "admin inserts events" on public.complaint_events;
create policy "admin inserts events" on public.complaint_events for insert with check(public.is_admin());

-- updated_at trigger
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$ begin new.updated_at=now(); return new; end $$;
drop trigger if exists customers_updated_at on public.customers;
create trigger customers_updated_at before update on public.customers for each row execute function public.set_updated_at();
drop trigger if exists complaints_updated_at on public.complaints;
create trigger complaints_updated_at before update on public.complaints for each row execute function public.set_updated_at();

-- নিরাপদে প্রথম Admin তৈরি:
-- 1) Authentication > Users থেকে আপনার ইমেইল দিয়ে user তৈরি করুন।
-- 2) তার UUID কপি করে নিচের query-তে বসিয়ে চালান।
-- insert into public.profiles(id,full_name,role) values
-- ('YOUR-AUTH-USER-UUID','আপনার নাম','admin');
--
-- লাইনম্যান: Authentication > Users-এ আলাদা user তৈরি করে staff role দিন:
-- insert into public.profiles(id,full_name,phone,role) values
-- ('STAFF-AUTH-USER-UUID','লাইনম্যানের নাম','01XXXXXXXXX','staff');
--
-- মনে রাখবেন: এই সংস্করণে লাইনম্যানরা শুধু নিজেদের বরাদ্দ অভিযোগ দেখতে পারবে।
-- অভিযোগ এন্ট্রি/সম্পাদনা করবেন Admin। 
