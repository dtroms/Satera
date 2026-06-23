# Card Vertex Draft Lot Workspace Architecture

This document defines the approved Draft Lot Workspace architecture and
lifecycle for Card Vertex before implementation begins. It is planning
documentation only. It does not authorize schema, RPC, route, UI, migration,
seed, service, package, build, Vercel, Supabase, or runnable Card Vertex app
work.

The governing boundary remains:

```text
Satera preserves what happened.
Card Vertex prepares what a collector is still deciding.
```

Satera owns canonical financial truth, inventory truth, ownership truth, basis,
lineage, audit, privacy, and final transaction commitment. Card Vertex owns the
collector workflow for preparing a lot, incomplete intake, review, allocation
assistance, context, and the user experience that decides when a lot is ready
to commit.

## Draft Lot Principle

A Draft Lot is not inventory.

A Draft Lot is not a transaction.

A Draft Lot is not a final accounting record.

A Draft Lot is a long-lived, reversible Card Vertex preparation workspace for a
prospective multi-item acquisition.

A Draft Lot becomes canonical only at explicit commit.

Until commit:

- no inventory items exist
- no ownership event exists
- no basis event exists
- no transaction exists
- no public card reference exists
- no comp history is attached as owned inventory truth
- no permanent global catalog truth is created merely from user-entered draft
  text

At commit:

```text
Draft Lot
-> validated final card identities
-> allocation review
-> existing Satera Core lot-purchase RPC
-> canonical inventory items
-> purchase-lot transaction
-> ownership events
-> basis events
-> basis lineage
-> audit event
-> committed read-only lot history
```

The existing Satera Core lot-purchase RPC is the final commit mechanism. Draft
Lots must not redesign, replace, weaken, duplicate, or bypass that Core
capability.

## Intended Collector Workflows

### Card Show / Convention Purchase

A collector buys a group of cards at a show. They may know only some
identities, may not have images, may negotiate one total price, and may need to
enter the lot quickly. Draft Lots let the collector preserve the deal and come
back later without creating premature inventory rows.

### Bulk Purchase / Collection Buy

A collector acquires a collection, box break result, dealer lot, estate group,
or multiple-card purchase over time. Draft Lots support partial split decisions
and later review before a final Core lot transaction exists.

### Online Multi-Item Acquisition

A collector buys multiple cards from one seller, potentially with shared
shipping, tax, buyer fees, or discounts. Draft Lots collect the shared
economics and prepare the eventual item-level allocation.

### Starting Inventory Import

A collector brings existing cards into Card Vertex and wants to record a
meaningful starting basis or basis-known lot without falsely representing a
modern purchase event. This is related to Draft Lots, but it is not identical
to a purchase lot.

### Deferred Review

A collector creates a lot at a show, enters partial information, then completes
identity, costs, allocation, images, notes, and exact serials later.

### Catalog Candidate / Provisional Identity Intake

A card cannot be confidently matched to a canonical Card Vertex catalog
identity at intake time. Draft Lots preserve original text, images, evidence,
and uncertainty without silently creating global catalog truth.

Draft Lots support these workflows without forcing a collector to create
private inventory rows prematurely.

## Lifecycle

The recommended lifecycle is:

```text
Draft
-> In Intake
-> Needs Identity Review
-> Needs Allocation Review
-> Ready to Commit
-> Commit In Progress
-> Committed
```

`Abandoned` and `Archived` are terminal or inactive non-commit states.

### Draft

- Workspace created.
- No required cards yet.
- Editable.
- Deletable while never committed.
- No Core truth exists.

### In Intake

- Cards, source, costs, and notes are being added.
- Incomplete identity is allowed.
- Editable.
- May be paused indefinitely.
- Not inventory and not a transaction.

### Needs Identity Review

- One or more entries are unresolved, provisional, duplicate-suspected, or
  insufficiently identified for safe commit.
- Draft remains editable.
- Not eligible for final Core commit.
- User evidence and original entered text must remain preserved while identity
  is refined.

### Needs Allocation Review

- Cards are sufficiently identified, but basis allocation does not reconcile or
  requires explicit founder/user decision.
- Draft remains editable.
- Not eligible for commit until allocation validates.

### Ready to Commit

- Required acquisition information is present.
- Every committed inventory item has an acceptable identity state.
- Allocation reconciles exactly.
- No validation blockers remain.
- Still editable until commit begins.

### Commit In Progress

- UI/service execution state only.
- Protects against accidental duplicate submission.
- Must be idempotent at eventual implementation.
- No edits allowed while committing.
- Experience locking is not the sole financial safety guarantee.

### Committed

- Core transaction succeeded.
- Draft snapshot is preserved.
- Draft becomes read-only.
- Links to created transaction and inventory items.
- Future corrections happen through explicit correcting workflows, not direct
  edits to committed source data.

### Abandoned

- User intentionally abandons a draft.
- Preserved or deleted according to explicit policy.
- Never creates Core truth.

### Archived

- Inactive draft retained for reference.
- No Core truth.
- May remain visible in active-workspace and dashboard summaries only when the
  product later decides that archived drafts are useful to the collector.

### Deletion Recommendation

Drafts with no historical significance may be hard-deleted only while they
have never been committed. Abandoned or archived drafts may be retained for
user continuity. Any committed lot must never be deletable as though it never
happened.

## Information Architecture

### Lot Header

- Working title.
- Acquisition source.
- Seller/dealer.
- Acquisition date.
- Location or event.
- Status.
- Created and updated timestamps.
- Owner/workspace.
- Optional linked event/show later.

### Financial Summary

- Item purchase amount.
- Buyer fees.
- Tax.
- Shared shipping.
- Other acquisition costs.
- Discount or credit if supported.
- Total basis pool.
- Allocation method.
- Allocated total.
- Unallocated or overallocated remainder.

### Candidate Cards

- Draft line items.
- Quantity.
- Catalog identity state.
- Provisional identity or unresolved free-text evidence.
- Condition.
- Expected grade if relevant.
- Exact serial if known.
- Item images/evidence.
- Notes.
- Intended allocation.
- Allocation rationale where needed.
- Whether the item should become inventory at commit.

### Key Cards / Highlights

- Optional organizational tags only.
- Must not affect financial truth automatically.
- May help the user focus allocation and review.
- Do not become a separate accounting concept.

### Evidence And Notes

- Source screenshots.
- Seller notes.
- Receipt photos.
- Private notes.
- Show/dealer context.
- Pricing rationale.
- Provenance context.
- All private by default.

### Review And Commit

- Validation checklist.
- Final acquisition information.
- Final card identity status.
- Basis allocation reconciliation.
- Final generated commit preview.
- Explicit irreversible-action disclosure.
- Commit action.

## Cost And Basis Allocation Model

Draft Lots must distinguish acquisition economics from card allocation.

Acquisition economics include:

- Item purchase amount.
- Buyer fees.
- Tax.
- Shipping.
- Other acquisition costs.
- Discounts, credits, or adjustments if supported.

Card allocation is the amount of total lot basis assigned to each card intended
to become inventory.

The Core-aligned financial rule is:

```text
total basis pool =
  purchase amount
  + buyer fees
  + tax
  + shipping
  + other acquisition costs
  - explicit credits/discounts when supported
```

The current Core lot-purchase RPC supports purchase price, buyer fees, tax,
shipping, and other acquisition costs. Credits and discounts are conceptual
future requirements and must not be invented in the Draft Lot adapter until
Core support and policy are approved.

Allocation must reconcile exactly to the total basis pool before commit.

### Manual Allocation

- User enters basis allocation per card.
- Must reconcile exactly.
- Supports collector judgment, deal structure, intentional value weighting, and
  known component prices.

### Equal Allocation

- Total basis distributed equally across cards designated for inventory.
- Only appropriate when all eligible items are intentionally treated equally.
- Rounding behavior must be deterministic and transparent later.
- Current Core assigns any rounding remainder to the final item.

### Suggested Allocation

Suggested Allocation is future assistance only.

- May use declared values, comp context, or market signals.
- Never silently commits values.
- User must approve.
- Must not imply that comp value equals basis.

Automated valuation allocation is not MVP truth.

### Special Treatments

Cards included free in a purchase still need deliberate basis handling. They
may receive a zero allocation only when the user intentionally records known
zero basis.

Empty wrappers, sealed product, supplies, or non-card items require a product
decision before they become inventory. If they are excluded from inventory,
their cost treatment must still reconcile with the total basis pool.

Seller discounts, shared shipping, refunded amounts, partial returns, gifts,
promotional items, and known zero-basis items all require explicit policy
before implementation. Draft Lots must record the user's intent without
silently turning unknown values into zero.

Cards intentionally not being added to inventory must be marked as excluded or
otherwise treated intentionally during review. Excluded cards cannot receive
hidden canonical inventory truth.

Every eligible inventory item must receive a deliberate basis result at commit:
positive, zero, or unknown/null where policy permits. The exact null-versus-zero
policy must align with current Core constraints and be explicitly finalized
during schema/RPC implementation planning. Draft Lots must never quietly
convert unknown basis into zero.

## Identity Handling Inside Draft Lots

Draft Lots use the Card Vertex Card Identity and Catalog Strategy. Candidate
cards may have these identity states:

- Canonical Card Vertex identity.
- Controlled provisional Card Vertex identity.
- Unresolved intake record.
- Needs Review.
- Superseded / merged identity reference later.

Canonical identity may commit to inventory when all other validation passes.

Controlled provisional identity may commit only under an explicit approved MVP
policy.

Unresolved free-text identity cannot silently create global catalog truth.

A user can preserve photos, receipt evidence, and original entered text even
after later canonical identity resolution.

Identity changes before commit remain editable and must preserve user
evidence.

Identity changes after commit need an explicit correction/remapping flow later;
do not rewrite history invisibly.

### Recommended MVP Policy

For the earliest Card Vertex MVP, a Draft Lot can preserve unresolved entries,
but final commit should require either:

- a canonical Card Vertex identity; or
- a controlled provisional identity that has a stable internal ID, clear
  uncertainty status, and restricted public/comp/trade behavior.

Unresolved intake entries should block final lot commit until intentionally
resolved or explicitly excluded from inventory commitment.

## Commit Contract With Satera Core

Card Vertex Draft Lot prepares:

- Source information.
- Acquisition date.
- Purchase/cost inputs.
- Candidate-card entries.
- Final chosen card identities.
- Quantity and condition.
- Allocation selection.
- Item-level allocations.
- Private notes/evidence references where supported.
- Review/validation state.
- Idempotency intent later.

Satera Core final commit owns:

- Transaction creation.
- Transaction lines.
- Inventory item creation.
- Ownership events.
- Basis events.
- Basis lineage.
- Audit record.
- Atomicity.
- Authorization.
- Canonical financial truth.
- Prevention of partial final state.

Before calling the existing Core lot-purchase RPC, eventual Card Vertex
implementation must validate:

- User/workspace authority.
- No duplicate commit already succeeded.
- Valid acquisition amount and cost fields.
- Valid total basis pool.
- All committed entries have stable acceptable identity.
- Allocation reconciles exactly.
- Every included inventory item has required creation fields.
- Excluded/non-inventory entries are treated intentionally.
- No unsupported negative values or invalid costs.
- No unresolved blockers.
- Final user confirmation.

### Idempotency Requirements

- Commit request must have a stable idempotency key or equivalent draft-commit
  guard.
- Retry must return the prior successful result rather than duplicate
  inventory or transactions.
- Commit-in-progress locking is experience protection, not the sole financial
  safety guarantee.
- Core remains the final authority for atomic correctness.

## After Commit And Corrections

After a successful commit:

- Draft Lot becomes a committed lot record / immutable snapshot.
- User can view original source, cards, allocations, evidence, and resulting
  inventory items.
- User can navigate to transaction, inventory rows, lineage, and related
  activity.
- Committed lot cannot be edited as a draft.
- Later mistakes require corrections, not silent edits.

Future correction categories include:

- Wrong card identity mapping.
- Wrong quantity.
- Allocation correction.
- Omitted acquisition cost.
- Duplicate entry.
- Item that should not have become inventory.
- Item that should have been included.
- Later return/refund.
- Sale/trade of individual items after commit.
- Split/merge or catalog correction later.

Corrections must preserve historical truth and auditability. They should
create explicit corrective events or amendments rather than mutating original
transaction history invisibly.

Do not design final correction SQL or RPCs yet.

## Starting Inventory Distinction

Starting Inventory Import is related but not identical to a purchase lot.

- Starting inventory often represents pre-existing ownership.
- It may use a preparation workspace that resembles Draft Lots.
- It must not falsely imply a new purchase on the import date.
- It may need an acquisition-date-unknown option, a known/unknown basis policy,
  and distinct ownership-event semantics.
- It may reuse visual and review primitives without reusing an incorrect
  financial transaction type.

Recommendation: Starting Inventory Workspace should be a separate workflow
sharing Draft Lot primitives, not a normal Draft Lot subtype that commits
through purchase-lot semantics. It may reuse candidate cards, identity review,
evidence, notes, allocation review, and commit preview primitives, but the
final Core commit path and ownership-event meaning must remain distinct from a
modern purchase lot.

## Current Core Mapping And Future Data Requirements

### Core Already Provides

- `transactions`: final purchase-lot transaction truth.
- `transaction_lines`: frozen cash, cost, and inventory allocation lines.
- `inventory_items`: canonical owned physical items after commit.
- `asset_families` and `asset_variants`: current generic pointers for
  inventory and lot-purchase RPC inputs.
- `ownership_events`: ownership event history.
- `basis_events`: basis event history.
- `basis_lineage_edges`: basis allocation lineage.
- `audit_events`: audit trail for final Core workflow.
- `asset_images`: current generic image attachment infrastructure.
- `public_object_references`: safe public exposure records after inventory
  exists and owner intentionally exposes it.
- Product context and product-lens reads.
- Existing `create_lot_purchase_transaction` RPC for final atomic commit.

### Likely Later Card Vertex Product Records / Workspaces

Later schema design will likely need Card Vertex-specific ways to represent:

- Draft Lot workspaces.
- Draft Lot lifecycle status.
- Candidate card entries.
- Draft identity evidence.
- Controlled provisional identity references.
- Identity review blockers.
- Allocation workspace state.
- Evidence and notes.
- Seller/dealer/show/event context.
- Commit preview and validation state.
- Idempotent commit guard.
- Committed snapshot links to resulting Core transaction and inventory items.
- Abandoned/archive/delete metadata.
- Starting Inventory Workspace primitives.
- Product-domain activity history derived from draft and commit events.

### Product-Specific Boundaries

Draft Lot workspace behavior, candidate-card intake, key cards, allocation
assistance, seller/show context, provisional identity review, and collector
review states should remain Card Vertex product-domain behavior.

Do not generalize Draft Lots into a generic Satera draft-workspace system yet.
No other product has proven matching semantics.

### Conceptual Fields Only

All fields in this document are conceptual. This document does not approve SQL,
table definitions, column names, column types, migration names, RLS policies,
RPC signatures, service code, routes, UI, or package configuration.

Before any schema proposal, decide:

- Draft ownership scope and sharing rules.
- Exact lifecycle statuses and terminal-state policy.
- Whether controlled provisional identities can commit in MVP.
- Null-versus-zero basis policy for lot and starting inventory workflows.
- Credit/discount/refund/partial-return treatment.
- Evidence storage and retention policy.
- Idempotency and duplicate-commit guard design.
- Committed snapshot retention and correction model.
- Starting Inventory Workspace relationship to Draft Lot primitives.
- Public reference and comp restrictions for provisional or recently corrected
  identities.

## Decision Matrix

| Concern | Recommended decision | Ownership | Current support | MVP requirement | Open risk | Requires schema decision later? |
| --- | --- | --- | --- | --- | --- | --- |
| Draft Lot existence | Long-lived reversible Card Vertex workspace, not Core transaction | Card Vertex | Gap documented; no implementation | Yes before lot UI | Premature inventory creation | Yes |
| Draft status/lifecycle | Use Draft, In Intake, Needs Identity Review, Needs Allocation Review, Ready to Commit, Commit In Progress, Committed, Abandoned, Archived | Card Vertex | None | Yes | State drift and unclear terminal rules | Yes |
| Candidate card entry | One candidate per possible committed physical card or intentionally excluded item | Card Vertex | Final Core item payload only | Yes | Quantity/split ambiguity | Yes |
| Provisional identity | Controlled provisional identity may commit only under explicit MVP policy | Card Vertex catalog/domain | Identity strategy only | Conditional | Public/catalog confusion | Yes |
| Unresolved identity | Preserve in draft but block commit unless excluded | Card Vertex | Identity strategy only | Yes | Free text becoming catalog truth | Yes |
| Financial input | Capture purchase amount and approved cost buckets, plus future credits only when Core supports them | Card Vertex prepares; Satera commits | Core lot RPC supports canonical cost buckets | Yes | Discounts/refunds not currently modeled | Yes |
| Basis allocation | Must reconcile exactly to total basis pool before commit | Card Vertex validates; Satera commits | Core manual/equal allocation exists | Yes | Rounding and null/zero policy | Yes |
| Allocation method | Manual/equal for MVP; suggestions later as assistance only | Card Vertex UX; Satera Core final methods | Core supports manual/equal | Yes | Suggested values mistaken for truth | Yes |
| Lot evidence | Private evidence and source context attached to draft/snapshot later | Card Vertex | Generic image/evidence infrastructure only | Yes for useful workflow | Storage/retention/licensing | Yes |
| Private notes | Private by default and not public reference data | Card Vertex; Satera privacy guarantees | Inventory notes and transaction notes exist after commit | Yes | Note leakage into public refs | Yes |
| Seller/event context | Capture dealer/show/seller context before commit | Card Vertex | Core has seller/marketplace/order fields only | Yes | Overloading transaction fields | Yes |
| Commit guard / idempotency | Stable key or equivalent guard required; UI lock not enough | Card Vertex service plus Core correctness | Not implemented for draft commits | Yes | Duplicate transactions on retry | Yes |
| Commit preview | Generated validation and final Core payload preview before irreversible action | Card Vertex | None | Yes | Preview diverges from actual RPC inputs | Yes |
| Committed snapshot | Preserve read-only draft snapshot linked to Core outputs | Card Vertex | Core transaction/audit exists | Yes | Snapshot vs canonical truth confusion | Yes |
| Correction handling | Explicit corrective workflows later; no silent edits | Satera for canonical corrections; Card Vertex for UX | Correction event concepts exist, detailed flows not designed | Not for Draft Lot MVP unless errors found | Historical mutation | Yes |
| Abandoned/archive/delete policy | Hard-delete only never-committed drafts with no historical need; retain committed lots forever | Card Vertex | None | Yes | User expects undo after commit | Yes |
| Starting inventory reuse | Separate workflow sharing primitives, not normal purchase lot | Card Vertex prepares; Satera final starting inventory semantics | Core starting inventory RPC exists | Yes if import MVP included | False purchase history | Yes |
| Public references | None before commit; intentional exposure only after inventory exists | Satera Core bridge; Card Vertex rendering | Public object references implemented | Yes | Draft/private data leakage | Yes |
| Comp usage | Draft evidence/context only; no comp history as owned inventory truth before commit | Card Vertex comps; Satera basis separation | Comp evidence exists, writes not exposed | No automated MVP allocation | Comps mistaken for basis | Yes |
| Activity history | Compose from draft events later and Core events after commit | Card Vertex presentation; Satera source facts | Core histories exist | Later | Duplicated mutable history | Yes |

## Founder Decisions To Approve

1. Draft Lots are reversible Card Vertex product workspaces, not Core
   transactions.
2. Commit is the sole boundary where Core truth is created.
3. Draft Lots support long-lived incomplete intake.
4. Allocation must reconcile exactly before commit.
5. Unknown basis must not silently become zero.
6. Unresolved identity blocks commit unless a controlled provisional policy
   allows it.
7. Committed lots are immutable snapshots; corrections are explicit later.
8. Starting inventory is not a normal purchase lot, but may share Draft Lot
   primitives.
9. Evidence and notes are private by default.
10. Automated comp-driven allocation is not MVP truth.

## Do Not Build Yet

- Migrations.
- Schema implementation.
- Draft Lot UI.
- Live auto-save.
- Show-floor mobile UI.
- Scanning/OCR.
- Provider catalog integrations.
- Browser-extension capture.
- Automatic catalog matching.
- Automatic comp-driven allocation.
- Automatic tax/shipping splitting.
- Transaction correction implementation.
- Partial-return implementation.
- Full starting-inventory implementation.
- Marketplace payments.
- Trade proposal workflows.
- Community sharing from drafts.
- Public draft lots.
- Generic Satera draft-workspace system.

## Verification Plan

Because this is documentation-only, no Supabase reset is required. Required
verification commands:

```text
npm run test
npm run typecheck
npm run build
```

Do not claim success unless each command actually passes.
