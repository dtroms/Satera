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
  getInternalBasisEventsForTransaction,
  getInternalBasisLineageForTransaction,
  getInternalOwnershipEventsForTransaction,
  getInternalTransactionById,
  getInternalTransactionLinesForTransaction,
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

export default async function InternalTransactionDetailPage({
  params,
}: PageProps) {
  await requireInternalAccess();
  const { id } = await params;

  const [
    transaction,
    transactionLines,
    ownershipEvents,
    basisEvents,
    basisLineage,
    auditEvents,
  ] = await Promise.all([
    getInternalTransactionById(id),
    getInternalTransactionLinesForTransaction(id),
    getInternalOwnershipEventsForTransaction(id),
    getInternalBasisEventsForTransaction(id),
    getInternalBasisLineageForTransaction(id),
    getInternalAuditEventsForEntity("transactions", id),
  ]);

  if (!transaction) {
    notFound();
  }

  return (
    <main className="mx-auto max-w-7xl px-6 py-10">
      <InternalPageHeader
        title="Transaction Detail"
        description="Read-only inspection of one Core transaction and the records it explains."
        backHref="/internal/transactions"
        backLabel="Transactions"
      />

      <Section title="Transaction Summary">
        <KeyValueGrid
          items={[
            { label: "Transaction ID", value: <ShortId id={transaction.id} /> },
            { label: "Type", value: transaction.transaction_type },
            { label: "Owner", value: <OwnerContextBadge record={transaction} /> },
            {
              label: "Transaction Date",
              value: formatDateTime(transaction.transaction_date),
            },
            { label: "Source", value: transaction.source ?? "-" },
            { label: "Counterparty", value: transaction.counterparty ?? "-" },
            { label: "Created By", value: <ShortId id={transaction.created_by} /> },
            { label: "Notes", value: transaction.notes ?? "-" },
            { label: "Created", value: formatDateTime(transaction.created_at) },
          ]}
        />
      </Section>

      <Section title="Transaction Lines">
        <InternalTable
          rows={transactionLines}
          emptyMessage="No transaction lines found for this transaction."
          columns={[
            { key: "id", header: "Line", render: (row) => <ShortId id={row.id} /> },
            { key: "item", header: "Inventory Item", render: (row) => <ShortId id={row.inventory_item_id} /> },
            { key: "type", header: "Type", render: (row) => row.line_type },
            { key: "direction", header: "Direction", render: (row) => row.direction },
            { key: "amount", header: "Amount", render: (row) => formatCurrentValue(row.amount) },
            { key: "market", header: "Market Value", render: (row) => formatCurrentValue(row.market_value_at_time) },
            { key: "trade", header: "Trade Value", render: (row) => formatCurrentValue(row.trade_value_at_time) },
            { key: "basis", header: "Basis At Time", render: (row) => formatBasis(row.basis_at_time) },
            { key: "allocated", header: "Basis Allocated", render: (row) => formatBasis(row.basis_allocated) },
          ]}
        />
      </Section>

      <Section title="Ownership Events">
        <InternalTable
          rows={ownershipEvents}
          emptyMessage="No ownership events found for this transaction."
          columns={[
            { key: "event", header: "Event", render: (row) => row.event_type },
            { key: "item", header: "Inventory Item", render: (row) => <ShortId id={row.inventory_item_id} /> },
            { key: "date", header: "Date", render: (row) => formatDateTime(row.event_date) },
            { key: "previous", header: "Previous", render: (row) => row.previous_status ?? "-" },
            { key: "new", header: "New", render: (row) => row.new_status ?? "-" },
          ]}
        />
      </Section>

      <Section title="Basis Events">
        <InternalTable
          rows={basisEvents}
          emptyMessage="No basis events found for this transaction."
          columns={[
            { key: "type", header: "Type", render: (row) => row.basis_event_type },
            { key: "item", header: "Inventory Item", render: (row) => <ShortId id={row.inventory_item_id} /> },
            { key: "amount", header: "Amount", render: (row) => formatBasis(row.amount) },
            { key: "previous", header: "Previous Basis", render: (row) => formatBasis(row.previous_basis) },
            { key: "new", header: "New Basis", render: (row) => formatBasis(row.new_basis) },
            { key: "method", header: "Method", render: (row) => row.calculation_method },
          ]}
        />
      </Section>

      <Section title="Basis Lineage Edges">
        <InternalTable
          rows={basisLineage}
          emptyMessage="No basis lineage edges found for this transaction."
          columns={[
            { key: "source", header: "Source Item", render: (row) => <ShortId id={row.source_inventory_item_id} /> },
            { key: "target", header: "Target Item", render: (row) => <ShortId id={row.target_inventory_item_id} /> },
            { key: "source_basis", header: "Source Basis", render: (row) => formatBasis(row.source_basis_amount) },
            { key: "cash_paid", header: "Cash Paid", render: (row) => formatCurrentValue(row.cash_paid_amount) },
            { key: "cash_received", header: "Cash Received", render: (row) => formatCurrentValue(row.cash_received_amount) },
            { key: "fees", header: "Fees", render: (row) => formatCurrentValue(row.fees_amount) },
            { key: "allocated", header: "Allocated", render: (row) => formatBasis(row.allocated_basis_amount) },
            { key: "method", header: "Method", render: (row) => row.allocation_method },
          ]}
        />
      </Section>

      <Section title="Audit Events">
        {auditEvents.length > 0 ? <JsonBlock value={auditEvents} /> : <EmptyState message="No audit events found for this transaction." />}
      </Section>
    </main>
  );
}
