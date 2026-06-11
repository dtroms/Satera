-- Verifies atomic RPC write workflows for starting inventory and purchase
-- transactions, including basis semantics and ownership authorization.

begin;

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

set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000a1';

create temp table rpc_transaction_results (
  label text primary key,
  inventory_item_id uuid not null,
  transaction_id uuid not null
) on commit drop;

insert into rpc_transaction_results
select
  'starting_missing_basis',
  inventory_item_id,
  transaction_id
from create_starting_inventory_transaction(
  p_owner_user_id => '00000000-0000-0000-0000-0000000000a1',
  p_category_id => '20000000-0000-0000-0000-000000000001',
  p_asset_variant_id => '60000000-0000-0000-0000-000000000001',
  p_condition_type => 'raw',
  p_status => 'active',
  p_availability => 'available',
  p_intent => 'hold',
  p_initial_basis => null,
  p_notes => 'RPC starting inventory with missing basis.',
  p_transaction_date => '2026-01-01T00:00:00Z',
  p_source => 'sql_verification'
);

select pg_temp.satera_assert(
  (
    select ii.true_basis is null
      and t.transaction_type = 'starting_inventory'
      and tl.id is not null
      and oe.id is not null
      and ae.id is not null
      and be.id is null
    from rpc_transaction_results r
    join inventory_items ii on ii.id = r.inventory_item_id
    join transactions t on t.id = r.transaction_id
    left join transaction_lines tl on tl.transaction_id = r.transaction_id
      and tl.inventory_item_id = r.inventory_item_id
    left join ownership_events oe on oe.transaction_id = r.transaction_id
      and oe.inventory_item_id = r.inventory_item_id
    left join basis_events be on be.transaction_id = r.transaction_id
      and be.inventory_item_id = r.inventory_item_id
    left join audit_events ae on ae.entity_table = 'inventory_items'
      and ae.entity_id = r.inventory_item_id
    where r.label = 'starting_missing_basis'
  ),
  'create_starting_inventory_transaction with missing basis creates required rows and no basis_event.'
);

insert into rpc_transaction_results
select
  'starting_zero_basis',
  inventory_item_id,
  transaction_id
from create_starting_inventory_transaction(
  p_owner_user_id => '00000000-0000-0000-0000-0000000000a1',
  p_category_id => '20000000-0000-0000-0000-000000000002',
  p_asset_variant_id => '60000000-0000-0000-0000-000000000002',
  p_condition_type => 'raw',
  p_status => 'active',
  p_availability => 'available',
  p_intent => 'hold',
  p_initial_basis => 0,
  p_notes => 'RPC starting inventory with known zero basis.',
  p_transaction_date => '2026-01-02T00:00:00Z',
  p_source => 'sql_verification'
);

select pg_temp.satera_assert(
  (
    select ii.true_basis = 0
      and be.basis_event_type = 'starting_basis'
      and be.amount = 0
      and be.new_basis = 0
    from rpc_transaction_results r
    join inventory_items ii on ii.id = r.inventory_item_id
    join basis_events be on be.transaction_id = r.transaction_id
      and be.inventory_item_id = r.inventory_item_id
    where r.label = 'starting_zero_basis'
  ),
  'create_starting_inventory_transaction with zero basis stores true_basis 0 and creates a basis_event.'
);

insert into rpc_transaction_results
select
  'purchase',
  inventory_item_id,
  transaction_id
from create_purchase_transaction(
  p_owner_user_id => '00000000-0000-0000-0000-0000000000a1',
  p_category_id => '20000000-0000-0000-0000-000000000001',
  p_asset_variant_id => '60000000-0000-0000-0000-000000000001',
  p_condition_type => 'raw',
  p_status => 'active',
  p_availability => 'available',
  p_intent => 'hold',
  p_purchase_price => 100,
  p_buyer_fees => 5,
  p_tax => 8,
  p_shipping => 7,
  p_direct_acquisition_costs => 10,
  p_notes => 'RPC purchase transaction.',
  p_transaction_date => '2026-01-03T00:00:00Z',
  p_source => 'sql_verification',
  p_counterparty => 'Demo seller'
);

select pg_temp.satera_assert(
  (
    select ii.true_basis = 130
      and t.transaction_type = 'purchase_single'
      and tl.amount = 100
      and tl.market_value_at_time is null
      and tl.basis_allocated = 130
      and oe.event_type = 'purchase'
      and be.basis_event_type = 'purchase_basis'
      and be.amount = 130
      and be.new_basis = 130
      and be.calculation_inputs = jsonb_build_object(
        'purchase_price', 100,
        'buyer_fees', 5,
        'tax', 8,
        'shipping', 7,
        'direct_acquisition_costs', 10
      )
      and ae.id is not null
    from rpc_transaction_results r
    join inventory_items ii on ii.id = r.inventory_item_id
    join transactions t on t.id = r.transaction_id
    join transaction_lines tl on tl.transaction_id = r.transaction_id
      and tl.inventory_item_id = r.inventory_item_id
    join ownership_events oe on oe.transaction_id = r.transaction_id
      and oe.inventory_item_id = r.inventory_item_id
    join basis_events be on be.transaction_id = r.transaction_id
      and be.inventory_item_id = r.inventory_item_id
    left join audit_events ae on ae.entity_table = 'inventory_items'
      and ae.entity_id = r.inventory_item_id
    where r.label = 'purchase'
  ),
  'create_purchase_transaction calculates basis and creates all required rows.'
);

do $$
declare
  rejected boolean := false;
begin
  begin
    perform create_starting_inventory_transaction(
      p_owner_user_id => '00000000-0000-0000-0000-0000000000a1',
      p_category_id => '20000000-0000-0000-0000-000000000001',
      p_asset_variant_id => '60000000-0000-0000-0000-000000000001',
      p_initial_basis => -1
    );
  exception when others then
    rejected := true;
  end;

  if not rejected then
    raise exception 'verification failed: negative basis is rejected.';
  end if;

  raise notice 'ok: negative basis is rejected.';
end;
$$;

do $$
declare
  rejected boolean := false;
begin
  begin
    perform create_purchase_transaction(
      p_owner_user_id => '00000000-0000-0000-0000-0000000000a1',
      p_category_id => '20000000-0000-0000-0000-000000000001',
      p_asset_variant_id => '60000000-0000-0000-0000-000000000001',
      p_purchase_price => 100,
      p_buyer_fees => -1
    );
  exception when others then
    rejected := true;
  end;

  if not rejected then
    raise exception 'verification failed: negative purchase cost inputs are rejected.';
  end if;

  raise notice 'ok: negative purchase cost inputs are rejected.';
end;
$$;

reset role;
set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000b2';

do $$
declare
  rejected boolean := false;
begin
  begin
    perform create_starting_inventory_transaction(
      p_owner_user_id => '00000000-0000-0000-0000-0000000000a1',
      p_category_id => '20000000-0000-0000-0000-000000000001',
      p_asset_variant_id => '60000000-0000-0000-0000-000000000001',
      p_initial_basis => null
    );
  exception when others then
    rejected := true;
  end;

  if not rejected then
    raise exception 'verification failed: unauthorized user cannot create inventory for another user.';
  end if;

  raise notice 'ok: unauthorized user cannot create inventory for another user.';
end;
$$;

select pg_temp.satera_assert(
  (select count(*) = 1 from product_profiles where user_id = auth.uid()),
  'User B has a product profile for product-profile authorization check.'
);

do $$
declare
  rejected boolean := false;
begin
  begin
    perform create_purchase_transaction(
      p_owner_user_id => '00000000-0000-0000-0000-0000000000a1',
      p_category_id => '20000000-0000-0000-0000-000000000001',
      p_asset_variant_id => '60000000-0000-0000-0000-000000000001',
      p_purchase_price => 10
    );
  exception when others then
    rejected := true;
  end;

  if not rejected then
    raise exception 'verification failed: product_profile alone does not authorize inventory creation.';
  end if;

  raise notice 'ok: product_profile alone does not authorize inventory creation.';
end;
$$;

do $$
declare
  rejected boolean := false;
begin
  begin
    perform create_starting_inventory_transaction(
      p_organization_id => '40000000-0000-0000-0000-000000000001',
      p_category_id => '20000000-0000-0000-0000-000000000003',
      p_asset_variant_id => '60000000-0000-0000-0000-000000000003',
      p_initial_basis => null
    );
  exception when others then
    rejected := true;
  end;

  if not rejected then
    raise exception 'verification failed: organization non-member cannot create organization inventory.';
  end if;

  raise notice 'ok: organization non-member cannot create organization inventory.';
end;
$$;

do $$
declare
  rejected boolean := false;
begin
  begin
    perform create_purchase_transaction(
      p_workspace_id => '30000000-0000-0000-0000-000000000001',
      p_category_id => '20000000-0000-0000-0000-000000000001',
      p_asset_variant_id => '60000000-0000-0000-0000-000000000001',
      p_purchase_price => 10
    );
  exception when others then
    rejected := true;
  end;

  if not rejected then
    raise exception 'verification failed: workspace non-member cannot create workspace inventory.';
  end if;

  raise notice 'ok: workspace non-member cannot create workspace inventory.';
end;
$$;

rollback;
