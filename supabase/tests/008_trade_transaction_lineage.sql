-- Verifies atomic trade transactions preserve ownership history, frozen
-- outgoing basis, incoming basis allocation, and basis lineage.

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

create temp table trade_results (
  label text primary key,
  outgoing_inventory_item_id uuid,
  incoming_inventory_item_id uuid,
  second_incoming_inventory_item_id uuid,
  transaction_id uuid
) on commit drop;

create temp table setup_items (
  label text primary key,
  inventory_item_id uuid not null
) on commit drop;

insert into setup_items
select 'cash_paid_source', inventory_item_id
from create_starting_inventory_transaction(
  p_owner_user_id => auth.uid(),
  p_category_id => '20000000-0000-0000-0000-000000000001',
  p_asset_variant_id => '60000000-0000-0000-0000-000000000001',
  p_initial_basis => 100,
  p_transaction_date => '2026-03-01T00:00:00Z',
  p_source => 'trade_verification'
);

insert into trade_results
select
  'cash_paid',
  (select inventory_item_id from setup_items where label = 'cash_paid_source'),
  incoming_inventory_item_ids[1],
  null,
  transaction_id
from create_trade_transaction(
  p_owner_user_id => auth.uid(),
  p_transaction_date => '2026-03-02T00:00:00Z',
  p_source => 'trade_verification',
  p_outgoing_items => jsonb_build_array(jsonb_build_object(
    'inventory_item_id', (select inventory_item_id from setup_items where label = 'cash_paid_source'),
    'trade_value', 125
  )),
  p_incoming_items => jsonb_build_array(jsonb_build_object(
    'category_id', '20000000-0000-0000-0000-000000000002',
    'asset_variant_id', '60000000-0000-0000-0000-000000000002',
    'condition_type', 'raw',
    'trade_value', 175,
    'notes', 'Incoming item with cash paid.'
  )),
  p_cash_paid => 50
);

select pg_temp.satera_assert(
  (
    select ii.true_basis = 150
      and tl_out.basis_at_time = 100
      and tl_out.trade_value_at_time = 125
      and tl_in.trade_value_at_time = 175
      and tl_in.basis_allocated = 150
      and source_item.status = 'traded'
      and source_item.availability = 'archived'
      and source_item.id is not null
      and oe_out.event_type = 'trade_out'
      and oe_in.event_type = 'trade_in'
      and be.basis_event_type = 'trade_allocation'
      and be.new_basis = 150
      and ble.source_inventory_item_id = r.outgoing_inventory_item_id
      and ble.target_inventory_item_id = r.incoming_inventory_item_id
      and ble.cash_paid_amount = 50
    from trade_results r
    join inventory_items ii on ii.id = r.incoming_inventory_item_id
    join inventory_items source_item on source_item.id = r.outgoing_inventory_item_id
    join transaction_lines tl_out on tl_out.transaction_id = r.transaction_id
      and tl_out.inventory_item_id = r.outgoing_inventory_item_id
      and tl_out.direction = 'out'
    join transaction_lines tl_in on tl_in.transaction_id = r.transaction_id
      and tl_in.inventory_item_id = r.incoming_inventory_item_id
      and tl_in.direction = 'in'
    join ownership_events oe_out on oe_out.transaction_id = r.transaction_id
      and oe_out.inventory_item_id = r.outgoing_inventory_item_id
    join ownership_events oe_in on oe_in.transaction_id = r.transaction_id
      and oe_in.inventory_item_id = r.incoming_inventory_item_id
    join basis_events be on be.transaction_id = r.transaction_id
      and be.inventory_item_id = r.incoming_inventory_item_id
    join basis_lineage_edges ble on ble.transaction_id = r.transaction_id
      and ble.target_inventory_item_id = r.incoming_inventory_item_id
    where r.label = 'cash_paid'
  ),
  'one outgoing item plus cash paid creates one incoming item with correct basis and lineage.'
);

insert into setup_items
select 'no_cash_source', inventory_item_id
from create_starting_inventory_transaction(
  p_owner_user_id => auth.uid(),
  p_category_id => '20000000-0000-0000-0000-000000000001',
  p_asset_variant_id => '60000000-0000-0000-0000-000000000001',
  p_initial_basis => 80,
  p_transaction_date => '2026-03-03T00:00:00Z',
  p_source => 'trade_verification'
);

insert into trade_results
select
  'no_cash',
  (select inventory_item_id from setup_items where label = 'no_cash_source'),
  incoming_inventory_item_ids[1],
  null,
  transaction_id
from create_trade_transaction(
  p_owner_user_id => auth.uid(),
  p_transaction_date => '2026-03-04T00:00:00Z',
  p_source => 'trade_verification',
  p_outgoing_items => jsonb_build_array(jsonb_build_object(
    'inventory_item_id', (select inventory_item_id from setup_items where label = 'no_cash_source'),
    'trade_value', 80
  )),
  p_incoming_items => jsonb_build_array(jsonb_build_object(
    'category_id', '20000000-0000-0000-0000-000000000003',
    'asset_variant_id', '60000000-0000-0000-0000-000000000003',
    'condition_type', 'authenticated',
    'trade_value', 80
  ))
);

select pg_temp.satera_assert(
  (
    select ii.true_basis = 80
    from trade_results r
    join inventory_items ii on ii.id = r.incoming_inventory_item_id
    where r.label = 'no_cash'
  ),
  'one outgoing item with no cash creates one incoming item with outgoing basis.'
);

insert into setup_items
select 'multi_source', inventory_item_id
from create_starting_inventory_transaction(
  p_owner_user_id => auth.uid(),
  p_category_id => '20000000-0000-0000-0000-000000000001',
  p_asset_variant_id => '60000000-0000-0000-0000-000000000001',
  p_initial_basis => 120,
  p_transaction_date => '2026-03-05T00:00:00Z',
  p_source => 'trade_verification'
);

insert into trade_results
select
  'multi_incoming',
  (select inventory_item_id from setup_items where label = 'multi_source'),
  incoming_inventory_item_ids[1],
  incoming_inventory_item_ids[2],
  transaction_id
from create_trade_transaction(
  p_owner_user_id => auth.uid(),
  p_transaction_date => '2026-03-06T00:00:00Z',
  p_source => 'trade_verification',
  p_outgoing_items => jsonb_build_array(jsonb_build_object(
    'inventory_item_id', (select inventory_item_id from setup_items where label = 'multi_source'),
    'trade_value', 400
  )),
  p_incoming_items => jsonb_build_array(
    jsonb_build_object(
      'category_id', '20000000-0000-0000-0000-000000000002',
      'asset_variant_id', '60000000-0000-0000-0000-000000000002',
      'trade_value', 100
    ),
    jsonb_build_object(
      'category_id', '20000000-0000-0000-0000-000000000004',
      'asset_variant_id', '60000000-0000-0000-0000-000000000004',
      'trade_value', 300
    )
  )
);

select pg_temp.satera_assert(
  (
    select first_item.true_basis = 30
      and second_item.true_basis = 90
      and (select count(*) = 2 from basis_lineage_edges where transaction_id = r.transaction_id)
    from trade_results r
    join inventory_items first_item on first_item.id = r.incoming_inventory_item_id
    join inventory_items second_item on second_item.id = r.second_incoming_inventory_item_id
    where r.label = 'multi_incoming'
  ),
  'multiple incoming items allocate basis proportionally by incoming trade value.'
);

insert into setup_items
select 'cash_received_source', inventory_item_id
from create_starting_inventory_transaction(
  p_owner_user_id => auth.uid(),
  p_category_id => '20000000-0000-0000-0000-000000000001',
  p_asset_variant_id => '60000000-0000-0000-0000-000000000001',
  p_initial_basis => 100,
  p_transaction_date => '2026-03-07T00:00:00Z',
  p_source => 'trade_verification'
);

insert into trade_results
select
  'cash_received',
  (select inventory_item_id from setup_items where label = 'cash_received_source'),
  incoming_inventory_item_ids[1],
  null,
  transaction_id
from create_trade_transaction(
  p_owner_user_id => auth.uid(),
  p_outgoing_items => jsonb_build_array(jsonb_build_object(
    'inventory_item_id', (select inventory_item_id from setup_items where label = 'cash_received_source'),
    'trade_value', 100
  )),
  p_incoming_items => jsonb_build_array(jsonb_build_object(
    'category_id', '20000000-0000-0000-0000-000000000002',
    'asset_variant_id', '60000000-0000-0000-0000-000000000002',
    'trade_value', 100
  )),
  p_cash_received => 25
);

select pg_temp.satera_assert(
  (
    select ii.true_basis = 75
    from trade_results r
    join inventory_items ii on ii.id = r.incoming_inventory_item_id
    where r.label = 'cash_received'
  ),
  'cash received decreases basis pool.'
);

insert into setup_items
select 'costs_source', inventory_item_id
from create_starting_inventory_transaction(
  p_owner_user_id => auth.uid(),
  p_category_id => '20000000-0000-0000-0000-000000000001',
  p_asset_variant_id => '60000000-0000-0000-0000-000000000001',
  p_initial_basis => 100,
  p_transaction_date => '2026-03-08T00:00:00Z',
  p_source => 'trade_verification'
);

insert into trade_results
select
  'costs',
  (select inventory_item_id from setup_items where label = 'costs_source'),
  incoming_inventory_item_ids[1],
  null,
  transaction_id
from create_trade_transaction(
  p_owner_user_id => auth.uid(),
  p_outgoing_items => jsonb_build_array(jsonb_build_object(
    'inventory_item_id', (select inventory_item_id from setup_items where label = 'costs_source'),
    'trade_value', 100
  )),
  p_incoming_items => jsonb_build_array(jsonb_build_object(
    'category_id', '20000000-0000-0000-0000-000000000002',
    'asset_variant_id', '60000000-0000-0000-0000-000000000002',
    'trade_value', 100
  )),
  p_trade_related_costs => 12
);

select pg_temp.satera_assert(
  (
    select ii.true_basis = 112
    from trade_results r
    join inventory_items ii on ii.id = r.incoming_inventory_item_id
    where r.label = 'costs'
  ),
  'trade-related costs increase basis pool.'
);

insert into setup_items
select 'excess_source', inventory_item_id
from create_starting_inventory_transaction(
  p_owner_user_id => auth.uid(),
  p_category_id => '20000000-0000-0000-0000-000000000001',
  p_asset_variant_id => '60000000-0000-0000-0000-000000000001',
  p_initial_basis => 10,
  p_transaction_date => '2026-03-09T00:00:00Z',
  p_source => 'trade_verification'
);

insert into trade_results
select
  'excess',
  (select inventory_item_id from setup_items where label = 'excess_source'),
  incoming_inventory_item_ids[1],
  null,
  transaction_id
from create_trade_transaction(
  p_owner_user_id => auth.uid(),
  p_outgoing_items => jsonb_build_array(jsonb_build_object(
    'inventory_item_id', (select inventory_item_id from setup_items where label = 'excess_source'),
    'trade_value', 100
  )),
  p_incoming_items => jsonb_build_array(jsonb_build_object(
    'category_id', '20000000-0000-0000-0000-000000000002',
    'asset_variant_id', '60000000-0000-0000-0000-000000000002',
    'trade_value', 100
  )),
  p_cash_received => 25
);

select pg_temp.satera_assert(
  (
    select ii.true_basis = 0
      and exists (
        select 1
        from transaction_lines
        where transaction_id = r.transaction_id
          and line_type = 'value'
          and amount = 15
          and notes = 'Excess realized profit from non-positive trade basis pool.'
      )
      and (be.calculation_inputs->>'excess_realized_profit')::numeric = 15
    from trade_results r
    join inventory_items ii on ii.id = r.incoming_inventory_item_id
    join basis_events be on be.transaction_id = r.transaction_id
      and be.inventory_item_id = r.incoming_inventory_item_id
    where r.label = 'excess'
  ),
  'basis_pool <= 0 creates incoming basis 0 and records excess realized profit clearly.'
);

select pg_temp.satera_expect_rejected(
  format(
    $sql$
      select create_trade_transaction(
        p_owner_user_id => auth.uid(),
        p_outgoing_items => jsonb_build_array(jsonb_build_object('inventory_item_id', %L, 'trade_value', 1)),
        p_incoming_items => jsonb_build_array(jsonb_build_object(
          'category_id', '20000000-0000-0000-0000-000000000001',
          'asset_variant_id', '60000000-0000-0000-0000-000000000001',
          'trade_value', 1
        ))
      )
    $sql$,
    '70000000-0000-0000-0000-000000000001'
  ),
  'trade rejects outgoing item with missing true_basis.'
);

insert into setup_items
select 'workspace_source', inventory_item_id
from create_starting_inventory_transaction(
  p_workspace_id => '30000000-0000-0000-0000-000000000001',
  p_category_id => '20000000-0000-0000-0000-000000000001',
  p_asset_variant_id => '60000000-0000-0000-0000-000000000001',
  p_initial_basis => 50,
  p_transaction_date => '2026-03-10T00:00:00Z',
  p_source => 'trade_verification'
);

reset role;
set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000b2';

select pg_temp.satera_expect_rejected(
  $sql$
    select create_trade_transaction(
      p_owner_user_id => '00000000-0000-0000-0000-0000000000a1',
      p_outgoing_items => jsonb_build_array(jsonb_build_object('inventory_item_id', '70000000-0000-0000-0000-000000000002', 'trade_value', 1)),
      p_incoming_items => jsonb_build_array(jsonb_build_object(
        'category_id', '20000000-0000-0000-0000-000000000001',
        'asset_variant_id', '60000000-0000-0000-0000-000000000001',
        'trade_value', 1
      ))
    )
  $sql$,
  'trade rejects unauthorized user.'
);

select pg_temp.satera_assert(
  (select count(*) = 1 from product_profiles where user_id = auth.uid()),
  'User B has a product profile for product-profile trade authorization check.'
);

select pg_temp.satera_expect_rejected(
  $sql$
    select create_trade_transaction(
      p_owner_user_id => '00000000-0000-0000-0000-0000000000a1',
      p_outgoing_items => jsonb_build_array(jsonb_build_object('inventory_item_id', '70000000-0000-0000-0000-000000000002', 'trade_value', 1)),
      p_incoming_items => jsonb_build_array(jsonb_build_object(
        'category_id', '20000000-0000-0000-0000-000000000001',
        'asset_variant_id', '60000000-0000-0000-0000-000000000001',
        'trade_value', 1
      ))
    )
  $sql$,
  'product_profile alone does not authorize trade.'
);

select pg_temp.satera_expect_rejected(
  $sql$
    select create_trade_transaction(
      p_organization_id => '40000000-0000-0000-0000-000000000001',
      p_outgoing_items => jsonb_build_array(jsonb_build_object('inventory_item_id', '70000000-0000-0000-0000-000000000004', 'trade_value', 1)),
      p_incoming_items => jsonb_build_array(jsonb_build_object(
        'category_id', '20000000-0000-0000-0000-000000000003',
        'asset_variant_id', '60000000-0000-0000-0000-000000000003',
        'trade_value', 1
      ))
    )
  $sql$,
  'trade rejects organization non-member.'
);

do $$
declare
  target_id uuid;
begin
  select inventory_item_id into target_id from setup_items where label = 'workspace_source';

  begin
    perform create_trade_transaction(
      p_workspace_id => '30000000-0000-0000-0000-000000000001',
      p_outgoing_items => jsonb_build_array(jsonb_build_object('inventory_item_id', target_id, 'trade_value', 1)),
      p_incoming_items => jsonb_build_array(jsonb_build_object(
        'category_id', '20000000-0000-0000-0000-000000000001',
        'asset_variant_id', '60000000-0000-0000-0000-000000000001',
        'trade_value', 1
      ))
    );
  exception when others then
    raise notice 'ok: trade rejects workspace non-member.';
    return;
  end;

  raise exception 'verification failed: trade rejects workspace non-member.';
end;
$$;

rollback;
