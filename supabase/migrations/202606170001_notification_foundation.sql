create table notification_events (
  id uuid primary key default gen_random_uuid(),
  product_id uuid references products(id) on delete set null,
  actor_user_id uuid references auth.users(id) on delete set null,
  event_type text not null,
  entity_table text,
  entity_id uuid,
  related_entity_table text,
  related_entity_id uuid,
  title text not null,
  body text,
  safe_metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint notification_events_event_type_non_empty check (
    nullif(trim(event_type), '') is not null
  ),
  constraint notification_events_title_non_empty check (
    nullif(trim(title), '') is not null
  ),
  constraint notification_events_safe_metadata_safe check (
    not public_metadata_has_private_reference_keys(safe_metadata)
  )
);

comment on table notification_events is
  'Durable Satera Core notification source events. Delivery providers and product UI are downstream of these truth records.';
comment on column notification_events.safe_metadata is
  'Safe notification metadata only. Do not store true_basis, purchase price, profit, location, private notes, private tags, ownership history, or private transaction history.';

create table notifications (
  id uuid primary key default gen_random_uuid(),
  notification_event_id uuid references notification_events(id) on delete set null,
  recipient_user_id uuid not null references auth.users(id) on delete cascade,
  product_id uuid references products(id) on delete set null,
  notification_type text not null,
  title text not null,
  body text,
  entity_table text,
  entity_id uuid,
  related_entity_table text,
  related_entity_id uuid,
  status text not null default 'unread',
  priority text not null default 'normal',
  delivery_state text not null default 'in_app_pending',
  safe_metadata jsonb not null default '{}'::jsonb,
  read_at timestamptz,
  dismissed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint notifications_type_non_empty check (
    nullif(trim(notification_type), '') is not null
  ),
  constraint notifications_title_non_empty check (
    nullif(trim(title), '') is not null
  ),
  constraint notifications_status_check check (
    status in ('unread', 'read', 'dismissed', 'archived')
  ),
  constraint notifications_priority_check check (
    priority in ('low', 'normal', 'high', 'urgent')
  ),
  constraint notifications_delivery_state_check check (
    delivery_state in (
      'in_app_pending',
      'in_app_seen',
      'email_pending',
      'email_sent',
      'email_failed',
      'suppressed',
      'delivered_external'
    )
  ),
  constraint notifications_read_at_status_check check (
    read_at is null or status = 'read'
  ),
  constraint notifications_dismissed_at_status_check check (
    dismissed_at is null or status = 'dismissed'
  ),
  constraint notifications_safe_metadata_safe check (
    not public_metadata_has_private_reference_keys(safe_metadata)
  )
);

comment on table notifications is
  'Recipient-specific durable Satera Core notification state. Products render experiences later.';
comment on column notifications.safe_metadata is
  'Safe notification metadata only. Do not store private inventory fields.';

create table notification_delivery_attempts (
  id uuid primary key default gen_random_uuid(),
  notification_id uuid not null references notifications(id) on delete cascade,
  delivery_channel text not null,
  provider text,
  provider_message_id text,
  status text not null default 'pending',
  error_message text,
  attempted_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  constraint notification_delivery_attempts_channel_check check (
    delivery_channel in ('in_app', 'email', 'push', 'sms', 'webhook')
  ),
  constraint notification_delivery_attempts_status_check check (
    status in ('pending', 'sent', 'failed', 'suppressed')
  )
);

comment on table notification_delivery_attempts is
  'Future delivery tracking for notification providers. This migration does not implement email, push, SMS, realtime, or background delivery.';

create index notification_events_product_id_idx on notification_events(product_id);
create index notification_events_event_type_idx on notification_events(event_type);
create index notification_events_entity_idx on notification_events(entity_table, entity_id);

create index notifications_recipient_user_id_idx on notifications(recipient_user_id);
create index notifications_product_id_idx on notifications(product_id);
create index notifications_status_idx on notifications(status);
create index notifications_created_at_idx on notifications(created_at);
create index notifications_entity_idx on notifications(entity_table, entity_id);
create index notifications_related_entity_idx on notifications(related_entity_table, related_entity_id);

create index notification_delivery_attempts_notification_id_idx on notification_delivery_attempts(notification_id);
create index notification_delivery_attempts_status_idx on notification_delivery_attempts(status);

create trigger notifications_set_updated_at
before update on notifications
for each row execute function set_updated_at();

alter table notification_events enable row level security;
alter table notifications enable row level security;
alter table notification_delivery_attempts enable row level security;

create policy "platform admins read all notification events"
on notification_events
for select
using (is_platform_admin());

create policy "product admins read product notification events"
on notification_events
for select
using (product_id is not null and is_product_admin(product_id));

create policy "actors read created notification events"
on notification_events
for select
using (actor_user_id = auth.uid());

create policy "recipients read notification events through notifications"
on notification_events
for select
using (
  exists (
    select 1
    from notifications
    where notifications.notification_event_id = notification_events.id
      and notifications.recipient_user_id = auth.uid()
  )
);

create policy "recipients read own notifications"
on notifications
for select
using (recipient_user_id = auth.uid());

create policy "platform admins read all notifications"
on notifications
for select
using (is_platform_admin());

create policy "product admins read product notifications"
on notifications
for select
using (product_id is not null and is_product_admin(product_id));

create policy "recipients read own notification delivery attempts"
on notification_delivery_attempts
for select
using (
  exists (
    select 1
    from notifications
    where notifications.id = notification_delivery_attempts.notification_id
      and notifications.recipient_user_id = auth.uid()
  )
);

create policy "platform admins read all notification delivery attempts"
on notification_delivery_attempts
for select
using (is_platform_admin());

create policy "product admins read product notification delivery attempts"
on notification_delivery_attempts
for select
using (
  exists (
    select 1
    from notifications
    where notifications.id = notification_delivery_attempts.notification_id
      and notifications.product_id is not null
      and is_product_admin(notifications.product_id)
  )
);

grant select on notification_events to authenticated;
grant select on notifications to authenticated;
grant select on notification_delivery_attempts to authenticated;

revoke insert, update, delete on notification_events from authenticated, anon;
revoke insert, update, delete on notifications from authenticated, anon;
revoke insert, update, delete on notification_delivery_attempts from authenticated, anon;

create or replace function create_notification_event(
  p_product_id uuid default null,
  p_actor_user_id uuid default null,
  p_event_type text default null,
  p_entity_table text default null,
  p_entity_id uuid default null,
  p_related_entity_table text default null,
  p_related_entity_id uuid default null,
  p_title text default null,
  p_body text default null,
  p_safe_metadata jsonb default '{}'::jsonb,
  p_recipient_user_ids uuid[] default '{}'::uuid[],
  p_notification_type text default 'system',
  p_priority text default 'normal'
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor_user_id uuid := auth.uid();
  v_effective_actor_user_id uuid;
  v_event_id uuid;
  v_recipient_user_id uuid;
begin
  if v_actor_user_id is null then
    raise exception 'authenticated user is required'
      using errcode = '42501';
  end if;

  v_effective_actor_user_id := coalesce(p_actor_user_id, v_actor_user_id);

  if p_actor_user_id is not null
    and p_actor_user_id <> v_actor_user_id
    and not (
      is_platform_admin()
      or (p_product_id is not null and is_product_admin(p_product_id))
    ) then
    raise exception 'actor authorization is required'
      using errcode = '42501';
  end if;

  if p_product_id is not null
    and not exists (select 1 from products where id = p_product_id) then
    raise exception 'product not found'
      using errcode = 'P0002';
  end if;

  if nullif(trim(coalesce(p_event_type, '')), '') is null then
    raise exception 'event_type is required'
      using errcode = '23514';
  end if;

  if nullif(trim(coalesce(p_title, '')), '') is null then
    raise exception 'title is required'
      using errcode = '23514';
  end if;

  if nullif(trim(coalesce(p_notification_type, '')), '') is null then
    raise exception 'notification_type is required'
      using errcode = '23514';
  end if;

  if p_priority not in ('low', 'normal', 'high', 'urgent') then
    raise exception 'invalid notification priority'
      using errcode = '23514';
  end if;

  perform assert_public_reference_metadata_safe(coalesce(p_safe_metadata, '{}'::jsonb));

  insert into notification_events (
    product_id,
    actor_user_id,
    event_type,
    entity_table,
    entity_id,
    related_entity_table,
    related_entity_id,
    title,
    body,
    safe_metadata
  ) values (
    p_product_id,
    v_effective_actor_user_id,
    trim(p_event_type),
    nullif(trim(coalesce(p_entity_table, '')), ''),
    p_entity_id,
    nullif(trim(coalesce(p_related_entity_table, '')), ''),
    p_related_entity_id,
    trim(p_title),
    p_body,
    coalesce(p_safe_metadata, '{}'::jsonb)
  )
  returning id into v_event_id;

  for v_recipient_user_id in
    select distinct recipient_user_id
    from unnest(coalesce(p_recipient_user_ids, '{}'::uuid[])) as recipients(recipient_user_id)
    where recipient_user_id is not null
  loop
    insert into notifications (
      notification_event_id,
      recipient_user_id,
      product_id,
      notification_type,
      title,
      body,
      entity_table,
      entity_id,
      related_entity_table,
      related_entity_id,
      priority,
      safe_metadata
    ) values (
      v_event_id,
      v_recipient_user_id,
      p_product_id,
      trim(p_notification_type),
      trim(p_title),
      p_body,
      nullif(trim(coalesce(p_entity_table, '')), ''),
      p_entity_id,
      nullif(trim(coalesce(p_related_entity_table, '')), ''),
      p_related_entity_id,
      p_priority,
      coalesce(p_safe_metadata, '{}'::jsonb)
    );
  end loop;

  insert into audit_events (
    actor_user_id,
    event_type,
    entity_table,
    entity_id,
    owner_user_id,
    workspace_id,
    organization_id,
    product_id,
    metadata
  ) values (
    v_actor_user_id,
    'notification_event_created',
    'notification_events',
    v_event_id,
    v_effective_actor_user_id,
    null,
    null,
    p_product_id,
    jsonb_build_object(
      'actor_user_id', v_effective_actor_user_id,
      'notification_type', trim(p_notification_type),
      'priority', p_priority,
      'recipient_count', (
        select count(distinct recipient_user_id)
        from unnest(coalesce(p_recipient_user_ids, '{}'::uuid[])) as recipients(recipient_user_id)
        where recipient_user_id is not null
      )
    )
  );

  return v_event_id;
end;
$$;

create or replace function mark_notification_read(p_notification_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor_user_id uuid := auth.uid();
begin
  if v_actor_user_id is null then
    raise exception 'authenticated user is required'
      using errcode = '42501';
  end if;

  update notifications
  set
    status = 'read',
    read_at = now(),
    dismissed_at = null,
    delivery_state = case
      when delivery_state = 'in_app_pending' then 'in_app_seen'
      else delivery_state
    end,
    updated_at = now()
  where id = p_notification_id
    and (recipient_user_id = v_actor_user_id or is_platform_admin());

  if not found then
    raise exception 'notification not found or not authorized'
      using errcode = '42501';
  end if;

  return p_notification_id;
end;
$$;

create or replace function mark_notifications_read(p_notification_ids uuid[])
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor_user_id uuid := auth.uid();
  v_updated_count integer;
begin
  if v_actor_user_id is null then
    raise exception 'authenticated user is required'
      using errcode = '42501';
  end if;

  update notifications
  set
    status = 'read',
    read_at = now(),
    dismissed_at = null,
    delivery_state = case
      when delivery_state = 'in_app_pending' then 'in_app_seen'
      else delivery_state
    end,
    updated_at = now()
  where id = any(coalesce(p_notification_ids, '{}'::uuid[]))
    and (recipient_user_id = v_actor_user_id or is_platform_admin());

  get diagnostics v_updated_count = row_count;
  return v_updated_count;
end;
$$;

create or replace function dismiss_notification(p_notification_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor_user_id uuid := auth.uid();
begin
  if v_actor_user_id is null then
    raise exception 'authenticated user is required'
      using errcode = '42501';
  end if;

  update notifications
  set
    status = 'dismissed',
    read_at = null,
    dismissed_at = now(),
    updated_at = now()
  where id = p_notification_id
    and (recipient_user_id = v_actor_user_id or is_platform_admin());

  if not found then
    raise exception 'notification not found or not authorized'
      using errcode = '42501';
  end if;

  return p_notification_id;
end;
$$;

create or replace function archive_notification(p_notification_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor_user_id uuid := auth.uid();
begin
  if v_actor_user_id is null then
    raise exception 'authenticated user is required'
      using errcode = '42501';
  end if;

  update notifications
  set
    status = 'archived',
    read_at = null,
    dismissed_at = null,
    updated_at = now()
  where id = p_notification_id
    and (recipient_user_id = v_actor_user_id or is_platform_admin());

  if not found then
    raise exception 'notification not found or not authorized'
      using errcode = '42501';
  end if;

  return p_notification_id;
end;
$$;

revoke execute on function create_notification_event(uuid, uuid, text, text, uuid, text, uuid, text, text, jsonb, uuid[], text, text) from public, anon;
revoke execute on function mark_notification_read(uuid) from public, anon;
revoke execute on function mark_notifications_read(uuid[]) from public, anon;
revoke execute on function dismiss_notification(uuid) from public, anon;
revoke execute on function archive_notification(uuid) from public, anon;

grant execute on function create_notification_event(uuid, uuid, text, text, uuid, text, uuid, text, text, jsonb, uuid[], text, text) to authenticated;
grant execute on function mark_notification_read(uuid) to authenticated;
grant execute on function mark_notifications_read(uuid[]) to authenticated;
grant execute on function dismiss_notification(uuid) to authenticated;
grant execute on function archive_notification(uuid) to authenticated;
