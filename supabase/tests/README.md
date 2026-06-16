# Satera Core Foundation Verification

These SQL files are local verification scripts for the Satera Core foundation.
They assume the foundation migration and `supabase/seed.sql` have already been
applied to a local Supabase database.

Database RLS protects row visibility. Table grants control whether client code
can write to tables at all. Critical write workflows are protected by atomic
Postgres RPCs so inventory, transactions, transaction lines, ownership events,
basis events, basis lineage edges, and audit events do not become partially
written. Direct authenticated writes to critical financial/history tables are
blocked; the TypeScript service layer should route app code through RPC-backed
workflows, and UI code must not write directly to core inventory, transaction,
financial, or history tables.

Trade workflows are RPC-only. They preserve outgoing items for history, freeze
outgoing basis at trade time, create incoming inventory, write `trade_out` and
`trade_in` ownership events, allocate incoming basis from outgoing basis plus
cash and costs, and create basis events plus lineage edges. Items with missing
outgoing basis cannot be traded until a later correction/confirmation workflow
establishes basis.

Community Core workflows are RPC-only for this pass. Product-scoped
communities, channels, memberships, messages, safe public object reference
message attachments, moderation report/action records, and audit events are
protected by RLS and direct-write hardening. Message references attach
`public_object_references` and do not expose private inventory fields.

## Requirements

- Docker
- Supabase CLI installed through this project's dev dependencies
- PostgreSQL client tools, including `psql`

Install project dependencies:

```sh
npm install
```

Use npm scripts for the local CLI, or call it directly with `npx supabase`.
Examples:

```sh
npx supabase start
npx supabase db reset
```

## Run Locally

Start the local Supabase stack:

```sh
npm run supabase:start
```

Reset the database. This applies migrations and loads `supabase/seed.sql`
through the `[db.seed]` configuration in `supabase/config.toml`:

```sh
npm run supabase:reset
```

Run all verification scripts:

```sh
npm run db:test
```

The runner uses:

```text
postgresql://postgres:postgres@127.0.0.1:54322/postgres
```

Set `DATABASE_URL` to override the target database.

Each script wraps its assertions in a transaction and ends with `rollback`, so
scenario data created by the script is not persisted.

The scripts intentionally use:

```sql
set local role authenticated;
set local request.jwt.claim.sub = '<demo-user-id>';
```

That exercises RLS through Supabase's `auth.uid()` helper rather than bypassing
privacy rules with a service role.

## Script Coverage

- `001_inventory_privacy.sql`: user-owned inventory, organization inventory,
  product profile non-access, non-member denial, and basis null/zero semantics.
- `002_product_lens_access.sql`: Card Vertex, Vertex Pro, and Satera Portfolio
  as category lenses over owned inventory.
- `003_entitlements_do_not_override_privacy.sql`: cross-Vertex and organization
  entitlements are not privacy overrides.
- `004_basis_lineage_trade_example.sql`: Item A basis plus cash paid flows into
  Item B through transaction lines, ownership events, basis events, and a basis
  lineage edge.
- `005_comp_snapshot_privacy.sql`: comp snapshots are private owner-scoped
  intelligence and do not mutate `inventory_items.true_basis`.
- `006_rpc_atomic_transactions.sql`: atomic RPC workflows for starting
  inventory and purchase transactions, including missing basis versus known
  zero basis, purchase basis calculation, required dependent rows, and
  unauthorized owner, workspace, organization, and product-profile cases.
- `007_direct_write_hardening.sql`: direct-write grant hardening for critical
  tables, continued RPC write success, safe inventory update RPC behavior, and
  unauthorized safe update rejection.
- `008_trade_transaction_lineage.sql`: atomic trade transaction lineage,
  incoming basis allocation, cash paid/received and fee effects, non-positive
  basis pool excess profit recording, frozen outgoing basis, and trade
  authorization failures.
- `009_public_object_references.sql`: safe public object reference RPCs,
  visibility, direct-write hardening, audit events, revocation, and private
  inventory field exclusion.
- `010_community_core_mvp.sql`: product-scoped Community Core schema, RLS,
  RPC-only message writes, safe public object reference attachments, direct
  write hardening, basic reporting/moderation, hidden-message visibility, and
  audit events.
