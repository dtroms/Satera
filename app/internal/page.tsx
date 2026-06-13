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
        {[
          {
            href: "/internal/inventory",
            title: "Inventory",
            description:
              "Inspect private inventory truth records, ownership context, basis, value snapshots, and item-linked history.",
          },
          {
            href: "/internal/transactions",
            title: "Transactions",
            description:
              "Inspect transaction records, lines, ownership events, basis events, lineage edges, and audit events.",
          },
          {
            href: "/internal/lineage",
            title: "Lineage",
            description:
              "Inspect basis lineage edges that explain trades, allocations, cash effects, and transferred basis.",
          },
          {
            href: "/internal/audit",
            title: "Audit",
            description:
              "Inspect audit events that record protected workflow actions and related owner context.",
          },
          {
            href: "/internal/products",
            title: "Products",
            description:
              "Inspect products, categories, and asset structure to verify products remain lenses over Core.",
          },
        ].map((link) => (
          <Link
            key={link.href}
            href={link.href}
            className="border border-neutral-300 bg-white p-5 hover:bg-neutral-50"
          >
            <h2 className="text-lg font-semibold">{link.title}</h2>
            <p className="mt-2 text-sm leading-6 text-neutral-600">
              {link.description}
            </p>
          </Link>
        ))}
      </div>
    </main>
  );
}
