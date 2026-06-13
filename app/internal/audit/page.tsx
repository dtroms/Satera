import {
  EmptyState,
  InternalPageHeader,
  InternalTable,
  JsonBlock,
  OwnerContextBadge,
  ShortId,
} from "@/components/internal";
import { requireInternalAccess } from "@/lib/core/internal/access";
import { formatDateTime } from "@/lib/core/internal/format";
import {
  getInternalAuditEvents,
  type InternalRecord,
} from "@/lib/core/internal/queries";

export const dynamic = "force-dynamic";

export default async function InternalAuditPage() {
  await requireInternalAccess();
  let auditEvents: InternalRecord[] = [];
  let errorMessage: string | null = null;

  try {
    auditEvents = await getInternalAuditEvents();
  } catch (error) {
    errorMessage =
      error instanceof Error
        ? `Audit events could not be loaded: ${error.message}`
        : "Audit events could not be loaded.";
  }

  return (
    <main className="mx-auto max-w-7xl px-6 py-10">
      <InternalPageHeader
        title="Audit Events"
        description="Read-only Core audit records. Auditability documents important system actions and protected workflow outcomes."
        backHref="/internal"
        backLabel="Internal home"
      />

      <section className="mt-8">
        {errorMessage ? (
          <EmptyState message={errorMessage} />
        ) : (
          <InternalTable
            rows={auditEvents}
            emptyMessage="No audit events are visible to this internal session."
            columns={[
              {
                key: "created",
                header: "Created",
                render: (row) => formatDateTime(row.created_at),
              },
              {
                key: "actor",
                header: "Actor",
                render: (row) => <ShortId id={row.actor_user_id} />,
              },
              {
                key: "event",
                header: "Event",
                render: (row) => row.event_type,
              },
              {
                key: "entity_table",
                header: "Entity Table",
                render: (row) => row.entity_table,
              },
              {
                key: "entity_id",
                header: "Entity ID",
                render: (row) => <ShortId id={row.entity_id} />,
              },
              {
                key: "owner",
                header: "Owner",
                render: (row) => <OwnerContextBadge record={row} />,
              },
              {
                key: "product",
                header: "Product",
                render: (row) => <ShortId id={row.product_id} />,
              },
              {
                key: "metadata",
                header: "Metadata",
                render: (row) => <JsonBlock value={row.metadata} />,
              },
            ]}
          />
        )}
      </section>
    </main>
  );
}
