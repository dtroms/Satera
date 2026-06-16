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
import { formatDateTime } from "@/lib/core/internal/format";
import {
  getInternalCommunityById,
  getInternalCommunityChannels,
  getInternalCommunityMemberships,
  getInternalCommunityMessageReferences,
  getInternalCommunityMessages,
  getInternalModerationActions,
  getInternalModerationReports,
} from "@/lib/core/internal/queries";

export const dynamic = "force-dynamic";

type PageProps = {
  params: Promise<{ id: string }>;
};

function nullableShortId(id: string | null | undefined) {
  return id ? <ShortId id={id} /> : "-";
}

function bodyPreview(body: string | null | undefined) {
  if (!body) {
    return "-";
  }

  return body.length > 80 ? `${body.slice(0, 80)}...` : body;
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

export default async function InternalCommunityDetailPage({ params }: PageProps) {
  await requireInternalAccess();
  const { id } = await params;
  const [
    community,
    channels,
    memberships,
    messages,
    references,
    reports,
    actions,
  ] = await Promise.all([
    getInternalCommunityById(id),
    getInternalCommunityChannels(id),
    getInternalCommunityMemberships(id),
    getInternalCommunityMessages({ communityId: id }),
    getInternalCommunityMessageReferences({ communityId: id }),
    getInternalModerationReports({ communityId: id }),
    getInternalModerationActions({ communityId: id }),
  ]);

  if (!community) {
    return (
      <main className="mx-auto max-w-7xl px-6 py-10">
        <InternalPageHeader
          title="Community Not Found"
          backHref="/internal/communities"
          backLabel="Communities"
        />
        <div className="mt-8">
          <EmptyState message="No community is visible for this id." />
        </div>
      </main>
    );
  }

  return (
    <main className="mx-auto max-w-7xl px-6 py-10">
      <InternalPageHeader
        title={community.name}
        description="Read-only Community Core detail view."
        backHref="/internal/communities"
        backLabel="Communities"
      />

      <Section title="Community Summary">
        <KeyValueGrid
          items={[
            { label: "ID", value: <ShortId id={community.id} /> },
            { label: "Name", value: community.name },
            { label: "Slug", value: community.slug },
            { label: "Description", value: community.description },
            { label: "Product", value: nullableShortId(community.product_id) },
            {
              label: "Owner",
              value: <OwnerContextBadge record={community} />,
            },
            { label: "Type", value: community.community_type },
            { label: "Visibility", value: community.visibility },
            { label: "Status", value: community.status },
            { label: "Created By", value: nullableShortId(community.created_by) },
            { label: "Created", value: formatDateTime(community.created_at) },
            { label: "Updated", value: formatDateTime(community.updated_at) },
          ]}
        />
      </Section>

      <Section title="Channels">
        <InternalTable
          rows={channels}
          emptyMessage="No channels are visible for this community."
          columns={[
            { key: "name", header: "Name", render: (channel) => channel.name },
            { key: "slug", header: "Slug", render: (channel) => channel.slug },
            {
              key: "type",
              header: "Type",
              render: (channel) => channel.channel_type,
            },
            {
              key: "visibility",
              header: "Visibility",
              render: (channel) => channel.visibility,
            },
            {
              key: "status",
              header: "Status",
              render: (channel) => channel.status,
            },
            {
              key: "sort_order",
              header: "Sort",
              render: (channel) => channel.sort_order,
            },
          ]}
        />
      </Section>

      <Section title="Memberships">
        <InternalTable
          rows={memberships}
          emptyMessage="No memberships are visible for this community."
          columns={[
            {
              key: "user",
              header: "User",
              render: (membership) => nullableShortId(membership.user_id),
            },
            { key: "role", header: "Role", render: (membership) => membership.role },
            {
              key: "status",
              header: "Status",
              render: (membership) => membership.status,
            },
            {
              key: "joined",
              header: "Joined",
              render: (membership) => formatDateTime(membership.joined_at),
            },
            {
              key: "invited_by",
              header: "Invited By",
              render: (membership) => nullableShortId(membership.invited_by),
            },
          ]}
        />
      </Section>

      <Section title="Recent Messages">
        <InternalTable
          rows={messages}
          emptyMessage="No messages are visible for this community."
          columns={[
            { key: "id", header: "Message", render: (message) => <ShortId id={message.id} /> },
            {
              key: "channel",
              header: "Channel",
              render: (message) => nullableShortId(message.channel_id),
            },
            {
              key: "author",
              header: "Author",
              render: (message) => nullableShortId(message.author_user_id),
            },
            {
              key: "type",
              header: "Type",
              render: (message) => message.message_type,
            },
            {
              key: "status",
              header: "Status",
              render: (message) => message.status,
            },
            {
              key: "body",
              header: "Body",
              render: (message) => bodyPreview(message.body),
            },
            {
              key: "created",
              header: "Created",
              render: (message) => formatDateTime(message.created_at),
            },
          ]}
        />
      </Section>

      <Section title="Message References">
        <InternalTable
          rows={references}
          emptyMessage="No message references are visible for this community."
          columns={[
            {
              key: "message",
              header: "Message",
              render: (reference) => nullableShortId(reference.message_id),
            },
            {
              key: "reference",
              header: "Public Ref",
              render: (reference) =>
                nullableShortId(reference.public_object_reference_id),
            },
            {
              key: "type",
              header: "Type",
              render: (reference) => reference.reference_type,
            },
            {
              key: "snapshot",
              header: "Display Snapshot",
              render: (reference) => (
                <div className="max-w-md whitespace-normal">
                  <JsonBlock value={reference.display_snapshot} />
                </div>
              ),
            },
          ]}
        />
      </Section>

      <Section title="Moderation Reports">
        <InternalTable
          rows={reports}
          emptyMessage="No moderation reports are visible for this community."
          columns={[
            { key: "id", header: "Report", render: (report) => <ShortId id={report.id} /> },
            { key: "reason", header: "Reason", render: (report) => report.reason },
            { key: "status", header: "Status", render: (report) => report.status },
            {
              key: "reported_by",
              header: "Reported By",
              render: (report) => nullableShortId(report.reported_by),
            },
            {
              key: "created",
              header: "Created",
              render: (report) => formatDateTime(report.created_at),
            },
          ]}
        />
      </Section>

      <Section title="Moderation Actions">
        <InternalTable
          rows={actions}
          emptyMessage="No moderation actions are visible for this community."
          columns={[
            {
              key: "action",
              header: "Action",
              render: (action) => action.action_type,
            },
            {
              key: "actor",
              header: "Actor",
              render: (action) => nullableShortId(action.actor_user_id),
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
            {
              key: "created",
              header: "Created",
              render: (action) => formatDateTime(action.created_at),
            },
          ]}
        />
      </Section>
    </main>
  );
}
