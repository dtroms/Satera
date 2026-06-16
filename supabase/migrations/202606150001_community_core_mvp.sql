create table communities (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references products(id) on delete restrict,
  organization_id uuid references organizations(id) on delete set null,
  owner_user_id uuid references auth.users(id) on delete set null,
  workspace_id uuid references workspaces(id) on delete set null,
  name text not null,
  slug text not null,
  description text,
  community_type text not null default 'collector_group',
  visibility text not null default 'private',
  status text not null default 'active',
  created_by uuid references auth.users(id) on delete set null,
  updated_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint communities_owner_context_required check (
    organization_id is not null or owner_user_id is not null or workspace_id is not null
  ),
  constraint communities_community_type_check check (
    community_type in (
      'collector_group',
      'shop',
      'show',
      'event',
      'trade_room',
      'support',
      'private_group'
    )
  ),
  constraint communities_visibility_check check (
    visibility in ('private', 'invite_only', 'product_visible', 'public')
  ),
  constraint communities_status_check check (
    status in ('active', 'archived', 'suspended')
  ),
  constraint communities_name_non_empty check (nullif(trim(name), '') is not null),
  constraint communities_slug_non_empty check (nullif(trim(slug), '') is not null),
  unique (product_id, slug)
);

create table community_channels (
  id uuid primary key default gen_random_uuid(),
  community_id uuid not null references communities(id) on delete cascade,
  product_id uuid not null references products(id) on delete restrict,
  name text not null,
  slug text not null,
  description text,
  channel_type text not null default 'conversation',
  visibility text not null default 'community',
  status text not null default 'active',
  sort_order integer not null default 0,
  created_by uuid references auth.users(id) on delete set null,
  updated_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint community_channels_channel_type_check check (
    channel_type in (
      'conversation',
      'announcement',
      'trade_sale',
      'looking_for',
      'comps_research',
      'show_floor',
      'support'
    )
  ),
  constraint community_channels_visibility_check check (
    visibility in ('community', 'moderators', 'staff', 'public')
  ),
  constraint community_channels_status_check check (
    status in ('active', 'archived', 'locked')
  ),
  constraint community_channels_name_non_empty check (nullif(trim(name), '') is not null),
  constraint community_channels_slug_non_empty check (nullif(trim(slug), '') is not null),
  unique (community_id, slug)
);

create table community_memberships (
  id uuid primary key default gen_random_uuid(),
  community_id uuid not null references communities(id) on delete cascade,
  product_id uuid not null references products(id) on delete restrict,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'member',
  status text not null default 'active',
  joined_at timestamptz not null default now(),
  invited_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint community_memberships_role_check check (
    role in ('owner', 'admin', 'moderator', 'staff', 'member', 'viewer')
  ),
  constraint community_memberships_status_check check (
    status in ('invited', 'active', 'muted', 'restricted', 'banned', 'left')
  ),
  unique (community_id, user_id)
);

create table community_messages (
  id uuid primary key default gen_random_uuid(),
  community_id uuid not null references communities(id) on delete cascade,
  channel_id uuid not null references community_channels(id) on delete cascade,
  product_id uuid not null references products(id) on delete restrict,
  author_user_id uuid not null references auth.users(id) on delete cascade,
  body text,
  message_type text not null default 'message',
  status text not null default 'active',
  reply_to_message_id uuid references community_messages(id) on delete set null,
  edited_at timestamptz,
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint community_messages_message_type_check check (
    message_type in ('message', 'announcement', 'trade_sale', 'looking_for', 'system')
  ),
  constraint community_messages_status_check check (
    status in ('active', 'hidden', 'removed', 'deleted')
  )
);

create table community_message_references (
  id uuid primary key default gen_random_uuid(),
  message_id uuid not null references community_messages(id) on delete cascade,
  community_id uuid not null references communities(id) on delete cascade,
  channel_id uuid not null references community_channels(id) on delete cascade,
  product_id uuid not null references products(id) on delete restrict,
  public_object_reference_id uuid not null references public_object_references(id) on delete restrict,
  reference_type text not null default 'shared_object',
  display_snapshot jsonb not null default '{}'::jsonb,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  constraint community_message_references_reference_type_check check (
    reference_type in (
      'shared_object',
      'trade_candidate',
      'sale_candidate',
      'comp_reference',
      'discussion_reference'
    )
  ),
  constraint community_message_references_display_snapshot_safe check (
    not public_metadata_has_private_reference_keys(display_snapshot)
  )
);

comment on table community_message_references is
  'Safe public object reference attachments for Community Core messages. This table intentionally stores snapshots from public_object_references and must not contain private inventory fields.';
comment on column community_message_references.display_snapshot is
  'Safe display snapshot only. Do not store true_basis, purchase price, profit, ROI, location, private notes, private tags, ownership history, or private transaction history.';

create table moderation_reports (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references products(id) on delete restrict,
  community_id uuid references communities(id) on delete cascade,
  channel_id uuid references community_channels(id) on delete cascade,
  message_id uuid references community_messages(id) on delete set null,
  reported_entity_table text not null,
  reported_entity_id uuid not null,
  reported_by uuid not null references auth.users(id) on delete cascade,
  reason text not null,
  details text,
  status text not null default 'open',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint moderation_reports_status_check check (
    status in ('open', 'reviewing', 'resolved', 'dismissed', 'escalated')
  ),
  constraint moderation_reports_reason_non_empty check (nullif(trim(reason), '') is not null),
  constraint moderation_reports_reported_table_non_empty check (nullif(trim(reported_entity_table), '') is not null)
);

create table moderation_actions (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references products(id) on delete restrict,
  community_id uuid references communities(id) on delete cascade,
  channel_id uuid references community_channels(id) on delete cascade,
  message_id uuid references community_messages(id) on delete set null,
  report_id uuid references moderation_reports(id) on delete set null,
  actor_user_id uuid not null references auth.users(id) on delete cascade,
  action_type text not null,
  target_entity_table text not null,
  target_entity_id uuid not null,
  reason text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint moderation_actions_action_type_check check (
    action_type in (
      'allow',
      'hide',
      'remove',
      'delete',
      'quarantine',
      'mark_sensitive',
      'mute_user',
      'restrict_user',
      'ban_from_channel',
      'ban_from_community',
      'platform_suspend',
      'escalate_to_admin'
    )
  ),
  constraint moderation_actions_target_table_non_empty check (nullif(trim(target_entity_table), '') is not null)
);

create index communities_product_id_idx on communities(product_id);
create index communities_organization_id_idx on communities(organization_id);
create index communities_owner_user_id_idx on communities(owner_user_id);
create index communities_workspace_id_idx on communities(workspace_id);
create index communities_visibility_status_idx on communities(visibility, status);
create index community_channels_community_id_idx on community_channels(community_id);
create index community_channels_product_id_idx on community_channels(product_id);
create index community_channels_visibility_status_idx on community_channels(visibility, status);
create index community_memberships_community_id_idx on community_memberships(community_id);
create index community_memberships_product_id_idx on community_memberships(product_id);
create index community_memberships_user_id_idx on community_memberships(user_id);
create index community_messages_community_channel_created_idx on community_messages(community_id, channel_id, created_at);
create index community_messages_product_id_idx on community_messages(product_id);
create index community_messages_author_user_id_idx on community_messages(author_user_id);
create index community_messages_status_idx on community_messages(status);
create index community_message_references_message_id_idx on community_message_references(message_id);
create index community_message_references_public_object_reference_id_idx on community_message_references(public_object_reference_id);
create index moderation_reports_product_id_idx on moderation_reports(product_id);
create index moderation_reports_community_id_idx on moderation_reports(community_id);
create index moderation_reports_reported_by_idx on moderation_reports(reported_by);
create index moderation_reports_status_idx on moderation_reports(status);
create index moderation_actions_product_id_idx on moderation_actions(product_id);
create index moderation_actions_community_id_idx on moderation_actions(community_id);
create index moderation_actions_report_id_idx on moderation_actions(report_id);

create trigger communities_set_updated_at before update on communities for each row execute function set_updated_at();
create trigger community_channels_set_updated_at before update on community_channels for each row execute function set_updated_at();
create trigger community_memberships_set_updated_at before update on community_memberships for each row execute function set_updated_at();
create trigger community_messages_set_updated_at before update on community_messages for each row execute function set_updated_at();
create trigger moderation_reports_set_updated_at before update on moderation_reports for each row execute function set_updated_at();

create or replace function enforce_community_core_product_consistency()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_product_id uuid;
  v_community_id uuid;
  v_channel_id uuid;
begin
  if tg_table_name = 'community_channels' then
    select product_id into v_product_id from communities where id = new.community_id;
    if v_product_id is null or new.product_id <> v_product_id then
      raise exception 'channel product_id must match parent community product_id'
        using errcode = '23514';
    end if;
  elsif tg_table_name = 'community_memberships' then
    select product_id into v_product_id from communities where id = new.community_id;
    if v_product_id is null or new.product_id <> v_product_id then
      raise exception 'membership product_id must match community product_id'
        using errcode = '23514';
    end if;
  elsif tg_table_name = 'community_messages' then
    select community_id, product_id
    into v_community_id, v_product_id
    from community_channels
    where id = new.channel_id;

    if v_community_id is null
      or new.community_id <> v_community_id
      or new.product_id <> v_product_id then
      raise exception 'message community/channel/product relationship is invalid'
        using errcode = '23514';
    end if;

    if new.reply_to_message_id is not null and not exists (
      select 1
      from community_messages
      where id = new.reply_to_message_id
        and community_id = new.community_id
        and channel_id = new.channel_id
        and product_id = new.product_id
    ) then
      raise exception 'reply_to_message_id must belong to the same channel'
        using errcode = '23514';
    end if;
  elsif tg_table_name = 'community_message_references' then
    select community_id, channel_id, product_id
    into v_community_id, v_channel_id, v_product_id
    from community_messages
    where id = new.message_id;

    if v_community_id is null
      or new.community_id <> v_community_id
      or new.channel_id <> v_channel_id
      or new.product_id <> v_product_id then
      raise exception 'message reference must match message community/channel/product'
        using errcode = '23514';
    end if;

    if not exists (
      select 1
      from public_object_references
      where id = new.public_object_reference_id
        and product_id = new.product_id
        and exposure_state = 'active'
        and visibility in ('private_reference', 'community', 'listing', 'showcase', 'trade', 'public')
    ) then
      raise exception 'active matching public object reference is required'
        using errcode = '23514';
    end if;
  end if;

  return new;
end;
$$;

create trigger community_channels_product_consistency
before insert or update on community_channels
for each row execute function enforce_community_core_product_consistency();

create trigger community_memberships_product_consistency
before insert or update on community_memberships
for each row execute function enforce_community_core_product_consistency();

create trigger community_messages_product_consistency
before insert or update on community_messages
for each row execute function enforce_community_core_product_consistency();

create trigger community_message_references_product_consistency
before insert or update on community_message_references
for each row execute function enforce_community_core_product_consistency();

create or replace function is_community_member(target_community_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from community_memberships
    where community_id = target_community_id
      and user_id = auth.uid()
      and status = 'active'
  );
$$;

create or replace function is_community_moderator(target_community_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from community_memberships
    where community_id = target_community_id
      and user_id = auth.uid()
      and status = 'active'
      and role in ('owner', 'admin', 'moderator', 'staff')
  );
$$;

create or replace function can_manage_community(target_community_id uuid)
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
        or owner_user_id = auth.uid()
        or exists (
          select 1
          from community_memberships
          where community_memberships.community_id = communities.id
            and user_id = auth.uid()
            and status = 'active'
            and role in ('owner', 'admin', 'moderator')
        )
      )
  );
$$;

create or replace function can_read_community(target_community_id uuid)
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
        or (organization_id is not null and is_organization_member(organization_id))
        or (workspace_id is not null and is_workspace_member(workspace_id))
        or owner_user_id = auth.uid()
        or is_community_member(id)
        or (
          auth.uid() is not null
          and status = 'active'
          and visibility in ('product_visible', 'public')
        )
      )
  );
$$;

create or replace function can_read_community_channel(target_channel_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from community_channels
    where id = target_channel_id
      and can_read_community(community_id)
      and (
        visibility in ('community', 'public')
        or (visibility = 'moderators' and can_manage_community(community_id))
        or (
          visibility = 'staff'
          and (
            can_manage_community(community_id)
            or exists (
              select 1
              from community_memberships
              where community_memberships.community_id = community_channels.community_id
                and user_id = auth.uid()
                and status = 'active'
                and role in ('staff', 'admin', 'owner')
            )
          )
        )
      )
  );
$$;

create or replace function can_read_community_message(target_message_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from community_messages
    where id = target_message_id
      and can_read_community_channel(channel_id)
      and (
        status = 'active'
        or can_manage_community(community_id)
      )
  );
$$;

alter table communities enable row level security;
alter table community_channels enable row level security;
alter table community_memberships enable row level security;
alter table community_messages enable row level security;
alter table community_message_references enable row level security;
alter table moderation_reports enable row level security;
alter table moderation_actions enable row level security;

create policy "authorized users read communities"
on communities
for select
using (can_read_community(id));

create policy "authorized users read community channels"
on community_channels
for select
using (can_read_community_channel(id));

create policy "authorized users read community memberships"
on community_memberships
for select
using (
  user_id = auth.uid()
  or can_manage_community(community_id)
  or is_platform_admin()
  or is_product_admin(product_id)
);

create policy "authorized users read community messages"
on community_messages
for select
using (can_read_community_message(id));

create policy "authorized users read community message references"
on community_message_references
for select
using (can_read_community_message(message_id));

create policy "authorized users read moderation reports"
on moderation_reports
for select
using (
  reported_by = auth.uid()
  or (community_id is not null and can_manage_community(community_id))
  or is_product_admin(product_id)
  or is_platform_admin()
);

create policy "authorized users read moderation actions"
on moderation_actions
for select
using (
  (community_id is not null and can_manage_community(community_id))
  or is_product_admin(product_id)
  or is_platform_admin()
);

grant select on communities to authenticated;
grant select on community_channels to authenticated;
grant select on community_memberships to authenticated;
grant select on community_messages to authenticated;
grant select on community_message_references to authenticated;
grant select on moderation_reports to authenticated;
grant select on moderation_actions to authenticated;

revoke insert, update, delete on communities from authenticated, anon;
revoke insert, update, delete on community_channels from authenticated, anon;
revoke insert, update, delete on community_memberships from authenticated, anon;
revoke insert, update, delete on community_messages from authenticated, anon;
revoke insert, update, delete on community_message_references from authenticated, anon;
revoke insert, update, delete on moderation_reports from authenticated, anon;
revoke insert, update, delete on moderation_actions from authenticated, anon;

create or replace function create_community(
  p_product_id uuid,
  p_organization_id uuid default null,
  p_workspace_id uuid default null,
  p_owner_user_id uuid default null,
  p_name text default null,
  p_slug text default null,
  p_description text default null,
  p_community_type text default 'collector_group',
  p_visibility text default 'private'
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor_user_id uuid := auth.uid();
  v_owner_user_id uuid := p_owner_user_id;
  v_community_id uuid;
begin
  if v_actor_user_id is null then
    raise exception 'authenticated user is required'
      using errcode = '42501';
  end if;

  if not exists (
    select 1 from products where id = p_product_id and status = 'active'
  ) then
    raise exception 'active product is required'
      using errcode = 'P0002';
  end if;

  if num_nonnulls(p_organization_id, p_workspace_id, p_owner_user_id) = 0 then
    v_owner_user_id := v_actor_user_id;
  elsif num_nonnulls(p_organization_id, p_workspace_id, p_owner_user_id) <> 1 then
    raise exception 'exactly one owner context is required'
      using errcode = '23514';
  end if;

  if v_owner_user_id is not null
    and v_owner_user_id <> v_actor_user_id
    and not is_platform_admin() then
    raise exception 'owner_user_id must match authenticated user'
      using errcode = '42501';
  end if;

  if p_workspace_id is not null
    and not (is_platform_admin() or is_workspace_member(p_workspace_id)) then
    raise exception 'workspace membership is required'
      using errcode = '42501';
  end if;

  if p_organization_id is not null
    and not (is_platform_admin() or is_organization_member(p_organization_id)) then
    raise exception 'organization membership is required'
      using errcode = '42501';
  end if;

  insert into communities (
    product_id,
    organization_id,
    owner_user_id,
    workspace_id,
    name,
    slug,
    description,
    community_type,
    visibility,
    created_by,
    updated_by
  ) values (
    p_product_id,
    p_organization_id,
    v_owner_user_id,
    p_workspace_id,
    trim(p_name),
    lower(trim(p_slug)),
    p_description,
    p_community_type,
    p_visibility,
    v_actor_user_id,
    v_actor_user_id
  )
  returning id into v_community_id;

  insert into community_memberships (
    community_id,
    product_id,
    user_id,
    role,
    status,
    invited_by
  ) values (
    v_community_id,
    p_product_id,
    v_actor_user_id,
    'owner',
    'active',
    v_actor_user_id
  );

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
    'community_created',
    'communities',
    v_community_id,
    v_owner_user_id,
    p_workspace_id,
    p_organization_id,
    p_product_id,
    jsonb_build_object('visibility', p_visibility, 'community_type', p_community_type)
  );

  return v_community_id;
end;
$$;

create or replace function create_community_channel(
  p_community_id uuid,
  p_name text,
  p_slug text,
  p_description text default null,
  p_channel_type text default 'conversation',
  p_visibility text default 'community',
  p_sort_order integer default 0
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor_user_id uuid := auth.uid();
  v_community communities;
  v_channel_id uuid;
begin
  if v_actor_user_id is null then
    raise exception 'authenticated user is required'
      using errcode = '42501';
  end if;

  select *
  into v_community
  from communities
  where id = p_community_id
    and status = 'active';

  if not found then
    raise exception 'active community is required'
      using errcode = 'P0002';
  end if;

  if not can_manage_community(p_community_id) then
    raise exception 'community moderation role is required'
      using errcode = '42501';
  end if;

  insert into community_channels (
    community_id,
    product_id,
    name,
    slug,
    description,
    channel_type,
    visibility,
    sort_order,
    created_by,
    updated_by
  ) values (
    v_community.id,
    v_community.product_id,
    trim(p_name),
    lower(trim(p_slug)),
    p_description,
    p_channel_type,
    p_visibility,
    coalesce(p_sort_order, 0),
    v_actor_user_id,
    v_actor_user_id
  )
  returning id into v_channel_id;

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
    'community_channel_created',
    'community_channels',
    v_channel_id,
    v_community.owner_user_id,
    v_community.workspace_id,
    v_community.organization_id,
    v_community.product_id,
    jsonb_build_object('community_id', v_community.id, 'visibility', p_visibility, 'channel_type', p_channel_type)
  );

  return v_channel_id;
end;
$$;

create or replace function join_community(p_community_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor_user_id uuid := auth.uid();
  v_community communities;
  v_membership_id uuid;
begin
  if v_actor_user_id is null then
    raise exception 'authenticated user is required'
      using errcode = '42501';
  end if;

  select *
  into v_community
  from communities
  where id = p_community_id
    and status = 'active';

  if not found then
    raise exception 'active community is required'
      using errcode = 'P0002';
  end if;

  if v_community.visibility not in ('product_visible', 'public') then
    raise exception 'community is not open to self-join'
      using errcode = '42501';
  end if;

  insert into community_memberships (
    community_id,
    product_id,
    user_id,
    role,
    status
  ) values (
    v_community.id,
    v_community.product_id,
    v_actor_user_id,
    'member',
    'active'
  )
  on conflict (community_id, user_id) do update
  set
    status = case
      when community_memberships.status in ('banned', 'restricted') then community_memberships.status
      else 'active'
    end,
    role = case
      when community_memberships.status in ('banned', 'restricted') then community_memberships.role
      else community_memberships.role
    end,
    joined_at = case
      when community_memberships.status in ('banned', 'restricted') then community_memberships.joined_at
      else now()
    end,
    updated_at = now()
  returning id into v_membership_id;

  if exists (
    select 1
    from community_memberships
    where id = v_membership_id
      and status in ('banned', 'restricted')
  ) then
    raise exception 'community membership is restricted'
      using errcode = '42501';
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
    'community_joined',
    'community_memberships',
    v_membership_id,
    v_community.owner_user_id,
    v_community.workspace_id,
    v_community.organization_id,
    v_community.product_id,
    jsonb_build_object('community_id', v_community.id)
  );

  return v_membership_id;
end;
$$;

create or replace function build_public_object_reference_snapshot(target_reference public_object_references)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select jsonb_strip_nulls(jsonb_build_object(
    'public_object_reference_id', target_reference.id,
    'product_id', target_reference.product_id,
    'category_id', target_reference.category_id,
    'asset_family_id', target_reference.asset_family_id,
    'asset_variant_id', target_reference.asset_variant_id,
    'object_type', target_reference.object_type,
    'display_title', target_reference.display_title,
    'display_subtitle', target_reference.display_subtitle,
    'display_label', target_reference.display_label,
    'display_image_url', target_reference.display_image_url,
    'condition_label', target_reference.condition_label,
    'grade_label', target_reference.grade_label,
    'value_label', target_reference.value_label,
    'visibility', target_reference.visibility,
    'public_metadata', target_reference.public_metadata
  ));
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
  v_membership community_memberships;
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

  select *
  into v_membership
  from community_memberships
  where community_id = v_community.id
    and user_id = v_actor_user_id;

  if not found or v_membership.status <> 'active' then
    raise exception 'active community membership is required'
      using errcode = '42501';
  end if;

  if v_channel.status = 'archived' then
    raise exception 'channel is archived'
      using errcode = '42501';
  end if;

  if v_channel.status = 'locked' and not can_manage_community(v_community.id) then
    raise exception 'channel is locked'
      using errcode = '42501';
  end if;

  if v_channel.visibility in ('moderators', 'staff')
    and not can_read_community_channel(v_channel.id) then
    raise exception 'channel access is required'
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

create or replace function report_community_content(
  p_product_id uuid,
  p_community_id uuid default null,
  p_channel_id uuid default null,
  p_message_id uuid default null,
  p_reported_entity_table text default null,
  p_reported_entity_id uuid default null,
  p_reason text default null,
  p_details text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor_user_id uuid := auth.uid();
  v_message community_messages;
  v_report_id uuid;
begin
  if v_actor_user_id is null then
    raise exception 'authenticated user is required'
      using errcode = '42501';
  end if;

  if nullif(trim(coalesce(p_reason, '')), '') is null then
    raise exception 'report reason is required'
      using errcode = '23514';
  end if;

  if p_message_id is not null then
    if not can_read_community_message(p_message_id) then
      raise exception 'reported message must be visible to reporter'
        using errcode = '42501';
    end if;

    select * into v_message from community_messages where id = p_message_id;

    if v_message.product_id <> p_product_id
      or (p_community_id is not null and v_message.community_id <> p_community_id)
      or (p_channel_id is not null and v_message.channel_id <> p_channel_id) then
      raise exception 'reported message scope does not match report scope'
        using errcode = '23514';
    end if;
  elsif p_community_id is not null and not can_read_community(p_community_id) then
    raise exception 'reported community must be visible to reporter'
      using errcode = '42501';
  end if;

  insert into moderation_reports (
    product_id,
    community_id,
    channel_id,
    message_id,
    reported_entity_table,
    reported_entity_id,
    reported_by,
    reason,
    details
  ) values (
    p_product_id,
    p_community_id,
    p_channel_id,
    p_message_id,
    trim(p_reported_entity_table),
    p_reported_entity_id,
    v_actor_user_id,
    trim(p_reason),
    p_details
  )
  returning id into v_report_id;

  insert into audit_events (
    actor_user_id,
    event_type,
    entity_table,
    entity_id,
    product_id,
    metadata
  ) values (
    v_actor_user_id,
    'community_content_reported',
    'moderation_reports',
    v_report_id,
    p_product_id,
    jsonb_build_object(
      'community_id', p_community_id,
      'channel_id', p_channel_id,
      'message_id', p_message_id,
      'reported_entity_table', p_reported_entity_table,
      'reported_entity_id', p_reported_entity_id
    )
  );

  return v_report_id;
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
begin
  if v_actor_user_id is null then
    raise exception 'authenticated user is required'
      using errcode = '42501';
  end if;

  if p_community_id is not null then
    if not (can_manage_community(p_community_id) or is_product_admin(p_product_id) or is_platform_admin()) then
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
    p_message_id,
    p_report_id,
    v_actor_user_id,
    p_action_type,
    trim(p_target_entity_table),
    p_target_entity_id,
    p_reason,
    coalesce(p_metadata, '{}'::jsonb)
  )
  returning id into v_action_id;

  if p_target_entity_table = 'community_messages'
    or p_message_id is not null then
    if p_action_type = 'hide' then
      update community_messages
      set status = 'hidden'
      where id = coalesce(p_message_id, p_target_entity_id);
    elsif p_action_type = 'remove' then
      update community_messages
      set status = 'removed'
      where id = coalesce(p_message_id, p_target_entity_id);
    elsif p_action_type = 'delete' then
      update community_messages
      set status = 'deleted', deleted_at = now()
      where id = coalesce(p_message_id, p_target_entity_id);
    elsif p_action_type = 'allow' then
      update community_messages
      set status = 'active'
      where id = coalesce(p_message_id, p_target_entity_id);
    end if;
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
    product_id,
    metadata
  ) values (
    v_actor_user_id,
    'community_content_moderated',
    'moderation_actions',
    v_action_id,
    p_product_id,
    jsonb_build_object(
      'community_id', p_community_id,
      'channel_id', p_channel_id,
      'message_id', p_message_id,
      'report_id', p_report_id,
      'target_entity_table', p_target_entity_table,
      'target_entity_id', p_target_entity_id,
      'action_type', p_action_type
    )
  );

  return v_action_id;
end;
$$;

revoke all on function is_community_member(uuid) from public, anon;
revoke all on function is_community_moderator(uuid) from public, anon;
revoke all on function can_manage_community(uuid) from public, anon;
revoke all on function can_read_community(uuid) from public, anon;
revoke all on function can_read_community_channel(uuid) from public, anon;
revoke all on function can_read_community_message(uuid) from public, anon;
revoke all on function build_public_object_reference_snapshot(public_object_references) from public, anon;
revoke all on function create_community(uuid, uuid, uuid, uuid, text, text, text, text, text) from public, anon;
revoke all on function create_community_channel(uuid, text, text, text, text, text, integer) from public, anon;
revoke all on function join_community(uuid) from public, anon;
revoke all on function create_community_message(uuid, text, text, uuid, uuid[]) from public, anon;
revoke all on function report_community_content(uuid, uuid, uuid, uuid, text, uuid, text, text) from public, anon;
revoke all on function moderate_community_content(uuid, uuid, uuid, uuid, uuid, text, uuid, text, text, jsonb) from public, anon;

grant execute on function create_community(uuid, uuid, uuid, uuid, text, text, text, text, text) to authenticated;
grant execute on function create_community_channel(uuid, text, text, text, text, text, integer) to authenticated;
grant execute on function join_community(uuid) to authenticated;
grant execute on function create_community_message(uuid, text, text, uuid, uuid[]) to authenticated;
grant execute on function report_community_content(uuid, uuid, uuid, uuid, text, uuid, text, text) to authenticated;
grant execute on function moderate_community_content(uuid, uuid, uuid, uuid, uuid, text, uuid, text, text, jsonb) to authenticated;
grant execute on function is_community_member(uuid) to authenticated;
grant execute on function is_community_moderator(uuid) to authenticated;
grant execute on function can_manage_community(uuid) to authenticated;
grant execute on function can_read_community(uuid) to authenticated;
grant execute on function can_read_community_channel(uuid) to authenticated;
grant execute on function can_read_community_message(uuid) to authenticated;
