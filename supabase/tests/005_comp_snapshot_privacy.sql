-- Verifies owner-scoped comp snapshots and confirms value snapshots do not
-- mutate inventory true_basis.

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

select pg_temp.satera_assert(
  (select count(*) = 1 from comp_snapshots where id = '80000000-0000-0000-0000-000000000001'),
  'User-created comp snapshot is owner-scoped and readable by owner.'
);

select pg_temp.satera_assert(
  (select true_basis = 0 from inventory_items where id = '70000000-0000-0000-0000-000000000002'),
  'Seed item starts with known zero basis.'
);

insert into comp_snapshots (
  id,
  owner_user_id,
  category_id,
  asset_family_id,
  asset_variant_id,
  inventory_item_id,
  source,
  market_value,
  currency_code,
  method,
  number_of_comps,
  condition_or_grade,
  snapshot_data,
  created_by
) values (
  '80000000-0000-0000-0000-000000000002',
  auth.uid(),
  '20000000-0000-0000-0000-000000000002',
  '50000000-0000-0000-0000-000000000002',
  '60000000-0000-0000-0000-000000000002',
  '70000000-0000-0000-0000-000000000002',
  'manual_demo',
  95,
  'USD',
  'manual',
  2,
  'raw demo condition',
  '{"demo":true,"note":"second owner-scoped comp"}'::jsonb,
  auth.uid()
);

select pg_temp.satera_assert(
  (select true_basis = 0 from inventory_items where id = '70000000-0000-0000-0000-000000000002'),
  'Adding a new comp snapshot does not change true_basis.'
);

select pg_temp.satera_assert(
  (
    select market_value = 95
      and inventory_item_id = '70000000-0000-0000-0000-000000000002'
    from comp_snapshots
    where id = '80000000-0000-0000-0000-000000000002'
  ),
  'Market value snapshot data is stored separately from basis.'
);

reset role;
set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000b2';

select pg_temp.satera_assert(
  (select count(*) = 0 from comp_snapshots where id = '80000000-0000-0000-0000-000000000001'),
  'Another user cannot read owner-scoped comp snapshot.'
);

select pg_temp.satera_assert(
  (select count(*) = 0 from comp_snapshots where id = '80000000-0000-0000-0000-000000000002'),
  'Another user cannot read newly added owner-scoped comp snapshot.'
);

rollback;
