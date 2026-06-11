create or replace function create_trade_transaction(
  p_owner_user_id uuid default null,
  p_workspace_id uuid default null,
  p_organization_id uuid default null,
  p_transaction_date timestamptz default null,
  p_source text default null,
  p_counterparty text default null,
  p_notes text default null,
  p_outgoing_items jsonb default '[]'::jsonb,
  p_incoming_items jsonb default '[]'::jsonb,
  p_cash_paid numeric default 0,
  p_cash_received numeric default 0,
  p_trade_related_costs numeric default 0
)
returns table (
  transaction_id uuid,
  incoming_inventory_item_ids uuid[],
  outgoing_inventory_item_ids uuid[]
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor_user_id uuid := auth.uid();
  v_transaction_id uuid;
  v_transaction_date timestamptz := coalesce(p_transaction_date, now());
  v_owner_context jsonb;
  v_outgoing_basis_total numeric := 0;
  v_total_incoming_trade_value numeric := 0;
  v_basis_pool numeric;
  v_excess_realized_profit numeric := 0;
  v_outgoing jsonb;
  v_incoming jsonb;
  v_outgoing_item inventory_items;
  v_incoming_item_id uuid;
  v_trade_value numeric;
  v_allocated_basis numeric;
  v_source_basis_share numeric;
  v_outgoing_count integer := 0;
  v_incoming_ids uuid[] := array[]::uuid[];
  v_outgoing_ids uuid[] := array[]::uuid[];
  v_source record;
begin
  if v_actor_user_id is null then
    raise exception 'authenticated user is required'
      using errcode = '42501';
  end if;

  if p_owner_user_id is null and p_workspace_id is null and p_organization_id is null then
    raise exception 'trade requires a user, workspace, or organization owner context'
      using errcode = '23514';
  end if;

  if p_owner_user_id is not null and p_owner_user_id <> v_actor_user_id and not is_platform_admin() then
    raise exception 'cannot create trade for another user'
      using errcode = '42501';
  end if;

  if p_workspace_id is not null and not is_workspace_member(p_workspace_id) and not is_platform_admin() then
    raise exception 'workspace membership is required to create workspace trade'
      using errcode = '42501';
  end if;

  if p_organization_id is not null and not is_organization_member(p_organization_id) and not is_platform_admin() then
    raise exception 'organization membership is required to create organization trade'
      using errcode = '42501';
  end if;

  if jsonb_typeof(p_outgoing_items) <> 'array' or jsonb_array_length(p_outgoing_items) = 0 then
    raise exception 'trade requires at least one outgoing item'
      using errcode = '23514';
  end if;

  if jsonb_typeof(p_incoming_items) <> 'array' or jsonb_array_length(p_incoming_items) = 0 then
    raise exception 'trade requires at least one incoming item'
      using errcode = '23514';
  end if;

  if coalesce(p_cash_paid, 0) < 0
    or coalesce(p_cash_received, 0) < 0
    or coalesce(p_trade_related_costs, 0) < 0 then
    raise exception 'trade cash and cost inputs cannot be negative'
      using errcode = '22003';
  end if;

  v_owner_context := jsonb_build_object(
    'owner_user_id', p_owner_user_id,
    'workspace_id', p_workspace_id,
    'organization_id', p_organization_id
  );

  for v_outgoing in select value from jsonb_array_elements(p_outgoing_items)
  loop
    v_trade_value := (v_outgoing ->> 'trade_value')::numeric;

    if v_trade_value is null or v_trade_value < 0 then
      raise exception 'outgoing trade values cannot be negative or null'
        using errcode = '22003';
    end if;

    select *
    into v_outgoing_item
    from inventory_items
    where id = (v_outgoing ->> 'inventory_item_id')::uuid
    for update;

    if not found then
      raise exception 'outgoing inventory item not found'
        using errcode = 'P0002';
    end if;

    if not coalesce((
      is_platform_admin()
      or v_outgoing_item.owner_user_id = v_actor_user_id
      or (v_outgoing_item.workspace_id is not null and is_workspace_member(v_outgoing_item.workspace_id))
      or (v_outgoing_item.organization_id is not null and is_organization_member(v_outgoing_item.organization_id))
    ), false) then
      raise exception 'outgoing inventory item access is required'
        using errcode = '42501';
    end if;

    if v_outgoing_item.owner_user_id is distinct from p_owner_user_id
      or v_outgoing_item.workspace_id is distinct from p_workspace_id
      or v_outgoing_item.organization_id is distinct from p_organization_id then
      raise exception 'outgoing inventory item must match trade owner context'
        using errcode = '23514';
    end if;

    if v_outgoing_item.true_basis is null then
      raise exception 'outgoing inventory item is missing true_basis'
        using errcode = '23514';
    end if;

    v_outgoing_basis_total := v_outgoing_basis_total + v_outgoing_item.true_basis;
    v_outgoing_count := v_outgoing_count + 1;
    v_outgoing_ids := array_append(v_outgoing_ids, v_outgoing_item.id);
  end loop;

  for v_incoming in select value from jsonb_array_elements(p_incoming_items)
  loop
    v_trade_value := (v_incoming ->> 'trade_value')::numeric;

    if v_trade_value is null or v_trade_value < 0 then
      raise exception 'incoming trade values cannot be negative or null'
        using errcode = '22003';
    end if;

    v_total_incoming_trade_value := v_total_incoming_trade_value + v_trade_value;
  end loop;

  if v_total_incoming_trade_value <= 0 then
    raise exception 'total incoming trade value must be greater than zero'
      using errcode = '22003';
  end if;

  v_basis_pool := v_outgoing_basis_total
    + coalesce(p_cash_paid, 0)
    - coalesce(p_cash_received, 0)
    + coalesce(p_trade_related_costs, 0);

  if v_basis_pool <= 0 then
    v_excess_realized_profit := abs(v_basis_pool);
  end if;

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
    'trade',
    v_transaction_date,
    coalesce(p_source, 'manual'),
    p_counterparty,
    p_notes,
    v_actor_user_id
  )
  returning id into v_transaction_id;

  for v_outgoing in select value from jsonb_array_elements(p_outgoing_items)
  loop
    v_trade_value := (v_outgoing ->> 'trade_value')::numeric;

    select *
    into v_outgoing_item
    from inventory_items
    where id = (v_outgoing ->> 'inventory_item_id')::uuid
    for update;

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
      v_outgoing_item.id,
      'out',
      null,
      null,
      v_trade_value,
      v_outgoing_item.true_basis,
      null,
      'Trade outgoing item. Basis frozen at trade time.'
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
      v_outgoing_item.id,
      v_transaction_id,
      'trade_out',
      v_transaction_date,
      v_outgoing_item.status,
      'traded',
      v_owner_context,
      v_owner_context,
      p_notes,
      v_actor_user_id
    );

    update inventory_items
    set
      status = 'traded',
      availability = 'archived',
      updated_by = v_actor_user_id,
      updated_at = now()
    where id = v_outgoing_item.id;
  end loop;

  if coalesce(p_cash_paid, 0) > 0 then
    insert into transaction_lines (transaction_id, line_type, direction, amount, notes)
    values (v_transaction_id, 'cash', 'out', p_cash_paid, 'Cash paid in trade.');
  end if;

  if coalesce(p_cash_received, 0) > 0 then
    insert into transaction_lines (transaction_id, line_type, direction, amount, notes)
    values (v_transaction_id, 'cash', 'in', p_cash_received, 'Cash received in trade.');
  end if;

  if coalesce(p_trade_related_costs, 0) > 0 then
    insert into transaction_lines (transaction_id, line_type, direction, amount, notes)
    values (v_transaction_id, 'fee', 'out', p_trade_related_costs, 'Trade-related costs.');
  end if;

  if v_excess_realized_profit > 0 then
    insert into transaction_lines (transaction_id, line_type, direction, amount, notes)
    values (v_transaction_id, 'value', 'neutral', v_excess_realized_profit, 'Excess realized profit from non-positive trade basis pool.');
  end if;

  for v_incoming in select value from jsonb_array_elements(p_incoming_items)
  loop
    v_trade_value := (v_incoming ->> 'trade_value')::numeric;
    v_allocated_basis := case
      when v_basis_pool <= 0 then 0
      else v_basis_pool * (v_trade_value / v_total_incoming_trade_value)
    end;

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
      (v_incoming ->> 'category_id')::uuid,
      (v_incoming ->> 'asset_variant_id')::uuid,
      coalesce((v_incoming ->> 'condition_type')::condition_type, 'unknown'),
      coalesce((v_incoming ->> 'status')::inventory_status, 'active'),
      coalesce((v_incoming ->> 'availability')::inventory_availability, 'available'),
      coalesce((v_incoming ->> 'intent')::inventory_intent, 'hold'),
      nullif(v_incoming ->> 'location_id', '')::uuid,
      v_allocated_basis,
      null,
      v_transaction_date,
      v_incoming ->> 'notes',
      v_actor_user_id,
      v_actor_user_id
    )
    returning id into v_incoming_item_id;

    v_incoming_ids := array_append(v_incoming_ids, v_incoming_item_id);

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
      v_incoming_item_id,
      'in',
      null,
      null,
      v_trade_value,
      null,
      v_allocated_basis,
      'Trade incoming item.'
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
      v_incoming_item_id,
      v_transaction_id,
      'trade_in',
      v_transaction_date,
      null,
      coalesce((v_incoming ->> 'status')::inventory_status, 'active'),
      null,
      v_owner_context,
      v_incoming ->> 'notes',
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
      v_incoming_item_id,
      v_transaction_id,
      'trade_allocation',
      v_allocated_basis,
      0,
      v_allocated_basis,
      'trade_basis_pool_proportional_by_trade_value',
      jsonb_build_object(
        'outgoing_basis_total', v_outgoing_basis_total,
        'cash_paid', coalesce(p_cash_paid, 0),
        'cash_received', coalesce(p_cash_received, 0),
        'trade_related_costs', coalesce(p_trade_related_costs, 0),
        'basis_pool', v_basis_pool,
        'incoming_trade_value', v_trade_value,
        'total_incoming_trade_value', v_total_incoming_trade_value,
        'allocation_method', 'proportional_by_incoming_trade_value',
        'allocated_basis', v_allocated_basis,
        'excess_realized_profit', v_excess_realized_profit
      ),
      null,
      v_actor_user_id
    );

    for v_source in
      select ii.id, ii.true_basis
      from inventory_items ii
      where ii.id = any(v_outgoing_ids)
      order by ii.id
    loop
      v_source_basis_share := case
        when v_outgoing_basis_total > 0 and v_basis_pool > 0
          then v_allocated_basis * (v_source.true_basis / v_outgoing_basis_total)
        else 0
      end;

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
        v_source.id,
        v_incoming_item_id,
        v_source_basis_share,
        case when v_outgoing_count > 0 then coalesce(p_cash_paid, 0) / v_outgoing_count else 0 end,
        case when v_outgoing_count > 0 then coalesce(p_cash_received, 0) / v_outgoing_count else 0 end,
        case when v_outgoing_count > 0 then coalesce(p_trade_related_costs, 0) / v_outgoing_count else 0 end,
        v_allocated_basis,
        'proportional_by_incoming_trade_value',
        jsonb_build_object(
          'outgoing_basis_total', v_outgoing_basis_total,
          'basis_pool', v_basis_pool,
          'incoming_trade_value', v_trade_value,
          'total_incoming_trade_value', v_total_incoming_trade_value,
          'source_basis', v_source.true_basis,
          'excess_realized_profit', v_excess_realized_profit
        )
      );
    end loop;
  end loop;

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
    'trade_transaction_created',
    'transactions',
    v_transaction_id,
    p_owner_user_id,
    p_workspace_id,
    p_organization_id,
    null,
    jsonb_build_object(
      'outgoing_inventory_item_ids', to_jsonb(v_outgoing_ids),
      'incoming_inventory_item_ids', to_jsonb(v_incoming_ids),
      'outgoing_basis_total', v_outgoing_basis_total,
      'basis_pool', v_basis_pool,
      'excess_realized_profit', v_excess_realized_profit
    )
  );

  transaction_id := v_transaction_id;
  incoming_inventory_item_ids := v_incoming_ids;
  outgoing_inventory_item_ids := v_outgoing_ids;
  return next;
end;
$$;

revoke all on function create_trade_transaction(
  uuid,
  uuid,
  uuid,
  timestamptz,
  text,
  text,
  text,
  jsonb,
  jsonb,
  numeric,
  numeric,
  numeric
) from public, anon;

grant execute on function create_trade_transaction(
  uuid,
  uuid,
  uuid,
  timestamptz,
  text,
  text,
  text,
  jsonb,
  jsonb,
  numeric,
  numeric,
  numeric
) to authenticated;
