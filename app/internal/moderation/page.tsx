import {
  InternalPageHeader,
  InternalTable,
  JsonBlock,
  ShortId,
} from "@/components/internal";
import { requireInternalAccess } from "@/lib/core/internal/access";
import { formatDateTime } from "@/lib/core/internal/format";
import {
  getInternalModerationAppeals,
  getInternalModerationActions,
  getInternalModerationNotes,
  getInternalModerationReports,
  getInternalUserRestrictions,
} from "@/lib/core/internal/queries";

export const dynamic = "force-dynamic";

function nullableShortId(id: string | null | undefined) {
  return id ? <ShortId id={id} /> : "-";
}

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

export default async function InternalModerationPage() {
  await requireInternalAccess();
  const [reports, actions, restrictions, notes, appeals] = await Promise.all([
    getInternalModerationReports(),
    getInternalModerationActions(),
    getInternalUserRestrictions(),
    getInternalModerationNotes(),
    getInternalModerationAppeals(),
  ]);

  return (
    <main className="mx-auto max-w-7xl px-6 py-10">
      <InternalPageHeader
        title="Moderation"
        description="Read-only Community Core moderation reports and actions."
        backHref="/internal"
        backLabel="Internal home"
      />

      <Section title="Moderation Reports">
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
      </Section>

      <Section title="Moderation Actions">
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
      </Section>

      <Section title="User Restrictions">
        <InternalTable
          rows={restrictions}
          emptyMessage="No user restrictions are visible to this internal session."
          columns={[
            {
              key: "id",
              header: "Restriction",
              render: (restriction) => <ShortId id={restriction.id} />,
            },
            {
              key: "product",
              header: "Product",
              render: (restriction) => nullableShortId(restriction.product_id),
            },
            {
              key: "community",
              header: "Community",
              render: (restriction) => nullableShortId(restriction.community_id),
            },
            {
              key: "channel",
              header: "Channel",
              render: (restriction) => nullableShortId(restriction.channel_id),
            },
            {
              key: "user",
              header: "User",
              render: (restriction) => nullableShortId(restriction.user_id),
            },
            {
              key: "type",
              header: "Type",
              render: (restriction) => restriction.restriction_type,
            },
            {
              key: "status",
              header: "Status",
              render: (restriction) => restriction.status,
            },
            {
              key: "starts",
              header: "Starts",
              render: (restriction) => formatDateTime(restriction.starts_at),
            },
            {
              key: "expires",
              header: "Expires",
              render: (restriction) => formatDateTime(restriction.expires_at),
            },
            {
              key: "lifted",
              header: "Lifted",
              render: (restriction) => formatDateTime(restriction.lifted_at),
            },
            {
              key: "metadata",
              header: "Metadata",
              render: (restriction) => (
                <div className="max-w-md whitespace-normal">
                  <JsonBlock value={restriction.metadata} />
                </div>
              ),
            },
          ]}
        />
      </Section>

      <Section title="Moderation Notes">
        <InternalTable
          rows={notes}
          emptyMessage="No moderation notes are visible to this internal session."
          columns={[
            { key: "id", header: "Note", render: (note) => <ShortId id={note.id} /> },
            {
              key: "product",
              header: "Product",
              render: (note) => nullableShortId(note.product_id),
            },
            {
              key: "community",
              header: "Community",
              render: (note) => nullableShortId(note.community_id),
            },
            {
              key: "report",
              header: "Report",
              render: (note) => nullableShortId(note.report_id),
            },
            {
              key: "action",
              header: "Action",
              render: (note) => nullableShortId(note.action_id),
            },
            {
              key: "subject",
              header: "Subject",
              render: (note) => nullableShortId(note.subject_user_id),
            },
            { key: "visibility", header: "Visibility", render: (note) => note.visibility },
            { key: "note", header: "Note", render: (note) => note.note },
            {
              key: "created_by",
              header: "Created By",
              render: (note) => nullableShortId(note.created_by),
            },
            {
              key: "created",
              header: "Created",
              render: (note) => formatDateTime(note.created_at),
            },
          ]}
        />
      </Section>

      <Section title="Moderation Appeals">
        <InternalTable
          rows={appeals}
          emptyMessage="No moderation appeals are visible to this internal session."
          columns={[
            {
              key: "id",
              header: "Appeal",
              render: (appeal) => <ShortId id={appeal.id} />,
            },
            {
              key: "product",
              header: "Product",
              render: (appeal) => nullableShortId(appeal.product_id),
            },
            {
              key: "community",
              header: "Community",
              render: (appeal) => nullableShortId(appeal.community_id),
            },
            {
              key: "report",
              header: "Report",
              render: (appeal) => nullableShortId(appeal.report_id),
            },
            {
              key: "action",
              header: "Action",
              render: (appeal) => nullableShortId(appeal.action_id),
            },
            {
              key: "restriction",
              header: "Restriction",
              render: (appeal) => nullableShortId(appeal.restriction_id),
            },
            {
              key: "submitted_by",
              header: "Submitted By",
              render: (appeal) => nullableShortId(appeal.submitted_by),
            },
            { key: "status", header: "Status", render: (appeal) => appeal.status },
            { key: "reason", header: "Reason", render: (appeal) => appeal.reason },
            {
              key: "reviewed_by",
              header: "Reviewed By",
              render: (appeal) => nullableShortId(appeal.reviewed_by),
            },
            {
              key: "created",
              header: "Created",
              render: (appeal) => formatDateTime(appeal.created_at),
            },
          ]}
        />
      </Section>
    </main>
  );
}
