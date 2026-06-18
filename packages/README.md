# Future Shared Packages

`packages/` is reserved for future shared packages.
No package extraction has happened yet.

Future candidates include:

- `packages/satera-core/`: shared service functions, RPC wrappers, and Core
  types.
- `packages/ui/`: shared primitives and design tokens.
- `packages/config/`: shared TypeScript, ESLint, Tailwind, and related tooling
  configuration.

The existing `lib/core` tree remains the active source for Satera Core service
code for now. Future extraction should be staged and should keep compatibility
exports from `lib/core` during the transition so existing imports keep working.
