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
- appeals later
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
