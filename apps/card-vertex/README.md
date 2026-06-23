# Card Vertex App Root Placeholder

Card Vertex will eventually be the first standalone user-facing product
experience powered by Satera Core and deployed to `cardvertex.com`.

This directory is a placeholder only. No runnable application, routes, product
UI, inventory screens, workspace, or Community Dock exists here yet. The
current Next.js application remains at the repository root.

When Card Vertex becomes a real app, it will:

- consume Satera Core through `packages/satera-core`;
- use the shared Satera Supabase backend and source of truth;
- not own a separate database or Supabase project;
- call Satera Core service functions and RPC wrappers for mutations;
- not directly mutate Satera Core tables; and
- use product-lens queries instead of unscoped inventory queries.

Creating the runnable app requires an intentional later pass for repository
workspace, package-manager, build, deployment, and domain configuration.
