# Technology Roadmap

This roadmap is planning documentation only. It does not authorize current
implementation of community media, LiveKit, uploaded video, automated
moderation, routes, migrations, or packages.

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
