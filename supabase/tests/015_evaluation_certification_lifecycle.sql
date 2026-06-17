-- Verifies product-neutral evaluation/certification lifecycle records, RPCs,
-- RLS, direct-write hardening, and explicit basis increase behavior.

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

create temp table evaluation_test_ids (
  key text primary key,
  id uuid not null
) on commit drop;

insert into evaluation_test_ids
select 'known_basis_item', inventory_item_id
from create_starting_inventory_transaction(
  p_workspace_id => '30000000-0000-0000-0000-000000000001',
  p_category_id => '20000000-0000-0000-0000-000000000001',
  p_asset_variant_id => '60000000-0000-0000-0000-000000000001',
  p_condition_type => 'raw',
  p_initial_basis => 100,
  p_acquired_at => '2026-06-01T00:00:00Z',
  p_transaction_date => '2026-06-01T00:00:00Z',
  p_source => 'evaluation verification'
);

insert into evaluation_test_ids
select 'unknown_basis_item', inventory_item_id
from create_starting_inventory_transaction(
  p_workspace_id => '30000000-0000-0000-0000-000000000001',
  p_category_id => '20000000-0000-0000-0000-000000000001',
  p_asset_variant_id => '60000000-0000-0000-0000-000000000001',
  p_condition_type => 'raw',
  p_initial_basis => null,
  p_acquired_at => '2026-06-01T00:00:00Z',
  p_transaction_date => '2026-06-01T00:00:00Z',
  p_source => 'evaluation verification'
);

insert into evaluation_test_ids
select 'case', create_evaluation_case(
  p_workspace_id => '30000000-0000-0000-0000-000000000001',
  p_product_id => '10000000-0000-0000-0000-000000000001',
  p_case_type => 'grading',
  p_provider_name => 'Manual Provider',
  p_provider_reference => 'CASE-1',
  p_opened_at => '2026-06-02T00:00:00Z',
  p_expected_return_at => '2026-07-02T00:00:00Z',
  p_total_declared_value => 500,
  p_total_evaluation_cost => 40,
  p_total_shipping_cost => 10,
  p_total_insurance_cost => 5,
  p_total_other_costs => 2,
  p_notes => 'Evaluation verification case.',
  p_metadata => '{"safe_context":"verification"}'::jsonb
);

select pg_temp.satera_assert(
  (
    select c.workspace_id = '30000000-0000-0000-0000-000000000001'
      and c.product_id = '10000000-0000-0000-0000-000000000001'
      and c.case_type = 'grading'
      and c.provider_name = 'Manual Provider'
      and c.provider_reference = 'CASE-1'
      and c.status = 'draft'
      and c.total_case_cost = 57
      and exists (
        select 1 from evaluation_events e
        where e.evaluation_case_id = c.id
          and e.event_type = 'case_created'
      )
      and exists (
        select 1 from audit_events ae
        where ae.entity_table = 'evaluation_cases'
          and ae.entity_id = c.id
          and ae.event_type = 'evaluation_case_created'
      )
    from evaluation_cases c
    where c.id = (select id from evaluation_test_ids where key = 'case')
  ),
  'user can create evaluation case, with case_created evaluation event and audit event.'
);

insert into evaluation_test_ids
select 'case_item', add_evaluation_case_item(
  p_evaluation_case_id => (select id from evaluation_test_ids where key = 'case'),
  p_inventory_item_id => (select id from evaluation_test_ids where key = 'known_basis_item'),
  p_declared_value => 250,
  p_allocated_evaluation_cost => 25,
  p_allocated_shipping_cost => 5,
  p_allocated_insurance_cost => 3,
  p_allocated_other_costs => 2,
  p_provider_item_reference => 'ITEM-1',
  p_notes => 'Evaluation item.'
);

select pg_temp.satera_assert(
  (
    select i.inventory_item_id = (select id from evaluation_test_ids where key = 'known_basis_item')
      and i.product_id = '10000000-0000-0000-0000-000000000001'
      and i.item_status = 'included'
      and i.allocated_total_cost = 35
      and exists (
        select 1 from evaluation_events e
        where e.evaluation_case_item_id = i.id
          and e.event_type = 'item_added'
      )
      and exists (
        select 1 from audit_events ae
        where ae.entity_table = 'evaluation_case_items'
          and ae.entity_id = i.id
          and ae.event_type = 'evaluation_case_item_added'
      )
    from evaluation_case_items i
    where i.id = (select id from evaluation_test_ids where key = 'case_item')
  ),
  'user can add owned workspace inventory item to evaluation case with item_added event.'
);

select pg_temp.satera_expect_rejected(
  format(
    $sql$
      select add_evaluation_case_item(
        p_evaluation_case_id => %L::uuid,
        p_inventory_item_id => '70000000-0000-0000-0000-000000000001'
      )
    $sql$,
    (select id from evaluation_test_ids where key = 'case')
  ),
  'cannot add inventory item from another owner context/workspace.'
);

select pg_temp.satera_expect_rejected(
  $sql$
    select create_evaluation_case(
      p_workspace_id => '30000000-0000-0000-0000-000000000001',
      p_case_type => 'grading',
      p_total_evaluation_cost => -1
    )
  $sql$,
  'negative evaluation case costs are rejected.'
);

select pg_temp.satera_expect_rejected(
  $sql$
    select create_evaluation_case(
      p_workspace_id => '30000000-0000-0000-0000-000000000001',
      p_case_type => 'unsupported'
    )
  $sql$,
  'invalid case_type is rejected.'
);

select pg_temp.satera_expect_rejected(
  format(
    $sql$
      select add_evaluation_case_item(
        p_evaluation_case_id => %L::uuid,
        p_inventory_item_id => %L::uuid,
        p_allocated_evaluation_cost => -1
      )
    $sql$,
    (select id from evaluation_test_ids where key = 'case'),
    (select id from evaluation_test_ids where key = 'known_basis_item')
  ),
  'negative evaluation case item costs are rejected.'
);

select update_evaluation_case_status(
  p_evaluation_case_id => (select id from evaluation_test_ids where key = 'case'),
  p_status => 'submitted',
  p_occurred_at => '2026-06-03T00:00:00Z',
  p_notes => 'Submitted.'
);

select update_evaluation_case_status(
  p_evaluation_case_id => (select id from evaluation_test_ids where key = 'case'),
  p_status => 'in_review',
  p_occurred_at => '2026-06-04T00:00:00Z'
);

select update_evaluation_case_status(
  p_evaluation_case_id => (select id from evaluation_test_ids where key = 'case'),
  p_status => 'completed',
  p_occurred_at => '2026-06-05T00:00:00Z'
);

select update_evaluation_case_status(
  p_evaluation_case_id => (select id from evaluation_test_ids where key = 'case'),
  p_status => 'returned',
  p_occurred_at => '2026-06-06T00:00:00Z'
);

select pg_temp.satera_assert(
  (
    select c.status = 'returned'
      and c.submitted_at = '2026-06-03T00:00:00Z'
      and c.completed_at = '2026-06-05T00:00:00Z'
      and c.returned_at = '2026-06-06T00:00:00Z'
      and (
        select count(*)
        from evaluation_events e
        where e.evaluation_case_id = c.id
          and e.event_type = 'status_changed'
      ) = 4
    from evaluation_cases c
    where c.id = (select id from evaluation_test_ids where key = 'case')
  ),
  'case status can move through submitted, in_review, completed, and returned with events.'
);

select record_evaluation_result(
  p_evaluation_case_item_id => (select id from evaluation_test_ids where key = 'case_item'),
  p_item_status => 'completed',
  p_result_summary => 'Authenticated and certified.',
  p_result_grade => '10',
  p_result_authenticity => 'authentic',
  p_result_certification_number => 'CERT-123',
  p_result_metadata => '{"safe_result":"ok"}'::jsonb,
  p_notes => 'Result recorded.'
);

select pg_temp.satera_assert(
  (
    select i.item_status = 'completed'
      and i.result_summary = 'Authenticated and certified.'
      and i.result_grade = '10'
      and i.result_authenticity = 'authentic'
      and i.result_certification_number = 'CERT-123'
      and inv.true_basis = 100
      and inv.current_value_snapshot_id is null
      and exists (
        select 1 from evaluation_events e
        where e.evaluation_case_item_id = i.id
          and e.event_type = 'result_recorded'
      )
    from evaluation_case_items i
    join inventory_items inv on inv.id = i.inventory_item_id
    where i.id = (select id from evaluation_test_ids where key = 'case_item')
  ),
  'recording a result updates result fields but does not update true_basis or current_value.'
);

select apply_evaluation_basis_increase(
  p_evaluation_case_item_id => (select id from evaluation_test_ids where key = 'case_item'),
  p_basis_increase_amount => 35,
  p_notes => 'Capitalize explicit evaluation costs.'
);

select pg_temp.satera_assert(
  (
    select i.basis_increase_amount = 35
      and inv.true_basis = 135
      and inv.current_value_snapshot_id is null
      and exists (
        select 1 from basis_events be
        where be.inventory_item_id = inv.id
          and be.basis_event_type = 'evaluation_cost'
          and be.amount = 35
          and be.previous_basis = 100
          and be.new_basis = 135
      )
      and exists (
        select 1 from evaluation_events e
        where e.evaluation_case_item_id = i.id
          and e.event_type = 'basis_increase_applied'
      )
      and exists (
        select 1 from audit_events ae
        where ae.entity_table = 'evaluation_case_items'
          and ae.entity_id = i.id
          and ae.event_type = 'evaluation_basis_increase_applied'
      )
    from evaluation_case_items i
    join inventory_items inv on inv.id = i.inventory_item_id
    where i.id = (select id from evaluation_test_ids where key = 'case_item')
  ),
  'explicit basis increase updates true_basis and creates basis, evaluation, and audit events without updating current_value.'
);

select pg_temp.satera_expect_rejected(
  format(
    $sql$
      select apply_evaluation_basis_increase(
        p_evaluation_case_item_id => %L::uuid,
        p_basis_increase_amount => -1
      )
    $sql$,
    (select id from evaluation_test_ids where key = 'case_item')
  ),
  'negative evaluation basis increase is rejected.'
);

insert into evaluation_test_ids
select 'unknown_basis_case_item', add_evaluation_case_item(
  p_evaluation_case_id => (select id from evaluation_test_ids where key = 'case'),
  p_inventory_item_id => (select id from evaluation_test_ids where key = 'unknown_basis_item')
);

select pg_temp.satera_expect_rejected(
  format(
    $sql$
      select apply_evaluation_basis_increase(
        p_evaluation_case_item_id => %L::uuid,
        p_basis_increase_amount => 10
      )
    $sql$,
    (select id from evaluation_test_ids where key = 'unknown_basis_case_item')
  ),
  'basis increase rejects item with true_basis null.'
);

select pg_temp.satera_expect_rejected(
  $sql$
    insert into evaluation_cases (
      workspace_id,
      case_type,
      created_by
    ) values (
      '30000000-0000-0000-0000-000000000001',
      'grading',
      auth.uid()
    )
  $sql$,
  'direct authenticated inserts to evaluation_cases are blocked.'
);

select pg_temp.satera_expect_rejected(
  format(
    $sql$
      update evaluation_case_items
      set result_grade = '9'
      where id = %L::uuid
    $sql$,
    (select id from evaluation_test_ids where key = 'case_item')
  ),
  'direct authenticated updates to evaluation_case_items are blocked.'
);

select pg_temp.satera_expect_rejected(
  format(
    $sql$
      delete from evaluation_events
      where evaluation_case_id = %L::uuid
    $sql$,
    (select id from evaluation_test_ids where key = 'case')
  ),
  'direct authenticated deletes from evaluation_events are blocked.'
);

set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000b2';

insert into workspaces (id, name, owner_user_id)
values (
  '30000000-0000-0000-0000-0000000000b2',
  'Demo Workspace B',
  '00000000-0000-0000-0000-0000000000b2'
);

insert into workspace_members (workspace_id, user_id, role)
values (
  '30000000-0000-0000-0000-0000000000b2',
  '00000000-0000-0000-0000-0000000000b2',
  'owner'
);

insert into evaluation_test_ids
select 'other_case', create_evaluation_case(
  p_workspace_id => '30000000-0000-0000-0000-0000000000b2',
  p_case_type => 'authentication'
);

set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000a1';

select pg_temp.satera_assert(
  not exists (
    select 1
    from evaluation_cases
    where id = (select id from evaluation_test_ids where key = 'other_case')
  ),
  'workspace RLS prevents reading another workspace evaluation case.'
);

select pg_temp.satera_assert(
  not exists (
    select 1
    from evaluation_case_items
    where evaluation_case_id = (select id from evaluation_test_ids where key = 'other_case')
  )
  and not exists (
    select 1
    from evaluation_events
    where evaluation_case_id = (select id from evaluation_test_ids where key = 'other_case')
  ),
  'workspace RLS prevents reading another workspace evaluation items and events.'
);

rollback;
