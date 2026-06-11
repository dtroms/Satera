-- Verifies a trade lineage can explain an incoming item basis from outgoing
-- source basis plus cash paid.

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

insert into inventory_items (
  id,
  owner_user_id,
  category_id,
  asset_variant_id,
  condition_type,
  status,
  availability,
  intent,
  true_basis,
  acquired_at,
  notes,
  created_by,
  updated_by
) values
  (
    '71000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-0000000000a1',
    '20000000-0000-0000-0000-000000000001',
    '60000000-0000-0000-0000-000000000001',
    'raw',
    'traded',
    'archived',
    'trade',
    100,
    now(),
    'Demo trade Item A: outgoing item with known basis 100.',
    '00000000-0000-0000-0000-0000000000a1',
    '00000000-0000-0000-0000-0000000000a1'
  ),
  (
    '71000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-0000000000a1',
    '20000000-0000-0000-0000-000000000002',
    '60000000-0000-0000-0000-000000000002',
    'raw',
    'active',
    'available',
    'hold',
    150,
    now(),
    'Demo trade Item B: incoming item with basis from Item A plus cash.',
    '00000000-0000-0000-0000-0000000000a1',
    '00000000-0000-0000-0000-0000000000a1'
  );

insert into transactions (
  id,
  owner_user_id,
  transaction_type,
  transaction_date,
  source,
  counterparty,
  notes,
  created_by
) values (
  '72000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-0000000000a1',
  'trade',
  now(),
  'manual_demo',
  'Demo Counterparty',
  'User trades Item A plus 50 cash to receive Item B.',
  '00000000-0000-0000-0000-0000000000a1'
);

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
) values
  (
    '72000000-0000-0000-0000-000000000001',
    'inventory',
    '71000000-0000-0000-0000-000000000001',
    'out',
    null,
    100,
    100,
    100,
    null,
    'Outgoing Item A basis frozen at 100.'
  ),
  (
    '72000000-0000-0000-0000-000000000001',
    'cash',
    null,
    'out',
    50,
    null,
    null,
    null,
    null,
    'Cash paid into trade basis pool.'
  ),
  (
    '72000000-0000-0000-0000-000000000001',
    'inventory',
    '71000000-0000-0000-0000-000000000002',
    'in',
    null,
    150,
    150,
    null,
    150,
    'Incoming Item B receives allocated basis 150.'
  );

insert into ownership_events (
  owner_user_id,
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
) values
  (
    '00000000-0000-0000-0000-0000000000a1',
    '71000000-0000-0000-0000-000000000001',
    '72000000-0000-0000-0000-000000000001',
    'trade_out',
    now(),
    'active',
    'traded',
    '{"owner_user_id":"00000000-0000-0000-0000-0000000000a1"}'::jsonb,
    '{"owner_user_id":"00000000-0000-0000-0000-0000000000a1","status":"traded"}'::jsonb,
    'Item A traded out.',
    '00000000-0000-0000-0000-0000000000a1'
  ),
  (
    '00000000-0000-0000-0000-0000000000a1',
    '71000000-0000-0000-0000-000000000002',
    '72000000-0000-0000-0000-000000000001',
    'trade_in',
    now(),
    null,
    'active',
    null,
    '{"owner_user_id":"00000000-0000-0000-0000-0000000000a1"}'::jsonb,
    'Item B received from trade.',
    '00000000-0000-0000-0000-0000000000a1'
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
  '71000000-0000-0000-0000-000000000002',
  '72000000-0000-0000-0000-000000000001',
  'trade_allocation',
  150,
  0,
  150,
  'trade_basis_pool',
  '{"source_basis_amount":100,"cash_paid_amount":50,"cash_received_amount":0,"fees_amount":0}'::jsonb,
  null,
  '00000000-0000-0000-0000-0000000000a1'
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
  '72000000-0000-0000-0000-000000000001',
  '71000000-0000-0000-0000-000000000001',
  '71000000-0000-0000-0000-000000000002',
  100,
  50,
  0,
  0,
  150,
  'one_for_one_trade',
  '{"basis_pool":"source_basis_amount + cash_paid_amount - cash_received_amount + fees_amount"}'::jsonb
);

set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000a1';

select pg_temp.satera_assert(
  (select true_basis = 150 from inventory_items where id = '71000000-0000-0000-0000-000000000002'),
  'Item B true_basis becomes 150.'
);

select pg_temp.satera_assert(
  (select count(*) = 1 from transactions where id = '72000000-0000-0000-0000-000000000001'),
  'Trade transaction is readable by owning user.'
);

select pg_temp.satera_assert(
  (
    select count(*) = 3
    from transaction_lines
    where transaction_id = '72000000-0000-0000-0000-000000000001'
  ),
  'Transaction lines freeze outgoing basis, cash paid, and incoming trade value.'
);

select pg_temp.satera_assert(
  (
    select count(*) = 2
    from ownership_events
    where transaction_id = '72000000-0000-0000-0000-000000000001'
      and event_type in ('trade_out', 'trade_in')
  ),
  'Ownership events show Item A traded_out and Item B trade_in.'
);

select pg_temp.satera_assert(
  (
    select count(*) = 1
    from basis_events
    where inventory_item_id = '71000000-0000-0000-0000-000000000002'
      and basis_event_type = 'trade_allocation'
      and previous_basis = 0
      and new_basis = 150
  ),
  'Basis events show Item B trade allocation.'
);

select pg_temp.satera_assert(
  (
    select source_basis_amount = 100
      and cash_paid_amount = 50
      and allocated_basis_amount = 150
    from basis_lineage_edges
    where source_inventory_item_id = '71000000-0000-0000-0000-000000000001'
      and target_inventory_item_id = '71000000-0000-0000-0000-000000000002'
  ),
  'Basis lineage edge links Item A basis and cash to Item B.'
);

select pg_temp.satera_assert(
  (
    select sum(source_basis_amount + cash_paid_amount - cash_received_amount + fees_amount) = 150
    from basis_lineage_edges
    where target_inventory_item_id = '71000000-0000-0000-0000-000000000002'
  ),
  'Lineage query explains Item B basis as 100 source basis plus 50 cash.'
);

reset role;
set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000b2';

select pg_temp.satera_assert(
  (select count(*) = 0 from inventory_items where id = '71000000-0000-0000-0000-000000000002'),
  'Another user cannot read the trade item.'
);

select pg_temp.satera_assert(
  (
    select count(*) = 0
    from basis_lineage_edges
    where target_inventory_item_id = '71000000-0000-0000-0000-000000000002'
  ),
  'Another user cannot read private basis lineage.'
);

rollback;
