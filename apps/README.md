# Future Product Apps

`apps/` is reserved for future independently deployable product surfaces.
No product app roots have been created yet.

Future candidates include:

- `apps/card-vertex/`: Card Vertex, eventually deployed to `cardvertex.com`.
- `apps/satera/`: a possible Satera platform surface at `satera.app` for
  account/billing, platform/admin, internal tooling, Satera Portfolio, or other
  cross-product surfaces.
- `apps/vertex-pro/`: a future dealer/operator app.
- `apps/satera-portfolio/`: a future cross-product portfolio app if it is
  separate from `apps/satera/`.

Satera should not be treated as a generic marketplace or generic dashboard MVP.
Card Vertex remains the first standalone user-facing product experience.

Product apps are isolated user experiences over shared Satera Core. They should
consume Satera Core service functions and RPC wrappers, including product-lens
queries for scoped reads. Product apps must not own separate Supabase
databases, must not create a separate Card Vertex Supabase project, and must
not directly mutate Satera Core tables.

Satera owns the truth. Products render scoped experiences.
