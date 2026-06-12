import Link from "next/link";
import {
  InternalPageHeader,
  InternalTable,
  OwnerContextBadge,
  ShortId,
} from "@/components/internal";
import { requireInternalAccess } from "@/lib/core/internal/access";
import {
  formatBasis,
  formatCurrentValue,
  formatDateTime,
} from "@/lib/core/internal/format";
import {
  getInternalInventoryItems,
  type InternalRecord,
} from "@/lib/core/internal/queries";

export const dynamic = "force-dynamic";

function relatedName(record: InternalRecord, relation: string, fallback: string) {
  const related = record[relation] as InternalRecord | null | undefined;
  return related?.name ?? related?.slug ?? related?.variant_key ?? fallback;
}

export default async function InternalInventoryPage() {
  await requireInternalAccess();
  const items = await getInternalInventoryItems();

  return (
    <main className="mx-auto max-w-7xl px-6 py-10">
      <InternalPageHeader
        title="Inventory"
        description="Read-only Core inventory records. Inventory remains private by owner context; products are only lenses."
        backHref="/internal"
        backLabel="Internal home"
      />

      <section className="mt-8">
        <InternalTable
          rows={items}
          emptyMessage="No inventory records are visible to this internal session."
          columns={[
            {
              key: "id",
              header: "Item",
              render: (item) => (
                <Link
                  href={`/internal/inventory/${item.id}`}
                  className="underline-offset-4 hover:underline"
                >
                  <ShortId id={item.id} />
                </Link>
              ),
            },
            {
              key: "owner",
              header: "Owner",
              render: (item) => <OwnerContextBadge record={item} />,
            },
            {
              key: "category",
              header: "Category",
              render: (item) =>
                relatedName(item, "category", item.category_id ?? "-"),
            },
            {
              key: "asset",
              header: "Asset Variant",
              render: (item) =>
                relatedName(
                  item,
                  "asset_variant",
                  item.asset_variant_id ?? "-",
                ),
            },
            { key: "status", header: "Status", render: (item) => item.status },
            {
              key: "availability",
              header: "Availability",
              render: (item) => item.availability,
            },
            { key: "intent", header: "Intent", render: (item) => item.intent },
            {
              key: "basis",
              header: "True Basis",
              render: (item) => formatBasis(item.true_basis),
            },
            {
              key: "value",
              header: "Current Value",
              render: (item) =>
                formatCurrentValue(item.current_value_snapshot?.market_value),
            },
            {
              key: "acquired",
              header: "Acquired",
              render: (item) => formatDateTime(item.acquired_at),
            },
            {
              key: "updated",
              header: "Updated",
              render: (item) => formatDateTime(item.updated_at),
            },
          ]}
        />
      </section>
    </main>
  );
}
