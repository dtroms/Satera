# Card Vertex Product Domain and Workflows

This document defines planned Card Vertex behavior over Satera Core. It is not
an implementation specification and does not authorize schema, RPC, route, app,
UI, provider-integration, or configuration work.

The ownership baseline is
[`SATERA_CARD_VERTEX_OWNERSHIP.md`](../../architecture/SATERA_CARD_VERTEX_OWNERSHIP.md).
The current data-model gap assessment is
[`PRODUCT_DOMAIN_DATA_MODEL_GAP_ASSESSMENT.md`](PRODUCT_DOMAIN_DATA_MODEL_GAP_ASSESSMENT.md).
The proposed card identity and catalog strategy is
[`CARD_IDENTITY_AND_CATALOG_STRATEGY.md`](CARD_IDENTITY_AND_CATALOG_STRATEGY.md).
The Draft Lot Workspace architecture and lifecycle is
[`DRAFT_LOT_WORKSPACE_ARCHITECTURE.md`](DRAFT_LOT_WORKSPACE_ARCHITECTURE.md).
The Grading Workspace and Certification Lifecycle contract is
[`GRADING_WORKSPACE_AND_CERTIFICATION_LIFECYCLE.md`](GRADING_WORKSPACE_AND_CERTIFICATION_LIFECYCLE.md).

## Product Domain Principle

Card Vertex is the first product lens powered by Satera, but it is not merely a
skin over Core records. Card Vertex owns the sports-card interpretation and
collector workflow that turns canonical facts into useful decisions.

```text
Satera preserves what happened.
Card Vertex explains why it matters to a card collector.
```

Card Vertex-specific records may remain in the shared Satera database. They
must use shared identity, privacy, permissions, RLS, audit, and product scoping.
Physical storage does not transfer product-domain ownership to Satera Core.

## Product Surfaces

The planned Card Vertex experience includes:

- Dashboard for card-specific signals, goals, and next actions
- Inventory Workspace for dense, card-aware collection work
- Trade Network for opportunity and relationship discovery
- Community Dock and full Community page
- Context Drawer for card identity, market, lineage, activity, and discussion
- center sheets for focused workflows such as completed trades and sales
- card reference rendering and card-specific interaction patterns

These surfaces remain future work. Their inclusion here defines responsibility,
not implementation status.

## Trade Network and Logged Trades

Trade Network and Logged Trade solve different problems.

### Trade Network

Trade Network is opportunity and relationship discovery. Its initial behavior
should support:

- collector discovery through relevant card and relationship context
- Looking For interests
- available-for-trade public card references
- lightweight interest signals
- conversations that can develop into an offline or agreed trade

It should not initially act as a formal exchange. Proposals, counters,
acceptance, escrow, automatic completion, and dispute handling are later
capabilities requiring separate approval and contracts.

Satera supplies identity, privacy, relationship facts, community/conversation
infrastructure, moderation, and safe public references. Card Vertex owns trade
discovery semantics, relevance, partner context, card presentation, and the
collector behavior of the network.

### Logged Trade

A completed trade is recorded through one Trade Center Sheet. One workflow
handles:

- cards coming in
- cards going out
- cash paid or cash received
- direct trade costs
- review before final commit

Satera owns the resulting transaction truth, ownership changes, basis
allocation, basis lineage, and audit history. Card Vertex owns partner
selection, card selection, relationship context, review UI, card terminology,
and Trade Center Sheet behavior.

The Trade Center Sheet records a completed trade; it is not the first version
of a negotiation engine. Completion must invoke the approved Satera trade
transaction mechanism rather than reconstructing basis in product code.

## Sale Intent and Sale Truth

“Available for Sale” is an intent or inventory state change. It is not a sale
transaction. It may affect Card Vertex discovery and workflow presentation, but
it must not dispose of ownership or realize profit/loss.

An actual sale is recorded only after final terms are known. Satera owns:

- sale price
- selling costs
- net proceeds
- realized profit/loss
- ownership disposition
- audit history

Card Vertex owns:

- sale workflow and review experience
- marketplace-specific terminology
- projected proceeds display before commit
- card-specific historical presentation after commit

Projected amounts are explanatory UI, not canonical results. Final sale truth
must come from the Satera sale transaction workflow.

## Draft Lots and Committed Lots

A draft lot is neither inventory nor a transaction. It is a long-lived Card
Vertex workspace for uncertain acquisitions. A collector may still be
identifying cards, deciding which cards matter, recording source context, or
working out basis allocation.

Draft lots can be edited, paused, deleted, and revisited. A committed lot is
historical and remains visible after commitment.

Satera owns final lot commitment:

- basis allocation truth
- inventory creation
- ownership events
- basis events and lineage
- audit history

Card Vertex owns Lot Workspace behavior:

- candidate-card intake
- key-card highlighting
- acquisition notes
- dealer, show, or collection context
- review behavior
- allocation experience
- draft workflow
- starting-inventory experience

### Current Architecture Gap

The existing Satera Lot Purchase Transaction RPC is the correct final “Commit
Lot” truth mechanism. Card Vertex still needs a Draft Lot Workspace above that
commit action.

Target flow:

```text
Card Vertex Draft Lot Workspace
-> card intake, notes, key cards, allocation, review
-> Commit Lot
-> Satera Lot Purchase Transaction RPC
-> inventory, basis events, lineage, audit
```

The Draft Lot Workspace lifecycle, persistence needs, permissions, deletion
semantics, and commit contract must be designed before schema is proposed. Do
not modify the existing final commit mechanism merely to represent draft work.
That architecture is now defined in
[`DRAFT_LOT_WORKSPACE_ARCHITECTURE.md`](DRAFT_LOT_WORKSPACE_ARCHITECTURE.md):
Draft Lots are reversible Card Vertex preparation workspaces, not inventory,
transactions, or final accounting records; commit is the only boundary where
Satera Core truth is created.

## Grading and Evaluation

Satera owns the product-neutral evaluation/certification lifecycle, access,
event history, attachments, audit, and explicit handling of costs that may
increase basis.

Card Vertex owns grading workspace behavior, grading-company presentation,
submission language, cert-number context, card-specific state explanation,
estimated-grade context, and the relationship between grading and collector
goals. A grading result does not automatically change basis or market value.

The product workflow should translate the existing lifecycle rather than fork
it. Provider integrations, submission packages, uploads, and Card Vertex UI are
not part of the current state.

The approved grading contract is documented in
[`GRADING_WORKSPACE_AND_CERTIFICATION_LIFECYCLE.md`](GRADING_WORKSPACE_AND_CERTIFICATION_LIFECYCLE.md).
It defines grading as evaluation/certification state on an owned physical card,
not a new catalog card; requires Return Review before completion; keeps cards
visible as inventory but operationally unavailable while grading; preserves
grade/certification history; and keeps grading costs, basis capitalization,
and market value interpretation separate.

## Signals and Notifications

Signals explain why something matters. Notifications announce that something
happened.

Satera owns source facts, canonical events, access controls, relationship facts,
and the notification substrate. Card Vertex owns signal definition, relevance,
explanation, dashboard placement, and the collector-facing action.

Examples of Card Vertex signals may eventually include a goal-relevant card
becoming available, a comp changing the context of a parallel, or a grading
result creating a useful next decision. These are product interpretations, not
new canonical facts.

Build the first signal experience in Card Vertex. Do not build a generic Satera
signal engine first. Promote a reusable primitive only after another product
has a concrete need with matching semantics.

## Collector Goals

Do not build a generic Satera Goals product first. Card Vertex owns:

- player goals
- set goals
- rainbow goals
- theme goals
- trade-up goals
- custom collector goals

Card Vertex also owns goal progress meaning, card matching, suggestions, and
collector-facing actions. Satera may later own a generic Intent or Goal
primitive after reuse is proven across products. Hypothetical reuse is not a
reason to generalize the first model.

## Search

Card Vertex owns the Spotlight-style search experience and card-specific query
and result interpretation. That includes understanding player, team, year, set,
parallel, grade, serial number, collector intent, and appropriate actions in
context.

Satera may later own search indexing, permission-aware retrieval,
cross-product result infrastructure, and history primitives. Any future search
infrastructure must preserve owner/workspace/organization privacy before
Card Vertex ranks or presents results.

Start from Card Vertex search tasks. Do not build a generic cross-product search
platform before the card experience proves its contracts.

## Trust and Endorsements

Satera owns underlying relationship facts, completed trade facts,
endorsements, moderation, restrictions, privacy, and auditability. Card Vertex
owns the card-collector profile, trade context, trust presentation, and
relationship storytelling.

Trust should be specific and explainable: shared community context, completed
trade history that the viewer is permitted to see, or a concrete endorsement.
Avoid:

- star ratings
- negative reviews
- numerical reputation scores
- followers
- engagement mechanics

Trust presentation must not expose private transaction terms, inventory,
financial history, restrictions, or moderation details beyond the viewer's
authorization.

## Card Identity, Market Context, and Activity

Card Vertex owns interpretation of players, teams, sets, parallels,
serial-number semantics, grading presentation, and card-market matching. Satera
owns canonical inventory association, access, durable evidence, and the strict
separation between value evidence and financial basis.

Card identity should follow the four-layer strategy: Catalog Card Identity,
Owned Card Instance, Evaluation / Certification State, and Public Card
Reference. Grade and certification should not create a new catalog-card
identity by default, exact serial number belongs to the owned physical copy,
and safe public display must be mediated through public object references.

Card Vertex market/comps behavior should explain evidence, matching rationale,
recency, source, grade/parallel context, inclusion or exclusion, and confidence.
It must not present a black-box number as truth or mutate basis because market
context changed.

Card Vertex may compose a collector-facing activity timeline from authorized
Core events and product-domain events. Satera remains the canonical source for
ownership, transaction, basis, evaluation, moderation, and audit history.
Card Vertex owns which events are useful to collectors and how they are grouped
and explained; it must not create a competing history ledger.

## Promotion and Build Rule

Build the first experience in Card Vertex. Promote only proven reusable
primitives to Satera after another product has a real need for them.

Documentation of a future system is not authorization to implement it. Before
implementation begins, define the Card Vertex data-model gaps, lifecycle and
service contracts, privacy requirements, and MVP experience, then review which
parts are truly Core guarantees and which remain product-domain behavior.
