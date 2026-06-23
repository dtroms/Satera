# Next Steps

## Current Priority

1. Review and approve Card Vertex Collector Profile and Trust Contract.
2. Define Card Vertex Goals and Signals contract.
3. Define Card Vertex Search, Dashboard, and comp write-path contract.
4. Define Card Vertex MVP Product Experience Specification.
5. Create a Card Vertex schema-design proposal only after preceding product
   decisions are approved.
6. Plan real workspace/build configuration for `apps/card-vertex`.
7. Create real Card Vertex app root only after product-domain plan is approved.
8. Build Card Vertex Inventory Workspace shell.
9. Add Card Vertex workflows incrementally.

Available planning documents:

1. [`CARD_IDENTITY_AND_CATALOG_STRATEGY.md`](products/card-vertex/CARD_IDENTITY_AND_CATALOG_STRATEGY.md)
2. [`DRAFT_LOT_WORKSPACE_ARCHITECTURE.md`](products/card-vertex/DRAFT_LOT_WORKSPACE_ARCHITECTURE.md)
3. [`GRADING_WORKSPACE_AND_CERTIFICATION_LIFECYCLE.md`](products/card-vertex/GRADING_WORKSPACE_AND_CERTIFICATION_LIFECYCLE.md)
4. [`TRADE_NETWORK_AND_LOGGED_TRADE_CONTRACT.md`](products/card-vertex/TRADE_NETWORK_AND_LOGGED_TRADE_CONTRACT.md)
5. [`COLLECTOR_PROFILE_AND_TRUST_CONTRACT.md`](products/card-vertex/COLLECTOR_PROFILE_AND_TRUST_CONTRACT.md)

This sequence is a planning gate. Documenting a future capability does not
authorize implementation, and steps must not be skipped merely because Core
infrastructure already exists.

Product Lens Framework hardening is complete as a Core read-only service
boundary. Products are isolated experiences over shared Satera Core data, not
data silos. Product access, product profiles, organization product profiles,
entitlements, category mappings, public references, communities, notifications,
and evaluation cases are queried through explicit product context while
inventory privacy remains owner/workspace/organization-controlled.

`packages/satera-core` now provides the first real shared package boundary. It
re-exports the active `lib/core` implementation without moving source logic,
so existing imports remain compatible and runtime behavior is unchanged. The
current root `app/` and `lib/core` structure remains active. The new
`apps/card-vertex` directory is documentation/scaffolding only: it is not
runnable and contains no Card Vertex UI. Source logic may migrate into the
package gradually in future passes; runnable app-root creation is a later
milestone after intentional workspace/build planning. Card Vertex is intended
to become a standalone product
surface at `cardvertex.com`, while Satera may later host account/billing,
platform/admin, internal tooling, Satera Portfolio, or other cross-product
surfaces. Satera is not the generic marketplace/dashboard MVP. Card Vertex
must not get its own Supabase database or Supabase project.

Future app roots may include `card-vertex`, `satera`, `vertex-pro`, and
`satera-portfolio`. Future packages may include `ui` and `config`. Product apps
should eventually consume Satera Core services and RPC wrappers through
`packages/satera-core`. Future Vercel setup may use multiple Vercel projects
pointing at app roots in this repo, but that configuration comes later.

This placeholder pass adds no Vercel/domain configuration and makes no
Supabase changes.

The canonical product boundary is documented in
[`SATERA_CARD_VERTEX_OWNERSHIP.md`](architecture/SATERA_CARD_VERTEX_OWNERSHIP.md),
with Card Vertex workflow distinctions in
[`PRODUCT_DOMAIN_AND_WORKFLOWS.md`](products/card-vertex/PRODUCT_DOMAIN_AND_WORKFLOWS.md).
The current Card Vertex product-domain data-model gap assessment is documented
in
[`PRODUCT_DOMAIN_DATA_MODEL_GAP_ASSESSMENT.md`](products/card-vertex/PRODUCT_DOMAIN_DATA_MODEL_GAP_ASSESSMENT.md).
The proposed Card Vertex identity and catalog strategy is documented in
[`CARD_IDENTITY_AND_CATALOG_STRATEGY.md`](products/card-vertex/CARD_IDENTITY_AND_CATALOG_STRATEGY.md).
The proposed Draft Lot Workspace architecture and lifecycle is documented in
[`DRAFT_LOT_WORKSPACE_ARCHITECTURE.md`](products/card-vertex/DRAFT_LOT_WORKSPACE_ARCHITECTURE.md).
The proposed Card Vertex grading workspace and certification lifecycle is
documented in
[`GRADING_WORKSPACE_AND_CERTIFICATION_LIFECYCLE.md`](products/card-vertex/GRADING_WORKSPACE_AND_CERTIFICATION_LIFECYCLE.md).
The proposed Card Vertex Trade Network and Logged Trade contract is documented
in
[`TRADE_NETWORK_AND_LOGGED_TRADE_CONTRACT.md`](products/card-vertex/TRADE_NETWORK_AND_LOGGED_TRADE_CONTRACT.md).
The proposed Card Vertex Collector Profile and Trust contract is documented in
[`COLLECTOR_PROFILE_AND_TRUST_CONTRACT.md`](products/card-vertex/COLLECTOR_PROFILE_AND_TRUST_CONTRACT.md).

Satera Evaluation / Certification Lifecycle is now complete as product-neutral
Core infrastructure. It stores evaluation cases, items, immutable lifecycle
events, and future-safe attachment records. It supports grading,
authentication, appraisal, certification, service, condition review,
restoration review, and provenance review without building product-specific UI
or provider integrations.

Evaluation results do not automatically mutate `true_basis` or market value.
Evaluation costs may increase `true_basis` only through explicit audited basis
increase. Items with `true_basis = null` reject basis increase for now, and
`current_value` is not updated by evaluation result recording or basis
increase.

Lot Purchase RPC is now complete as a strict Satera Core RPC. It creates
multiple inventory items under one `purchase_lot` transaction, preserves
`purchase_price + buyer_fees + tax + shipping + other_acquisition_costs` as the
total lot basis pool, supports `manual` and `equal` allocation, freezes
allocated `true_basis` per item, writes transaction lines, ownership events,
basis events, basis lineage edges, and an audit event, and does not infer
current value from basis.

Sale Transaction RPC is now complete as a strict Satera Core RPC. It completes
the purchase -> own -> sell -> realize profit/loss lifecycle by writing the
sale transaction, transaction lines, ownership event, sale realization basis
event, audit event, and sold inventory state atomically. Sale realization
freezes basis at sale time; it does not rewrite `true_basis` and does not
update current value.

Satera Notification Foundation now exists as platform infrastructure. Core owns
durable notification events, recipient-specific read/dismiss/archive state,
safe metadata, product/entity context, audit trail, and future delivery-attempt
records. Products render notification experiences later. External delivery
providers such as Resend, push, SMS, webhooks, realtime systems, and background
jobs remain future infrastructure only.

Satera Moderation Foundation hardening now exists as platform infrastructure.
Core owns durable user restrictions, internal moderation notes, appeal records,
moderation decisions, enforcement state, and audit trail. Community messages
respect active restrictions, normal users do not see hidden/removed/deleted
content, and moderators/admins can inspect moderated content in scope.

Satera Community Core MVP Pass 2 also exists as platform infrastructure.
Community messages can attach safe public object references instead of private
inventory rows, TypeScript mutations route through RPCs only, and the Internal
Inspector can inspect community and moderation records through read-only views.
Product-specific community UI and product-facing moderation UI, including Card
Vertex community surfaces and the Community Dock, come later.

Products can translate the Core evaluation/certification backbone into
niche-specific workflows: Card Vertex grading submissions and cert numbers,
Comic Vertex restoration review and page quality, Watch Vertex authentication
and service records, Coin Vertex holder and mint/state details, and Memorabilia
certificates of authenticity or provenance review.

Evaluation results do not automatically increase `true_basis` or market value.
A grading fee, authentication fee, appraisal fee, or certification fee may be
capitalized into basis only through explicit audited basis increase. A PSA 10,
authenticated watch, certified comic, or appraised item affects market value
separately from basis unless actual costs were incurred.

Future evaluation work includes provider integrations, submission package
generation, label/cert image uploads, automated notifications, product-specific
UI, Card Vertex grading workflow, Watch Vertex service/appraisal workflow, and
Comic Vertex grading/restoration workflow.

## Future Product Work

1. Keep Satera Core focused on durable truth, permissions, financial workflows,
   lineage, public references, community, moderation, notifications, audit, and
   entitlements.
2. Build Satera Portfolio after the Core truth layer and product lens framework
   are stable.
3. Build Card Vertex from product documentation, starting with manual comp UX
   only after Core write boundaries are approved.
4. Build Vertex Pro after organization/product profile workflows are ready for
   operator-facing surfaces.

## Future Extraction Guardrails

1. Do not move everything in one pass.
2. Extract Satera Core services first.
3. Keep compatibility exports from `lib/core` during transition.
4. Keep Supabase migrations and tests at the repo root.
5. Keep database truth centralized in Satera Core.
6. Keep product-specific logic out of Satera Core.
7. Keep Satera financial truth logic out of product UI.
8. Product apps should call service functions and RPCs.
9. Product apps should not call direct table mutations.
10. Product apps may use safe read queries through Satera Core services.
11. Card Vertex should use product-lens queries rather than unscoped inventory
    queries.

## Future Lot Purchase Work

1. Review and approve the Draft Lot Workspace Architecture and Lifecycle.
2. Create a Card Vertex schema-design proposal for Draft Lot workspaces only
   after product-domain decisions are approved.
3. Add a future draft-to-commit adapter that prepares payloads for the existing
   Satera Core lot-purchase RPC without replacing it.
4. Consider estimated-value proportional allocation only as user-approved
   assistance.
5. Consider comp-based allocation only as user-approved assistance, not MVP
   truth.
6. Consider user-defined allocation templates.
7. Consider receipt/import-assisted allocation.

## Future Card Vertex Workflow

1. Inventory workspace shell.
2. Saved filters.
3. Search within current filter.
4. Table controls.
5. Column customization.
6. Density modes.
7. Bulk mode.
8. Card Context Drawer.
9. Community Dock.
10. Drag/drop public card references.
11. Comp display and discussion.
12. Trade/sale/wanted posts.
13. Card Vertex Grading Workflow, powered by Satera Evaluation /
    Certification Lifecycle.

## Future Satera Community Core

1. Notification hooks from community workflows into the Core notification
   foundation.
2. Future post/listing/trade-specific workflows.
3. Realtime presence later.
4. LiveKit, uploaded media, and media processing later.

Public references follow the reusable Core pattern:

```text
private inventory item -> safe public object reference -> product/community/listing attachment
```

They must never expose true_basis, purchase price, profit, location, private
notes, private tags, ownership history, or private transaction history.

Card Vertex should use product-lens queries for card categories, Card Vertex
communities, Card Vertex notifications, Card Vertex evaluation cases, and Card
Vertex public references. Card Vertex at `cardvertex.com` should continue to
mutate Satera Core only through approved Core services/RPCs.

## Future Vertex Pro

1. Organization-owned cross-product community management.
2. Multi-product moderation queue.
3. Staff permissions by product, community, and channel.
4. Cross-product community analytics.
5. Operator UI for organization-owned communities across products.

## Future Media

1. LiveKit for branded voice and screen-share rooms.
2. Mux or Cloudflare Stream for uploaded video playback.
3. External moderation providers only as signal sources.

Automated moderation providers remain future signal sources only. Satera owns
moderation state, enforcement, decisions, appeals, and audit.
