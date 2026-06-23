# Card Vertex Trade Network And Logged Trade Contract

This document defines the approved Card Vertex Trade Network and Logged Trade
contract before implementation begins. It is planning documentation only. It
does not authorize schema, RPC, route, UI, migration, seed, service, package,
build, Vercel, Supabase, marketplace-integration, or runnable Card Vertex app
work.

The governing boundary remains:

```text
Satera preserves completed trade truth.
Card Vertex creates the collector trade experience before final commit.
```

Satera Core already has the final trade transaction capability that can create
canonical ownership, basis, lineage, and audit truth for a completed exchange.
Card Vertex must not redesign, replace, weaken, or duplicate that final Core
trade transaction behavior. Card Vertex owns the trade-specific discovery,
intent, interest, conversation, and review experience above it.

## Trade Principle

Trade Network is not a marketplace.

Trade Network is not an auction system.

Trade Network is not a public inventory browser.

Trade Network is not a binding proposal engine in MVP.

Trade Network is a relationship-first collector opportunity surface.

Logged Trade is a completed historical ownership exchange.

### Trade Network

Trade Network supports:

- public safe references
- availability intent
- Looking For intent
- discovery
- interest
- conversation
- private negotiation
- optional manual review

### Logged Trade

Logged Trade records:

- selected outgoing owned inventory items
- selected incoming cards
- counterparty
- cash paid or received
- direct trade costs
- basis allocation
- explicit review
- final Core trade transaction
- ownership events
- basis events
- lineage edges
- audit event

### Operating Rule

A card can be visible as trade-available without exposing the private inventory
item.

A public trade reference is not evidence that the card is currently available,
still owned, or guaranteed to be included in a completed trade.

Only final logged-trade commit creates ownership and basis truth.

## Trade Network Experience

Trade Network is a product-specific discovery surface, not a generic community
feed. Community infrastructure or messaging may eventually host parts of the
experience, but Trade Network should remain calm, card-aware, and
relationship-first.

### 1. For You

For You presents relevant trade opportunities. Relevance may later come from a
collector's stated interests, saved searches, goals, collection context, or
availability preferences.

For You should not become an algorithmic social feed. It should use a calm,
relevance-first presentation that helps a collector notice useful trade
opportunities without engagement mechanics.

### 2. Browse

Browse lets collectors discover public safe card references intentionally
shared for trade.

Possible browse dimensions include card identity, sport, player, set,
parallel, grade, type, broad location or region only if intentionally exposed
later, and trade intent.

Browse must not expose private inventory details.

### 3. Looking For

Looking For captures collector-declared acquisition interests. Examples
include player, set needs, parallels, specific card identities, and trade-up
targets.

Looking For remains intent. It is not a public buy order and not a binding
request.

### 4. My Trade Desk

My Trade Desk is the collector's trade control surface. It may later include:

- user's trade-available public references
- Looking For items
- saved opportunities
- active conversations
- completed logged trades
- pending or manual review context

My Trade Desk is not inventory truth. It organizes trade context around
private inventory and public references.

## Public Trade References And Privacy

Card Vertex follows the approved Card Identity and Catalog Strategy:

```text
Catalog Card Identity
-> Owned Card Instance
-> Evaluation / Certification State
-> Public Card Reference
```

A public trade reference is a safe public projection of an owned card instance.
It is intentionally shareable trade context. It is not the private inventory
item, not a transaction record, and not ownership proof.

### May Include If Intentionally Shared

- Card Vertex card identity
- public catalog image where allowed
- grade and certification state only if intentionally exposed
- market context only if intentionally exposed
- public condition summary only if intentionally exposed
- broad trade intent
- broad location or region only if intentionally exposed later
- collector profile presentation context later

### Must Not Expose

- purchase price
- true basis
- profit
- private notes
- storage location
- private tags
- transaction history
- ownership history
- grading costs
- private strategy
- private images unless explicitly shared
- internal inventory item ID
- unapproved seller or contact information

### Inventory Item Does Not Equal Trade Reference

The inventory item remains private.

The Trade Reference is a public-safe projection that may become stale, be
withdrawn, or have its availability changed without changing historical
transaction truth.

A trade reference should be revocable. Creating or sharing a trade reference
must not grant a recipient authority over the private item.

## Availability, Intent, And Trade Eligibility

Card Vertex must keep these concepts separate:

- private inventory state
- public trade availability intent
- trade eligibility
- reserved or active negotiation state later
- final ownership truth

### Conceptual Availability Labels

- Not Listed
- Open to Trade
- Trade + Cash Considered
- Trade Up Only
- Looking For Specific Return
- Available for Sale and Trade later
- On Hold / Reserved later
- Unavailable / In Grading
- Sold / Traded / Archived

Availability intent is not a completed transaction. It does not promise that a
specific offer will be accepted and does not create an ownership or basis
event.

Private inventory status remains authoritative. Inventory cards in active
grading should be unavailable for ordinary trade. Sold, traded, archived, or
otherwise unavailable cards cannot become active trade references. Public
listing or trade visibility may need to be withdrawn after a completed trade.

A user should be able to remove trade visibility without deleting inventory. A
card may be visible for trade while still not guaranteed for any particular
offer.

### MVP Trade Eligibility

A card may enter trade discovery only when:

- it remains owned inventory
- it is not sold, traded away, archived, or otherwise unavailable
- it is not in active grading or another incompatible workflow
- the owner intentionally enables trade visibility
- a safe public reference can be generated
- required identity state is acceptable for public sharing

## Looking For And Trade Interests

Looking For is collector-declared intent. It helps other collectors understand
what someone wants without creating a marketplace order.

Conceptual examples:

- player or athlete
- team
- set completion need
- specific card identity
- parallel or color
- grade range
- trade-up target
- preferred category
- "show me similar cards" later
- open-ended free-text note as private or selectively public later

Looking For is not a bid.

Looking For is not a marketplace listing.

Looking For does not reserve cards or create obligations.

Looking For should be reusable by Goals later, but must not be prematurely
generalized into a Satera-wide Goals or Wants system. User visibility controls
are required. Private research notes must remain private.

## Interest, Conversation, And Negotiation Boundaries

The recommended MVP interaction model is:

```text
Trade Reference
-> Express Interest
-> Start or continue product-scoped conversation
-> discuss privately
-> optionally open manual logged-trade review
-> final commit only after parties actually agree and exchange occurs
```

An interest action is not a proposal.

An interest action is not binding.

Conversation is not proof of a completed trade.

The community or messaging layer may host the conversation later, but Trade
Network must not depend on a global social feed. MVP should not include a
formal offer, counteroffer, or acceptance engine. MVP should not include
escrow, payments, shipping, identity verification, dispute handling, public
reputation scores, or automatic inventory locking merely because someone
expressed interest.

### Future Possibilities

The following are future capabilities and require separate contracts:

- trade proposals
- counteroffers
- temporary reservations
- shipping details
- authentication or condition confirmation
- completed-trade acknowledgments
- mutual "would trade again" signal
- dispute workflow
- formalized multi-party trade support

## Logged Trade Workflow

Logged Trade is a Card Vertex experience over existing Satera Core final-trade
truth. It records a completed exchange only after terms are known and the
collector is ready to commit the historical event.

### 1. Start Logged Trade

A collector may start from inventory, Trade Desk, a conversation, or manually.

### 2. Select Counterparty

The counterparty may be a person/contact record or manually entered
counterparty later. MVP should not require a public social profile.

### 3. Define What You Gave

The collector selects existing owned inventory items. Each outgoing item must
be eligible. No private inventory information is exposed outside the owner's
workspace.

### 4. Define What You Received

The collector identifies incoming cards. Canonical Card Vertex identity is
preferred. A controlled provisional identity policy may apply later. Each
incoming item needs intentional condition, grade, and certification information
when known.

### 5. Record Cash Adjustment

The collector records:

- cash paid
- cash received
- direct costs

Cash direction must not be ambiguous. A workflow should not allow both
directions to be entered in a way that hides the net effect.

### 6. Review Basis Pool

Review shows:

- outgoing basis
- cash paid
- cash received
- direct trade costs
- resulting incoming basis pool
- allocation across received items

The Core-aligned conceptual basis rule is:

```text
incoming basis pool =
  outgoing basis
  + cash paid
  + direct trade costs
  - cash received
```

Allocation across received items must be explicit and reconcile exactly before
final commit.

Card Vertex should not silently derive market value from the trade basis pool.
Trade values and market estimates are context, not transaction truth. If an
outgoing item has unknown basis, Card Vertex must surface Core constraints
rather than inventing a value.

### 7. Review And Commit

Final review must:

- confirm counterparty and context
- validate outgoing eligibility
- validate incoming identity
- validate allocation
- show irreversible-action disclosure
- invoke the existing Satera Core trade transaction
- return canonical transaction, inventory, and lineage result

Trade transaction commit must be idempotent at eventual implementation.

## Logged Trade Lifecycle And Corrections

Recommended product-facing lifecycle:

- Draft
- In Review
- Ready to Commit
- Commit In Progress
- Completed
- Cancelled
- Problem / Exception

### Draft

- no Core truth
- editable
- may be abandoned

### In Review

- cards, cash, direct costs, identities, and allocations are being reconciled

### Ready To Commit

- all required validation passes
- still editable until commit begins

### Commit In Progress

- no edits
- user-experience guard only
- eventual idempotency required

### Completed

- Core trade succeeded
- transaction, ownership events, basis events, lineage, and audit exist
- Card Vertex draft becomes read-only historical context

### Cancelled

- no Core truth
- preserve or delete according to explicit future policy

### Problem / Exception

Used for mismatch, disputed terms, missing item, incorrect identity, failed
receipt, duplicate attempt, or post-exchange correction need.

### Future Correction Categories

- wrong outgoing item
- wrong incoming item
- wrong cash amount
- wrong direct cost
- wrong allocation
- duplicate transaction
- trade never completed
- partial exchange
- later return or unwind
- identity correction
- counterparty correction

Do not silently edit completed trades. Corrections must preserve historical
truth through explicit corrective workflows, not mutation of the original
transaction record.

## Trust Model

Card Vertex trust should be evidence-based and calm, not gamified.

Potential future positive signals:

- completed trades
- repeat partners
- optional endorsements
- "Would Trade Again" acknowledgement
- verified organization or shop profile later
- participation context later

Do not build:

- star ratings
- public numerical reputation scores
- follower counts
- leaderboards
- "top trader" gamification
- public dispute score
- automated trust score

Proof of completed trade belongs to historical transaction truth. Public
presentation of trust signals belongs to Card Vertex and must be privacy-aware
and intentionally surfaced.

## Current Core Mapping And Future Requirements

### Current Core Already Provides

- inventory items as canonical owned physical item truth
- final trade transaction capability for completed exchanges
- transaction and transaction-line history
- ownership events for trade in and trade out
- basis events for trade allocation
- basis lineage edges connecting outgoing and incoming items
- audit events for final workflows
- public object references for safe exposure records
- product-scoped community and message infrastructure
- notification foundation
- product-lens reads
- organization and product profile foundations
- evaluation/certification lifecycle for grading availability context
- privacy, authorization, RLS, and direct-write hardening

### Likely Later Card Vertex Product State

Later schema design will likely need Card Vertex-specific ways to represent:

- Trade Network visibility and availability intent
- trade-safe public reference display policy
- Looking For records and visibility controls
- saved opportunities
- interest actions
- product-scoped trade conversations or conversation links
- manual logged-trade draft and review state
- counterparty/contact context
- outgoing and incoming selection work before commit
- allocation review state and validation snapshots
- idempotent commit guard
- completed logged-trade product context
- withdrawal after completed trade
- activity history derived from trade-domain and Core events
- trust presentation such as repeat partners or Would Trade Again later

### Product-Specific Boundaries

Trade Network layout, availability labels, Looking For semantics, interest
behavior, trade opportunity context, collector-facing review workflow,
product-specific trade status language, trade-specific signals, and
trade-specific trust presentation should remain Card Vertex product-domain
behavior.

Do not turn this into a generic Satera marketplace system. Satera should keep
owning canonical transaction truth, ownership transfer truth, basis calculation
and allocation, basis lineage, audit history, authorization, inventory truth,
public object references, and privacy enforcement.

### Decisions Before Schema Proposal

Before proposing schema, decide:

- exact public trade reference visibility states and withdrawal policy
- whether Looking For belongs to profile, Trade Desk, or a separate trade
  domain record
- whether conversations use community channels/messages, a future direct
  message primitive, or product-specific opportunity threads
- whether interest is anonymous, identified, revocable, or visible to both
  parties
- how active negotiation and reserved states behave later
- counterparty/contact identity policy for logged trades
- draft retention and cancellation policy
- idempotency and duplicate-commit guard design
- correction taxonomy and escalation path
- trust presentation and privacy rules

Community and messaging integration is required later, but it should not block
trade-domain planning. Trade Network can be planned as a product-domain
experience now while conversations remain an integration decision.

## Decision Matrix

| Concern | Recommended decision | Ownership | Current support | MVP requirement | Open risk | Requires schema decision later? |
| --- | --- | --- | --- | --- | --- | --- |
| Trade Network existence | Relationship-first collector opportunity surface, not marketplace | Card Vertex experience and domain | Public references and community substrate exist | Yes before trade UI | Marketplace expectations | Yes |
| Trade reference | Safe public projection, not inventory | Satera public reference bridge; Card Vertex rendering | Public object references exist | Yes | Stale or overexposed references | Yes |
| Public visibility | Intentional, revocable, field-limited exposure | Satera privacy enforcement; Card Vertex display policy | Active exposed references exist | Yes | Private field leakage | Yes |
| Availability intent | Non-binding public intent | Card Vertex | Inventory intent/availability exists internally | Yes | Users treating intent as commitment | Yes |
| Trade eligibility | Owned, available, not graded/sold/traded/archived, safe identity | Satera inventory truth; Card Vertex validation | Inventory status and evaluation state exist | Yes | Incompatible workflows | Yes |
| Looking For | Collector-declared acquisition intent, not bid | Card Vertex | Gap documented | Yes | Premature generic Wants system | Yes |
| Interest action | Lightweight non-binding signal | Card Vertex | No current implementation | Yes | Confusion with formal offer | Yes |
| Conversation linkage | Product-scoped private discussion from opportunity | Satera community/messaging substrate later; Card Vertex context | Community messages exist, not trade threads | Yes later | Global feed dependency | Yes |
| Private negotiation | Conversations do not prove completion | Card Vertex experience; Satera privacy | Community privacy substrate exists | Yes | Terms exposed publicly | Yes |
| Reserved state | Future active negotiation/hold state, not MVP locking | Card Vertex later; Satera inventory truth | No reservation workflow | No for MVP | Inventory oversold or falsely locked | Yes |
| Logged-trade draft | Editable review workspace before Core commit | Card Vertex | Gap documented | Yes | Duplicate transaction truth | Yes |
| Outgoing selection | Existing owned eligible inventory only | Satera inventory; Card Vertex selection UX | Trade RPC validates ownership and basis | Yes | Unknown basis or wrong copy | Possibly |
| Incoming identity | Prefer canonical Card Vertex identity; controlled provisional later | Card Vertex identity/catalog | Generic variant pointers exist | Yes | Provisional public confusion | Yes |
| Cash adjustment | Cash paid, cash received, and direct costs with clear direction | Satera final trade truth; Card Vertex review | Core trade supports cash/cost inputs | Yes | Ambiguous net effect | Possibly |
| Direct costs | Explicit trade-related costs, not hidden basis edits | Satera final trade truth; Card Vertex review | Core trade supports trade costs | Yes | Misclassification | Possibly |
| Basis allocation | Explicit allocation, exact reconciliation before commit | Satera basis truth; Card Vertex review | Core allocates final trade basis | Yes | Market value confused with basis | Possibly |
| Commit guard/idempotency | Stable guard required; UI lock alone is insufficient | Card Vertex service plus Core correctness | Final RPC is atomic; draft guard not built | Yes | Duplicate commit on retry | Yes |
| Completed trade history | Completed Core trade is historical truth | Satera Core; Card Vertex presentation | Transactions, events, lineage, audit exist | Yes | Public over-disclosure | No for existing Core; yes for UX |
| Correction handling | Explicit corrective workflows later; no silent edits | Satera canonical corrections; Card Vertex UX | Correction concepts exist, flows not designed | Later | Historical mutation | Yes |
| Trust presentation | Calm positive evidence only | Card Vertex presentation; Satera source facts | Completed trades/community facts exist | Later | Gamification or privacy leakage | Yes |
| Public reputation avoidance | No stars, scores, leaderboards, followers, or top-trader mechanics | Card Vertex | Policy only | Yes | Social-marketplace drift | No |
| Public reference withdrawal after trade | Withdraw or mark unavailable after completed trade | Card Vertex workflow; Satera reference state | Reference revoke/visibility concepts exist | Yes | Stale trade bait | Yes |
| Activity history | Compose from trade-domain and Core events without duplicating truth | Satera source facts; Card Vertex timeline | Core histories exist | Later | Mutable shadow history | Yes |

## Founder Decisions To Approve

1. Trade Network is relationship-first discovery, not a marketplace.
2. Public trade references are safe projections, not public inventory.
3. Availability intent is not a binding offer or completed transaction.
4. Interest and conversation are non-binding in MVP.
5. Logged Trade is the only path that creates completed ownership/basis truth.
6. Basis allocation must reconcile exactly for received cards.
7. Completed trades are immutable; corrections are explicit later.
8. Cards in grading or otherwise unavailable cannot enter ordinary trade.
9. Trust uses calm positive evidence, not numerical reputation scores.
10. Offers, counteroffers, payments, escrow, disputes, and shipment workflows
    are not MVP.

## Follow-On Sequence

1. Review and approve Card Vertex Trade Network and Logged Trade Contract.
2. Define Card Vertex collector profile and trust contract.
3. Define Card Vertex Goals and Signals contract.
4. Define Card Vertex Search, Dashboard, and comp write-path contract.
5. Define Card Vertex MVP Product Experience Specification.
6. Create a Card Vertex schema-design proposal only after preceding product
   decisions are approved.
7. Plan real workspace/build configuration for `apps/card-vertex`.
8. Create real Card Vertex app root only after product-domain plan is approved.
9. Build Card Vertex Inventory Workspace shell.
10. Add Card Vertex workflows incrementally.

## Do Not Build Yet

- migrations
- schema implementation
- Trade Network UI
- public marketplace listings
- auctions
- payments
- escrow
- shipping-label generation
- address exchange
- formal trade offers
- counteroffers
- automatic inventory locking
- reservation workflow
- dispute resolution
- buyer/seller protection
- identity verification
- public star ratings
- public numerical reputation scores
- leaderboards
- follower mechanics
- algorithmic social feed
- formal multi-party trade workflow
- correction implementation
- public API integrations
- marketplace imports

## Verification Plan

Because this is documentation-only, no Supabase reset is required. Required
verification commands:

```text
npm run test
npm run typecheck
npm run build
```

Do not claim success unless each command actually passes.
