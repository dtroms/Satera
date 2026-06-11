-- Verifies products act as category lenses and do not own inventory.

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
  (
    select count(*) = 1
    from product_categories pc
    join products p on p.id = pc.product_id
    where p.slug = 'card_vertex'
  ),
  'Authenticated users can read active product category mappings needed for product lenses.'
);

select pg_temp.satera_assert(
  (
    select count(*) = 1
    from inventory_items ii
    join product_categories pc on pc.category_id = ii.category_id
    join products p on p.id = pc.product_id
    where p.slug = 'card_vertex'
      and ii.owner_user_id = auth.uid()
  ),
  'Card Vertex lens returns only owned inventory in Card Vertex-supported categories.'
);

select pg_temp.satera_assert(
  (
    select count(*) = 2
    from inventory_items ii
    join product_categories pc on pc.category_id = ii.category_id
    join products p on p.id = pc.product_id
    where p.slug = 'satera_portfolio'
      and ii.owner_user_id = auth.uid()
      and has_account_entitlement(auth.uid(), 'cross_vertex_portfolio')
  ),
  'Satera Portfolio can aggregate User A own cross-category inventory with cross_vertex_portfolio entitlement.'
);

select pg_temp.satera_assert(
  (
    select count(*) = 1
    from inventory_items ii
    join product_categories pc on pc.category_id = ii.category_id
    join products p on p.id = pc.product_id
    where p.slug = 'vertex_pro'
      and ii.organization_id = '40000000-0000-0000-0000-000000000001'
      and is_organization_member(ii.organization_id)
      and (
        has_organization_entitlement(ii.organization_id, 'vertex_pro')
        or has_organization_entitlement(ii.organization_id, 'cross_vertex_inventory')
      )
  ),
  'Vertex Pro lens can return organization inventory across supported categories for entitled member organizations.'
);

reset role;
set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000b2';

select pg_temp.satera_assert(
  (
    select count(*) = 0
    from inventory_items ii
    join product_categories pc on pc.category_id = ii.category_id
    join products p on p.id = pc.product_id
    where p.slug = 'card_vertex'
      and ii.owner_user_id = '00000000-0000-0000-0000-0000000000a1'
  ),
  'Product lens cannot bypass private inventory RLS for another user.'
);

select pg_temp.satera_assert(
  (
    select count(*) = 0
    from inventory_items ii
    join product_categories pc on pc.category_id = ii.category_id
    join products p on p.id = pc.product_id
    where p.slug = 'vertex_pro'
      and ii.organization_id = '40000000-0000-0000-0000-000000000001'
      and (
        has_organization_entitlement('40000000-0000-0000-0000-000000000001', 'vertex_pro')
        or has_organization_entitlement('40000000-0000-0000-0000-000000000001', 'cross_vertex_inventory')
      )
  ),
  'Vertex Pro entitlement does not expose organization inventory to non-members.'
);

rollback;
