import {
  EmptyState,
  InternalPageHeader,
  InternalTable,
  ShortId,
} from "@/components/internal";
import { requireInternalAccess } from "@/lib/core/internal/access";
import {
  formatBasis,
  formatDateTime,
} from "@/lib/core/internal/format";
import {
  getInternalBasisLineageEdges,
  type InternalRecord,
} from "@/lib/core/internal/queries";

export const dynamic = "force-dynamic";

export default async function InternalLineagePage() {
  await requireInternalAccess();
  let lineageEdges: InternalRecord[] = [];
  let errorMessage: string | null = null;

  try {
    lineageEdges = await getInternalBasisLineageEdges();
  } catch (error) {
    errorMessage =
      error instanceof Error
        ? `Basis lineage could not be loaded: ${error.message}`
        : "Basis lineage could not be loaded.";
  }

  return (
    <main className="mx-auto max-w-7xl px-6 py-10">
      <InternalPageHeader
        title="Basis Lineage"
        description="Read-only basis lineage edges. Trades and allocations must remain explainable without mutating historical truth."
        backHref="/internal"
        backLabel="Internal home"
      />

      <section className="mt-8">
        {errorMessage ? (
          <EmptyState message={errorMessage} />
        ) : (
          <InternalTable
            rows={lineageEdges}
            emptyMessage="No basis lineage edges are visible to this internal session."
            columns={[
              {
                key: "transaction",
                header: "Transaction",
                render: (row) => <ShortId id={row.transaction_id} />,
              },
              {
                key: "source",
                header: "Source Item",
                render: (row) => <ShortId id={row.source_inventory_item_id} />,
              },
              {
                key: "target",
                header: "Target Item",
                render: (row) => <ShortId id={row.target_inventory_item_id} />,
              },
              {
                key: "source_basis",
                header: "Source Basis",
                render: (row) => formatBasis(row.source_basis_amount),
              },
              {
                key: "cash_paid",
                header: "Cash Paid",
                render: (row) => formatBasis(row.cash_paid_amount),
              },
              {
                key: "cash_received",
                header: "Cash Received",
                render: (row) => formatBasis(row.cash_received_amount),
              },
              {
                key: "fees",
                header: "Fees",
                render: (row) => formatBasis(row.fees_amount),
              },
              {
                key: "allocated",
                header: "Allocated Basis",
                render: (row) => formatBasis(row.allocated_basis_amount),
              },
              {
                key: "method",
                header: "Method",
                render: (row) => row.allocation_method,
              },
              {
                key: "created",
                header: "Created",
                render: (row) => formatDateTime(row.created_at),
              },
            ]}
          />
        )}
      </section>
    </main>
  );
}
