-- Verifies lot purchase transactions allocate a single acquisition basis pool
-- across multiple newly acquired inventory items.

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

create or replace function pg_temp.satera_expect_rejected(statement text, message text)
returns void
language plpgsql
as $$
begin
  begin
    execute statement;
  exception when others then
    raise notice 'ok: %', message;
    return;
  end;

  raise exception 'verification failed: %', message;
end;
$$;

create temp table lot_results (
  label text primary key,
  transaction_id uuid not null,
  inventory_item_ids uuid[] not null,
  total_lot_basis numeric not null
) on commit drop;

insert into locations (workspace_id, name, location_type)
values ('30000000-0000-0000-0000-000000000001', 'Lot Purchase Verification Vault', 'storage');

insert into locations (owner_user_id, name, location_type)
values (auth.uid(), 'User-Owned Location Not In Workspace', 'storage');

insert into lot_results
select
  'manual',
  transaction_id,
  inventory_item_ids,
  total_lot_basis
from create_lot_purchase_transaction(
  p_workspace_id => '30000000-0000-0000-0000-000000000001',
  p_product_id => '10000000-0000-0000-0000-000000000001',
  p_purchase_price => 100,
  p_buyer_fees => 5,
  p_tax => 8,
  p_shipping => 7,
  p_other_acquisition_costs => 10,
  p_purchased_at => '2026-05-01T00:00:00Z',
  p_seller_reference => 'Demo seller',
  p_marketplace => 'manual',
  p_order_reference => 'ORDER-1',
  p_allocation_method => 'manual',
  p_items => jsonb_build_array(
    jsonb_build_object(
      'asset_variant_id', '60000000-0000-0000-0000-000000000001',
      'condition_type', 'raw',
      'allocated_basis', 60,
      'acquisition_notes', 'Manual lot item 1'
    ),
    jsonb_build_object(
      'asset_variant_id', '60000000-0000-0000-0000-000000000001',
      'condition_type', 'sealed',
      'allocated_basis', 70,
      'location_id', (select id from locations where name = 'Lot Purchase Verification Vault'),
      'acquisition_notes', 'Manual lot item 2'
    )
  ),
  p_notes => 'Manual lot purchase verification.'
);

select pg_temp.satera_assert(
  (
    select r.total_lot_basis = 130
      and array_length(r.inventory_item_ids, 1) = 2
      and t.transaction_type = 'purchase_lot'
      and t.workspace_id = '30000000-0000-0000-0000-000000000001'
      and (t.metadata ->> 'transaction_kind') = 'lot_purchase'
      and (t.metadata ->> 'purchase_price')::numeric = 100
      and (t.metadata ->> 'buyer_fees')::numeric = 5
      and (t.metadata ->> 'tax')::numeric = 8
      and (t.metadata ->> 'shipping')::numeric = 7
      and (t.metadata ->> 'other_acquisition_costs')::numeric = 10
      and (t.metadata ->> 'total_lot_basis')::numeric = 130
      and (t.metadata ->> 'allocation_method') = 'manual'
      and (t.metadata ->> 'item_count')::integer = 2
      and first_item.true_basis = 60
      and second_item.true_basis = 70
      and first_item.current_value_snapshot_id is null
      and second_item.current_value_snapshot_id is null
      and first_item.status = 'active'
      and second_item.availability = 'available'
      and (select sum(true_basis) from inventory_items where id = any(r.inventory_item_ids)) = 130
      and (select count(*) from transaction_lines where transaction_id = r.transaction_id and line_type = 'inventory') = 2
      and (select count(*) from ownership_events where transaction_id = r.transaction_id and event_type = 'lot_purchase') = 2
      and (select count(*) from basis_events where transaction_id = r.transaction_id and basis_event_type = 'lot_allocation') = 2
      and (select count(*) from basis_lineage_edges where transaction_id = r.transaction_id and source_inventory_item_id is null) = 2
      and first_line.basis_allocated = 60
      and (first_line.metadata ->> 'allocation_method') = 'manual'
      and first_basis.new_basis = 60
      and (first_basis.calculation_inputs ->> 'total_lot_basis')::numeric = 130
      and first_lineage.allocated_basis_amount = 60
      and first_lineage.allocation_method = 'manual'
      and ae.id is not null
    from lot_results r
    join transactions t on t.id = r.transaction_id
    join inventory_items first_item on first_item.id = r.inventory_item_ids[1]
    join inventory_items second_item on second_item.id = r.inventory_item_ids[2]
    join transaction_lines first_line on first_line.transaction_id = r.transaction_id
      and first_line.inventory_item_id = first_item.id
    join basis_events first_basis on first_basis.transaction_id = r.transaction_id
      and first_basis.inventory_item_id = first_item.id
    join basis_lineage_edges first_lineage on first_lineage.transaction_id = r.transaction_id
      and first_lineage.target_inventory_item_id = first_item.id
    left join audit_events ae on ae.entity_table = 'transactions'
      and ae.entity_id = r.transaction_id
      and ae.event_type = 'lot_purchase_transaction_created'
    where r.label = 'manual'
  ),
  'manual lot purchase creates transaction, inventory, lines, ownership events, basis events, lineage, and audit event.'
);

insert into lot_results
select
  'equal_rounding',
  transaction_id,
  inventory_item_ids,
  total_lot_basis
from create_lot_purchase_transaction(
  p_workspace_id => '30000000-0000-0000-0000-000000000001',
  p_purchase_price => 100,
  p_purchased_at => '2026-05-02T00:00:00Z',
  p_allocation_method => 'equal',
  p_items => jsonb_build_array(
    jsonb_build_object('asset_variant_id', '60000000-0000-0000-0000-000000000001', 'condition_type', 'raw'),
    jsonb_build_object('asset_variant_id', '60000000-0000-0000-0000-000000000002', 'condition_type', 'raw'),
    jsonb_build_object('asset_variant_id', '60000000-0000-0000-0000-000000000003', 'condition_type', 'raw')
  )
);

select pg_temp.satera_assert(
  (
    select first_item.true_basis = 33.33
      and second_item.true_basis = 33.33
      and third_item.true_basis = 33.34
      and (select sum(true_basis) from inventory_items where id = any(r.inventory_item_ids)) = 100
      and (t.metadata ->> 'allocation_method') = 'equal'
      and (t.metadata ->> 'rounding_adjustment')::numeric = 0.01
      and (third_basis.calculation_inputs ->> 'rounding_adjustment_applied')::numeric = 0.01
    from lot_results r
    join transactions t on t.id = r.transaction_id
    join inventory_items first_item on first_item.id = r.inventory_item_ids[1]
    join inventory_items second_item on second_item.id = r.inventory_item_ids[2]
    join inventory_items third_item on third_item.id = r.inventory_item_ids[3]
    join basis_events third_basis on third_basis.transaction_id = r.transaction_id
      and third_basis.inventory_item_id = third_item.id
    where r.label = 'equal_rounding'
  ),
  'equal lot allocation divides basis and applies rounding remainder to final item.'
);

insert into lot_results
select
  'zero_dollar',
  transaction_id,
  inventory_item_ids,
  total_lot_basis
from create_lot_purchase_transaction(
  p_workspace_id => '30000000-0000-0000-0000-000000000001',
  p_purchase_price => 0,
  p_buyer_fees => 0,
  p_tax => 0,
  p_shipping => 0,
  p_other_acquisition_costs => 0,
  p_purchased_at => '2026-05-03T00:00:00Z',
  p_allocation_method => 'manual',
  p_items => jsonb_build_array(
    jsonb_build_object('asset_variant_id', '60000000-0000-0000-0000-000000000001', 'allocated_basis', 0),
    jsonb_build_object('asset_variant_id', '60000000-0000-0000-0000-000000000002', 'allocated_basis', 0)
  )
);

select pg_temp.satera_assert(
  (
    select r.total_lot_basis = 0
      and (select sum(true_basis) from inventory_items where id = any(r.inventory_item_ids)) = 0
      and (select count(*) from basis_events where transaction_id = r.transaction_id and new_basis = 0) = 2
    from lot_results r
    where r.label = 'zero_dollar'
  ),
  'zero-dollar lot purchase works when total lot basis and allocated bases are zero.'
);

select pg_temp.satera_expect_rejected(
  $sql$
    select * from create_lot_purchase_transaction(
      p_workspace_id => '30000000-0000-0000-0000-000000000001',
      p_purchase_price => 10,
      p_allocation_method => 'manual',
      p_items => jsonb_build_array(jsonb_build_object(
        'asset_variant_id', '60000000-0000-0000-0000-000000000001',
        'allocated_basis', 9
      ))
    )
  $sql$,
  'manual lot allocation mismatch is rejected.'
);

select pg_temp.satera_expect_rejected(
  $sql$
    select * from create_lot_purchase_transaction(
      p_workspace_id => '30000000-0000-0000-0000-000000000001',
      p_purchase_price => -1,
      p_items => jsonb_build_array(jsonb_build_object(
        'asset_variant_id', '60000000-0000-0000-0000-000000000001',
        'allocated_basis', 0
      ))
    )
  $sql$,
  'negative lot purchase price is rejected.'
);

select pg_temp.satera_expect_rejected(
  $sql$
    select * from create_lot_purchase_transaction(
      p_workspace_id => '30000000-0000-0000-0000-000000000001',
      p_purchase_price => 10,
      p_buyer_fees => -1,
      p_items => jsonb_build_array(jsonb_build_object(
        'asset_variant_id', '60000000-0000-0000-0000-000000000001',
        'allocated_basis', 10
      ))
    )
  $sql$,
  'negative lot purchase cost inputs are rejected.'
);

select pg_temp.satera_expect_rejected(
  $sql$
    select * from create_lot_purchase_transaction(
      p_workspace_id => '30000000-0000-0000-0000-000000000001',
      p_purchase_price => 10,
      p_items => jsonb_build_array(jsonb_build_object(
        'asset_variant_id', '60000000-0000-0000-0000-000000000001',
        'allocated_basis', -1
      ))
    )
  $sql$,
  'negative allocated basis is rejected.'
);

select pg_temp.satera_expect_rejected(
  $sql$
    select * from create_lot_purchase_transaction(
      p_workspace_id => '30000000-0000-0000-0000-000000000001',
      p_purchase_price => 10,
      p_allocation_method => 'estimated_value',
      p_items => jsonb_build_array(jsonb_build_object(
        'asset_variant_id', '60000000-0000-0000-0000-000000000001',
        'allocated_basis', 10
      ))
    )
  $sql$,
  'unsupported lot allocation method is rejected.'
);

select pg_temp.satera_expect_rejected(
  $sql$
    select * from create_lot_purchase_transaction(
      p_workspace_id => '30000000-0000-0000-0000-000000000001',
      p_purchase_price => 0,
      p_items => '[]'::jsonb
    )
  $sql$,
  'empty item array is rejected.'
);

select pg_temp.satera_expect_rejected(
  $sql$
    select * from create_lot_purchase_transaction(
      p_workspace_id => '30000000-0000-0000-0000-000000000001',
      p_purchase_price => 10,
      p_items => jsonb_build_array(jsonb_build_object(
        'asset_variant_id', 'ffffffff-ffff-ffff-ffff-ffffffffffff',
        'allocated_basis', 10
      ))
    )
  $sql$,
  'invalid asset_variant_id is rejected.'
);

select pg_temp.satera_expect_rejected(
  $sql$
    select * from create_lot_purchase_transaction(
      p_workspace_id => '30000000-0000-0000-0000-000000000001',
      p_purchase_price => 10,
      p_items => jsonb_build_array(jsonb_build_object(
        'asset_variant_id', '60000000-0000-0000-0000-000000000001',
        'collection_id', 'ffffffff-ffff-ffff-ffff-ffffffffffff',
        'allocated_basis', 10
      ))
    )
  $sql$,
  'invalid collection_id is rejected.'
);

select pg_temp.satera_expect_rejected(
  format(
    $sql$
      select * from create_lot_purchase_transaction(
        p_workspace_id => '30000000-0000-0000-0000-000000000001',
        p_purchase_price => 10,
        p_items => jsonb_build_array(jsonb_build_object(
          'asset_variant_id', '60000000-0000-0000-0000-000000000001',
          'location_id', %L,
          'allocated_basis', 10
        ))
      )
    $sql$,
    (select id from locations where name = 'User-Owned Location Not In Workspace')
  ),
  'invalid location_id is rejected.'
);

select pg_temp.satera_assert(
  not has_table_privilege('transactions', 'INSERT')
    and not has_table_privilege('transaction_lines', 'INSERT')
    and not has_table_privilege('basis_events', 'INSERT'),
  'direct authenticated writes remain blocked for financial truth tables.'
);

reset role;
set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000b2';

select pg_temp.satera_expect_rejected(
  $sql$
    select * from create_lot_purchase_transaction(
      p_workspace_id => '30000000-0000-0000-0000-000000000001',
      p_purchase_price => 10,
      p_items => jsonb_build_array(jsonb_build_object(
        'asset_variant_id', '60000000-0000-0000-0000-000000000001',
        'allocated_basis', 10
      ))
    )
  $sql$,
  'unauthorized workspace lot purchase is rejected.'
);

rollback;
