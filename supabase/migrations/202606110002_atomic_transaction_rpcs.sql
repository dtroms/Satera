create or replace function create_starting_inventory_transaction(
  p_category_id uuid,
  p_asset_variant_id uuid,
  p_owner_user_id uuid default null,
  p_workspace_id uuid default null,
  p_organization_id uuid default null,
  p_condition_type condition_type default 'unknown',
  p_status inventory_status default 'active',
  p_availability inventory_availability default 'available',
  p_intent inventory_intent default 'hold',
  p_location_id uuid default null,
  p_initial_basis numeric default null,
  p_acquired_at timestamptz default null,
  p_notes text default null,
  p_transaction_date timestamptz default null,
  p_source text default null
)
returns table (
  inventory_item_id uuid,
  transaction_id uuid
)
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_actor_user_id uuid := auth.uid();
  v_inventory_item_id uuid;
  v_transaction_id uuid;
  v_transaction_date timestamptz := coalesce(p_transaction_date, now());
  v_owner_context jsonb;
begin
  if v_actor_user_id is null then
    raise exception 'authenticated user is required'
      using errcode = '42501';
  end if;

  if p_owner_user_id is null and p_workspace_id is null and p_organization_id is null then
    raise exception 'inventory requires a user, workspace, or organization owner context'
      using errcode = '23514';
  end if;

  if p_owner_user_id is not null and p_owner_user_id <> v_actor_user_id and not is_platform_admin() then
    raise exception 'cannot create inventory for another user'
      using errcode = '42501';
  end if;

  if p_workspace_id is not null and not is_workspace_member(p_workspace_id) and not is_platform_admin() then
    raise exception 'workspace membership is required to create workspace inventory'
      using errcode = '42501';
  end if;

  if p_organization_id is not null and not is_organization_member(p_organization_id) and not is_platform_admin() then
    raise exception 'organization membership is required to create organization inventory'
      using errcode = '42501';
  end if;

  if p_initial_basis is not null and p_initial_basis < 0 then
    raise exception 'initial basis cannot be negative'
      using errcode = '22003';
  end if;

  v_owner_context := jsonb_build_object(
    'owner_user_id', p_owner_user_id,
    'workspace_id', p_workspace_id,
    'organization_id', p_organization_id
  );

  insert into inventory_items (
    owner_user_id,
    workspace_id,
    organization_id,
    category_id,
    asset_variant_id,
    condition_type,
    status,
    availability,
    intent,
    location_id,
    true_basis,
    current_value_snapshot_id,
    acquired_at,
    notes,
    created_by,
    updated_by
  ) values (
    p_owner_user_id,
    p_workspace_id,
    p_organization_id,
    p_category_id,
    p_asset_variant_id,
    p_condition_type,
    p_status,
    p_availability,
    p_intent,
    p_location_id,
    p_initial_basis,
    null,
    coalesce(p_acquired_at, v_transaction_date),
    p_notes,
    v_actor_user_id,
    v_actor_user_id
  )
  returning id into v_inventory_item_id;

  insert into transactions (
    owner_user_id,
    workspace_id,
    organization_id,
    transaction_type,
    transaction_date,
    source,
    counterparty,
    notes,
    created_by
  ) values (
    p_owner_user_id,
    p_workspace_id,
    p_organization_id,
    'starting_inventory',
    v_transaction_date,
    coalesce(p_source, 'manual'),
    null,
    p_notes,
    v_actor_user_id
  )
  returning id into v_transaction_id;

  insert into transaction_lines (
    transaction_id,
    line_type,
    inventory_item_id,
    direction,
    amount,
    market_value_at_time,
    trade_value_at_time,
    basis_at_time,
    basis_allocated,
    notes
  ) values (
    v_transaction_id,
    'inventory',
    v_inventory_item_id,
    'in',
    null,
    null,
    null,
    null,
    p_initial_basis,
    'Starting inventory item.'
  );

  insert into ownership_events (
    owner_user_id,
    workspace_id,
    organization_id,
    inventory_item_id,
    transaction_id,
    event_type,
    event_date,
    previous_status,
    new_status,
    previous_owner_context,
    new_owner_context,
    notes,
    created_by
  ) values (
    p_owner_user_id,
    p_workspace_id,
    p_organization_id,
    v_inventory_item_id,
    v_transaction_id,
    'starting_inventory',
    v_transaction_date,
    null,
    p_status,
    null,
    v_owner_context,
    p_notes,
    v_actor_user_id
  );

  if p_initial_basis is not null then
    insert into basis_events (
      inventory_item_id,
      transaction_id,
      basis_event_type,
      amount,
      previous_basis,
      new_basis,
      calculation_method,
      calculation_inputs,
      reason,
      created_by
    ) values (
      v_inventory_item_id,
      v_transaction_id,
      'starting_basis',
      p_initial_basis,
      0,
      p_initial_basis,
      'starting_inventory',
      jsonb_build_object(
        'initial_basis', p_initial_basis,
        'basis_provided', true
      ),
      null,
      v_actor_user_id
    );
  end if;

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
    'starting_inventory_created',
    'inventory_items',
    v_inventory_item_id,
    p_owner_user_id,
    p_workspace_id,
    p_organization_id,
    null,
    jsonb_build_object(
      'transaction_id', v_transaction_id,
      'basis_provided', p_initial_basis is not null
    )
  );

  inventory_item_id := v_inventory_item_id;
  transaction_id := v_transaction_id;
  return next;
end;
$$;

create or replace function create_purchase_transaction(
  p_category_id uuid,
  p_asset_variant_id uuid,
  p_purchase_price numeric,
  p_buyer_fees numeric default 0,
  p_tax numeric default 0,
  p_shipping numeric default 0,
  p_direct_acquisition_costs numeric default 0,
  p_owner_user_id uuid default null,
  p_workspace_id uuid default null,
  p_organization_id uuid default null,
  p_condition_type condition_type default 'unknown',
  p_status inventory_status default 'active',
  p_availability inventory_availability default 'available',
  p_intent inventory_intent default 'hold',
  p_location_id uuid default null,
  p_acquired_at timestamptz default null,
  p_notes text default null,
  p_transaction_date timestamptz default null,
  p_source text default null,
  p_counterparty text default null
)
returns table (
  inventory_item_id uuid,
  transaction_id uuid
)
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_actor_user_id uuid := auth.uid();
  v_inventory_item_id uuid;
  v_transaction_id uuid;
  v_transaction_date timestamptz := coalesce(p_transaction_date, now());
  v_true_basis numeric := p_purchase_price
    + coalesce(p_buyer_fees, 0)
    + coalesce(p_tax, 0)
    + coalesce(p_shipping, 0)
    + coalesce(p_direct_acquisition_costs, 0);
  v_owner_context jsonb;
begin
  if v_actor_user_id is null then
    raise exception 'authenticated user is required'
      using errcode = '42501';
  end if;

  if p_owner_user_id is null and p_workspace_id is null and p_organization_id is null then
    raise exception 'inventory requires a user, workspace, or organization owner context'
      using errcode = '23514';
  end if;

  if p_owner_user_id is not null and p_owner_user_id <> v_actor_user_id and not is_platform_admin() then
    raise exception 'cannot create inventory for another user'
      using errcode = '42501';
  end if;

  if p_workspace_id is not null and not is_workspace_member(p_workspace_id) and not is_platform_admin() then
    raise exception 'workspace membership is required to create workspace inventory'
      using errcode = '42501';
  end if;

  if p_organization_id is not null and not is_organization_member(p_organization_id) and not is_platform_admin() then
    raise exception 'organization membership is required to create organization inventory'
      using errcode = '42501';
  end if;

  if p_purchase_price is null then
    raise exception 'purchase price is required'
      using errcode = '23502';
  end if;

  if p_purchase_price < 0
    or coalesce(p_buyer_fees, 0) < 0
    or coalesce(p_tax, 0) < 0
    or coalesce(p_shipping, 0) < 0
    or coalesce(p_direct_acquisition_costs, 0) < 0 then
    raise exception 'purchase basis inputs cannot be negative'
      using errcode = '22003';
  end if;

  v_owner_context := jsonb_build_object(
    'owner_user_id', p_owner_user_id,
    'workspace_id', p_workspace_id,
    'organization_id', p_organization_id
  );

  insert into inventory_items (
    owner_user_id,
    workspace_id,
    organization_id,
    category_id,
    asset_variant_id,
    condition_type,
    status,
    availability,
    intent,
    location_id,
    true_basis,
    current_value_snapshot_id,
    acquired_at,
    notes,
    created_by,
    updated_by
  ) values (
    p_owner_user_id,
    p_workspace_id,
    p_organization_id,
    p_category_id,
    p_asset_variant_id,
    p_condition_type,
    p_status,
    p_availability,
    p_intent,
    p_location_id,
    v_true_basis,
    null,
    coalesce(p_acquired_at, v_transaction_date),
    p_notes,
    v_actor_user_id,
    v_actor_user_id
  )
  returning id into v_inventory_item_id;

  insert into transactions (
    owner_user_id,
    workspace_id,
    organization_id,
    transaction_type,
    transaction_date,
    source,
    counterparty,
    notes,
    created_by
  ) values (
    p_owner_user_id,
    p_workspace_id,
    p_organization_id,
    'purchase_single',
    v_transaction_date,
    coalesce(p_source, 'manual'),
    p_counterparty,
    p_notes,
    v_actor_user_id
  )
  returning id into v_transaction_id;

  insert into transaction_lines (
    transaction_id,
    line_type,
    inventory_item_id,
    direction,
    amount,
    market_value_at_time,
    trade_value_at_time,
    basis_at_time,
    basis_allocated,
    notes
  ) values (
    v_transaction_id,
    'inventory',
    v_inventory_item_id,
    'in',
    p_purchase_price,
    null,
    null,
    null,
    v_true_basis,
    'Purchased inventory item.'
  );

  insert into ownership_events (
    owner_user_id,
    workspace_id,
    organization_id,
    inventory_item_id,
    transaction_id,
    event_type,
    event_date,
    previous_status,
    new_status,
    previous_owner_context,
    new_owner_context,
    notes,
    created_by
  ) values (
    p_owner_user_id,
    p_workspace_id,
    p_organization_id,
    v_inventory_item_id,
    v_transaction_id,
    'purchase',
    v_transaction_date,
    null,
    p_status,
    null,
    v_owner_context,
    p_notes,
    v_actor_user_id
  );

  insert into basis_events (
    inventory_item_id,
    transaction_id,
    basis_event_type,
    amount,
    previous_basis,
    new_basis,
    calculation_method,
    calculation_inputs,
    reason,
    created_by
  ) values (
    v_inventory_item_id,
    v_transaction_id,
    'purchase_basis',
    v_true_basis,
    0,
    v_true_basis,
    'purchase_price_plus_direct_costs',
    jsonb_build_object(
      'purchase_price', p_purchase_price,
      'buyer_fees', coalesce(p_buyer_fees, 0),
      'tax', coalesce(p_tax, 0),
      'shipping', coalesce(p_shipping, 0),
      'direct_acquisition_costs', coalesce(p_direct_acquisition_costs, 0)
    ),
    null,
    v_actor_user_id
  );

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
    'purchase_inventory_created',
    'inventory_items',
    v_inventory_item_id,
    p_owner_user_id,
    p_workspace_id,
    p_organization_id,
    null,
    jsonb_build_object(
      'transaction_id', v_transaction_id,
      'true_basis', v_true_basis
    )
  );

  inventory_item_id := v_inventory_item_id;
  transaction_id := v_transaction_id;
  return next;
end;
$$;

revoke all on function create_starting_inventory_transaction(
  uuid,
  uuid,
  uuid,
  uuid,
  uuid,
  condition_type,
  inventory_status,
  inventory_availability,
  inventory_intent,
  uuid,
  numeric,
  timestamptz,
  text,
  timestamptz,
  text
) from public, anon;

revoke all on function create_purchase_transaction(
  uuid,
  uuid,
  numeric,
  numeric,
  numeric,
  numeric,
  numeric,
  uuid,
  uuid,
  uuid,
  condition_type,
  inventory_status,
  inventory_availability,
  inventory_intent,
  uuid,
  timestamptz,
  text,
  timestamptz,
  text,
  text
) from public, anon;

grant execute on function create_starting_inventory_transaction(
  uuid,
  uuid,
  uuid,
  uuid,
  uuid,
  condition_type,
  inventory_status,
  inventory_availability,
  inventory_intent,
  uuid,
  numeric,
  timestamptz,
  text,
  timestamptz,
  text
) to authenticated;

grant execute on function create_purchase_transaction(
  uuid,
  uuid,
  numeric,
  numeric,
  numeric,
  numeric,
  numeric,
  uuid,
  uuid,
  uuid,
  condition_type,
  inventory_status,
  inventory_availability,
  inventory_intent,
  uuid,
  timestamptz,
  text,
  timestamptz,
  text,
  text
) to authenticated;
