alter type basis_event_type add value if not exists 'sale_realization';

alter table transactions
add column if not exists metadata jsonb not null default '{}'::jsonb;

create or replace function create_sale_transaction(
  p_inventory_item_id uuid,
  p_sale_price numeric,
  p_platform_fees numeric default 0,
  p_payment_processing_fees numeric default 0,
  p_shipping_cost numeric default 0,
  p_supplies_cost numeric default 0,
  p_consignment_fees numeric default 0,
  p_other_selling_costs numeric default 0,
  p_owner_user_id uuid default null,
  p_workspace_id uuid default null,
  p_organization_id uuid default null,
  p_transaction_date timestamptz default null,
  p_source text default null,
  p_counterparty text default null,
  p_notes text default null
)
returns table (
  transaction_id uuid,
  inventory_item_id uuid,
  gross_sale_price numeric,
  selling_costs numeric,
  net_proceeds numeric,
  basis_at_sale numeric,
  realized_profit_loss numeric
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor_user_id uuid := auth.uid();
  v_inventory_item inventory_items;
  v_transaction_id uuid;
  v_transaction_date timestamptz := coalesce(p_transaction_date, now());
  v_owner_context jsonb;
  v_platform_fees numeric := coalesce(p_platform_fees, 0);
  v_payment_processing_fees numeric := coalesce(p_payment_processing_fees, 0);
  v_shipping_cost numeric := coalesce(p_shipping_cost, 0);
  v_supplies_cost numeric := coalesce(p_supplies_cost, 0);
  v_consignment_fees numeric := coalesce(p_consignment_fees, 0);
  v_other_selling_costs numeric := coalesce(p_other_selling_costs, 0);
  v_total_selling_costs numeric;
  v_net_proceeds numeric;
  v_realized_profit_loss numeric;
  v_sale_metadata jsonb;
begin
  if v_actor_user_id is null then
    raise exception 'authenticated user is required'
      using errcode = '42501';
  end if;

  if p_owner_user_id is null and p_workspace_id is null and p_organization_id is null then
    raise exception 'sale requires a user, workspace, or organization owner context'
      using errcode = '23514';
  end if;

  if p_sale_price is null then
    raise exception 'sale price is required'
      using errcode = '23502';
  end if;

  if p_sale_price < 0
    or v_platform_fees < 0
    or v_payment_processing_fees < 0
    or v_shipping_cost < 0
    or v_supplies_cost < 0
    or v_consignment_fees < 0
    or v_other_selling_costs < 0 then
    raise exception 'sale price and selling cost inputs cannot be negative'
      using errcode = '22003';
  end if;

  if p_owner_user_id is not null and p_owner_user_id <> v_actor_user_id and not is_platform_admin() then
    raise exception 'cannot create sale for another user'
      using errcode = '42501';
  end if;

  if p_workspace_id is not null and not is_workspace_member(p_workspace_id) and not is_platform_admin() then
    raise exception 'workspace membership is required to create workspace sale'
      using errcode = '42501';
  end if;

  if p_organization_id is not null and not is_organization_member(p_organization_id) and not is_platform_admin() then
    raise exception 'organization membership is required to create organization sale'
      using errcode = '42501';
  end if;

  select *
  into v_inventory_item
  from inventory_items
  where id = p_inventory_item_id
  for update;

  if not found then
    raise exception 'inventory item not found'
      using errcode = 'P0002';
  end if;

  if not coalesce((
    is_platform_admin()
    or v_inventory_item.owner_user_id = v_actor_user_id
    or (v_inventory_item.workspace_id is not null and is_workspace_member(v_inventory_item.workspace_id))
    or (v_inventory_item.organization_id is not null and is_organization_member(v_inventory_item.organization_id))
  ), false) then
    raise exception 'inventory item access is required'
      using errcode = '42501';
  end if;

  if v_inventory_item.owner_user_id is distinct from p_owner_user_id
    or v_inventory_item.workspace_id is distinct from p_workspace_id
    or v_inventory_item.organization_id is distinct from p_organization_id then
    raise exception 'inventory item must match sale owner context'
      using errcode = '23514';
  end if;

  if v_inventory_item.status <> 'active' then
    raise exception 'inventory item is not in active ownership'
      using errcode = '23514';
  end if;

  if v_inventory_item.availability = 'archived' then
    raise exception 'inventory item is archived'
      using errcode = '23514';
  end if;

  if v_inventory_item.true_basis is null then
    raise exception 'inventory item is missing true_basis'
      using errcode = '23514';
  end if;

  v_owner_context := jsonb_build_object(
    'owner_user_id', p_owner_user_id,
    'workspace_id', p_workspace_id,
    'organization_id', p_organization_id
  );
  v_total_selling_costs := v_platform_fees
    + v_payment_processing_fees
    + v_shipping_cost
    + v_supplies_cost
    + v_consignment_fees
    + v_other_selling_costs;
  v_net_proceeds := p_sale_price - v_total_selling_costs;
  v_realized_profit_loss := v_net_proceeds - v_inventory_item.true_basis;
  v_sale_metadata := jsonb_build_object(
    'sale_price', p_sale_price,
    'platform_fees', v_platform_fees,
    'payment_processing_fees', v_payment_processing_fees,
    'shipping_cost', v_shipping_cost,
    'supplies_cost', v_supplies_cost,
    'consignment_fees', v_consignment_fees,
    'other_selling_costs', v_other_selling_costs,
    'total_selling_costs', v_total_selling_costs,
    'net_proceeds', v_net_proceeds,
    'basis_at_sale', v_inventory_item.true_basis,
    'realized_profit_loss', v_realized_profit_loss
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
    p_owner_user_id,
    p_workspace_id,
    p_organization_id,
    'sale',
    v_transaction_date,
    coalesce(p_source, 'manual'),
    p_counterparty,
    p_notes,
    v_sale_metadata,
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
    v_inventory_item.id,
    'out',
    p_sale_price,
    null,
    null,
    v_inventory_item.true_basis,
    null,
    'Sold inventory item. Basis frozen at sale time.'
  );

  if v_platform_fees > 0 then
    insert into transaction_lines (transaction_id, line_type, direction, amount, notes)
    values (v_transaction_id, 'fee', 'out', v_platform_fees, 'Platform fees.');
  end if;

  if v_payment_processing_fees > 0 then
    insert into transaction_lines (transaction_id, line_type, direction, amount, notes)
    values (v_transaction_id, 'fee', 'out', v_payment_processing_fees, 'Payment processing fees.');
  end if;

  if v_shipping_cost > 0 then
    insert into transaction_lines (transaction_id, line_type, direction, amount, notes)
    values (v_transaction_id, 'shipping', 'out', v_shipping_cost, 'Seller-paid shipping.');
  end if;

  if v_supplies_cost > 0 then
    insert into transaction_lines (transaction_id, line_type, direction, amount, notes)
    values (v_transaction_id, 'fee', 'out', v_supplies_cost, 'Supplies cost.');
  end if;

  if v_consignment_fees > 0 then
    insert into transaction_lines (transaction_id, line_type, direction, amount, notes)
    values (v_transaction_id, 'fee', 'out', v_consignment_fees, 'Consignment fees.');
  end if;

  if v_other_selling_costs > 0 then
    insert into transaction_lines (transaction_id, line_type, direction, amount, notes)
    values (v_transaction_id, 'fee', 'out', v_other_selling_costs, 'Other selling costs.');
  end if;

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
    'value',
    v_inventory_item.id,
    'neutral',
    v_realized_profit_loss,
    null,
    null,
    v_inventory_item.true_basis,
    null,
    'Realized profit or loss from sale.'
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
    v_inventory_item.id,
    v_transaction_id,
    'sale',
    v_transaction_date,
    v_inventory_item.status,
    'sold',
    v_owner_context,
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
    v_inventory_item.id,
    v_transaction_id,
    'sale_realization',
    v_inventory_item.true_basis,
    v_inventory_item.true_basis,
    v_inventory_item.true_basis,
    'net_proceeds_minus_true_basis',
    v_sale_metadata,
    'Sale realization; true_basis is frozen, not rewritten.',
    v_actor_user_id
  );

  update inventory_items
  set
    status = 'sold',
    availability = 'archived',
    updated_by = v_actor_user_id,
    updated_at = now()
  where id = v_inventory_item.id;

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
    'sale_transaction_created',
    'transactions',
    v_transaction_id,
    p_owner_user_id,
    p_workspace_id,
    p_organization_id,
    null,
    v_sale_metadata || jsonb_build_object('inventory_item_id', v_inventory_item.id)
  );

  transaction_id := v_transaction_id;
  inventory_item_id := v_inventory_item.id;
  gross_sale_price := p_sale_price;
  selling_costs := v_total_selling_costs;
  net_proceeds := v_net_proceeds;
  basis_at_sale := v_inventory_item.true_basis;
  realized_profit_loss := v_realized_profit_loss;
  return next;
end;
$$;

revoke all on function create_sale_transaction(
  uuid,
  numeric,
  numeric,
  numeric,
  numeric,
  numeric,
  numeric,
  numeric,
  uuid,
  uuid,
  uuid,
  timestamptz,
  text,
  text,
  text
) from public, anon;

grant execute on function create_sale_transaction(
  uuid,
  numeric,
  numeric,
  numeric,
  numeric,
  numeric,
  numeric,
  numeric,
  uuid,
  uuid,
  uuid,
  timestamptz,
  text,
  text,
  text
) to authenticated;
