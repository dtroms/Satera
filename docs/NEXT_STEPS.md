# Next Steps

## Current Priority

1. Satera Community Core MVP Pass 2: TypeScript service layer + Internal Inspector.
2. Satera Moderation Foundation hardening.
3. Notification Foundation.
4. Sale Transaction RPC.
5. Lot Purchase RPC.
6. Grading Lifecycle.
7. Card Vertex product shell later.

Satera Community Core MVP Pass 1 now exists as platform infrastructure.
Community messages can attach safe public object references instead of private
inventory rows. Product-specific community UI, including Card Vertex community
surfaces, comes later.

## Future Product Work

1. Build Satera Portfolio after the Core truth layer and product lens framework
   are stable.
2. Build Card Vertex from product documentation, starting with manual comp UX
   only after Core write boundaries are approved.
3. Build Vertex Pro after organization/product profile workflows are ready for
   operator-facing surfaces.

## Future Card Vertex Workflow

1. Inventory workspace shell.
2. Saved filters.
3. Search within current filter.
4. Table controls.
5. Column customization.
6. Density modes.
7. Bulk mode.
8. Card Context Drawer.
9. Community Dock.
10. Drag/drop public card references.
11. Comp display and discussion.
12. Trade/sale/wanted posts.

## Future Satera Community Core

1. TypeScript service layer for community RPCs.
2. Read-only Internal Inspector coverage for communities, channels,
   memberships, messages, references, reports, actions, and audit trail.
3. Moderation Foundation hardening.
4. Notification hooks.
5. Future post/listing/trade-specific workflows.

Public references follow the reusable Core pattern:

```text
private inventory item -> safe public object reference -> product/community/listing attachment
```

They must never expose true_basis, purchase price, profit, location, private
notes, private tags, ownership history, or private transaction history.

## Future Vertex Pro

1. Organization-owned cross-product community management.
2. Multi-product moderation queue.
3. Staff permissions by product, community, and channel.
4. Cross-product community analytics.
5. Operator UI for organization-owned communities across products.

## Future Media

1. LiveKit for branded voice and screen-share rooms.
2. Mux or Cloudflare Stream for uploaded video playback.
3. External moderation providers only as signal sources.
