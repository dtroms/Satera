-- Verifies durable Satera Core notification records, RLS, safe metadata,
-- auditability, and RPC-only write paths without product notification UI or
-- delivery providers.

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

create temp table notification_foundation_results (
  label text primary key,
  entity_id uuid not null
) on commit drop;

insert into notification_foundation_results
select
  'event',
  create_notification_event(
    p_product_id => '10000000-0000-0000-0000-000000000001',
    p_event_type => 'community.message.created',
    p_entity_table => 'community_messages',
    p_entity_id => gen_random_uuid(),
    p_related_entity_table => 'communities',
    p_related_entity_id => gen_random_uuid(),
    p_title => 'Community message',
    p_body => 'A safe notification body.',
    p_safe_metadata => jsonb_build_object('safe_context', 'sql verification'),
    p_recipient_user_ids => array[
      '00000000-0000-0000-0000-0000000000a1'::uuid,
      '00000000-0000-0000-0000-0000000000b2'::uuid,
      '00000000-0000-0000-0000-0000000000b2'::uuid,
      null::uuid
    ],
    p_notification_type => 'community',
    p_priority => 'normal'
  );

insert into notification_foundation_results
select 'notification_a', id
from notifications
where notification_event_id = (
    select entity_id from notification_foundation_results where label = 'event'
  )
  and recipient_user_id = '00000000-0000-0000-0000-0000000000a1';

reset role;

insert into notification_foundation_results
select 'notification_b', id
from notifications
where notification_event_id = (
    select entity_id from notification_foundation_results where label = 'event'
  )
  and recipient_user_id = '00000000-0000-0000-0000-0000000000b2';

select pg_temp.satera_assert(
  (
    select count(*) = 2
    from notifications
    where notification_event_id = (
      select entity_id from notification_foundation_results where label = 'event'
    )
  ),
  'user can create a notification event and distinct recipient notifications through RPC.'
);

set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000a1';

select pg_temp.satera_assert(
  exists (
    select 1
    from audit_events
    where entity_table = 'notification_events'
      and entity_id = (
        select entity_id from notification_foundation_results where label = 'event'
      )
      and event_type = 'notification_event_created'
  ),
  'create_notification_event writes an audit_event.'
);

select pg_temp.satera_expect_rejected(
  $sql$
    select create_notification_event(
      p_event_type => 'unsafe.metadata',
      p_title => 'Unsafe metadata',
      p_safe_metadata => '{"true_basis":100,"nested":{"private_notes":"hidden"}}'::jsonb,
      p_recipient_user_ids => array['00000000-0000-0000-0000-0000000000a1'::uuid]
    )
  $sql$,
  'notification safe_metadata cannot contain private inventory fields.'
);

select pg_temp.satera_expect_rejected(
  $sql$
    insert into notifications (
      recipient_user_id,
      notification_type,
      title
    ) values (
      '00000000-0000-0000-0000-0000000000a1',
      'system',
      'Direct insert should fail'
    )
  $sql$,
  'direct insert on notifications is blocked for authenticated users.'
);

select pg_temp.satera_expect_rejected(
  format(
    $sql$
      update notifications
      set status = 'read'
      where id = %L::uuid
    $sql$,
    (select entity_id from notification_foundation_results where label = 'notification_a')
  ),
  'direct update on notifications is blocked for authenticated users.'
);

select pg_temp.satera_expect_rejected(
  format(
    $sql$
      delete from notifications
      where id = %L::uuid
    $sql$,
    (select entity_id from notification_foundation_results where label = 'notification_a')
  ),
  'direct delete on notifications is blocked for authenticated users.'
);

select pg_temp.satera_expect_rejected(
  format(
    $sql$
      insert into notification_delivery_attempts (
        notification_id,
        delivery_channel
      ) values (
        %L::uuid,
        'email'
      )
    $sql$,
    (select entity_id from notification_foundation_results where label = 'notification_a')
  ),
  'notification_delivery_attempts direct writes are blocked.'
);

set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000b2';

select pg_temp.satera_assert(
  (
    select count(*) = 1
    from notifications
    where id = (
      select entity_id from notification_foundation_results where label = 'notification_b'
    )
  ),
  'recipient can read their own notification.'
);

select pg_temp.satera_assert(
  not exists (
    select 1
    from notifications
    where id = (
      select entity_id from notification_foundation_results where label = 'notification_a'
    )
  ),
  'another normal user cannot read someone else''s notification.'
);

select mark_notification_read(
  (select entity_id from notification_foundation_results where label = 'notification_b')
);

select pg_temp.satera_assert(
  (
    select status = 'read'
      and read_at is not null
      and delivery_state = 'in_app_seen'
    from notifications
    where id = (
      select entity_id from notification_foundation_results where label = 'notification_b'
    )
  ),
  'mark_notification_read works for recipient.'
);

select pg_temp.satera_expect_rejected(
  format(
    $sql$
      select mark_notification_read(%L::uuid)
    $sql$,
    (select entity_id from notification_foundation_results where label = 'notification_a')
  ),
  'recipient cannot mark another user''s notification read.'
);

insert into notification_foundation_results
select
  'dismiss_event',
  create_notification_event(
    p_event_type => 'moderation.notice',
    p_title => 'Moderation notice',
    p_recipient_user_ids => array['00000000-0000-0000-0000-0000000000b2'::uuid],
    p_notification_type => 'moderation'
  );

insert into notification_foundation_results
select 'dismiss_notification', id
from notifications
where notification_event_id = (
  select entity_id from notification_foundation_results where label = 'dismiss_event'
);

select dismiss_notification(
  (select entity_id from notification_foundation_results where label = 'dismiss_notification')
);

select pg_temp.satera_assert(
  (
    select status = 'dismissed'
      and dismissed_at is not null
    from notifications
    where id = (
      select entity_id from notification_foundation_results where label = 'dismiss_notification'
    )
  ),
  'dismiss_notification works for recipient.'
);

insert into notification_foundation_results
select
  'archive_event',
  create_notification_event(
    p_event_type => 'workflow.notice',
    p_title => 'Workflow notice',
    p_recipient_user_ids => array['00000000-0000-0000-0000-0000000000b2'::uuid],
    p_notification_type => 'system'
  );

insert into notification_foundation_results
select 'archive_notification', id
from notifications
where notification_event_id = (
  select entity_id from notification_foundation_results where label = 'archive_event'
);

select archive_notification(
  (select entity_id from notification_foundation_results where label = 'archive_notification')
);

select pg_temp.satera_assert(
  (
    select status = 'archived'
      and read_at is null
      and dismissed_at is null
    from notifications
    where id = (
      select entity_id from notification_foundation_results where label = 'archive_notification'
    )
  ),
  'archive_notification works for recipient.'
);

reset role;

insert into platform_admins (
  user_id,
  role
) values (
  '00000000-0000-0000-0000-0000000000b2',
  'platform_support'
) on conflict (user_id, role) do nothing;

set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000b2';

select pg_temp.satera_assert(
  exists (
    select 1
    from notifications
    where id = (
      select entity_id from notification_foundation_results where label = 'notification_a'
    )
  ),
  'platform admin can inspect notifications.'
);

rollback;
