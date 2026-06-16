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

Critical write workflows now run through atomic Postgres RPC functions:

- `create_starting_inventory_transaction`
- `create_purchase_transaction`
- `create_trade_transaction`
- `update_inventory_item_safe_fields`
- `create_community`
- `create_community_channel`
- `join_community`
- `create_community_message`
- `report_community_content`
- `moderate_community_content`

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

Satera Core should model evaluation/certification as a product-neutral
lifecycle. Products can translate that backbone into niche-specific workflows,
such as Card Vertex grading submissions, Comic Vertex restoration review, Watch
Vertex authentication and service records, Coin Vertex holder certification,
or Memorabilia appraisal and provenance review. Evaluation cost may increase
`true_basis`, but evaluation result does not automatically increase
`true_basis`; basis and market value remain separate.

Satera Community Core MVP now exists as platform infrastructure. Communities
are product-scoped Core records with channels, memberships, roles, messages,
safe public object reference attachments, basic moderation report/action
records, audit events, RLS visibility controls, TypeScript services, and
read-only Internal Inspector visibility. Community TypeScript mutations call
the Community Core RPCs only; they do not directly insert, update, delete, or
upsert community tables. Products such as Card Vertex will render their own
community experiences later; no Card Vertex community pages, Community Dock,
Vertex Pro UI, realtime, LiveKit, voice, video, screenshare, uploaded video,
media processing, notifications, or advanced moderation automation have been
implemented.

Trades are atomic RPC workflows. A trade freezes outgoing item basis in
`transaction_lines`, marks outgoing items as traded and archived without
deleting them, creates incoming inventory, records `trade_in` and `trade_out`
ownership events, creates `trade_allocation` basis events, and links outgoing
and incoming items through `basis_lineage_edges`. Incoming basis is allocated
from outgoing basis plus cash paid, minus cash received, plus trade-related
costs. Missing outgoing basis cannot be traded yet; it must be corrected or
confirmed before a trade workflow can preserve explainable basis.

The TypeScript service layer routes app code through these safe workflows.
UI components should call service functions instead of writing directly to core
tables. In particular, UI code must not directly update `true_basis`,
`current_value_snapshot_id`, ownership context fields, `category_id`, or
`asset_variant_id`. UI must not write directly to core financial or history
tables such as `transactions`, `transaction_lines`, `ownership_events`,
`basis_events`, `basis_lineage_edges`, or `audit_events`; those writes belong
behind service workflows and database RPCs so ownership history and cost basis
remain explainable.

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

## App Checks

```sh
npm run test
npm run typecheck
npm run build
```

## Internal Inspector

The `/internal` surface is a read-only development/internal inspector for
Satera Core truth records. It exists to inspect inventory, transactions,
ownership events, basis events, basis lineage, and audit records while the Core
backbone is being verified.

It is not Card Vertex. It is not Satera Portfolio. It is not Vertex Pro.

Before production use, the inspector must be protected by real `platform_admin`
authorization. It must never introduce unsafe write paths or bypass the RPC
workflows that protect ownership history and cost basis.

Current internal inspector routes include inventory, transactions, lineage,
audit, products/category/catalog, public reference, communities, community
messages, and moderation views. The products view exists to verify that Card
Vertex, Vertex Pro, and Satera Portfolio are product/category lenses, not
inventory owners. Community inspector views are read-only and do not provide
forms, edit buttons, create message UI, or moderation write paths.

## Card Vertex Planning

Card Vertex crowdsourced comp planning lives in
`docs/products/card-vertex/CROWDSOURCED_COMP_SYSTEM.md`. No Card Vertex UI,
browser extension, public comp creation route, or internal inspector write path
has been implemented.

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
