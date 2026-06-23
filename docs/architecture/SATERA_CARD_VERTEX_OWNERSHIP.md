# Satera Core and Card Vertex Ownership

This document defines the architecture and product boundary to use before Card
Vertex implementation begins. It is planning documentation only. It does not
authorize schema, RPC, route, application, UI, or deployment work.

## Governing Rule

```text
Satera preserves what happened.
Card Vertex explains why it matters to a card collector.

Satera protects the truth.
Card Vertex makes that truth useful, contextual, human, and enjoyable.
```

Ownership does not imply separate databases. Card Vertex-specific records may
live in the shared Satera database and remain protected by shared Satera RLS,
permissions, audit systems, and product scoping. Database location does not
determine product ownership.

Satera owning canonical truth does not make Card Vertex a UI skin. Card Vertex
owns sports-card semantics, decisions, workflows, intelligence, and
collector-facing behavior. Satera owns the durable, reusable guarantees those
workflows rely on.

## Three-Layer Ownership Model

### 1. Satera Core

Satera Core owns reusable platform capabilities and canonical records:

- authentication, accounts, workspaces, and organizations
- memberships, roles, entitlements, and permissions
- privacy boundaries and product access
- audit history
- notification foundation
- community and moderation infrastructure
- public object reference safety
- canonical inventory truth
- transaction, sale, and trade truth
- basis and basis lineage
- lot commit truth
- evaluation and certification lifecycle primitives
- cross-product identity continuity
- future cross-product portfolio and operator capabilities

Core answers who may act, what happened, what an owner holds, how basis was
derived, what was exposed publicly, and which history must remain auditable.

### 2. Card Vertex Product Domain

The Card Vertex product domain owns card-specific meaning and behavior:

- sports card identity interpretation
- players, teams, sets, parallels, and serial-number semantics
- grading-company presentation
- card-specific filters and search interpretation
- card-specific goals and signals
- trade-network behavior
- collector-focused trust presentation
- card-specific lot workflow behavior
- grading workspace behavior
- card-market context
- card-specific product rules

This layer may require Card Vertex-specific records in the shared database.
Those records remain subject to Satera identity, privacy, RLS, audit, and
product-scoping rules. Shared storage is not a reason to make a concept generic.

### 3. Card Vertex Experience

The Card Vertex experience owns the collector-facing product:

- Dashboard
- Inventory Workspace
- Trade Network
- Community Dock and full Community page
- Context Drawer
- center sheets
- card reference rendering
- interaction patterns and visual hierarchy
- desktop-first responsive behavior
- product language
- card-specific workflows

The experience invokes Card Vertex domain behavior and Satera Core services. It
must not recreate financial, permission, privacy, lineage, or audit truth in UI
state.

## Ownership Decision Matrix

“Current state” distinguishes implemented foundation from planned behavior.
“Future implementation guidance” is direction, not approval to build.

| System | Satera owns | Card Vertex owns | Current state | Future implementation guidance | Do not build yet |
| --- | --- | --- | --- | --- | --- |
| Identity and access | Authentication, accounts, owner contexts, workspaces, organizations, memberships, roles, entitlements, permissions, privacy, product access | Onboarding language, access presentation, and collector-facing account context | Core identity, ownership, entitlement, privacy, RLS, and product-lens boundaries exist | Use shared identity and explicit Card Vertex product context; never infer inventory access from product access | Separate Card Vertex auth, database, Supabase project, or permissions |
| Collector profile | Cross-product account identity, privacy, restrictions, and identity continuity | Card-collector fields, interests, Looking For context, profile presentation, and relationship story | Shared account/community foundations exist; a complete collector profile does not | Define card-specific requirements before proposing data; separate private from public fields | Generic social profiles, followers, engagement mechanics, or premature abstraction |
| Inventory | Canonical item, owner, status, privacy, basis, lineage, and safe mutation truth | Card identity display, terminology, filters, columns, bulk behavior, organization, and collector workflows | Core inventory and safe transaction/update paths exist; Card Vertex workspace does not | Query through product-lens services and translate card semantics without duplicating truth | Alternate inventory ledger, direct writes, or inventory UI now |
| Transactions | Canonical transactions, lines, ownership events, basis events, lineage, atomicity, and audit | Card-specific intake, review, terminology, and context | Starting inventory, purchase, lot purchase, sale, and trade RPC foundations exist | Keep financial mutation behind Core workflows; let Card Vertex orchestrate card input and review | Product-side canonical financial logic or new RPCs in this pass |
| Sales | Sale price, selling costs, net proceeds, realized profit/loss, disposition, and audit | Sale UX, review, marketplace terminology, projected proceeds, and history presentation | Core sale RPC exists; Card Vertex sale workflow does not | Treat Available for Sale as intent; record a sale only when final terms are known | Marketplace execution, listing integrations, automated completion, or sale UI |
| Trades | Completed trade, cards in/out, cash direction, direct costs, basis allocation, ownership changes, lineage, and audit | Partner/card selection, relationship context, review, and Trade Center Sheet | Core trade RPC exists; Trade Center Sheet does not | Use one completed-trade workflow for cards, cash either direction, and costs | Competing trade truth flows or direct basis manipulation |
| Trade Network | Relationship/access facts, privacy, safe references, community substrate, and future approved proposal facts | Discovery, Looking For, available-for-trade references, lightweight interest, conversations, relevance, and network behavior | Community/public-reference foundations exist; Trade Network does not | Start with opportunity and relationship discovery; complete trades in the Trade Center Sheet | Formal proposals, counters, acceptance, escrow, or automatic completion |
| Lots | Final lot transaction, basis pool/allocation truth, inventory creation, ownership/basis events, lineage, and audit | Draft Lot Workspace, intake, key cards, notes, source context, review, allocation experience, and starting-inventory experience | Lot Purchase RPC exists; Draft Lot Workspace lifecycle does not | Design a long-lived Card Vertex draft layer above the final commit mechanism | Treating drafts as inventory/transactions, changing the commit RPC, or lot UI now |
| Grading/evaluation | Product-neutral cases, items, lifecycle events, result history, attachments, basis increases, privacy, and audit | Grading-company language, submission workspace, card-specific states, cert presentation, estimated-grade context, and rules | Core lifecycle exists; Card Vertex grading workspace does not | Translate the Core lifecycle into a card workflow; keep market value separate from basis | Provider integrations, grading UI, uploads, or automatic value/basis changes |
| Community | Communities, channels, memberships, roles, messages, safe references, privacy, moderation, and audit | Community Dock/page behavior, card discussion, card sharing, language, and collector interactions | Community Core and moderation foundations exist; Card Vertex surfaces do not | Build branded surfaces over Core permissions and references | New community backend, realtime/media, or engagement ranking |
| Public card references | Exposure records, privacy enforcement, safe fields, source linkage, and lifecycle rules | Card rendering, labels, interaction, attachment behavior, and collector context | Core public references and safe message attachments exist; Card Vertex rendering does not | Keep private inventory distinct and disclose only approved display data | Sharing private rows or exposing basis, profit, notes, tags, location, or history |
| Notifications | Durable events, recipients, state, safe metadata, access, audit, and delivery substrate | Card-specific wording, relevance, grouping, placement, and action | Core foundation exists; Card Vertex notification experience does not | Generate notifications from canonical events and product decisions; distinguish them from signals | Delivery providers, preferences, push/email/SMS, or notification UI now |
| Signals | Source facts/events, access controls, relationship facts, and notification substrate | Card-specific definition, relevance, explanation, placement, and collector action | Source foundations partly exist; Card Vertex signals do not | Build first in Card Vertex; promote only after another product proves reuse | Generic Satera signal engine, opaque scores, or signals as notifications |
| Goals | Identity, permissions, privacy, and a possible future intent primitive after proven reuse | Player, set, rainbow, theme, trade-up, custom goals, and progress semantics | No generic Goals product exists | Design and validate inside Card Vertex first | Generic Satera Goals product or speculative universal schema |
| Search | Permission-aware source access; later indexing, cross-product retrieval, and history if proven reusable | Spotlight UX, card query interpretation, ranking, filters, actions, and presentation | Product-lens reads exist; Card Vertex search and general search infrastructure do not | Begin with card tasks and preserve permissions at retrieval | Premature cross-product search platform, route, or index |
| Trust and endorsements | Relationship facts, completed trade facts, endorsements, moderation, restrictions, privacy, and audit | Collector trust presentation, trade context, and relationship storytelling | Relationship/community/moderation facts exist in part; Card Vertex trust does not | Present specific, explainable facts instead of a synthetic score | Stars, negative reviews, numerical reputation, followers, or engagement mechanics |
| Activity history | Canonical ownership, transaction, basis, evaluation, moderation, notification, and audit events | Card-focused selection, explanation, labels, grouping, and visibility | Multiple Core histories exist; no unified Card Vertex activity experience exists | Compose permission-safe views from canonical events | Duplicated mutable history or private financial/audit leakage |
| Market/comps | Privacy, provenance-capable evidence records, access rules, and separation of value evidence from basis | Card-market interpretation, matching, parallel/grade context, rationale, confidence, and research UX | Early evidence infrastructure exists; direct client writes and Card Vertex workflow do not | Keep evidence transparent and establish reviewed write boundaries first | Scraping, black-box valuation, direct writes, or automatic basis changes |
| Future Portfolio | Cross-product identity, inventory continuity, canonical basis/value inputs, permissions, and aggregation | Card Vertex links and card-context handoff | No Portfolio surface is implemented | Build after product truths and lens boundaries are stable | Portfolio UI or speculative aggregation now |
| Future Vertex Pro | Organization identity, roles, permissions, cross-product truth, moderation, and audit | Card Vertex-specific handoffs and card-domain operator context | Vertex Pro planning exists; no operator app is implemented | Let Vertex Pro own operator workflows over shared Core and product facts | Vertex Pro app, dealer workflows, or generalized operator abstractions now |

## Promotion Rule

Build the first experience in Card Vertex. Promote only proven reusable
primitives to Satera after another product has a real need for them.

Promotion requires evidence of stable semantics across products. Shared
storage, a shared database, or possible future reuse is not enough. A promoted
primitive must preserve product-owned interpretation and keep card terminology
out of Core.

## Boundary Tests

1. If it preserves canonical ownership, money, basis, lineage, permissions,
   privacy, or audit history, Satera Core owns the guarantee.
2. If it interprets card identity, collector intent, card markets, or a card
   workflow, Card Vertex Product Domain owns the behavior.
3. If it determines how collectors navigate, understand, or act, Card Vertex
   Experience owns it.
4. A record may live in the shared database without changing domain ownership.
5. If reuse is hypothetical, keep it in Card Vertex until another product
   proves a shared primitive is needed.

## Current Architecture Gaps

- Card Vertex product-domain records and contracts have not been defined.
- A Draft Lot Workspace lifecycle is missing above the final lot commit RPC.
- Card identity and catalog strategy is not yet defined.
- Signals, Goals, search, and trust contracts are not defined.
- Trade Network and Logged Trade behavior is now defined in
  `docs/products/card-vertex/TRADE_NETWORK_AND_LOGGED_TRADE_CONTRACT.md`.
- Grading behavior has not been mapped onto the Core evaluation lifecycle.
- A Card Vertex MVP Product Experience Specification has not been approved.
- Real Card Vertex workspace, build, deployment, routes, and UI remain future
  work.
