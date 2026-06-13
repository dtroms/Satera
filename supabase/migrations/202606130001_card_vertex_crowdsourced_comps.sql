-- Early Core value-evidence infrastructure for future product lenses such as
-- Card Vertex. These fields extend owner-scoped comp_snapshots; they do not
-- create product-owned inventory, basis events, or any workflow that mutates
-- inventory_items.true_basis. Direct client writes are revoked below until a
-- reviewed RPC-based comp workflow exists.

create type comp_source_type as enum (
  'marketplace',
  'auction_house',
  'price_guide',
  'private_sale',
  'local_card_shop',
  'card_show',
  'dealer_verified',
  'user_submitted',
  'admin_verified',
  'partner_feed'
);

create type comp_capture_mode as enum (
  'manual',
  'smart',
  'reference_only'
);

create type comp_verification_status as enum (
  'user_submitted',
  'system_assisted',
  'needs_review',
  'admin_verified',
  'dealer_verified',
  'excluded',
  'disputed'
);

create type comp_match_quality as enum (
  'exact_match',
  'same_card_different_grade',
  'same_player_different_parallel',
  'similar_card',
  'reference_only',
  'excluded'
);

create type comp_exclusion_reason as enum (
  'wrong_card',
  'wrong_parallel',
  'wrong_grade',
  'raw_vs_graded_mismatch',
  'multi_card_lot',
  'reprint',
  'custom_card',
  'suspicious_price',
  'unpaid_or_canceled_sale',
  'damaged_card',
  'altered_card',
  'poor_image_match',
  'old_comp',
  'not_enough_information'
);

create type comp_confidence_label as enum (
  'unknown',
  'user_entered',
  'low_confidence',
  'medium_confidence',
  'high_confidence',
  'verified'
);

alter table comp_snapshots
  add column source_type comp_source_type not null default 'user_submitted',
  add column capture_mode comp_capture_mode not null default 'manual',
  add column verification_status comp_verification_status not null default 'user_submitted',
  add column match_quality comp_match_quality not null default 'exact_match',
  add column include_in_valuation boolean not null default true,
  add column exclusion_reason comp_exclusion_reason,
  add column exclusion_notes text,
  add column sale_date date,
  add column sale_title text,
  add column source_domain text,
  add column grading_company text,
  add column screenshot_url text,
  add column notes text,
  add column submitted_by uuid references auth.users(id) on delete set null,
  add column verified_by uuid references auth.users(id) on delete set null,
  add column verified_at timestamptz,
  add column confidence_label comp_confidence_label not null default 'user_entered',
  add column review_requested boolean not null default false,
  add column review_reason text;

alter table comp_snapshots
  add constraint comp_snapshots_exclusion_reason_required check (
    include_in_valuation
    or exclusion_reason is not null
    or match_quality in ('reference_only', 'excluded')
    or verification_status in ('excluded', 'disputed')
  );

create index comp_snapshots_include_in_valuation_idx on comp_snapshots(include_in_valuation);
create index comp_snapshots_verification_status_idx on comp_snapshots(verification_status);
create index comp_snapshots_source_type_idx on comp_snapshots(source_type);
create index comp_snapshots_sale_date_idx on comp_snapshots(sale_date);
create index comp_snapshots_review_requested_idx on comp_snapshots(review_requested) where review_requested;

revoke insert, update, delete on comp_snapshots from authenticated, anon;
grant select on comp_snapshots to authenticated;
