import Link from "next/link";
import { InternalPageHeader } from "@/components/internal";
import { requireInternalAccess } from "@/lib/core/internal/access";

export const dynamic = "force-dynamic";

export default async function InternalHomePage() {
  await requireInternalAccess();

  return (
    <main className="mx-auto max-w-6xl px-6 py-10">
      <InternalPageHeader
        title="Satera Core Internal Inspector"
        description="Read-only development/admin surface. Not customer-facing."
      />

      <div className="mt-8 grid gap-4 sm:grid-cols-2">
        <Link
          href="/internal/inventory"
          className="border border-neutral-300 bg-white p-5 hover:bg-neutral-50"
        >
          <h2 className="text-lg font-semibold">Inventory</h2>
          <p className="mt-2 text-sm leading-6 text-neutral-600">
            Inspect private inventory truth records, ownership context, basis,
            value snapshots, and item-linked history.
          </p>
        </Link>
        <Link
          href="/internal/transactions"
          className="border border-neutral-300 bg-white p-5 hover:bg-neutral-50"
        >
          <h2 className="text-lg font-semibold">Transactions</h2>
          <p className="mt-2 text-sm leading-6 text-neutral-600">
            Inspect transaction records, lines, ownership events, basis events,
            lineage edges, and audit events.
          </p>
        </Link>
      </div>
    </main>
  );
}
