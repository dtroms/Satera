-- Verifies account and organization entitlements are product capabilities,
-- not privacy overrides.

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

insert into account_entitlements (user_id, entitlement_key)
values ('00000000-0000-0000-0000-0000000000b2', 'cross_vertex_portfolio')
on conflict (user_id, entitlement_key) do nothing;

set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000a1';

select pg_temp.satera_assert(
  has_account_entitlement(auth.uid(), 'cross_vertex_portfolio'),
  'cross_vertex_portfolio is present for User A.'
);

select pg_temp.satera_assert(
  (
    select count(*) = 2
    from inventory_items
    where owner_user_id = auth.uid()
  ),
  'cross_vertex_portfolio lets User A aggregate only User A inventory.'
);

reset role;
set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000b2';

select pg_temp.satera_assert(
  has_account_entitlement(auth.uid(), 'cross_vertex_portfolio'),
  'cross_vertex_portfolio can exist for User B.'
);

select pg_temp.satera_assert(
  (
    select count(*) = 0
    from inventory_items
    where owner_user_id = '00000000-0000-0000-0000-0000000000a1'
  ),
  'cross_vertex_portfolio does not allow User B to read User A inventory.'
);

select pg_temp.satera_assert(
  has_organization_entitlement('40000000-0000-0000-0000-000000000001', 'vertex_pro'),
  'Organization entitlement exists on Demo Organization.'
);

select pg_temp.satera_assert(
  (
    select count(*) = 0
    from inventory_items
    where organization_id = '40000000-0000-0000-0000-000000000001'
  ),
  'Organization entitlements do not allow non-members to read organization inventory.'
);

rollback;
