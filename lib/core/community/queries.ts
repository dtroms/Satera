import type {
  Community,
  CommunityChannel,
  CommunityMembership,
  CommunityMessage,
  CommunityMessageReference,
  CoreDbClient,
  ModerationAction,
  ModerationReport,
} from "./types";

const COMMUNITY_SELECT = "*";
const CHANNEL_SELECT = "*";
const MEMBERSHIP_SELECT = "*";
const MESSAGE_SELECT = "*";
const MESSAGE_REFERENCE_SELECT = "*";
const MODERATION_REPORT_SELECT = "*";
const MODERATION_ACTION_SELECT = "*";

export async function getCommunityById(
  db: CoreDbClient,
  communityId: string,
): Promise<Community | null> {
  const { data, error } = await db
    .from("communities")
    .select(COMMUNITY_SELECT)
    .eq("id", communityId)
    .maybeSingle();

  if (error) {
    throw error;
  }

  return data ?? null;
}

export async function getCommunitiesForProduct(
  db: CoreDbClient,
  productId: string,
): Promise<Community[]> {
  const { data, error } = await db
    .from("communities")
    .select(COMMUNITY_SELECT)
    .eq("product_id", productId)
    .order("created_at", { ascending: false });

  if (error) {
    throw error;
  }

  return data ?? [];
}

export async function getCommunitiesForOrganization(
  db: CoreDbClient,
  organizationId: string,
): Promise<Community[]> {
  const { data, error } = await db
    .from("communities")
    .select(COMMUNITY_SELECT)
    .eq("organization_id", organizationId)
    .order("created_at", { ascending: false });

  if (error) {
    throw error;
  }

  return data ?? [];
}

export async function getCommunityChannels(
  db: CoreDbClient,
  communityId: string,
): Promise<CommunityChannel[]> {
  const { data, error } = await db
    .from("community_channels")
    .select(CHANNEL_SELECT)
    .eq("community_id", communityId)
    .order("sort_order", { ascending: true })
    .order("created_at", { ascending: true });

  if (error) {
    throw error;
  }

  return data ?? [];
}

export async function getCommunityMemberships(
  db: CoreDbClient,
  communityId: string,
): Promise<CommunityMembership[]> {
  const { data, error } = await db
    .from("community_memberships")
    .select(MEMBERSHIP_SELECT)
    .eq("community_id", communityId)
    .order("joined_at", { ascending: false });

  if (error) {
    throw error;
  }

  return data ?? [];
}

export async function getCommunityMessages(
  db: CoreDbClient,
  filters: { communityId?: string; channelId?: string; productId?: string } = {},
): Promise<CommunityMessage[]> {
  let query = db
    .from("community_messages")
    .select(MESSAGE_SELECT)
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

  if (error) {
    throw error;
  }

  return data ?? [];
}

export async function getCommunityMessageReferences(
  db: CoreDbClient,
  filters: { messageId?: string; communityId?: string; channelId?: string } = {},
): Promise<CommunityMessageReference[]> {
  let query = db
    .from("community_message_references")
    .select(MESSAGE_REFERENCE_SELECT)
    .order("created_at", { ascending: false });

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

  if (error) {
    throw error;
  }

  return data ?? [];
}

export async function getModerationReports(
  db: CoreDbClient,
  filters: { communityId?: string; productId?: string; messageId?: string } = {},
): Promise<ModerationReport[]> {
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

  if (error) {
    throw error;
  }

  return data ?? [];
}

export async function getModerationActions(
  db: CoreDbClient,
  filters: { communityId?: string; productId?: string; messageId?: string } = {},
): Promise<ModerationAction[]> {
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

  const { data, error } = await query;

  if (error) {
    throw error;
  }

  return data ?? [];
}
