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
  formatDate,
  formatDateTime,
  formatEnumLabel,
  formatMoney,
} from "@/lib/core/internal/format";
import { buildCompValueSummary } from "@/lib/core/comps/calculations";
import type { CompSnapshot } from "@/lib/core/comps/types";
import {
  getInternalAuditEventsForEntity,
  getInternalBasisEventsForItem,
  getInternalBasisLineageForItem,
  getInternalCompSnapshotsForItem,
  getInternalInventoryItemById,
  getInternalOwnershipEventsForItem,
  getInternalPublicObjectReferencesForItem,
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

async function getRowsSafely<T>(
  label: string,
  loader: Promise<T[]>,
): Promise<{ rows: T[]; errorMessage: string | null }> {
  try {
    return {
      rows: await loader,
      errorMessage: null,
    };
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown error";

    return {
      rows: [],
      errorMessage: `${label} could not be loaded: ${message}`,
    };
  }
}

export default async function InternalInventoryDetailPage({
  params,
}: PageProps) {
  await requireInternalAccess();
  const { id } = await params;

  let item: InternalRecord | null;
  try {
    item = await getInternalInventoryItemById(id);
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown error";

    return (
      <main className="mx-auto max-w-7xl px-6 py-10">
        <InternalPageHeader
          title="Inventory Detail"
          description="Read-only inspection of one Core inventory item and its related truth records."
          backHref="/internal/inventory"
          backLabel="Inventory"
        />
        <section className="mt-8">
          <EmptyState message={`Inventory item could not be loaded: ${message}`} />
        </section>
      </main>
    );
  }

  if (!item) {
    notFound();
  }

  const [
    ownershipEvents,
    basisEvents,
    basisLineage,
    transactionLines,
    auditEvents,
    compEvidence,
    publicReferences,
  ] = await Promise.all([
    getRowsSafely("Ownership timeline", getInternalOwnershipEventsForItem(id)),
    getRowsSafely("Basis events", getInternalBasisEventsForItem(id)),
    getRowsSafely("Basis lineage", getInternalBasisLineageForItem(id)),
    getRowsSafely("Transaction lines", getInternalTransactionLinesForItem(id)),
    getRowsSafely(
      "Audit events",
      getInternalAuditEventsForEntity("inventory_items", id),
    ),
    getRowsSafely<CompSnapshot>(
      "Comp evidence",
      getInternalCompSnapshotsForItem(id),
    ),
    getRowsSafely(
      "Public references",
      getInternalPublicObjectReferencesForItem(id),
    ),
  ]);

  const compSnapshots = compEvidence.rows;
  const compSummary = buildCompValueSummary(compSnapshots);

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
        {ownershipEvents.errorMessage ? (
          <EmptyState message={ownershipEvents.errorMessage} />
        ) : (
          <InternalTable
            rows={ownershipEvents.rows}
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
        )}
      </Section>

      <Section title="Basis Events">
        {basisEvents.errorMessage ? (
          <EmptyState message={basisEvents.errorMessage} />
        ) : (
          <InternalTable
            rows={basisEvents.rows}
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
        )}
      </Section>

      <Section title="Basis Lineage">
        {basisLineage.errorMessage ? (
          <EmptyState message={basisLineage.errorMessage} />
        ) : (
          <InternalTable
            rows={basisLineage.rows}
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
        )}
      </Section>

      <Section title="Comp Evidence">
        {compEvidence.errorMessage ? (
          <EmptyState message={compEvidence.errorMessage} />
        ) : (
          <>
            <KeyValueGrid
              items={[
                {
                  label: "Estimated Value",
                  value: formatCurrentValue(compSummary.estimatedValue),
                },
                {
                  label: "Confidence",
                  value: formatEnumLabel(compSummary.confidenceLabel),
                },
                {
                  label: "Included Comps",
                  value: compSummary.includedCount,
                },
                {
                  label: "Excluded / Reference",
                  value: compSummary.excludedCount,
                },
                {
                  label: "Verified Comps",
                  value: compSummary.verifiedCount,
                },
                {
                  label: "Average Included",
                  value: formatCurrentValue(compSummary.averageValue),
                },
                {
                  label: "Median Included",
                  value: formatCurrentValue(compSummary.medianValue),
                },
              ]}
            />
            <div className="mt-4">
          <InternalTable
            rows={compSnapshots}
            emptyMessage="No comps saved for this item."
            columns={[
              {
                key: "value",
                header: "Value",
                render: (row) => formatMoney(row.market_value),
              },
              {
                key: "included",
                header: "Included",
                render: (row) => (row.include_in_valuation ? "Yes" : "No"),
              },
              {
                key: "source",
                header: "Source",
                render: (row) =>
                  row.source_domain ?? row.source ?? formatEnumLabel(row.source_type),
              },
              {
                key: "sale_date",
                header: "Sale Date",
                render: (row) => formatDate(row.sale_date ?? row.observed_at),
              },
              {
                key: "match",
                header: "Match",
                render: (row) => formatEnumLabel(row.match_quality),
              },
              {
                key: "status",
                header: "Verification",
                render: (row) => formatEnumLabel(row.verification_status),
              },
              {
                key: "grade",
                header: "Grade",
                render: (row) =>
                  [row.grading_company, row.condition_or_grade]
                    .filter(Boolean)
                    .join(" ") || "-",
              },
              {
                key: "exclusion",
                header: "Exclusion Reason",
                render: (row) => formatEnumLabel(row.exclusion_reason),
              },
              {
                key: "url",
                header: "URL",
                render: (row) =>
                  row.source_url ? (
                    <a
                      className="text-blue-700 underline"
                      href={row.source_url}
                      rel="noreferrer"
                      target="_blank"
                    >
                      Open
                    </a>
                  ) : (
                    "-"
                  ),
              },
            ]}
          />
            </div>
          </>
        )}
      </Section>

      <Section title="Transaction Lines">
        {transactionLines.errorMessage ? (
          <EmptyState message={transactionLines.errorMessage} />
        ) : (
          <InternalTable
            rows={transactionLines.rows}
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
        )}
      </Section>

      <Section title="Public Object References">
        {publicReferences.errorMessage ? (
          <EmptyState message={publicReferences.errorMessage} />
        ) : (
          <InternalTable
            rows={publicReferences.rows}
            emptyMessage="No public object references found for this item."
            columns={[
              {
                key: "reference",
                header: "Reference",
                render: (row) => <ShortId id={row.id} />,
              },
              {
                key: "product",
                header: "Product",
                render: (row) => <ShortId id={row.product_id} />,
              },
              {
                key: "title",
                header: "Title",
                render: (row) => row.display_title,
              },
              {
                key: "visibility",
                header: "Visibility",
                render: (row) => row.visibility,
              },
              {
                key: "state",
                header: "State",
                render: (row) => row.exposure_state,
              },
              {
                key: "created_for",
                header: "Created For",
                render: (row) => row.created_for ?? "-",
              },
              {
                key: "created_from",
                header: "Created From",
                render: (row) => row.created_from ?? "-",
              },
              {
                key: "created",
                header: "Created",
                render: (row) => formatDateTime(row.created_at),
              },
              {
                key: "updated",
                header: "Updated",
                render: (row) => formatDateTime(row.updated_at),
              },
            ]}
          />
        )}
      </Section>

      <Section title="Audit Events">
        {auditEvents.errorMessage ? (
          <EmptyState message={auditEvents.errorMessage} />
        ) : auditEvents.rows.length > 0 ? (
          <JsonBlock value={auditEvents.rows} />
        ) : (
          <EmptyState message="No audit events found for this item." />
        )}
      </Section>
    </main>
  );
}
