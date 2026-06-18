# Shared Packages

`packages/` contains shared boundaries for current and future product apps.

Current package:

- `packages/satera-core/`: the first shared Core package boundary. It currently
  re-exports the active `lib/core` service functions, query helpers, RPC
  wrappers, and types without moving their implementation.

Future candidates include:

- `packages/ui/`: shared primitives and design tokens.
- `packages/config/`: shared TypeScript, ESLint, Tailwind, and related tooling
  configuration.

The existing `lib/core` tree remains the active implementation and
compatibility surface. Source logic may move into `packages/satera-core/src`
gradually in later passes while existing imports continue to work.
