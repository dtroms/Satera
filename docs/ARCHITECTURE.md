# Satera Core Architecture

Satera Core is the truth layer for Satera. It owns the durable records for private inventory, transactions, ownership history, financial basis, lineage, and auditability.

Products are lenses over Core records. Card Vertex, Vertex Pro, Satera Portfolio, and future products may present different workflows or category-specific experiences, but they do not own inventory and must not become alternate sources of truth.

The Product Lens Framework hardens this rule in the service layer. Product
lenses resolve product context, product category mappings, product profiles,
organization product profiles, account and organization entitlements, public
object references, communities, notifications, evaluation cases, and
workspace-scoped inventory through explicit product constraints. Lenses filter
and translate Core data; they do not fork the data model or create product data
silos.

Product apps may eventually become separate app roots, domains, and
deployments, but not separate data platforms. Card Vertex should eventually
live at `cardvertex.com` as its own standalone product surface. Satera may
eventually live separately at `satera.app` for account/billing,
platform/admin, internal tooling, Satera Portfolio, or other cross-product
surfaces. Satera is not the generic marketplace/dashboard MVP. These surfaces
should continue to use the same Satera Core backend, same auth model, same
RPCs, same RLS, and the same Satera Supabase database. Card Vertex should not
have a separate Supabase project.

Satera owns the database, auth, permissions, inventory truth, transactions,
basis, lineage, public object references, communities, moderation,
notifications, audit, and entitlements. Card Vertex owns the card-specific
product experience, UI, workflows, terminology, layout, and product behavior.
Card Vertex must call Satera Core services and RPCs instead of directly
mutating Satera Core tables. Product UI must not contain Satera financial truth
logic.

The detailed three-layer ownership model, decision matrix, and promotion rule
live in
[`SATERA_CARD_VERTEX_OWNERSHIP.md`](architecture/SATERA_CARD_VERTEX_OWNERSHIP.md).
Satera owning canonical truth does not reduce Card Vertex to a UI skin: Card
Vertex owns card-specific semantics, product rules, intelligence, and workflow
behavior. Product-specific records may live in the shared database while using
shared RLS, permissions, audit, and product scoping.

`packages/satera-core` is now the first shared package boundary. It currently
re-exports the active `lib/core` implementation without moving logic, changing
runtime behavior, or breaking existing `lib/core` imports. Separate app roots
remain later milestones before the Card Vertex product shell is built.
`apps/card-vertex` now provides a documentation-only placeholder for the
future Card Vertex app root; it is not runnable and contains no product UI:

```text
Satera/
├── apps/
│   ├── card-vertex/        deployed to cardvertex.com
│   ├── satera/             platform/account/admin/portfolio surface
│   ├── vertex-pro/         future dealer/operator app
│   └── satera-portfolio/   future portfolio app if separate from apps/satera
├── packages/
│   ├── satera-core/        current shared service/RPC/type boundary
│   ├── ui/                 shared primitives
│   └── config/             shared config
└── supabase/
    ├── migrations/
    └── tests/
```

Except for the placeholder directory, the app-root and remaining package
structure is planning only. The current root `app/` and `lib/core` structure
remains active; `lib/core` is the active
implementation and compatibility surface. Future passes may migrate source
logic into `packages/satera-core/src` gradually while preserving the service/API
boundary so Card Vertex can become a separate app root
without rewriting the Core logic. It should not introduce a separate Card
Vertex database or Supabase project. Future Vercel setup may use multiple
Vercel projects pointing at different app roots in this repo, but Vercel
configuration is a later milestone.

Creating a runnable Card Vertex app requires intentionally introducing
workspace/build configuration later. This placeholder adds no Card Vertex UI,
Vercel/domain configuration, runtime changes, or Supabase changes.

The staged roadmap is:

1. Plan workspace/build configuration for real app roots.
2. Create minimal `apps/satera` root only after deciding its exact role.
3. Configure real monorepo/workspace tooling later.
4. Comp/Value Workflow write path.
5. Card Vertex product shell.

Future extraction rules: do not move everything in one pass, extract Satera
Core services first, keep compatibility exports from `lib/core`, keep Supabase
migrations/tests at the repo root, keep database truth centralized, keep
product-specific logic out of Satera Core, keep Satera financial truth logic
out of product UI, route product app mutations through service functions/RPCs,
allow safe reads through Satera Core services, and prefer product-lens queries
over unscoped inventory queries.

Inventory belongs to users, workspaces, or organizations. Every inventory item carries an owner context, and privacy starts there. Row Level Security protects row visibility so a product profile, entitlement, or product-specific surface cannot override private inventory boundaries.

Product access is separate from inventory access. An active product, product
profile, organization product profile, product admin role, or entitlement can
authorize a product lens experience, but it cannot expose another user's
private inventory, another workspace's inventory, private comp snapshots, or
workspace-scoped evaluation cases. Product lens inventory starts from Core
owner/workspace/organization access and then filters to categories mapped to
the requested product.

Public Object References are the safe sharing bridge between private inventory
and future product/community surfaces. A private inventory item is not a public
object reference. The platform pattern is:

```text
private inventory item -> safe public object reference -> product/community/listing attachment
```

Public references are intentional exposure records. They can carry safe display
fields and market/value labels, but they must never expose true basis, purchase
price, profit, ROI, location, private notes, private tags, ownership history,
private transaction history, or evaluation/certification costs such as grading
costs. They are not the inventory source of truth.

Product-scoped communities, notifications, evaluation cases, and public object
references remain product-filterable through Core services. Card Vertex should
use product-lens queries to access card categories, Card Vertex communities,
Card Vertex notifications, Card Vertex evaluation cases, and Card Vertex public
references without reading private inventory fields.

Atomic write workflows are protected by Postgres RPCs. Starting inventory,
purchase, lot purchase, sale, trade, and safe inventory field updates route
through database functions that create or update the required transaction,
transaction line, ownership event, basis event, basis lineage, inventory, and
audit records together. The TypeScript service layer routes app code through
these safe workflows.

Direct writes to critical Core tables are hardened. App code must not directly mutate financial or history tables such as `transactions`, `transaction_lines`, `ownership_events`, `basis_events`, `basis_lineage_edges`, or `audit_events`. App code must also not directly mutate sacred inventory fields such as `true_basis`, owner context, `category_id`, `asset_variant_id`, or `current_value_snapshot_id`.

Cost basis is sacred. Missing basis is `null`; known zero basis is `0`. Market value and basis are separate concepts, and trade value and basis are separate concepts. Financial basis changes must be explainable through `basis_events`.

Lot purchase allocation freezes basis at acquisition time. `create_lot_purchase_transaction`
creates multiple inventory items under one `purchase_lot` transaction and
allocates `purchase_price + buyer_fees + tax + shipping +
other_acquisition_costs` across the incoming items. This pass supports `manual`
and `equal` allocation only. Manual allocations must sum to the total lot basis,
with only a tiny rounding tolerance that is applied to the final item and
recorded in metadata. Equal allocation divides the total lot basis across all
items and assigns any rounding remainder to the final item. Each item receives
its allocated `true_basis`, current value remains separate, and no public object
references are created.

Sale realization freezes basis at sale time. `create_sale_transaction`
calculates canonical selling-cost buckets, net proceeds, and realized
profit/loss as `net_proceeds - true_basis`, then writes the sale transaction,
transaction lines, ownership event, `sale_realization` basis event, audit event,
and sold inventory state atomically. It must not rewrite `true_basis`, must not
update current value, must reject missing basis, and must allow known zero
basis.

Evaluation / Certification Lifecycle now exists as the product-neutral Core
concept for grading, authentication, appraisal, condition review, restoration
review, certification, service records, and provenance review. Products
translate that backbone into niche-specific workflows: Card Vertex grading
submissions through future provider workflows with grade returned, cert number,
and slab images; Comic Vertex grading, restoration review, page quality, and
certification; Watch Vertex authentication, service records, condition review,
appraisal, and box/papers verification; Coin Vertex grading, certification,
holder, and mint/state details; and Memorabilia authentication, appraisal,
certificate of authenticity, and provenance review.

Evaluation results do not automatically mutate `true_basis` or market value. A
grading fee, authentication fee, appraisal fee, or certification fee may be
capitalized into basis only through the explicit
`apply_evaluation_basis_increase` RPC, which writes a basis event, evaluation
event, and audit event. Items with `true_basis = null` reject basis increase for
now because missing basis must not be silently converted into known basis.
`current_value` is not updated by evaluation results or by explicit evaluation
basis increases. Basis and market value remain separate.

Ownership lineage is a core platform concept. Ownership and status changes must be explainable through `ownership_events`.

Trade lineage is a core platform concept. Trades must be explainable through `basis_lineage_edges`, frozen transaction line values, basis events, and ownership events.

Audit events record important system actions so Core workflows remain inspectable.

Value evidence is separate from cost basis. Core may store owner-scoped
`comp_snapshots` as early market-value evidence infrastructure, but comps do not
own inventory, do not mutate `true_basis`, and do not create `basis_events`.
Excluded comps may remain visible as research evidence, but they must not affect
estimated value summaries. Future Card Vertex comp workflows must respect Core
RLS/privacy and should be reviewed before any write path is exposed.

Community follows the same product lens boundary. Satera owns the reusable
Community Core infrastructure, while products own product-specific community
experiences. Community participation, product profiles, and entitlements must
not override private inventory ownership.

Satera Community Core MVP includes product-scoped communities, channels,
memberships, roles, messages, safe public object reference message attachments,
basic moderation reports/actions, audit events, and RLS visibility controls.
Pass 2 adds TypeScript read helpers and RPC-only mutation services for those
Community Core workflows, plus read-only Internal Inspector visibility for
communities, messages, references, reports, and actions.

Satera Moderation Foundation now hardens Core trust and safety infrastructure
with durable user restrictions, moderator/admin notes, appeal records,
restriction-aware posting checks, moderation RPCs, RLS policies, and audit
events. Satera owns moderation state, enforcement, decisions, appeals, and
audit trail. External moderation providers may provide future signals, but
they do not own final moderation state. Normal users should not see hidden,
removed, or deleted community messages; moderators and admins can inspect
moderated content in scope.

Satera Notification Foundation is Core platform infrastructure. Satera owns
durable notification events and recipient notification state, including
read/unread, dismissed, and archived status. Notifications can be scoped to a
product and attached to primary and related entity context. Payloads use
`safe_metadata` only and must not expose private inventory fields. Products
render notification experiences later. External delivery providers such as
Resend, push, SMS, webhook, realtime, and background job systems are future
delivery layers only; no provider delivery is implemented in this foundation.

Messages, trade posts, listings, showcases, and future Card Vertex drag/drop
sharing must attach safe public object references instead of private inventory
rows. The same Core pattern should work for cards, comics, watches, games, and
future product lenses.

Community message references snapshot only safe `public_object_references`
display fields. They must not include true basis, purchase price, profit, ROI,
location, private notes, private tags, ownership history, private transaction
history, or evaluation/certification costs such as grading costs.

Community Core is not a visible generic Satera social network. There is no
global Satera feed, algorithmic feed, public viral profile network, Card Vertex
Community Dock, Vertex Pro UI, product-facing moderation dashboard, realtime
presence, LiveKit, voice, video, screenshare, uploaded video, media processing,
AI moderation, automated moderation providers, or advanced moderation
automation in this pass.

Internal Inspector coverage for Community Core and moderation records is
read-only. It exists for Core audit and debugging visibility and must not add
edit buttons, forms, message composition, moderation write UI, product-facing
moderation dashboards, or product-specific community experiences.
Notification Inspector coverage is also read-only and must not add notification
composition UI, product notification UI, preference UI, realtime behavior, or
delivery-provider controls.

Future lot purchase work may add estimated-value proportional allocation,
comp-based allocation, user-defined allocation templates, and receipt/import
assistance. Those workflows are not part of the current Core RPC.

Community architecture is documented in `docs/architecture/COMMUNITY_CORE.md`.
Future media and moderation alignment is documented in
`docs/architecture/TECHNOLOGY_ROADMAP.md`.
Product app boundary planning is documented in
`docs/architecture/PRODUCT_APP_BOUNDARY.md`.

Card Vertex inventory/community workspace planning is documented in
`docs/products/card-vertex/INVENTORY_WORKSPACE_AND_COMMUNITY.md`. Vertex Pro
cross-product community management planning is documented in
`docs/products/vertex-pro/CROSS_PRODUCT_COMMUNITY_MANAGEMENT.md`.
The Card Vertex product-domain data-model gap assessment is documented in
`docs/products/card-vertex/PRODUCT_DOMAIN_DATA_MODEL_GAP_ASSESSMENT.md`.
The proposed Card Vertex card identity and catalog strategy is documented in
`docs/products/card-vertex/CARD_IDENTITY_AND_CATALOG_STRATEGY.md`; it treats
current generic asset family and variant records as temporary infrastructure,
not the approved sports-card catalog model, and treats grade and certification
as owned-card/evaluation state rather than catalog identity by default. The
proposed Card Vertex grading workspace and certification lifecycle is
documented in
`docs/products/card-vertex/GRADING_WORKSPACE_AND_CERTIFICATION_LIFECYCLE.md`.
It translates the Core evaluation/certification lifecycle into Card Vertex
submission preparation, provider/service language, inventory availability
behavior, Return Review, certification handling, cost allocation review, and
explicit basis capitalization decisions without adding product-specific grading
truth to Core. The proposed Draft Lot Workspace architecture is documented in
`docs/products/card-vertex/DRAFT_LOT_WORKSPACE_ARCHITECTURE.md`; it keeps
long-lived incomplete lot preparation in Card Vertex and reserves canonical
inventory, transaction, ownership, basis, lineage, and audit creation for the
existing Satera Core lot-purchase RPC at explicit commit.
The proposed Card Vertex Trade Network and Logged Trade contract is documented
in `docs/products/card-vertex/TRADE_NETWORK_AND_LOGGED_TRADE_CONTRACT.md`;
it keeps trade discovery, availability intent, Looking For, interest,
conversation, private negotiation, and collector-facing review in Card Vertex
while reserving completed ownership, basis, lineage, and audit truth for the
existing Satera Core trade transaction.
