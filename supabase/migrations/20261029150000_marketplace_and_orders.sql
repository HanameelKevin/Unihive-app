create table public.shops (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid references auth.users (id) on delete set null,
  name text not null,
  tagline text not null default '',
  banner_url text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.products (
  id uuid primary key default gen_random_uuid(),
  shop_id uuid not null references public.shops (id) on delete restrict,
  title text not null,
  description text not null default '',
  price_kes integer not null check (price_kes between 1 and 1000000),
  condition text not null default 'new'
    check (condition in ('new', 'like_new', 'good')),
  category text not null,
  location text,
  image_url text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create index products_active_created_at_idx
  on public.products (created_at desc)
  where is_active;

create table public.orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete restrict,
  delivery_method text not null
    check (delivery_method in ('pickup', 'meet_seller', 'doorstep')),
  delivery_amount_kes integer not null check (delivery_amount_kes in (0, 150, 300)),
  total_amount_kes integer not null check (total_amount_kes > 0),
  payment_status text not null default 'pending'
    check (payment_status in ('pending', 'paid', 'cancelled')),
  created_at timestamptz not null default now()
);

create index orders_user_created_at_idx
  on public.orders (user_id, created_at desc);

create table public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete cascade,
  product_id uuid not null references public.products (id) on delete restrict,
  product_title text not null,
  unit_price_kes integer not null check (unit_price_kes > 0),
  quantity integer not null check (quantity between 1 and 99),
  line_total_kes integer generated always as (unit_price_kes * quantity) stored
);

create index order_items_order_id_idx on public.order_items (order_id);

create table public.mpesa_payments (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete restrict,
  user_id uuid not null references auth.users (id) on delete restrict,
  amount_kes integer not null check (amount_kes > 0),
  phone_number text not null,
  status text not null default 'initiating'
    check (status in ('initiating', 'pending', 'paid', 'failed')),
  merchant_request_id text,
  checkout_request_id text unique,
  receipt_number text unique,
  result_code integer,
  result_description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index mpesa_one_active_payment_per_order_idx
  on public.mpesa_payments (order_id)
  where status in ('initiating', 'pending', 'paid');

alter table public.shops enable row level security;
alter table public.products enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.mpesa_payments enable row level security;

create policy "Anyone can view active shops"
  on public.shops for select
  using (is_active);

create policy "Anyone can view active products"
  on public.products for select
  using (is_active);

create policy "Users can view their own orders"
  on public.orders for select to authenticated
  using (user_id = (select auth.uid()));

create policy "Users can view their own order items"
  on public.order_items for select to authenticated
  using (
    exists (
      select 1 from public.orders
      where orders.id = order_items.order_id
        and orders.user_id = (select auth.uid())
    )
  );

create policy "Users can view their own payment status"
  on public.mpesa_payments for select to authenticated
  using (user_id = (select auth.uid()));

revoke all on public.shops, public.products, public.orders,
  public.order_items, public.mpesa_payments from anon, authenticated;
grant select on public.shops, public.products to anon, authenticated;
grant select on public.orders, public.order_items, public.mpesa_payments to authenticated;

create or replace function public.create_order(
  p_user_id uuid,
  p_items jsonb,
  p_delivery_method text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  item jsonb;
  product_row public.products%rowtype;
  item_quantity integer;
  order_id uuid := gen_random_uuid();
  total_kes bigint := 0;
  delivery_kes integer;
  item_count integer;
begin
  if p_user_id is null
    or p_items is null
    or jsonb_typeof(p_items) is distinct from 'array' then
    raise exception 'Invalid order input' using errcode = '22023';
  end if;

  delivery_kes := case p_delivery_method
    when 'pickup' then 150
    when 'meet_seller' then 0
    when 'doorstep' then 300
    else null
  end;
  if delivery_kes is null then
    raise exception 'Invalid delivery method' using errcode = '22023';
  end if;

  item_count := jsonb_array_length(p_items);
  if item_count < 1 or item_count > 50 then
    raise exception 'Order must contain between 1 and 50 items' using errcode = '22023';
  end if;

  insert into public.orders (
    id, user_id, delivery_method, delivery_amount_kes, total_amount_kes
  ) values (
    order_id, p_user_id, p_delivery_method, delivery_kes, 1
  );

  for item in select value from jsonb_array_elements(p_items)
  loop
    if jsonb_typeof(item -> 'productId') is distinct from 'string'
      or jsonb_typeof(item -> 'quantity') is distinct from 'number' then
      raise exception 'Invalid order item' using errcode = '22023';
    end if;

    if (item ->> 'quantity')::numeric <> trunc((item ->> 'quantity')::numeric) then
      raise exception 'Invalid item quantity' using errcode = '22023';
    end if;

    item_quantity := (item ->> 'quantity')::integer;
    if item_quantity < 1 or item_quantity > 99 then
      raise exception 'Invalid item quantity' using errcode = '22023';
    end if;

    select * into product_row
    from public.products
    where id = (item ->> 'productId')::uuid
      and is_active
    for share;

    if not found then
      raise exception 'Product is unavailable' using errcode = '22023';
    end if;

    total_kes := total_kes + product_row.price_kes::bigint * item_quantity;
    if total_kes > 100000000 then
      raise exception 'Order total exceeds limit' using errcode = '22023';
    end if;

    insert into public.order_items (
      order_id, product_id, product_title, unit_price_kes, quantity
    ) values (
      order_id, product_row.id, product_row.title,
      product_row.price_kes, item_quantity
    );
  end loop;

  total_kes := total_kes + delivery_kes;
  if total_kes > 100000000 then
    raise exception 'Order total exceeds limit' using errcode = '22023';
  end if;

  update public.orders
  set total_amount_kes = total_kes::integer
  where id = order_id;

  return jsonb_build_object('id', order_id, 'totalAmountKes', total_kes);
end;
$$;

revoke all on function public.create_order(uuid, jsonb, text) from public, anon, authenticated;
grant execute on function public.create_order(uuid, jsonb, text) to service_role;

create or replace function public.confirm_mpesa_payment(
  p_payment_id uuid,
  p_receipt_number text
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  payment_row public.mpesa_payments%rowtype;
begin
  if p_receipt_number is null or length(p_receipt_number) < 1 then
    raise exception 'Invalid M-Pesa receipt' using errcode = '22023';
  end if;

  select * into payment_row
  from public.mpesa_payments
  where id = p_payment_id
  for update;

  if not found then
    return false;
  end if;

  if payment_row.status = 'paid' then
    return payment_row.receipt_number = p_receipt_number;
  end if;
  if payment_row.status <> 'pending' then
    return false;
  end if;

  update public.orders
  set payment_status = 'paid'
  where id = payment_row.order_id
    and user_id = payment_row.user_id
    and total_amount_kes = payment_row.amount_kes
    and payment_status = 'pending';

  if not found then
    return false;
  end if;

  update public.mpesa_payments
  set status = 'paid',
      receipt_number = p_receipt_number,
      result_code = 0,
      updated_at = now()
  where id = payment_row.id;

  return true;
end;
$$;

revoke all on function public.confirm_mpesa_payment(uuid, text) from public, anon, authenticated;
grant execute on function public.confirm_mpesa_payment(uuid, text) to service_role;
