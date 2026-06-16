import {
  InternalPageHeader,
  InternalTable,
  JsonBlock,
  ShortId,
} from "@/components/internal";
import { requireInternalAccess } from "@/lib/core/internal/access";
import { formatDateTime } from "@/lib/core/internal/format";
import {
  getInternalModerationActions,
  getInternalModerationReports,
} from "@/lib/core/internal/queries";

export const dynamic = "force-dynamic";

function nullableShortId(id: string | null | undefined) {
  return id ? <ShortId id={id} /> : "-";
}

export default async function InternalModerationPage() {
  await requireInternalAccess();
  const [reports, actions] = await Promise.all([
    getInternalModerationReports(),
    getInternalModerationActions(),
  ]);

  return (
    <main className="mx-auto max-w-7xl px-6 py-10">
      <InternalPageHeader
        title="Moderation"
        description="Read-only Community Core moderation reports and actions."
        backHref="/internal"
        backLabel="Internal home"
      />

      <section className="mt-8">
        <h2 className="mb-3 text-lg font-semibold text-neutral-950">
          Moderation Reports
        </h2>
        <InternalTable
          rows={reports}
          emptyMessage="No moderation reports are visible to this internal session."
          columns={[
            { key: "id", header: "Report", render: (report) => <ShortId id={report.id} /> },
            {
              key: "product",
              header: "Product",
              render: (report) => nullableShortId(report.product_id),
            },
            {
              key: "community",
              header: "Community",
              render: (report) => nullableShortId(report.community_id),
            },
            {
              key: "channel",
              header: "Channel",
              render: (report) => nullableShortId(report.channel_id),
            },
            {
              key: "message",
              header: "Message",
              render: (report) => nullableShortId(report.message_id),
            },
            {
              key: "entity_table",
              header: "Entity Table",
              render: (report) => report.reported_entity_table,
            },
            {
              key: "entity_id",
              header: "Entity",
              render: (report) => nullableShortId(report.reported_entity_id),
            },
            {
              key: "reported_by",
              header: "Reported By",
              render: (report) => nullableShortId(report.reported_by),
            },
            { key: "reason", header: "Reason", render: (report) => report.reason },
            { key: "status", header: "Status", render: (report) => report.status },
            {
              key: "created",
              header: "Created",
              render: (report) => formatDateTime(report.created_at),
            },
            {
              key: "updated",
              header: "Updated",
              render: (report) => formatDateTime(report.updated_at),
            },
          ]}
        />
      </section>

      <section className="mt-8">
        <h2 className="mb-3 text-lg font-semibold text-neutral-950">
          Moderation Actions
        </h2>
        <InternalTable
          rows={actions}
          emptyMessage="No moderation actions are visible to this internal session."
          columns={[
            { key: "id", header: "Action", render: (action) => <ShortId id={action.id} /> },
            {
              key: "product",
              header: "Product",
              render: (action) => nullableShortId(action.product_id),
            },
            {
              key: "community",
              header: "Community",
              render: (action) => nullableShortId(action.community_id),
            },
            {
              key: "channel",
              header: "Channel",
              render: (action) => nullableShortId(action.channel_id),
            },
            {
              key: "message",
              header: "Message",
              render: (action) => nullableShortId(action.message_id),
            },
            {
              key: "report",
              header: "Report",
              render: (action) => nullableShortId(action.report_id),
            },
            {
              key: "actor",
              header: "Actor",
              render: (action) => nullableShortId(action.actor_user_id),
            },
            {
              key: "type",
              header: "Type",
              render: (action) => action.action_type,
            },
            {
              key: "target_table",
              header: "Target Table",
              render: (action) => action.target_entity_table,
            },
            {
              key: "target_id",
              header: "Target",
              render: (action) => nullableShortId(action.target_entity_id),
            },
            { key: "reason", header: "Reason", render: (action) => action.reason },
            {
              key: "metadata",
              header: "Metadata",
              render: (action) => (
                <div className="max-w-md whitespace-normal">
                  <JsonBlock value={action.metadata} />
                </div>
              ),
            },
            {
              key: "created",
              header: "Created",
              render: (action) => formatDateTime(action.created_at),
            },
          ]}
        />
      </section>
    </main>
  );
}
