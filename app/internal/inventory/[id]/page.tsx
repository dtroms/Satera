import { notFound } from "next/navigation";
import {
  EmptyState,
  InternalPageHeader,
  InternalTable,
  JsonBlock,
  KeyValueGrid,
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
  getInternalAuditEventsForEntity,
  getInternalBasisEventsForItem,
  getInternalBasisLineageForItem,
  getInternalInventoryItemById,
  getInternalOwnershipEventsForItem,
  getInternalTransactionLinesForItem,
  type InternalRecord,
} from "@/lib/core/internal/queries";

export const dynamic = "force-dynamic";

type PageProps = {
  params: Promise<{ id: string }>;
};

function Section({
  title,
  children,
}: {
  title: string;
  children: React.ReactNode;
}) {
  return (
    <section className="mt-8">
      <h2 className="mb-3 text-lg font-semibold text-neutral-950">{title}</h2>
      {children}
    </section>
  );
}

function relationLabel(record: InternalRecord, relation: string, idKey: string) {
  const related = record[relation] as InternalRecord | null | undefined;
  return related?.name ?? related?.slug ?? related?.variant_key ?? record[idKey] ?? "-";
}

export default async function InternalInventoryDetailPage({
  params,
}: PageProps) {
  await requireInternalAccess();
  const { id } = await params;

  const [
    item,
    ownershipEvents,
    basisEvents,
    basisLineage,
    transactionLines,
    auditEvents,
  ] = await Promise.all([
    getInternalInventoryItemById(id),
    getInternalOwnershipEventsForItem(id),
    getInternalBasisEventsForItem(id),
    getInternalBasisLineageForItem(id),
    getInternalTransactionLinesForItem(id),
    getInternalAuditEventsForEntity("inventory_items", id),
  ]);

  if (!item) {
    notFound();
  }

  return (
    <main className="mx-auto max-w-7xl px-6 py-10">
      <InternalPageHeader
        title="Inventory Detail"
        description="Read-only inspection of one Core inventory item and its related truth records."
        backHref="/internal/inventory"
        backLabel="Inventory"
      />

      <Section title="Item Summary">
        <KeyValueGrid
          items={[
            { label: "Inventory ID", value: <ShortId id={item.id} /> },
            { label: "Owner", value: <OwnerContextBadge record={item} /> },
            {
              label: "Category",
              value: relationLabel(item, "category", "category_id"),
            },
            {
              label: "Asset Variant",
              value: relationLabel(item, "asset_variant", "asset_variant_id"),
            },
            { label: "Condition", value: item.condition_type },
            { label: "Status", value: item.status },
            { label: "Availability", value: item.availability },
            { label: "Intent", value: item.intent },
            { label: "True Basis", value: formatBasis(item.true_basis) },
            {
              label: "Current Value Snapshot",
              value: formatCurrentValue(
                item.current_value_snapshot?.market_value,
              ),
            },
            { label: "Notes", value: item.notes ?? "-" },
            { label: "Created", value: formatDateTime(item.created_at) },
            { label: "Updated", value: formatDateTime(item.updated_at) },
          ]}
        />
      </Section>

      <Section title="Ownership Timeline">
        <InternalTable
          rows={ownershipEvents}
          emptyMessage="No ownership events found for this item."
          columns={[
            { key: "event", header: "Event", render: (row) => row.event_type },
            { key: "date", header: "Date", render: (row) => formatDateTime(row.event_date) },
            { key: "previous", header: "Previous", render: (row) => row.previous_status ?? "-" },
            { key: "new", header: "New", render: (row) => row.new_status ?? "-" },
            { key: "transaction", header: "Transaction", render: (row) => <ShortId id={row.transaction_id} /> },
            { key: "created", header: "Created", render: (row) => formatDateTime(row.created_at) },
          ]}
        />
      </Section>

      <Section title="Basis Events">
        <InternalTable
          rows={basisEvents}
          emptyMessage="No basis events found for this item."
          columns={[
            { key: "type", header: "Type", render: (row) => row.basis_event_type },
            { key: "amount", header: "Amount", render: (row) => formatBasis(row.amount) },
            { key: "previous", header: "Previous Basis", render: (row) => formatBasis(row.previous_basis) },
            { key: "new", header: "New Basis", render: (row) => formatBasis(row.new_basis) },
            { key: "method", header: "Method", render: (row) => row.calculation_method },
            { key: "transaction", header: "Transaction", render: (row) => <ShortId id={row.transaction_id} /> },
          ]}
        />
      </Section>

      <Section title="Basis Lineage">
        <InternalTable
          rows={basisLineage}
          emptyMessage="No basis lineage edges found for this item."
          columns={[
            { key: "source", header: "Source Item", render: (row) => <ShortId id={row.source_inventory_item_id} /> },
            { key: "target", header: "Target Item", render: (row) => <ShortId id={row.target_inventory_item_id} /> },
            { key: "source_basis", header: "Source Basis", render: (row) => formatBasis(row.source_basis_amount) },
            { key: "allocated", header: "Allocated", render: (row) => formatBasis(row.allocated_basis_amount) },
            { key: "method", header: "Method", render: (row) => row.allocation_method },
            { key: "transaction", header: "Transaction", render: (row) => <ShortId id={row.transaction_id} /> },
          ]}
        />
      </Section>

      <Section title="Transaction Lines">
        <InternalTable
          rows={transactionLines}
          emptyMessage="No transaction lines found for this item."
          columns={[
            { key: "transaction", header: "Transaction", render: (row) => <ShortId id={row.transaction_id} /> },
            { key: "line", header: "Line Type", render: (row) => row.line_type },
            { key: "direction", header: "Direction", render: (row) => row.direction },
            { key: "amount", header: "Amount", render: (row) => formatCurrentValue(row.amount) },
            { key: "trade", header: "Trade Value", render: (row) => formatCurrentValue(row.trade_value_at_time) },
            { key: "basis", header: "Basis At Time", render: (row) => formatBasis(row.basis_at_time) },
          ]}
        />
      </Section>

      <Section title="Audit Events">
        {auditEvents.length > 0 ? <JsonBlock value={auditEvents} /> : <EmptyState message="No audit events found for this item." />}
      </Section>
    </main>
  );
}
