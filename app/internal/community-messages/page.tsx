import {
  InternalPageHeader,
  InternalTable,
  JsonBlock,
  ShortId,
} from "@/components/internal";
import { requireInternalAccess } from "@/lib/core/internal/access";
import { formatDateTime } from "@/lib/core/internal/format";
import {
  getInternalCommunityMessageReferences,
  getInternalCommunityMessages,
} from "@/lib/core/internal/queries";

export const dynamic = "force-dynamic";

function nullableShortId(id: string | null | undefined) {
  return id ? <ShortId id={id} /> : "-";
}

function bodyPreview(body: string | null | undefined) {
  if (!body) {
    return "-";
  }

  return body.length > 100 ? `${body.slice(0, 100)}...` : body;
}

export default async function InternalCommunityMessagesPage() {
  await requireInternalAccess();
  const [messages, references] = await Promise.all([
    getInternalCommunityMessages(),
    getInternalCommunityMessageReferences(),
  ]);

  return (
    <main className="mx-auto max-w-7xl px-6 py-10">
      <InternalPageHeader
        title="Community Messages"
        description="Read-only Community Core messages and safe public object reference attachments."
        backHref="/internal"
        backLabel="Internal home"
      />

      <section className="mt-8">
        <InternalTable
          rows={messages}
          emptyMessage="No community messages are visible to this internal session."
          columns={[
            { key: "id", header: "Message", render: (message) => <ShortId id={message.id} /> },
            {
              key: "community",
              header: "Community",
              render: (message) => nullableShortId(message.community_id),
            },
            {
              key: "channel",
              header: "Channel",
              render: (message) => nullableShortId(message.channel_id),
            },
            {
              key: "product",
              header: "Product",
              render: (message) => nullableShortId(message.product_id),
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
            {
              key: "updated",
              header: "Updated",
              render: (message) => formatDateTime(message.updated_at),
            },
          ]}
        />
      </section>

      <section className="mt-8">
        <h2 className="mb-3 text-lg font-semibold text-neutral-950">
          Message References
        </h2>
        <InternalTable
          rows={references}
          emptyMessage="No message references are visible to this internal session."
          columns={[
            {
              key: "message",
              header: "Message",
              render: (reference) => nullableShortId(reference.message_id),
            },
            {
              key: "community",
              header: "Community",
              render: (reference) => nullableShortId(reference.community_id),
            },
            {
              key: "public_ref",
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
      </section>
    </main>
  );
}
