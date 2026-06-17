# Next Steps

## Current Priority

1. Product App Boundary / Monorepo Restructure.
2. Comp/Value Workflow write path.
3. Card Vertex product shell later.

Product Lens Framework hardening is complete as a Core read-only service
boundary. Products are isolated experiences over shared Satera Core data, not
data silos. Product access, product profiles, organization product profiles,
entitlements, category mappings, public references, communities, notifications,
and evaluation cases are queried through explicit product context while
inventory privacy remains owner/workspace/organization-controlled.

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

## Future Lot Purchase Work

1. Estimated-value proportional allocation.
2. Comp-based allocation.
3. User-defined allocation templates.
4. Receipt/import-assisted allocation.

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
