-- Verifies durable Satera Core moderation enforcement, notes, appeals, RLS,
-- and RPC-only write paths without building product-facing moderation UI.

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

create temp table moderation_foundation_results (
  label text primary key,
  entity_id uuid not null
) on commit drop;

insert into moderation_foundation_results
select
  'community',
  create_community(
    p_product_id => '10000000-0000-0000-0000-000000000001',
    p_owner_user_id => '00000000-0000-0000-0000-0000000000a1',
    p_name => 'SQL Moderation Foundation Community',
    p_slug => 'sql-moderation-foundation-community',
    p_visibility => 'product_visible'
  );

insert into moderation_foundation_results
select
  'channel',
  create_community_channel(
    p_community_id => (
      select entity_id from moderation_foundation_results where label = 'community'
    ),
    p_name => 'Moderation General',
    p_slug => 'moderation-general'
  );

set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000b2';

insert into moderation_foundation_results
select
  'membership_b',
  join_community(
    p_community_id => (
      select entity_id from moderation_foundation_results where label = 'community'
    )
  );

insert into moderation_foundation_results
select
  'pre_restriction_message',
  create_community_message(
    p_channel_id => (
      select entity_id from moderation_foundation_results where label = 'channel'
    ),
    p_body => 'Active member can post before restriction.'
  );

select pg_temp.satera_assert(
  (
    select status = 'active'
    from community_messages
    where id = (
      select entity_id from moderation_foundation_results where label = 'pre_restriction_message'
    )
  ),
  'active member can post before restriction.'
);

set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000a1';

insert into moderation_foundation_results
select
  'mute_action',
  moderate_community_content(
    p_product_id => '10000000-0000-0000-0000-000000000001',
    p_community_id => (
      select entity_id from moderation_foundation_results where label = 'community'
    ),
    p_channel_id => (
      select entity_id from moderation_foundation_results where label = 'channel'
    ),
    p_message_id => (
      select entity_id from moderation_foundation_results where label = 'pre_restriction_message'
    ),
    p_target_entity_table => 'community_messages',
    p_target_entity_id => (
      select entity_id from moderation_foundation_results where label = 'pre_restriction_message'
    ),
    p_action_type => 'mute_user',
    p_reason => 'sql verification mute'
  );

insert into moderation_foundation_results
select 'mute_restriction', id
from user_restrictions
where metadata ->> 'moderation_action_id' = (
  select entity_id::text from moderation_foundation_results where label = 'mute_action'
);

select pg_temp.satera_assert(
  (
    select restriction_type = 'muted'
      and status = 'active'
      and user_id = '00000000-0000-0000-0000-0000000000b2'
    from user_restrictions
    where id = (
      select entity_id from moderation_foundation_results where label = 'mute_restriction'
    )
  ),
  'moderator can mute a user and create a durable user restriction.'
);

set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000b2';

select pg_temp.satera_expect_rejected(
  format(
    $sql$
      select create_community_message(
        p_channel_id => %L::uuid,
        p_body => 'Muted user should not post.'
      )
    $sql$,
    (select entity_id from moderation_foundation_results where label = 'channel')
  ),
  'muted user cannot post.'
);

set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000a1';

select lift_user_restriction(
  p_restriction_id => (
    select entity_id from moderation_foundation_results where label = 'mute_restriction'
  ),
  p_reason => 'sql verification lift'
);

select pg_temp.satera_assert(
  (
    select status = 'lifted'
      and lifted_by = auth.uid()
      and lifted_at is not null
    from user_restrictions
    where id = (
      select entity_id from moderation_foundation_results where label = 'mute_restriction'
    )
  ),
  'moderator can lift restriction.'
);

set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000b2';

insert into moderation_foundation_results
select
  'post_lift_message',
  create_community_message(
    p_channel_id => (
      select entity_id from moderation_foundation_results where label = 'channel'
    ),
    p_body => 'Lifted user can post again.'
  );

insert into moderation_foundation_results
select
  'remove_message',
  create_community_message(
    p_channel_id => (
      select entity_id from moderation_foundation_results where label = 'channel'
    ),
    p_body => 'Message for removal.'
  );

insert into moderation_foundation_results
select
  'delete_message',
  create_community_message(
    p_channel_id => (
      select entity_id from moderation_foundation_results where label = 'channel'
    ),
    p_body => 'Message for deletion.'
  );

insert into moderation_foundation_results
select
  'reportable_message',
  create_community_message(
    p_channel_id => (
      select entity_id from moderation_foundation_results where label = 'channel'
    ),
    p_body => 'Visible content can be reported.'
  );

select pg_temp.satera_assert(
  (
    select count(*) = 1
    from community_messages
    where id = (
      select entity_id from moderation_foundation_results where label = 'post_lift_message'
    )
  ),
  'lifted user can post again.'
);

set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000a1';

insert into moderation_foundation_results
select
  'hide_action',
  moderate_community_content(
    p_product_id => '10000000-0000-0000-0000-000000000001',
    p_community_id => (
      select entity_id from moderation_foundation_results where label = 'community'
    ),
    p_channel_id => (
      select entity_id from moderation_foundation_results where label = 'channel'
    ),
    p_message_id => (
      select entity_id from moderation_foundation_results where label = 'post_lift_message'
    ),
    p_target_entity_table => 'community_messages',
    p_target_entity_id => (
      select entity_id from moderation_foundation_results where label = 'post_lift_message'
    ),
    p_action_type => 'hide',
    p_reason => 'sql verification hide'
  );

insert into moderation_foundation_results
select
  'remove_action',
  moderate_community_content(
    p_product_id => '10000000-0000-0000-0000-000000000001',
    p_community_id => (
      select entity_id from moderation_foundation_results where label = 'community'
    ),
    p_channel_id => (
      select entity_id from moderation_foundation_results where label = 'channel'
    ),
    p_message_id => (
      select entity_id from moderation_foundation_results where label = 'remove_message'
    ),
    p_target_entity_table => 'community_messages',
    p_target_entity_id => (
      select entity_id from moderation_foundation_results where label = 'remove_message'
    ),
    p_action_type => 'remove',
    p_reason => 'sql verification remove'
  );

insert into moderation_foundation_results
select
  'delete_action',
  moderate_community_content(
    p_product_id => '10000000-0000-0000-0000-000000000001',
    p_community_id => (
      select entity_id from moderation_foundation_results where label = 'community'
    ),
    p_channel_id => (
      select entity_id from moderation_foundation_results where label = 'channel'
    ),
    p_message_id => (
      select entity_id from moderation_foundation_results where label = 'delete_message'
    ),
    p_target_entity_table => 'community_messages',
    p_target_entity_id => (
      select entity_id from moderation_foundation_results where label = 'delete_message'
    ),
    p_action_type => 'delete',
    p_reason => 'sql verification delete'
  );

select pg_temp.satera_assert(
  (
    select count(*) = 3
    from community_messages
    where id in (
      (select entity_id from moderation_foundation_results where label = 'post_lift_message'),
      (select entity_id from moderation_foundation_results where label = 'remove_message'),
      (select entity_id from moderation_foundation_results where label = 'delete_message')
    )
      and status in ('hidden', 'removed', 'deleted')
  ),
  'moderator can hide/remove/delete messages.'
);

select pg_temp.satera_assert(
  (
    select count(*) = 3
    from community_messages
    where id in (
      (select entity_id from moderation_foundation_results where label = 'post_lift_message'),
      (select entity_id from moderation_foundation_results where label = 'remove_message'),
      (select entity_id from moderation_foundation_results where label = 'delete_message')
    )
  ),
  'moderator/admin can inspect hidden/removed/deleted messages.'
);

set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000b2';

select pg_temp.satera_assert(
  (
    select count(*) = 0
    from community_messages
    where id in (
      (select entity_id from moderation_foundation_results where label = 'post_lift_message'),
      (select entity_id from moderation_foundation_results where label = 'remove_message'),
      (select entity_id from moderation_foundation_results where label = 'delete_message')
    )
  ),
  'hidden/removed/deleted messages are not visible to normal members.'
);

insert into moderation_foundation_results
select
  'report_resolve',
  report_community_content(
    p_product_id => '10000000-0000-0000-0000-000000000001',
    p_community_id => (
      select entity_id from moderation_foundation_results where label = 'community'
    ),
    p_channel_id => (
      select entity_id from moderation_foundation_results where label = 'channel'
    ),
    p_message_id => (
      select entity_id from moderation_foundation_results where label = 'reportable_message'
    ),
    p_reported_entity_table => 'community_messages',
    p_reported_entity_id => (
      select entity_id from moderation_foundation_results where label = 'reportable_message'
    ),
    p_reason => 'visible content report'
  );

select pg_temp.satera_assert(
  (
    select status = 'open'
    from moderation_reports
    where id = (
      select entity_id from moderation_foundation_results where label = 'report_resolve'
    )
  ),
  'user can report visible content.'
);

insert into moderation_foundation_results
select
  'report_escalate',
  report_community_content(
    p_product_id => '10000000-0000-0000-0000-000000000001',
    p_community_id => (
      select entity_id from moderation_foundation_results where label = 'community'
    ),
    p_channel_id => (
      select entity_id from moderation_foundation_results where label = 'channel'
    ),
    p_message_id => (
      select entity_id from moderation_foundation_results where label = 'reportable_message'
    ),
    p_reported_entity_table => 'community_messages',
    p_reported_entity_id => (
      select entity_id from moderation_foundation_results where label = 'reportable_message'
    ),
    p_reason => 'escalate content report'
  );

insert into moderation_foundation_results
select
  'report_allow',
  report_community_content(
    p_product_id => '10000000-0000-0000-0000-000000000001',
    p_community_id => (
      select entity_id from moderation_foundation_results where label = 'community'
    ),
    p_channel_id => (
      select entity_id from moderation_foundation_results where label = 'channel'
    ),
    p_message_id => (
      select entity_id from moderation_foundation_results where label = 'reportable_message'
    ),
    p_reported_entity_table => 'community_messages',
    p_reported_entity_id => (
      select entity_id from moderation_foundation_results where label = 'reportable_message'
    ),
    p_reason => 'allow content report'
  );

set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000a1';

select moderate_community_content(
  p_report_id => (
    select entity_id from moderation_foundation_results where label = 'report_resolve'
  ),
  p_product_id => '10000000-0000-0000-0000-000000000001',
  p_community_id => (
    select entity_id from moderation_foundation_results where label = 'community'
  ),
  p_channel_id => (
    select entity_id from moderation_foundation_results where label = 'channel'
  ),
  p_message_id => (
    select entity_id from moderation_foundation_results where label = 'reportable_message'
  ),
  p_target_entity_table => 'community_messages',
  p_target_entity_id => (
    select entity_id from moderation_foundation_results where label = 'reportable_message'
  ),
  p_action_type => 'mark_sensitive',
  p_reason => 'resolve report without product UI behavior'
);

select moderate_community_content(
  p_report_id => (
    select entity_id from moderation_foundation_results where label = 'report_escalate'
  ),
  p_product_id => '10000000-0000-0000-0000-000000000001',
  p_community_id => (
    select entity_id from moderation_foundation_results where label = 'community'
  ),
  p_channel_id => (
    select entity_id from moderation_foundation_results where label = 'channel'
  ),
  p_message_id => (
    select entity_id from moderation_foundation_results where label = 'reportable_message'
  ),
  p_target_entity_table => 'community_messages',
  p_target_entity_id => (
    select entity_id from moderation_foundation_results where label = 'reportable_message'
  ),
  p_action_type => 'escalate_to_admin',
  p_reason => 'escalate report'
);

select moderate_community_content(
  p_report_id => (
    select entity_id from moderation_foundation_results where label = 'report_allow'
  ),
  p_product_id => '10000000-0000-0000-0000-000000000001',
  p_community_id => (
    select entity_id from moderation_foundation_results where label = 'community'
  ),
  p_channel_id => (
    select entity_id from moderation_foundation_results where label = 'channel'
  ),
  p_message_id => (
    select entity_id from moderation_foundation_results where label = 'reportable_message'
  ),
  p_target_entity_table => 'community_messages',
  p_target_entity_id => (
    select entity_id from moderation_foundation_results where label = 'reportable_message'
  ),
  p_action_type => 'allow',
  p_reason => 'dismiss report'
);

select pg_temp.satera_assert(
  (
    select array_agg(status order by status) = array['dismissed', 'escalated', 'resolved']
    from moderation_reports
    where id in (
      (select entity_id from moderation_foundation_results where label = 'report_resolve'),
      (select entity_id from moderation_foundation_results where label = 'report_escalate'),
      (select entity_id from moderation_foundation_results where label = 'report_allow')
    )
  ),
  'moderator can resolve/escalate/dismiss report through moderate_community_content.'
);

select pg_temp.satera_assert(
  (
    select count(*) >= 1
    from audit_events
    where event_type = 'community_content_moderated'
      and entity_id = (
        select entity_id from moderation_foundation_results where label = 'hide_action'
      )
  ),
  'moderation action creates audit_event.'
);

select pg_temp.satera_assert(
  (
    select count(*) >= 1
    from audit_events
    where event_type = 'user_restriction_created'
      and entity_id = (
        select entity_id from moderation_foundation_results where label = 'mute_restriction'
      )
  ),
  'user restriction creates audit_event.'
);

insert into moderation_foundation_results
select
  'moderation_note',
  add_moderation_note(
    p_product_id => '10000000-0000-0000-0000-000000000001',
    p_community_id => (
      select entity_id from moderation_foundation_results where label = 'community'
    ),
    p_action_id => (
      select entity_id from moderation_foundation_results where label = 'hide_action'
    ),
    p_subject_user_id => '00000000-0000-0000-0000-0000000000b2',
    p_note => 'Internal moderation note for SQL verification.',
    p_visibility => 'moderators'
  );

select pg_temp.satera_assert(
  (
    select count(*) = 1
    from moderation_notes
    where id = (
      select entity_id from moderation_foundation_results where label = 'moderation_note'
    )
  ),
  'moderator can read moderation note.'
);

set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000b2';

select pg_temp.satera_assert(
  (
    select count(*) = 0
    from moderation_notes
    where id = (
      select entity_id from moderation_foundation_results where label = 'moderation_note'
    )
  ),
  'normal users cannot read internal moderation notes.'
);

insert into moderation_foundation_results
select
  'appeal',
  submit_moderation_appeal(
    p_product_id => '10000000-0000-0000-0000-000000000001',
    p_community_id => (
      select entity_id from moderation_foundation_results where label = 'community'
    ),
    p_action_id => (
      select entity_id from moderation_foundation_results where label = 'mute_action'
    ),
    p_restriction_id => (
      select entity_id from moderation_foundation_results where label = 'mute_restriction'
    ),
    p_reason => 'Appeal submitted by the restricted user.'
  );

select pg_temp.satera_assert(
  (
    select count(*) = 1
    from moderation_appeals
    where id = (
      select entity_id from moderation_foundation_results where label = 'appeal'
    )
      and submitted_by = auth.uid()
  ),
  'submit_moderation_appeal creates an appeal visible to submitter.'
);

set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000a1';

select pg_temp.satera_assert(
  (
    select count(*) = 1
    from moderation_appeals
    where id = (
      select entity_id from moderation_foundation_results where label = 'appeal'
    )
  ),
  'moderators/admins can read moderation appeals in scope.'
);

select pg_temp.satera_assert(
  not has_table_privilege('user_restrictions', 'INSERT')
    and not has_table_privilege('user_restrictions', 'UPDATE')
    and not has_table_privilege('user_restrictions', 'DELETE')
    and not has_table_privilege('moderation_notes', 'INSERT')
    and not has_table_privilege('moderation_notes', 'UPDATE')
    and not has_table_privilege('moderation_notes', 'DELETE')
    and not has_table_privilege('moderation_appeals', 'INSERT')
    and not has_table_privilege('moderation_appeals', 'UPDATE')
    and not has_table_privilege('moderation_appeals', 'DELETE'),
  'direct insert/update/delete grants are revoked for new moderation tables.'
);

select pg_temp.satera_expect_insufficient_privilege(
  $sql$
    insert into user_restrictions (
      product_id,
      user_id,
      restriction_type,
      created_by
    ) values (
      '10000000-0000-0000-0000-000000000001',
      auth.uid(),
      'muted',
      auth.uid()
    )
  $sql$,
  'authenticated user cannot directly insert user_restrictions.'
);

select pg_temp.satera_expect_insufficient_privilege(
  $sql$
    update user_restrictions set status = 'lifted'
  $sql$,
  'authenticated user cannot directly update user_restrictions.'
);

select pg_temp.satera_expect_insufficient_privilege(
  $sql$
    delete from user_restrictions
  $sql$,
  'authenticated user cannot directly delete user_restrictions.'
);

select pg_temp.satera_expect_insufficient_privilege(
  $sql$
    insert into moderation_notes (
      product_id,
      community_id,
      note,
      created_by
    ) values (
      '10000000-0000-0000-0000-000000000001',
      null,
      'unsafe direct note',
      auth.uid()
    )
  $sql$,
  'authenticated user cannot directly insert moderation_notes.'
);

select pg_temp.satera_expect_insufficient_privilege(
  $sql$
    update moderation_notes set note = 'unsafe direct update'
  $sql$,
  'authenticated user cannot directly update moderation_notes.'
);

select pg_temp.satera_expect_insufficient_privilege(
  $sql$
    delete from moderation_notes
  $sql$,
  'authenticated user cannot directly delete moderation_notes.'
);

select pg_temp.satera_expect_insufficient_privilege(
  $sql$
    insert into moderation_appeals (
      product_id,
      submitted_by,
      reason
    ) values (
      '10000000-0000-0000-0000-000000000001',
      auth.uid(),
      'unsafe direct appeal'
    )
  $sql$,
  'authenticated user cannot directly insert moderation_appeals.'
);

select pg_temp.satera_expect_insufficient_privilege(
  $sql$
    update moderation_appeals set status = 'closed'
  $sql$,
  'authenticated user cannot directly update moderation_appeals.'
);

select pg_temp.satera_expect_insufficient_privilege(
  $sql$
    delete from moderation_appeals
  $sql$,
  'authenticated user cannot directly delete moderation_appeals.'
);

rollback;
