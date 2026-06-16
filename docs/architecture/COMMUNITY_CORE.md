# Satera Community Core

This document describes Satera Community Core architecture. Pass 1 implemented
the reusable backend MVP: schema, RLS, RPC write paths, safe public object
reference message attachments, basic moderation records, audit events, and SQL
verification. Pass 2 adds the TypeScript service layer and read-only Internal
Inspector visibility. Notification Foundation now exists separately in Satera
Core as durable event and recipient state infrastructure. This document still
does not describe product UI, realtime transport, media processing,
notification UI, notification delivery, or advanced moderation automation.

## Core Rule

Satera should own the community system. Products should own the community
experience.

Satera should not become a visible generic social network. Do not build:

- global Satera feed
- generic Discord clone
- public viral profile network
- algorithmic social feed
- global marketplace-first social app

Instead, Satera should provide reusable product-scoped community infrastructure
that products can render through their own workflow language and UI.

## Ownership Boundaries

Satera Community Core should eventually own:

- communities
- channels
- memberships
- roles
- messages
- posts
- comments
- attachments through safe public object references
- moderation reports
- moderation actions
- moderation events
- durable user restrictions
- internal moderation notes
- appeals
- audit trail
- notifications
- presence metadata later
- live-room metadata later
- media asset metadata later

Product experiences should own:

- layout
- workflow
- language
- product-specific object references
- product-specific context panels
- product-specific community templates
- product-specific interaction patterns

## Layer 1: Satera Community Core

Satera Community Core is reusable across every product. It is responsible for:

- who can join
- who can post
- who can moderate
- what product the community belongs to
- what channel the content belongs to
- what object was referenced
- what was reported
- what was hidden or removed
- what happened historically

Pass 1 implements:

- `communities`
- `community_channels`
- `community_memberships`
- `community_messages`
- `community_message_references`
- `moderation_reports`
- `moderation_actions`
- helper authorization functions for community read/member/moderator checks
- RPCs for creating communities, creating channels, joining open communities,
  creating messages, reporting content, and recording moderation actions
- audit events for important community actions
- RLS policies and direct-write hardening so application clients use RPCs

Pass 2 implements:

- TypeScript Community Core types and read helpers
- TypeScript mutation helpers that call `create_community`,
  `create_community_channel`, `join_community`, `create_community_message`,
  `report_community_content`, and `moderate_community_content`
- service-layer tests that verify community mutations use RPCs only
- read-only Internal Inspector views for communities, messages, references,
  moderation reports, and moderation actions

Moderation Foundation hardening adds:

- `user_restrictions`
- `moderation_notes`
- `moderation_appeals`
- restriction-aware `create_community_message` posting checks
- expanded `moderate_community_content` enforcement behavior
- RPCs for lifting restrictions, adding moderation notes, and submitting
  appeals
- RLS and direct-write hardening for enforcement records
- audit events for moderation decisions, restrictions, notes, and appeals

Notification Foundation adds reusable Core infrastructure for:

- durable notification events
- recipient notification state
- read, dismissed, and archived state
- product, entity, and related entity context
- safe metadata only
- future delivery-attempt tracking
- audit events

Community workflows can emit notification events later, but products render the
experience. No notification UI, email, push, SMS, realtime delivery, or
background jobs are part of Community Core.

## Layer 2: Product Community Templates

Product Community Templates are reusable defaults that products can configure.

Examples:

- Collector Group Template
- Shop Community Template
- Show/Event Community Template
- Trade Room Template
- Break/Live Room Template later
- Dealer Support Template

Card Vertex template examples:

- Trade/Sale
- Looking For
- Comps & Research
- Show Floor
- Shop Announcements
- Break Room later

Comic Vertex template examples:

- Pull Lists
- Keys & Grails
- Convention Floor
- Shop Announcements
- Trade/Sale

## Layer 3: Product-Specific UI

Card Vertex uses:

- inventory workspace
- saved filters
- inventory table
- community dock
- fixed composer
- drag/drop public card references
- card context drawer

Future products may use different layouts while reusing the same Satera
Community Core.

## Object Reference Rule

Private inventory items must not be exposed directly through community content.
The pattern is:

```text
Private inventory item
-> Safe public object reference
-> Community attachment/message/post
```

This pattern should scale across products:

- Card Vertex: Private card inventory item -> Public card reference
- Comic Vertex: Private comic inventory item -> Public comic reference
- Watch Vertex: Private watch inventory item -> Public watch reference
- Game Vertex: Private game inventory item -> Public game reference

Private fields such as true cost basis, purchase price, location, private
notes, private tags, ownership history, transaction history, and strategy must
not leak into public object references.

The implemented Core bridge for this rule is `public_object_references`. It is
a safe display/exposure table, not an inventory truth table. Community messages
attach these public references through `community_message_references` instead
of attaching `inventory_items` rows.

`community_message_references.display_snapshot` is intentionally limited to
safe public reference display fields such as title, subtitle, label, image,
condition, grade, value label, visibility, and safe public metadata. It must not
contain true basis, purchase price, profit, ROI, location, private notes,
private tags, ownership history, private transaction history, or
evaluation/certification costs such as grading costs.

TypeScript message creation accepts public object reference ids only for
attachments. It does not accept inventory item ids, true basis, purchase price,
private notes, private tags, ownership history, or private transaction history
payload fields.

## Implemented Schema

The Pass 1 schema is platform-level and product-scoped:

- `communities`
- `community_channels`
- `community_memberships`
- `community_messages`
- `community_message_references`
- `moderation_reports`
- `moderation_actions`
- `user_restrictions`
- `moderation_notes`
- `moderation_appeals`

The Pass 2 service and inspector layer is also platform-level. The Internal
Inspector reads these records for debugging and audit visibility only; it does
not provide edit buttons, forms, create message UI, moderation write UI, or
product-facing moderation dashboard behavior.

The following remain future concepts:

- `community_roles`
- `community_permissions`
- `community_posts`
- `community_comments`
- richer attachment models beyond public object references
- `moderation_events`
- community-specific notification hooks into the Core notification foundation

Any future schema must preserve Satera Core privacy boundaries and product lens
rules. Product membership, entitlement, or community participation must not
override private inventory ownership.

## Phase 1 Scope

Community Phase 1 includes:

- Satera Community Core concepts
- product-scoped communities
- channels
- memberships
- roles
- messages
- safe public object references
- basic moderation foundation records
- audit trail
- RPC-only TypeScript mutation services
- read-only Internal Inspector visibility

Community Phase 1 does not include:

- LiveKit implementation
- Discord-style screen share
- uploaded video playback
- realtime implementation
- notification UI
- email, push, SMS, realtime notification delivery, or background jobs
- advanced automated moderation
- AI moderation
- marketplace payments
- global discovery feed
- generic social-network UI
- Card Vertex Community Dock
- Card Vertex pages
- Vertex Pro community management UI

## Moderation Foundation

Moderation belongs in Satera Core, not Card Vertex or any other product lens.
Satera owns moderation state, enforcement, decisions, appeals, and audit.
External moderation providers may provide future signals, but final moderation
state remains in Core.

Normal users should not see hidden, removed, or deleted community messages.
Moderators and admins can inspect moderated content in scope. Community message
attachments must continue to use safe public object references and must not
expose private inventory data.

This pass does not build product-facing moderation dashboards, automated or AI
moderation, realtime moderation workflows, LiveKit, voice, video, screenshare,
uploaded video, or media processing.
