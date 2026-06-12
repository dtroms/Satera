import Link from "next/link";
import {
  InternalPageHeader,
  InternalTable,
  OwnerContextBadge,
  ShortId,
} from "@/components/internal";
import { requireInternalAccess } from "@/lib/core/internal/access";
import { formatDateTime } from "@/lib/core/internal/format";
import { getInternalTransactions } from "@/lib/core/internal/queries";

export const dynamic = "force-dynamic";

export default async function InternalTransactionsPage() {
  await requireInternalAccess();
  const transactions = await getInternalTransactions();

  return (
    <main className="mx-auto max-w-7xl px-6 py-10">
      <InternalPageHeader
        title="Transactions"
        description="Read-only Core transaction records. Transactions drive state and explain ownership, basis, and lineage changes."
        backHref="/internal"
        backLabel="Internal home"
      />

      <section className="mt-8">
        <InternalTable
          rows={transactions}
          emptyMessage="No transaction records are visible to this internal session."
          columns={[
            {
              key: "id",
              header: "Transaction",
              render: (transaction) => (
                <Link
                  href={`/internal/transactions/${transaction.id}`}
                  className="underline-offset-4 hover:underline"
                >
                  <ShortId id={transaction.id} />
                </Link>
              ),
            },
            {
              key: "type",
              header: "Type",
              render: (transaction) => transaction.transaction_type,
            },
            {
              key: "owner",
              header: "Owner",
              render: (transaction) => <OwnerContextBadge record={transaction} />,
            },
            {
              key: "date",
              header: "Date",
              render: (transaction) =>
                formatDateTime(transaction.transaction_date),
            },
            {
              key: "source",
              header: "Source",
              render: (transaction) => transaction.source ?? "-",
            },
            {
              key: "counterparty",
              header: "Counterparty",
              render: (transaction) => transaction.counterparty ?? "-",
            },
            {
              key: "created_by",
              header: "Created By",
              render: (transaction) => <ShortId id={transaction.created_by} />,
            },
            {
              key: "created",
              header: "Created",
              render: (transaction) => formatDateTime(transaction.created_at),
            },
          ]}
        />
      </section>
    </main>
  );
}
