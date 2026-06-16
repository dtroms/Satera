# Satera Community Core

This document describes Satera Community Core architecture. Pass 1 has now
implemented the reusable backend MVP: schema, RLS, RPC write paths, safe public
object reference message attachments, basic moderation records, audit events,
and SQL verification. It still does not describe product UI, routes, realtime
transport, media processing, or advanced moderation automation.

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
private tags, ownership history, private transaction history, or grading costs.

## Implemented Schema

The Pass 1 schema is platform-level and product-scoped:

- `communities`
- `community_channels`
- `community_memberships`
- `community_messages`
- `community_message_references`
- `moderation_reports`
- `moderation_actions`

The following remain future concepts:

- `community_roles`
- `community_permissions`
- `community_posts`
- `community_comments`
- richer attachment models beyond public object references
- `moderation_events`
- `user_restrictions`
- `community_bans`
- `channel_mutes`
- `notifications`

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

Community Phase 1 does not include:

- LiveKit implementation
- Discord-style screen share
- uploaded video playback
- advanced automated moderation
- marketplace payments
- global discovery feed
- generic social-network UI
- Card Vertex Community Dock
- Vertex Pro community management UI
