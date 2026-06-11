-- Local development seed data for Satera Core foundation verification.
-- All assets are generic demo placeholders and are not real collectible identities.

insert into auth.users (
  id,
  instance_id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at
) values
  (
    '00000000-0000-0000-0000-0000000000a1',
    '00000000-0000-0000-0000-000000000000',
    'authenticated',
    'authenticated',
    'demo-user-a@satera.local',
    crypt('password', gen_salt('bf')),
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"name":"Demo User A"}'::jsonb,
    now(),
    now()
  ),
  (
    '00000000-0000-0000-0000-0000000000b2',
    '00000000-0000-0000-0000-000000000000',
    'authenticated',
    'authenticated',
    'demo-user-b@satera.local',
    crypt('password', gen_salt('bf')),
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"name":"Demo User B"}'::jsonb,
    now(),
    now()
  )
on conflict (id) do update
set
  email = excluded.email,
  updated_at = now();

insert into products (id, slug, name, product_type, status) values
  ('10000000-0000-0000-0000-000000000001', 'card_vertex', 'Card Vertex', 'vertical', 'active'),
  ('10000000-0000-0000-0000-000000000002', 'vertex_pro', 'Vertex Pro', 'pro_console', 'active'),
  ('10000000-0000-0000-0000-000000000003', 'satera_portfolio', 'Satera Portfolio', 'portfolio', 'active')
on conflict (id) do update
set
  slug = excluded.slug,
  name = excluded.name,
  product_type = excluded.product_type,
  status = excluded.status;

insert into categories (id, slug, name, description) values
  ('20000000-0000-0000-0000-000000000001', 'sports_cards', 'Sports Cards', 'Demo category for sports card assets.'),
  ('20000000-0000-0000-0000-000000000002', 'comics', 'Comics', 'Demo category for comic assets.'),
  ('20000000-0000-0000-0000-000000000003', 'watches', 'Watches', 'Demo category for watch assets.'),
  ('20000000-0000-0000-0000-000000000004', 'video_games', 'Video Games', 'Demo category for video game assets.')
on conflict (id) do update
set
  slug = excluded.slug,
  name = excluded.name,
  description = excluded.description;

insert into product_categories (product_id, category_id) values
  ('10000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001'),
  ('10000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000001'),
  ('10000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000002'),
  ('10000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000003'),
  ('10000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000004'),
  ('10000000-0000-0000-0000-000000000003', '20000000-0000-0000-0000-000000000001'),
  ('10000000-0000-0000-0000-000000000003', '20000000-0000-0000-0000-000000000002'),
  ('10000000-0000-0000-0000-000000000003', '20000000-0000-0000-0000-000000000003'),
  ('10000000-0000-0000-0000-000000000003', '20000000-0000-0000-0000-000000000004')
on conflict (product_id, category_id) do nothing;

insert into workspaces (id, name, owner_user_id) values
  ('30000000-0000-0000-0000-000000000001', 'Demo Workspace', '00000000-0000-0000-0000-0000000000a1')
on conflict (id) do update
set
  name = excluded.name,
  owner_user_id = excluded.owner_user_id;

insert into workspace_members (workspace_id, user_id, role) values
  ('30000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-0000000000a1', 'owner')
on conflict (workspace_id, user_id) do update
set role = excluded.role;

insert into organizations (id, name, owner_user_id) values
  ('40000000-0000-0000-0000-000000000001', 'Demo Organization', '00000000-0000-0000-0000-0000000000a1')
on conflict (id) do update
set
  name = excluded.name,
  owner_user_id = excluded.owner_user_id;

insert into organization_memberships (organization_id, user_id, role) values
  ('40000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-0000000000a1', 'owner')
on conflict (organization_id, user_id) do update
set role = excluded.role;

insert into account_entitlements (user_id, entitlement_key) values
  ('00000000-0000-0000-0000-0000000000a1', 'cross_vertex_portfolio')
on conflict (user_id, entitlement_key) do nothing;

insert into organization_entitlements (organization_id, entitlement_key) values
  ('40000000-0000-0000-0000-000000000001', 'vertex_pro'),
  ('40000000-0000-0000-0000-000000000001', 'cross_vertex_inventory')
on conflict (organization_id, entitlement_key) do nothing;

insert into asset_families (id, category_id, name, canonical_key, attributes) values
  ('50000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', 'Demo Sports Card Family', 'demo-sports-card-family', '{"demo":true}'::jsonb),
  ('50000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000002', 'Demo Comic Family', 'demo-comic-family', '{"demo":true}'::jsonb),
  ('50000000-0000-0000-0000-000000000003', '20000000-0000-0000-0000-000000000003', 'Demo Watch Family', 'demo-watch-family', '{"demo":true}'::jsonb),
  ('50000000-0000-0000-0000-000000000004', '20000000-0000-0000-0000-000000000004', 'Demo Video Game Family', 'demo-video-game-family', '{"demo":true}'::jsonb)
on conflict (id) do update
set
  category_id = excluded.category_id,
  name = excluded.name,
  canonical_key = excluded.canonical_key,
  attributes = excluded.attributes;

insert into asset_variants (id, asset_family_id, category_id, name, variant_key, attributes) values
  ('60000000-0000-0000-0000-000000000001', '50000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', 'Demo Sports Card Variant', 'demo-sports-card-variant', '{"demo":true}'::jsonb),
  ('60000000-0000-0000-0000-000000000002', '50000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000002', 'Demo Comic Variant', 'demo-comic-variant', '{"demo":true}'::jsonb),
  ('60000000-0000-0000-0000-000000000003', '50000000-0000-0000-0000-000000000003', '20000000-0000-0000-0000-000000000003', 'Demo Watch Variant', 'demo-watch-variant', '{"demo":true}'::jsonb),
  ('60000000-0000-0000-0000-000000000004', '50000000-0000-0000-0000-000000000004', '20000000-0000-0000-0000-000000000004', 'Demo Video Game Variant', 'demo-video-game-variant', '{"demo":true}'::jsonb)
on conflict (id) do update
set
  asset_family_id = excluded.asset_family_id,
  category_id = excluded.category_id,
  name = excluded.name,
  variant_key = excluded.variant_key,
  attributes = excluded.attributes;

insert into product_profiles (id, user_id, product_id, display_name, handle, profile_data) values
  ('90000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-0000000000b2', '10000000-0000-0000-0000-000000000001', 'Demo User B Card Vertex Profile', 'demo-user-b-cards', '{"demo":true}'::jsonb)
on conflict (id) do update
set
  user_id = excluded.user_id,
  product_id = excluded.product_id,
  display_name = excluded.display_name,
  handle = excluded.handle,
  profile_data = excluded.profile_data;

insert into organization_product_profiles (id, organization_id, product_id, display_name, handle, profile_data) values
  ('90000000-0000-0000-0000-000000000002', '40000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'Demo Organization Card Vertex Profile', 'demo-org-cards', '{"demo":true}'::jsonb)
on conflict (id) do update
set
  organization_id = excluded.organization_id,
  product_id = excluded.product_id,
  display_name = excluded.display_name,
  handle = excluded.handle,
  profile_data = excluded.profile_data;

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
    '70000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-0000000000a1',
    '20000000-0000-0000-0000-000000000001',
    '60000000-0000-0000-0000-000000000001',
    'raw',
    'active',
    'available',
    'hold',
    null,
    now(),
    'Demo user-owned sports card item with missing basis.',
    '00000000-0000-0000-0000-0000000000a1',
    '00000000-0000-0000-0000-0000000000a1'
  ),
  (
    '70000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-0000000000a1',
    '20000000-0000-0000-0000-000000000002',
    '60000000-0000-0000-0000-000000000002',
    'raw',
    'active',
    'available',
    'hold',
    0,
    now(),
    'Demo user-owned comic item with known zero basis.',
    '00000000-0000-0000-0000-0000000000a1',
    '00000000-0000-0000-0000-0000000000a1'
  ),
  (
    '70000000-0000-0000-0000-000000000003',
    '00000000-0000-0000-0000-0000000000b2',
    '20000000-0000-0000-0000-000000000004',
    '60000000-0000-0000-0000-000000000004',
    'sealed',
    'active',
    'available',
    'hold',
    25,
    now(),
    'Demo user B private video game item.',
    '00000000-0000-0000-0000-0000000000b2',
    '00000000-0000-0000-0000-0000000000b2'
  )
on conflict (id) do update
set
  owner_user_id = excluded.owner_user_id,
  workspace_id = null,
  organization_id = null,
  category_id = excluded.category_id,
  asset_variant_id = excluded.asset_variant_id,
  condition_type = excluded.condition_type,
  status = excluded.status,
  availability = excluded.availability,
  intent = excluded.intent,
  true_basis = excluded.true_basis,
  notes = excluded.notes,
  updated_by = excluded.updated_by;

insert into inventory_items (
  id,
  organization_id,
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
) values (
  '70000000-0000-0000-0000-000000000004',
  '40000000-0000-0000-0000-000000000001',
  '20000000-0000-0000-0000-000000000003',
  '60000000-0000-0000-0000-000000000003',
  'authenticated',
  'active',
  'available',
  'sell',
  500,
  now(),
  'Demo organization-owned watch item.',
  '00000000-0000-0000-0000-0000000000a1',
  '00000000-0000-0000-0000-0000000000a1'
)
on conflict (id) do update
set
  owner_user_id = null,
  workspace_id = null,
  organization_id = excluded.organization_id,
  category_id = excluded.category_id,
  asset_variant_id = excluded.asset_variant_id,
  condition_type = excluded.condition_type,
  status = excluded.status,
  availability = excluded.availability,
  intent = excluded.intent,
  true_basis = excluded.true_basis,
  notes = excluded.notes,
  updated_by = excluded.updated_by;

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
  '80000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-0000000000a1',
  '20000000-0000-0000-0000-000000000002',
  '50000000-0000-0000-0000-000000000002',
  '60000000-0000-0000-0000-000000000002',
  '70000000-0000-0000-0000-000000000002',
  'manual_demo',
  75,
  'USD',
  'manual',
  1,
  'raw demo condition',
  '{"demo":true}'::jsonb,
  '00000000-0000-0000-0000-0000000000a1'
)
on conflict (id) do update
set
  owner_user_id = excluded.owner_user_id,
  category_id = excluded.category_id,
  asset_family_id = excluded.asset_family_id,
  asset_variant_id = excluded.asset_variant_id,
  inventory_item_id = excluded.inventory_item_id,
  source = excluded.source,
  market_value = excluded.market_value,
  currency_code = excluded.currency_code,
  method = excluded.method,
  number_of_comps = excluded.number_of_comps,
  condition_or_grade = excluded.condition_or_grade,
  snapshot_data = excluded.snapshot_data,
  created_by = excluded.created_by;

update inventory_items
set current_value_snapshot_id = '80000000-0000-0000-0000-000000000001'
where id = '70000000-0000-0000-0000-000000000002';
