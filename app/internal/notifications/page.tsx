import {
  InternalPageHeader,
  InternalTable,
  JsonBlock,
  ShortId,
} from "@/components/internal";
import { requireInternalAccess } from "@/lib/core/internal/access";
import { formatDateTime } from "@/lib/core/internal/format";
import {
  getInternalNotificationDeliveryAttempts,
  getInternalNotificationEvents,
  getInternalNotifications,
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

export default async function InternalNotificationsPage() {
  await requireInternalAccess();
  const [events, notifications, attempts] = await Promise.all([
    getInternalNotificationEvents(),
    getInternalNotifications(),
    getInternalNotificationDeliveryAttempts(),
  ]);

  return (
    <main className="mx-auto max-w-7xl px-6 py-10">
      <InternalPageHeader
        title="Notifications"
        description="Read-only Satera Core notification events, recipient notifications, and future delivery attempt records."
        backHref="/internal"
        backLabel="Internal home"
      />

      <Section title="Notification Events">
        <InternalTable
          rows={events}
          emptyMessage="No notification events are visible to this internal session."
          columns={[
            { key: "id", header: "Event", render: (event) => <ShortId id={event.id} /> },
            {
              key: "product",
              header: "Product",
              render: (event) => nullableShortId(event.product_id),
            },
            {
              key: "actor",
              header: "Actor",
              render: (event) => nullableShortId(event.actor_user_id),
            },
            { key: "event_type", header: "Event Type", render: (event) => event.event_type },
            {
              key: "entity_table",
              header: "Entity Table",
              render: (event) => event.entity_table ?? "-",
            },
            {
              key: "entity_id",
              header: "Entity",
              render: (event) => nullableShortId(event.entity_id),
            },
            { key: "title", header: "Title", render: (event) => event.title },
            {
              key: "created",
              header: "Created",
              render: (event) => formatDateTime(event.created_at),
            },
            {
              key: "metadata",
              header: "Safe Metadata",
              render: (event) => (
                <div className="max-w-md whitespace-normal">
                  <JsonBlock value={event.safe_metadata} />
                </div>
              ),
            },
          ]}
        />
      </Section>

      <Section title="Notifications">
        <InternalTable
          rows={notifications}
          emptyMessage="No notifications are visible to this internal session."
          columns={[
            {
              key: "id",
              header: "Notification",
              render: (notification) => <ShortId id={notification.id} />,
            },
            {
              key: "event",
              header: "Event",
              render: (notification) => nullableShortId(notification.notification_event_id),
            },
            {
              key: "recipient",
              header: "Recipient",
              render: (notification) => nullableShortId(notification.recipient_user_id),
            },
            {
              key: "product",
              header: "Product",
              render: (notification) => nullableShortId(notification.product_id),
            },
            {
              key: "type",
              header: "Type",
              render: (notification) => notification.notification_type,
            },
            { key: "status", header: "Status", render: (notification) => notification.status },
            { key: "priority", header: "Priority", render: (notification) => notification.priority },
            {
              key: "delivery",
              header: "Delivery",
              render: (notification) => notification.delivery_state,
            },
            {
              key: "entity_table",
              header: "Entity Table",
              render: (notification) => notification.entity_table ?? "-",
            },
            {
              key: "entity_id",
              header: "Entity",
              render: (notification) => nullableShortId(notification.entity_id),
            },
            { key: "title", header: "Title", render: (notification) => notification.title },
            {
              key: "read_at",
              header: "Read",
              render: (notification) => formatDateTime(notification.read_at),
            },
            {
              key: "dismissed_at",
              header: "Dismissed",
              render: (notification) => formatDateTime(notification.dismissed_at),
            },
            {
              key: "created",
              header: "Created",
              render: (notification) => formatDateTime(notification.created_at),
            },
          ]}
        />
      </Section>

      <Section title="Delivery Attempts">
        <InternalTable
          rows={attempts}
          emptyMessage="No notification delivery attempts are visible to this internal session."
          columns={[
            { key: "id", header: "Attempt", render: (attempt) => <ShortId id={attempt.id} /> },
            {
              key: "notification",
              header: "Notification",
              render: (attempt) => nullableShortId(attempt.notification_id),
            },
            {
              key: "channel",
              header: "Channel",
              render: (attempt) => attempt.delivery_channel,
            },
            {
              key: "provider",
              header: "Provider",
              render: (attempt) => attempt.provider ?? "-",
            },
            { key: "status", header: "Status", render: (attempt) => attempt.status },
            {
              key: "attempted",
              header: "Attempted",
              render: (attempt) => formatDateTime(attempt.attempted_at),
            },
            {
              key: "error",
              header: "Error",
              render: (attempt) => attempt.error_message ?? "-",
            },
          ]}
        />
      </Section>
    </main>
  );
}
