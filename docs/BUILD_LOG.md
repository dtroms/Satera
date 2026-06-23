# Build Log

The current Satera Core foundation includes:

- Foundation Supabase migration for products, categories, ownership contexts, inventory, value snapshots, transactions, lineage, and audit records.
- Local seed data for demo users, products, categories, asset variants, owner contexts, inventory, and verification examples.
- SQL verification suite covering inventory privacy, product lens access, entitlement boundaries, basis lineage, comp snapshot privacy, atomic RPC workflows, direct-write hardening, and trade lineage.
- Atomic starting inventory RPC.
- Atomic purchase RPC.
- Atomic lot purchase RPC for buying multiple inventory items in one
  acquisition. It records one `purchase_lot` transaction, preserves the total
  lot basis formula, supports manual and equal allocation, freezes allocated
  `true_basis` per item, writes transaction lines, ownership events, basis
  events, basis lineage edges, and an audit event, and does not infer current
  value from basis.
- Atomic sale RPC for purchase -> own -> sell -> realize profit/loss
  lifecycle. It freezes basis at sale time, writes sale transaction lines,
  ownership event, sale realization basis event, audit event, and sold inventory
  state, and does not rewrite `true_basis` or update current value.
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
- Satera Evaluation / Certification Lifecycle with product-neutral cases,
  case items, immutable lifecycle events, future-safe attachment records, RLS
  policies, direct-write hardening, RPC-only mutations, explicit audited basis
  increases, SQL verification, TypeScript service helpers, and read-only
  Internal Inspector visibility.
- Product Lens Framework hardening with read-only TypeScript services for
  product context, product-scoped inventory, public references, communities,
  notifications, evaluation cases, entitlements, and summary counts.
- First shared package boundary at `packages/satera-core`. Its domain entry
  points re-export the active `lib/core` services, query helpers, RPC wrappers,
  and types. Existing `lib/core` imports remain compatible, no implementation
  files moved, and runtime behavior is unchanged.
- Product-lens SQL helper functions for product access checks, category/product
  membership, and inventory-item/product membership.
- SQL verification that product-scoped inventory, public references,
  communities, notifications, evaluation cases, and summary-style counts stay
  scoped to the requested product while inventory privacy remains
  owner/workspace-controlled.
- Direct-write hardening for critical financial and history tables.
- TypeScript service layer that routes application code through safe workflows.
- Tests for calculations, service-layer protections, atomic transaction inputs,
  sale transaction lifecycle, lot purchase allocation,
  public object reference privacy/RPC behavior, community RPC-only mutation
  behavior, and product/portfolio read helpers.
- Internal Inspector Slice 2 with read-only lineage, audit,
  products/category/catalog, public reference, communities, community messages,
  and moderation views.
- Card Vertex crowdsourced comp system documentation under `docs/products/card-vertex/`.
- Card Vertex inventory workspace and community interaction planning under `docs/products/card-vertex/`.
- Satera Core/Card Vertex three-layer ownership documentation with a detailed
  current-state decision matrix, promotion rule, and explicit shared-database
  boundary under `docs/architecture/`.
- Card Vertex product-domain workflow documentation distinguishing Trade
  Network from logged trades, sale intent from sale truth, and Draft Lot
  Workspace behavior from final Core lot commitment. It also defines ownership
  for signals, goals, search, trust, grading, market context, and activity.
- Card Vertex product-domain data-model gap assessment documenting current
  Core capabilities, immediate consumption paths, missing Card Vertex-specific
  records/contracts, future-work boundaries, and product decisions required
  before proposing migrations.
- Card Vertex card identity and catalog strategy documentation defining the
  proposed separation between catalog card identity, owned physical copies,
  evaluation/certification state, and public card references; catalog hierarchy;
  source strategy; provisional intake; aliases; image provenance; current Core
  mapping; decision matrix; and founder-review decisions.
- Card Vertex Draft Lot Workspace architecture and lifecycle documentation
  defining Draft Lots as reversible Card Vertex preparation workspaces rather
  than inventory, transactions, or accounting records; documenting collector
  workflows, lifecycle states, information architecture, allocation behavior,
  provisional identity handling, Core commit contract, correction model,
  starting-inventory distinction, current Core mapping, future schema
  requirements, decision matrix, founder decisions, and explicit non-goals.
- Card Vertex Grading Workspace and Certification Lifecycle documentation
  defining grading as evaluation/certification state on an owned physical card
  instance rather than a new catalog identity; documenting grading workspace
  purpose, submission lifecycle, submission structure, cost/basis/value
  separation, certification handling, inventory availability behavior, entry
  points, Return Review, correction rules, Core/Card Vertex ownership mapping,
  decision matrix, founder decisions, follow-on sequence, and explicit
  non-goals.
- Satera Community Core architecture planning under `docs/architecture/`.
- Vertex Pro cross-product community management planning under `docs/products/vertex-pro/`.
- Technology roadmap planning for future community media and moderation alignment under `docs/architecture/`.
- Product App Boundary documentation now records the implemented incremental
  package boundary and future standalone product app boundaries without moving
  the current app.
- Added `apps/card-vertex` as a documentation-only placeholder for the future
  standalone Card Vertex app root. It contains no runnable app, routes, product
  UI, workspace, inventory screens, or Community Dock. The current root app
  remains active, and `packages/satera-core` remains the package boundary for
  future product apps.
- Card Vertex may later live as its own app root at `cardvertex.com`, and
  Satera may later live separately at `satera.app` for account/billing,
  platform/admin, internal tooling, Satera Portfolio, or other cross-product
  surfaces. Satera is not the generic marketplace/dashboard MVP. Future Vercel
  setup may use multiple Vercel projects pointing at app roots in one repo, but
  Vercel configuration is a later milestone.
- Future product app boundaries should rely on the product-lens service
  boundary. Card Vertex at `cardvertex.com` should use Satera Core
  services/RPCs rather than direct table mutations or product-owned truth.
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
- Internal Evaluation Inspector views are read-only and do not add Card Vertex
  pages, grading UI, submission UI, provider integrations, upload UI, or
  evaluation write paths.
- Evaluation results do not update `true_basis` or `current_value`. Evaluation
  costs may increase `true_basis` only through explicit audited basis increase,
  and items with `true_basis = null` reject basis increase for now.
- The Card Vertex grading contract preserves this Core rule: predicted grading
  costs, actual grading costs, final grades, and certification numbers never
  automatically update basis or market value. Any eligible cost capitalization
  must happen through explicit audited basis increase after Return Review.
- No Card Vertex community UI, Card Vertex pages, Community Dock, Vertex Pro
  UI, realtime, LiveKit, voice, video, screenshare, uploaded video, media
  processing, grading UI, submission UI, lot purchase UI, bulk import UI,
  marketplace integrations, appraisal provider integrations, grading provider
  integrations, authentication provider integrations, receipt parsing, OCR, AI
  allocation, custom acquisition-cost category management, notification
  delivery, email, push, SMS, AI moderation, automated moderation providers, or
  advanced moderation automation has been built.
- The existing Lot Purchase Transaction RPC remains the correct final Commit
  Lot truth mechanism. A long-lived Card Vertex Draft Lot Workspace above it is
  now documented as an approved planning architecture, but has not been
  implemented.
- No runnable app roots, separate Card Vertex deployment, Card Vertex
  Vercel/domain configuration, separate Card Vertex database, or separate Card
  Vertex Supabase project have been created. No Supabase files, workspace/build
  tooling, or runtime behavior changed for the placeholder.
- Moving Satera Core implementation logic into the package and full app-root
  creation are later milestones. Future extraction should keep
  compatibility exports from `lib/core`, keep Supabase migrations/tests at the
  repo root, keep database truth centralized, keep product-specific logic out
  of Core, and keep Satera financial truth logic out of product UI.
