alter table transaction_lines
add column if not exists metadata jsonb not null default '{}'::jsonb;

create or replace function create_lot_purchase_transaction(
  p_workspace_id uuid,
  p_product_id uuid default null,
  p_purchase_price numeric default 0,
  p_purchased_at timestamptz default now(),
  p_seller_reference text default null,
  p_marketplace text default null,
  p_order_reference text default null,
  p_buyer_fees numeric default 0,
  p_tax numeric default 0,
  p_shipping numeric default 0,
  p_other_acquisition_costs numeric default 0,
  p_allocation_method text default 'manual',
  p_items jsonb default '[]'::jsonb,
  p_notes text default null
)
returns table (
  transaction_id uuid,
  inventory_item_ids uuid[],
  total_lot_basis numeric
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor_user_id uuid := auth.uid();
  v_workspace workspaces;
  v_transaction_id uuid;
  v_owner_context jsonb;
  v_purchase_price numeric := round(coalesce(p_purchase_price, 0), 2);
  v_buyer_fees numeric := round(coalesce(p_buyer_fees, 0), 2);
  v_tax numeric := round(coalesce(p_tax, 0), 2);
  v_shipping numeric := round(coalesce(p_shipping, 0), 2);
  v_other_acquisition_costs numeric := round(coalesce(p_other_acquisition_costs, 0), 2);
  v_purchased_at timestamptz := coalesce(p_purchased_at, now());
  v_total_lot_basis numeric;
  v_item_count integer;
  v_method text := coalesce(nullif(trim(p_allocation_method), ''), 'manual');
  v_manual_sum numeric := 0;
  v_rounding_adjustment numeric := 0;
  v_item jsonb;
  v_item_index integer := 0;
  v_variant asset_variants;
  v_collection_id uuid;
  v_location locations;
  v_location_id uuid;
  v_condition condition_type;
  v_status inventory_status;
  v_availability inventory_availability;
  v_intent inventory_intent;
  v_allocated_basis numeric;
  v_equal_share numeric;
  v_inventory_item_id uuid;
  v_inventory_item_ids uuid[] := array[]::uuid[];
  v_transaction_metadata jsonb;
  v_item_snapshot jsonb;
begin
  if v_actor_user_id is null then
    raise exception 'authenticated user is required'
      using errcode = '42501';
  end if;

  if p_workspace_id is null then
    raise exception 'workspace is required for lot purchase'
      using errcode = '23502';
  end if;

  select *
  into v_workspace
  from workspaces
  where id = p_workspace_id;

  if not found then
    raise exception 'workspace not found'
      using errcode = 'P0002';
  end if;

  if not is_workspace_member(p_workspace_id) and not is_platform_admin() then
    raise exception 'workspace membership is required to create lot purchase'
      using errcode = '42501';
  end if;

  if p_product_id is not null and not exists (
    select 1 from products where id = p_product_id and status = 'active'
  ) then
    raise exception 'active product is required when product_id is provided'
      using errcode = '23514';
  end if;

  if v_purchase_price < 0
    or v_buyer_fees < 0
    or v_tax < 0
    or v_shipping < 0
    or v_other_acquisition_costs < 0 then
    raise exception 'lot purchase cost inputs cannot be negative'
      using errcode = '22003';
  end if;

  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'lot purchase requires at least one item'
      using errcode = '23514';
  end if;

  if v_method not in ('manual', 'equal') then
    raise exception 'unsupported lot allocation method: %', v_method
      using errcode = '23514';
  end if;

  v_item_count := jsonb_array_length(p_items);
  v_total_lot_basis := v_purchase_price
    + v_buyer_fees
    + v_tax
    + v_shipping
    + v_other_acquisition_costs;

  for v_item in select value from jsonb_array_elements(p_items)
  loop
    if nullif(v_item ->> 'asset_variant_id', '') is null then
      raise exception 'lot purchase item requires asset_variant_id'
        using errcode = '23502';
    end if;

    select *
    into v_variant
    from asset_variants
    where id = (v_item ->> 'asset_variant_id')::uuid;

    if not found then
      raise exception 'asset_variant_id does not exist: %', v_item ->> 'asset_variant_id'
        using errcode = 'P0002';
    end if;

    if p_product_id is not null and not exists (
      select 1
      from product_categories
      where product_id = p_product_id
        and category_id = v_variant.category_id
    ) then
      raise exception 'asset variant category is not available for product'
        using errcode = '23514';
    end if;

    v_collection_id := nullif(v_item ->> 'collection_id', '')::uuid;
    if v_collection_id is not null then
      if not exists (
        select 1
        from collections c
        where c.id = v_collection_id
          and c.category_id = v_variant.category_id
      ) then
        raise exception 'collection_id is invalid for item category'
          using errcode = '23514';
      end if;
    end if;

    v_location_id := nullif(v_item ->> 'location_id', '')::uuid;
    if v_location_id is not null then
      select *
      into v_location
      from locations
      where id = v_location_id;

      if not found then
        raise exception 'location_id does not exist: %', v_item ->> 'location_id'
          using errcode = 'P0002';
      end if;

      if v_location.workspace_id is distinct from p_workspace_id
        or v_location.owner_user_id is not null
        or v_location.organization_id is not null then
        raise exception 'location_id must belong to the lot purchase workspace'
          using errcode = '23514';
      end if;
    end if;

    if nullif(v_item ->> 'quantity', '') is not null
      and (v_item ->> 'quantity')::integer <> 1 then
      raise exception 'lot purchase quantity is not supported; provide one item per physical copy'
        using errcode = '23514';
    end if;

    if v_method = 'manual' then
      if nullif(v_item ->> 'allocated_basis', '') is null then
        raise exception 'manual lot allocation requires allocated_basis per item'
          using errcode = '23502';
      end if;

      v_allocated_basis := round((v_item ->> 'allocated_basis')::numeric, 2);

      if v_allocated_basis < 0 then
        raise exception 'allocated_basis cannot be negative'
          using errcode = '22003';
      end if;

      v_manual_sum := v_manual_sum + v_allocated_basis;
    end if;
  end loop;

  if v_method = 'manual' then
    if abs(v_manual_sum - v_total_lot_basis) > 0.01 then
      raise exception 'manual allocated basis must equal total lot basis'
        using errcode = '23514';
    end if;

    v_rounding_adjustment := v_total_lot_basis - v_manual_sum;
  end if;

  if v_method = 'equal' then
    v_equal_share := floor((v_total_lot_basis / v_item_count) * 100) / 100;
    v_rounding_adjustment := v_total_lot_basis - (v_equal_share * v_item_count);
  end if;

  v_owner_context := jsonb_build_object(
    'owner_user_id', null,
    'workspace_id', p_workspace_id,
    'organization_id', null
  );
  v_transaction_metadata := jsonb_build_object(
    'transaction_kind', 'lot_purchase',
    'purchase_price', v_purchase_price,
    'buyer_fees', v_buyer_fees,
    'tax', v_tax,
    'shipping', v_shipping,
    'other_acquisition_costs', v_other_acquisition_costs,
    'total_lot_basis', v_total_lot_basis,
    'allocation_method', v_method,
    'item_count', v_item_count,
    'rounding_adjustment', v_rounding_adjustment,
    'seller_reference', p_seller_reference,
    'marketplace', p_marketplace,
    'order_reference', p_order_reference,
    'purchased_at', v_purchased_at,
    'notes', p_notes
  );

  insert into transactions (
    owner_user_id,
    workspace_id,
    organization_id,
    transaction_type,
    transaction_date,
    source,
    counterparty,
    notes,
    metadata,
    created_by
  ) values (
    null,
    p_workspace_id,
    null,
    'purchase_lot',
    v_purchased_at,
    coalesce(p_marketplace, 'manual'),
    p_seller_reference,
    p_notes,
    v_transaction_metadata,
    v_actor_user_id
  )
  returning id into v_transaction_id;

  v_item_index := 0;
  for v_item in select value from jsonb_array_elements(p_items)
  loop
    v_item_index := v_item_index + 1;

    select *
    into v_variant
    from asset_variants
    where id = (v_item ->> 'asset_variant_id')::uuid;

    v_condition := coalesce(nullif(coalesce(v_item ->> 'condition_type', v_item ->> 'condition'), '')::condition_type, 'unknown');
    v_status := coalesce(nullif(v_item ->> 'inventory_status', '')::inventory_status, 'active');
    v_availability := coalesce(nullif(v_item ->> 'availability', '')::inventory_availability, 'available');
    v_intent := coalesce(nullif(v_item ->> 'intent', '')::inventory_intent, 'hold');
    v_location_id := nullif(v_item ->> 'location_id', '')::uuid;

    if v_method = 'manual' then
      v_allocated_basis := round((v_item ->> 'allocated_basis')::numeric, 2);
      if v_item_index = v_item_count then
        v_allocated_basis := v_allocated_basis + v_rounding_adjustment;
      end if;
    else
      v_allocated_basis := v_equal_share;
      if v_item_index = v_item_count then
        v_allocated_basis := v_allocated_basis + v_rounding_adjustment;
      end if;
    end if;

    if v_allocated_basis < 0 then
      raise exception 'allocated_basis cannot be negative after rounding adjustment'
        using errcode = '22003';
    end if;

    v_item_snapshot := jsonb_build_object(
      'item_index', v_item_index,
      'asset_variant_id', v_variant.id,
      'category_id', v_variant.category_id,
      'collection_id', nullif(v_item ->> 'collection_id', ''),
      'location_id', nullif(v_item ->> 'location_id', ''),
      'condition_type', v_condition,
      'inventory_status', v_status,
      'availability', v_availability,
      'intent', v_intent,
      'allocated_basis', v_allocated_basis,
      'allocation_method', v_method,
      'rounding_adjustment_applied', case when v_item_index = v_item_count then v_rounding_adjustment else 0 end,
      'acquisition_notes', coalesce(v_item ->> 'acquisition_notes', v_item ->> 'notes'),
      'private_notes_provided', nullif(v_item ->> 'private_notes', '') is not null
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
      null,
      p_workspace_id,
      null,
      v_variant.category_id,
      v_variant.id,
      v_condition,
      v_status,
      v_availability,
      v_intent,
      v_location_id,
      v_allocated_basis,
      null,
      v_purchased_at,
      coalesce(v_item ->> 'acquisition_notes', v_item ->> 'notes', v_item ->> 'private_notes'),
      v_actor_user_id,
      v_actor_user_id
    )
    returning id into v_inventory_item_id;

    v_inventory_item_ids := array_append(v_inventory_item_ids, v_inventory_item_id);

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
      notes,
      metadata
    ) values (
      v_transaction_id,
      'inventory',
      v_inventory_item_id,
      'in',
      null,
      null,
      null,
      null,
      v_allocated_basis,
      'Lot purchase incoming item. Basis allocated and frozen at purchase time.',
      v_item_snapshot
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
      null,
      p_workspace_id,
      null,
      v_inventory_item_id,
      v_transaction_id,
      'lot_purchase',
      v_purchased_at,
      null,
      v_status,
      null,
      v_owner_context,
      coalesce(v_item ->> 'acquisition_notes', v_item ->> 'notes'),
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
      'lot_allocation',
      v_allocated_basis,
      0,
      v_allocated_basis,
      'lot_purchase_total_basis_allocated_to_items',
      v_transaction_metadata || v_item_snapshot || jsonb_build_object(
        'source_transaction_id', v_transaction_id,
        'basis_formula', 'purchase_price + buyer_fees + tax + shipping + other_acquisition_costs'
      ),
      'Lot purchase allocated basis; true_basis is frozen at purchase time.',
      v_actor_user_id
    );

    insert into basis_lineage_edges (
      transaction_id,
      source_inventory_item_id,
      target_inventory_item_id,
      source_basis_amount,
      cash_paid_amount,
      cash_received_amount,
      fees_amount,
      allocated_basis_amount,
      allocation_method,
      allocation_inputs
    ) values (
      v_transaction_id,
      null,
      v_inventory_item_id,
      0,
      v_purchase_price,
      0,
      v_buyer_fees + v_tax + v_shipping + v_other_acquisition_costs,
      v_allocated_basis,
      v_method,
      v_transaction_metadata || v_item_snapshot || jsonb_build_object(
        'source', 'lot_purchase_transaction',
        'source_transaction_id', v_transaction_id
      )
    );
  end loop;

  if v_purchase_price > 0 then
    insert into transaction_lines (transaction_id, line_type, direction, amount, notes, metadata)
    values (v_transaction_id, 'cash', 'out', v_purchase_price, 'Lot purchase price paid.', v_transaction_metadata);
  end if;

  if v_buyer_fees > 0 then
    insert into transaction_lines (transaction_id, line_type, direction, amount, notes, metadata)
    values (v_transaction_id, 'fee', 'out', v_buyer_fees, 'Lot purchase buyer fees.', v_transaction_metadata);
  end if;

  if v_tax > 0 then
    insert into transaction_lines (transaction_id, line_type, direction, amount, notes, metadata)
    values (v_transaction_id, 'tax', 'out', v_tax, 'Lot purchase tax.', v_transaction_metadata);
  end if;

  if v_shipping > 0 then
    insert into transaction_lines (transaction_id, line_type, direction, amount, notes, metadata)
    values (v_transaction_id, 'shipping', 'out', v_shipping, 'Lot purchase shipping.', v_transaction_metadata);
  end if;

  if v_other_acquisition_costs > 0 then
    insert into transaction_lines (transaction_id, line_type, direction, amount, notes, metadata)
    values (v_transaction_id, 'fee', 'out', v_other_acquisition_costs, 'Lot purchase other acquisition costs.', v_transaction_metadata);
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
    'lot_purchase_transaction_created',
    'transactions',
    v_transaction_id,
    null,
    p_workspace_id,
    null,
    p_product_id,
    jsonb_build_object(
      'transaction_id', v_transaction_id,
      'workspace_id', p_workspace_id,
      'item_count', v_item_count,
      'purchase_price', v_purchase_price,
      'total_lot_basis', v_total_lot_basis,
      'allocation_method', v_method,
      'inventory_item_ids', to_jsonb(v_inventory_item_ids)
    )
  );

  transaction_id := v_transaction_id;
  inventory_item_ids := v_inventory_item_ids;
  total_lot_basis := v_total_lot_basis;
  return next;
end;
$$;

revoke all on function create_lot_purchase_transaction(
  uuid,
  uuid,
  numeric,
  timestamptz,
  text,
  text,
  text,
  numeric,
  numeric,
  numeric,
  numeric,
  text,
  jsonb,
  text
) from public, anon;

grant execute on function create_lot_purchase_transaction(
  uuid,
  uuid,
  numeric,
  timestamptz,
  text,
  text,
  text,
  numeric,
  numeric,
  numeric,
  numeric,
  text,
  jsonb,
  text
) to authenticated;
