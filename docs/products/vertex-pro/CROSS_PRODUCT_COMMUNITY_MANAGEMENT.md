# Vertex Pro Cross-Product Community Management

This document is product and architecture planning only. It does not describe
implemented schema, routes, migrations, UI, messaging, realtime, or moderation
features.

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

Existing Core concepts already started:

- `organizations`
- `organization_memberships`
- `products`
- `organization_product_profiles`

The future community layer extends these with product-scoped community
concepts.

Possible future `communities` fields:

- `id`
- `organization_id` nullable
- `product_id`
- `name`
- `slug`
- `community_type`
- `visibility`
- `created_by`
- `created_at`

Possible future `community_channels` fields:

- `id`
- `community_id`
- `product_id`
- `name`
- `channel_type`
- `sort_order`
- `created_at`

Possible future `community_memberships` fields:

- `id`
- `community_id`
- `user_id`
- `role`
- `status`
- `joined_at`

Possible future `community_roles` fields:

- `id`
- `community_id`
- `name`
- `permissions`

Possible future `messages` fields:

- `id`
- `community_id`
- `channel_id`
- `product_id`
- `author_user_id`
- `body`
- `created_at`

Possible future `message_object_references` fields:

- `id`
- `message_id`
- `object_type`
- `public_reference_id`
- `inventory_item_id` nullable but never exposed directly
- `product_id`

These are future concepts only, not implemented schema.

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
