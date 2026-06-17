-- Verifies sale transactions complete the ownership lifecycle:
-- purchase -> own -> sell -> realize profit/loss.

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

create temp table sale_setup_items (
  label text primary key,
  inventory_item_id uuid not null,
  transaction_id uuid not null
) on commit drop;

create temp table sale_results (
  label text primary key,
  inventory_item_id uuid not null,
  transaction_id uuid not null,
  gross_sale_price numeric not null,
  selling_costs numeric not null,
  net_proceeds numeric not null,
  basis_at_sale numeric not null,
  realized_profit_loss numeric not null
) on commit drop;

insert into sale_setup_items
select
  'profit_source',
  inventory_item_id,
  transaction_id
from create_purchase_transaction(
  p_owner_user_id => auth.uid(),
  p_category_id => '20000000-0000-0000-0000-000000000001',
  p_asset_variant_id => '60000000-0000-0000-0000-000000000001',
  p_purchase_price => 100,
  p_buyer_fees => 5,
  p_tax => 8,
  p_shipping => 7,
  p_direct_acquisition_costs => 10,
  p_transaction_date => '2026-04-01T00:00:00Z',
  p_source => 'sale_verification',
  p_counterparty => 'Demo seller'
);

insert into sale_results
select
  'profit_sale',
  inventory_item_id,
  transaction_id,
  gross_sale_price,
  selling_costs,
  net_proceeds,
  basis_at_sale,
  realized_profit_loss
from create_sale_transaction(
  p_owner_user_id => auth.uid(),
  p_inventory_item_id => (select inventory_item_id from sale_setup_items where label = 'profit_source'),
  p_sale_price => 200,
  p_platform_fees => 10,
  p_payment_processing_fees => 3,
  p_shipping_cost => 5,
  p_supplies_cost => 2,
  p_consignment_fees => 4,
  p_other_selling_costs => 1,
  p_transaction_date => '2026-04-02T00:00:00Z',
  p_source => 'sale_verification',
  p_counterparty => 'Demo buyer',
  p_notes => 'Profitable sale.'
);

select pg_temp.satera_assert(
  (
    select r.gross_sale_price = 200
      and r.selling_costs = 25
      and r.net_proceeds = 175
      and r.basis_at_sale = 130
      and r.realized_profit_loss = 45
      and ii.status = 'sold'
      and ii.availability = 'archived'
      and ii.true_basis = 130
      and ii.current_value_snapshot_id is null
      and t.transaction_type = 'sale'
      and (t.metadata ->> 'platform_fees')::numeric = 10
      and (t.metadata ->> 'payment_processing_fees')::numeric = 3
      and (t.metadata ->> 'shipping_cost')::numeric = 5
      and (t.metadata ->> 'supplies_cost')::numeric = 2
      and (t.metadata ->> 'consignment_fees')::numeric = 4
      and (t.metadata ->> 'other_selling_costs')::numeric = 1
      and (t.metadata ->> 'total_selling_costs')::numeric = 25
      and (t.metadata ->> 'net_proceeds')::numeric = 175
      and (t.metadata ->> 'realized_profit_loss')::numeric = 45
      and tl_inventory.direction = 'out'
      and tl_inventory.amount = 200
      and tl_inventory.basis_at_time = 130
      and tl_platform.amount = 10
      and tl_processing.amount = 3
      and tl_shipping.amount = 5
      and tl_supplies.amount = 2
      and tl_consignment.amount = 4
      and tl_other.amount = 1
      and tl_profit.amount = 45
      and oe.event_type = 'sale'
      and oe.previous_status = 'active'
      and oe.new_status = 'sold'
      and be.basis_event_type = 'sale_realization'
      and be.amount = 130
      and be.previous_basis = 130
      and be.new_basis = 130
      and be.calculation_method = 'net_proceeds_minus_true_basis'
      and (be.calculation_inputs ->> 'platform_fees')::numeric = 10
      and (be.calculation_inputs ->> 'payment_processing_fees')::numeric = 3
      and (be.calculation_inputs ->> 'shipping_cost')::numeric = 5
      and (be.calculation_inputs ->> 'supplies_cost')::numeric = 2
      and (be.calculation_inputs ->> 'consignment_fees')::numeric = 4
      and (be.calculation_inputs ->> 'other_selling_costs')::numeric = 1
      and (be.calculation_inputs ->> 'total_selling_costs')::numeric = 25
      and (be.calculation_inputs ->> 'net_proceeds')::numeric = 175
      and (be.calculation_inputs ->> 'realized_profit_loss')::numeric = 45
      and (ae.metadata ->> 'platform_fees')::numeric = 10
      and (ae.metadata ->> 'payment_processing_fees')::numeric = 3
      and (ae.metadata ->> 'shipping_cost')::numeric = 5
      and (ae.metadata ->> 'supplies_cost')::numeric = 2
      and (ae.metadata ->> 'consignment_fees')::numeric = 4
      and (ae.metadata ->> 'other_selling_costs')::numeric = 1
      and (ae.metadata ->> 'total_selling_costs')::numeric = 25
      and (ae.metadata ->> 'net_proceeds')::numeric = 175
      and (ae.metadata ->> 'realized_profit_loss')::numeric = 45
      and ae.id is not null
    from sale_results r
    join inventory_items ii on ii.id = r.inventory_item_id
    join transactions t on t.id = r.transaction_id
    join transaction_lines tl_inventory on tl_inventory.transaction_id = r.transaction_id
      and tl_inventory.inventory_item_id = r.inventory_item_id
      and tl_inventory.line_type = 'inventory'
    join transaction_lines tl_platform on tl_platform.transaction_id = r.transaction_id
      and tl_platform.line_type = 'fee'
      and tl_platform.notes = 'Platform fees.'
    join transaction_lines tl_processing on tl_processing.transaction_id = r.transaction_id
      and tl_processing.line_type = 'fee'
      and tl_processing.notes = 'Payment processing fees.'
    join transaction_lines tl_shipping on tl_shipping.transaction_id = r.transaction_id
      and tl_shipping.line_type = 'shipping'
    join transaction_lines tl_supplies on tl_supplies.transaction_id = r.transaction_id
      and tl_supplies.line_type = 'fee'
      and tl_supplies.notes = 'Supplies cost.'
    join transaction_lines tl_consignment on tl_consignment.transaction_id = r.transaction_id
      and tl_consignment.line_type = 'fee'
      and tl_consignment.notes = 'Consignment fees.'
    join transaction_lines tl_other on tl_other.transaction_id = r.transaction_id
      and tl_other.line_type = 'fee'
      and tl_other.notes = 'Other selling costs.'
    join transaction_lines tl_profit on tl_profit.transaction_id = r.transaction_id
      and tl_profit.line_type = 'value'
    join ownership_events oe on oe.transaction_id = r.transaction_id
      and oe.inventory_item_id = r.inventory_item_id
    join basis_events be on be.transaction_id = r.transaction_id
      and be.inventory_item_id = r.inventory_item_id
    left join audit_events ae on ae.entity_table = 'transactions'
      and ae.entity_id = r.transaction_id
      and ae.event_type = 'sale_transaction_created'
    where r.label = 'profit_sale'
  ),
  'create_sale_transaction records sale math and freezes basis without changing current value.'
);

insert into sale_setup_items
select
  'zero_basis_source',
  inventory_item_id,
  transaction_id
from create_starting_inventory_transaction(
  p_owner_user_id => auth.uid(),
  p_category_id => '20000000-0000-0000-0000-000000000002',
  p_asset_variant_id => '60000000-0000-0000-0000-000000000002',
  p_initial_basis => 0,
  p_transaction_date => '2026-04-03T00:00:00Z',
  p_source => 'sale_verification'
);

insert into sale_results
select
  'zero_basis_sale',
  inventory_item_id,
  transaction_id,
  gross_sale_price,
  selling_costs,
  net_proceeds,
  basis_at_sale,
  realized_profit_loss
from create_sale_transaction(
  p_owner_user_id => auth.uid(),
  p_inventory_item_id => (select inventory_item_id from sale_setup_items where label = 'zero_basis_source'),
  p_sale_price => 25,
  p_transaction_date => '2026-04-04T00:00:00Z',
  p_source => 'sale_verification'
);

select pg_temp.satera_assert(
  (
    select basis_at_sale = 0
      and realized_profit_loss = 25
      and ii.true_basis = 0
      and ii.status = 'sold'
    from sale_results r
    join inventory_items ii on ii.id = r.inventory_item_id
    where r.label = 'zero_basis_sale'
  ),
  'create_sale_transaction allows known zero true_basis.'
);

insert into sale_setup_items
select
  'missing_basis_source',
  inventory_item_id,
  transaction_id
from create_starting_inventory_transaction(
  p_owner_user_id => auth.uid(),
  p_category_id => '20000000-0000-0000-0000-000000000003',
  p_asset_variant_id => '60000000-0000-0000-0000-000000000003',
  p_initial_basis => null,
  p_transaction_date => '2026-04-05T00:00:00Z',
  p_source => 'sale_verification'
);

select pg_temp.satera_expect_rejected(
  format(
    $sql$
      select * from create_sale_transaction(
        p_owner_user_id => auth.uid(),
        p_inventory_item_id => %L::uuid,
        p_sale_price => 10
      )
    $sql$,
    (select inventory_item_id from sale_setup_items where label = 'missing_basis_source')
  ),
  'create_sale_transaction rejects missing true_basis.'
);

insert into sale_setup_items
select
  'negative_input_source',
  inventory_item_id,
  transaction_id
from create_starting_inventory_transaction(
  p_owner_user_id => auth.uid(),
  p_category_id => '20000000-0000-0000-0000-000000000004',
  p_asset_variant_id => '60000000-0000-0000-0000-000000000004',
  p_initial_basis => 10,
  p_transaction_date => '2026-04-06T00:00:00Z',
  p_source => 'sale_verification'
);

select pg_temp.satera_expect_rejected(
  format(
    $sql$
      select * from create_sale_transaction(
        p_owner_user_id => auth.uid(),
        p_inventory_item_id => %L::uuid,
        p_sale_price => -1
      )
    $sql$,
    (select inventory_item_id from sale_setup_items where label = 'negative_input_source')
  ),
  'create_sale_transaction rejects negative sale price.'
);

select pg_temp.satera_expect_rejected(
  format(
    $sql$
      select * from create_sale_transaction(
        p_owner_user_id => auth.uid(),
        p_inventory_item_id => %L::uuid,
        p_sale_price => 10,
        p_platform_fees => -1
      )
    $sql$,
    (select inventory_item_id from sale_setup_items where label = 'negative_input_source')
  ),
  'create_sale_transaction rejects negative fees or costs.'
);

insert into sale_setup_items
select
  'resale_source',
  inventory_item_id,
  transaction_id
from create_starting_inventory_transaction(
  p_owner_user_id => auth.uid(),
  p_category_id => '20000000-0000-0000-0000-000000000001',
  p_asset_variant_id => '60000000-0000-0000-0000-000000000001',
  p_initial_basis => 40,
  p_transaction_date => '2026-04-07T00:00:00Z',
  p_source => 'sale_verification'
);

insert into sale_results
select
  'resale_first_sale',
  inventory_item_id,
  transaction_id,
  gross_sale_price,
  selling_costs,
  net_proceeds,
  basis_at_sale,
  realized_profit_loss
from create_sale_transaction(
  p_owner_user_id => auth.uid(),
  p_inventory_item_id => (select inventory_item_id from sale_setup_items where label = 'resale_source'),
  p_sale_price => 55,
  p_transaction_date => '2026-04-08T00:00:00Z',
  p_source => 'sale_verification'
);

select pg_temp.satera_expect_rejected(
  format(
    $sql$
      select * from create_sale_transaction(
        p_owner_user_id => auth.uid(),
        p_inventory_item_id => %L::uuid,
        p_sale_price => 60
      )
    $sql$,
    (select inventory_item_id from sale_setup_items where label = 'resale_source')
  ),
  'create_sale_transaction rejects already sold inventory.'
);

insert into sale_setup_items
select
  'trade_source',
  inventory_item_id,
  transaction_id
from create_starting_inventory_transaction(
  p_owner_user_id => auth.uid(),
  p_category_id => '20000000-0000-0000-0000-000000000001',
  p_asset_variant_id => '60000000-0000-0000-0000-000000000001',
  p_initial_basis => 35,
  p_transaction_date => '2026-04-09T00:00:00Z',
  p_source => 'sale_verification'
);

select transaction_id
from create_trade_transaction(
  p_owner_user_id => auth.uid(),
  p_transaction_date => '2026-04-10T00:00:00Z',
  p_source => 'sale_verification',
  p_outgoing_items => jsonb_build_array(jsonb_build_object(
    'inventory_item_id', (select inventory_item_id from sale_setup_items where label = 'trade_source'),
    'trade_value', 35
  )),
  p_incoming_items => jsonb_build_array(jsonb_build_object(
    'category_id', '20000000-0000-0000-0000-000000000002',
    'asset_variant_id', '60000000-0000-0000-0000-000000000002',
    'trade_value', 35
  ))
);

select pg_temp.satera_expect_rejected(
  format(
    $sql$
      select * from create_sale_transaction(
        p_owner_user_id => auth.uid(),
        p_inventory_item_id => %L::uuid,
        p_sale_price => 40
      )
    $sql$,
    (select inventory_item_id from sale_setup_items where label = 'trade_source')
  ),
  'create_sale_transaction rejects inventory outside active ownership.'
);

reset role;
set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000b2';

select pg_temp.satera_expect_rejected(
  format(
    $sql$
      select * from create_sale_transaction(
        p_owner_user_id => '00000000-0000-0000-0000-0000000000a1',
        p_inventory_item_id => %L::uuid,
        p_sale_price => 75
      )
    $sql$,
    (select inventory_item_id from sale_setup_items where label = 'negative_input_source')
  ),
  'create_sale_transaction rejects selling another user inventory.'
);

rollback;
