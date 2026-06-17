import Link from "next/link";
import {
  InternalPageHeader,
  InternalTable,
  ShortId,
} from "@/components/internal";
import { requireInternalAccess } from "@/lib/core/internal/access";
import {
  formatCurrentValue,
  formatDateTime,
} from "@/lib/core/internal/format";
import { getInternalEvaluationCases } from "@/lib/core/internal/queries";

export const dynamic = "force-dynamic";

function nullableShortId(id: string | null | undefined) {
  return id ? <ShortId id={id} /> : "-";
}

export default async function InternalEvaluationsPage() {
  await requireInternalAccess();
  const cases = await getInternalEvaluationCases();

  return (
    <main className="mx-auto max-w-7xl px-6 py-10">
      <InternalPageHeader
        title="Evaluations"
        description="Read-only Satera Core evaluation and certification lifecycle cases."
        backHref="/internal"
        backLabel="Internal home"
      />

      <section className="mt-8">
        <InternalTable
          rows={cases}
          emptyMessage="No evaluation cases are visible to this internal session."
          columns={[
            {
              key: "id",
              header: "Case",
              render: (evaluationCase) => (
                <Link
                  href={`/internal/evaluations/${evaluationCase.id}`}
                  className="font-medium text-neutral-950 underline-offset-2 hover:underline"
                >
                  <ShortId id={evaluationCase.id} />
                </Link>
              ),
            },
            {
              key: "workspace",
              header: "Workspace",
              render: (evaluationCase) => <ShortId id={evaluationCase.workspace_id} />,
            },
            {
              key: "product",
              header: "Product",
              render: (evaluationCase) => nullableShortId(evaluationCase.product_id),
            },
            {
              key: "case_type",
              header: "Type",
              render: (evaluationCase) => evaluationCase.case_type,
            },
            {
              key: "provider",
              header: "Provider",
              render: (evaluationCase) => evaluationCase.provider_name ?? "-",
            },
            {
              key: "provider_reference",
              header: "Reference",
              render: (evaluationCase) => evaluationCase.provider_reference ?? "-",
            },
            {
              key: "status",
              header: "Status",
              render: (evaluationCase) => evaluationCase.status,
            },
            {
              key: "total_case_cost",
              header: "Case Cost",
              render: (evaluationCase) => formatCurrentValue(evaluationCase.total_case_cost),
            },
            {
              key: "opened_at",
              header: "Opened",
              render: (evaluationCase) => formatDateTime(evaluationCase.opened_at),
            },
            {
              key: "submitted_at",
              header: "Submitted",
              render: (evaluationCase) => formatDateTime(evaluationCase.submitted_at),
            },
            {
              key: "completed_at",
              header: "Completed",
              render: (evaluationCase) => formatDateTime(evaluationCase.completed_at),
            },
            {
              key: "returned_at",
              header: "Returned",
              render: (evaluationCase) => formatDateTime(evaluationCase.returned_at),
            },
          ]}
        />
      </section>
    </main>
  );
}
