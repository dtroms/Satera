create or replace function public_metadata_has_private_reference_keys(target jsonb)
returns boolean
language plpgsql
immutable
set search_path = public
as $$
declare
  v_key text;
  v_value jsonb;
begin
  if target is null then
    return false;
  end if;

  if jsonb_typeof(target) = 'object' then
    for v_key, v_value in
      select key, value
      from jsonb_each(target)
    loop
      if lower(v_key) in (
        'purchase_price',
        'true_basis',
        'cost_basis',
        'basis',
        'profit',
        'roi',
        'location',
        'private_notes',
        'private_tags',
        'ownership_history',
        'private_transaction_history',
        'grading_costs'
      ) then
        return true;
      end if;

      if public_metadata_has_private_reference_keys(v_value) then
        return true;
      end if;
    end loop;
  elsif jsonb_typeof(target) = 'array' then
    for v_value in
      select value
      from jsonb_array_elements(target)
    loop
      if public_metadata_has_private_reference_keys(v_value) then
        return true;
      end if;
    end loop;
  end if;

  return false;
end;
$$;

create table public_object_references (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid references auth.users(id) on delete cascade,
  workspace_id uuid references workspaces(id) on delete cascade,
  organization_id uuid references organizations(id) on delete cascade,
  product_id uuid not null references products(id) on delete restrict,
  category_id uuid references categories(id) on delete set null,
  inventory_item_id uuid references inventory_items(id) on delete set null,
  asset_family_id uuid references asset_families(id) on delete set null,
  asset_variant_id uuid references asset_variants(id) on delete set null,
  object_type text not null,
  display_title text not null,
  display_subtitle text,
  display_label text,
  display_image_url text,
  condition_label text,
  grade_label text,
  value_label text,
  value_snapshot_id uuid references comp_snapshots(id) on delete set null,
  visibility text not null default 'private_reference',
  exposure_state text not null default 'active',
  created_for text,
  created_from text,
  public_metadata jsonb not null default '{}'::jsonb,
  created_by uuid references auth.users(id) on delete set null,
  updated_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint public_object_references_exactly_one_owner_context check (
    num_nonnulls(owner_user_id, workspace_id, organization_id) = 1
  ),
  constraint public_object_references_visibility_check check (
    visibility in (
      'private_reference',
      'community',
      'listing',
      'showcase',
      'trade',
      'public'
    )
  ),
  constraint public_object_references_exposure_state_check check (
    exposure_state in ('active', 'hidden', 'removed', 'expired', 'revoked')
  ),
  constraint public_object_references_object_type_non_empty check (
    nullif(trim(object_type), '') is not null
  ),
  constraint public_object_references_display_title_non_empty check (
    nullif(trim(display_title), '') is not null
  ),
  constraint public_object_references_public_metadata_safe check (
    not public_metadata_has_private_reference_keys(public_metadata)
  )
);

comment on table public_object_references is
  'Safe exposure/display references for private inventory objects. This table is not the inventory source of truth and must not contain private financial, basis, storage, notes, tag, ownership history, or transaction history data.';
comment on column public_object_references.public_metadata is
  'Safe product-facing metadata only. Do not store true_basis, purchase price, profit, location, private notes, private tags, ownership history, or private transaction history.';

create index public_object_references_owner_user_id_idx on public_object_references(owner_user_id);
create index public_object_references_workspace_id_idx on public_object_references(workspace_id);
create index public_object_references_organization_id_idx on public_object_references(organization_id);
create index public_object_references_product_id_idx on public_object_references(product_id);
create index public_object_references_category_id_idx on public_object_references(category_id);
create index public_object_references_inventory_item_id_idx on public_object_references(inventory_item_id);
create index public_object_references_asset_family_id_idx on public_object_references(asset_family_id);
create index public_object_references_asset_variant_id_idx on public_object_references(asset_variant_id);
create index public_object_references_visibility_idx on public_object_references(visibility);
create index public_object_references_exposure_state_idx on public_object_references(exposure_state);
create index public_object_references_created_at_idx on public_object_references(created_at);

create trigger public_object_references_set_updated_at
before update on public_object_references
for each row execute function set_updated_at();

alter table public_object_references enable row level security;

create policy "owners and members read public object references"
on public_object_references
for select
using (
  owner_user_id = auth.uid()
  or (workspace_id is not null and is_workspace_member(workspace_id))
  or (organization_id is not null and is_organization_member(organization_id))
);

create policy "authenticated users read active exposed public object references"
on public_object_references
for select
using (
  auth.uid() is not null
  and exposure_state = 'active'
  and visibility in ('community', 'listing', 'showcase', 'trade', 'public')
);

create policy "platform admins read all public object references"
on public_object_references
for select
using (is_platform_admin());

grant select on public_object_references to authenticated;
revoke insert, update, delete on public_object_references from authenticated, anon;

create or replace function assert_public_reference_metadata_safe(target jsonb)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if target is null then
    return;
  end if;

  if public_metadata_has_private_reference_keys(target) then
    raise exception 'public metadata contains private inventory fields'
      using errcode = '23514';
  end if;
end;
$$;

create or replace function create_public_object_reference(
  p_inventory_item_id uuid,
  p_product_id uuid,
  p_visibility text default 'private_reference',
  p_created_for text default null,
  p_display_title text default null,
  p_display_subtitle text default null,
  p_display_label text default null,
  p_display_image_url text default null,
  p_condition_label text default null,
  p_grade_label text default null,
  p_value_label text default null,
  p_value_snapshot_id uuid default null,
  p_public_metadata jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor_user_id uuid := auth.uid();
  v_inventory inventory_items;
  v_product products;
  v_variant asset_variants;
  v_family asset_families;
  v_snapshot comp_snapshots;
  v_reference_id uuid;
  v_value_snapshot_id uuid;
  v_value_label text;
begin
  if v_actor_user_id is null then
    raise exception 'authenticated user is required'
      using errcode = '42501';
  end if;

  if p_visibility not in ('private_reference', 'community', 'listing', 'showcase', 'trade', 'public') then
    raise exception 'invalid public object reference visibility'
      using errcode = '23514';
  end if;

  perform assert_public_reference_metadata_safe(coalesce(p_public_metadata, '{}'::jsonb));

  select *
  into v_inventory
  from inventory_items
  where id = p_inventory_item_id
  for share;

  if not found then
    raise exception 'inventory item not found'
      using errcode = 'P0002';
  end if;

  if not coalesce((
    is_platform_admin()
    or v_inventory.owner_user_id = v_actor_user_id
    or (v_inventory.workspace_id is not null and is_workspace_member(v_inventory.workspace_id))
    or (v_inventory.organization_id is not null and is_organization_member(v_inventory.organization_id))
  ), false) then
    raise exception 'inventory item access is required'
      using errcode = '42501';
  end if;

  select *
  into v_product
  from products
  where id = p_product_id
    and status = 'active';

  if not found then
    raise exception 'active product is required'
      using errcode = 'P0002';
  end if;

  if exists (select 1 from product_categories where product_id = p_product_id)
    and not exists (
      select 1
      from product_categories
      where product_id = p_product_id
        and category_id = v_inventory.category_id
    ) then
    raise exception 'inventory category is not available for product'
      using errcode = '42501';
  end if;

  select *
  into v_variant
  from asset_variants
  where id = v_inventory.asset_variant_id;

  if found then
    select *
    into v_family
    from asset_families
    where id = v_variant.asset_family_id;
  end if;

  v_value_snapshot_id := coalesce(p_value_snapshot_id, v_inventory.current_value_snapshot_id);

  if v_value_snapshot_id is not null then
    select *
    into v_snapshot
    from comp_snapshots
    where id = v_value_snapshot_id;

    if not found then
      raise exception 'value snapshot not found'
        using errcode = 'P0002';
    end if;

    if not coalesce((
      is_platform_admin()
      or v_snapshot.owner_user_id = v_actor_user_id
      or v_snapshot.owner_user_id = v_inventory.owner_user_id
      or (v_snapshot.workspace_id is not null and v_snapshot.workspace_id = v_inventory.workspace_id)
      or (v_snapshot.organization_id is not null and v_snapshot.organization_id = v_inventory.organization_id)
    ), false) then
      raise exception 'value snapshot access is required'
        using errcode = '42501';
    end if;

    v_value_label := coalesce(
      p_value_label,
      trim(to_char(v_snapshot.market_value, 'FM999999999999990.00')) || ' ' || v_snapshot.currency_code
    );
  else
    v_value_label := p_value_label;
  end if;

  insert into public_object_references (
    owner_user_id,
    workspace_id,
    organization_id,
    product_id,
    category_id,
    inventory_item_id,
    asset_family_id,
    asset_variant_id,
    object_type,
    display_title,
    display_subtitle,
    display_label,
    display_image_url,
    condition_label,
    grade_label,
    value_label,
    value_snapshot_id,
    visibility,
    exposure_state,
    created_for,
    created_from,
    public_metadata,
    created_by,
    updated_by
  ) values (
    v_inventory.owner_user_id,
    v_inventory.workspace_id,
    v_inventory.organization_id,
    p_product_id,
    v_inventory.category_id,
    v_inventory.id,
    v_family.id,
    v_inventory.asset_variant_id,
    coalesce((select slug from categories where id = v_inventory.category_id), 'inventory_object'),
    coalesce(nullif(trim(p_display_title), ''), v_variant.name, v_family.name, 'Inventory object'),
    coalesce(nullif(trim(p_display_subtitle), ''), nullif(v_family.name, v_variant.name)),
    p_display_label,
    p_display_image_url,
    coalesce(p_condition_label, initcap(replace(v_inventory.condition_type::text, '_', ' '))),
    coalesce(
      p_grade_label,
      v_variant.attributes ->> 'grade_label',
      v_variant.attributes ->> 'grade'
    ),
    v_value_label,
    v_value_snapshot_id,
    p_visibility,
    'active',
    p_created_for,
    'inventory_item',
    coalesce(p_public_metadata, '{}'::jsonb),
    v_actor_user_id,
    v_actor_user_id
  )
  returning id into v_reference_id;

  insert into audit_events (
    actor_user_id,
    event_type,
    entity_table,
    entity_id,
    owner_user_id,
    workspace_id,
    organization_id,
    product_id,
    metadata
  ) values (
    v_actor_user_id,
    'public_object_reference_created',
    'public_object_references',
    v_reference_id,
    v_inventory.owner_user_id,
    v_inventory.workspace_id,
    v_inventory.organization_id,
    p_product_id,
    jsonb_build_object(
      'inventory_item_id', v_inventory.id,
      'visibility', p_visibility,
      'created_for', p_created_for
    )
  );

  return v_reference_id;
end;
$$;

create or replace function revoke_public_object_reference(
  p_public_object_reference_id uuid,
  p_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor_user_id uuid := auth.uid();
  v_reference public_object_references;
begin
  if v_actor_user_id is null then
    raise exception 'authenticated user is required'
      using errcode = '42501';
  end if;

  select *
  into v_reference
  from public_object_references
  where id = p_public_object_reference_id
  for update;

  if not found then
    raise exception 'public object reference not found'
      using errcode = 'P0002';
  end if;

  if not coalesce((
    is_platform_admin()
    or v_reference.owner_user_id = v_actor_user_id
    or (v_reference.workspace_id is not null and is_workspace_member(v_reference.workspace_id))
    or (v_reference.organization_id is not null and is_organization_member(v_reference.organization_id))
  ), false) then
    raise exception 'public object reference access is required'
      using errcode = '42501';
  end if;

  update public_object_references
  set
    exposure_state = 'revoked',
    updated_by = v_actor_user_id,
    updated_at = now()
  where id = p_public_object_reference_id
  returning * into v_reference;

  insert into audit_events (
    actor_user_id,
    event_type,
    entity_table,
    entity_id,
    owner_user_id,
    workspace_id,
    organization_id,
    product_id,
    metadata
  ) values (
    v_actor_user_id,
    'public_object_reference_revoked',
    'public_object_references',
    v_reference.id,
    v_reference.owner_user_id,
    v_reference.workspace_id,
    v_reference.organization_id,
    v_reference.product_id,
    jsonb_build_object('reason', p_reason)
  );

  return v_reference.id;
end;
$$;

create or replace function update_public_object_reference_display(
  p_public_object_reference_id uuid,
  p_display_title text default null,
  p_display_subtitle text default null,
  p_display_label text default null,
  p_display_image_url text default null,
  p_condition_label text default null,
  p_grade_label text default null,
  p_value_label text default null,
  p_value_snapshot_id uuid default null,
  p_public_metadata jsonb default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor_user_id uuid := auth.uid();
  v_reference public_object_references;
  v_snapshot comp_snapshots;
begin
  if v_actor_user_id is null then
    raise exception 'authenticated user is required'
      using errcode = '42501';
  end if;

  if p_public_metadata is not null then
    perform assert_public_reference_metadata_safe(p_public_metadata);
  end if;

  select *
  into v_reference
  from public_object_references
  where id = p_public_object_reference_id
  for update;

  if not found then
    raise exception 'public object reference not found'
      using errcode = 'P0002';
  end if;

  if not coalesce((
    is_platform_admin()
    or v_reference.owner_user_id = v_actor_user_id
    or (v_reference.workspace_id is not null and is_workspace_member(v_reference.workspace_id))
    or (v_reference.organization_id is not null and is_organization_member(v_reference.organization_id))
  ), false) then
    raise exception 'public object reference access is required'
      using errcode = '42501';
  end if;

  if p_value_snapshot_id is not null then
    select *
    into v_snapshot
    from comp_snapshots
    where id = p_value_snapshot_id;

    if not found then
      raise exception 'value snapshot not found'
        using errcode = 'P0002';
    end if;

    if not coalesce((
      is_platform_admin()
      or v_snapshot.owner_user_id = v_actor_user_id
      or v_snapshot.owner_user_id = v_reference.owner_user_id
      or (v_snapshot.workspace_id is not null and v_snapshot.workspace_id = v_reference.workspace_id)
      or (v_snapshot.organization_id is not null and v_snapshot.organization_id = v_reference.organization_id)
    ), false) then
      raise exception 'value snapshot access is required'
        using errcode = '42501';
    end if;
  end if;

  update public_object_references
  set
    display_title = coalesce(nullif(trim(p_display_title), ''), display_title),
    display_subtitle = coalesce(p_display_subtitle, display_subtitle),
    display_label = coalesce(p_display_label, display_label),
    display_image_url = coalesce(p_display_image_url, display_image_url),
    condition_label = coalesce(p_condition_label, condition_label),
    grade_label = coalesce(p_grade_label, grade_label),
    value_label = coalesce(p_value_label, value_label),
    value_snapshot_id = coalesce(p_value_snapshot_id, value_snapshot_id),
    public_metadata = coalesce(p_public_metadata, public_metadata),
    updated_by = v_actor_user_id,
    updated_at = now()
  where id = p_public_object_reference_id
  returning * into v_reference;

  insert into audit_events (
    actor_user_id,
    event_type,
    entity_table,
    entity_id,
    owner_user_id,
    workspace_id,
    organization_id,
    product_id,
    metadata
  ) values (
    v_actor_user_id,
    'public_object_reference_display_updated',
    'public_object_references',
    v_reference.id,
    v_reference.owner_user_id,
    v_reference.workspace_id,
    v_reference.organization_id,
    v_reference.product_id,
    jsonb_build_object(
      'updated_display', true,
      'value_snapshot_id', p_value_snapshot_id
    )
  );

  return v_reference.id;
end;
$$;

revoke all on function assert_public_reference_metadata_safe(jsonb) from public, anon;
revoke all on function create_public_object_reference(
  uuid,
  uuid,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  uuid,
  jsonb
) from public, anon;
revoke all on function revoke_public_object_reference(uuid, text) from public, anon;
revoke all on function update_public_object_reference_display(
  uuid,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  uuid,
  jsonb
) from public, anon;

grant execute on function create_public_object_reference(
  uuid,
  uuid,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  uuid,
  jsonb
) to authenticated;
grant execute on function revoke_public_object_reference(uuid, text) to authenticated;
grant execute on function update_public_object_reference_display(
  uuid,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  uuid,
  jsonb
) to authenticated;
