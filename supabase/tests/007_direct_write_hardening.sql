-- Verifies direct write grants are hardened and critical write workflows still
-- work through RPCs.

begin;

set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000a1';

create or replace function pg_temp.satera_assert(ok boolean, message text)
returns void
language plpgsql
as $$
begin
  if not ok then
    raise exception 'verification failed: %', message;
  end if;

  raise notice 'ok: %', message;
end;
$$;

create or replace function pg_temp.satera_expect_insufficient_privilege(statement text, message text)
returns void
language plpgsql
as $$
begin
  begin
    execute statement;
  exception
    when insufficient_privilege then
      raise notice 'ok: %', message;
      return;
  end;

  raise exception 'verification failed: %', message;
end;
$$;

create temp table hardened_rpc_results (
  label text primary key,
  inventory_item_id uuid not null,
  transaction_id uuid not null
) on commit drop;

select pg_temp.satera_assert(
  not has_table_privilege('inventory_items', 'INSERT')
    and not has_table_privilege('inventory_items', 'UPDATE')
    and not has_table_privilege('inventory_items', 'DELETE')
    and has_table_privilege('inventory_items', 'SELECT'),
  'authenticated direct inventory_items writes are revoked while select remains available.'
);

select pg_temp.satera_assert(
  not has_table_privilege('transactions', 'INSERT')
    and not has_table_privilege('transaction_lines', 'INSERT')
    and not has_table_privilege('ownership_events', 'INSERT')
    and not has_table_privilege('basis_events', 'INSERT')
    and not has_table_privilege('basis_lineage_edges', 'INSERT')
    and not has_table_privilege('comp_snapshots', 'INSERT')
    and not has_table_privilege('audit_events', 'INSERT'),
  'authenticated direct financial/history and comp snapshot inserts are revoked.'
);

select pg_temp.satera_expect_insufficient_privilege(
  $sql$
    insert into inventory_items (
      owner_user_id,
      category_id,
      asset_variant_id,
      condition_type,
      status,
      availability,
      intent,
      created_by,
      updated_by
    ) values (
      auth.uid(),
      '20000000-0000-0000-0000-000000000001',
      '60000000-0000-0000-0000-000000000001',
      'raw',
      'active',
      'available',
      'hold',
      auth.uid(),
      auth.uid()
    )
  $sql$,
  'authenticated user cannot directly insert inventory_items.'
);

select pg_temp.satera_expect_insufficient_privilege(
  $sql$
    update inventory_items
    set true_basis = 999
    where id = '70000000-0000-0000-0000-000000000001'
  $sql$,
  'authenticated user cannot directly update inventory_items.true_basis.'
);

select pg_temp.satera_expect_insufficient_privilege(
  $sql$
    insert into transactions (
      owner_user_id,
      transaction_type,
      transaction_date,
      source,
      created_by
    ) values (
      auth.uid(),
      'starting_inventory',
      now(),
      'unsafe_direct_insert',
      auth.uid()
    )
  $sql$,
  'authenticated user cannot directly insert transactions.'
);

select pg_temp.satera_expect_insufficient_privilege(
  $sql$
    insert into transaction_lines (
      transaction_id,
      line_type,
      inventory_item_id,
      direction
    ) values (
      gen_random_uuid(),
      'inventory',
      '70000000-0000-0000-0000-000000000001',
      'in'
    )
  $sql$,
  'authenticated user cannot directly insert transaction_lines.'
);

select pg_temp.satera_expect_insufficient_privilege(
  $sql$
    insert into ownership_events (
      owner_user_id,
      inventory_item_id,
      transaction_id,
      event_type,
      event_date,
      new_status,
      created_by
    ) values (
      auth.uid(),
      '70000000-0000-0000-0000-000000000001',
      null,
      'adjustment',
      now(),
      'active',
      auth.uid()
    )
  $sql$,
  'authenticated user cannot directly insert ownership_events.'
);

select pg_temp.satera_expect_insufficient_privilege(
  $sql$
    insert into basis_events (
      inventory_item_id,
      transaction_id,
      basis_event_type,
      amount,
      previous_basis,
      new_basis,
      calculation_method,
      calculation_inputs,
      created_by
    ) values (
      '70000000-0000-0000-0000-000000000001',
      null,
      'adjustment',
      1,
      0,
      1,
      'unsafe_direct_insert',
      '{}'::jsonb,
      auth.uid()
    )
  $sql$,
  'authenticated user cannot directly insert basis_events.'
);

select pg_temp.satera_expect_insufficient_privilege(
  $sql$
    insert into basis_lineage_edges (
      transaction_id,
      source_inventory_item_id,
      target_inventory_item_id,
      allocated_basis_amount,
      allocation_method,
      allocation_inputs
    ) values (
      gen_random_uuid(),
      null,
      '70000000-0000-0000-0000-000000000001',
      1,
      'unsafe_direct_insert',
      '{}'::jsonb
    )
  $sql$,
  'authenticated user cannot directly insert basis_lineage_edges.'
);

select pg_temp.satera_expect_insufficient_privilege(
  $sql$
    insert into comp_snapshots (
      owner_user_id,
      category_id,
      asset_variant_id,
      source,
      market_value,
      currency_code,
      created_by
    ) values (
      auth.uid(),
      '20000000-0000-0000-0000-000000000001',
      '60000000-0000-0000-0000-000000000001',
      'unsafe_direct_insert',
      1,
      'USD',
      auth.uid()
    )
  $sql$,
  'authenticated user cannot directly insert comp_snapshots.'
);

select pg_temp.satera_expect_insufficient_privilege(
  $sql$
    insert into audit_events (
      actor_user_id,
      event_type,
      entity_table,
      entity_id,
      owner_user_id,
      metadata
    ) values (
      auth.uid(),
      'unsafe_direct_insert',
      'inventory_items',
      '70000000-0000-0000-0000-000000000001',
      auth.uid(),
      '{}'::jsonb
    )
  $sql$,
  'authenticated user cannot directly insert audit_events.'
);

insert into hardened_rpc_results
select
  'starting_inventory',
  inventory_item_id,
  transaction_id
from create_starting_inventory_transaction(
  p_owner_user_id => auth.uid(),
  p_category_id => '20000000-0000-0000-0000-000000000001',
  p_asset_variant_id => '60000000-0000-0000-0000-000000000001',
  p_condition_type => 'raw',
  p_initial_basis => null,
  p_notes => 'Hardened grant test starting inventory.',
  p_transaction_date => '2026-02-01T00:00:00Z',
  p_source => 'sql_verification'
);

select pg_temp.satera_assert(
  (
    select ii.true_basis is null
      and t.transaction_type = 'starting_inventory'
    from hardened_rpc_results r
    join inventory_items ii on ii.id = r.inventory_item_id
    join transactions t on t.id = r.transaction_id
    where r.label = 'starting_inventory'
  ),
  'create_starting_inventory_transaction RPC still works after direct write revocation.'
);

insert into hardened_rpc_results
select
  'purchase',
  inventory_item_id,
  transaction_id
from create_purchase_transaction(
  p_owner_user_id => auth.uid(),
  p_category_id => '20000000-0000-0000-0000-000000000001',
  p_asset_variant_id => '60000000-0000-0000-0000-000000000001',
  p_purchase_price => 20,
  p_buyer_fees => 2,
  p_tax => 1,
  p_shipping => 3,
  p_direct_acquisition_costs => 4,
  p_notes => 'Hardened grant test purchase.',
  p_transaction_date => '2026-02-02T00:00:00Z',
  p_source => 'sql_verification'
);

select pg_temp.satera_assert(
  (
    select ii.true_basis = 30
      and t.transaction_type = 'purchase_single'
      and be.basis_event_type = 'purchase_basis'
      and be.new_basis = 30
    from hardened_rpc_results r
    join inventory_items ii on ii.id = r.inventory_item_id
    join transactions t on t.id = r.transaction_id
    join basis_events be on be.transaction_id = r.transaction_id
      and be.inventory_item_id = r.inventory_item_id
    where r.label = 'purchase'
  ),
  'create_purchase_transaction RPC still works after direct write revocation.'
);

select update_inventory_item_safe_fields(
  p_target_inventory_item_id => '70000000-0000-0000-0000-000000000001',
  p_new_notes => 'Safe RPC update note.',
  p_new_intent => 'sell',
  p_new_location_id => null,
  p_new_availability => 'committed',
  p_update_notes => true,
  p_update_intent => true,
  p_update_location_id => false,
  p_update_availability => true
);

select pg_temp.satera_assert(
  (
    select notes = 'Safe RPC update note.'
      and intent = 'sell'
      and availability = 'committed'
      and true_basis is null
      and owner_user_id = auth.uid()
      and workspace_id is null
      and organization_id is null
      and category_id = '20000000-0000-0000-0000-000000000001'
      and asset_variant_id = '60000000-0000-0000-0000-000000000001'
    from inventory_items
    where id = '70000000-0000-0000-0000-000000000001'
  ),
  'update_inventory_item_safe_fields updates allowed fields and leaves basis, ownership, category, and variant unchanged.'
);

select pg_temp.satera_assert(
  (
    select count(*) = 1
    from audit_events
    where entity_table = 'inventory_items'
      and entity_id = '70000000-0000-0000-0000-000000000001'
      and event_type = 'inventory_safe_fields_updated'
  ),
  'update_inventory_item_safe_fields writes an audit event.'
);

insert into hardened_rpc_results
select
  'workspace_inventory',
  inventory_item_id,
  transaction_id
from create_starting_inventory_transaction(
  p_workspace_id => '30000000-0000-0000-0000-000000000001',
  p_category_id => '20000000-0000-0000-0000-000000000001',
  p_asset_variant_id => '60000000-0000-0000-0000-000000000001',
  p_initial_basis => null,
  p_notes => 'Workspace item for safe update authorization.',
  p_transaction_date => '2026-02-03T00:00:00Z',
  p_source => 'sql_verification'
);

reset role;
set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000b2';

select pg_temp.satera_expect_insufficient_privilege(
  $sql$
    select update_inventory_item_safe_fields(
      p_target_inventory_item_id => '70000000-0000-0000-0000-000000000001',
      p_new_notes => 'Unsafe update.',
      p_update_notes => true
    )
  $sql$,
  'unauthorized user cannot update another user inventory through the RPC.'
);

select pg_temp.satera_expect_insufficient_privilege(
  $sql$
    select update_inventory_item_safe_fields(
      p_target_inventory_item_id => '70000000-0000-0000-0000-000000000004',
      p_new_notes => 'Unsafe organization update.',
      p_update_notes => true
    )
  $sql$,
  'organization non-member cannot update organization inventory through the RPC.'
);

do $$
declare
  target_id uuid;
begin
  select inventory_item_id
  into target_id
  from hardened_rpc_results
  where label = 'workspace_inventory';

  begin
    perform update_inventory_item_safe_fields(
      p_target_inventory_item_id => target_id,
      p_new_notes => 'Unsafe workspace update.',
      p_update_notes => true
    );
  exception
    when insufficient_privilege then
      raise notice 'ok: workspace non-member cannot update workspace inventory through the RPC.';
      return;
  end;

  raise exception 'verification failed: workspace non-member cannot update workspace inventory through the RPC.';
end;
$$;

rollback;
