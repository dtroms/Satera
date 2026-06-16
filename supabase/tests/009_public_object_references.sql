-- Verifies safe public object references expose intentional display records
-- without exposing private inventory fields or allowing direct writes.

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

create or replace function pg_temp.satera_expect_insufficient_privilege(
  statement text,
  message text
)
returns void
language plpgsql
as $$
begin
  begin
    execute statement;
  exception
    when insufficient_privilege then
      raise notice 'ok: %', message;
      return;
  end;

  raise exception 'verification failed: %', message;
end;
$$;

create temp table public_reference_results (
  label text primary key,
  public_object_reference_id uuid not null
) on commit drop;

insert into public_reference_results
select
  'owner_community_reference',
  create_public_object_reference(
    p_inventory_item_id => '70000000-0000-0000-0000-000000000001',
    p_product_id => '10000000-0000-0000-0000-000000000001',
    p_visibility => 'community',
    p_created_for => 'sql_verification',
    p_display_title => 'Safe demo card reference',
    p_display_subtitle => 'Public display subtitle',
    p_display_label => 'Trade candidate',
    p_condition_label => 'Raw',
    p_value_label => 'Market signal only',
    p_public_metadata => '{"safe_context":"community attachment"}'::jsonb
  );

select pg_temp.satera_assert(
  (
    select owner_user_id = auth.uid()
      and inventory_item_id = '70000000-0000-0000-0000-000000000001'
      and product_id = '10000000-0000-0000-0000-000000000001'
      and category_id = '20000000-0000-0000-0000-000000000001'
      and asset_family_id = '50000000-0000-0000-0000-000000000001'
      and asset_variant_id = '60000000-0000-0000-0000-000000000001'
      and object_type = 'sports_cards'
      and display_title = 'Safe demo card reference'
      and display_subtitle = 'Public display subtitle'
      and display_label = 'Trade candidate'
      and condition_label = 'Raw'
      and value_label = 'Market signal only'
      and visibility = 'community'
      and exposure_state = 'active'
      and created_for = 'sql_verification'
      and created_from = 'inventory_item'
    from public_object_references
    where id = (
      select public_object_reference_id
      from public_reference_results
      where label = 'owner_community_reference'
    )
  ),
  'owner can create a safe public object reference from their inventory item through RPC.'
);

select pg_temp.satera_assert(
  not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'public_object_references'
      and column_name in (
        'true_basis',
        'purchase_price',
        'profit',
        'location',
        'private_notes'
      )
  ),
  'public_object_references has no private inventory or financial columns.'
);

select pg_temp.satera_expect_rejected(
  $sql$
    select create_public_object_reference(
      p_inventory_item_id => '70000000-0000-0000-0000-000000000001',
      p_product_id => '10000000-0000-0000-0000-000000000001',
      p_public_metadata => '{"true_basis":100}'::jsonb
    )
  $sql$,
  'public metadata cannot contain private basis fields.'
);

set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000b2';

select pg_temp.satera_expect_rejected(
  $sql$
    select create_public_object_reference(
      p_inventory_item_id => '70000000-0000-0000-0000-000000000001',
      p_product_id => '10000000-0000-0000-0000-000000000001',
      p_visibility => 'community'
    )
  $sql$,
  'another authenticated user cannot create a reference from someone else''s private inventory item.'
);

select pg_temp.satera_assert(
  (
    select count(*) = 1
    from public_object_references
    where id = (
      select public_object_reference_id
      from public_reference_results
      where label = 'owner_community_reference'
    )
      and display_title = 'Safe demo card reference'
  ),
  'active community references are readable as safe reference records by authenticated users.'
);

select pg_temp.satera_assert(
  not has_table_privilege('public_object_references', 'INSERT')
    and not has_table_privilege('public_object_references', 'UPDATE')
    and not has_table_privilege('public_object_references', 'DELETE')
    and has_table_privilege('public_object_references', 'SELECT'),
  'authenticated direct public_object_references writes are revoked while select remains available.'
);

select pg_temp.satera_expect_insufficient_privilege(
  $sql$
    insert into public_object_references (
      owner_user_id,
      product_id,
      object_type,
      display_title
    ) values (
      auth.uid(),
      '10000000-0000-0000-0000-000000000001',
      'sports_cards',
      'Unsafe direct insert'
    )
  $sql$,
  'authenticated user cannot directly insert public_object_references.'
);

select pg_temp.satera_expect_insufficient_privilege(
  $sql$
    update public_object_references
    set display_title = 'Unsafe direct update'
  $sql$,
  'authenticated user cannot directly update public_object_references.'
);

select pg_temp.satera_expect_insufficient_privilege(
  $sql$
    delete from public_object_references
  $sql$,
  'authenticated user cannot directly delete public_object_references.'
);

set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000a1';

select update_public_object_reference_display(
  p_public_object_reference_id => (
    select public_object_reference_id
    from public_reference_results
    where label = 'owner_community_reference'
  ),
  p_display_title => 'Updated safe title',
  p_display_label => 'Updated safe label',
  p_public_metadata => '{"safe_context":"updated display"}'::jsonb
);

select pg_temp.satera_assert(
  (
    select display_title = 'Updated safe title'
      and display_label = 'Updated safe label'
      and public_metadata = '{"safe_context":"updated display"}'::jsonb
    from public_object_references
    where id = (
      select public_object_reference_id
      from public_reference_results
      where label = 'owner_community_reference'
    )
  )
  and (
    select notes = 'Demo user-owned sports card item with missing basis.'
    from inventory_items
    where id = '70000000-0000-0000-0000-000000000001'
  ),
  'update_public_object_reference_display updates only safe display fields and does not mutate inventory private fields.'
);

select pg_temp.satera_expect_rejected(
  $sql$
    select update_public_object_reference_display(
      p_public_object_reference_id => (
        select public_object_reference_id
        from public_reference_results
        where label = 'owner_community_reference'
      ),
      p_public_metadata => '{"location":"Vault A"}'::jsonb
    )
  $sql$,
  'display update rejects private location metadata.'
);

select revoke_public_object_reference(
  p_public_object_reference_id => (
    select public_object_reference_id
    from public_reference_results
    where label = 'owner_community_reference'
  ),
  p_reason => 'sql verification'
);

select pg_temp.satera_assert(
  (
    select exposure_state = 'revoked'
    from public_object_references
    where id = (
      select public_object_reference_id
      from public_reference_results
      where label = 'owner_community_reference'
    )
  ),
  'revoke_public_object_reference changes exposure_state to revoked.'
);

select pg_temp.satera_assert(
  (
    select count(*) >= 3
    from audit_events
    where entity_table = 'public_object_references'
      and entity_id = (
        select public_object_reference_id
        from public_reference_results
        where label = 'owner_community_reference'
      )
      and event_type in (
        'public_object_reference_created',
        'public_object_reference_display_updated',
        'public_object_reference_revoked'
      )
  ),
  'creating, updating, and revoking public object references writes audit events.'
);

set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000b2';

select pg_temp.satera_assert(
  (
    select count(*) = 0
    from public_object_references
    where id = (
      select public_object_reference_id
      from public_reference_results
      where label = 'owner_community_reference'
    )
  ),
  'revoked references are not readable through product/public visibility policy.'
);

rollback;
