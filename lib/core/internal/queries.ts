import { createClient } from "@/lib/supabase/server";
import type { CompSnapshot } from "@/lib/core/comps/types";

export type InternalRecord = Record<string, any>;

const INVENTORY_SELECT = `
  *,
  category:categories(id, slug, name),
  asset_variant:asset_variants(id, name, variant_key),
  current_value_snapshot:comp_snapshots!inventory_items_current_value_snapshot_id_fkey(
    id,
    market_value,
    currency_code,
    observed_at
  )
`;

const TRANSACTION_SELECT = "*";
const COMP_SNAPSHOT_SELECT = "*";
const PUBLIC_OBJECT_REFERENCE_SELECT = "*";
const COMMUNITY_SELECT = "*";
const COMMUNITY_CHANNEL_SELECT = "*";
const COMMUNITY_MEMBERSHIP_SELECT = "*";
const COMMUNITY_MESSAGE_SELECT = "*";
const COMMUNITY_MESSAGE_REFERENCE_SELECT = "*";
const MODERATION_REPORT_SELECT = "*";
const MODERATION_ACTION_SELECT = "*";
const USER_RESTRICTION_SELECT = "*";
const MODERATION_NOTE_SELECT = "*";
const MODERATION_APPEAL_SELECT = "*";
const NOTIFICATION_EVENT_SELECT = "*";
const NOTIFICATION_SELECT = "*";
const NOTIFICATION_DELIVERY_ATTEMPT_SELECT = "*";
const EVALUATION_CASE_SELECT = "*";
const EVALUATION_CASE_ITEM_SELECT = "*";
const EVALUATION_EVENT_SELECT = "*";
const EVALUATION_ATTACHMENT_SELECT = "*";

function throwIfError(error: unknown): void {
  if (error) {
    throw error;
  }
}

export async function getInternalInventoryItems(): Promise<InternalRecord[]> {
  const db = await createClient();
  const { data, error } = await db
    .from("inventory_items")
    .select(INVENTORY_SELECT)
    .order("updated_at", { ascending: false })
    .limit(100);

  throwIfError(error);
  return data ?? [];
}

export async function getInternalInventoryItemById(
  id: string,
): Promise<InternalRecord | null> {
  const db = await createClient();
  const { data, error } = await db
    .from("inventory_items")
    .select(INVENTORY_SELECT)
    .eq("id", id)
    .maybeSingle();

  throwIfError(error);
  return data ?? null;
}

export async function getInternalTransactions(): Promise<InternalRecord[]> {
  const db = await createClient();
  const { data, error } = await db
    .from("transactions")
    .select(TRANSACTION_SELECT)
    .order("transaction_date", { ascending: false })
    .order("created_at", { ascending: false })
    .limit(100);

  throwIfError(error);
  return data ?? [];
}

export async function getInternalTransactionById(
  id: string,
): Promise<InternalRecord | null> {
  const db = await createClient();
  const { data, error } = await db
    .from("transactions")
    .select(TRANSACTION_SELECT)
    .eq("id", id)
    .maybeSingle();

  throwIfError(error);
  return data ?? null;
}

export async function getInternalOwnershipEventsForItem(
  inventoryItemId: string,
): Promise<InternalRecord[]> {
  const db = await createClient();
  const { data, error } = await db
    .from("ownership_events")
    .select("*, transaction:transactions(id, transaction_type, transaction_date)")
    .eq("inventory_item_id", inventoryItemId)
    .order("event_date", { ascending: true })
    .order("created_at", { ascending: true });

  throwIfError(error);
  return data ?? [];
}

export async function getInternalBasisEventsForItem(
  inventoryItemId: string,
): Promise<InternalRecord[]> {
  const db = await createClient();
  const { data, error } = await db
    .from("basis_events")
    .select("*, transaction:transactions(id, transaction_type, transaction_date)")
    .eq("inventory_item_id", inventoryItemId)
    .order("created_at", { ascending: true });

  throwIfError(error);
  return data ?? [];
}

export async function getInternalBasisLineageForItem(
  inventoryItemId: string,
): Promise<InternalRecord[]> {
  const db = await createClient();
  const { data, error } = await db
    .from("basis_lineage_edges")
    .select("*, transaction:transactions(id, transaction_type, transaction_date)")
    .or(
      `source_inventory_item_id.eq.${inventoryItemId},target_inventory_item_id.eq.${inventoryItemId}`,
    )
    .order("created_at", { ascending: true });

  throwIfError(error);
  return data ?? [];
}

export async function getInternalTransactionLinesForItem(
  inventoryItemId: string,
): Promise<InternalRecord[]> {
  const db = await createClient();
  const { data, error } = await db
    .from("transaction_lines")
    .select("*, transaction:transactions(id, transaction_type, transaction_date)")
    .eq("inventory_item_id", inventoryItemId)
    .order("created_at", { ascending: true });

  throwIfError(error);
  return data ?? [];
}

export async function getInternalCompSnapshotsForItem(
  inventoryItemId: string,
): Promise<CompSnapshot[]> {
  const db = await createClient();
  const { data, error } = await db
    .from("comp_snapshots")
    .select(COMP_SNAPSHOT_SELECT)
    .eq("inventory_item_id", inventoryItemId)
    .order("sale_date", { ascending: false, nullsFirst: false })
    .order("observed_at", { ascending: false });

  throwIfError(error);
  return (data ?? []) as CompSnapshot[];
}

export async function getInternalPublicObjectReferences(): Promise<
  InternalRecord[]
> {
  const db = await createClient();
  const { data, error } = await db
    .from("public_object_references")
    .select(PUBLIC_OBJECT_REFERENCE_SELECT)
    .order("created_at", { ascending: false })
    .limit(100);

  throwIfError(error);
  return data ?? [];
}

export async function getInternalPublicObjectReferencesForItem(
  inventoryItemId: string,
): Promise<InternalRecord[]> {
  const db = await createClient();
  const { data, error } = await db
    .from("public_object_references")
    .select(PUBLIC_OBJECT_REFERENCE_SELECT)
    .eq("inventory_item_id", inventoryItemId)
    .order("created_at", { ascending: false });

  throwIfError(error);
  return data ?? [];
}

export async function getInternalBasisLineageEdges(): Promise<InternalRecord[]> {
  const db = await createClient();
  const { data, error } = await db
    .from("basis_lineage_edges")
    .select("*")
    .order("created_at", { ascending: false })
    .limit(100);

  throwIfError(error);
  return data ?? [];
}

export async function getInternalAuditEvents(): Promise<InternalRecord[]> {
  const db = await createClient();
  const { data, error } = await db
    .from("audit_events")
    .select("*")
    .order("created_at", { ascending: false })
    .limit(100);

  throwIfError(error);
  return data ?? [];
}

export async function getInternalProducts(): Promise<InternalRecord[]> {
  const db = await createClient();
  const { data, error } = await db
    .from("products")
    .select("*")
    .order("slug", { ascending: true });

  throwIfError(error);
  return data ?? [];
}

export async function getInternalProductCategories(): Promise<InternalRecord[]> {
  const db = await createClient();
  const { data, error } = await db
    .from("product_categories")
    .select("*, product:products(id, slug, name), category:categories(id, slug, name)")
    .order("created_at", { ascending: true });

  throwIfError(error);
  return data ?? [];
}

export async function getInternalCategories(): Promise<InternalRecord[]> {
  const db = await createClient();
  const { data, error } = await db
    .from("categories")
    .select("*")
    .order("slug", { ascending: true });

  throwIfError(error);
  return data ?? [];
}

export async function getInternalAssetFamilies(): Promise<InternalRecord[]> {
  const db = await createClient();
  const { data, error } = await db
    .from("asset_families")
    .select("*, category:categories(id, slug, name), collection:collections(id, slug, name)")
    .order("created_at", { ascending: false })
    .limit(50);

  throwIfError(error);
  return data ?? [];
}

export async function getInternalAssetVariants(): Promise<InternalRecord[]> {
  const db = await createClient();
  const { data, error } = await db
    .from("asset_variants")
    .select("*, asset_family:asset_families(id, name), category:categories(id, slug, name)")
    .order("created_at", { ascending: false })
    .limit(100);

  throwIfError(error);
  return data ?? [];
}

export async function getInternalTransactionLinesForTransaction(
  transactionId: string,
): Promise<InternalRecord[]> {
  const db = await createClient();
  const { data, error } = await db
    .from("transaction_lines")
    .select("*, inventory_item:inventory_items(id, category_id, asset_variant_id)")
    .eq("transaction_id", transactionId)
    .order("created_at", { ascending: true });

  throwIfError(error);
  return data ?? [];
}

export async function getInternalOwnershipEventsForTransaction(
  transactionId: string,
): Promise<InternalRecord[]> {
  const db = await createClient();
  const { data, error } = await db
    .from("ownership_events")
    .select("*")
    .eq("transaction_id", transactionId)
    .order("event_date", { ascending: true })
    .order("created_at", { ascending: true });

  throwIfError(error);
  return data ?? [];
}

export async function getInternalBasisEventsForTransaction(
  transactionId: string,
): Promise<InternalRecord[]> {
  const db = await createClient();
  const { data, error } = await db
    .from("basis_events")
    .select("*")
    .eq("transaction_id", transactionId)
    .order("created_at", { ascending: true });

  throwIfError(error);
  return data ?? [];
}

export async function getInternalBasisLineageForTransaction(
  transactionId: string,
): Promise<InternalRecord[]> {
  const db = await createClient();
  const { data, error } = await db
    .from("basis_lineage_edges")
    .select("*")
    .eq("transaction_id", transactionId)
    .order("created_at", { ascending: true });

  throwIfError(error);
  return data ?? [];
}

export async function getInternalAuditEventsForEntity(
  entityTable: string,
  entityId: string,
): Promise<InternalRecord[]> {
  const db = await createClient();
  const { data, error } = await db
    .from("audit_events")
    .select("*")
    .eq("entity_table", entityTable)
    .eq("entity_id", entityId)
    .order("created_at", { ascending: true });

  throwIfError(error);
  return data ?? [];
}

export async function getInternalCommunities(): Promise<InternalRecord[]> {
  const db = await createClient();
  const { data, error } = await db
    .from("communities")
    .select(COMMUNITY_SELECT)
    .order("created_at", { ascending: false })
    .limit(100);

  throwIfError(error);
  return data ?? [];
}

export async function getInternalCommunityById(
  id: string,
): Promise<InternalRecord | null> {
  const db = await createClient();
  const { data, error } = await db
    .from("communities")
    .select(COMMUNITY_SELECT)
    .eq("id", id)
    .maybeSingle();

  throwIfError(error);
  return data ?? null;
}

export async function getInternalCommunityChannels(
  communityId?: string,
): Promise<InternalRecord[]> {
  const db = await createClient();
  let query = db
    .from("community_channels")
    .select(COMMUNITY_CHANNEL_SELECT)
    .order("sort_order", { ascending: true })
    .order("created_at", { ascending: true });

  if (communityId) {
    query = query.eq("community_id", communityId);
  }

  const { data, error } = await query;

  throwIfError(error);
  return data ?? [];
}

export async function getInternalCommunityMemberships(
  communityId?: string,
): Promise<InternalRecord[]> {
  const db = await createClient();
  let query = db
    .from("community_memberships")
    .select(COMMUNITY_MEMBERSHIP_SELECT)
    .order("joined_at", { ascending: false });

  if (communityId) {
    query = query.eq("community_id", communityId);
  }

  const { data, error } = await query;

  throwIfError(error);
  return data ?? [];
}

export async function getInternalCommunityMessages(filters: {
  communityId?: string;
  channelId?: string;
  productId?: string;
} = {}): Promise<InternalRecord[]> {
  const db = await createClient();
  let query = db
    .from("community_messages")
    .select(COMMUNITY_MESSAGE_SELECT)
    .order("created_at", { ascending: false })
    .limit(100);

  if (filters.communityId) {
    query = query.eq("community_id", filters.communityId);
  }

  if (filters.channelId) {
    query = query.eq("channel_id", filters.channelId);
  }

  if (filters.productId) {
    query = query.eq("product_id", filters.productId);
  }

  const { data, error } = await query;

  throwIfError(error);
  return data ?? [];
}

export async function getInternalCommunityMessageReferences(filters: {
  messageId?: string;
  communityId?: string;
  channelId?: string;
} = {}): Promise<InternalRecord[]> {
  const db = await createClient();
  let query = db
    .from("community_message_references")
    .select(COMMUNITY_MESSAGE_REFERENCE_SELECT)
    .order("created_at", { ascending: false })
    .limit(100);

  if (filters.messageId) {
    query = query.eq("message_id", filters.messageId);
  }

  if (filters.communityId) {
    query = query.eq("community_id", filters.communityId);
  }

  if (filters.channelId) {
    query = query.eq("channel_id", filters.channelId);
  }

  const { data, error } = await query;

  throwIfError(error);
  return data ?? [];
}

export async function getInternalModerationReports(filters: {
  communityId?: string;
  productId?: string;
  messageId?: string;
} = {}): Promise<InternalRecord[]> {
  const db = await createClient();
  let query = db
    .from("moderation_reports")
    .select(MODERATION_REPORT_SELECT)
    .order("created_at", { ascending: false })
    .limit(100);

  if (filters.communityId) {
    query = query.eq("community_id", filters.communityId);
  }

  if (filters.productId) {
    query = query.eq("product_id", filters.productId);
  }

  if (filters.messageId) {
    query = query.eq("message_id", filters.messageId);
  }

  const { data, error } = await query;

  throwIfError(error);
  return data ?? [];
}

export async function getInternalModerationActions(filters: {
  communityId?: string;
  productId?: string;
  messageId?: string;
  reportId?: string;
} = {}): Promise<InternalRecord[]> {
  const db = await createClient();
  let query = db
    .from("moderation_actions")
    .select(MODERATION_ACTION_SELECT)
    .order("created_at", { ascending: false })
    .limit(100);

  if (filters.communityId) {
    query = query.eq("community_id", filters.communityId);
  }

  if (filters.productId) {
    query = query.eq("product_id", filters.productId);
  }

  if (filters.messageId) {
    query = query.eq("message_id", filters.messageId);
  }

  if (filters.reportId) {
    query = query.eq("report_id", filters.reportId);
  }

  const { data, error } = await query;

  throwIfError(error);
  return data ?? [];
}

export async function getInternalUserRestrictions(filters: {
  communityId?: string;
  productId?: string;
  userId?: string;
  status?: string;
} = {}): Promise<InternalRecord[]> {
  const db = await createClient();
  let query = db
    .from("user_restrictions")
    .select(USER_RESTRICTION_SELECT)
    .order("created_at", { ascending: false })
    .limit(100);

  if (filters.communityId) {
    query = query.eq("community_id", filters.communityId);
  }

  if (filters.productId) {
    query = query.eq("product_id", filters.productId);
  }

  if (filters.userId) {
    query = query.eq("user_id", filters.userId);
  }

  if (filters.status) {
    query = query.eq("status", filters.status);
  }

  const { data, error } = await query;

  throwIfError(error);
  return data ?? [];
}

export async function getInternalModerationNotes(filters: {
  communityId?: string;
  productId?: string;
  reportId?: string;
  actionId?: string;
  subjectUserId?: string;
} = {}): Promise<InternalRecord[]> {
  const db = await createClient();
  let query = db
    .from("moderation_notes")
    .select(MODERATION_NOTE_SELECT)
    .order("created_at", { ascending: false })
    .limit(100);

  if (filters.communityId) {
    query = query.eq("community_id", filters.communityId);
  }

  if (filters.productId) {
    query = query.eq("product_id", filters.productId);
  }

  if (filters.reportId) {
    query = query.eq("report_id", filters.reportId);
  }

  if (filters.actionId) {
    query = query.eq("action_id", filters.actionId);
  }

  if (filters.subjectUserId) {
    query = query.eq("subject_user_id", filters.subjectUserId);
  }

  const { data, error } = await query;

  throwIfError(error);
  return data ?? [];
}

export async function getInternalModerationAppeals(filters: {
  communityId?: string;
  productId?: string;
  submittedBy?: string;
  status?: string;
  actionId?: string;
  restrictionId?: string;
} = {}): Promise<InternalRecord[]> {
  const db = await createClient();
  let query = db
    .from("moderation_appeals")
    .select(MODERATION_APPEAL_SELECT)
    .order("created_at", { ascending: false })
    .limit(100);

  if (filters.communityId) {
    query = query.eq("community_id", filters.communityId);
  }

  if (filters.productId) {
    query = query.eq("product_id", filters.productId);
  }

  if (filters.submittedBy) {
    query = query.eq("submitted_by", filters.submittedBy);
  }

  if (filters.status) {
    query = query.eq("status", filters.status);
  }

  if (filters.actionId) {
    query = query.eq("action_id", filters.actionId);
  }

  if (filters.restrictionId) {
    query = query.eq("restriction_id", filters.restrictionId);
  }

  const { data, error } = await query;

  throwIfError(error);
  return data ?? [];
}

export async function getInternalNotificationEvents(filters: {
  productId?: string;
  eventType?: string;
} = {}): Promise<InternalRecord[]> {
  const db = await createClient();
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

  throwIfError(error);
  return data ?? [];
}

export async function getInternalNotifications(filters: {
  productId?: string;
  recipientUserId?: string;
  status?: string;
} = {}): Promise<InternalRecord[]> {
  const db = await createClient();
  let query = db
    .from("notifications")
    .select(NOTIFICATION_SELECT)
    .order("created_at", { ascending: false })
    .limit(100);

  if (filters.productId) {
    query = query.eq("product_id", filters.productId);
  }

  if (filters.recipientUserId) {
    query = query.eq("recipient_user_id", filters.recipientUserId);
  }

  if (filters.status) {
    query = query.eq("status", filters.status);
  }

  const { data, error } = await query;

  throwIfError(error);
  return data ?? [];
}

export async function getInternalNotificationDeliveryAttempts(filters: {
  notificationId?: string;
  status?: string;
} = {}): Promise<InternalRecord[]> {
  const db = await createClient();
  let query = db
    .from("notification_delivery_attempts")
    .select(NOTIFICATION_DELIVERY_ATTEMPT_SELECT)
    .order("attempted_at", { ascending: false })
    .limit(100);

  if (filters.notificationId) {
    query = query.eq("notification_id", filters.notificationId);
  }

  if (filters.status) {
    query = query.eq("status", filters.status);
  }

  const { data, error } = await query;

  throwIfError(error);
  return data ?? [];
}

export async function getInternalEvaluationCases(): Promise<InternalRecord[]> {
  const db = await createClient();
  const { data, error } = await db
    .from("evaluation_cases")
    .select(EVALUATION_CASE_SELECT)
    .order("opened_at", { ascending: false })
    .order("created_at", { ascending: false })
    .limit(100);

  throwIfError(error);
  return data ?? [];
}

export async function getInternalEvaluationCaseById(
  id: string,
): Promise<InternalRecord | null> {
  const db = await createClient();
  const { data, error } = await db
    .from("evaluation_cases")
    .select(EVALUATION_CASE_SELECT)
    .eq("id", id)
    .maybeSingle();

  throwIfError(error);
  return data ?? null;
}

export async function getInternalEvaluationCaseItems(
  evaluationCaseId?: string,
): Promise<InternalRecord[]> {
  const db = await createClient();
  let query = db
    .from("evaluation_case_items")
    .select(EVALUATION_CASE_ITEM_SELECT)
    .order("created_at", { ascending: true })
    .limit(100);

  if (evaluationCaseId) {
    query = query.eq("evaluation_case_id", evaluationCaseId);
  }

  const { data, error } = await query;

  throwIfError(error);
  return data ?? [];
}

export async function getInternalEvaluationEvents(
  evaluationCaseId?: string,
): Promise<InternalRecord[]> {
  const db = await createClient();
  let query = db
    .from("evaluation_events")
    .select(EVALUATION_EVENT_SELECT)
    .order("occurred_at", { ascending: true })
    .order("created_at", { ascending: true })
    .limit(200);

  if (evaluationCaseId) {
    query = query.eq("evaluation_case_id", evaluationCaseId);
  }

  const { data, error } = await query;

  throwIfError(error);
  return data ?? [];
}

export async function getInternalEvaluationAttachments(
  evaluationCaseId?: string,
): Promise<InternalRecord[]> {
  const db = await createClient();
  let query = db
    .from("evaluation_attachments")
    .select(EVALUATION_ATTACHMENT_SELECT)
    .order("created_at", { ascending: false })
    .limit(100);

  if (evaluationCaseId) {
    query = query.eq("evaluation_case_id", evaluationCaseId);
  }

  const { data, error } = await query;

  throwIfError(error);
  return data ?? [];
}
