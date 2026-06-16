import { BLOCKED_PUBLIC_REFERENCE_METADATA_KEYS as BLOCKED_KEYS } from "@/lib/core/public-references/types";
import type {
  ArchiveNotificationInput,
  CoreDbClient,
  CreateNotificationEventInput,
  DismissNotificationInput,
  MarkNotificationReadInput,
  MarkNotificationsReadInput,
} from "./types";

type SafeMetadata = Record<string, unknown>;

function containsBlockedMetadataKey(value: unknown): string | null {
  if (!value || typeof value !== "object") {
    return null;
  }

  if (Array.isArray(value)) {
    for (const item of value) {
      const blocked = containsBlockedMetadataKey(item);
      if (blocked) {
        return blocked;
      }
    }

    return null;
  }

  for (const [key, nestedValue] of Object.entries(value)) {
    const blockedKey = BLOCKED_KEYS.find(
      (blocked) => blocked.toLowerCase() === key.toLowerCase(),
    );

    if (blockedKey) {
      return blockedKey;
    }

    const nestedBlocked = containsBlockedMetadataKey(nestedValue);
    if (nestedBlocked) {
      return nestedBlocked;
    }
  }

  return null;
}

export function assertNotificationMetadataSafe(
  metadata: SafeMetadata | null | undefined,
): void {
  const blockedKey = containsBlockedMetadataKey(metadata);

  if (blockedKey) {
    throw new Error(
      `Notification metadata cannot include private field ${blockedKey}.`,
    );
  }
}

function requireRpcId(data: string | { id?: string } | null): string {
  if (typeof data === "string" && data) {
    return data;
  }

  if (data && typeof data === "object" && typeof data.id === "string") {
    return data.id;
  }

  throw new Error("Notification RPC did not return an id.");
}

function requireRpcCount(data: number | { count?: number } | null): number {
  if (typeof data === "number") {
    return data;
  }

  if (data && typeof data === "object" && typeof data.count === "number") {
    return data.count;
  }

  throw new Error("Notification RPC did not return a count.");
}

export async function createNotificationEvent(
  db: CoreDbClient,
  input: CreateNotificationEventInput,
): Promise<string> {
  assertNotificationMetadataSafe(input.safeMetadata);

  const { data, error } = await db.rpc("create_notification_event", {
    p_product_id: input.productId ?? null,
    p_actor_user_id: input.actorUserId ?? null,
    p_event_type: input.eventType,
    p_entity_table: input.entityTable ?? null,
    p_entity_id: input.entityId ?? null,
    p_related_entity_table: input.relatedEntityTable ?? null,
    p_related_entity_id: input.relatedEntityId ?? null,
    p_title: input.title,
    p_body: input.body ?? null,
    p_safe_metadata: input.safeMetadata ?? {},
    p_recipient_user_ids: input.recipientUserIds ?? [],
    p_notification_type: input.notificationType ?? "system",
    p_priority: input.priority ?? "normal",
  });

  if (error) {
    throw error;
  }

  return requireRpcId(data);
}

export async function markNotificationRead(
  db: CoreDbClient,
  input: MarkNotificationReadInput,
): Promise<string> {
  const { data, error } = await db.rpc("mark_notification_read", {
    p_notification_id: input.notificationId,
  });

  if (error) {
    throw error;
  }

  return requireRpcId(data);
}

export async function markNotificationsRead(
  db: CoreDbClient,
  input: MarkNotificationsReadInput,
): Promise<number> {
  const { data, error } = await db.rpc("mark_notifications_read", {
    p_notification_ids: input.notificationIds,
  });

  if (error) {
    throw error;
  }

  return requireRpcCount(data);
}

export async function dismissNotification(
  db: CoreDbClient,
  input: DismissNotificationInput,
): Promise<string> {
  const { data, error } = await db.rpc("dismiss_notification", {
    p_notification_id: input.notificationId,
  });

  if (error) {
    throw error;
  }

  return requireRpcId(data);
}

export async function archiveNotification(
  db: CoreDbClient,
  input: ArchiveNotificationInput,
): Promise<string> {
  const { data, error } = await db.rpc("archive_notification", {
    p_notification_id: input.notificationId,
  });

  if (error) {
    throw error;
  }

  return requireRpcId(data);
}
