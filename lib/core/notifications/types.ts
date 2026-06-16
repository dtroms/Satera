import type { CoreDbClient } from "@/lib/core/inventory/types";

export type { CoreDbClient };

export type NotificationStatus = "unread" | "read" | "dismissed" | "archived";

export type NotificationPriority = "low" | "normal" | "high" | "urgent";

export type NotificationDeliveryState =
  | "in_app_pending"
  | "in_app_seen"
  | "email_pending"
  | "email_sent"
  | "email_failed"
  | "suppressed"
  | "delivered_external";

export type NotificationDeliveryChannel =
  | "in_app"
  | "email"
  | "push"
  | "sms"
  | "webhook";

export type NotificationDeliveryAttemptStatus =
  | "pending"
  | "sent"
  | "failed"
  | "suppressed";

export type NotificationEvent = {
  id: string;
  product_id: string | null;
  actor_user_id: string | null;
  event_type: string;
  entity_table: string | null;
  entity_id: string | null;
  related_entity_table: string | null;
  related_entity_id: string | null;
  title: string;
  body: string | null;
  safe_metadata: Record<string, unknown>;
  created_at: string;
};

export type Notification = {
  id: string;
  notification_event_id: string | null;
  recipient_user_id: string;
  product_id: string | null;
  notification_type: string;
  title: string;
  body: string | null;
  entity_table: string | null;
  entity_id: string | null;
  related_entity_table: string | null;
  related_entity_id: string | null;
  status: NotificationStatus;
  priority: NotificationPriority;
  delivery_state: NotificationDeliveryState;
  safe_metadata: Record<string, unknown>;
  read_at: string | null;
  dismissed_at: string | null;
  created_at: string;
  updated_at: string;
};

export type NotificationDeliveryAttempt = {
  id: string;
  notification_id: string;
  delivery_channel: NotificationDeliveryChannel;
  provider: string | null;
  provider_message_id: string | null;
  status: NotificationDeliveryAttemptStatus;
  error_message: string | null;
  attempted_at: string;
  created_at: string;
};

export type CreateNotificationEventInput = {
  productId?: string | null;
  actorUserId?: string | null;
  eventType: string;
  entityTable?: string | null;
  entityId?: string | null;
  relatedEntityTable?: string | null;
  relatedEntityId?: string | null;
  title: string;
  body?: string | null;
  safeMetadata?: Record<string, unknown>;
  recipientUserIds?: Array<string | null | undefined>;
  notificationType?: string;
  priority?: NotificationPriority;
};

export type MarkNotificationReadInput = {
  notificationId: string;
};

export type MarkNotificationsReadInput = {
  notificationIds: string[];
};

export type DismissNotificationInput = {
  notificationId: string;
};

export type ArchiveNotificationInput = {
  notificationId: string;
};
