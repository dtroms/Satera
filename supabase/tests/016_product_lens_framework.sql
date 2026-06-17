-- Verifies product lenses are scoped views over Satera Core data, not data silos.

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
  workspace_id,
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
    null,
    '30000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000001',
    '60000000-0000-0000-0000-000000000001',
    'raw',
    'active',
    'available',
    'hold',
    10,
    now(),
    'Workspace sports card product lens fixture.',
    '00000000-0000-0000-0000-0000000000a1',
    '00000000-0000-0000-0000-0000000000a1'
  ),
  (
    '71000000-0000-0000-0000-000000000002',
    null,
    '30000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000002',
    '60000000-0000-0000-0000-000000000002',
    'raw',
    'active',
    'available',
    'hold',
    20,
    now(),
    'Workspace comic product lens fixture.',
    '00000000-0000-0000-0000-0000000000a1',
    '00000000-0000-0000-0000-0000000000a1'
  ),
  (
    '71000000-0000-0000-0000-000000000003',
    '00000000-0000-0000-0000-0000000000b2',
    null,
    '20000000-0000-0000-0000-000000000001',
    '60000000-0000-0000-0000-000000000001',
    'raw',
    'active',
    'available',
    'hold',
    30,
    now(),
    'User B private sports card fixture.',
    '00000000-0000-0000-0000-0000000000b2',
    '00000000-0000-0000-0000-0000000000b2'
  );

insert into account_entitlements (user_id, entitlement_key)
values ('00000000-0000-0000-0000-0000000000b2', 'cross_vertex_portfolio')
on conflict (user_id, entitlement_key) do nothing;

insert into public_object_references (
  id,
  owner_user_id,
  product_id,
  category_id,
  inventory_item_id,
  asset_family_id,
  asset_variant_id,
  object_type,
  display_title,
  display_subtitle,
  display_label,
  visibility,
  exposure_state,
  public_metadata,
  created_by,
  updated_by
) values
  (
    'a1000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-0000000000a1',
    '10000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000001',
    '70000000-0000-0000-0000-000000000001',
    '50000000-0000-0000-0000-000000000001',
    '60000000-0000-0000-0000-000000000001',
    'inventory_item',
    'Safe Card Reference',
    'Public card display only',
    'Card',
    'community',
    'active',
    '{"safe":true}'::jsonb,
    '00000000-0000-0000-0000-0000000000a1',
    '00000000-0000-0000-0000-0000000000a1'
  ),
  (
    'a1000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-0000000000a1',
    '10000000-0000-0000-0000-000000000003',
    '20000000-0000-0000-0000-000000000002',
    '70000000-0000-0000-0000-000000000002',
    '50000000-0000-0000-0000-000000000002',
    '60000000-0000-0000-0000-000000000002',
    'inventory_item',
    'Safe Portfolio Comic Reference',
    'Public comic display only',
    'Comic',
    'community',
    'active',
    '{"safe":true}'::jsonb,
    '00000000-0000-0000-0000-0000000000a1',
    '00000000-0000-0000-0000-0000000000a1'
  );

insert into communities (
  id,
  product_id,
  owner_user_id,
  name,
  slug,
  description,
  visibility,
  created_by,
  updated_by
) values
  (
    'b1000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-0000000000a1',
    'Product Lens Card Community',
    'product-lens-card-community',
    'Product lens test community.',
    'public',
    '00000000-0000-0000-0000-0000000000a1',
    '00000000-0000-0000-0000-0000000000a1'
  ),
  (
    'b1000000-0000-0000-0000-000000000002',
    '10000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-0000000000a1',
    'Product Lens Vertex Pro Community',
    'product-lens-vertex-pro-community',
    'Cross-product test community.',
    'public',
    '00000000-0000-0000-0000-0000000000a1',
    '00000000-0000-0000-0000-0000000000a1'
  );

insert into notification_events (
  id,
  product_id,
  actor_user_id,
  event_type,
  entity_table,
  entity_id,
  title,
  safe_metadata
) values
  (
    'c1000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-0000000000a1',
    'product_lens.card',
    'communities',
    'b1000000-0000-0000-0000-000000000001',
    'Card lens notification',
    '{"safe":true}'::jsonb
  ),
  (
    'c1000000-0000-0000-0000-000000000002',
    '10000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-0000000000a1',
    'product_lens.vertex_pro',
    'communities',
    'b1000000-0000-0000-0000-000000000002',
    'Vertex Pro notification',
    '{"safe":true}'::jsonb
  ),
  (
    'c1000000-0000-0000-0000-000000000003',
    null,
    '00000000-0000-0000-0000-0000000000a1',
    'product_lens.global',
    'products',
    '10000000-0000-0000-0000-000000000001',
    'Global notification',
    '{"safe":true}'::jsonb
  );

insert into notifications (
  id,
  notification_event_id,
  recipient_user_id,
  product_id,
  notification_type,
  title,
  entity_table,
  entity_id,
  status,
  safe_metadata
) values
  (
    'd1000000-0000-0000-0000-000000000001',
    'c1000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-0000000000a1',
    '10000000-0000-0000-0000-000000000001',
    'product_lens',
    'Card lens notification',
    'communities',
    'b1000000-0000-0000-0000-000000000001',
    'unread',
    '{"safe":true}'::jsonb
  ),
  (
    'd1000000-0000-0000-0000-000000000002',
    'c1000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-0000000000a1',
    '10000000-0000-0000-0000-000000000002',
    'product_lens',
    'Vertex Pro notification',
    'communities',
    'b1000000-0000-0000-0000-000000000002',
    'unread',
    '{"safe":true}'::jsonb
  ),
  (
    'd1000000-0000-0000-0000-000000000003',
    'c1000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-0000000000b2',
    '10000000-0000-0000-0000-000000000001',
    'product_lens',
    'Card lens notification for B',
    'communities',
    'b1000000-0000-0000-0000-000000000001',
    'unread',
    '{"safe":true}'::jsonb
  ),
  (
    'd1000000-0000-0000-0000-000000000004',
    'c1000000-0000-0000-0000-000000000003',
    '00000000-0000-0000-0000-0000000000a1',
    null,
    'product_lens',
    'Global notification',
    'products',
    '10000000-0000-0000-0000-000000000001',
    'unread',
    '{"safe":true}'::jsonb
  );

insert into evaluation_cases (
  id,
  workspace_id,
  product_id,
  case_type,
  provider_name,
  status,
  opened_at,
  total_evaluation_cost,
  created_by
) values
  (
    'e1000000-0000-0000-0000-000000000001',
    '30000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001',
    'grading',
    'Demo Grader',
    'draft',
    now(),
    15,
    '00000000-0000-0000-0000-0000000000a1'
  ),
  (
    'e1000000-0000-0000-0000-000000000002',
    '30000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000002',
    'authentication',
    'Demo Authenticator',
    'draft',
    now(),
    25,
    '00000000-0000-0000-0000-0000000000a1'
  );

set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000a1';

select pg_temp.satera_assert(
  is_category_in_product(
    '20000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001'
  ),
  'Card Vertex product category mapping includes sports cards.'
);

select pg_temp.satera_assert(
  not is_category_in_product(
    '20000000-0000-0000-0000-000000000002',
    '10000000-0000-0000-0000-000000000001'
  ),
  'Card Vertex product category mapping excludes comics.'
);

select pg_temp.satera_assert(
  can_access_product('10000000-0000-0000-0000-000000000001'),
  'Authenticated user can access active Card Vertex product lens context.'
);

select pg_temp.satera_assert(
  inventory_item_belongs_to_product(
    '71000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001'
  ),
  'Helper confirms workspace card inventory belongs to Card Vertex.'
);

select pg_temp.satera_assert(
  not inventory_item_belongs_to_product(
    '71000000-0000-0000-0000-000000000002',
    '10000000-0000-0000-0000-000000000001'
  ),
  'Helper confirms workspace comic inventory does not belong to Card Vertex.'
);

select pg_temp.satera_assert(
  (
    select count(*) = 1
    from inventory_items ii
    join product_categories pc on pc.category_id = ii.category_id
    where pc.product_id = '10000000-0000-0000-0000-000000000001'
      and ii.workspace_id = '30000000-0000-0000-0000-000000000001'
  ),
  'Product lens inventory returns only workspace items mapped to the requested product.'
);

select pg_temp.satera_assert(
  (
    select count(*) = 0
    from inventory_items ii
    join product_categories pc on pc.category_id = ii.category_id
    where pc.product_id = '10000000-0000-0000-0000-000000000001'
      and ii.owner_user_id = '00000000-0000-0000-0000-0000000000b2'
  ),
  'Product lens inventory does not return another user private inventory.'
);

select pg_temp.satera_assert(
  (
    select count(*) = 1
    from public_object_references
    where product_id = '10000000-0000-0000-0000-000000000001'
      and exposure_state = 'active'
      and visibility = 'community'
      and public_metadata ? 'safe'
      and not public_metadata ? 'true_basis'
  ),
  'Public object references are product-scoped and expose safe metadata only.'
);

select pg_temp.satera_assert(
  (
    select count(*) = 1
    from communities
    where product_id = '10000000-0000-0000-0000-000000000001'
  ),
  'Product-scoped communities can be filtered to Card Vertex without cross-product leakage.'
);

select pg_temp.satera_assert(
  (
    select count(*) = 1
    from notifications
    where product_id = '10000000-0000-0000-0000-000000000001'
      and recipient_user_id = auth.uid()
      and status = 'unread'
  ),
  'Product-scoped notifications can be filtered by product and current recipient.'
);

select pg_temp.satera_assert(
  (
    select count(*) = 1
    from notifications
    where product_id is null
      and recipient_user_id = auth.uid()
      and status = 'unread'
  ),
  'Global notifications remain explicit product_id null records.'
);

select pg_temp.satera_assert(
  (
    select count(*) = 1
    from evaluation_cases
    where product_id = '10000000-0000-0000-0000-000000000001'
      and workspace_id = '30000000-0000-0000-0000-000000000001'
  ),
  'Product-scoped evaluation cases can be filtered by product and workspace.'
);

select pg_temp.satera_assert(
  (
    select jsonb_build_object(
      'inventory_count', (
        select count(*)
        from inventory_items ii
        join product_categories pc on pc.category_id = ii.category_id
        where pc.product_id = '10000000-0000-0000-0000-000000000001'
          and ii.workspace_id = '30000000-0000-0000-0000-000000000001'
      ),
      'public_reference_count', (
        select count(*)
        from public_object_references
        where product_id = '10000000-0000-0000-0000-000000000001'
      ),
      'community_count', (
        select count(*)
        from communities
        where product_id = '10000000-0000-0000-0000-000000000001'
      ),
      'unread_notification_count', (
        select count(*)
        from notifications
        where product_id = '10000000-0000-0000-0000-000000000001'
          and recipient_user_id = auth.uid()
          and status = 'unread'
      ),
      'evaluation_case_count', (
        select count(*)
        from evaluation_cases
        where product_id = '10000000-0000-0000-0000-000000000001'
          and workspace_id = '30000000-0000-0000-0000-000000000001'
      )
    ) = '{"inventory_count":1,"public_reference_count":1,"community_count":1,"unread_notification_count":1,"evaluation_case_count":1}'::jsonb
  ),
  'Product lens summary-style counts include only requested product data.'
);

do $$
begin
  insert into communities (
    product_id,
    owner_user_id,
    name,
    slug,
    visibility,
    created_by
  ) values (
    '10000000-0000-0000-0000-000000000001',
    auth.uid(),
    'Blocked Direct Community',
    'blocked-direct-community',
    'public',
    auth.uid()
  );

  raise exception 'direct community insert unexpectedly succeeded';
exception
  when insufficient_privilege then
    raise notice 'ok: Direct writes remain blocked for community tables.';
end;
$$;

reset role;
set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000b2';

select pg_temp.satera_assert(
  can_access_product('10000000-0000-0000-0000-000000000001'),
  'Product profile or active product availability can grant product lens access.'
);

select pg_temp.satera_assert(
  has_account_entitlement(auth.uid(), 'cross_vertex_portfolio'),
  'User B has a product-relevant entitlement fixture.'
);

select pg_temp.satera_assert(
  (
    select count(*) = 0
    from inventory_items ii
    join product_categories pc on pc.category_id = ii.category_id
    where pc.product_id = '10000000-0000-0000-0000-000000000001'
      and ii.owner_user_id = '00000000-0000-0000-0000-0000000000a1'
  ),
  'Product entitlement does not override another user private inventory privacy.'
);

select pg_temp.satera_assert(
  (
    select count(*) = 1
    from notifications
    where product_id = '10000000-0000-0000-0000-000000000001'
      and recipient_user_id = auth.uid()
  ),
  'Product-scoped notifications do not leak across recipients.'
);

select pg_temp.satera_assert(
  (
    select count(*) = 0
    from evaluation_cases
    where product_id = '10000000-0000-0000-0000-000000000001'
      and workspace_id = '30000000-0000-0000-0000-000000000001'
  ),
  'Evaluation cases remain workspace-scoped even when product-filtered.'
);

rollback;
