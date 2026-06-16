create table user_restrictions (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references products(id) on delete restrict,
  community_id uuid references communities(id) on delete cascade,
  channel_id uuid references community_channels(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  restriction_type text not null,
  status text not null default 'active',
  reason text,
  starts_at timestamptz not null default now(),
  expires_at timestamptz,
  created_by uuid not null references auth.users(id) on delete restrict,
  lifted_by uuid references auth.users(id) on delete set null,
  lifted_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint user_restrictions_type_check check (
    restriction_type in (
      'muted',
      'restricted',
      'read_only',
      'posting_disabled',
      'community_banned',
      'channel_banned',
      'platform_suspended'
    )
  ),
  constraint user_restrictions_status_check check (
    status in ('active', 'expired', 'lifted', 'replaced')
  ),
  constraint user_restrictions_expiry_after_start check (
    expires_at is null or expires_at > starts_at
  ),
  constraint user_restrictions_lifted_status_check check (
    lifted_at is null or status = 'lifted'
  ),
  constraint user_restrictions_reason_non_empty check (
    reason is null or nullif(trim(reason), '') is not null
  ),
  constraint user_restrictions_metadata_safe check (
    not public_metadata_has_private_reference_keys(metadata)
  )
);

comment on table user_restrictions is
  'Durable Satera Core enforcement records. Metadata is guarded against private inventory fields and must remain safe moderation context only.';

create table moderation_notes (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references products(id) on delete restrict,
  community_id uuid references communities(id) on delete cascade,
  report_id uuid references moderation_reports(id) on delete cascade,
  action_id uuid references moderation_actions(id) on delete cascade,
  subject_user_id uuid references auth.users(id) on delete set null,
  note text not null,
  visibility text not null default 'moderators',
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint moderation_notes_visibility_check check (
    visibility in ('moderators', 'product_admins', 'platform_admins')
  ),
  constraint moderation_notes_note_non_empty check (
    nullif(trim(note), '') is not null
  ),
  constraint moderation_notes_target_required check (
    report_id is not null
    or action_id is not null
    or subject_user_id is not null
    or community_id is not null
  )
);

create table moderation_appeals (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references products(id) on delete restrict,
  community_id uuid references communities(id) on delete cascade,
  report_id uuid references moderation_reports(id) on delete set null,
  action_id uuid references moderation_actions(id) on delete set null,
  restriction_id uuid references user_restrictions(id) on delete set null,
  submitted_by uuid not null references auth.users(id) on delete cascade,
  reason text not null,
  status text not null default 'open',
  reviewed_by uuid references auth.users(id) on delete set null,
  reviewed_at timestamptz,
  decision_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint moderation_appeals_status_check check (
    status in ('open', 'reviewing', 'accepted', 'denied', 'closed')
  ),
  constraint moderation_appeals_reason_non_empty check (
    nullif(trim(reason), '') is not null
  )
);

create index user_restrictions_product_id_idx on user_restrictions(product_id);
create index user_restrictions_community_id_idx on user_restrictions(community_id);
create index user_restrictions_channel_id_idx on user_restrictions(channel_id);
create index user_restrictions_user_id_idx on user_restrictions(user_id);
create index user_restrictions_status_idx on user_restrictions(status);
create index user_restrictions_expires_at_idx on user_restrictions(expires_at);
create index moderation_notes_report_id_idx on moderation_notes(report_id);
create index moderation_notes_action_id_idx on moderation_notes(action_id);
create index moderation_notes_subject_user_id_idx on moderation_notes(subject_user_id);
create index moderation_appeals_submitted_by_idx on moderation_appeals(submitted_by);
create index moderation_appeals_status_idx on moderation_appeals(status);
create index moderation_appeals_action_id_idx on moderation_appeals(action_id);
create index moderation_appeals_restriction_id_idx on moderation_appeals(restriction_id);

create trigger user_restrictions_set_updated_at
before update on user_restrictions
for each row execute function set_updated_at();

create trigger moderation_notes_set_updated_at
before update on moderation_notes
for each row execute function set_updated_at();

create trigger moderation_appeals_set_updated_at
before update on moderation_appeals
for each row execute function set_updated_at();

create or replace function enforce_moderation_foundation_product_consistency()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_product_id uuid;
  v_community_id uuid;
begin
  if tg_table_name = 'user_restrictions' then
    if new.community_id is not null then
      select product_id into v_product_id from communities where id = new.community_id;
      if v_product_id is null or new.product_id <> v_product_id then
        raise exception 'restriction product_id must match parent community product_id'
          using errcode = '23514';
      end if;
    end if;

    if new.channel_id is not null then
      select community_id, product_id
      into v_community_id, v_product_id
      from community_channels
      where id = new.channel_id;

      if v_product_id is null
        or new.product_id <> v_product_id
        or new.community_id is null
        or new.community_id <> v_community_id then
        raise exception 'restriction channel scope must match community/product scope'
          using errcode = '23514';
      end if;
    end if;
  elsif tg_table_name = 'moderation_notes' then
    if new.community_id is not null then
      select product_id into v_product_id from communities where id = new.community_id;
      if v_product_id is null or new.product_id <> v_product_id then
        raise exception 'note product_id must match parent community product_id'
          using errcode = '23514';
      end if;
    end if;
  elsif tg_table_name = 'moderation_appeals' then
    if new.community_id is not null then
      select product_id into v_product_id from communities where id = new.community_id;
      if v_product_id is null or new.product_id <> v_product_id then
        raise exception 'appeal product_id must match parent community product_id'
          using errcode = '23514';
      end if;
    end if;
  end if;

  return new;
end;
$$;

create trigger user_restrictions_product_consistency
before insert or update on user_restrictions
for each row execute function enforce_moderation_foundation_product_consistency();

create trigger moderation_notes_product_consistency
before insert or update on moderation_notes
for each row execute function enforce_moderation_foundation_product_consistency();

create trigger moderation_appeals_product_consistency
before insert or update on moderation_appeals
for each row execute function enforce_moderation_foundation_product_consistency();

create or replace function has_active_user_restriction(
  target_user_id uuid,
  target_product_id uuid,
  target_community_id uuid default null,
  target_channel_id uuid default null,
  target_restriction_type text default null
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from user_restrictions
    where user_id = target_user_id
      and product_id = target_product_id
      and status = 'active'
      and (expires_at is null or expires_at > now())
      and (target_restriction_type is null or restriction_type = target_restriction_type)
      and (
        community_id is null
        or (target_community_id is not null and community_id = target_community_id)
      )
      and (
        channel_id is null
        or (target_channel_id is not null and channel_id = target_channel_id)
      )
  );
$$;

create or replace function can_moderate_community_content(
  target_user_id uuid,
  target_community_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from communities
    where id = target_community_id
      and (
        is_platform_admin()
        or is_product_admin(product_id)
        or exists (
          select 1
          from community_memberships
          where community_memberships.community_id = communities.id
            and user_id = target_user_id
            and status = 'active'
            and role in ('owner', 'admin', 'moderator')
        )
      )
  );
$$;

create or replace function can_user_post_in_channel(
  target_user_id uuid,
  target_channel_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from community_channels cc
    join communities c on c.id = cc.community_id
    join community_memberships cm on cm.community_id = c.id
      and cm.user_id = target_user_id
      and cm.status = 'active'
    where cc.id = target_channel_id
      and c.status = 'active'
      and (
        cc.status = 'active'
        or (
          cc.status in ('locked', 'archived')
          and can_moderate_community_content(target_user_id, c.id)
        )
      )
      and (
        cc.visibility in ('community', 'public')
        or can_read_community_channel(cc.id)
      )
      and not has_active_user_restriction(target_user_id, c.product_id, c.id, cc.id, 'muted')
      and not has_active_user_restriction(target_user_id, c.product_id, c.id, cc.id, 'restricted')
      and not has_active_user_restriction(target_user_id, c.product_id, c.id, cc.id, 'read_only')
      and not has_active_user_restriction(target_user_id, c.product_id, c.id, cc.id, 'posting_disabled')
      and not has_active_user_restriction(target_user_id, c.product_id, c.id, cc.id, 'community_banned')
      and not has_active_user_restriction(target_user_id, c.product_id, c.id, cc.id, 'channel_banned')
      and not has_active_user_restriction(target_user_id, c.product_id, c.id, cc.id, 'platform_suspended')
  );
$$;

create or replace function create_community_message(
  p_channel_id uuid,
  p_body text default null,
  p_message_type text default 'message',
  p_reply_to_message_id uuid default null,
  p_public_object_reference_ids uuid[] default '{}'
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor_user_id uuid := auth.uid();
  v_channel community_channels;
  v_community communities;
  v_message_id uuid;
  v_reference_id uuid;
  v_reference public_object_references;
begin
  if v_actor_user_id is null then
    raise exception 'authenticated user is required'
      using errcode = '42501';
  end if;

  select *
  into v_channel
  from community_channels
  where id = p_channel_id;

  if not found then
    raise exception 'channel is required'
      using errcode = 'P0002';
  end if;

  select *
  into v_community
  from communities
  where id = v_channel.community_id
    and status = 'active';

  if not found then
    raise exception 'active community is required'
      using errcode = 'P0002';
  end if;

  if not can_user_post_in_channel(v_actor_user_id, v_channel.id) then
    raise exception 'user cannot post in channel'
      using errcode = '42501';
  end if;

  if nullif(trim(coalesce(p_body, '')), '') is null
    and coalesce(cardinality(p_public_object_reference_ids), 0) = 0 then
    raise exception 'message body or public object reference is required'
      using errcode = '23514';
  end if;

  insert into community_messages (
    community_id,
    channel_id,
    product_id,
    author_user_id,
    body,
    message_type,
    reply_to_message_id
  ) values (
    v_community.id,
    v_channel.id,
    v_community.product_id,
    v_actor_user_id,
    nullif(trim(coalesce(p_body, '')), ''),
    p_message_type,
    p_reply_to_message_id
  )
  returning id into v_message_id;

  foreach v_reference_id in array coalesce(p_public_object_reference_ids, '{}'::uuid[]) loop
    select *
    into v_reference
    from public_object_references
    where id = v_reference_id
      and product_id = v_community.product_id
      and exposure_state = 'active';

    if not found then
      raise exception 'active matching public object reference is required'
        using errcode = 'P0002';
    end if;

    if v_reference.visibility not in ('community', 'listing', 'showcase', 'trade', 'public', 'private_reference') then
      raise exception 'public object reference visibility is not shareable'
        using errcode = '42501';
    end if;

    if v_reference.visibility = 'private_reference'
      and not (
        v_reference.owner_user_id = v_actor_user_id
        or (v_reference.workspace_id is not null and is_workspace_member(v_reference.workspace_id))
        or (v_reference.organization_id is not null and is_organization_member(v_reference.organization_id))
        or is_platform_admin()
      ) then
      raise exception 'private reference can only be shared by its owner context'
        using errcode = '42501';
    end if;

    insert into community_message_references (
      message_id,
      community_id,
      channel_id,
      product_id,
      public_object_reference_id,
      reference_type,
      display_snapshot,
      created_by
    ) values (
      v_message_id,
      v_community.id,
      v_channel.id,
      v_community.product_id,
      v_reference.id,
      'shared_object',
      build_public_object_reference_snapshot(v_reference),
      v_actor_user_id
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
    'community_message_created',
    'community_messages',
    v_message_id,
    v_community.owner_user_id,
    v_community.workspace_id,
    v_community.organization_id,
    v_community.product_id,
    jsonb_build_object(
      'community_id', v_community.id,
      'channel_id', v_channel.id,
      'message_type', p_message_type,
      'reference_count', coalesce(cardinality(p_public_object_reference_ids), 0)
    )
  );

  return v_message_id;
end;
$$;

create or replace function moderate_community_content(
  p_report_id uuid default null,
  p_product_id uuid default null,
  p_community_id uuid default null,
  p_channel_id uuid default null,
  p_message_id uuid default null,
  p_target_entity_table text default null,
  p_target_entity_id uuid default null,
  p_action_type text default null,
  p_reason text default null,
  p_metadata jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor_user_id uuid := auth.uid();
  v_action_id uuid;
  v_report moderation_reports;
  v_report_status text;
  v_message community_messages;
  v_target_user_id uuid;
  v_restriction_id uuid;
  v_restriction_type text;
  v_metadata jsonb := coalesce(p_metadata, '{}'::jsonb);
begin
  if v_actor_user_id is null then
    raise exception 'authenticated user is required'
      using errcode = '42501';
  end if;

  if p_product_id is null then
    raise exception 'product_id is required'
      using errcode = '23514';
  end if;

  if nullif(trim(coalesce(p_action_type, '')), '') is null then
    raise exception 'action_type is required'
      using errcode = '23514';
  end if;

  if public_metadata_has_private_reference_keys(v_metadata) then
    raise exception 'moderation metadata contains private inventory fields'
      using errcode = '23514';
  end if;

  if p_community_id is not null then
    if not can_moderate_community_content(v_actor_user_id, p_community_id) then
      raise exception 'community moderation role is required'
        using errcode = '42501';
    end if;
  elsif not (is_product_admin(p_product_id) or is_platform_admin()) then
    raise exception 'product or platform moderation role is required'
      using errcode = '42501';
  end if;

  if p_report_id is not null then
    select *
    into v_report
    from moderation_reports
    where id = p_report_id
    for update;

    if not found then
      raise exception 'moderation report not found'
        using errcode = 'P0002';
    end if;

    if v_report.product_id <> p_product_id
      or (p_community_id is not null and v_report.community_id <> p_community_id)
      or (p_channel_id is not null and v_report.channel_id <> p_channel_id)
      or (p_message_id is not null and v_report.message_id <> p_message_id) then
      raise exception 'moderation report scope does not match action scope'
        using errcode = '23514';
    end if;
  end if;

  if p_message_id is not null
    or p_target_entity_table = 'community_messages' then
    select *
    into v_message
    from community_messages
    where id = coalesce(p_message_id, p_target_entity_id);

    if not found then
      raise exception 'target message not found'
        using errcode = 'P0002';
    end if;

    if v_message.product_id <> p_product_id
      or (p_community_id is not null and v_message.community_id <> p_community_id)
      or (p_channel_id is not null and v_message.channel_id <> p_channel_id) then
      raise exception 'target message scope does not match action scope'
        using errcode = '23514';
    end if;

    v_target_user_id := v_message.author_user_id;
  elsif p_target_entity_table = 'auth.users' then
    v_target_user_id := p_target_entity_id;
  elsif v_metadata ? 'target_user_id' then
    v_target_user_id := (v_metadata ->> 'target_user_id')::uuid;
  end if;

  insert into moderation_actions (
    product_id,
    community_id,
    channel_id,
    message_id,
    report_id,
    actor_user_id,
    action_type,
    target_entity_table,
    target_entity_id,
    reason,
    metadata
  ) values (
    p_product_id,
    p_community_id,
    p_channel_id,
    coalesce(p_message_id, v_message.id),
    p_report_id,
    v_actor_user_id,
    p_action_type,
    trim(p_target_entity_table),
    p_target_entity_id,
    p_reason,
    v_metadata
  )
  returning id into v_action_id;

  if v_message.id is not null then
    if p_action_type = 'hide' then
      update community_messages
      set status = 'hidden'
      where id = v_message.id;
    elsif p_action_type = 'remove' then
      update community_messages
      set status = 'removed'
      where id = v_message.id;
    elsif p_action_type = 'delete' then
      update community_messages
      set status = 'deleted', deleted_at = now()
      where id = v_message.id;
    elsif p_action_type = 'quarantine' then
      update community_messages
      set status = 'hidden'
      where id = v_message.id;
    elsif p_action_type = 'allow' then
      update community_messages
      set status = 'active'
      where id = v_message.id;
    end if;
  end if;

  v_restriction_type := case p_action_type
    when 'mute_user' then 'muted'
    when 'restrict_user' then 'restricted'
    when 'ban_from_channel' then 'channel_banned'
    when 'ban_from_community' then 'community_banned'
    when 'platform_suspend' then 'platform_suspended'
    else null
  end;

  if v_restriction_type is not null then
    if v_target_user_id is null then
      raise exception 'target user is required for restriction action'
        using errcode = '23514';
    end if;

    insert into user_restrictions (
      product_id,
      community_id,
      channel_id,
      user_id,
      restriction_type,
      reason,
      starts_at,
      expires_at,
      created_by,
      metadata
    ) values (
      p_product_id,
      case
        when v_restriction_type in ('muted', 'restricted', 'community_banned', 'channel_banned')
          then p_community_id
        else null
      end,
      case when v_restriction_type = 'channel_banned' then p_channel_id else null end,
      v_target_user_id,
      v_restriction_type,
      p_reason,
      now(),
      case
        when v_metadata ? 'expires_at' then (v_metadata ->> 'expires_at')::timestamptz
        else null
      end,
      v_actor_user_id,
      jsonb_build_object(
        'moderation_action_id', v_action_id,
        'source_action_type', p_action_type
      ) || v_metadata
    )
    returning id into v_restriction_id;

    update moderation_actions
    set metadata = metadata || jsonb_build_object('restriction_id', v_restriction_id)
    where id = v_action_id;

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
      'user_restriction_created',
      'user_restrictions',
      v_restriction_id,
      (select owner_user_id from communities where id = p_community_id),
      (select workspace_id from communities where id = p_community_id),
      (select organization_id from communities where id = p_community_id),
      p_product_id,
      jsonb_build_object(
        'community_id', p_community_id,
        'channel_id', p_channel_id,
        'target_user_id', v_target_user_id,
        'restriction_type', v_restriction_type,
        'moderation_action_id', v_action_id
      )
    );
  end if;

  if p_report_id is not null then
    v_report_status := case
      when p_action_type = 'escalate_to_admin' then 'escalated'
      when p_action_type = 'allow' then 'dismissed'
      else 'resolved'
    end;

    update moderation_reports
    set status = v_report_status
    where id = p_report_id;
  end if;

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
    'community_content_moderated',
    'moderation_actions',
    v_action_id,
    (select owner_user_id from communities where id = p_community_id),
    (select workspace_id from communities where id = p_community_id),
    (select organization_id from communities where id = p_community_id),
    p_product_id,
    jsonb_build_object(
      'community_id', p_community_id,
      'channel_id', p_channel_id,
      'message_id', coalesce(p_message_id, v_message.id),
      'report_id', p_report_id,
      'target_entity_table', p_target_entity_table,
      'target_entity_id', p_target_entity_id,
      'target_user_id', v_target_user_id,
      'action_type', p_action_type,
      'restriction_id', v_restriction_id,
      'quarantine_status', case when p_action_type = 'quarantine' then 'hidden' else null end
    )
  );

  return v_action_id;
end;
$$;

create or replace function lift_user_restriction(
  p_restriction_id uuid,
  p_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor_user_id uuid := auth.uid();
  v_restriction user_restrictions;
  v_action_id uuid;
begin
  if v_actor_user_id is null then
    raise exception 'authenticated user is required'
      using errcode = '42501';
  end if;

  select *
  into v_restriction
  from user_restrictions
  where id = p_restriction_id
  for update;

  if not found then
    raise exception 'restriction not found'
      using errcode = 'P0002';
  end if;

  if v_restriction.community_id is not null then
    if not can_moderate_community_content(v_actor_user_id, v_restriction.community_id) then
      raise exception 'community moderation role is required'
        using errcode = '42501';
    end if;
  elsif not (is_product_admin(v_restriction.product_id) or is_platform_admin()) then
    raise exception 'product or platform moderation role is required'
      using errcode = '42501';
  end if;

  update user_restrictions
  set
    status = 'lifted',
    lifted_by = v_actor_user_id,
    lifted_at = now(),
    metadata = metadata || jsonb_build_object('lift_reason', nullif(trim(coalesce(p_reason, '')), ''))
  where id = p_restriction_id;

  insert into moderation_actions (
    product_id,
    community_id,
    channel_id,
    actor_user_id,
    action_type,
    target_entity_table,
    target_entity_id,
    reason,
    metadata
  ) values (
    v_restriction.product_id,
    v_restriction.community_id,
    v_restriction.channel_id,
    v_actor_user_id,
    'allow',
    'user_restrictions',
    p_restriction_id,
    p_reason,
    jsonb_build_object(
      'restriction_id', p_restriction_id,
      'restriction_type', v_restriction.restriction_type,
      'target_user_id', v_restriction.user_id,
      'lifted', true
    )
  )
  returning id into v_action_id;

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
    'user_restriction_lifted',
    'user_restrictions',
    p_restriction_id,
    (select owner_user_id from communities where id = v_restriction.community_id),
    (select workspace_id from communities where id = v_restriction.community_id),
    (select organization_id from communities where id = v_restriction.community_id),
    v_restriction.product_id,
    jsonb_build_object(
      'community_id', v_restriction.community_id,
      'channel_id', v_restriction.channel_id,
      'target_user_id', v_restriction.user_id,
      'moderation_action_id', v_action_id
    )
  );

  return p_restriction_id;
end;
$$;

create or replace function add_moderation_note(
  p_product_id uuid,
  p_community_id uuid default null,
  p_report_id uuid default null,
  p_action_id uuid default null,
  p_subject_user_id uuid default null,
  p_note text default null,
  p_visibility text default 'moderators'
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor_user_id uuid := auth.uid();
  v_note_id uuid;
begin
  if v_actor_user_id is null then
    raise exception 'authenticated user is required'
      using errcode = '42501';
  end if;

  if p_community_id is not null then
    if not can_moderate_community_content(v_actor_user_id, p_community_id) then
      raise exception 'community moderation role is required'
        using errcode = '42501';
    end if;
  elsif not (is_product_admin(p_product_id) or is_platform_admin()) then
    raise exception 'product or platform moderation role is required'
      using errcode = '42501';
  end if;

  insert into moderation_notes (
    product_id,
    community_id,
    report_id,
    action_id,
    subject_user_id,
    note,
    visibility,
    created_by
  ) values (
    p_product_id,
    p_community_id,
    p_report_id,
    p_action_id,
    p_subject_user_id,
    trim(p_note),
    p_visibility,
    v_actor_user_id
  )
  returning id into v_note_id;

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
    'moderation_note_added',
    'moderation_notes',
    v_note_id,
    (select owner_user_id from communities where id = p_community_id),
    (select workspace_id from communities where id = p_community_id),
    (select organization_id from communities where id = p_community_id),
    p_product_id,
    jsonb_build_object(
      'community_id', p_community_id,
      'report_id', p_report_id,
      'action_id', p_action_id,
      'subject_user_id', p_subject_user_id,
      'visibility', p_visibility
    )
  );

  return v_note_id;
end;
$$;

create or replace function submit_moderation_appeal(
  p_product_id uuid,
  p_community_id uuid default null,
  p_report_id uuid default null,
  p_action_id uuid default null,
  p_restriction_id uuid default null,
  p_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor_user_id uuid := auth.uid();
  v_restriction user_restrictions;
  v_action moderation_actions;
  v_report moderation_reports;
  v_appeal_id uuid;
  v_related_user_id uuid;
begin
  if v_actor_user_id is null then
    raise exception 'authenticated user is required'
      using errcode = '42501';
  end if;

  if nullif(trim(coalesce(p_reason, '')), '') is null then
    raise exception 'appeal reason is required'
      using errcode = '23514';
  end if;

  if p_restriction_id is not null then
    select * into v_restriction from user_restrictions where id = p_restriction_id;
    if not found then
      raise exception 'restriction not found'
        using errcode = 'P0002';
    end if;

    v_related_user_id := v_restriction.user_id;

    if v_restriction.product_id <> p_product_id
      or (p_community_id is not null and v_restriction.community_id <> p_community_id) then
      raise exception 'restriction scope does not match appeal scope'
        using errcode = '23514';
    end if;
  end if;

  if p_action_id is not null then
    select * into v_action from moderation_actions where id = p_action_id;
    if not found then
      raise exception 'moderation action not found'
        using errcode = 'P0002';
    end if;

    if v_action.product_id <> p_product_id
      or (p_community_id is not null and v_action.community_id <> p_community_id) then
      raise exception 'action scope does not match appeal scope'
        using errcode = '23514';
    end if;

    if v_action.metadata ? 'target_user_id' then
      v_related_user_id := coalesce(v_related_user_id, (v_action.metadata ->> 'target_user_id')::uuid);
    end if;
  end if;

  if p_report_id is not null then
    select * into v_report from moderation_reports where id = p_report_id;
    if not found then
      raise exception 'moderation report not found'
        using errcode = 'P0002';
    end if;

    if v_report.product_id <> p_product_id
      or (p_community_id is not null and v_report.community_id <> p_community_id) then
      raise exception 'report scope does not match appeal scope'
        using errcode = '23514';
    end if;

    v_related_user_id := coalesce(v_related_user_id, v_report.reported_by);
  end if;

  if v_related_user_id is not null and v_related_user_id <> v_actor_user_id then
    raise exception 'appeal can only be submitted by the related user'
      using errcode = '42501';
  end if;

  insert into moderation_appeals (
    product_id,
    community_id,
    report_id,
    action_id,
    restriction_id,
    submitted_by,
    reason
  ) values (
    p_product_id,
    p_community_id,
    p_report_id,
    p_action_id,
    p_restriction_id,
    v_actor_user_id,
    trim(p_reason)
  )
  returning id into v_appeal_id;

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
    'moderation_appeal_submitted',
    'moderation_appeals',
    v_appeal_id,
    (select owner_user_id from communities where id = p_community_id),
    (select workspace_id from communities where id = p_community_id),
    (select organization_id from communities where id = p_community_id),
    p_product_id,
    jsonb_build_object(
      'community_id', p_community_id,
      'report_id', p_report_id,
      'action_id', p_action_id,
      'restriction_id', p_restriction_id
    )
  );

  return v_appeal_id;
end;
$$;

alter table user_restrictions enable row level security;
alter table moderation_notes enable row level security;
alter table moderation_appeals enable row level security;

create policy "authorized users read user restrictions"
on user_restrictions
for select
using (
  is_platform_admin()
  or is_product_admin(product_id)
  or (community_id is not null and can_moderate_community_content(auth.uid(), community_id))
  or (user_id = auth.uid() and status in ('active', 'lifted'))
);

create policy "authorized users read moderation notes"
on moderation_notes
for select
using (
  is_platform_admin()
  or (visibility in ('moderators', 'product_admins') and is_product_admin(product_id))
  or (
    visibility = 'moderators'
    and community_id is not null
    and can_moderate_community_content(auth.uid(), community_id)
  )
);

create policy "authorized users read moderation appeals"
on moderation_appeals
for select
using (
  submitted_by = auth.uid()
  or is_platform_admin()
  or is_product_admin(product_id)
  or (community_id is not null and can_moderate_community_content(auth.uid(), community_id))
);

grant select on user_restrictions to authenticated;
grant select on moderation_notes to authenticated;
grant select on moderation_appeals to authenticated;

revoke insert, update, delete on user_restrictions from authenticated, anon;
revoke insert, update, delete on moderation_notes from authenticated, anon;
revoke insert, update, delete on moderation_appeals from authenticated, anon;

revoke all on function enforce_moderation_foundation_product_consistency() from public, anon;
revoke all on function has_active_user_restriction(uuid, uuid, uuid, uuid, text) from public, anon;
revoke all on function can_user_post_in_channel(uuid, uuid) from public, anon;
revoke all on function can_moderate_community_content(uuid, uuid) from public, anon;
revoke all on function lift_user_restriction(uuid, text) from public, anon;
revoke all on function add_moderation_note(uuid, uuid, uuid, uuid, uuid, text, text) from public, anon;
revoke all on function submit_moderation_appeal(uuid, uuid, uuid, uuid, uuid, text) from public, anon;

grant execute on function has_active_user_restriction(uuid, uuid, uuid, uuid, text) to authenticated;
grant execute on function can_user_post_in_channel(uuid, uuid) to authenticated;
grant execute on function can_moderate_community_content(uuid, uuid) to authenticated;
grant execute on function lift_user_restriction(uuid, text) to authenticated;
grant execute on function add_moderation_note(uuid, uuid, uuid, uuid, uuid, text, text) to authenticated;
grant execute on function submit_moderation_appeal(uuid, uuid, uuid, uuid, uuid, text) to authenticated;
