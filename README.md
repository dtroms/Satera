# Satera

Satera Core is the shared platform backbone for collectible asset products.
This repository currently contains the foundation migration, local seed data,
and verification scripts for the Core truth layer.

## Verified Foundation Status

The Satera Core foundation has been verified locally:

- Supabase local stack starts with the project-local CLI.
- `npm run supabase:reset` applies the foundation migration and `seed.sql`.
- `npm run db:test` passes the SQL verification suite.
- `npm run test`, `npm run typecheck`, and `npm run build` pass.

## Core Access Model

Database RLS protects row visibility. Table grants control whether client code
can write to tables at all. Inventory is private by default and belongs to a
user, workspace, or organization. Products are category lenses and do not own
inventory.

The Product Lens Framework is now hardened as a read-only Core service
boundary. Product lenses resolve active products, product category mappings,
product profiles, organization product profiles, entitlements, communities,
notifications, evaluation cases, public object references, and workspace
inventory through explicit product context. Product access does not override
inventory privacy: lenses start from owner/workspace/organization-scoped Core
data and then filter by product category or product_id. Product lenses are not
data silos and do not fork Satera Core truth.

Future product deployment planning keeps data ownership centralized in Satera
Core. Card Vertex should eventually live at `cardvertex.com` as its own
standalone product surface. Satera may eventually live at `satera.app` for
account/billing, platform/admin, internal tooling, Satera Portfolio, or other
cross-product surfaces. Satera is not the generic marketplace/dashboard MVP.
That future separation is app-root, domain, and deployment separation only.
Card Vertex should continue using the same Satera Core backend, same auth
model, same RPCs, same RLS, and same Satera Supabase database; it should not
get a separate Supabase project.

Critical write workflows now run through atomic Postgres RPC functions:

- `create_starting_inventory_transaction`
- `create_purchase_transaction`
- `create_lot_purchase_transaction`
- `create_sale_transaction`
- `create_trade_transaction`
- `update_inventory_item_safe_fields`
- `create_community`
- `create_community_channel`
- `join_community`
- `create_community_message`
- `report_community_content`
- `moderate_community_content`
- `lift_user_restriction`
- `add_moderation_note`
- `submit_moderation_appeal`
- `create_notification_event`
- `mark_notification_read`
- `mark_notifications_read`
- `dismiss_notification`
- `archive_notification`
- `create_evaluation_case`
- `add_evaluation_case_item`
- `update_evaluation_case_status`
- `record_evaluation_result`
- `apply_evaluation_basis_increase`

Read-only product-lens helper functions support safe product checks:

- `can_access_product`
- `is_category_in_product`
- `inventory_item_belongs_to_product`

These RPCs create inventory, transactions, transaction lines, ownership
events, basis events, and audit events in one database transaction. They also
validate the authenticated user against the requested user, workspace, or
organization owner context so product profiles and entitlements cannot override
privacy.

Direct authenticated writes to core financial and history tables are blocked by
table grants. RLS still controls which rows can be read, while grants prevent
unsafe client-side insert, update, or delete bypasses around the RPC workflows.
Direct authenticated writes to `comp_snapshots` are also blocked while the comp
workflow remains early infrastructure. Future comp submissions should go through
a reviewed service/RPC workflow before any UI or extension can create records.

Public Object References are the Core bridge for safe sharing. A private
inventory item is not a public object reference. Future community messages,
trade posts, listings, showcases, and Card Vertex drag/drop sharing should use:

```text
private inventory item -> safe public object reference -> product/community/listing attachment
```

Public references are intentional exposure records and are not the inventory
source of truth. They may carry safe display and market/value signals, but must
never expose `true_basis`, purchase price, profit, ROI, location, private notes,
private tags, ownership history, private transaction history, or
evaluation/certification costs such as grading costs.

Satera Evaluation / Certification Lifecycle now exists in Core as a
product-neutral lifecycle. It can represent grading, authentication, appraisal,
certification, condition review, restoration review, service, and provenance
review. Products translate that backbone into niche-specific workflows, such as
Card Vertex grading submissions, Comic Vertex restoration review, Watch Vertex
authentication and service records, Coin Vertex holder certification, or
Memorabilia appraisal and provenance review. Evaluation results do not
automatically mutate `true_basis` or market value. Evaluation costs may
increase `true_basis` only when explicitly applied through
`apply_evaluation_basis_increase`; items with `true_basis = null` reject basis
increase for now, and current value is not updated by result recording or basis
increase.

Satera Community Core MVP now exists as platform infrastructure. Communities
are product-scoped Core records with channels, memberships, roles, messages,
safe public object reference attachments, durable user restrictions,
moderation notes, moderation appeals, moderation report/action records, audit
events, RLS visibility controls, TypeScript services, and read-only Internal
Inspector visibility. Community TypeScript mutations call the Community Core
RPCs only; they do not directly insert, update, delete, or upsert community or
moderation enforcement tables. Products such as Card Vertex will render their
own community and moderation experiences later; no Card Vertex community pages,
Community Dock, Vertex Pro UI, product-facing moderation dashboard, realtime,
LiveKit, voice, video, screenshare, uploaded video, media processing,
notifications, AI moderation, automated moderation providers, or advanced
moderation automation have been implemented.

Satera Moderation Foundation is Core trust and safety infrastructure. Satera
owns moderation state, enforcement, decisions, appeals, and audit trail.
External moderation providers may provide signals later, but final state
belongs in Satera Core. Normal users should not see hidden, removed, or deleted
community messages; moderators and admins can inspect moderated content in
scope.

Satera Notification Foundation now exists as platform infrastructure. Core owns
durable notification events, recipient notification records, read/dismiss/archive
state, safe metadata, related entity context, delivery attempt tracking for
future providers, and audit events. Products will render notification
experiences later. External providers such as Resend, push, SMS, webhooks,
realtime transports, and background delivery jobs are future delivery layers
only and are not implemented here.

Trades are atomic RPC workflows. A trade freezes outgoing item basis in
`transaction_lines`, marks outgoing items as traded and archived without
deleting them, creates incoming inventory, records `trade_in` and `trade_out`
ownership events, creates `trade_allocation` basis events, and links outgoing
and incoming items through `basis_lineage_edges`. Incoming basis is allocated
from outgoing basis plus cash paid, minus cash received, plus trade-related
costs. Missing outgoing basis cannot be traded yet; it must be corrected or
confirmed before a trade workflow can preserve explainable basis.

Lot purchases are atomic RPC workflows. A lot purchase creates multiple
inventory items under one `purchase_lot` transaction and allocates the total lot
basis pool across those items. The canonical formula is `purchase_price +
buyer_fees + tax + shipping + other_acquisition_costs`. Supported allocation
methods are `manual` and `equal`; allocated basis is frozen per item, the sum
of allocated item basis must equal the total lot basis with only a tiny
rounding adjustment, and current value is not inferred from basis. Lot purchase
does not create public object references, variants, marketplace integrations,
receipt parsing, OCR, AI allocation, or custom acquisition-cost categories.

Sales are atomic RPC workflows. A sale freezes item basis in
`transaction_lines`, calculates net proceeds as sale price minus canonical
selling-cost buckets (platform fees, payment processing fees, shipping cost,
supplies cost, consignment fees, and other selling costs), records realized
profit/loss as `net_proceeds - true_basis`, marks the item sold and archived,
writes a `sale_realization` basis event, and writes an audit event. Sale does
not rewrite `true_basis` and does not update current value. Missing basis cannot
be sold yet; known zero basis can be sold and can realize profit/loss.

The TypeScript service layer routes app code through these safe workflows.
UI components should call service functions instead of writing directly to core
tables. In particular, UI code must not directly update `true_basis`,
`current_value_snapshot_id`, ownership context fields, `category_id`, or
`asset_variant_id`. UI must not write directly to core financial or history
tables such as `transactions`, `transaction_lines`, `ownership_events`,
`basis_events`, `basis_lineage_edges`, or `audit_events`; those writes belong
behind service workflows and database RPCs so ownership history and cost basis
remain explainable.

The same boundary applies to future product apps. Card Vertex should own the
card-specific product experience, UI, workflows, terminology, layout, and
product behavior, but it must call Satera Core services/RPCs for database
mutations. Product UI must not contain Satera financial truth logic. Preserving
that service/API boundary lets Card Vertex become a separate app root later
without rewriting Core inventory, transaction, basis, lineage, permission,
community, moderation, notification, audit, or entitlement logic.

The canonical ownership model and decision matrix are documented in
[`docs/architecture/SATERA_CARD_VERTEX_OWNERSHIP.md`](docs/architecture/SATERA_CARD_VERTEX_OWNERSHIP.md).
Card Vertex domain workflows are documented in
[`docs/products/card-vertex/PRODUCT_DOMAIN_AND_WORKFLOWS.md`](docs/products/card-vertex/PRODUCT_DOMAIN_AND_WORKFLOWS.md).
Card Vertex-specific records may live in the shared Satera database without
transferring card-specific behavior to Core.

Card Vertex at `cardvertex.com` should use Satera Core services/RPCs and the
product-lens query boundary to see card categories, Card Vertex communities,
Card Vertex notifications, Card Vertex evaluation cases, and Card Vertex public
references. It should not directly mutate Core tables or reimplement Satera
financial truth logic in product UI.

## Product App Boundary

`packages/satera-core` now exists as the first shared package boundary. It
currently re-exports the active `lib/core` implementation through domain entry
points for services, query helpers, RPC wrappers, and types. The current root
`app/` remains unchanged, and `lib/core` remains both the active implementation
and compatibility surface for existing imports. No runtime behavior changed.

Future passes may migrate source logic into `packages/satera-core/src`
gradually. Future product apps should consume Satera Core through that package
boundary and continue routing mutations through approved Core services/RPCs.
Card Vertex at `cardvertex.com` should use this shared package when its runnable
app is created from the placeholder.

`apps/card-vertex` now exists as a documentation-only placeholder for that
future standalone app root. No runnable Card Vertex app, routes, or UI have
been created there. The current root `app/` remains the active application,
and no files were moved from it or from `lib/core`. Turning the placeholder
into a real app requires intentional workspace and build configuration in a
later pass. No Vercel/domain configuration or Supabase changes accompany this
placeholder.

Future product apps may include Card Vertex, Satera, Vertex Pro, and Satera
Portfolio. Future shared packages may also include `ui` and `config`. Future
Vercel setup may use multiple Vercel projects pointing at app roots in one
repo, but Vercel configuration has not changed in this pass.

The intended staged roadmap is:

1. Plan workspace/build configuration for real app roots.
2. Create minimal `apps/satera` root only after deciding its exact role.
3. Configure real monorepo/workspace tooling later.
4. Comp/Value Workflow write path.
5. Card Vertex product shell.

Future extraction must be staged: extract Satera Core services first, keep
compatibility exports from `lib/core`, keep Supabase migrations/tests at the
repo root, keep database truth centralized, keep product-specific logic out of
Satera Core, and keep Satera financial truth logic out of product UI. Product
apps should call service functions/RPCs, avoid direct table mutations, and use
safe product-lens reads instead of unscoped inventory queries.

## Local Supabase Setup

Prerequisites:

- Node.js and npm
- Docker
- Supabase CLI installed through this project's dev dependencies
- PostgreSQL client tools, including `psql`

Install project dependencies:

```sh
npm install
```

The Supabase CLI is available through npm scripts. If you need to call it
directly, use `npx supabase ...`, for example:

```sh
npx supabase start
npx supabase db reset
```

Start the local Supabase stack:

```sh
npm run supabase:start
```

Reset the local database, apply migrations, and load `supabase/seed.sql`:

```sh
npm run supabase:reset
```

Run the Satera Core SQL verification suite:

```sh
npm run db:test
```

The verification runner uses the default Supabase local database URL:

```text
postgresql://postgres:postgres@127.0.0.1:54322/postgres
```

Override it when needed:

```sh
DATABASE_URL="postgresql://postgres:postgres@127.0.0.1:54322/postgres" npm run db:test
```

## Verification Coverage

- `001_inventory_privacy.sql`: verifies user, workspace, and organization
  inventory privacy, plus `true_basis` null versus zero semantics.
- `002_product_lens_access.sql`: verifies products act as category lenses and
  do not own inventory.
- `003_entitlements_do_not_override_privacy.sql`: verifies account and
  organization entitlements do not bypass inventory privacy.
- `004_basis_lineage_trade_example.sql`: verifies a trade can explain basis
  through transactions, transaction lines, ownership events, basis events, and
  basis lineage edges.
- `005_comp_snapshot_privacy.sql`: verifies owner-scoped comp snapshots and
  confirms market value updates do not change `true_basis`.
- `006_rpc_atomic_transactions.sql`: verifies atomic transaction RPCs for
  starting inventory and purchase workflows, including basis semantics,
  required dependent rows, and authorization failures.
- `007_direct_write_hardening.sql`: verifies direct authenticated writes to
  critical financial/history tables are blocked while RPC workflows and safe
  inventory updates still work.
- `008_trade_transaction_lineage.sql`: verifies atomic trade workflows,
  proportional basis allocation, cash/cost effects, non-positive basis pools,
  frozen outgoing basis, ownership events, basis events, lineage edges, and
  authorization failures.
- `009_public_object_references.sql`: verifies safe public object reference
  RPCs, RLS visibility, direct-write hardening, audit events, revocation, and
  absence of private inventory fields.
- `010_community_core_mvp.sql`: verifies product-scoped Community Core tables,
  RLS, RPC-only message writes, safe public object reference message
  attachments, basic reporting/moderation, hidden-message visibility, direct
  write hardening, and audit events.
- `011_moderation_foundation_hardening.sql`: verifies durable user
  restrictions, moderation notes, appeals, posting restriction enforcement,
  hidden/removed/deleted visibility, RPC-only moderation writes, RLS, and audit
  events.
- `012_notification_foundation.sql`: verifies durable notification events,
  recipient notification RLS, safe metadata guards, RPC-only status mutations,
  audit events, blocked direct writes, delivery-attempt write hardening, and
  platform-admin inspection.
- `013_sale_transaction_lifecycle.sql`: verifies sale transaction math,
  sold inventory state, sale realization basis event, audit event, zero-basis
  sales, missing-basis rejection, negative input rejection, unauthorized sale
  rejection, and already-sold/out-of-active-ownership rejection.
- `014_lot_purchase_transaction_rpc.sql`: verifies manual and equal lot
  allocation, rounding, zero-dollar lots, transaction/inventory/lineage/basis
  records, audit events, invalid input rejection, reference validation, and
  unauthorized workspace rejection.
- `015_evaluation_certification_lifecycle.sql`: verifies product-neutral
  evaluation cases, items, lifecycle events, explicit audited basis increases,
  result/basis/value separation, RLS, and direct-write hardening.

## App Checks

```sh
npm run test
npm run typecheck
npm run build
```

## Internal Inspector

The `/internal` surface is a read-only development/internal inspector for
Satera Core truth records. It exists to inspect inventory, transactions,
ownership events, basis events, basis lineage, notification records,
evaluation/certification records, and audit records while the Core backbone is
being verified.

It is not Card Vertex. It is not Satera Portfolio. It is not Vertex Pro.

Before production use, the inspector must be protected by real `platform_admin`
authorization. It must never introduce unsafe write paths or bypass the RPC
workflows that protect ownership history and cost basis.

Current internal inspector routes include inventory, transactions, lineage,
audit, products/category/catalog, public reference, communities, community
messages, moderation, notifications, and evaluations. The moderation inspector
can read reports, actions, user restrictions, notes, and appeals visible to the
internal session. The evaluation inspector can read cases, items, lifecycle
events, and attachment records only. The products view exists to verify that
Card Vertex, Vertex Pro, and Satera Portfolio are product/category lenses, not
inventory owners. Community, moderation, notification, and evaluation inspector
views are read-only and do not provide forms, edit buttons, create message UI,
product-facing moderation dashboards, grading UI, submission UI, provider
integrations, or moderation write paths.

## Card Vertex Planning

Card Vertex crowdsourced comp planning lives in
`docs/products/card-vertex/CROWDSOURCED_COMP_SYSTEM.md`. No Card Vertex UI,
browser extension, public comp creation route, or internal inspector write path
has been implemented.

Product App Boundary / Monorepo Prep is documented in
`docs/architecture/PRODUCT_APP_BOUNDARY.md` and should precede the Card Vertex
product shell. Later milestones may introduce separate app roots for
`cardvertex.com` and `satera.app` plus shared packages for Core service
wrappers, UI primitives, and config, but this repository has not had package
extraction or app-root creation yet.

Card Vertex inventory workspace, saved filters, community dock, drag/drop public
card references, and Card Context Drawer planning lives in
`docs/products/card-vertex/INVENTORY_WORKSPACE_AND_COMMUNITY.md`. This is
product UX planning only; the reusable Satera Community Core backend now exists,
but no Card Vertex UI, Community Dock, realtime features, routes, or packages
have been implemented.

The current comp schema is early Core value-evidence infrastructure only. It
keeps market value separate from cost basis: comps and current value snapshots
must not mutate `true_basis` or create basis events.

## Community And Media Planning

Satera Community Core planning lives in `docs/architecture/COMMUNITY_CORE.md`.
Vertex Pro cross-product community management planning lives in
`docs/products/vertex-pro/CROSS_PRODUCT_COMMUNITY_MANAGEMENT.md`. Future media
and moderation alignment lives in `docs/architecture/TECHNOLOGY_ROADMAP.md`.

Satera now owns the reusable product-scoped community infrastructure in Core.
Products should render their own community experiences, and Vertex Pro should
eventually manage organization-owned community presence across product contexts.
