import { notFound } from "next/navigation";
import {
  EmptyState,
  InternalPageHeader,
  InternalTable,
  JsonBlock,
  KeyValueGrid,
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
  getInternalEvaluationAttachments,
  getInternalEvaluationCaseById,
  getInternalEvaluationCaseItems,
  getInternalEvaluationEvents,
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

function nullableShortId(id: string | null | undefined) {
  return id ? <ShortId id={id} /> : "-";
}

export default async function InternalEvaluationDetailPage({
  params,
}: PageProps) {
  await requireInternalAccess();
  const { id } = await params;

  const [evaluationCase, items, events, attachments, auditEvents] =
    await Promise.all([
      getInternalEvaluationCaseById(id),
      getInternalEvaluationCaseItems(id),
      getInternalEvaluationEvents(id),
      getInternalEvaluationAttachments(id),
      getInternalAuditEventsForEntity("evaluation_cases", id),
    ]);

  if (!evaluationCase) {
    notFound();
  }

  return (
    <main className="mx-auto max-w-7xl px-6 py-10">
      <InternalPageHeader
        title="Evaluation Detail"
        description="Read-only inspection of one product-neutral evaluation/certification case."
        backHref="/internal/evaluations"
        backLabel="Evaluations"
      />

      <Section title="Case Metadata">
        <KeyValueGrid
          items={[
            { label: "Case ID", value: <ShortId id={evaluationCase.id} /> },
            { label: "Workspace", value: <ShortId id={evaluationCase.workspace_id} /> },
            { label: "Product", value: nullableShortId(evaluationCase.product_id) },
            { label: "Organization", value: nullableShortId(evaluationCase.organization_id) },
            { label: "Type", value: evaluationCase.case_type },
            { label: "Status", value: evaluationCase.status },
            { label: "Provider", value: evaluationCase.provider_name ?? "-" },
            {
              label: "Provider Reference",
              value: evaluationCase.provider_reference ?? "-",
            },
            { label: "Declared Value", value: formatCurrentValue(evaluationCase.total_declared_value) },
            { label: "Evaluation Cost", value: formatCurrentValue(evaluationCase.total_evaluation_cost) },
            { label: "Shipping Cost", value: formatCurrentValue(evaluationCase.total_shipping_cost) },
            { label: "Insurance Cost", value: formatCurrentValue(evaluationCase.total_insurance_cost) },
            { label: "Other Costs", value: formatCurrentValue(evaluationCase.total_other_costs) },
            { label: "Total Case Cost", value: formatCurrentValue(evaluationCase.total_case_cost) },
            { label: "Opened", value: formatDateTime(evaluationCase.opened_at) },
            { label: "Submitted", value: formatDateTime(evaluationCase.submitted_at) },
            { label: "Received", value: formatDateTime(evaluationCase.received_at) },
            { label: "Completed", value: formatDateTime(evaluationCase.completed_at) },
            { label: "Returned", value: formatDateTime(evaluationCase.returned_at) },
            { label: "Canceled", value: formatDateTime(evaluationCase.canceled_at) },
            { label: "Expected Return", value: formatDateTime(evaluationCase.expected_return_at) },
            { label: "Created By", value: <ShortId id={evaluationCase.created_by} /> },
            { label: "Notes", value: evaluationCase.notes ?? "-" },
          ]}
        />
      </Section>

      <Section title="Case Metadata JSON">
        <JsonBlock value={evaluationCase.metadata} />
      </Section>

      <Section title="Items">
        <InternalTable
          rows={items}
          emptyMessage="No items found for this evaluation case."
          columns={[
            { key: "id", header: "Item", render: (item) => <ShortId id={item.id} /> },
            {
              key: "inventory",
              header: "Inventory",
              render: (item) => <ShortId id={item.inventory_item_id} />,
            },
            { key: "status", header: "Status", render: (item) => item.item_status },
            {
              key: "declared",
              header: "Declared",
              render: (item) => formatCurrentValue(item.declared_value),
            },
            {
              key: "allocated",
              header: "Allocated Cost",
              render: (item) => formatCurrentValue(item.allocated_total_cost),
            },
            {
              key: "basis",
              header: "Basis Increase",
              render: (item) => formatBasis(item.basis_increase_amount),
            },
            {
              key: "provider_ref",
              header: "Provider Ref",
              render: (item) => item.provider_item_reference ?? "-",
            },
            {
              key: "grade",
              header: "Grade",
              render: (item) => item.result_grade ?? "-",
            },
            {
              key: "authenticity",
              header: "Authenticity",
              render: (item) => item.result_authenticity ?? "-",
            },
            {
              key: "cert",
              header: "Cert",
              render: (item) => item.result_certification_number ?? "-",
            },
          ]}
        />
      </Section>

      <Section title="Lifecycle Events">
        <InternalTable
          rows={events}
          emptyMessage="No lifecycle events found for this evaluation case."
          columns={[
            { key: "id", header: "Event", render: (event) => <ShortId id={event.id} /> },
            {
              key: "item",
              header: "Item",
              render: (event) => nullableShortId(event.evaluation_case_item_id),
            },
            { key: "type", header: "Type", render: (event) => event.event_type },
            { key: "from", header: "From", render: (event) => event.from_status ?? "-" },
            { key: "to", header: "To", render: (event) => event.to_status ?? "-" },
            {
              key: "occurred",
              header: "Occurred",
              render: (event) => formatDateTime(event.occurred_at),
            },
            { key: "notes", header: "Notes", render: (event) => event.notes ?? "-" },
          ]}
        />
      </Section>

      <Section title="Attachments">
        <InternalTable
          rows={attachments}
          emptyMessage="No attachments found for this evaluation case."
          columns={[
            { key: "id", header: "Attachment", render: (row) => <ShortId id={row.id} /> },
            { key: "type", header: "Type", render: (row) => row.attachment_type },
            { key: "title", header: "Title", render: (row) => row.title ?? "-" },
            { key: "storage", header: "Storage Path", render: (row) => row.storage_path ?? "-" },
            { key: "url", header: "External URL", render: (row) => row.external_url ?? "-" },
            {
              key: "provider_asset",
              header: "Provider Asset",
              render: (row) => row.provider_asset_id ?? "-",
            },
            { key: "created", header: "Created", render: (row) => formatDateTime(row.created_at) },
          ]}
        />
      </Section>

      <Section title="Audit Events">
        {auditEvents.length > 0 ? (
          <JsonBlock value={auditEvents} />
        ) : (
          <EmptyState message="No audit events found for this evaluation case." />
        )}
      </Section>
    </main>
  );
}
