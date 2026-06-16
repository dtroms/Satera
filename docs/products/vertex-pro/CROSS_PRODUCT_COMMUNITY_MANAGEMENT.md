# Vertex Pro Cross-Product Community Management

This document is Vertex Pro product planning. Satera Community Core Pass 1 now
implements the reusable backend schema, RLS, RPCs, safe public object reference
message attachments, basic moderation records, and audit events. Vertex Pro
routes, UI, realtime, operator workflows, and cross-product moderation screens
remain future work.

## Principle

Vertex Pro does not own separate communities. Vertex Pro is the operator
console for managing organization-owned community presence across multiple
product contexts.

```text
Satera Community Core = shared infrastructure
Card Vertex Community = card-specific community surface
Comic Vertex Community = comic-specific community surface
Watch Vertex Community = watch-specific community surface
Vertex Pro = business/operator control center across those surfaces
```

Core rule:

```text
A community belongs to a product context.
An organization can participate in many product contexts.
```

Example organization:

- Dale's Collectibles

Organization product profiles:

- Card Vertex profile
- Comic Vertex profile
- Watch Vertex profile

Communities:

- Dale's Card Shop Community
- Dale's Comic Shop Community
- Dale's Watch Collector Community

Vertex Pro lets the organization manage all of those from one place.

## Engineering Model

Existing Core concepts:

- `organizations`
- `organization_memberships`
- `products`
- `organization_product_profiles`

The implemented community layer extends these with product-scoped Core tables:

- `communities`
- `community_channels`
- `community_memberships`
- `community_messages`
- `community_message_references`
- `moderation_reports`
- `moderation_actions`

Organization-owned communities can now be represented by `communities` rows
with both `organization_id` and `product_id`. Vertex Pro should eventually
manage those records across products without owning a separate community
system.

## Product Scope

The important field is `product_id`. It keeps community interaction scoped to
the correct product lens.

Vertex Pro queries by `organization_id` across products. Product surfaces query
by `product_id`.

Vertex Pro can show:

- all Card Vertex communities managed by this organization
- all Comic Vertex communities managed by this organization
- all Watch Vertex communities managed by this organization
- shared moderation queue
- staff permissions
- cross-product community analytics

The current pass provides only the backend records and authorization
foundation. Vertex Pro UI, cross-product dashboards, notification workflows,
realtime presence, and advanced moderation automation are still future work.

Card Vertex should only show communities where `product_id = Card Vertex`.
Comic Vertex should only show communities where `product_id = Comic Vertex`.

A user inside Card Vertex should not see comic or watch channels unless they
are also intentionally in those products.

## Permissions

Organization permissions:

- owner
- admin
- staff
- inventory_manager
- community_moderator
- viewer

Community permissions:

- post
- reply
- moderate
- pin
- delete
- ban
- create_channel
- start_live_room
- share_inventory_reference
- manage_trade_posts

Permissions should eventually support:

- `organization_id`
- `product_id`
- `community_id`
- `channel_id`
- `role`
- `permission`

## Final Rule

Satera stores the community system. Products render product-specific community
experiences. Vertex Pro manages organization-owned communities across products.
