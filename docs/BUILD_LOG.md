# Build Log

The current Satera Core foundation includes:

- Foundation Supabase migration for products, categories, ownership contexts, inventory, value snapshots, transactions, lineage, and audit records.
- Local seed data for demo users, products, categories, asset variants, owner contexts, inventory, and verification examples.
- SQL verification suite covering inventory privacy, product lens access, entitlement boundaries, basis lineage, comp snapshot privacy, atomic RPC workflows, direct-write hardening, and trade lineage.
- Atomic starting inventory RPC.
- Atomic purchase RPC.
- Atomic trade RPC.
- Safe inventory update RPC for the narrow set of allowed inventory fields.
- Direct-write hardening for critical financial and history tables.
- TypeScript service layer that routes application code through safe workflows.
- Tests for calculations, service-layer protections, atomic transaction inputs, and product/portfolio read helpers.
- Internal Inspector Slice 2 with read-only lineage, audit, and products/category/catalog views.
- Card Vertex crowdsourced comp system documentation under `docs/products/card-vertex/`.
- Early comp evidence schema extensions remain in Core as value-evidence infrastructure only. Direct app/client comp writes are not active, and comp mutations are not exposed through UI.
