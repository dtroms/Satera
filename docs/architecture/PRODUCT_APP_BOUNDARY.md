# Product App Boundary

This document records the repo-boundary direction for future standalone product
surfaces. `packages/satera-core` now exists as the first package boundary, but
this pass does not create product app roots, deployments, routes, UI, database
schema, migrations, RLS, RPCs, or build-tooling changes.

## Core Principle

Satera owns the truth. Products render scoped experiences.

Satera remains the shared Core backend, source of truth, platform/company
layer, and powering infrastructure. Product apps call Satera Core services and
RPCs. Product apps do not fork the data model, do not own their own Supabase
databases, and do not directly mutate Satera Core tables.

Card Vertex is intended to become a standalone product surface at
`cardvertex.com`, but it should continue using the same Satera Core backend,
same Satera Supabase database, same auth model, same RPCs, same RLS, and same
source of truth.

Satera may later host account/billing, platform/admin, internal tooling, Satera
Portfolio, or other cross-product surfaces. Satera should not be framed as a
generic marketplace or primary user dashboard MVP. Satera Portfolio and Vertex
Pro are future product surfaces.

The intended separation is:

- separate app root: yes, later
- separate domain: yes, later
- separate deployment: yes, later
- separate database: no
- separate Supabase project for Card Vertex: no

## Future Shape

Future Vercel setup may use multiple Vercel projects that point at different
app roots in this one repository. That is a later configuration milestone, not
part of this pass.

The future repo shape may become:

```text
Satera/
├── apps/
│   ├── card-vertex/        future app deployed to cardvertex.com
│   ├── satera/             future platform/account/admin/portfolio surface
│   ├── vertex-pro/         future dealer/operator app
│   └── satera-portfolio/   future portfolio app if separate from apps/satera
├── packages/
│   ├── satera-core/        current shared service/RPC/type boundary
│   ├── ui/                 future shared design primitives
│   └── config/             future shared tooling config
└── supabase/
    ├── migrations/
    ├── tests/
    └── seed.sql
```

The current root `app/` and `lib/core` structure remains active.
`packages/satera-core` currently re-exports `lib/core`; no implementation logic
has moved, existing imports remain compatible, and runtime behavior is
unchanged. Future product apps should consume this package boundary, and future
passes may migrate implementation logic into it gradually.

## Staged Roadmap

1. Create minimal `apps/card-vertex` root.
2. Create minimal `apps/satera` root only after deciding its exact role.
3. Configure Vercel projects and domains later.
4. Comp/Value Workflow write path.
5. Card Vertex product shell.

## Extraction Guardrails

- Do not move everything in one pass.
- Extract Satera Core services first.
- Keep compatibility exports from `lib/core` during transition.
- Keep Supabase migrations and tests at the repo root.
- Keep database truth centralized.
- Keep product-specific logic out of Satera Core.
- Keep Satera financial truth logic out of product UI.
- Product apps should call service functions and RPCs.
- Product apps should not call direct table mutations.
- Product apps may use safe read queries through Satera Core services.
- Card Vertex should use product-lens queries rather than unscoped inventory
  queries.

Moving the active implementation into the package and creating app roots are
later milestones.
