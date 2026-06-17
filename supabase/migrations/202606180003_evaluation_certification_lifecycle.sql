alter type basis_event_type add value if not exists 'evaluation_cost';

create table evaluation_cases (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces(id) on delete cascade,
  product_id uuid references products(id) on delete restrict,
  organization_id uuid references organizations(id) on delete set null,
  case_type text not null,
  provider_name text,
  provider_reference text,
  status text not null default 'draft',
  opened_at timestamptz not null default now(),
  submitted_at timestamptz,
  received_at timestamptz,
  completed_at timestamptz,
  canceled_at timestamptz,
  returned_at timestamptz,
  expected_return_at timestamptz,
  total_declared_value numeric(14,2),
  total_evaluation_cost numeric(14,2) not null default 0,
  total_shipping_cost numeric(14,2) not null default 0,
  total_insurance_cost numeric(14,2) not null default 0,
  total_other_costs numeric(14,2) not null default 0,
  total_case_cost numeric(14,2) generated always as (
    total_evaluation_cost + total_shipping_cost + total_insurance_cost + total_other_costs
  ) stored,
  notes text,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint evaluation_cases_case_type_check check (
    case_type in (
      'grading',
      'authentication',
      'appraisal',
      'certification',
      'condition_review',
      'restoration_review',
      'service',
      'provenance_review',
      'other'
    )
  ),
  constraint evaluation_cases_status_check check (
    status in (
      'draft',
      'prepared',
      'submitted',
      'in_review',
      'received',
      'completed',
      'returned',
      'canceled',
      'lost',
      'on_hold'
    )
  ),
  constraint evaluation_cases_declared_value_nonnegative check (
    total_declared_value is null or total_declared_value >= 0
  ),
  constraint evaluation_cases_costs_nonnegative check (
    total_evaluation_cost >= 0
    and total_shipping_cost >= 0
    and total_insurance_cost >= 0
    and total_other_costs >= 0
  ),
  constraint evaluation_cases_metadata_safe check (
    not public_metadata_has_private_reference_keys(metadata)
  ),
  constraint evaluation_cases_timestamps_coherent check (
    (submitted_at is null or submitted_at >= opened_at)
    and (received_at is null or received_at >= opened_at)
    and (completed_at is null or completed_at >= opened_at)
    and (canceled_at is null or canceled_at >= opened_at)
    and (returned_at is null or returned_at >= opened_at)
  )
);

comment on table evaluation_cases is
  'Product-neutral Satera Core evaluation/certification cases for grading, authentication, appraisal, certification, condition review, restoration review, service, and provenance review.';
comment on column evaluation_cases.metadata is
  'Safe lifecycle metadata only. Do not store private inventory fields such as true_basis, purchase price, private notes, private tags, ownership history, or private transaction history.';

create table evaluation_case_items (
  id uuid primary key default gen_random_uuid(),
  evaluation_case_id uuid not null references evaluation_cases(id) on delete cascade,
  inventory_item_id uuid not null references inventory_items(id) on delete restrict,
  product_id uuid references products(id) on delete restrict,
  item_status text not null default 'included',
  declared_value numeric(14,2),
  allocated_evaluation_cost numeric(14,2) not null default 0,
  allocated_shipping_cost numeric(14,2) not null default 0,
  allocated_insurance_cost numeric(14,2) not null default 0,
  allocated_other_costs numeric(14,2) not null default 0,
  allocated_total_cost numeric(14,2) generated always as (
    allocated_evaluation_cost + allocated_shipping_cost + allocated_insurance_cost + allocated_other_costs
  ) stored,
  basis_increase_amount numeric(14,2) not null default 0,
  provider_item_reference text,
  result_summary text,
  result_grade text,
  result_authenticity text,
  result_certification_number text,
  result_metadata jsonb not null default '{}'::jsonb,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint evaluation_case_items_status_check check (
    item_status in (
      'included',
      'submitted',
      'in_review',
      'completed',
      'returned',
      'canceled',
      'rejected',
      'lost',
      'damaged'
    )
  ),
  constraint evaluation_case_items_declared_value_nonnegative check (
    declared_value is null or declared_value >= 0
  ),
  constraint evaluation_case_items_costs_nonnegative check (
    allocated_evaluation_cost >= 0
    and allocated_shipping_cost >= 0
    and allocated_insurance_cost >= 0
    and allocated_other_costs >= 0
  ),
  constraint evaluation_case_items_basis_nonnegative check (
    basis_increase_amount >= 0
  ),
  constraint evaluation_case_items_result_metadata_safe check (
    not public_metadata_has_private_reference_keys(result_metadata)
  )
);

comment on table evaluation_case_items is
  'Inventory items included in a product-neutral evaluation/certification case. Result fields are descriptive and do not automatically mutate basis or current value.';

create table evaluation_events (
  id uuid primary key default gen_random_uuid(),
  evaluation_case_id uuid not null references evaluation_cases(id) on delete cascade,
  evaluation_case_item_id uuid references evaluation_case_items(id) on delete cascade,
  event_type text not null,
  from_status text,
  to_status text,
  occurred_at timestamptz not null default now(),
  notes text,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  constraint evaluation_events_event_type_check check (
    event_type in (
      'case_created',
      'item_added',
      'status_changed',
      'submitted',
      'received',
      'completed',
      'returned',
      'canceled',
      'result_recorded',
      'cost_allocated',
      'basis_increase_applied',
      'note_added'
    )
  ),
  constraint evaluation_events_metadata_safe check (
    not public_metadata_has_private_reference_keys(metadata)
  )
);

comment on table evaluation_events is
  'Immutable product-neutral evaluation/certification lifecycle history.';

create table evaluation_attachments (
  id uuid primary key default gen_random_uuid(),
  evaluation_case_id uuid not null references evaluation_cases(id) on delete cascade,
  evaluation_case_item_id uuid references evaluation_case_items(id) on delete cascade,
  attachment_type text not null,
  storage_path text,
  external_url text,
  provider_asset_id text,
  title text,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  constraint evaluation_attachments_type_nonempty check (
    nullif(trim(attachment_type), '') is not null
  ),
  constraint evaluation_attachments_metadata_safe check (
    not public_metadata_has_private_reference_keys(metadata)
  )
);

comment on table evaluation_attachments is
  'Future-safe records for evaluation/certification reports, receipts, labels, images, and provider assets. Storage upload UI is not implemented by this table.';

create index evaluation_cases_workspace_id_idx on evaluation_cases(workspace_id);
create index evaluation_cases_product_id_idx on evaluation_cases(product_id);
create index evaluation_cases_status_idx on evaluation_cases(status);
create index evaluation_cases_case_type_idx on evaluation_cases(case_type);
create index evaluation_cases_provider_name_idx on evaluation_cases(provider_name);
create index evaluation_case_items_evaluation_case_id_idx on evaluation_case_items(evaluation_case_id);
create index evaluation_case_items_inventory_item_id_idx on evaluation_case_items(inventory_item_id);
create index evaluation_case_items_item_status_idx on evaluation_case_items(item_status);
create index evaluation_events_evaluation_case_id_idx on evaluation_events(evaluation_case_id);
create index evaluation_events_evaluation_case_item_id_idx on evaluation_events(evaluation_case_item_id);
create index evaluation_events_event_type_idx on evaluation_events(event_type);
create index evaluation_attachments_evaluation_case_id_idx on evaluation_attachments(evaluation_case_id);
create index evaluation_attachments_evaluation_case_item_id_idx on evaluation_attachments(evaluation_case_item_id);

create trigger evaluation_cases_set_updated_at
before update on evaluation_cases
for each row execute function set_updated_at();

create trigger evaluation_case_items_set_updated_at
before update on evaluation_case_items
for each row execute function set_updated_at();

alter table evaluation_cases enable row level security;
alter table evaluation_case_items enable row level security;
alter table evaluation_events enable row level security;
alter table evaluation_attachments enable row level security;

create policy "workspace members read evaluation cases"
on evaluation_cases
for select
using (
  is_platform_admin()
  or is_workspace_member(workspace_id)
  or (product_id is not null and is_product_admin(product_id))
);

create policy "workspace members read evaluation case items"
on evaluation_case_items
for select
using (
  is_platform_admin()
  or exists (
    select 1
    from evaluation_cases
    where evaluation_cases.id = evaluation_case_items.evaluation_case_id
      and (
        is_workspace_member(evaluation_cases.workspace_id)
        or (evaluation_cases.product_id is not null and is_product_admin(evaluation_cases.product_id))
      )
  )
);

create policy "workspace members read evaluation events"
on evaluation_events
for select
using (
  is_platform_admin()
  or exists (
    select 1
    from evaluation_cases
    where evaluation_cases.id = evaluation_events.evaluation_case_id
      and (
        is_workspace_member(evaluation_cases.workspace_id)
        or (evaluation_cases.product_id is not null and is_product_admin(evaluation_cases.product_id))
      )
  )
);

create policy "workspace members read evaluation attachments"
on evaluation_attachments
for select
using (
  is_platform_admin()
  or exists (
    select 1
    from evaluation_cases
    where evaluation_cases.id = evaluation_attachments.evaluation_case_id
      and (
        is_workspace_member(evaluation_cases.workspace_id)
        or (evaluation_cases.product_id is not null and is_product_admin(evaluation_cases.product_id))
      )
  )
);

grant select on evaluation_cases to authenticated;
grant select on evaluation_case_items to authenticated;
grant select on evaluation_events to authenticated;
grant select on evaluation_attachments to authenticated;
revoke insert, update, delete on evaluation_cases from authenticated, anon;
revoke insert, update, delete on evaluation_case_items from authenticated, anon;
revoke insert, update, delete on evaluation_events from authenticated, anon;
revoke insert, update, delete on evaluation_attachments from authenticated, anon;

create or replace function create_evaluation_case(
  p_workspace_id uuid,
  p_product_id uuid default null,
  p_case_type text default null,
  p_provider_name text default null,
  p_provider_reference text default null,
  p_opened_at timestamptz default now(),
  p_expected_return_at timestamptz default null,
  p_total_declared_value numeric default null,
  p_total_evaluation_cost numeric default 0,
  p_total_shipping_cost numeric default 0,
  p_total_insurance_cost numeric default 0,
  p_total_other_costs numeric default 0,
  p_notes text default null,
  p_metadata jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor_user_id uuid := auth.uid();
  v_case_id uuid;
  v_opened_at timestamptz := coalesce(p_opened_at, now());
  v_metadata jsonb := coalesce(p_metadata, '{}'::jsonb);
begin
  if v_actor_user_id is null then
    raise exception 'authenticated user is required'
      using errcode = '42501';
  end if;

  if p_workspace_id is null then
    raise exception 'workspace is required'
      using errcode = '23502';
  end if;

  if not exists (select 1 from workspaces where id = p_workspace_id) then
    raise exception 'workspace not found'
      using errcode = 'P0002';
  end if;

  if not is_workspace_member(p_workspace_id) and not is_platform_admin() then
    raise exception 'workspace membership is required to create evaluation case'
      using errcode = '42501';
  end if;

  if p_product_id is not null and not exists (
    select 1 from products where id = p_product_id and status = 'active'
  ) then
    raise exception 'active product is required when product_id is provided'
      using errcode = '23514';
  end if;

  if p_case_type is null or p_case_type not in (
    'grading',
    'authentication',
    'appraisal',
    'certification',
    'condition_review',
    'restoration_review',
    'service',
    'provenance_review',
    'other'
  ) then
    raise exception 'invalid evaluation case_type'
      using errcode = '23514';
  end if;

  if coalesce(p_total_evaluation_cost, 0) < 0
    or coalesce(p_total_shipping_cost, 0) < 0
    or coalesce(p_total_insurance_cost, 0) < 0
    or coalesce(p_total_other_costs, 0) < 0 then
    raise exception 'evaluation case cost inputs cannot be negative'
      using errcode = '22003';
  end if;

  if p_total_declared_value is not null and p_total_declared_value < 0 then
    raise exception 'declared value cannot be negative'
      using errcode = '22003';
  end if;

  perform assert_public_reference_metadata_safe(v_metadata);

  insert into evaluation_cases (
    workspace_id,
    product_id,
    case_type,
    provider_name,
    provider_reference,
    opened_at,
    expected_return_at,
    total_declared_value,
    total_evaluation_cost,
    total_shipping_cost,
    total_insurance_cost,
    total_other_costs,
    notes,
    metadata,
    created_by
  ) values (
    p_workspace_id,
    p_product_id,
    p_case_type,
    p_provider_name,
    p_provider_reference,
    v_opened_at,
    p_expected_return_at,
    p_total_declared_value,
    coalesce(p_total_evaluation_cost, 0),
    coalesce(p_total_shipping_cost, 0),
    coalesce(p_total_insurance_cost, 0),
    coalesce(p_total_other_costs, 0),
    p_notes,
    v_metadata,
    v_actor_user_id
  )
  returning id into v_case_id;

  insert into evaluation_events (
    evaluation_case_id,
    event_type,
    to_status,
    occurred_at,
    notes,
    metadata,
    created_by
  ) values (
    v_case_id,
    'case_created',
    'draft',
    v_opened_at,
    p_notes,
    jsonb_build_object('case_type', p_case_type, 'provider_name', p_provider_name),
    v_actor_user_id
  );

  insert into audit_events (
    actor_user_id,
    event_type,
    entity_table,
    entity_id,
    workspace_id,
    product_id,
    metadata
  ) values (
    v_actor_user_id,
    'evaluation_case_created',
    'evaluation_cases',
    v_case_id,
    p_workspace_id,
    p_product_id,
    jsonb_build_object(
      'case_type', p_case_type,
      'provider_name', p_provider_name,
      'total_case_cost',
      coalesce(p_total_evaluation_cost, 0)
        + coalesce(p_total_shipping_cost, 0)
        + coalesce(p_total_insurance_cost, 0)
        + coalesce(p_total_other_costs, 0)
    )
  );

  return v_case_id;
end;
$$;

create or replace function add_evaluation_case_item(
  p_evaluation_case_id uuid,
  p_inventory_item_id uuid,
  p_declared_value numeric default null,
  p_allocated_evaluation_cost numeric default 0,
  p_allocated_shipping_cost numeric default 0,
  p_allocated_insurance_cost numeric default 0,
  p_allocated_other_costs numeric default 0,
  p_provider_item_reference text default null,
  p_notes text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor_user_id uuid := auth.uid();
  v_case evaluation_cases;
  v_inventory inventory_items;
  v_case_item_id uuid;
begin
  if v_actor_user_id is null then
    raise exception 'authenticated user is required'
      using errcode = '42501';
  end if;

  select *
  into v_case
  from evaluation_cases
  where id = p_evaluation_case_id;

  if not found then
    raise exception 'evaluation case not found'
      using errcode = 'P0002';
  end if;

  if not is_workspace_member(v_case.workspace_id) and not is_platform_admin() then
    raise exception 'workspace membership is required to add evaluation case item'
      using errcode = '42501';
  end if;

  select *
  into v_inventory
  from inventory_items
  where id = p_inventory_item_id;

  if not found then
    raise exception 'inventory item not found'
      using errcode = 'P0002';
  end if;

  if v_inventory.workspace_id is distinct from v_case.workspace_id then
    raise exception 'inventory item must belong to the evaluation case workspace'
      using errcode = '23514';
  end if;

  if coalesce(p_allocated_evaluation_cost, 0) < 0
    or coalesce(p_allocated_shipping_cost, 0) < 0
    or coalesce(p_allocated_insurance_cost, 0) < 0
    or coalesce(p_allocated_other_costs, 0) < 0 then
    raise exception 'evaluation item cost inputs cannot be negative'
      using errcode = '22003';
  end if;

  if p_declared_value is not null and p_declared_value < 0 then
    raise exception 'declared value cannot be negative'
      using errcode = '22003';
  end if;

  insert into evaluation_case_items (
    evaluation_case_id,
    inventory_item_id,
    product_id,
    declared_value,
    allocated_evaluation_cost,
    allocated_shipping_cost,
    allocated_insurance_cost,
    allocated_other_costs,
    provider_item_reference,
    notes
  ) values (
    v_case.id,
    v_inventory.id,
    v_case.product_id,
    p_declared_value,
    coalesce(p_allocated_evaluation_cost, 0),
    coalesce(p_allocated_shipping_cost, 0),
    coalesce(p_allocated_insurance_cost, 0),
    coalesce(p_allocated_other_costs, 0),
    p_provider_item_reference,
    p_notes
  )
  returning id into v_case_item_id;

  insert into evaluation_events (
    evaluation_case_id,
    evaluation_case_item_id,
    event_type,
    to_status,
    notes,
    metadata,
    created_by
  ) values (
    v_case.id,
    v_case_item_id,
    'item_added',
    'included',
    p_notes,
    jsonb_build_object(
      'inventory_item_id', v_inventory.id,
      'allocated_total_cost',
      coalesce(p_allocated_evaluation_cost, 0)
        + coalesce(p_allocated_shipping_cost, 0)
        + coalesce(p_allocated_insurance_cost, 0)
        + coalesce(p_allocated_other_costs, 0)
    ),
    v_actor_user_id
  );

  insert into audit_events (
    actor_user_id,
    event_type,
    entity_table,
    entity_id,
    workspace_id,
    product_id,
    metadata
  ) values (
    v_actor_user_id,
    'evaluation_case_item_added',
    'evaluation_case_items',
    v_case_item_id,
    v_case.workspace_id,
    v_case.product_id,
    jsonb_build_object(
      'evaluation_case_id', v_case.id,
      'inventory_item_id', v_inventory.id
    )
  );

  return v_case_item_id;
end;
$$;

create or replace function update_evaluation_case_status(
  p_evaluation_case_id uuid,
  p_status text,
  p_occurred_at timestamptz default now(),
  p_notes text default null,
  p_metadata jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor_user_id uuid := auth.uid();
  v_case evaluation_cases;
  v_occurred_at timestamptz := coalesce(p_occurred_at, now());
  v_metadata jsonb := coalesce(p_metadata, '{}'::jsonb);
begin
  if v_actor_user_id is null then
    raise exception 'authenticated user is required'
      using errcode = '42501';
  end if;

  if p_status is null or p_status not in (
    'draft',
    'prepared',
    'submitted',
    'in_review',
    'received',
    'completed',
    'returned',
    'canceled',
    'lost',
    'on_hold'
  ) then
    raise exception 'invalid evaluation case status'
      using errcode = '23514';
  end if;

  perform assert_public_reference_metadata_safe(v_metadata);

  select *
  into v_case
  from evaluation_cases
  where id = p_evaluation_case_id
  for update;

  if not found then
    raise exception 'evaluation case not found'
      using errcode = 'P0002';
  end if;

  if not is_workspace_member(v_case.workspace_id) and not is_platform_admin() then
    raise exception 'workspace membership is required to update evaluation case'
      using errcode = '42501';
  end if;

  update evaluation_cases
  set
    status = p_status,
    submitted_at = case when p_status = 'submitted' then coalesce(submitted_at, v_occurred_at) else submitted_at end,
    received_at = case when p_status = 'received' then coalesce(received_at, v_occurred_at) else received_at end,
    completed_at = case when p_status = 'completed' then coalesce(completed_at, v_occurred_at) else completed_at end,
    returned_at = case when p_status = 'returned' then coalesce(returned_at, v_occurred_at) else returned_at end,
    canceled_at = case when p_status = 'canceled' then coalesce(canceled_at, v_occurred_at) else canceled_at end
  where id = v_case.id;

  insert into evaluation_events (
    evaluation_case_id,
    event_type,
    from_status,
    to_status,
    occurred_at,
    notes,
    metadata,
    created_by
  ) values (
    v_case.id,
    'status_changed',
    v_case.status,
    p_status,
    v_occurred_at,
    p_notes,
    v_metadata,
    v_actor_user_id
  );

  insert into audit_events (
    actor_user_id,
    event_type,
    entity_table,
    entity_id,
    workspace_id,
    product_id,
    metadata
  ) values (
    v_actor_user_id,
    'evaluation_case_status_updated',
    'evaluation_cases',
    v_case.id,
    v_case.workspace_id,
    v_case.product_id,
    jsonb_build_object('from_status', v_case.status, 'to_status', p_status)
  );

  return v_case.id;
end;
$$;

create or replace function record_evaluation_result(
  p_evaluation_case_item_id uuid,
  p_item_status text default 'completed',
  p_result_summary text default null,
  p_result_grade text default null,
  p_result_authenticity text default null,
  p_result_certification_number text default null,
  p_result_metadata jsonb default '{}'::jsonb,
  p_notes text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor_user_id uuid := auth.uid();
  v_item evaluation_case_items;
  v_case evaluation_cases;
  v_metadata jsonb := coalesce(p_result_metadata, '{}'::jsonb);
begin
  if v_actor_user_id is null then
    raise exception 'authenticated user is required'
      using errcode = '42501';
  end if;

  if p_item_status is null or p_item_status not in (
    'included',
    'submitted',
    'in_review',
    'completed',
    'returned',
    'canceled',
    'rejected',
    'lost',
    'damaged'
  ) then
    raise exception 'invalid evaluation case item status'
      using errcode = '23514';
  end if;

  perform assert_public_reference_metadata_safe(v_metadata);

  select *
  into v_item
  from evaluation_case_items
  where id = p_evaluation_case_item_id
  for update;

  if not found then
    raise exception 'evaluation case item not found'
      using errcode = 'P0002';
  end if;

  select *
  into v_case
  from evaluation_cases
  where id = v_item.evaluation_case_id;

  if not is_workspace_member(v_case.workspace_id) and not is_platform_admin() then
    raise exception 'workspace membership is required to record evaluation result'
      using errcode = '42501';
  end if;

  update evaluation_case_items
  set
    item_status = p_item_status,
    result_summary = p_result_summary,
    result_grade = p_result_grade,
    result_authenticity = p_result_authenticity,
    result_certification_number = p_result_certification_number,
    result_metadata = v_metadata,
    notes = coalesce(p_notes, notes)
  where id = v_item.id;

  insert into evaluation_events (
    evaluation_case_id,
    evaluation_case_item_id,
    event_type,
    from_status,
    to_status,
    notes,
    metadata,
    created_by
  ) values (
    v_case.id,
    v_item.id,
    'result_recorded',
    v_item.item_status,
    p_item_status,
    p_notes,
    jsonb_build_object(
      'result_grade', p_result_grade,
      'result_authenticity', p_result_authenticity,
      'result_certification_number', p_result_certification_number
    ) || v_metadata,
    v_actor_user_id
  );

  insert into audit_events (
    actor_user_id,
    event_type,
    entity_table,
    entity_id,
    workspace_id,
    product_id,
    metadata
  ) values (
    v_actor_user_id,
    'evaluation_result_recorded',
    'evaluation_case_items',
    v_item.id,
    v_case.workspace_id,
    v_case.product_id,
    jsonb_build_object(
      'evaluation_case_id', v_case.id,
      'inventory_item_id', v_item.inventory_item_id,
      'item_status', p_item_status
    )
  );

  return v_item.id;
end;
$$;

create or replace function apply_evaluation_basis_increase(
  p_evaluation_case_item_id uuid,
  p_basis_increase_amount numeric,
  p_notes text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor_user_id uuid := auth.uid();
  v_item evaluation_case_items;
  v_case evaluation_cases;
  v_inventory inventory_items;
  v_amount numeric := round(coalesce(p_basis_increase_amount, 0), 2);
  v_previous_basis numeric;
  v_new_basis numeric;
begin
  if v_actor_user_id is null then
    raise exception 'authenticated user is required'
      using errcode = '42501';
  end if;

  if p_basis_increase_amount is null then
    raise exception 'basis increase amount is required'
      using errcode = '23502';
  end if;

  if v_amount < 0 then
    raise exception 'basis increase amount cannot be negative'
      using errcode = '22003';
  end if;

  select *
  into v_item
  from evaluation_case_items
  where id = p_evaluation_case_item_id
  for update;

  if not found then
    raise exception 'evaluation case item not found'
      using errcode = 'P0002';
  end if;

  select *
  into v_case
  from evaluation_cases
  where id = v_item.evaluation_case_id;

  if not is_workspace_member(v_case.workspace_id) and not is_platform_admin() then
    raise exception 'workspace membership is required to apply evaluation basis increase'
      using errcode = '42501';
  end if;

  select *
  into v_inventory
  from inventory_items
  where id = v_item.inventory_item_id
  for update;

  if not found then
    raise exception 'inventory item not found'
      using errcode = 'P0002';
  end if;

  if v_inventory.workspace_id is distinct from v_case.workspace_id then
    raise exception 'inventory item must belong to the evaluation case workspace'
      using errcode = '23514';
  end if;

  if v_inventory.true_basis is null then
    raise exception 'inventory item is missing true_basis'
      using errcode = '23514';
  end if;

  v_previous_basis := v_inventory.true_basis;
  v_new_basis := v_previous_basis + v_amount;

  update evaluation_case_items
  set basis_increase_amount = basis_increase_amount + v_amount
  where id = v_item.id;

  update inventory_items
  set
    true_basis = v_new_basis,
    updated_by = v_actor_user_id,
    updated_at = now()
  where id = v_inventory.id;

  insert into basis_events (
    inventory_item_id,
    transaction_id,
    basis_event_type,
    amount,
    previous_basis,
    new_basis,
    calculation_method,
    calculation_inputs,
    reason,
    created_by
  ) values (
    v_inventory.id,
    null,
    'evaluation_cost',
    v_amount,
    v_previous_basis,
    v_new_basis,
    'explicit_evaluation_basis_increase',
    jsonb_build_object(
      'evaluation_case_id', v_case.id,
      'evaluation_case_item_id', v_item.id,
      'allocated_total_cost', v_item.allocated_total_cost,
      'requested_basis_increase_amount', v_amount
    ),
    coalesce(p_notes, 'Evaluation/certification cost explicitly capitalized into true_basis.'),
    v_actor_user_id
  );

  insert into evaluation_events (
    evaluation_case_id,
    evaluation_case_item_id,
    event_type,
    from_status,
    to_status,
    notes,
    metadata,
    created_by
  ) values (
    v_case.id,
    v_item.id,
    'basis_increase_applied',
    v_item.item_status,
    v_item.item_status,
    p_notes,
    jsonb_build_object(
      'inventory_item_id', v_inventory.id,
      'basis_increase_amount', v_amount,
      'previous_basis', v_previous_basis,
      'new_basis', v_new_basis
    ),
    v_actor_user_id
  );

  insert into audit_events (
    actor_user_id,
    event_type,
    entity_table,
    entity_id,
    workspace_id,
    product_id,
    metadata
  ) values (
    v_actor_user_id,
    'evaluation_basis_increase_applied',
    'evaluation_case_items',
    v_item.id,
    v_case.workspace_id,
    v_case.product_id,
    jsonb_build_object(
      'evaluation_case_id', v_case.id,
      'inventory_item_id', v_inventory.id,
      'basis_increase_amount', v_amount,
      'previous_basis', v_previous_basis,
      'new_basis', v_new_basis
    )
  );

  return v_item.id;
end;
$$;

revoke all on function create_evaluation_case(
  uuid,
  uuid,
  text,
  text,
  text,
  timestamptz,
  timestamptz,
  numeric,
  numeric,
  numeric,
  numeric,
  numeric,
  text,
  jsonb
) from public, anon;

revoke all on function add_evaluation_case_item(
  uuid,
  uuid,
  numeric,
  numeric,
  numeric,
  numeric,
  numeric,
  text,
  text
) from public, anon;

revoke all on function update_evaluation_case_status(
  uuid,
  text,
  timestamptz,
  text,
  jsonb
) from public, anon;

revoke all on function record_evaluation_result(
  uuid,
  text,
  text,
  text,
  text,
  text,
  jsonb,
  text
) from public, anon;

revoke all on function apply_evaluation_basis_increase(
  uuid,
  numeric,
  text
) from public, anon;

grant execute on function create_evaluation_case(
  uuid,
  uuid,
  text,
  text,
  text,
  timestamptz,
  timestamptz,
  numeric,
  numeric,
  numeric,
  numeric,
  numeric,
  text,
  jsonb
) to authenticated;

grant execute on function add_evaluation_case_item(
  uuid,
  uuid,
  numeric,
  numeric,
  numeric,
  numeric,
  numeric,
  text,
  text
) to authenticated;

grant execute on function update_evaluation_case_status(
  uuid,
  text,
  timestamptz,
  text,
  jsonb
) to authenticated;

grant execute on function record_evaluation_result(
  uuid,
  text,
  text,
  text,
  text,
  text,
  jsonb,
  text
) to authenticated;

grant execute on function apply_evaluation_basis_increase(
  uuid,
  numeric,
  text
) to authenticated;
