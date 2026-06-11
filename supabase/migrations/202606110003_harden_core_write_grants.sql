alter function create_starting_inventory_transaction(
  uuid,
  uuid,
  uuid,
  uuid,
  uuid,
  condition_type,
  inventory_status,
  inventory_availability,
  inventory_intent,
  uuid,
  numeric,
  timestamptz,
  text,
  timestamptz,
  text
) security definer;

alter function create_starting_inventory_transaction(
  uuid,
  uuid,
  uuid,
  uuid,
  uuid,
  condition_type,
  inventory_status,
  inventory_availability,
  inventory_intent,
  uuid,
  numeric,
  timestamptz,
  text,
  timestamptz,
  text
) set search_path = public;

alter function create_purchase_transaction(
  uuid,
  uuid,
  numeric,
  numeric,
  numeric,
  numeric,
  numeric,
  uuid,
  uuid,
  uuid,
  condition_type,
  inventory_status,
  inventory_availability,
  inventory_intent,
  uuid,
  timestamptz,
  text,
  timestamptz,
  text,
  text
) security definer;

alter function create_purchase_transaction(
  uuid,
  uuid,
  numeric,
  numeric,
  numeric,
  numeric,
  numeric,
  uuid,
  uuid,
  uuid,
  condition_type,
  inventory_status,
  inventory_availability,
  inventory_intent,
  uuid,
  timestamptz,
  text,
  timestamptz,
  text,
  text
) set search_path = public;

revoke insert, update, delete on
  inventory_items,
  transactions,
  transaction_lines,
  ownership_events,
  basis_events,
  basis_lineage_edges,
  audit_events
from authenticated;

grant select on
  inventory_items,
  transactions,
  transaction_lines,
  ownership_events,
  basis_events,
  basis_lineage_edges,
  audit_events
to authenticated;

create or replace function update_inventory_item_safe_fields(
  p_target_inventory_item_id uuid,
  p_new_notes text default null,
  p_new_intent inventory_intent default null,
  p_new_location_id uuid default null,
  p_new_availability inventory_availability default null,
  p_update_notes boolean default false,
  p_update_intent boolean default false,
  p_update_location_id boolean default false,
  p_update_availability boolean default false
)
returns inventory_items
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor_user_id uuid := auth.uid();
  v_existing inventory_items;
  v_updated inventory_items;
begin
  if v_actor_user_id is null then
    raise exception 'authenticated user is required'
      using errcode = '42501';
  end if;

  select *
  into v_existing
  from inventory_items
  where id = p_target_inventory_item_id
  for update;

  if not found then
    raise exception 'inventory item not found'
      using errcode = 'P0002';
  end if;

  if not coalesce((
    is_platform_admin()
    or v_existing.owner_user_id = v_actor_user_id
    or (v_existing.workspace_id is not null and is_workspace_member(v_existing.workspace_id))
    or (v_existing.organization_id is not null and is_organization_member(v_existing.organization_id))
  ), false) then
    raise exception 'inventory item access is required'
      using errcode = '42501';
  end if;

  update inventory_items
  set
    notes = case when p_update_notes then p_new_notes else notes end,
    intent = case when p_update_intent then coalesce(p_new_intent, intent) else intent end,
    location_id = case when p_update_location_id then p_new_location_id else location_id end,
    availability = case when p_update_availability then coalesce(p_new_availability, availability) else availability end,
    updated_by = v_actor_user_id,
    updated_at = now()
  where id = p_target_inventory_item_id
  returning * into v_updated;

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
    'inventory_safe_fields_updated',
    'inventory_items',
    v_updated.id,
    v_updated.owner_user_id,
    v_updated.workspace_id,
    v_updated.organization_id,
    null,
    jsonb_build_object(
      'updated_fields',
      jsonb_strip_nulls(jsonb_build_object(
        'notes', case when p_update_notes then true else null end,
        'intent', case when p_update_intent then true else null end,
        'location_id', case when p_update_location_id then true else null end,
        'availability', case when p_update_availability then true else null end
      ))
    )
  );

  return v_updated;
end;
$$;

revoke all on function update_inventory_item_safe_fields(
  uuid,
  text,
  inventory_intent,
  uuid,
  inventory_availability,
  boolean,
  boolean,
  boolean,
  boolean
) from public, anon;

grant execute on function update_inventory_item_safe_fields(
  uuid,
  text,
  inventory_intent,
  uuid,
  inventory_availability,
  boolean,
  boolean,
  boolean,
  boolean
) to authenticated;
