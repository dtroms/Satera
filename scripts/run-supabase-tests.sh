#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATABASE_URL="${DATABASE_URL:-postgresql://postgres:postgres@127.0.0.1:54322/postgres}"

if ! command -v psql >/dev/null 2>&1; then
  echo "psql is required to run Satera Core SQL verification scripts." >&2
  echo "Install PostgreSQL client tools, then rerun: npm run db:test" >&2
  exit 127
fi

tests=(
  "supabase/tests/001_inventory_privacy.sql"
  "supabase/tests/002_product_lens_access.sql"
  "supabase/tests/003_entitlements_do_not_override_privacy.sql"
  "supabase/tests/004_basis_lineage_trade_example.sql"
  "supabase/tests/005_comp_snapshot_privacy.sql"
  "supabase/tests/006_rpc_atomic_transactions.sql"
  "supabase/tests/007_direct_write_hardening.sql"
  "supabase/tests/008_trade_transaction_lineage.sql"
  "supabase/tests/009_public_object_references.sql"
)

for test_file in "${tests[@]}"; do
  echo "==> Running ${test_file}"
  psql "${DATABASE_URL}" -v ON_ERROR_STOP=1 -f "${ROOT_DIR}/${test_file}"
done

echo "Satera Core SQL verification scripts passed."
