-- =========================================================
-- Schéma "Ma Boutique" — à coller dans Supabase > SQL Editor
-- =========================================================

-- Catégories
create table if not exists categories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  color text not null default '#6366F1',
  created_at timestamptz not null default now()
);

-- Produits
create table if not exists products (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  category_id uuid references categories(id) on delete set null,
  name text not null,
  description text,
  price numeric(12,2) not null default 0,
  quantity integer not null default 0,
  image_url text,
  created_at timestamptz not null default now()
);

-- Clients
create table if not exists customers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  phone text,
  address text,
  notes text,
  created_at timestamptz not null default now()
);

-- Ventes (en-tête)
create table if not exists sales (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  customer_id uuid references customers(id) on delete set null,
  total numeric(12,2) not null default 0,
  payment_method text not null default 'espèces',
  created_at timestamptz not null default now()
);

-- Lignes de vente (détail produit par produit)
create table if not exists sale_items (
  id uuid primary key default gen_random_uuid(),
  sale_id uuid not null references sales(id) on delete cascade,
  product_id uuid not null references products(id),
  quantity integer not null,
  unit_price numeric(12,2) not null
);

-- Index utiles pour les exports par mois/année et les recherches
create index if not exists idx_products_user on products(user_id);
create index if not exists idx_sales_user_date on sales(user_id, created_at);
create index if not exists idx_sale_items_sale on sale_items(sale_id);

-- =========================================================
-- Row Level Security : chaque utilisateur ne voit QUE ses données
-- =========================================================
alter table categories enable row level security;
alter table products enable row level security;
alter table customers enable row level security;
alter table sales enable row level security;
alter table sale_items enable row level security;

create policy "categories: owner only" on categories
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "products: owner only" on products
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "customers: owner only" on customers
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "sales: owner only" on sales
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- sale_items n'a pas de user_id direct : on vérifie via la vente parente
create policy "sale_items: owner only" on sale_items
  for all using (
    exists (select 1 from sales s where s.id = sale_items.sale_id and s.user_id = auth.uid())
  ) with check (
    exists (select 1 from sales s where s.id = sale_items.sale_id and s.user_id = auth.uid())
  );

-- =========================================================
-- Stockage des images produits (bucket "product-images")
-- Crée le bucket dans Storage > New bucket > "product-images" (public)
-- puis exécute ces policies :
-- =========================================================
-- insert into storage.buckets (id, name, public) values ('product-images', 'product-images', true)
-- on conflict (id) do nothing;

create policy "product images: owner upload"
  on storage.objects for insert
  with check (bucket_id = 'product-images' and auth.uid()::text = (storage.foldername(name))[1]);

create policy "product images: owner manage"
  on storage.objects for all
  using (bucket_id = 'product-images' and auth.uid()::text = (storage.foldername(name))[1]);

create policy "product images: public read"
  on storage.objects for select
  using (bucket_id = 'product-images');

-- =========================================================
-- Table profiles — informations supplémentaires utilisateur
-- =========================================================
create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  phone text,
  avatar_url text,
  updated_at timestamptz default now()
);

-- Créer automatiquement un profil vide à l'inscription
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, full_name, phone)
  values (
    new.id,
    new.raw_user_meta_data->>'full_name',
    new.raw_user_meta_data->>'phone'
  )
  on conflict (id) do update
    set full_name = excluded.full_name,
        phone = excluded.phone;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- RLS profiles
alter table profiles enable row level security;

create policy "profiles: owner read" on profiles
  for select using (auth.uid() = id);

create policy "profiles: owner write" on profiles
  for all using (auth.uid() = id) with check (auth.uid() = id);

