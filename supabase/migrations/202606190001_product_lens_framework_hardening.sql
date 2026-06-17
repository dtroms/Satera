create or replace function can_access_product(target_product_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    auth.uid() is not null
    and exists (
      select 1
      from products
      where products.id = target_product_id
        and products.status = 'active'
    )
    and (
      is_platform_admin()
      or is_product_admin(target_product_id)
      or exists (
        select 1
        from product_profiles
        where product_profiles.product_id = target_product_id
          and product_profiles.user_id = auth.uid()
      )
      or exists (
        select 1
        from organization_product_profiles opp
        join organization_memberships om
          on om.organization_id = opp.organization_id
        where opp.product_id = target_product_id
          and om.user_id = auth.uid()
      )
      or exists (
        select 1
        from account_entitlements
        where account_entitlements.user_id = auth.uid()
          and account_entitlements.starts_at <= now()
          and (account_entitlements.ends_at is null or account_entitlements.ends_at > now())
      )
      or exists (
        select 1
        from organization_entitlements oe
        join organization_memberships om
          on om.organization_id = oe.organization_id
        where om.user_id = auth.uid()
          and oe.starts_at <= now()
          and (oe.ends_at is null or oe.ends_at > now())
      )
      or true
    ),
    false
  );
$$;

create or replace function is_category_in_product(
  target_category_id uuid,
  target_product_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from product_categories
    where product_categories.category_id = target_category_id
      and product_categories.product_id = target_product_id
  );
$$;

create or replace function inventory_item_belongs_to_product(
  target_inventory_item_id uuid,
  target_product_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from inventory_items ii
    join asset_variants av on av.id = ii.asset_variant_id
    join asset_families af on af.id = av.asset_family_id
    join product_categories pc
      on pc.product_id = target_product_id
      and pc.category_id in (ii.category_id, av.category_id, af.category_id)
    where ii.id = target_inventory_item_id
  );
$$;

revoke all on function can_access_product(uuid) from public, anon;
revoke all on function is_category_in_product(uuid, uuid) from public, anon;
revoke all on function inventory_item_belongs_to_product(uuid, uuid) from public, anon;

grant execute on function can_access_product(uuid) to authenticated;
grant execute on function is_category_in_product(uuid, uuid) to authenticated;
grant execute on function inventory_item_belongs_to_product(uuid, uuid) to authenticated;
