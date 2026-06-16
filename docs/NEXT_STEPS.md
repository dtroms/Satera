# Next Steps

## Current Priority

1. Satera Moderation Foundation hardening.
2. Notification Foundation.
3. Sale Transaction RPC.
4. Lot Purchase RPC.
5. Evaluation / Certification Lifecycle.
6. Product Lens Framework hardening.
7. Card Vertex product shell later.

Satera Community Core MVP Pass 2 now exists as platform infrastructure.
Community messages can attach safe public object references instead of private
inventory rows, TypeScript mutations route through RPCs only, and the Internal
Inspector can inspect community records through read-only views. Product-specific
community UI, including Card Vertex community surfaces and the Community Dock,
comes later.

Satera Core should model evaluation/certification as a product-neutral
lifecycle. Products can translate that backbone into niche-specific workflows:
Card Vertex grading submissions and cert numbers, Comic Vertex restoration
review and page quality, Watch Vertex authentication and service records, Coin
Vertex holder and mint/state details, and Memorabilia certificates of
authenticity or provenance review.

Evaluation cost may increase `true_basis`. Evaluation result does not
automatically increase `true_basis`. A grading fee, authentication fee,
appraisal fee, or certification fee may be capitalized into basis when
appropriate, but a PSA 10, authenticated watch, certified comic, or appraised
item affects market value separately from basis unless actual costs were
incurred.

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
13. Card Vertex Grading Workflow, powered by Satera Evaluation /
    Certification Lifecycle.

## Future Satera Community Core

1. Moderation Foundation hardening.
2. Notification hooks.
3. Future post/listing/trade-specific workflows.
4. Realtime presence later.
5. LiveKit, uploaded media, and media processing later.

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
