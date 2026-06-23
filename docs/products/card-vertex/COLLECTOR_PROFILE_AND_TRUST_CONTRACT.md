# Card Vertex Collector Profile And Trust Contract

This document defines the approved Card Vertex collector profile and trust
contract before implementation begins. It is planning documentation only. It
does not authorize schema, RPC, route, UI, migration, seed, service, package,
build, Vercel, Supabase, marketplace-integration, or runnable Card Vertex app
work.

The governing boundary remains:

```text
Satera preserves identity, privacy, restrictions, ownership, transaction truth,
and auditability.
Card Vertex presents a selective card-collector identity and trust context.
```

Satera already owns platform identity, product access, product profiles,
organizations, organization memberships, organization product profiles,
privacy enforcement, public object references, community foundations,
moderation foundations, audit infrastructure, and canonical completed
transaction truth. Card Vertex must not redesign, replace, weaken, or
duplicate those guarantees. The missing product capability is Card Vertex's
collector-facing identity and trust presentation layer.

## Collector Profile Principle

A Card Vertex profile is not a generic social profile.

A Card Vertex profile is not a public inventory page.

A Card Vertex profile is not a follower graph.

A Card Vertex profile is not a public reputation score.

A Card Vertex profile is a selective collector-facing identity surface.

The approved layered model is:

```text
Satera Account Identity
-> Card Vertex Product Profile
-> Optional Organization / Shop Association
-> Selective Public Collector Presence
-> Public Trade References / Looking For / Trust Signals
```

The same person may participate in multiple Satera products. Their account
identity is continuous across products, but Card Vertex should show only the
card-specific presentation. Other product interests, activity, communities,
inventory, goals, or organization context should not leak into Card Vertex by
default.

Card Vertex profile visibility must never automatically expose private
inventory, private transaction truth, internal account identifiers, moderation
state, or financial fields. No profile section becomes public merely because
related inventory, transaction, community, or evaluation data exists.

## Profile Scope And Boundaries

Card Vertex should use least-exposure defaults. Profile data starts private or
product-scoped unless the user, product policy, and platform privacy rules
allow a narrower public or selectively public presentation.

### Public Or Selectively Public Sections

Future public or selectively public profile sections may include:

- display name or collector handle
- profile image or avatar later
- short collector bio
- collecting focus
- favorite players, teams, sets, eras, sports, or themes
- trade availability summary
- Looking For summary
- public trade references
- intentionally shared showcase cards later
- broad region only if the user enables it later
- shop or organization association if intentionally displayed
- selected calm trust signals
- participation context later

### Private-Only Information

Private-only information includes:

- full inventory
- purchase price
- true basis
- profit
- storage location
- private notes
- private tags
- ownership history
- private transaction history
- grading costs
- private strategy
- private contact details
- unapproved location details
- internal account identifiers
- internal moderation state
- private messages

Public references, Looking For summaries, trust signals, and showcases must be
intentional projections. They are not automatic windows into inventory,
transaction history, account state, private notes, messages, or moderation
records.

## Collector Profile Modes

The following are product-facing visibility concepts, not approved enums,
schema, routes, or policies:

- Private
- Card Vertex Members Only
- Public Profile
- Trade Discoverable
- Organization / Shop Affiliated
- Restricted / Limited Visibility

### Private

- no public profile discovery
- public trade references unavailable
- profile can still exist for internal product use

### Card Vertex Members Only

- profile visible only in authenticated Card Vertex context
- public trade reference behavior remains user-controlled
- does not imply visibility to other Satera products

### Public Profile

- selected profile information may be visible externally or to product users
  later
- does not imply public inventory
- does not imply public transaction history

### Trade Discoverable

- profile may appear in Trade Network context only when the user opts in
- public references and Looking For remain selective
- trade visibility does not create an obligation to trade

### Organization / Shop Affiliated

- profile may display optional affiliation to a Card Vertex organization
  profile
- affiliation does not transfer ownership of a private collector's inventory
- affiliation does not make a personal collector profile publicly commercial

### Restricted / Limited Visibility

- product moderation, user privacy choice, platform restriction, or safety
  setting may limit discovery, messaging, trade references, or profile sections
- internal moderation state must not become public reputation

## Trust Model

Trust should be evidence-based, calm, privacy-aware, and reversible in
presentation.

Trust should not be gamified.

Potential future positive trust signals include:

- completed trades, only where presentation is privacy-safe
- repeat trade partners
- optional "Would Trade Again" acknowledgements
- optional endorsements later
- verified organization/shop affiliation later
- identity verification or verified contact channel later
- participation history in product-scoped communities later
- show/event participation context later

Completed trade facts belong to Satera canonical transaction history. Card
Vertex decides whether and how those facts are presented to collectors. Trust
presentation must not reveal counterparties, cards, cash, values, costs,
messages, locations, or transaction terms without consent and policy support.

A completed-trade count may be acceptable later only if it does not create a
score, ranking system, or competitive volume mechanic. Trust signals should be
optional, contextual, and non-punitive. Absence of a signal is not negative
evidence.

Do not build:

- star ratings
- numerical reputation scores
- public rating averages
- follower counts
- leaderboards
- badges for volume
- "top trader" rankings
- public dispute counts
- automated trust scores
- social proof manipulation
- public transaction-value totals

## Trade And Profile Relationship

Collector Profile interacts with Trade Network as a selective identity and
context layer. It is not the Trade Network itself, and it is not inventory
truth.

Profile may show:

- selected trade availability summary
- Looking For summary
- selected public trade references
- optional broad trade preferences
- optional trust context
- optional shop or organization affiliation
- selected public contact path later

Profile must not:

- expose the collector's full inventory
- create an obligation to trade
- expose a card's true ownership history
- reveal basis, profit, location, private notes, or private strategy
- expose private messages
- automatically make all available cards public

The approved relationship is:

```text
Profile
-> selective public trade reference
-> Express Interest
-> private product-scoped conversation later
-> optional manual Logged Trade workflow
-> final Core transaction truth only at completion
```

Looking For and trade preferences are collector intent. They are not public
orders, binding offers, marketplace listings, inventory access grants, or
transaction truth.

## Organization And Shop Relationships

Individual collector profiles and organization/shop profiles use existing
Satera concepts:

- organizations
- organization memberships
- organization product profiles
- staff roles
- Card Vertex product profile

A collector may have no organization affiliation. A collector may optionally
display affiliation with a shop, dealer, breaker, team, community, or
organization where appropriate. A shop may have a separate organization-owned
Card Vertex profile.

Organization affiliation does not make the collector's private inventory
organization-owned. A dealer or staff role does not automatically make a
personal collector profile publicly commercial. Vertex Pro later manages
organization-level presence across products, but Card Vertex renders
card-specific context.

Potential future profile relationships include:

- owner
- staff
- affiliated collector
- verified shop representative
- event host
- community moderator

Those relationship labels are conceptual only. Exact roles, permission rules,
schema, verification workflow, and moderation workflow are not approved here.

## Identity, Moderation, And Privacy

Satera owns:

- authenticated identity
- restrictions
- bans
- moderation state
- audit trail
- authorization

Card Vertex owns:

- profile visibility controls
- trade discoverability controls
- card-specific profile fields
- profile section presentation
- product-context moderation experience later

An account restriction may limit profile discovery, Trade Network activity,
community participation, messaging, public references, or profile editing. A
Card Vertex profile should not expose internal moderation notes, active
restrictions, bans, appeals, reviewer identities, enforcement metadata, or
appeal outcomes as public reputation signals.

Platform/account privacy controls override product presentation preferences.
Profile edits require auditability where future trust, public trade context,
public references, historical display names, or organization affiliation
depends on them.

## Profile Lifecycle And Correction Model

The following are product-facing lifecycle concepts, not approved enums or
schema:

- Draft / Setup
- Active
- Limited Visibility
- Hidden
- Restricted
- Archived

Profile setup may be incomplete without blocking core inventory use. Public
fields remain editable. Historical transaction truth does not change because a
profile changes. Profile removal or hiding does not erase committed trade
history. A handle or display-name change must not silently break historical
references.

Future public-facing profile changes may require historical display handling.
For example, a public trade reference may need to preserve the display context
shown at the time while still linking to the current profile when allowed.
Account deletion, legal retention, and moderation deletion policy remain
Satera/platform concerns.

Conceptual correction categories include:

- display-name change
- handle change
- accidental public field exposure
- incorrect organization affiliation
- false or misleading trust presentation
- profile image/content moderation
- visibility-state correction
- public reference withdrawal
- account merge or duplicate profile later

Do not design final SQL, RPCs, table definitions, column types, migration names,
routes, UI, or service signatures here.

## Current Core Mapping And Future Requirements

### Current Core Already Provides

- Authenticated users and account identity through platform auth.
- Product profiles with product-scoped display name, handle, and profile data.
- Organizations for organization identity.
- Organization memberships for staff/member relationships.
- Organization product profiles for organization-owned product presence.
- Product context and product-lens reads for Card Vertex scoped access.
- Public object references for intentional safe exposure records.
- Community memberships and product-scoped community foundations.
- Moderation restrictions, notes, appeals, reports, actions, and enforcement
  foundations.
- Audit events for inspectable history.
- Transactions for canonical completed transaction truth.
- Ownership events for canonical item ownership history.
- Notification foundation for future product-scoped notification rendering.
- `packages/satera-core` as the future shared Core package boundary for
  product apps.

### Likely Later Card Vertex-Specific Records Or Presentation State

Later Card Vertex schema design will likely need product-specific ways to
represent:

- structured collector bio and collecting focus
- profile section visibility choices
- trade discoverability preference
- Looking For summary and detail records
- public trade reference selection and withdrawal context
- showcase selection later
- selected trust signal presentation preferences
- Would Trade Again acknowledgements later
- endorsements later
- profile/organization affiliation display state
- historical public display handling
- profile edit audit context for public/trust-relevant fields
- product-scoped contact path preference later

These needs should remain Card Vertex-specific until another product proves
matching semantics. Do not turn this into a generic Satera social-profile
system.

### What Must Be Decided Before Schema Proposal

- Which Card Vertex profile fields are MVP.
- Which fields are private, members-only, public, or trade-discoverable.
- Whether Looking For belongs directly on profile, Trade Network records,
  Goals, or a separate Card Vertex intent model.
- How public trade references attach to a profile without exposing inventory.
- Whether completed trade count is shown at all in MVP.
- Whether Would Trade Again exists in MVP or is deferred.
- Whether endorsements exist in MVP or are deferred.
- How organization affiliation is requested, approved, displayed, and removed.
- How profile handles/display names are retained for historical references.
- Which profile edits require explicit audit or public-history handling.
- How restrictions, privacy overrides, and public reference withdrawals affect
  discoverability.

### Deferred Until Trade Network Or Community Implementation

- private product-scoped conversation model
- public contact paths
- endorsement workflow
- organization verification workflow
- event/show participation context
- community participation trust context
- activity history presentation
- showcase card selection and rendering
- account merge or duplicate profile resolution

## Decision Matrix

| Concern | Recommended decision | Ownership | Current support | MVP requirement | Open risk | Requires schema decision later? |
| --- | --- | --- | --- | --- | --- | --- |
| Card Vertex profile existence | Approve a product-specific collector profile over continuous Satera identity | Satera identity; Card Vertex presentation | Product profiles exist | Yes before Trade Network | Generic social-profile drift | Yes |
| Display identity | Use Card Vertex display name/handle in card contexts | Satera product profile persistence; Card Vertex display | Product profile fields exist | Yes | Historical reference breakage | Yes |
| Collecting focus | Structured card-focused interests, not cross-product interests | Card Vertex | Profile data placeholder only | Yes | Leaking unrelated product interests | Yes |
| Public/private sections | Least-exposure defaults with explicit public sections | Satera privacy; Card Vertex section controls | Privacy/RLS foundations exist | Yes | Accidental inventory/financial leakage | Yes |
| Profile visibility mode | Treat modes as product-facing concepts first | Card Vertex; Satera override | No approved profile visibility model | Yes | Treating concepts as premature enums | Yes |
| Trade discoverability | Explicit opt-in for Trade Network discovery | Card Vertex; Satera restrictions | Public references and product profiles exist | Yes for Trade Network | Discovery without consent | Yes |
| Looking For summary | Selective intent, not a public order | Card Vertex | Not implemented | Yes for Trade Network | Marketplace/order confusion | Yes |
| Public trade references | Use safe public references only; never private inventory rows | Satera public reference bridge; Card Vertex rendering | Public object references exist | Yes | Stale or overexposed references | Yes |
| Showcase cards | Intentional later showcase, not automatic collection display | Card Vertex | Public references can support safe display | No MVP unless approved | Public inventory browsing pressure | Yes |
| Organization affiliation | Optional displayed relationship to organization/shop profile | Satera org/member/profile truth; Card Vertex display | Organizations and organization product profiles exist | Possibly | Implied inventory ownership transfer | Yes |
| Trust signals | Calm positive evidence only | Satera source facts; Card Vertex presentation | Completed trades, community, moderation foundations exist | Yes conceptually | Gamification pressure | Yes |
| Completed trade presentation | May show privacy-safe facts later without terms/counterparties | Satera transaction truth; Card Vertex presentation | Trade transaction truth exists | Possibly | Revealing private transaction details | Yes |
| Would Trade Again | Optional positive acknowledgement later | Card Vertex first | Not implemented | No MVP unless approved | Turning into ratings | Yes |
| Endorsements | Optional contextual endorsements later | Card Vertex first; possible Core only after reuse | Not implemented | No MVP unless approved | Social proof manipulation | Yes |
| Public ratings avoidance | Do not build stars, ratings, scores, rankings, follower counts | Product policy | No ratings exist | Yes | User pressure for reputation score | No, unless future reversal |
| Moderation/restriction behavior | Enforce privately; never public reputation | Satera moderation; Card Vertex experience | Restrictions and moderation foundations exist | Yes | Public shaming or hidden reason leakage | Yes |
| Public reference withdrawal | Revocable presentation without deleting inventory or history | Satera public references; Card Vertex controls | Revoke/hide states exist | Yes | Broken discovery/history links | Yes |
| Historical profile references | Preserve historical display context where public/trust history depends on it | Satera audit/source truth; Card Vertex presentation | Audit exists | Yes | Silent rewriting of public history | Yes |
| Activity history | Compose permission-safe card-focused activity later | Satera source facts; Card Vertex selection | Transactions, ownership, evaluation, community, audit exist | Later | Duplicated mutable history ledger | Yes |
| Profile edit auditability | Audit public/trust-relevant edits conceptually | Satera audit; Card Vertex edit policy | Audit foundation exists | Yes for public/trust fields | Undetectable misleading changes | Yes |

## Founder Decisions To Approve

1. Card Vertex profile is selective collector identity, not a social profile.
2. Satera identity remains continuous; Card Vertex renders card-specific
   context.
3. Private inventory and financial data never become public by default.
4. Trade discoverability and public references require explicit opt-in.
5. Looking For and trade preferences are selective intent, not public orders.
6. Trust uses calm positive evidence, not ratings, scores, followers, or
   rankings.
7. Organization affiliation is optional and does not transfer private inventory
   ownership.
8. Profile changes do not rewrite historical transaction truth.
9. Moderation state is enforced privately and never becomes public reputation.
10. Showcase cards, endorsements, verification, and public contact paths are
    deferred beyond MVP unless explicitly approved later.

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
- profile UI
- public profile routes
- follower mechanics
- follower counts
- social feed
- direct messaging
- public ratings
- public numerical reputation scores
- leaderboards
- verified identity program
- public contact details
- public inventory browsing
- automatic collection showcase
- public transaction-value totals
- organization verification workflow
- endorsement workflow
- account merge workflow
- profile moderation UI
- generic Satera social profile system

## Verification Plan

Because this is documentation-only, no Supabase reset is required. Required
verification commands:

```text
npm run test
npm run typecheck
npm run build
```

Do not claim success unless each command actually passes.
