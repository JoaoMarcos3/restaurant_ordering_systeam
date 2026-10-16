-- supabase/migrations/202610090001_schema_inicial.sql

create extension if not exists pgcrypto;

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique check (length(trim(name)) > 0),
  description text,
  created_at timestamptz not null default now()
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  category_id uuid not null references public.categories(id) on delete restrict,
  name text not null check (length(trim(name)) > 0),
  description text,
  price numeric(10, 2) not null check (price >= 0),
  available boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  customer_name text not null check (length(trim(customer_name)) > 0),
  status text not null default 'recebido'
    check (status in ('recebido', 'preparando', 'saiu_para_entrega', 'concluido', 'cancelado')),
  total numeric(10, 2) not null default 0 check (total >= 0),
  created_at timestamptz not null default now()
);

create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete restrict,
  product_name text not null,
  unit_price numeric(10, 2) not null check (unit_price >= 0),
  quantity integer not null check (quantity > 0),
  subtotal numeric(10, 2) generated always as (unit_price * quantity) stored
);

create index if not exists products_category_id_idx on public.products(category_id);
create index if not exists order_items_order_id_idx on public.order_items(order_id);
create index if not exists orders_created_at_idx on public.orders(created_at desc);

alter table public.categories enable row level security;
alter table public.products enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;

grant usage on schema public to anon, authenticated, service_role;
revoke all on table public.categories, public.products, public.orders, public.order_items from anon, authenticated;
grant select on table public.categories, public.products to anon, authenticated;
grant select, insert, update, delete on table public.categories, public.products, public.orders, public.order_items to service_role;

drop policy if exists "Catalog is readable" on public.categories;
create policy "Catalog is readable" on public.categories for select to anon, authenticated using (true);
drop policy if exists "Available products are readable" on public.products;
create policy "Available products are readable" on public.products for select to anon, authenticated using (available = true);

create or replace function public.create_order(p_customer_name text, p_items jsonb)
returns jsonb
language plpgsql
security invoker
set search_path = public
as $$
declare
  new_order public.orders%rowtype;
  item jsonb;
  found_product public.products%rowtype;
  item_quantity integer;
begin
  if p_customer_name is null or length(trim(p_customer_name)) = 0 then
    raise exception 'Nome do cliente obrigatório';
  end if;
  if p_items is null or jsonb_typeof(p_items) is distinct from 'array' then
    raise exception 'O pedido precisa ter ao menos um item';
  end if;
  if jsonb_array_length(p_items) = 0 then
    raise exception 'O pedido precisa ter ao menos um item';
  end if;

  insert into public.orders (customer_name)
  values (trim(p_customer_name))
  returning * into new_order;

  for item in select value from jsonb_array_elements(p_items)
  loop
    item_quantity := (item ->> 'quantity')::integer;
    if item_quantity is null or item_quantity < 1 then raise exception 'Quantidade deve ser maior que zero'; end if;

    select * into found_product
    from public.products
    where id = (item ->> 'product_id')::uuid and available = true
    for share;
    if not found then raise exception 'Produto não encontrado ou indisponível'; end if;

    insert into public.order_items (order_id, product_id, product_name, unit_price, quantity)
    values (new_order.id, found_product.id, found_product.name, found_product.price, item_quantity);
  end loop;

  update public.orders
  set total = (select coalesce(sum(subtotal), 0) from public.order_items where order_id = new_order.id)
  where id = new_order.id
  returning * into new_order;

  return jsonb_build_object(
    'id', new_order.id,
    'customer_name', new_order.customer_name,
    'status', new_order.status,
    'total', new_order.total,
    'created_at', new_order.created_at,
    'items', coalesce((select jsonb_agg(to_jsonb(order_items)) from public.order_items where order_id = new_order.id), '[]'::jsonb)
  );
end;
$$;

revoke all on function public.create_order(text, jsonb) from public, anon, authenticated;
grant execute on function public.create_order(text, jsonb) to service_role;

-- supabase/migrations/202610090002_order_status.sql

create or replace function public.update_order_status(p_order_id uuid, p_new_status text)
returns jsonb
language plpgsql
security invoker
set search_path = public
as $$
declare
  current_order public.orders%rowtype;
begin
  select * into current_order
  from public.orders
  where id = p_order_id
  for update;

  if not found then raise exception 'Pedido não encontrado'; end if;
  if p_new_status not in ('recebido', 'preparando', 'saiu_para_entrega', 'concluido', 'cancelado') then
    raise exception 'Status inválido';
  end if;

  if not (
    (current_order.status = 'recebido' and p_new_status in ('preparando', 'cancelado')) or
    (current_order.status = 'preparando' and p_new_status in ('saiu_para_entrega', 'cancelado')) or
    (current_order.status = 'saiu_para_entrega' and p_new_status = 'concluido')
  ) then
    raise exception 'Transição de status não permitida: % -> %', current_order.status, p_new_status;
  end if;

  update public.orders set status = p_new_status where id = p_order_id returning * into current_order;
  return jsonb_build_object(
    'id', current_order.id,
    'customer_name', current_order.customer_name,
    'status', current_order.status,
    'total', current_order.total,
    'created_at', current_order.created_at,
    'items', coalesce((select jsonb_agg(to_jsonb(order_items)) from public.order_items where order_id = current_order.id), '[]'::jsonb)
  );
end;
$$;

revoke all on function public.update_order_status(uuid, text) from public, anon, authenticated;
grant execute on function public.update_order_status(uuid, text) to service_role;

-- supabase/migrations/202610090003_catalogo_unico.sql

create unique index if not exists products_category_name_unique_idx
  on public.products(category_id, name);

-- supabase/seed.sql

insert into public.categories (name, description)
values
  ('Pizzas', 'Pizzas tradicionais e especiais'),
  ('Bebidas', 'Bebidas para acompanhar o pedido'),
  ('Sobremesas', 'Sobremesas da casa')
on conflict (name) do update set description = excluded.description;

insert into public.products (category_id, name, description, price)
select c.id, p.name, p.description, p.price
from (values
  ('Pizzas', 'Margherita', 'Molho de tomate, mussarela e manjericão', 39.90::numeric),
  ('Pizzas', 'Calabresa', 'Calabresa fatiada, cebola e mussarela', 42.90::numeric),
  ('Bebidas', 'Refrigerante 2L', 'Refrigerante de dois litros', 12.00::numeric),
  ('Sobremesas', 'Pizza de chocolate', 'Chocolate cremoso e granulado', 36.90::numeric)
) as p(category_name, name, description, price)
join public.categories c on c.name = p.category_name
on conflict (category_id, name) do update
set description = excluded.description,
    price = excluded.price,
    available = true;

