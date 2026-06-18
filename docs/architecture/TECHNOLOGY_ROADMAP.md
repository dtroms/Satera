# Technology Roadmap

This roadmap is planning documentation. It does not authorize current
implementation of community media, LiveKit, uploaded video, automated
moderation, routes, migrations, or additional packages.

## Core Transaction Workflows

Lot Purchase RPC is complete. `create_lot_purchase_transaction` is the strict
Core write path for buying multiple inventory items in one acquisition. It
records the total lot basis pool, supports manual and equal allocation, freezes
allocated basis per item, writes lineage and audit records, and does not infer
market value from basis.

Sale Transaction RPC is complete. `create_sale_transaction` is the strict Core
write path for purchase -> own -> sell -> realize profit/loss. It freezes basis
at sale time, records net proceeds and realized profit/loss, marks inventory
sold, and does not rewrite `true_basis` or update current value.

Future lot purchase work may add estimated-value proportional allocation,
comp-based allocation, user-defined allocation templates, and receipt/import
assistance. Marketplace integrations, receipt parsing, OCR, and AI allocation
are not implemented in the current Core RPC.

## Evaluation / Certification

Satera Evaluation / Certification Lifecycle is now Core infrastructure. It is
product-neutral and can represent grading, authentication, appraisal,
certification, condition review, restoration review, service records, and
provenance review. Card Vertex grading, Watch Vertex service/appraisal, Comic
Vertex grading/restoration, Coin Vertex certification, and Memorabilia
authentication should be product workflows powered by this Core lifecycle.

Evaluation results do not automatically mutate `true_basis` or market value.
Evaluation costs may increase `true_basis` only through explicit audited basis
increase, and `true_basis = null` blocks that increase for now. Current value is
not updated by result recording or basis increase.

Future evaluation work may include provider integrations, submission package
generation, label/cert image uploads, automated notifications, and
product-specific UI. Those workflows are not implemented in this Core pass.

## Product App Boundary

Card Vertex should eventually live at `cardvertex.com` as its own standalone
product surface. Satera may eventually live separately at `satera.app` for
account/billing, platform/admin, internal tooling, Satera Portfolio, or other
cross-product surfaces. Satera is not the generic marketplace/dashboard MVP.

The Product Lens Framework is hardened before that split. Future app roots
should consume Satera Core through product-lens services and RPC-backed
mutation workflows. Card Vertex, Comic Vertex, Watch Vertex, Game Vertex,
Satera Portfolio, and Vertex Pro should feel isolated to users while sharing
the same Core truth layer.

`packages/satera-core` now exists as the first package boundary and re-exports
the active `lib/core` implementation. Existing imports remain compatible and
runtime behavior is unchanged. The current root `app/` and `lib/core` structure
remains active. Gradual source migration and full app-root creation are later
milestones.

That future split is:

- separate app root: yes, later
- separate domain: yes, later
- separate deployment: yes, later
- separate database: no
- separate Supabase project for Card Vertex: no

Satera owns the database, auth, permissions, inventory truth, transactions,
basis, lineage, public object references, communities, moderation,
notifications, audit, and entitlements. Card Vertex owns the card-specific
product experience, UI, workflows, terminology, layout, and product behavior.

Card Vertex should not directly mutate Satera Core tables. It should call
Satera Core services/RPCs, and product UI should not contain Satera financial
truth logic. The service/API boundary should be preserved so Card Vertex can
become a separate app root without rewriting Core logic.

Product entitlement does not override inventory privacy. Public object
references remain the safe sharing bridge from private inventory into product,
community, listing, and showcase surfaces.

The future monorepo structure may become:

```text
Satera/
├── apps/
│   ├── card-vertex/        deployed to cardvertex.com
│   ├── satera/             platform/account/admin/portfolio surface
│   ├── vertex-pro/         future dealer/operator app
│   └── satera-portfolio/   future portfolio app if separate from apps/satera
├── packages/
│   ├── satera-core/        current shared service/RPC/type boundary
│   ├── ui/                 shared primitives
│   └── config/             shared config
└── supabase/
    ├── migrations/
    └── tests/
```

Future Vercel setup may use multiple Vercel projects pointing at app roots in
this repo, but that configuration is a later milestone.

The staged roadmap is:

1. Create minimal `apps/card-vertex` root.
2. Create minimal `apps/satera` root only after deciding its exact role.
3. Configure Vercel projects and domains later.
4. Comp/Value Workflow write path.
5. Card Vertex product shell.

Future extraction should not move everything in one pass. Extract Satera Core
services first, keep compatibility exports from `lib/core`, keep Supabase
migrations/tests at the repo root, keep database truth centralized, keep
product-specific logic out of Satera Core, keep Satera financial truth logic
out of product UI, route product app mutations through services/RPCs, and use
product-lens queries rather than unscoped inventory queries.

## Community Media Rule

```text
Satera authorizes.
LiveKit transports.
Products render.
```

LiveKit should be headless, invisible infrastructure. It should be used for:

- voice rooms
- small group video
- Discord-style screen share
- live trade rooms
- shop/community rooms

Product UI should remain branded. Card Vertex should render the call and
screenshare UI, but it should not own the LiveKit handshake.

Uploaded videos are different from live rooms. Future uploaded video playback
should use Mux or Cloudflare Stream.

Satera stores:

- media metadata
- provider asset IDs
- playback IDs
- permissions
- moderation state
- audit trail

The provider handles:

- upload
- encoding/transcoding
- adaptive playback
- thumbnails/previews
- delivery

## Moderation

Moderation belongs in Satera Core. External tools provide moderation signals
only.

Satera owns:

- moderation state
- enforcement
- decisions
- appeals
- audit trail

Moderatable content should include:

- posts
- comments
- messages
- images
- uploaded videos
- screen-share sessions
- listings
- trade posts
- profiles
- shop/community pages

Suggested moderation actions:

- allow
- hide
- remove
- quarantine
- mark_sensitive
- mute_user
- restrict_user
- ban_from_channel
- ban_from_community
- platform_suspend
- escalate_to_admin

Satera Moderation Foundation now includes durable user restrictions, internal
moderation notes, appeal records, and audit-backed RPC workflows. Product-facing
moderation UI comes later. Automated moderation and AI moderation remain future
signal-source integrations only; Satera Core owns final state and decisions.

## Notifications

Satera Notification Foundation is the durable Core notification truth layer.
It stores notification events, recipient notification state, safe metadata,
product/entity context, audit trail, and future delivery-attempt records.

Products render notification experiences later. External delivery providers
such as Resend, push, SMS, webhooks, realtime transports, and background jobs
remain future infrastructure only and are not implemented by the foundation.
Notification payloads must use safe metadata only and must not expose private
inventory fields.

## Community Phase Guidance

Community Phase 1 should include:

- Satera Community Core concepts
- product-scoped communities
- channels
- memberships
- roles
- permissions
- messages/posts
- object references
- moderation foundation
- audit trail

Community Phase 1 should not include:

- LiveKit implementation
- Discord-style screen share
- uploaded video playback
- advanced automated moderation
- marketplace payments
- global discovery feed
- notification UI or delivery providers
