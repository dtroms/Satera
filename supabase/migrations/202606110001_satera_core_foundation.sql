create extension if not exists pgcrypto;

create type product_type as enum ('vertical', 'pro_console', 'portfolio');
create type product_status as enum ('draft', 'active', 'paused', 'retired');
create type platform_admin_role as enum ('super_admin', 'platform_admin', 'platform_support', 'trust_and_safety', 'read_only');
create type product_admin_role as enum ('product_owner', 'product_admin', 'product_support', 'product_moderator', 'product_analyst');
create type entitlement_key as enum (
  'cross_vertex_portfolio',
  'advanced_analytics',
  'insurance_exports',
  'bulk_import',
  'premium_saved_views',
  'vertex_pro',
  'cross_vertex_inventory',
  'multi_product_presence',
  'staff_accounts',
  'multi_location_inventory',
  'organization_analytics',
  'dealer_verification'
);
create type condition_type as enum ('raw', 'graded', 'sealed', 'authenticated', 'parts', 'unknown');
create type inventory_status as enum ('active', 'pending', 'sold', 'traded', 'consigned', 'at_grading', 'archived');
create type inventory_availability as enum ('available', 'unavailable', 'pending_return', 'committed', 'archived');
create type inventory_intent as enum ('hold', 'sell', 'trade', 'grade', 'research', 'unknown');
create type transaction_type as enum (
  'starting_inventory',
  'purchase_single',
  'purchase_lot',
  'sale',
  'trade',
  'grading_submission',
  'grading_return',
  'consignment_send',
  'consignment_sale',
  'adjustment',
  'correction',
  'location_transfer'
);
create type transaction_line_type as enum ('inventory', 'cash', 'fee', 'tax', 'shipping', 'basis', 'value', 'note');
create type transaction_direction as enum ('in', 'out', 'neutral');
create type ownership_event_type as enum (
  'starting_inventory',
  'purchase',
  'lot_purchase',
  'trade_in',
  'trade_out',
  'sale',
  'grading_submission',
  'grading_return',
  'consignment_send',
  'consignment_sale',
  'adjustment',
  'correction',
  'location_transfer',
  'archive'
);
create type basis_event_type as enum (
  'starting_basis',
  'purchase_basis',
  'lot_allocation',
  'trade_allocation',
  'grading_cost',
  'consignment_fee',
  'correction',
  'adjustment'
);
create type lot_allocation_method as enum ('proportional_by_estimated_value', 'equal_split', 'manual', 'anchor_item');

create or replace function set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table products (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null,
  product_type product_type not null,
  status product_status not null default 'draft',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table categories (
  id uuid primary key default gen_random_uuid(),
  parent_category_id uuid references categories(id) on delete restrict,
  slug text not null unique,
  name text not null,
  description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table product_categories (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references products(id) on delete cascade,
  category_id uuid not null references categories(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (product_id, category_id)
);

create table platform_admins (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  role platform_admin_role not null,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  unique (user_id, role)
);

create table product_admins (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references products(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role product_admin_role not null,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  unique (product_id, user_id, role)
);

create table account_entitlements (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  entitlement_key entitlement_key not null,
  starts_at timestamptz not null default now(),
  ends_at timestamptz,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  unique (user_id, entitlement_key)
);

create table workspaces (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  owner_user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table workspace_members (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'member',
  created_at timestamptz not null default now(),
  unique (workspace_id, user_id)
);

create table organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  owner_user_id uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table organization_memberships (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'member',
  created_at timestamptz not null default now(),
  unique (organization_id, user_id)
);

create table organization_entitlements (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  entitlement_key entitlement_key not null,
  starts_at timestamptz not null default now(),
  ends_at timestamptz,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  unique (organization_id, entitlement_key)
);

create table product_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  product_id uuid not null references products(id) on delete cascade,
  display_name text not null,
  handle text,
  profile_data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, product_id),
  unique (product_id, handle)
);

create table organization_product_profiles (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  product_id uuid not null references products(id) on delete cascade,
  display_name text not null,
  handle text,
  profile_data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (organization_id, product_id),
  unique (product_id, handle)
);

create table collections (
  id uuid primary key default gen_random_uuid(),
  category_id uuid not null references categories(id) on delete restrict,
  slug text not null,
  name text not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (category_id, slug)
);

create table asset_families (
  id uuid primary key default gen_random_uuid(),
  category_id uuid not null references categories(id) on delete restrict,
  collection_id uuid references collections(id) on delete set null,
  name text not null,
  canonical_key text,
  attributes jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table asset_variants (
  id uuid primary key default gen_random_uuid(),
  asset_family_id uuid not null references asset_families(id) on delete cascade,
  category_id uuid not null references categories(id) on delete restrict,
  name text not null,
  variant_key text,
  attributes jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table locations (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid references auth.users(id) on delete cascade,
  workspace_id uuid references workspaces(id) on delete cascade,
  organization_id uuid references organizations(id) on delete cascade,
  name text not null,
  location_type text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint locations_owner_context_required check (
    owner_user_id is not null or workspace_id is not null or organization_id is not null
  )
);

create table comp_snapshots (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid references auth.users(id) on delete cascade,
  workspace_id uuid references workspaces(id) on delete cascade,
  organization_id uuid references organizations(id) on delete cascade,
  category_id uuid not null references categories(id) on delete restrict,
  asset_family_id uuid references asset_families(id) on delete set null,
  asset_variant_id uuid references asset_variants(id) on delete set null,
  source text,
  source_url text,
  market_value numeric(14,2) not null check (market_value >= 0),
  currency_code text not null default 'USD',
  method text,
  number_of_comps integer check (number_of_comps is null or number_of_comps >= 0),
  condition_or_grade text,
  observed_at timestamptz not null default now(),
  snapshot_data jsonb not null default '{}'::jsonb,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  constraint comp_snapshots_owner_context_required check (
    owner_user_id is not null or workspace_id is not null or organization_id is not null
  )
);

create table inventory_items (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid references auth.users(id) on delete cascade,
  workspace_id uuid references workspaces(id) on delete cascade,
  organization_id uuid references organizations(id) on delete cascade,
  category_id uuid not null references categories(id) on delete restrict,
  asset_variant_id uuid not null references asset_variants(id) on delete restrict,
  condition_type condition_type not null default 'unknown',
  status inventory_status not null default 'active',
  availability inventory_availability not null default 'available',
  intent inventory_intent not null default 'hold',
  location_id uuid references locations(id) on delete set null,
  true_basis numeric(14,2) check (true_basis >= 0),
  current_value_snapshot_id uuid references comp_snapshots(id) on delete set null,
  acquired_at timestamptz,
  notes text,
  created_by uuid references auth.users(id) on delete set null,
  updated_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint inventory_items_owner_context_required check (
    owner_user_id is not null or workspace_id is not null or organization_id is not null
  )
);

alter table comp_snapshots
  add column inventory_item_id uuid references inventory_items(id) on delete set null;

create table asset_images (
  id uuid primary key default gen_random_uuid(),
  asset_variant_id uuid references asset_variants(id) on delete cascade,
  inventory_item_id uuid references inventory_items(id) on delete cascade,
  storage_path text not null,
  alt_text text,
  image_type text,
  sort_order integer not null default 0,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  constraint asset_images_target_required check (
    asset_variant_id is not null or inventory_item_id is not null
  )
);

create table transactions (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid references auth.users(id) on delete cascade,
  workspace_id uuid references workspaces(id) on delete cascade,
  organization_id uuid references organizations(id) on delete cascade,
  transaction_type transaction_type not null,
  transaction_date timestamptz not null,
  source text,
  counterparty text,
  notes text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  constraint transactions_owner_context_required check (
    owner_user_id is not null or workspace_id is not null or organization_id is not null
  )
);

create table transaction_lines (
  id uuid primary key default gen_random_uuid(),
  transaction_id uuid not null references transactions(id) on delete cascade,
  line_type transaction_line_type not null,
  inventory_item_id uuid references inventory_items(id) on delete set null,
  direction transaction_direction not null,
  amount numeric(14,2),
  market_value_at_time numeric(14,2),
  trade_value_at_time numeric(14,2),
  basis_at_time numeric(14,2),
  basis_allocated numeric(14,2),
  notes text,
  created_at timestamptz not null default now()
);

create table ownership_events (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid references workspaces(id) on delete cascade,
  organization_id uuid references organizations(id) on delete cascade,
  owner_user_id uuid references auth.users(id) on delete cascade,
  inventory_item_id uuid not null references inventory_items(id) on delete cascade,
  transaction_id uuid references transactions(id) on delete set null,
  event_type ownership_event_type not null,
  event_date timestamptz not null,
  previous_status inventory_status,
  new_status inventory_status,
  previous_owner_context jsonb,
  new_owner_context jsonb,
  notes text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  constraint ownership_events_owner_context_required check (
    owner_user_id is not null or workspace_id is not null or organization_id is not null
  )
);

create table basis_events (
  id uuid primary key default gen_random_uuid(),
  inventory_item_id uuid not null references inventory_items(id) on delete cascade,
  transaction_id uuid references transactions(id) on delete set null,
  basis_event_type basis_event_type not null,
  amount numeric(14,2) not null,
  previous_basis numeric(14,2) not null check (previous_basis >= 0),
  new_basis numeric(14,2) not null check (new_basis >= 0),
  calculation_method text not null,
  calculation_inputs jsonb not null default '{}'::jsonb,
  reason text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  constraint basis_events_correction_reason_required check (
    basis_event_type <> 'correction' or nullif(trim(reason), '') is not null
  )
);

create table basis_lineage_edges (
  id uuid primary key default gen_random_uuid(),
  transaction_id uuid not null references transactions(id) on delete cascade,
  source_inventory_item_id uuid references inventory_items(id) on delete set null,
  target_inventory_item_id uuid not null references inventory_items(id) on delete cascade,
  source_basis_amount numeric(14,2) not null default 0 check (source_basis_amount >= 0),
  cash_paid_amount numeric(14,2) not null default 0 check (cash_paid_amount >= 0),
  cash_received_amount numeric(14,2) not null default 0 check (cash_received_amount >= 0),
  fees_amount numeric(14,2) not null default 0 check (fees_amount >= 0),
  allocated_basis_amount numeric(14,2) not null check (allocated_basis_amount >= 0),
  allocation_method text not null,
  allocation_inputs jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table audit_events (
  id uuid primary key default gen_random_uuid(),
  actor_user_id uuid references auth.users(id) on delete set null,
  event_type text not null,
  entity_table text not null,
  entity_id uuid,
  owner_user_id uuid references auth.users(id) on delete set null,
  workspace_id uuid references workspaces(id) on delete set null,
  organization_id uuid references organizations(id) on delete set null,
  product_id uuid references products(id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index product_categories_product_id_idx on product_categories(product_id);
create index product_admins_product_id_user_id_idx on product_admins(product_id, user_id);
create index account_entitlements_user_key_idx on account_entitlements(user_id, entitlement_key);
create index organization_entitlements_org_key_idx on organization_entitlements(organization_id, entitlement_key);
create index inventory_items_owner_user_id_idx on inventory_items(owner_user_id);
create index inventory_items_workspace_id_idx on inventory_items(workspace_id);
create index inventory_items_organization_id_idx on inventory_items(organization_id);
create index inventory_items_category_id_idx on inventory_items(category_id);
create index comp_snapshots_owner_user_id_idx on comp_snapshots(owner_user_id);
create index comp_snapshots_workspace_id_idx on comp_snapshots(workspace_id);
create index comp_snapshots_organization_id_idx on comp_snapshots(organization_id);
create index comp_snapshots_inventory_item_id_idx on comp_snapshots(inventory_item_id);
create index transactions_owner_user_id_idx on transactions(owner_user_id);
create index transaction_lines_transaction_id_idx on transaction_lines(transaction_id);
create index ownership_events_inventory_item_id_idx on ownership_events(inventory_item_id);
create index basis_events_inventory_item_id_idx on basis_events(inventory_item_id);
create index basis_lineage_edges_transaction_id_idx on basis_lineage_edges(transaction_id);

create trigger products_set_updated_at before update on products for each row execute function set_updated_at();
create trigger categories_set_updated_at before update on categories for each row execute function set_updated_at();
create trigger workspaces_set_updated_at before update on workspaces for each row execute function set_updated_at();
create trigger organizations_set_updated_at before update on organizations for each row execute function set_updated_at();
create trigger product_profiles_set_updated_at before update on product_profiles for each row execute function set_updated_at();
create trigger organization_product_profiles_set_updated_at before update on organization_product_profiles for each row execute function set_updated_at();
create trigger collections_set_updated_at before update on collections for each row execute function set_updated_at();
create trigger asset_families_set_updated_at before update on asset_families for each row execute function set_updated_at();
create trigger asset_variants_set_updated_at before update on asset_variants for each row execute function set_updated_at();
create trigger locations_set_updated_at before update on locations for each row execute function set_updated_at();
create trigger inventory_items_set_updated_at before update on inventory_items for each row execute function set_updated_at();

create or replace function is_platform_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from platform_admins
    where user_id = auth.uid()
      and role in ('super_admin', 'platform_admin', 'platform_support', 'trust_and_safety')
  );
$$;

create or replace function is_product_admin(target_product_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from product_admins
    where product_admins.product_id = target_product_id
      and user_id = auth.uid()
      and role in ('product_owner', 'product_admin', 'product_support', 'product_moderator')
  );
$$;

create or replace function is_workspace_member(target_workspace_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from workspace_members
    where workspace_members.workspace_id = target_workspace_id
      and user_id = auth.uid()
  );
$$;

create or replace function is_organization_member(target_organization_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from organization_memberships
    where organization_memberships.organization_id = target_organization_id
      and user_id = auth.uid()
  );
$$;

create or replace function has_account_entitlement(target_user_id uuid, target_entitlement_key entitlement_key)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from account_entitlements
    where account_entitlements.user_id = target_user_id
      and account_entitlements.entitlement_key = target_entitlement_key
      and starts_at <= now()
      and (ends_at is null or ends_at > now())
  );
$$;

create or replace function has_organization_entitlement(target_organization_id uuid, target_entitlement_key entitlement_key)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from organization_entitlements
    where organization_entitlements.organization_id = target_organization_id
      and organization_entitlements.entitlement_key = target_entitlement_key
      and starts_at <= now()
      and (ends_at is null or ends_at > now())
  );
$$;

alter table products enable row level security;
alter table product_categories enable row level security;
alter table platform_admins enable row level security;
alter table product_admins enable row level security;
alter table account_entitlements enable row level security;
alter table organization_entitlements enable row level security;
alter table workspaces enable row level security;
alter table workspace_members enable row level security;
alter table organizations enable row level security;
alter table organization_memberships enable row level security;
alter table organization_product_profiles enable row level security;
alter table product_profiles enable row level security;
alter table categories enable row level security;
alter table collections enable row level security;
alter table asset_families enable row level security;
alter table asset_variants enable row level security;
alter table inventory_items enable row level security;
alter table locations enable row level security;
alter table asset_images enable row level security;
alter table comp_snapshots enable row level security;
alter table transactions enable row level security;
alter table transaction_lines enable row level security;
alter table ownership_events enable row level security;
alter table basis_events enable row level security;
alter table basis_lineage_edges enable row level security;
alter table audit_events enable row level security;

create policy "platform admins and product admins manage products" on products for all using (is_platform_admin() or is_product_admin(id)) with check (is_platform_admin() or is_product_admin(id));
create policy "authenticated users read active products" on products for select using (status = 'active' and auth.uid() is not null);

create policy "platform admins and product admins manage product categories" on product_categories for all using (is_platform_admin() or is_product_admin(product_id)) with check (is_platform_admin() or is_product_admin(product_id));
create policy "authenticated users read active product categories" on product_categories for select using (
  auth.uid() is not null
  and exists (
    select 1
    from products
    where products.id = product_categories.product_id
      and products.status = 'active'
  )
);
create policy "product admins read product categories" on product_categories for select using (is_product_admin(product_id));

create policy "platform admins manage platform admins" on platform_admins for all using (is_platform_admin()) with check (is_platform_admin());
create policy "platform admins manage product admins" on product_admins for all using (is_platform_admin()) with check (is_platform_admin());
create policy "product admins read peer product admins" on product_admins for select using (is_product_admin(product_id));

create policy "platform admins manage account entitlements" on account_entitlements for all using (is_platform_admin()) with check (is_platform_admin());
create policy "users read own account entitlements" on account_entitlements for select using (user_id = auth.uid());
create policy "platform admins manage organization entitlements" on organization_entitlements for all using (is_platform_admin()) with check (is_platform_admin());
create policy "organization members read organization entitlements" on organization_entitlements for select using (is_organization_member(organization_id));

create policy "users manage owned workspaces" on workspaces for all using (owner_user_id = auth.uid() or is_platform_admin()) with check (owner_user_id = auth.uid() or is_platform_admin());
create policy "workspace members read workspaces" on workspaces for select using (is_workspace_member(id));
create policy "workspace members read memberships" on workspace_members for select using (is_workspace_member(workspace_id) or is_platform_admin());
create policy "workspace owners manage memberships" on workspace_members for all using (
  is_platform_admin() or exists (select 1 from workspaces where workspaces.id = workspace_id and owner_user_id = auth.uid())
) with check (
  is_platform_admin() or exists (select 1 from workspaces where workspaces.id = workspace_id and owner_user_id = auth.uid())
);

create policy "users manage owned organizations" on organizations for all using (owner_user_id = auth.uid() or is_platform_admin()) with check (owner_user_id = auth.uid() or is_platform_admin());
create policy "organization members read organizations" on organizations for select using (is_organization_member(id));
create policy "organization members read memberships" on organization_memberships for select using (is_organization_member(organization_id) or is_platform_admin());
create policy "organization owners manage memberships" on organization_memberships for all using (
  is_platform_admin() or exists (select 1 from organizations where organizations.id = organization_id and owner_user_id = auth.uid())
) with check (
  is_platform_admin() or exists (select 1 from organizations where organizations.id = organization_id and owner_user_id = auth.uid())
);

create policy "users manage own product profiles" on product_profiles for all using (user_id = auth.uid() or is_platform_admin() or is_product_admin(product_id)) with check (user_id = auth.uid() or is_platform_admin() or is_product_admin(product_id));
create policy "organization members manage organization product profiles" on organization_product_profiles for all using (is_organization_member(organization_id) or is_platform_admin() or is_product_admin(product_id)) with check (is_organization_member(organization_id) or is_platform_admin() or is_product_admin(product_id));

create policy "authenticated users read categories" on categories for select using (auth.uid() is not null);
create policy "platform admins manage categories" on categories for all using (is_platform_admin()) with check (is_platform_admin());
create policy "authenticated users read collections" on collections for select using (auth.uid() is not null);
create policy "platform admins manage collections" on collections for all using (is_platform_admin()) with check (is_platform_admin());
create policy "authenticated users read asset families" on asset_families for select using (auth.uid() is not null);
create policy "platform admins manage asset families" on asset_families for all using (is_platform_admin()) with check (is_platform_admin());
create policy "authenticated users read asset variants" on asset_variants for select using (auth.uid() is not null);
create policy "platform admins manage asset variants" on asset_variants for all using (is_platform_admin()) with check (is_platform_admin());

create policy "owners and members read inventory" on inventory_items for select using (
  is_platform_admin()
  or owner_user_id = auth.uid()
  or (workspace_id is not null and is_workspace_member(workspace_id))
  or (organization_id is not null and is_organization_member(organization_id))
);
create policy "owners and members manage inventory" on inventory_items for all using (
  is_platform_admin()
  or owner_user_id = auth.uid()
  or (workspace_id is not null and is_workspace_member(workspace_id))
  or (organization_id is not null and is_organization_member(organization_id))
) with check (
  is_platform_admin()
  or owner_user_id = auth.uid()
  or (workspace_id is not null and is_workspace_member(workspace_id))
  or (organization_id is not null and is_organization_member(organization_id))
);

create policy "owners and members manage locations" on locations for all using (
  is_platform_admin()
  or owner_user_id = auth.uid()
  or (workspace_id is not null and is_workspace_member(workspace_id))
  or (organization_id is not null and is_organization_member(organization_id))
) with check (
  is_platform_admin()
  or owner_user_id = auth.uid()
  or (workspace_id is not null and is_workspace_member(workspace_id))
  or (organization_id is not null and is_organization_member(organization_id))
);

create policy "owners and members read asset images" on asset_images for select using (
  is_platform_admin()
  or inventory_item_id is null
  or exists (
    select 1 from inventory_items
    where inventory_items.id = asset_images.inventory_item_id
      and (
        inventory_items.owner_user_id = auth.uid()
        or (inventory_items.workspace_id is not null and is_workspace_member(inventory_items.workspace_id))
        or (inventory_items.organization_id is not null and is_organization_member(inventory_items.organization_id))
      )
  )
);
create policy "owners and members manage asset images" on asset_images for all using (is_platform_admin() or created_by = auth.uid()) with check (is_platform_admin() or created_by = auth.uid());

create policy "owners and members read comp snapshots" on comp_snapshots for select using (
  is_platform_admin()
  or owner_user_id = auth.uid()
  or (workspace_id is not null and is_workspace_member(workspace_id))
  or (organization_id is not null and is_organization_member(organization_id))
  or (
    inventory_item_id is not null
    and exists (
      select 1 from inventory_items
      where inventory_items.id = comp_snapshots.inventory_item_id
        and (
          inventory_items.owner_user_id = auth.uid()
          or (inventory_items.workspace_id is not null and is_workspace_member(inventory_items.workspace_id))
          or (inventory_items.organization_id is not null and is_organization_member(inventory_items.organization_id))
        )
    )
  )
);
create policy "owners and members manage comp snapshots" on comp_snapshots for all using (
  is_platform_admin()
  or owner_user_id = auth.uid()
  or (workspace_id is not null and is_workspace_member(workspace_id))
  or (organization_id is not null and is_organization_member(organization_id))
) with check (
  is_platform_admin()
  or owner_user_id = auth.uid()
  or (workspace_id is not null and is_workspace_member(workspace_id))
  or (organization_id is not null and is_organization_member(organization_id))
);

create policy "owners and members manage transactions" on transactions for all using (
  is_platform_admin()
  or owner_user_id = auth.uid()
  or (workspace_id is not null and is_workspace_member(workspace_id))
  or (organization_id is not null and is_organization_member(organization_id))
) with check (
  is_platform_admin()
  or owner_user_id = auth.uid()
  or (workspace_id is not null and is_workspace_member(workspace_id))
  or (organization_id is not null and is_organization_member(organization_id))
);

create policy "transaction owners and members manage lines" on transaction_lines for all using (
  is_platform_admin()
  or exists (
    select 1 from transactions
    where transactions.id = transaction_lines.transaction_id
      and (
        transactions.owner_user_id = auth.uid()
        or (transactions.workspace_id is not null and is_workspace_member(transactions.workspace_id))
        or (transactions.organization_id is not null and is_organization_member(transactions.organization_id))
      )
  )
) with check (
  is_platform_admin()
  or exists (
    select 1 from transactions
    where transactions.id = transaction_lines.transaction_id
      and (
        transactions.owner_user_id = auth.uid()
        or (transactions.workspace_id is not null and is_workspace_member(transactions.workspace_id))
        or (transactions.organization_id is not null and is_organization_member(transactions.organization_id))
      )
  )
);

create policy "owners and members manage ownership events" on ownership_events for all using (
  is_platform_admin()
  or owner_user_id = auth.uid()
  or (workspace_id is not null and is_workspace_member(workspace_id))
  or (organization_id is not null and is_organization_member(organization_id))
  or exists (
    select 1 from inventory_items
    where inventory_items.id = ownership_events.inventory_item_id
      and (
        inventory_items.owner_user_id = auth.uid()
        or (inventory_items.workspace_id is not null and is_workspace_member(inventory_items.workspace_id))
        or (inventory_items.organization_id is not null and is_organization_member(inventory_items.organization_id))
      )
  )
  or (
    transaction_id is not null
    and exists (
      select 1 from transactions
      where transactions.id = ownership_events.transaction_id
        and (
          transactions.owner_user_id = auth.uid()
          or (transactions.workspace_id is not null and is_workspace_member(transactions.workspace_id))
          or (transactions.organization_id is not null and is_organization_member(transactions.organization_id))
        )
    )
  )
) with check (
  is_platform_admin()
  or owner_user_id = auth.uid()
  or (workspace_id is not null and is_workspace_member(workspace_id))
  or (organization_id is not null and is_organization_member(organization_id))
  or exists (
    select 1 from inventory_items
    where inventory_items.id = ownership_events.inventory_item_id
      and (
        inventory_items.owner_user_id = auth.uid()
        or (inventory_items.workspace_id is not null and is_workspace_member(inventory_items.workspace_id))
        or (inventory_items.organization_id is not null and is_organization_member(inventory_items.organization_id))
      )
  )
  or (
    transaction_id is not null
    and exists (
      select 1 from transactions
      where transactions.id = ownership_events.transaction_id
        and (
          transactions.owner_user_id = auth.uid()
          or (transactions.workspace_id is not null and is_workspace_member(transactions.workspace_id))
          or (transactions.organization_id is not null and is_organization_member(transactions.organization_id))
        )
    )
  )
);

create policy "inventory owners and members manage basis events" on basis_events for all using (
  is_platform_admin()
  or exists (
    select 1 from inventory_items
    where inventory_items.id = basis_events.inventory_item_id
      and (
        inventory_items.owner_user_id = auth.uid()
        or (inventory_items.workspace_id is not null and is_workspace_member(inventory_items.workspace_id))
        or (inventory_items.organization_id is not null and is_organization_member(inventory_items.organization_id))
      )
  )
  or (
    transaction_id is not null
    and exists (
      select 1 from transactions
      where transactions.id = basis_events.transaction_id
        and (
          transactions.owner_user_id = auth.uid()
          or (transactions.workspace_id is not null and is_workspace_member(transactions.workspace_id))
          or (transactions.organization_id is not null and is_organization_member(transactions.organization_id))
        )
    )
  )
) with check (
  is_platform_admin()
  or exists (
    select 1 from inventory_items
    where inventory_items.id = basis_events.inventory_item_id
      and (
        inventory_items.owner_user_id = auth.uid()
        or (inventory_items.workspace_id is not null and is_workspace_member(inventory_items.workspace_id))
        or (inventory_items.organization_id is not null and is_organization_member(inventory_items.organization_id))
      )
  )
  or (
    transaction_id is not null
    and exists (
      select 1 from transactions
      where transactions.id = basis_events.transaction_id
        and (
          transactions.owner_user_id = auth.uid()
          or (transactions.workspace_id is not null and is_workspace_member(transactions.workspace_id))
          or (transactions.organization_id is not null and is_organization_member(transactions.organization_id))
        )
    )
  )
);

create policy "inventory owners and members manage basis lineage edges" on basis_lineage_edges for all using (
  is_platform_admin()
  or exists (
    select 1 from transactions
    where transactions.id = basis_lineage_edges.transaction_id
      and (
        transactions.owner_user_id = auth.uid()
        or (transactions.workspace_id is not null and is_workspace_member(transactions.workspace_id))
        or (transactions.organization_id is not null and is_organization_member(transactions.organization_id))
      )
  )
  or exists (
    select 1 from inventory_items
    where inventory_items.id = basis_lineage_edges.target_inventory_item_id
      and (
        inventory_items.owner_user_id = auth.uid()
        or (inventory_items.workspace_id is not null and is_workspace_member(inventory_items.workspace_id))
        or (inventory_items.organization_id is not null and is_organization_member(inventory_items.organization_id))
      )
  )
  or (
    source_inventory_item_id is not null
    and exists (
      select 1 from inventory_items
      where inventory_items.id = basis_lineage_edges.source_inventory_item_id
        and (
          inventory_items.owner_user_id = auth.uid()
          or (inventory_items.workspace_id is not null and is_workspace_member(inventory_items.workspace_id))
          or (inventory_items.organization_id is not null and is_organization_member(inventory_items.organization_id))
        )
    )
  )
) with check (
  is_platform_admin()
  or exists (
    select 1 from transactions
    where transactions.id = basis_lineage_edges.transaction_id
      and (
        transactions.owner_user_id = auth.uid()
        or (transactions.workspace_id is not null and is_workspace_member(transactions.workspace_id))
        or (transactions.organization_id is not null and is_organization_member(transactions.organization_id))
      )
  )
  or exists (
    select 1 from inventory_items
    where inventory_items.id = basis_lineage_edges.target_inventory_item_id
      and (
        inventory_items.owner_user_id = auth.uid()
        or (inventory_items.workspace_id is not null and is_workspace_member(inventory_items.workspace_id))
        or (inventory_items.organization_id is not null and is_organization_member(inventory_items.organization_id))
      )
  )
  or (
    source_inventory_item_id is not null
    and exists (
      select 1 from inventory_items
      where inventory_items.id = basis_lineage_edges.source_inventory_item_id
        and (
          inventory_items.owner_user_id = auth.uid()
          or (inventory_items.workspace_id is not null and is_workspace_member(inventory_items.workspace_id))
          or (inventory_items.organization_id is not null and is_organization_member(inventory_items.organization_id))
        )
    )
  )
);

create policy "related owners and admins read audit events" on audit_events for select using (
  is_platform_admin()
  or owner_user_id = auth.uid()
  or (workspace_id is not null and is_workspace_member(workspace_id))
  or (organization_id is not null and is_organization_member(organization_id))
  or (product_id is not null and is_product_admin(product_id))
);
create policy "related owners and admins create audit events" on audit_events for insert with check (
  is_platform_admin()
  or actor_user_id = auth.uid()
  or owner_user_id = auth.uid()
  or (workspace_id is not null and is_workspace_member(workspace_id))
  or (organization_id is not null and is_organization_member(organization_id))
  or (product_id is not null and is_product_admin(product_id))
);

grant usage on schema public to authenticated;
grant select, insert, update, delete on all tables in schema public to authenticated;
grant usage on all sequences in schema public to authenticated;
