# Build Log

The current Satera Core foundation includes:

- Foundation Supabase migration for products, categories, ownership contexts, inventory, value snapshots, transactions, lineage, and audit records.
- Local seed data for demo users, products, categories, asset variants, owner contexts, inventory, and verification examples.
- SQL verification suite covering inventory privacy, product lens access, entitlement boundaries, basis lineage, comp snapshot privacy, atomic RPC workflows, direct-write hardening, and trade lineage.
- Atomic starting inventory RPC.
- Atomic purchase RPC.
- Atomic trade RPC.
- Safe inventory update RPC for the narrow set of allowed inventory fields.
- Public Object Reference schema, RLS policies, and RPCs for safe exposure
  records that bridge private inventory into future product/community/listing
  attachments without exposing private inventory data.
- Satera Community Core MVP schema, RLS policies, helper authorization
  functions, RPCs, and SQL verification for product-scoped communities,
  channels, memberships, roles, messages, safe public object reference
  attachments, basic moderation report/action records, and audit events.
- Satera Community Core MVP Pass 2 TypeScript services for read helpers and
  RPC-only mutations covering communities, channels, joins, messages,
  reporting, and moderation actions.
- Satera Moderation Foundation hardening with durable user restrictions,
  internal moderation notes, appeal records, restriction-aware message posting,
  expanded moderation RPC behavior, restriction lifting, note/appeal RPCs,
  RLS policies, direct-write hardening, audit events, TypeScript service
  helpers, SQL verification, and read-only Internal Inspector visibility.
- Satera Notification Foundation with durable notification events,
  recipient-specific notification state, safe metadata guards, product/entity
  context, future delivery-attempt tracking, RLS policies, direct-write
  hardening, RPC-only status mutations, audit events, TypeScript service
  helpers, SQL verification, and read-only Internal Inspector visibility.
- Direct-write hardening for critical financial and history tables.
- TypeScript service layer that routes application code through safe workflows.
- Tests for calculations, service-layer protections, atomic transaction inputs,
  public object reference privacy/RPC behavior, community RPC-only mutation
  behavior, and product/portfolio read helpers.
- Internal Inspector Slice 2 with read-only lineage, audit,
  products/category/catalog, public reference, communities, community messages,
  and moderation views.
- Card Vertex crowdsourced comp system documentation under `docs/products/card-vertex/`.
- Card Vertex inventory workspace and community interaction planning under `docs/products/card-vertex/`.
- Satera Community Core architecture planning under `docs/architecture/`.
- Vertex Pro cross-product community management planning under `docs/products/vertex-pro/`.
- Technology roadmap planning for future community media and moderation alignment under `docs/architecture/`.
- Early comp evidence schema extensions remain in Core as value-evidence infrastructure only. Direct app/client comp writes are not active, and comp mutations are not exposed through UI.
- Public references are Core display records only. They intentionally exclude
  true basis, purchase price, profit, location, private notes, private tags,
  ownership history, and private transaction history.
- Community message references attach `public_object_references` and snapshot
  only safe public display fields. They do not expose private inventory fields.
- Internal Community and Moderation Inspector views are read-only and do not
  add edit forms, create-message UI, moderation write paths, or product-facing
  moderation dashboards.
- Internal Notification Inspector views are read-only and do not add
  notification UI, forms, delivery controls, product notification surfaces, or
  preference management.
- No Card Vertex community UI, Card Vertex pages, Community Dock, Vertex Pro
  UI, realtime, LiveKit, voice, video, screenshare, uploaded video, media
  processing, notification delivery, email, push, SMS, AI moderation,
  automated moderation providers, or advanced moderation automation has been
  built.
