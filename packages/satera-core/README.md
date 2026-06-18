# Satera Core Package Boundary

`packages/satera-core` is the first shared package boundary for Satera Core. It
will contain shared service functions, types, query helpers, and RPC wrappers
that future product apps can consume.

This incremental pass re-exports the active implementation from `lib/core`.
No service logic has moved, and existing `lib/core` imports remain the current
compatibility surface. Future passes may migrate implementation files into
`packages/satera-core/src` gradually while preserving those compatibility
exports.

Satera Core does not own product UI. Product apps should eventually import
Core services through this package boundary and call approved services and RPC
wrappers instead of directly mutating Satera Core tables. Card Vertex at
`cardvertex.com` should follow this boundary when its app root is created.

Supabase schema, migrations, seed data, SQL tests, and database configuration
remain under the repository-root `supabase/` directory; they are not owned by
this package.
