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

These RPCs create inventory, transactions, transaction lines, ownership
events, basis events, and audit events in one database transaction. They also
validate the authenticated user against the requested user, workspace, or
organization owner context so product profiles and entitlements cannot override
privacy.

Direct authenticated writes to core financial and history tables are blocked by
table grants. RLS still controls which rows can be read, while grants prevent
unsafe client-side insert, update, or delete bypasses around the RPC workflows.

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
