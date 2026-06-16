-- Verifies Satera Community Core MVP backend infrastructure without building
-- product-specific community UI.

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

create temp table community_core_results (
  label text primary key,
  entity_id uuid not null
) on commit drop;

insert into community_core_results
select
  'private_community',
  create_community(
    p_product_id => '10000000-0000-0000-0000-000000000001',
    p_owner_user_id => '00000000-0000-0000-0000-0000000000a1',
    p_name => 'SQL Private Collector Group',
    p_slug => 'sql-private-collector-group',
    p_description => 'Private SQL verification community',
    p_community_type => 'collector_group',
    p_visibility => 'private'
  );

select pg_temp.satera_assert(
  (
    select product_id = '10000000-0000-0000-0000-000000000001'
      and owner_user_id = auth.uid()
      and organization_id is null
      and workspace_id is null
      and visibility = 'private'
      and status = 'active'
    from communities
    where id = (
      select entity_id from community_core_results where label = 'private_community'
    )
  ),
  'a user can create a private product-scoped community for their own owner_user context.'
);

select pg_temp.satera_assert(
  (
    select role = 'owner' and status = 'active' and product_id = '10000000-0000-0000-0000-000000000001'
    from community_memberships
    where community_id = (
      select entity_id from community_core_results where label = 'private_community'
    )
      and user_id = auth.uid()
  ),
  'the creator receives an active owner membership.'
);

insert into community_core_results
select
  'private_channel',
  create_community_channel(
    p_community_id => (
      select entity_id from community_core_results where label = 'private_community'
    ),
    p_name => 'General',
    p_slug => 'general',
    p_description => 'General community channel',
    p_channel_type => 'conversation',
    p_visibility => 'community'
  );

select pg_temp.satera_assert(
  (
    select community_id = (
        select entity_id from community_core_results where label = 'private_community'
      )
      and product_id = '10000000-0000-0000-0000-000000000001'
      and slug = 'general'
    from community_channels
    where id = (
      select entity_id from community_core_results where label = 'private_channel'
    )
  ),
  'a community owner/admin can create a product-matched channel.'
);

insert into community_core_results
select
  'message_reference',
  create_public_object_reference(
    p_inventory_item_id => '70000000-0000-0000-0000-000000000001',
    p_product_id => '10000000-0000-0000-0000-000000000001',
    p_visibility => 'community',
    p_created_for => 'community_core_sql_verification',
    p_display_title => 'Community-safe demo reference',
    p_display_subtitle => 'Safe public card context',
    p_display_label => 'Discussion object',
    p_value_label => 'Safe market signal',
    p_public_metadata => '{"safe_context":"message attachment"}'::jsonb
  );

insert into community_core_results
select
  'private_message',
  create_community_message(
    p_channel_id => (
      select entity_id from community_core_results where label = 'private_channel'
    ),
    p_body => 'Sharing a safe public reference.',
    p_message_type => 'message',
    p_public_object_reference_ids => array[
      (select entity_id from community_core_results where label = 'message_reference')
    ]::uuid[]
  );

select pg_temp.satera_assert(
  (
    select author_user_id = auth.uid()
      and product_id = '10000000-0000-0000-0000-000000000001'
      and status = 'active'
      and body = 'Sharing a safe public reference.'
    from community_messages
    where id = (
      select entity_id from community_core_results where label = 'private_message'
    )
  ),
  'an active community member can create a message through RPC.'
);

select pg_temp.satera_assert(
  (
    select count(*) = 1
    from community_message_references
    where message_id = (
      select entity_id from community_core_results where label = 'private_message'
    )
      and public_object_reference_id = (
        select entity_id from community_core_results where label = 'message_reference'
      )
  ),
  'a message can attach a safe public_object_reference.'
);

select pg_temp.satera_assert(
  (
    select display_snapshot ? 'display_title'
      and display_snapshot ->> 'display_title' = 'Community-safe demo reference'
      and not (display_snapshot ?| array[
        'true_basis',
        'purchase_price',
        'profit',
        'location',
        'private_notes',
        'private_tags'
      ])
    from community_message_references
    where message_id = (
      select entity_id from community_core_results where label = 'private_message'
    )
  ),
  'message reference display_snapshot excludes private inventory fields.'
);

set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000b2';

select pg_temp.satera_assert(
  (
    select count(*) = 0
    from community_messages
    where id = (
      select entity_id from community_core_results where label = 'private_message'
    )
  ),
  'a non-member cannot read private community messages.'
);

select pg_temp.satera_assert(
  not has_table_privilege('community_messages', 'INSERT')
    and not has_table_privilege('community_messages', 'UPDATE')
    and not has_table_privilege('community_messages', 'DELETE')
    and has_table_privilege('community_messages', 'SELECT'),
  'authenticated direct community_messages writes are revoked while select remains available.'
);

select pg_temp.satera_expect_insufficient_privilege(
  $sql$
    insert into community_messages (
      community_id,
      channel_id,
      product_id,
      author_user_id,
      body
    ) values (
      '00000000-0000-0000-0000-000000000001',
      '00000000-0000-0000-0000-000000000002',
      '10000000-0000-0000-0000-000000000001',
      auth.uid(),
      'unsafe direct insert'
    )
  $sql$,
  'authenticated user cannot directly insert community_messages.'
);

select pg_temp.satera_expect_insufficient_privilege(
  $sql$
    update community_messages set body = 'unsafe direct update'
  $sql$,
  'authenticated user cannot directly update community_messages.'
);

select pg_temp.satera_expect_insufficient_privilege(
  $sql$
    delete from community_messages
  $sql$,
  'authenticated user cannot directly delete community_messages.'
);

set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000a1';

insert into community_core_results
select
  'public_community',
  create_community(
    p_product_id => '10000000-0000-0000-0000-000000000001',
    p_owner_user_id => '00000000-0000-0000-0000-0000000000a1',
    p_name => 'SQL Public Collector Group',
    p_slug => 'sql-public-collector-group',
    p_community_type => 'collector_group',
    p_visibility => 'product_visible'
  );

insert into community_core_results
select
  'public_channel',
  create_community_channel(
    p_community_id => (
      select entity_id from community_core_results where label = 'public_community'
    ),
    p_name => 'Public General',
    p_slug => 'public-general',
    p_channel_type => 'conversation',
    p_visibility => 'community'
  );

set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000b2';

select pg_temp.satera_assert(
  (
    select count(*) = 1
    from communities
    where id = (
      select entity_id from community_core_results where label = 'public_community'
    )
  ),
  'an authenticated user can discover/read an active product_visible community.'
);

insert into community_core_results
select
  'public_membership_user_b',
  join_community(
    p_community_id => (
      select entity_id from community_core_results where label = 'public_community'
    )
  );

insert into community_core_results
select
  'public_message_user_b',
  create_community_message(
    p_channel_id => (
      select entity_id from community_core_results where label = 'public_channel'
    ),
    p_body => 'Visible product-scoped community message.'
  );

insert into community_core_results
select
  'public_report',
  report_community_content(
    p_product_id => '10000000-0000-0000-0000-000000000001',
    p_community_id => (
      select entity_id from community_core_results where label = 'public_community'
    ),
    p_channel_id => (
      select entity_id from community_core_results where label = 'public_channel'
    ),
    p_message_id => (
      select entity_id from community_core_results where label = 'public_message_user_b'
    ),
    p_reported_entity_table => 'community_messages',
    p_reported_entity_id => (
      select entity_id from community_core_results where label = 'public_message_user_b'
    ),
    p_reason => 'sql verification report',
    p_details => 'Visible content can be reported.'
  );

select pg_temp.satera_assert(
  (
    select reported_by = auth.uid()
      and status = 'open'
    from moderation_reports
    where id = (
      select entity_id from community_core_results where label = 'public_report'
    )
  ),
  'a user can report visible community content.'
);

set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000a1';

insert into community_core_results
select
  'moderation_action',
  moderate_community_content(
    p_report_id => (
      select entity_id from community_core_results where label = 'public_report'
    ),
    p_product_id => '10000000-0000-0000-0000-000000000001',
    p_community_id => (
      select entity_id from community_core_results where label = 'public_community'
    ),
    p_channel_id => (
      select entity_id from community_core_results where label = 'public_channel'
    ),
    p_message_id => (
      select entity_id from community_core_results where label = 'public_message_user_b'
    ),
    p_target_entity_table => 'community_messages',
    p_target_entity_id => (
      select entity_id from community_core_results where label = 'public_message_user_b'
    ),
    p_action_type => 'hide',
    p_reason => 'sql verification moderation'
  );

select pg_temp.satera_assert(
  (
    select action_type = 'hide'
    from moderation_actions
    where id = (
      select entity_id from community_core_results where label = 'moderation_action'
    )
  )
  and (
    select status = 'hidden'
    from community_messages
    where id = (
      select entity_id from community_core_results where label = 'public_message_user_b'
    )
  )
  and (
    select status = 'resolved'
    from moderation_reports
    where id = (
      select entity_id from community_core_results where label = 'public_report'
    )
  ),
  'a community owner/admin can moderate reported content and hide the target message.'
);

select pg_temp.satera_assert(
  (
    select count(*) = 1
    from community_messages
    where id = (
      select entity_id from community_core_results where label = 'public_message_user_b'
    )
  ),
  'hidden messages remain visible to community moderators/admins.'
);

set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000b2';

select pg_temp.satera_assert(
  (
    select count(*) = 0
    from community_messages
    where id = (
      select entity_id from community_core_results where label = 'public_message_user_b'
    )
  ),
  'hidden messages are not visible to normal members.'
);

set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000a1';

select pg_temp.satera_assert(
  (
    select count(*) >= 5
    from audit_events
    where event_type in (
      'community_created',
      'community_channel_created',
      'community_message_created',
      'community_content_reported',
      'community_content_moderated'
    )
      and product_id = '10000000-0000-0000-0000-000000000001'
  ),
  'audit events are written for create community, create channel, create message, report, and moderate actions.'
);

rollback;
