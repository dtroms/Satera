# Satera Core Architecture

Satera Core is the truth layer for Satera. It owns the durable records for private inventory, transactions, ownership history, financial basis, lineage, and auditability.

Products are lenses over Core records. Card Vertex, Vertex Pro, Satera Portfolio, and future products may present different workflows or category-specific experiences, but they do not own inventory and must not become alternate sources of truth.

Product apps may eventually become separate app roots, domains, and
deployments, but not separate data platforms. Card Vertex should eventually
live at `cardvertex.com` as its own standalone product surface. Satera should
eventually live separately at `satera.app` as the platform/powering layer,
portfolio/admin surface, or future platform home. Both surfaces should continue
to use the same Satera Core backend and the same Satera Supabase database.
Card Vertex should not have a separate Supabase project.

Satera owns the database, auth, permissions, inventory truth, transactions,
basis, lineage, public object references, communities, moderation,
notifications, audit, and entitlements. Card Vertex owns the card-specific
product experience, UI, workflows, terminology, layout, and product behavior.
Card Vertex must call Satera Core services and RPCs instead of directly
mutating Satera Core tables. Product UI must not contain Satera financial truth
logic.

The future Product App Boundary / Monorepo Restructure milestone may introduce
separate app roots and shared packages before the Card Vertex product shell is
built:

```text
Satera/
├── apps/
│   ├── card-vertex/        deployed to cardvertex.com
│   ├── satera/             deployed to satera.app
│   ├── vertex-pro/         future
│   └── satera-portfolio/   future
├── packages/
│   ├── satera-core/        shared service layer / RPC wrappers
│   ├── ui/                 shared primitives
│   └── config/             shared config
└── supabase/
    ├── migrations/
    └── tests/
```

That structure is planning only. It should preserve the service/API boundary
so Card Vertex can become a separate app root without rewriting the Core logic.
It should not introduce a separate Card Vertex database or Supabase project.

Inventory belongs to users, workspaces, or organizations. Every inventory item carries an owner context, and privacy starts there. Row Level Security protects row visibility so a product profile, entitlement, or product-specific surface cannot override private inventory boundaries.

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

Evaluation / Certification Lifecycle is the product-neutral Core concept for
grading, authentication, appraisal, condition review, restoration review,
certification, service records, and provenance review. Products translate that
backbone into niche-specific workflows: Card Vertex grading submissions through
PSA/BGS/SGC/CGC with grade returned, cert number, and slab images; Comic Vertex
grading, restoration review, page quality, and certification; Watch Vertex
authentication, service records, condition review, appraisal, and box/papers
verification; Coin Vertex grading, certification, holder, and mint/state
details; and Memorabilia authentication, appraisal, certificate of
authenticity, and provenance review.

Evaluation cost may increase `true_basis`. Evaluation result does not
automatically increase `true_basis`. A grading fee, authentication fee,
appraisal fee, or certification fee may be capitalized into basis when
appropriate. A PSA 10, authenticated watch, certified comic, or appraised item
may affect market value, but the result itself does not mutate basis except for
actual costs incurred. Basis and market value remain separate.

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

Card Vertex inventory/community workspace planning is documented in
`docs/products/card-vertex/INVENTORY_WORKSPACE_AND_COMMUNITY.md`. Vertex Pro
cross-product community management planning is documented in
`docs/products/vertex-pro/CROSS_PRODUCT_COMMUNITY_MANAGEMENT.md`.
