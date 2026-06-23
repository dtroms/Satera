# Card Vertex Product Domain Data Model Gap Assessment

This assessment compares approved Card Vertex workflows against the current
Satera Core schema, RPCs, service layer, and architecture documentation. It is
documentation only. It does not authorize migrations, RPCs, routes, UI, service
work, provider integrations, or build configuration.

The proposed Card Vertex card identity and catalog strategy is documented in
[`CARD_IDENTITY_AND_CATALOG_STRATEGY.md`](CARD_IDENTITY_AND_CATALOG_STRATEGY.md).
That strategy is the decision gate before schema design and treats current
generic `asset_families` and `asset_variants` as temporary/generic Core
reference infrastructure rather than an approved sports-card catalog model.
The Draft Lot Workspace architecture and lifecycle is documented in
[`DRAFT_LOT_WORKSPACE_ARCHITECTURE.md`](DRAFT_LOT_WORKSPACE_ARCHITECTURE.md)
and is the decision gate before any Draft Lot schema proposal.
The Grading Workspace and Certification Lifecycle contract is documented in
[`GRADING_WORKSPACE_AND_CERTIFICATION_LIFECYCLE.md`](GRADING_WORKSPACE_AND_CERTIFICATION_LIFECYCLE.md)
and is the decision gate before any Card Vertex grading schema proposal.

## Baseline

Satera Core owns canonical truth, privacy, access, audit, reusable primitives,
financial integrity, and cross-product continuity. Card Vertex owns
card-specific semantics, card-specific workflows, card-specific intelligence,
and the collector-facing experience.

A Card Vertex-specific record may live in the shared Satera database without
becoming a generic Satera Core concept. Possible future reuse is not enough to
generalize a concept now.

## Part 1 - Current Core Capability Inventory

| Area | Implemented schema / enums | Implemented RPCs | Service-layer support | Privacy / RLS behavior | Card Vertex can use now | Important limitations |
| --- | --- | --- | --- | --- | --- | --- |
| Products and product categories | `products`, `categories`, `product_categories`; `product_type`, `product_status`; Card Vertex category mappings are seeded | `can_access_product`, `is_category_in_product`, `inventory_item_belongs_to_product` | `lib/core/products`, `lib/core/product-lens`, `packages/satera-core` re-exports | Active products and product categories are readable to authenticated users; product access does not override inventory privacy | Resolve Card Vertex product context, category set, summaries, and product-scoped reads | No card catalog semantics; category membership is coarse product scoping |
| Workspaces and organizations | `workspaces`, `workspace_members`, `organizations`, `organization_memberships`, account/org entitlements and product profiles | `is_workspace_member`, `is_organization_member`, entitlement helpers | `lib/core/organizations`, product lens entitlement/context helpers | Owner, workspace, organization, product admin, and platform admin RLS checks | Scope Card Vertex inventory and workflows to workspace/organization context | No Card Vertex collector profile beyond product profile JSON; no workflow-specific workspace preferences |
| Inventory items | `inventory_items`; `condition_type`, `inventory_status`, `inventory_availability`, `inventory_intent`; locations and images exist | `create_starting_inventory_transaction`, `create_purchase_transaction`, `create_lot_purchase_transaction`, `create_trade_transaction`, `create_sale_transaction`, `update_inventory_item_safe_fields` | `lib/core/inventory`, `lib/core/transactions`, product lens inventory filtering | Owner/workspace/org RLS; direct writes to sacred fields are blocked; safe fields mutate through RPC | Store canonical owned cards as inventory items, filter by Card Vertex categories, update safe status/availability/intent fields | Requires existing `asset_variant_id`; no card identity fields; no Draft Lot or Card Vertex workspace records |
| Asset families and variants | `asset_families`, `asset_variants` with generic `attributes` JSON; categories and collections | None specific | Read access through internal inspector/product services; transaction inputs require variant IDs | Catalog rows are read according to Core RLS/admin policies; inventory privacy remains separate | Represent a generic catalog/family/variant pointer for inventory and comps | Not a sports-card catalog; no normalized player, set, parallel, card number, grade, cert, aliases, or image policy |
| Collections and categories | `collections`, `categories`, `product_categories` | Product-lens helper RPCs | Product and internal read helpers | Product categories readable through product access; collections category-scoped | Basic grouping for Card Vertex categories/collections | Collections are not a complete set/subset/release model |
| Transactions | `transactions` with `transaction_type`, source, counterparty, notes, metadata | Starting inventory, purchase, lot purchase, sale, trade RPCs | `lib/core/transactions` RPC wrappers | Owner/workspace/org RLS; direct client writes revoked on hardened Core tables | Commit completed financial events and history through Core | No draft/intake records; no formal proposal or negotiation state |
| Transaction lines | `transaction_lines` with inventory/cash/fee/tax/shipping/basis/value/note line types, directions, frozen basis/value fields, metadata | Written by transaction RPCs | Read through lineage/internal helpers; no direct mutation service | Read under transaction visibility; writes only through RPC | Explain sale/trade/lot line items and frozen values | Not a product workflow store; no draft line editing before commit |
| Ownership events | `ownership_events`; `ownership_event_type` includes purchase, lot purchase, trade in/out, sale, grading submission/return, consignment, correction, archive | Written by transaction and evaluation-related workflows where applicable | `lib/core/lineage`, internal read helpers | Owner/workspace/org visibility; direct writes hardened | Build owner-only activity/lineage views | Not a public activity feed; no Card Vertex labels/grouping |
| Basis events and lineage | `basis_events`, `basis_lineage_edges`; basis event types include starting, purchase, lot allocation, trade allocation, grading/evaluation cost, sale realization, corrections | Written by transaction RPCs and `apply_evaluation_basis_increase` | `lib/core/lineage`, transaction services | Financial truth protected by RLS and direct-write hardening | Explain basis, lot allocation, trade allocation, sale realization, and capitalized evaluation costs | Missing basis blocks sale/trade/evaluation basis increase in some flows; no product-side basis logic should be added |
| Purchases | `transactions` type `purchase_single`, `transaction_lines`, ownership and basis events | `create_purchase_transaction` | `createPurchaseTransaction` | Owner/workspace/org checks in RPC and RLS | Commit single-card acquisitions | No receipt parsing, OCR, draft intake, or card identity resolution |
| Lot purchases | `transactions` type `purchase_lot`; `transaction_lines.metadata`; basis lineage | `create_lot_purchase_transaction` | `createLotPurchaseTransaction` | Workspace membership required; active product/category validation when product_id is provided; direct final commit only | Commit a finalized lot into inventory with allocated basis | Workspace-only; existing variants required; one physical copy per item; only manual/equal allocation; no draft lifecycle |
| Sales | `transactions` type `sale`; sale realization basis event | `create_sale_transaction` | `createSaleTransaction` | Owner/workspace/org checks; requires item owner context; missing basis rejected, known zero allowed | Record final sale terms and realized profit/loss | Sale intent/listing state is not modeled beyond inventory intent/availability; no marketplace execution |
| Trades | `transactions` type `trade`; trade in/out ownership events; trade allocation basis events; lineage edges | `create_trade_transaction` | `createTradeTransaction` | Owner/workspace/org checks; outgoing item access; missing outgoing basis rejected | Record completed logged trades with cards in/out, cash, and costs | No Trade Network discovery, proposal, saved opportunity, conversation, or partner trust contract |
| Evaluation / certification lifecycle | `evaluation_cases`, `evaluation_case_items`, `evaluation_events`, `evaluation_attachments`; status/type checks; cost fields | `create_evaluation_case`, `add_evaluation_case_item`, `update_evaluation_case_status`, `record_evaluation_result`, `apply_evaluation_basis_increase` | `lib/core/evaluations`, product lens evaluation reads | Workspace RLS; safe metadata checks; direct writes revoked | Power Card Vertex grading cases, item membership, result grade/cert number, costs, and basis increase decisions | No grading-company-specific contract, submission package, provider integration, upload UI, prediction fields, returned-review UX, or automatic inventory availability changes |
| Public object references | `public_object_references`; safe metadata guards | `create_public_object_reference`, `update_public_object_reference_display`, `revoke_public_object_reference` | `lib/core/public-references`, product lens public reference reads | Owner/member read; authenticated users can read active exposed references; private keys blocked; direct writes revoked | Share safe public card references into community/listing/trade surfaces | Public references are not inventory; no Card Vertex rendering or card-specific reference contract yet |
| Communities, messages, moderation | `communities`, `community_channels`, `community_memberships`, `community_messages`, `community_message_references`, `moderation_reports`, `moderation_actions`, `user_restrictions`, `moderation_notes`, `moderation_appeals` | Community create/channel/join/message/report/moderate; restriction/note/appeal RPCs | `lib/core/community`; RPC-only mutation services | Product-scoped community RLS; restrictions block posting; safe public refs only for message attachments; direct writes revoked | Card Vertex can consume product communities and attach public references later | No Community Dock, realtime, media, product-facing moderation UI, posts/comments, or Trade Network conversations |
| Notifications | `notification_events`, `notifications`, `notification_delivery_attempts` | `create_notification_event`, read/dismiss/archive RPCs | `lib/core/notifications`, product lens notification reads | Recipients read own notifications; product/platform admin reads by scope; safe metadata only; direct writes revoked | Product-scoped Card Vertex notification lists later | No delivery providers, preference UI, realtime delivery, or Card Vertex wording/grouping |
| Product lens | No new product-specific truth; uses product/profile/entitlement/category/public ref/community/notification/evaluation/inventory tables | `can_access_product`, `is_category_in_product`, `inventory_item_belongs_to_product` | `lib/core/product-lens`, `packages/satera-core` | Product access layered over Core privacy; inventory first filtered by owner/workspace/org, then by product categories | Safe read boundary for Card Vertex app surfaces | Read-only; not search/ranking; no product-domain records |
| Comp snapshots / evidence | `comp_snapshots`; Card Vertex comp enums for source, capture, verification, match quality, exclusion, confidence; owner/workspace/org scope | None for writes | `lib/core/comps` read/calculation helpers | Select allowed; insert/update/delete revoked; owner/member/admin RLS | Read existing owner-scoped evidence and calculate summaries | No reviewed write path, no catalog-level matching contract, no admin queue service, no extension write path |
| Audit events | `audit_events` | Written by Core RPCs | Internal read helpers | Platform/admin and owner-scope visibility depending policies; direct app writes hardened | Internal inspection and activity source facts | Not a product-facing timeline by itself; must not leak private financial/audit details |

## Part 2 - Approved Card Vertex Domain Assessments

### 1. Card Identity and Catalog

- Product behavior required: identify sports cards by player, team, sport,
  league, manufacturer, release year, set, subset, card number, parallel,
  serial numbering, autograph/memorabilia attributes, rookie designation, raw
  versus graded state, grading company, grade, certification number, aliases,
  images, and normalized names.
- Existing Satera support: generic categories, collections, asset families,
  asset variants, inventory item pointers, generic attributes JSON, public
  references, asset images, and comp attachment fields.
- What can be represented now: a card inventory item can point to a generic
  asset variant and category, optionally a collection, condition type, image,
  and comp snapshot evidence.
- Missing records or contracts: normalized card identity, release/set/subset
  rules, variant/parallel semantics, graded versus raw identity boundaries,
  aliases, certification identity, catalog images, catalog provenance, and
  source-of-truth policy.
- Product decisions still needed: whether Card Vertex begins with
  user-created catalog records, curated seed catalog, partner/provider catalog,
  or hybrid; how to handle uncertain identities; whether graded certification
  is an item attribute, evaluation result, catalog variant, or display overlay;
  image licensing and fallback strategy.
- Recommended ownership: Card Vertex first, with Satera preserving inventory
  references and access guarantees.
- Recommended phase: decision work before schema design.
- Do not build yet: catalog ingestion, provider sync, automated matching, or
  generic Satera catalog primitives.

### 2. Inventory Workspace

- Product behavior required: dense table-first card workspace with saved
  filters, search within filter, columns, density modes, bulk actions, context
  drawer, community dock, card-specific display, owner/public permission views.
- Existing Satera support: product-lens inventory reads, inventory status,
  availability, intent, safe inventory updates, public references, communities,
  notifications, evaluation cases.
- What can be represented now: card inventory rows by product category and
  workspace, status/availability/intent such as sell/trade/grade/research, and
  owner-only financial fields under RLS.
- Missing records or contracts: saved filters, column preferences, Card Vertex
  card display contract, bulk workflow contracts, drag/drop public reference
  behavior, context drawer aggregation.
- Product decisions still needed: first MVP filter set, bulk actions allowed
  before product records exist, default columns, private/public field matrix.
- Recommended ownership: Card Vertex experience and product-domain records;
  Satera Core for inventory truth and safe mutation.
- Recommended phase: after identity and product-domain contracts.
- Do not build yet: UI shell, routes, realtime dock, or portfolio UI.

### 3. Card Context Drawer

- Product behavior required: right-side drawer aggregating identity, value,
  comps, lineage, images, notes, activity, community mentions, and actions.
- Existing Satera support: inventory, comp snapshots, lineage, public
  references, asset images, evaluation cases, community message references,
  audit events.
- What can be represented now: owner-only lineage and financial history, safe
  public reference display, comp evidence, evaluation result fields.
- Missing records or contracts: Card Vertex drawer aggregation contract,
  card-specific tabs, permission-filtered activity selection, public mention
  contract, image roles for front/back/slab/condition.
- Product decisions still needed: exact owner/public tab content, action list,
  what counts as activity, and how comp confidence appears.
- Recommended ownership: Card Vertex presentation and aggregation; Core source
  records remain canonical.
- Recommended phase: after inventory workspace contract.
- Do not build yet: drawer UI or new aggregate service.

### 4. Purchase Intake

- Product behavior required: capture single-card purchase terms, seller/source,
  notes, identity, costs, and review before commit.
- Existing Satera support: single purchase RPC, transactions, transaction
  lines, ownership events, purchase basis events.
- What can be represented now: finalized purchase of one known variant with
  acquisition costs and owner context.
- Missing records or contracts: draft purchase intake, uncertain card
  identity, receipt/source evidence, marketplace-specific fields, image intake.
- Product decisions still needed: whether purchase intake is a Draft Lot
  subset, a separate Card Vertex draft, or immediate commit only in MVP.
- Recommended ownership: Satera final commit; Card Vertex intake/review.
- Recommended phase: after identity and draft workflow decisions.
- Do not build yet: receipt parsing, OCR, marketplace integrations.

### 5. Logged Trades

- Product behavior required: record completed trades with outgoing cards,
  incoming cards, partner context, cash either direction, direct costs, review,
  and post-commit explanation.
- Existing Satera support: trade RPC, trade transaction lines, trade in/out
  ownership events, trade allocation basis events, lineage edges.
- What can be represented now: completed trade truth once incoming cards map
  to existing asset variants and outgoing cards have known basis.
- Missing records or contracts: partner profile relationship, trade center
  draft/review state, card-specific notes, post-trade trust prompts.
- Product decisions still needed: whether partner is free-text, product
  profile reference, community member, or later trade-network participant.
- Recommended ownership: Satera final trade truth; Card Vertex trade center
  workflow and partner context.
- Recommended phase: after card identity and collector profile decisions.
- Do not build yet: proposal/counter/acceptance engine.

### 6. Trade Network

- Product behavior required: discovery of Looking For, available-for-trade
  public references, lightweight interest, saved opportunities, conversations,
  and relationship context.
- Existing Satera support: public object references, product profiles,
  communities/messages, moderation, notifications, completed trade facts.
- What can be represented now: safe public card references in product-scoped
  communities and completed trade history internally.
- Missing records or contracts: Looking For, availability presentation beyond
  inventory intent, interest, saved opportunity, trade conversation, discovery
  ranking, visibility rules.
- Product decisions still needed: whether conversations are community channels,
  direct message primitives, or Card Vertex-specific opportunity threads; what
  "available for trade" exposes publicly.
- Recommended ownership: Card Vertex first; possible Core promotion only after
  another product proves matching semantics.
- Recommended phase: after public profile and trust contracts.
- Do not build yet: formal trade proposals, escrow, disputes, or automatic
  trade completion.

### 7. Sale Intent and Sale Recording

- Product behavior required: mark cards as available for sale, explain
  projected proceeds, then record actual sale when final terms are known.
- Existing Satera support: inventory intent/availability/status and sale RPC
  for final sale truth.
- What can be represented now: intent `sell`, availability, and final sale
  commit with canonical selling cost buckets.
- Missing records or contracts: sale listing/intent metadata, marketplace
  listing references, price expectations, public sale presentation.
- Product decisions still needed: whether "available for sale" is only
  inventory intent in MVP or requires Card Vertex-specific listing/intent
  records.
- Recommended ownership: Satera sale truth; Card Vertex sale intent and UX.
- Recommended phase: after inventory workspace and public reference decisions.
- Do not build yet: marketplace payments, listing integrations, automated sale
  completion.

### 8. Draft Lot Workspace

- Product behavior required: long-lived draft for candidate cards, incomplete
  identities, source/dealer/show context, notes, key-card highlights, editable
  allocation, review, delete/archive, starting inventory use case, commit, and
  post-commit preservation.
- Existing Satera support: final lot purchase RPC creates inventory and
  historical truth once all items are known.
- What can be represented now: committed lot only.
- Missing records or contracts: draft lot lifecycle, draft candidate items,
  incomplete identity capture, allocation edits before commit, review states,
  archival semantics, commit payload contract, post-commit read-only snapshot.
- Product decisions still needed: draft ownership context, privacy, whether
  starting inventory uses same draft model, and what draft data survives after
  commit.
- Recommended ownership: Card Vertex draft records and workflow; Satera final
  commit truth.
- Recommended phase: foundational Product Domain phase before UI.
- Do not build yet: migrations or changes to `create_lot_purchase_transaction`.

### 9. Grading Workspace

- Product behavior required: submission planning, grading company, service
  level, expected return, predictions, costs, card membership, status tracking,
  grade/cert entry, returned-review, outcome analysis, basis allocation, and
  inventory availability handling.
- Existing Satera support: evaluation/certification lifecycle with cases,
  items, events, attachments, costs, grade/cert result fields, and explicit
  basis increase RPC.
- What can be represented now: grading case, provider name/reference, expected
  return, item membership, costs, statuses, result grade, cert number, and
  basis increase decision.
- Missing records or contracts: grading company enum/policy, service level,
  predicted grade fields, card-specific returned-review workflow, outcome
  analysis, automatic availability/status transitions, submission package
  assets.
- Product decisions still needed: how predictions affect UX, whether service
  levels are controlled values, how to allocate shared costs, whether status
  changes should call inventory safe updates.
- Recommended ownership: Satera lifecycle primitives; Card Vertex grading
  semantics and workspace behavior.
- Recommended phase: after grading mapping and identity decisions.
- Do not build yet: provider integrations, uploads, grading UI, automatic
  basis/value updates.

Detailed lifecycle, return review, correction, availability, certification,
cost allocation, Core mapping, decision matrix, and founder-review decisions
are defined in
[`GRADING_WORKSPACE_AND_CERTIFICATION_LIFECYCLE.md`](GRADING_WORKSPACE_AND_CERTIFICATION_LIFECYCLE.md).
This assessment remains a gap inventory and does not approve schema.

### 10. Community and Card Sharing

- Product behavior required: Community Dock, full community page, drag/drop
  public card references, card discussions, channels, safe attachment display.
- Existing Satera support: product-scoped communities, channels, memberships,
  messages, public reference attachments, moderation, restrictions.
- What can be represented now: Core community messages with safe public object
  reference attachments.
- Missing records or contracts: Card Vertex Dock/page UI, composer behavior,
  card reference rendering, community templates, realtime/presence/media.
- Product decisions still needed: initial channels/templates, whether trade
  conversations use community messages, and card reference display fields.
- Recommended ownership: Satera community infrastructure; Card Vertex
  community experience.
- Recommended phase: after public reference and inventory workspace contracts.
- Do not build yet: realtime, LiveKit, media processing, product-facing
  moderation dashboards.

### 11. Collector Profiles

- Product behavior required: public/private card collector profile, handle,
  display name, focus areas, Looking For, availability context, trust facts,
  and privacy controls.
- Existing Satera support: `product_profiles` and
  `organization_product_profiles` with display name, handle, profile JSON;
  communities and restrictions.
- What can be represented now: minimal product profile identity.
- Missing records or contracts: structured collector focus areas, public
  profile visibility, private settings, profile card/reference attachments,
  relationship/trade summary contract.
- Product decisions still needed: which fields are public, which are private,
  whether Looking For belongs to profile or Trade Network records.
- Recommended ownership: Card Vertex first, using Satera identity/privacy.
- Recommended phase: before Trade Network.
- Do not build yet: generic social graph, followers, or viral profiles.

### 12. Trust and Endorsements

- Product behavior required: explainable trust from completed trade counts,
  repeat partners, positive endorsements, Would Trade Again, community context,
  and visibility-aware relationship facts.
- Existing Satera support: completed trade truth, community membership,
  moderation/restrictions, product profiles, audit.
- What can be represented now: underlying completed trade records and
  community membership are available internally.
- Missing records or contracts: endorsements, repeat partner visibility,
  public/private trust rules, partner identity resolution, trust presentation.
- Product decisions still needed: endorsement vocabulary, who can endorse,
  whether endorsements are public, whether declined/negative feedback exists
  at all.
- Recommended ownership: Card Vertex first; Core may later own reusable
  endorsement primitives only after reuse is proven.
- Recommended phase: after collector profiles and logged trade partner model.
- Do not build yet: star ratings, negative reviews, numerical reputation.

### 13. Goals

- Product behavior required: player, set, rainbow, theme, custom, and trade-up
  goals; goal progress; card matching; collector actions.
- Existing Satera support: identity/privacy and inventory source facts only.
- What can be represented now: no durable goal model; possible manual intent
  via notes/tags is not sufficient as a contract.
- Missing records or contracts: goal records, goal criteria, progress rules,
  card matching, privacy, dashboard/signal relationship.
- Product decisions still needed: goal types for MVP, matching confidence,
  public/private visibility, and whether trade-up goals use value evidence.
- Recommended ownership: Card Vertex first.
- Recommended phase: after card identity strategy.
- Do not build yet: generic Satera Goals.

### 14. Signals

- Product behavior required: explain why a card/opportunity/action matters,
  with source facts, relevance rules, explainability, priority, suppression,
  and dashboard placement.
- Existing Satera support: source facts in inventory, comps, evaluations,
  notifications, community, public references, transactions, and audit.
- What can be represented now: no durable Card Vertex signal contract.
- Missing records or contracts: signal types, inputs, scoring/relevance,
  explanations, suppression, lifecycle, relationship to notifications.
- Product decisions still needed: first signal set, priority rules, whether
  signals are persisted or computed, and dismissal/snooze semantics.
- Recommended ownership: Card Vertex first.
- Recommended phase: after goals/comps/Trade Network contracts.
- Do not build yet: generic Satera Signals or recommendation engine.

### 15. Unified Search

- Product behavior required: Spotlight-style card search across inventory,
  catalog, public references, communities, comps, grading submissions, actions,
  and commands, while respecting permissions.
- Existing Satera support: product-lens reads and table-specific queries.
- What can be represented now: simple scoped reads/filtering, not unified
  search.
- Missing records or contracts: search index, ranking, card-specific query
  interpretation, command/action model, permission boundary tests.
- Product decisions still needed: MVP searchable entities, allowed actions,
  ranking inputs, whether search is local or indexed.
- Recommended ownership: Card Vertex search semantics first; Core indexing
  only if reusable need is proven.
- Recommended phase: after identity and inventory workspace.
- Do not build yet: generic cross-product search platform.

### 16. Market / Comps

- Product behavior required: transparent evidence, source context, inclusion
  and exclusion, confidence, rationale, grade/parallel matching, public/shared
  comp policy, and value display.
- Existing Satera support: owner-scoped comp snapshots with Card Vertex comp
  enums, include/exclude fields, confidence label, source metadata, and read
  helpers; direct writes revoked.
- What can be represented now: read owner-scoped evidence attached to
  inventory/category/family/variant and calculate summaries from included
  comps.
- Missing records or contracts: reviewed write path, catalog-level matching,
  admin review queue, comp provenance policy, public/shared comp governance,
  source permissions.
- Product decisions still needed: allowed sources, manual versus smart
  capture, public sharing rules, confidence methodology, and image/screenshot
  policy.
- Recommended ownership: Core evidence privacy/provenance foundation; Card
  Vertex comp interpretation and workflow.
- Recommended phase: after identity matching decisions.
- Do not build yet: scraping, automated valuation, extension write path.

### 17. Activity History

- Product behavior required: card-focused timeline from ownership,
  transaction, basis, evaluation, comp, public sharing, community, and product
  workflow events.
- Existing Satera support: ownership events, transactions, basis events,
  evaluation events, notification events, community messages/references, audit.
- What can be represented now: owner-only lineage and internal audit/history
  facts.
- Missing records or contracts: product-domain activity event selection,
  public/private presentation, deduping, grouping, labels, and card-specific
  explanations.
- Product decisions still needed: which events appear to owners, public
  viewers, and collaborators; whether product-domain records emit activity.
- Recommended ownership: Satera source facts; Card Vertex timeline
  composition.
- Recommended phase: after major product-domain records are decided.
- Do not build yet: duplicated mutable history ledger.

### 18. Dashboard / Morning Briefing

- Product behavior required: card-specific morning briefing from signals,
  goals, active workspaces, needs-attention items, recent activity, community
  summary, grading status, trade opportunities, and comps.
- Existing Satera support: product-lens summary counts, notifications,
  evaluation cases, inventory, public references, communities, comps.
- What can be represented now: basic source facts and counts.
- Missing records or contracts: Card Vertex dashboard contract, needs-attention
  rules, signal/goal dependencies, community summary rules, action grouping.
- Product decisions still needed: first dashboard modules, refresh cadence,
  suppress/dismiss behavior, and whether briefings are persisted.
- Recommended ownership: Card Vertex product intelligence and experience.
- Recommended phase: after signals/goals/workspace contracts.
- Do not build yet: dashboard UI or recommendation engine.

## Part 3 - Card Identity and Catalog Assessment

### Current Support

- Asset families: generic `asset_families` rows with category, optional
  collection, name, canonical key, and JSON attributes.
- Asset variants: generic `asset_variants` rows with family, category, name,
  variant key, and JSON attributes.
- Categories: generic hierarchy and product-category mapping.
- Product categories: product-to-category membership for product lenses.
- Collections: category-scoped grouping with slug, name, and metadata.
- Inventory items: owner/workspace/org-scoped physical holdings pointing to
  category and asset variant, with condition/status/availability/intent,
  location, true basis, current value snapshot, acquired date, and notes.

### Likely Card Vertex Needs

Card Vertex likely needs durable ways to represent sport, league, player, team,
manufacturer, release year, set, subset, card number, parallel, serial
numbering, autograph and memorabilia attributes, rookie designation, raw versus
graded state, grading company, grade, certification number, aliases and naming
normalization, and image/reference strategy.

### Decisions Before Schema Design

1. Catalog source strategy: user-created, curated internal, licensed provider,
   partner feed, or hybrid.
2. Identity granularity: what is a family versus variant for cards, and where
   raw/graded/certified state belongs.
3. Set model: whether manufacturer, release year, set, subset, insert, and
   parallel are separate controlled concepts or attributes at first.
4. Player/team model: whether to normalize players and teams immediately or
   begin with searchable display strings.
5. Certification model: whether grading company, grade, and cert number remain
   inventory/evaluation facts, public reference facts, or part of card variant
   identity.
6. Alias policy: how to normalize card names, player names, teams, sets, and
   common shorthand.
7. Image policy: licensed catalog images, user images, public reference images,
   slab/front/back roles, and fallback images.
8. Incomplete identity policy: how drafts and purchases preserve uncertain or
   partial card identities before a canonical variant exists.
9. Provider and licensing policy: which catalog/market sources can be used and
   how evidence is attributed.
10. Migration threshold: which decisions must be stable before adding tables
   rather than storing temporary Card Vertex-specific draft metadata.

No final tables are proposed here.

## Part 4 - Draft Lot Workspace Gap

### Current Lot Purchase RPC Coverage

`create_lot_purchase_transaction` is the final Commit Lot mechanism. It:

- requires a workspace;
- optionally validates an active product and that each variant category belongs
  to the product;
- accepts purchase price, buyer fees, tax, shipping, other acquisition costs,
  seller reference, marketplace, order reference, date, notes, and item array;
- requires each item to have an existing `asset_variant_id`;
- supports one physical copy per item;
- supports `manual` and `equal` allocation only;
- validates manual allocations sum to total basis within rounding tolerance;
- creates one `purchase_lot` transaction;
- creates inventory items with allocated `true_basis`;
- writes transaction lines, ownership events, lot allocation basis events,
  lineage edges, metadata, and an audit event;
- does not infer current value;
- does not create public references, variants, drafts, or comp evidence.

### What It Does Not Cover

It does not cover draft lifecycle, candidate cards, incomplete identities,
source/dealer/show context beyond final transaction fields, rich notes,
key-card highlights, editable allocation before commit, review states,
delete/archive semantics, starting inventory staging, commit previews, or
post-commit draft preservation.

### Future Draft Lot Workspace Needs

- Draft lifecycle: create, edit, pause, review, commit, archive, delete.
- Candidate cards: one row per possible physical card or group before final
  split decisions.
- Incomplete identities: free-text and partial identity fields before an
  `asset_variant_id` exists.
- Source context: dealer, show, collection buy, seller notes, receipt/order
  references, acquisition channel.
- Notes: lot-level and candidate-level notes, private by default.
- Key-card highlights: mark anchors and cards driving allocation decisions.
- Editable allocation: manual, equal, later estimated-value or comp-based
  assistance.
- Review states: needs identity, needs allocation, ready to commit, committed.
- Delete/archive semantics: drafts can disappear; committed history cannot.
- Starting inventory use case: stage pre-owned cards without a current purchase
  event while preserving user explanations.
- Commit contract: convert only ready draft candidates into the existing
  Satera final commit RPC payload.
- Post-commit preservation: preserve draft notes and allocation rationale
  without making draft data canonical transaction truth.

### Ownership Split

Card Vertex-specific records may own draft lot, draft candidate card, draft
identity, key-card highlight, allocation workspace, review state, and
post-commit draft snapshot. Satera Core must remain the final lot transaction,
inventory creation, basis allocation, ownership event, basis event, lineage,
and audit truth.

No migration design is proposed here.

The detailed Draft Lot lifecycle, allocation behavior, provisional identity
policy, commit contract, correction model, starting-inventory distinction,
decision matrix, and founder decisions are now defined in
[`DRAFT_LOT_WORKSPACE_ARCHITECTURE.md`](DRAFT_LOT_WORKSPACE_ARCHITECTURE.md).
This assessment remains a gap inventory and does not approve schema.

## Part 5 - Grading Workspace Mapping

| Workflow element | Current support | Gap / ownership |
| --- | --- | --- |
| Submission-level fields | `evaluation_cases` has case type, provider name/reference, status, opened/submitted/received/completed/returned/expected timestamps, declared value, cost buckets, notes, metadata | Card Vertex needs grading-specific names, submission number semantics, and possibly controlled grading company/service levels |
| Grading company | `provider_name` text | Product decision needed on controlled list versus text and aliases |
| Service level | Not explicit; can be metadata only today | Card Vertex-only contract first; possible later Core lifecycle enhancement if multiple products need service levels |
| Estimated return | `expected_return_at` | Supported |
| Prediction fields | Not explicit | Card Vertex-only behavior; decide predicted grade, confidence, and use in outcome analysis |
| Submission costs | Case and item cost buckets plus generated totals | Supported for generic costs; allocation policy still product/workflow-specific |
| Card membership | `evaluation_case_items.inventory_item_id` | Supported for existing inventory items |
| States | Core case/item status checks support draft, prepared, submitted, in review, received, completed, returned, canceled, lost, on hold and item variants | Mostly supported; Card Vertex may need display mapping and returned-review sub-states |
| Grade entry | `result_grade`, `result_summary`, `result_authenticity`, `result_metadata` | Supported descriptively; no grade normalization |
| Certification numbers | `result_certification_number`, `provider_item_reference` | Supported descriptively |
| Returned-review workflow | `returned` status and events | Card Vertex behavior missing for review checklist, accept result, crack/resubmit decisions |
| Outcome analysis | Not explicit | Card Vertex-only intelligence using prediction, costs, value evidence, goals |
| Basis allocation decisions | `allocated_*_costs`, `basis_increase_amount`, `apply_evaluation_basis_increase` | Supported mechanically; product must decide when costs should increase basis |
| Inventory availability changes | Inventory has `at_grading`, `pending_return`, etc.; safe update RPC exists | No automatic link from evaluation status changes to inventory availability/status |

Already supported: cases, items, events, costs, result grade/cert number,
attachments metadata, expected return, explicit basis increase, workspace
privacy, product lens reads.

Partially supported: grading company, service level, returned states, item
availability, grade normalization.

Missing: predictions, submission package generation, provider integrations,
slab/cert image upload workflow, outcome analysis, automatic status/availability
transitions, Card Vertex grading UI.

Card Vertex-only behavior: grading-company presentation, predicted grade,
collector workflow, submission review, outcome explanation, goal connection.

Possible Core lifecycle enhancements later: normalized provider/service-level
records, provider item lifecycle events, inventory availability synchronization,
attachment upload contracts. These should wait for reuse or a precise Card
Vertex contract.

## Part 6 - Trade Network, Profiles, Trust, and Goals

Existing Core can preserve completed trade truth and expose safe public
references through community infrastructure. It does not implement discovery.

Likely future Card Vertex needs:

- Looking For: Card Vertex-specific collector intent tied to players, sets,
  cards, themes, grades, and trade-up goals.
- Availability-for-trade presentation: likely starts from inventory intent and
  public references, but needs visibility and public display rules.
- Lightweight interest: Card Vertex opportunity signal, not a completed trade.
- Saved opportunities: Card Vertex records for discovery workflow.
- Trade conversations: decide between product-specific conversation records,
  community channels/messages, or a future Core direct-message primitive.
- Public collector profile: structured Card Vertex profile fields with
  explicit public/private separation.
- Collector focus areas: Card Vertex profile semantics.
- Completed trade counts: derived from Core trade truth, but visibility must
  avoid exposing private terms.
- Repeat partners: requires partner identity model and visibility rules.
- Positive endorsements / Would Trade Again: Card Vertex first; possible Core
  promotion only after another product proves reusable endorsement semantics.
- Public/private visibility: must be decided before schema.
- Card-specific goals: Card Vertex records first.
- Goal progress: depends on card identity, inventory matching, and privacy.
- Trade-up goals: require value/comps policy and matching rules.
- Goal/card matching: depends on normalized card identity and relevance rules.

Do not turn these into generic Satera systems now. Satera should continue to
own identity, access, privacy, community/moderation, public references,
completed trade truth, and audit. Card Vertex should prove Looking For,
availability, opportunities, endorsements, goals, and trade matching in its own
domain first.

## Part 7 - Signals, Search, Dashboard, and Comps

### Signals

Source facts already available: inventory status/intent/availability,
transactions, ownership events, basis events, evaluation cases/events,
notifications, public references, communities/messages, comp snapshots, and
audit events.

Missing event inputs: Card Vertex goals, Looking For records, saved
opportunities, public profile focus areas, draft lot states, grading
prediction/outcome facts, comp write/review events.

Card-specific relevance rules: player/team/set/parallel/grade matching,
goal-relevance, trade-up relevance, grading ROI relevance, comp confidence,
relationship context, and user suppression preferences.

Required explainability: every signal must state the source facts, why it
matters, and what action is available.

Priority/suppression questions: signal severity, recency, user dismiss/snooze,
duplicate grouping, whether signals expire, and whether signals become
notifications.

Dashboard relationship: the morning briefing should consume signals, not
define them. Notifications announce events; signals explain decisions.

### Search

Current searchable entities are only available through table-specific reads:
inventory, products/categories, public references, communities/messages,
notifications, evaluation cases, comps, and internal histories. There is no
unified search index.

Needed permission boundaries: owner/workspace/org inventory privacy, public
reference exposure, community membership/channel visibility, product access,
moderation visibility, and private financial field suppression.

Card-specific search semantics: player, team, sport, year, set, subset, card
number, parallel, serial, grade, grading company, cert number, goals, trade
intent, sale intent, and actions.

Future command/action needs: add comp, mark for trade, create grading draft,
open context, start logged trade, create public reference. These should remain
non-implemented until search contracts and permission tests exist.

### Dashboard / Morning Briefing

Available source facts: product lens summary counts, inventory facts,
notifications, evaluation cases, public references, communities, comps,
transactions, lineage, and audit.

Needs-attention sources: pending grading cases, items at grading, stale comps,
sale/trade intent without public references, incomplete draft lots later,
unread notifications, moderation/community mentions where visible.

Active-workspace sources: inventory rows, evaluation cases, future draft lots,
future trade opportunities, future saved filters.

Recent activity sources: ownership, transaction, basis, evaluation,
notification, community, public reference, comp, and future product-domain
events.

Goal/signal dependencies: dashboard depends on Card Vertex goal and signal
contracts.

Community summary dependencies: community templates, unread/mention rules, and
safe object reference rendering.

### Market / Comps

Current evidence foundation: owner-scoped `comp_snapshots` with source URL,
domain, source type, capture mode, verification status, match quality,
include/exclude controls, sale date/title, grade/company, confidence label,
review fields, inventory/category/family/variant links, and read helpers.

Private/manual comp behavior: manual comp capture is the safest first contract;
direct writes are currently revoked pending reviewed service/RPC design.

Public/shared comp considerations: decide whether comps are private evidence,
public reference support, admin-verified shared evidence, or catalog-level
facts. Public sharing cannot leak private owner context or unsupported source
data.

Card identity matching dependencies: reliable comp use depends on normalized
card identity, grade/raw distinction, parallel, serial, autograph/memorabilia,
and source confidence.

Confidence/rationale needs: comp count, recency, included/excluded rationale,
verification status, source quality, match quality, and grade/parallel fit.

Write-path gaps: no comp create/update/review RPC, no admin queue service, no
extension write path, no provider ingestion.

Sources and policy questions: allowed sources, user confirmation rules,
reference-only sources, screenshot storage, terms compliance, partner feed
rights, and admin verification criteria.

## Part 8 - Recommended Implementation Sequence

1. Documentation / decision work:
   review and approve the Card Vertex Grading Workspace and Certification
   Lifecycle; define the Trade Network and logged trade contract; define the
   collector profile and trust contract; define Goals and Signals; define
   Search, Dashboard, and comp write-path contracts.
2. Future schema design:
   only after decisions, propose Card Vertex-specific records for card identity
   gaps, draft lots, collector profiles/Looking For, goals, trade opportunities,
   comp write/review, and workspace preferences. Keep Core concepts generic
   only where proven.
3. Future service/RPC work:
   add reviewed Card Vertex domain services and RPC-backed mutations for
   product records; continue invoking existing Satera RPCs for final purchase,
   lot, trade, sale, evaluation, public reference, community, notification, and
   audit truth.
4. Future product-domain implementation:
   implement Card Vertex contracts above Core, including identity resolution,
   draft-to-commit adapters, grading workflow mapping, comp review/write
   workflow, goals, signals, and Trade Network discovery.
5. Future Card Vertex UI work:
   build the real app root and inventory workspace only after workspace/build
   planning and product-domain contracts are approved.

Foundational priority order: approve grading lifecycle, Trade Network/logged
trade, collector profile/trust, goals/signals, search/dashboard/comp write
path, MVP product experience, then schema design.

## Part 9 - Explicit Non-Goals / Do Not Build Yet

- Real Card Vertex app.
- Card Vertex UI.
- Real app routes.
- Vercel/domain configuration.
- Automated card catalog ingestion.
- Marketplace payments.
- Formal peer trade proposals.
- Recommendation engines.
- Generic Satera Goals.
- Generic Satera Signals.
- Generic cross-product search.
- Provider integrations.
- Realtime/community media.
- Browser extension write path.
- Automated valuation.
- Portfolio UI.
- Vertex Pro UI.
- New schema, migrations, tables, RLS, seed data, SQL tests, RPCs, service
  code, package configuration, build tooling, or Supabase changes in this
  assessment pass.

## Part 10 - Verification Plan

Because this is documentation-only, no Supabase reset is required. The required
verification commands are:

```text
npm run test
npm run typecheck
npm run build
```

Results should be recorded in the completion summary. Do not claim success
unless each command actually passes.
