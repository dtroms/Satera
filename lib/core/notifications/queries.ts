import type {
  CoreDbClient,
  Notification,
  NotificationDeliveryAttempt,
  NotificationEvent,
} from "./types";

const NOTIFICATION_EVENT_SELECT = "*";
const NOTIFICATION_SELECT = "*";
const NOTIFICATION_DELIVERY_ATTEMPT_SELECT = "*";

export async function getNotificationsForCurrentUser(
  db: CoreDbClient,
): Promise<Notification[]> {
  const { data, error } = await db
    .from("notifications")
    .select(NOTIFICATION_SELECT)
    .order("created_at", { ascending: false })
    .limit(100);

  if (error) {
    throw error;
  }

  return data ?? [];
}

export async function getUnreadNotificationsForCurrentUser(
  db: CoreDbClient,
): Promise<Notification[]> {
  const { data, error } = await db
    .from("notifications")
    .select(NOTIFICATION_SELECT)
    .eq("status", "unread")
    .order("created_at", { ascending: false })
    .limit(100);

  if (error) {
    throw error;
  }

  return data ?? [];
}

export async function getNotificationById(
  db: CoreDbClient,
  notificationId: string,
): Promise<Notification | null> {
  const { data, error } = await db
    .from("notifications")
    .select(NOTIFICATION_SELECT)
    .eq("id", notificationId)
    .maybeSingle();

  if (error) {
    throw error;
  }

  return data ?? null;
}

export async function getNotificationEvents(
  db: CoreDbClient,
  filters: { productId?: string; eventType?: string } = {},
): Promise<NotificationEvent[]> {
  let query = db
    .from("notification_events")
    .select(NOTIFICATION_EVENT_SELECT)
    .order("created_at", { ascending: false })
    .limit(100);

  if (filters.productId) {
    query = query.eq("product_id", filters.productId);
  }

  if (filters.eventType) {
    query = query.eq("event_type", filters.eventType);
  }

  const { data, error } = await query;

  if (error) {
    throw error;
  }

  return data ?? [];
}

export async function getNotificationDeliveryAttempts(
  db: CoreDbClient,
  notificationId: string,
): Promise<NotificationDeliveryAttempt[]> {
  const { data, error } = await db
    .from("notification_delivery_attempts")
    .select(NOTIFICATION_DELIVERY_ATTEMPT_SELECT)
    .eq("notification_id", notificationId)
    .order("attempted_at", { ascending: false });

  if (error) {
    throw error;
  }

  return data ?? [];
}
