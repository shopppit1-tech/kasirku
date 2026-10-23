-- KASIRKU SUPABASE SCHEMA
-- Jalankan seluruh SQL ini di Supabase Dashboard > SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.store_settings(
 id uuid primary key default gen_random_uuid(),
 store_name text not null default 'Toko Saya',
 address text not null default '',
 phone text not null default '',
 created_at timestamptz not null default now()
);
create table if not exists public.profiles(
 id uuid primary key references auth.users(id) on delete cascade,
 store_id uuid not null references public.store_settings(id) on delete cascade,
 display_name text not null default '',
 role text not null default 'cashier' check(role in ('owner','cashier')),
 active boolean not null default true,
 created_at timestamptz not null default now()
);
create table if not exists public.products(
 id uuid primary key default gen_random_uuid(),
 store_id uuid not null references public.store_settings(id) on delete cascade,
 code text, name text not null, category text not null default 'Umum',
 price numeric(14,2) not null default 0 check(price>=0),
 cost numeric(14,2) not null default 0 check(cost>=0),
 stock integer not null default 0 check(stock>=0),
 active boolean not null default true,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create unique index if not exists products_store_code_unique on public.products(store_id,code) where code is not null and code<>'';
create table if not exists public.transactions(
 id uuid primary key default gen_random_uuid(),
 store_id uuid not null references public.store_settings(id) on delete cascade,
 cashier_id uuid references auth.users(id),
 receipt_no text not null,
 subtotal numeric(14,2) not null, discount numeric(14,2) not null default 0,
 total numeric(14,2) not null, paid numeric(14,2) not null default 0,
 change_amount numeric(14,2) not null default 0,
 method text not null default 'Tunai', status text not null default 'Lunas',
 created_at timestamptz not null default now(),
 unique(store_id,receipt_no)
);
create table if not exists public.transaction_items(
 id uuid primary key default gen_random_uuid(),
 store_id uuid not null references public.store_settings(id) on delete cascade,
 transaction_id uuid not null references public.transactions(id) on delete cascade,
 product_id uuid references public.products(id) on delete set null,
 product_name text not null, code text, price numeric(14,2) not null,
 cost numeric(14,2) not null default 0, qty integer not null check(qty>0),
 line_total numeric(14,2) not null
);
create table if not exists public.stock_history(
 id uuid primary key default gen_random_uuid(),
 store_id uuid not null references public.store_settings(id) on delete cascade,
 product_id uuid references public.products(id) on delete set null,
 product_name text not null, qty integer not null, note text not null default '',
 user_id uuid references auth.users(id), created_at timestamptz not null default now()
);

create or replace function public.current_store_id()
returns uuid language sql stable security definer set search_path=public,pg_temp
as $$ select store_id from public.profiles where id=auth.uid() and active=true limit 1 $$;
create or replace function public.is_store_owner()
returns boolean language sql stable security definer set search_path=public,pg_temp
as $$ select exists(select 1 from public.profiles where id=auth.uid() and active=true and role='owner') $$;
revoke execute on function public.current_store_id() from public, anon;
revoke execute on function public.is_store_owner() from public, anon;
grant execute on function public.current_store_id() to authenticated;
grant execute on function public.is_store_owner() to authenticated;

alter table public.store_settings enable row level security;
alter table public.profiles enable row level security;
alter table public.products enable row level security;
alter table public.transactions enable row level security;
alter table public.transaction_items enable row level security;
alter table public.stock_history enable row level security;

drop policy if exists "store read own settings" on public.store_settings;
create policy "store read own settings" on public.store_settings for select to authenticated using(id=public.current_store_id());
drop policy if exists "owner update settings" on public.store_settings;
create policy "owner update settings" on public.store_settings for update to authenticated using(id=public.current_store_id() and public.is_store_owner()) with check(id=public.current_store_id() and public.is_store_owner());

drop policy if exists "read own store profiles" on public.profiles;
create policy "read own store profiles" on public.profiles for select to authenticated using(store_id=public.current_store_id());
drop policy if exists "owner manage profiles" on public.profiles;
create policy "owner manage profiles" on public.profiles for all to authenticated using(store_id=public.current_store_id() and public.is_store_owner()) with check(store_id=public.current_store_id() and public.is_store_owner());

drop policy if exists "store products read" on public.products;
create policy "store products read" on public.products for select to authenticated using(store_id=public.current_store_id());
drop policy if exists "store products insert" on public.products;
create policy "store products insert" on public.products for insert to authenticated with check(store_id=public.current_store_id());
drop policy if exists "store products update" on public.products;
create policy "store products update" on public.products for update to authenticated using(store_id=public.current_store_id()) with check(store_id=public.current_store_id());
drop policy if exists "owner products delete" on public.products;
create policy "owner products delete" on public.products for delete to authenticated using(store_id=public.current_store_id() and public.is_store_owner());

drop policy if exists "store transactions read" on public.transactions;
create policy "store transactions read" on public.transactions for select to authenticated using(store_id=public.current_store_id());
drop policy if exists "store transaction items read" on public.transaction_items;
create policy "store transaction items read" on public.transaction_items for select to authenticated using(store_id=public.current_store_id());
drop policy if exists "store stock read" on public.stock_history;
create policy "store stock read" on public.stock_history for select to authenticated using(store_id=public.current_store_id());

-- Transaksi dan stok dijalankan di fungsi atomik, supaya dua kasir tidak menjual stok yang sama.
create or replace function public.create_sale(sale jsonb)
returns uuid language plpgsql security definer set search_path=public,pg_temp
as $$
declare v_store uuid:=public.current_store_id(); v_tx uuid; v_receipt text; v_sub numeric(14,2):=0; v_disc numeric(14,2); v_total numeric(14,2); v_paid numeric(14,2); v_method text; v_status text; it jsonb; p public.products%rowtype; q int; v_change numeric(14,2);
begin
 if v_store is null then raise exception 'Profil toko tidak ditemukan'; end if;
 v_disc:=coalesce((sale->>'discount')::numeric,0); v_paid:=coalesce((sale->>'paid')::numeric,0); v_method:=coalesce(sale->>'method','Tunai');
 if jsonb_typeof(sale->'items')<>'array' or jsonb_array_length(sale->'items')=0 then raise exception 'Keranjang kosong'; end if;
 -- Lock all products while validating and calculating subtotal.
 for it in select value from jsonb_array_elements(sale->'items') loop
   q:=(it->>'qty')::int; if q<1 then raise exception 'Jumlah barang tidak valid'; end if;
   select * into p from public.products where id=(it->>'product_id')::uuid and store_id=v_store and active=true for update;
   if not found then raise exception 'Produk tidak ditemukan'; end if;
   if p.stock<q then raise exception 'Stok % tidak mencukupi',p.name; end if;
   v_sub:=v_sub+p.price*q;
 end loop;
 if v_disc<0 or v_disc>v_sub then raise exception 'Diskon tidak valid'; end if;
 v_total:=v_sub-v_disc;
 if v_method<>'Tempo / Utang' and v_paid<v_total then raise exception 'Uang diterima belum cukup'; end if;
 v_status:=case when v_method='Tempo / Utang' then 'Belum lunas' else 'Lunas' end;
 v_change:=case when v_method='Tempo / Utang' then 0 else v_paid-v_total end;
 v_receipt:='TRX-'||to_char(clock_timestamp(),'YYMMDD-HH24MISS')||'-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,4));
 insert into public.transactions(store_id,cashier_id,receipt_no,subtotal,discount,total,paid,change_amount,method,status)
 values(v_store,auth.uid(),v_receipt,v_sub,v_disc,v_total,case when v_method='Tempo / Utang' then 0 else v_paid end,v_change,v_method,v_status) returning id into v_tx;
 for it in select value from jsonb_array_elements(sale->'items') loop
   q:=(it->>'qty')::int;
   select * into p from public.products where id=(it->>'product_id')::uuid and store_id=v_store and active=true for update;
   update public.products set stock=stock-q,updated_at=now() where id=p.id;
   insert into public.transaction_items(store_id,transaction_id,product_id,product_name,code,price,cost,qty,line_total)
   values(v_store,v_tx,p.id,p.name,p.code,p.price,p.cost,q,p.price*q);
 end loop;
 return v_tx;
end $$;

create or replace function public.add_stock(p_product_id uuid,p_qty integer,p_note text default '')
returns void language plpgsql security definer set search_path=public,pg_temp
as $$
declare v_store uuid:=public.current_store_id(); p public.products%rowtype;
begin
 if p_qty<1 then raise exception 'Jumlah stok harus minimal 1'; end if;
 select * into p from public.products where id=p_product_id and store_id=v_store and active=true for update;
 if not found then raise exception 'Produk tidak ditemukan'; end if;
 update public.products set stock=stock+p_qty,updated_at=now() where id=p.id;
 insert into public.stock_history(store_id,product_id,product_name,qty,note,user_id)
 values(v_store,p.id,p.name,p_qty,coalesce(p_note,''),auth.uid());
end $$;

grant execute on function public.create_sale(jsonb) to authenticated;
grant execute on function public.add_stock(uuid,integer,text) to authenticated;
revoke execute on function public.create_sale(jsonb) from public, anon;
revoke execute on function public.add_stock(uuid,integer,text) from public, anon;

-- Aktifkan Realtime untuk tabel yang dipantau aplikasi.
do $$ begin
  alter publication supabase_realtime add table public.products;
exception when duplicate_object then null;
when undefined_object then null;
end $$;
do $$ begin
  alter publication supabase_realtime add table public.transactions;
exception when duplicate_object then null;
when undefined_object then null;
end $$;

-- SETUP PERTAMA:
-- 1. Buat user di Authentication > Users.
-- 2. Jalankan SQL ini untuk membuat toko dan profile owner, ganti EMAIL_OWNER dan nama toko.
--    insert into public.store_settings(store_name,address,phone)
--    values('Nama Toko','Alamat Toko','08xxxx') returning id;
-- 3. Salin UUID hasilnya, lalu jalankan:
--    insert into public.profiles(id,store_id,display_name,role)
--    values((select id from auth.users where email='EMAIL_OWNER'), 'UUID_STORE_DARI_LANGKAH_2', 'Nama Pemilik','owner');
-- Buat akun kasir lewat Authentication > Users, lalu masukkan profil role cashier dengan store_id yang sama.
