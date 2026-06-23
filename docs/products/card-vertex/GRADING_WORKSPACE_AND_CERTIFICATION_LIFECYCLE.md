# Card Vertex Grading Workspace And Certification Lifecycle

This document defines the approved Card Vertex grading workspace and
certification lifecycle contract before implementation begins. It is planning
documentation only. It does not authorize schema, RPC, route, UI, migration,
seed, service, package, build, Vercel, Supabase, provider integration, or
runnable Card Vertex app work.

The governing boundary remains:

```text
Satera preserves evaluation truth.
Card Vertex prepares and explains grading work for card collectors.
```

Satera Core already owns product-neutral evaluation and certification
infrastructure. Core supports evaluation cases, evaluation items, lifecycle
events, future-safe attachments, audit history, explicit basis increases, and
product-neutral evaluation concepts such as grading, authentication, appraisal,
certification, service, condition review, restoration review, and provenance
review. Card Vertex must translate that backbone into a collector-friendly
grading workflow. It must not redesign, replace, weaken, or duplicate Core
evaluation/certification truth.

## Grading Principle

A grading submission is not a new card identity.

A graded card is not automatically a new catalog identity.

A grading result is evaluation/certification state attached to a specific
owned physical card instance.

The same owned card may have:

- a raw state before submission
- a grading submission history
- a returned grade
- a certification number
- a reholder history later
- a crossover history later
- a resubmission history later

The underlying owned card remains linked to the same Catalog Card Identity
unless a later explicit identity correction is needed.

The approved conceptual model is:

```text
Catalog Card Identity
-> Owned Card Instance
-> Grading Submission / Evaluation Case
-> Evaluation Item
-> Lifecycle Events
-> Grade / Certification Result
-> Card Vertex market interpretation
```

Market interpretation may use the grade and certification result later, but
grading does not automatically set market value or alter basis.

## Workspace Purpose

The Card Vertex Grading Workspace is a long-lived preparation and tracking
surface for cards being considered for grading, submitted to a provider, and
returned to the collector.

It should support:

- selecting cards from inventory
- drafting a submission
- grouping cards into provider and service-level submissions
- recording costs and estimates
- tracking lifecycle status
- recording return results
- capturing certification numbers
- reviewing returned cards
- deciding whether explicit basis capitalization is appropriate
- preserving history

It must not be treated as a generic project board or inventory substitute.
Cards in grading remain owned inventory. They should receive an operational
availability/status treatment indicating they are in grading or unavailable
for ordinary trade, sale, or movement. Submitted cards should not silently
disappear from inventory.

Later Card Vertex surfaces should make grading visible from the inventory row,
Context Drawer, and Activity history. The final grade and certification number
should be discoverable from the card context, subject to privacy and public
reference rules.

## Recommended Lifecycle

Actual Core evaluation lifecycle terminology may differ from the product-facing
Card Vertex labels. Card Vertex may translate product language without
duplicating truth.

Recommended product-facing states:

```text
Draft
-> Ready to Submit
-> Submitted
-> Received by Provider
-> In Process
-> Grades Available
-> Returned
-> Return Review
-> Completed
```

`Cancelled` and `Problem / Exception` are inactive or resolution states.

### Draft

- Cards may be added or removed.
- Provider, service details, expected costs, notes, and predictions are
  editable.
- No Core final evaluation truth is required yet if the product architecture
  chooses a Card Vertex draft layer.
- Cards are not yet operationally unavailable unless the user explicitly marks
  them for grading preparation.

### Ready To Submit

- Required provider/service, cards, and expected cost data are present.
- User confirms handoff intent.
- Still editable until submission is recorded.
- This state is a validation gate, not a final provider event.

### Submitted

- Submission is recorded.
- Cards are operationally unavailable.
- Submission details become historically meaningful.
- Provider tracking or reference details may be added.
- Cards should be blocked from normal trade/sale completion unless the
  submission is cancelled or otherwise resolved.

### Received By Provider

- Provider receipt is confirmed.
- Cards remain unavailable for ordinary movement.
- Provider receipt details may be captured if known.

### In Process

- Provider is grading, authenticating, reviewing, or otherwise processing the
  submitted cards.
- Card Vertex may show provider-specific wording, but Core truth remains the
  evaluation lifecycle.

### Grades Available

- Results are known, but cards may not be physically returned.
- Grade and certification data may be staged for review.
- Inventory availability should remain restricted until physical return and
  return review are complete.

### Returned

- Cards are physically returned to the collector or receiving location.
- Physical return does not complete the workflow by itself.
- The user still needs Return Review before final closure.

### Return Review

- User reviews actual grade, certification number, slab/evidence images later,
  final costs, exceptions, and availability.
- User reviews cost allocation and decides whether eligible actual grading
  costs should be considered for explicit basis capitalization.
- Exceptions must be resolved or intentionally deferred before completion.

### Completed

- Workflow is closed.
- Results are preserved.
- Inventory availability is restored as appropriate.
- Any explicit basis increase decision is separately recorded through the
  existing audited Satera Core basis-increase pathway.

### Cancelled

- No final result exists or the submission did not proceed.
- Reason should be preserved.
- Availability should be restored appropriately unless another workflow now
  controls the card.

### Problem / Exception

Used for lost shipment, damage, provider issue, mismatch, missing card, partial
return, duplicate certification conflict, wrong item mapping, or other issues
requiring explicit resolution later.

## Submission Structure

The grading workspace should not create duplicate card records. It references
owned inventory items.

### Submission Header

- working title
- grading company/provider
- service level
- submission reference or tracking number
- submission date
- expected return date
- actual return date
- status
- owner/workspace
- optional dealer/submission-group context later

### Submission Economics

- estimated provider fee
- estimated shipping
- estimated insurance
- estimated handling
- estimated other costs
- actual provider fee
- actual shipping
- actual insurance
- actual handling
- actual other costs
- total expected cost
- total actual cost
- cost allocation approach
- whether any cost is eligible for explicit basis increase review

### Submission Cards

- owned inventory item
- Catalog Card Identity
- current raw/graded state
- current condition
- optional predicted grade
- card-specific service level override if allowed later
- item-level expected cost allocation
- item-level actual cost allocation
- submission notes
- result grade
- certification number
- result date
- returned status
- exception state
- evidence/images later

### Return Review

- actual grade
- certification number
- actual cost
- evidence
- condition discrepancy
- provider issue
- basis increase decision
- final availability
- completion confirmation

## Costs, Basis, And Market Value

Card Vertex must preserve strict separation between:

1. Submission cost planning.
2. Actual provider cost.
3. Explicit basis increase.
4. Market value interpretation.

Required rules:

- predicted or estimated grading cost is not basis
- actual grading cost is not automatically basis
- final grade is not basis
- a grade result is not automatic market value
- no grading workflow may overwrite current market value automatically
- no grading workflow may overwrite original acquisition basis automatically

Recommended Card Vertex behavior:

- Users can track expected and actual grading costs inside the grading
  workflow.
- After Return Review, a user may explicitly choose whether eligible actual
  grading costs should be capitalized into basis.
- If cost is capitalized, Card Vertex invokes the existing explicit audited
  Satera Core basis-increase pathway later.
- If cost is not capitalized, it remains visible as workflow/expense context
  without mutating basis.
- Cost allocation across submitted cards must be explicit and reviewable
  before any future basis increase action.
- Unknown basis must not silently become zero.
- If current Core rejects basis increase for unknown basis, the UI must surface
  that constraint clearly rather than masking it.

Potential allocation modes:

- manual allocation
- equal allocation
- provider-line-item allocation later
- suggested allocation later only

Comp-driven allocation is not MVP truth.

## Certification And Grade Handling

This contract follows the Card Identity and Catalog Strategy.

Catalog-level information includes:

- issue details
- parallel
- print run
- program-issued autograph/relic
- intended issued-card attributes

Owned-card and evaluation information includes:

- grading provider
- grade
- certification number
- qualifier
- subgrades
- result date
- encapsulation/slab state
- provider notes
- reholder event later
- crossover event later
- altered/authentic status later
- slab images later

Clarifications:

- A grade does not create a new Catalog Card Identity by default.
- Certification number belongs to the specific owned item/evaluation result.
- A card can have multiple historical evaluation events.
- Latest valid result may become the active Card Vertex display state.
- Historical results must not be destroyed.
- A reholder may preserve the same underlying grade/cert lineage.
- Crossover or resubmission may create a new evaluation event, potentially with
  a new certification number.
- Later provider mismatch or duplicate cert conflict requires exception
  handling, not silent overwrite.

## Inventory Availability

A card remains owned inventory while in grading, but should have an operational
availability state such as:

- unavailable / in grading
- restricted from trade
- restricted from sale
- restricted from ordinary movement

The exact enum or data-model implementation is not approved yet.

Grading availability must affect:

- Inventory filtering
- Trade Network availability later
- sale/trade preparation later
- public card references later
- dashboard/workflow signals later
- item Context Drawer later

The user should be able to see that a card exists, where it is in the grading
workflow, and when it is expected back without exposing private costs publicly.

## Entry Points And Boundaries

Intended entry points:

- Inventory row action
- multi-select inventory action
- Context Drawer action
- dedicated Grading Workspace
- post-purchase / post-lot review later
- dealer/organization workflow later

Constraints:

- Only owned inventory cards may enter grading.
- Cards already sold, traded away, archived, or in incompatible workflows
  should be blocked or require explicit exception handling.
- A card should not be placed in two active grading submissions
  simultaneously.
- Cards in active grading should not enter normal trade/sale completion flows
  without explicit cancellation/return handling.
- Card Vertex owns user-facing validation.
- Satera Core owns final data integrity.

## Return Review And Corrections

Return Review is required before workflow completion.

At return, the user should be able to:

- confirm physical return
- record final grade
- record certification number
- record actual provider charges
- attach evidence later
- allocate final cost
- decide whether to request explicit basis capitalization
- resolve exceptions
- restore availability
- complete the submission

Future correction categories:

- wrong grade recorded
- wrong certification number
- wrong card-result mapping
- result received but card not returned
- card missing/damaged
- provider charge correction
- cost allocation correction
- duplicate submission entry
- reholder/crossover/resubmission event
- provider record correction

Corrections must preserve grading history and auditability. Card Vertex must
not silently overwrite a prior certified result or historical submission event.

Final correction SQL/RPCs are intentionally not designed here.

## Current Core Mapping

### Current Core Already Supports

- Evaluation cases for product-neutral grading/certification workflows.
- Evaluation items linked to inventory items.
- Lifecycle events.
- Future-safe attachment references.
- Workspace privacy and product-lens reads.
- Case-level and item-level cost fields.
- Result grade, certification number, authenticity, result summary, and result
  metadata fields.
- Explicit audited evaluation basis increase.
- Inventory items, ownership truth, status, availability, intent, and safe
  inventory update pathways.
- Audit events and product lens boundaries.
- Public object references for safe sharing later.
- Notifications and comp snapshots as separate Core foundations.

### Likely Card Vertex-Specific Data Later

- grading submission draft state before Core evaluation truth is recorded
- grading company/provider aliases and service-level language
- predicted grade and collector notes
- return-review checklist and completion state
- grading-specific exception state and resolution notes
- active-submission guard behavior
- card-specific cost allocation UX
- active display-grade selection rules
- reholder, crossover, and resubmission interpretation
- grading-specific dashboard, filters, and Context Drawer presentation

### Product-Specific Responsibilities

Card Vertex owns grading-specific workflow, grading provider/service language,
submission preparation, submission batch organization, card selection and
queueing, return review experience, grading-specific statuses and filters,
predicted grade, collector notes, grading cost planning, grading-specific
market interpretation, submission UI, and collector context.

### Core Responsibilities

Satera owns evaluation case truth, evaluation item truth, lifecycle events,
certification/evaluation record persistence, audit history, authorization,
inventory ownership truth, explicit basis increase truth,
transaction/basis integrity, and generic attachment references later.

### What Must Not Become Generic Yet

- Card Vertex grading UI.
- PSA/SGC/BGS/CGC-specific language.
- Predicted card grade fields.
- Grading ROI interpretation.
- Collector return-review workflow.
- Card-specific active display-grade rules.
- Submission package preparation.
- Card-market interpretation of graded outcomes.

Do not add these to Core until reusable need is proven outside Card Vertex or
until a precise Core guarantee is required.

### Decisions Before Schema Proposal

- Whether Card Vertex needs a draft layer before creating Core evaluation
  cases.
- Provider/service-level control policy.
- Active grading submission guard.
- Inventory availability sync approach.
- Cost allocation and basis capitalization review policy.
- Return Review required fields.
- Active display-grade rule.
- Correction and exception taxonomy.
- Evidence/image handling policy.
- Public reference behavior for graded cards.
- Trade Network behavior for cards that are unavailable because they are in
  active grading.

No exact SQL, table definitions, column types, migration names, or RPC names
are proposed here.

## Decision Matrix

| Concern | Recommended decision | Ownership | Current support | MVP requirement | Open risk | Requires schema decision later? |
| --- | --- | --- | --- | --- | --- | --- |
| Grading workspace existence | Approve a dedicated Card Vertex workspace over Core evaluation truth | Card Vertex | Core lifecycle exists | Yes | Scope creep into project board | Yes |
| Submission draft state | Allow Card Vertex draft before final submission truth if needed | Card Vertex | Core has draft status but not product draft UX | Yes | Duplicate truth if poorly bounded | Yes |
| Provider/service level | Capture provider and service language for collector workflow | Card Vertex, Core provider text today | Provider name/reference exist | Yes | Controlled list vs free text | Yes |
| Inventory card selection | Reference owned inventory items only | Core inventory, Card Vertex UX | Evaluation items link inventory | Yes | Incomplete identity or wrong copy | Possibly |
| Active submission guard | Prevent one card in two active grading submissions | Core integrity later, Card Vertex validation | Not automatic | Yes | Race conditions | Yes |
| Expected costs | Track planning costs separately from basis | Card Vertex | Core cost fields exist | Yes | Users may confuse estimates with basis | Possibly |
| Actual costs | Record provider charges after return | Satera persistence, Card Vertex UX | Core cost fields exist | Yes | Provider adjustments | Possibly |
| Cost allocation | Make allocation explicit and reviewable | Card Vertex UX, Core cost fields | Item allocated costs exist | Yes | Shared fees and rounding | Yes |
| Basis capitalization decision | User explicitly requests audited basis increase | Satera Core | Explicit basis increase exists | Yes | Unknown basis rejection | No for current Core path; yes for UX policy |
| Certification number | Store as result on the owned item/evaluation event | Satera Core | Result certification field exists | Yes | Duplicate or provider mismatch | Possibly |
| Active grade display | Latest valid result may display as active state | Card Vertex | Historical results can exist | Yes | Reholder/crossover ambiguity | Yes |
| Grade history | Preserve all evaluation history | Satera Core | Events and cases exist | Yes | Destructive correction temptation | Possibly |
| Provider lifecycle status | Translate Card Vertex labels onto Core lifecycle | Card Vertex | Core statuses exist | Yes | Label mismatch | Possibly |
| Inventory availability while grading | Keep item in inventory but operationally unavailable | Core inventory, Card Vertex UX | Status/availability concepts exist | Yes | Exact sync behavior | Yes |
| Return Review | Require review before completion | Card Vertex | Returned/completed statuses exist | Yes | Partial returns | Yes |
| Exception state | Explicit Problem / Exception handling | Card Vertex, Core events later | Lost/on hold/damaged-like states exist | Yes | Too many unstructured exceptions | Yes |
| Evidence/images | Future-safe attachments only; no upload UI now | Satera Core attachments, Card Vertex UX | Attachment records exist | No for MVP contract | Storage and privacy policy | Yes |
| Reholder/crossover history | Model as future evaluation history, not catalog identity | Card Vertex interpretation, Core history | Generic lifecycle exists | Later | Provider lineage complexity | Yes |
| Public reference behavior | Expose only safe grade/cert display if owner chooses | Satera public references, Card Vertex display | Public references exist | Yes for sharing later | Cost/privacy leakage | Yes |
| Market value interpretation | Grade may inform market view but never auto-updates value | Card Vertex market interpretation | Comp/value evidence separate | Yes | Black-box valuation pressure | Possibly |
| Activity history | Compose from Core evaluation, inventory, basis, audit, and product events | Satera source facts, Card Vertex presentation | Core histories exist | Yes | Private financial leakage | Yes |

## Founder Decisions

1. Grading is evaluation state on an owned physical card, not a new catalog
   card.
2. Card Vertex owns grading workflow; Satera owns generic evaluation truth.
3. Cards remain inventory but become operationally unavailable while grading.
4. Grading costs are tracked separately and never automatically change basis.
5. Explicit basis capitalization must be reviewed and audited.
6. Grade and certification history are preserved; no destructive overwrite.
7. Final grade does not automatically update market value.
8. Only owned eligible cards can enter grading submissions.
9. Return Review is required before workflow completion.
10. Automated provider integrations, scans, and comp-driven costing are not
    MVP.

## Follow-On Sequence

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

## Do Not Build Yet

- migrations
- schema implementation
- grading workspace UI
- provider API integrations
- PSA/SGC/BGS/CGC/etc. live integrations
- submission-label generation
- shipping-label generation
- automated provider status sync
- card scanning/OCR
- automated cert verification
- slab image recognition
- automatic market value updates
- automatic basis capitalization
- automatic comp-driven cost allocation
- grading fee payments
- dealer bulk-submission workflow
- correction implementation
- reholder/crossover implementation
- public grading leaderboard or reputation mechanics

## Verification Plan

Because this is documentation-only, no Supabase reset is required. Required
verification commands:

```text
npm run test
npm run typecheck
npm run build
```

Do not claim success unless each command actually passes.
