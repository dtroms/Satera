# Next Steps

## Current Priority

1. Public Object Reference System.
2. Satera Community Core MVP.
3. Satera Moderation Foundation.
4. Notification Foundation.
5. Sale Transaction RPC.
6. Lot Purchase RPC.
7. Grading Lifecycle.

Communities are part of the MVP direction, but Satera Core still comes first.
Community messages, trade posts, listings, showcases, and Card Vertex drag/drop
sharing should attach safe public object references instead of private inventory
rows.

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

1. Product-scoped community tables.
2. Channel, membership, role, and permission model.
3. Attach safe public object references to messages, posts, listings, and
   trades.
4. Moderation foundation.
5. Audit trail.

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

## Future Media

1. LiveKit for branded voice and screen-share rooms.
2. Mux or Cloudflare Stream for uploaded video playback.
3. External moderation providers only as signal sources.
