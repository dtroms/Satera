-- Verifies private inventory ownership, organization membership access, and
-- the distinction between missing basis and known zero basis.

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
  (select count(*) = 1 from inventory_items where id = '70000000-0000-0000-0000-000000000001'),
  'User A can read User A inventory.'
);

select pg_temp.satera_assert(
  (select true_basis is null from inventory_items where id = '70000000-0000-0000-0000-000000000001'),
  'true_basis null means Missing basis.'
);

select pg_temp.satera_assert(
  (select true_basis = 0 from inventory_items where id = '70000000-0000-0000-0000-000000000002'),
  'true_basis 0 means known zero basis.'
);

select pg_temp.satera_assert(
  (select count(*) = 0 from inventory_items where id = '70000000-0000-0000-0000-000000000003'),
  'User A cannot read User B inventory.'
);

select pg_temp.satera_assert(
  (select count(*) = 1 from inventory_items where id = '70000000-0000-0000-0000-000000000004'),
  'Organization member can read organization inventory.'
);

reset role;
set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000b2';

select pg_temp.satera_assert(
  (select count(*) = 1 from product_profiles where id = '90000000-0000-0000-0000-000000000001'),
  'User B can read User B Card Vertex product profile.'
);

select pg_temp.satera_assert(
  (select count(*) = 0 from inventory_items where id = '70000000-0000-0000-0000-000000000001'),
  'Product profile alone does not grant access to another user inventory.'
);

select pg_temp.satera_assert(
  (select count(*) = 0 from inventory_items where id = '70000000-0000-0000-0000-000000000004'),
  'Non-member cannot read organization inventory.'
);

rollback;
