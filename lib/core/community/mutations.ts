import type {
  CoreDbClient,
  CreateCommunityChannelInput,
  CreateCommunityInput,
  CreateCommunityMessageInput,
  JoinCommunityInput,
  ModerateCommunityContentInput,
  ReportCommunityContentInput,
} from "./types";

function requireRpcId(data: string | { id?: string } | null): string {
  if (typeof data === "string" && data) {
    return data;
  }

  if (data && typeof data === "object" && typeof data.id === "string") {
    return data.id;
  }

  throw new Error("Community RPC did not return an id.");
}

export async function createCommunity(
  db: CoreDbClient,
  input: CreateCommunityInput,
): Promise<string> {
  const { data, error } = await db.rpc("create_community", {
    p_product_id: input.productId,
    p_organization_id: input.organizationId ?? null,
    p_workspace_id: input.workspaceId ?? null,
    p_owner_user_id: input.ownerUserId ?? null,
    p_name: input.name,
    p_slug: input.slug,
    p_description: input.description ?? null,
    p_community_type: input.communityType ?? "collector_group",
    p_visibility: input.visibility ?? "private",
  });

  if (error) {
    throw error;
  }

  return requireRpcId(data);
}

export async function createCommunityChannel(
  db: CoreDbClient,
  input: CreateCommunityChannelInput,
): Promise<string> {
  const { data, error } = await db.rpc("create_community_channel", {
    p_community_id: input.communityId,
    p_name: input.name,
    p_slug: input.slug,
    p_description: input.description ?? null,
    p_channel_type: input.channelType ?? "conversation",
    p_visibility: input.visibility ?? "community",
    p_sort_order: input.sortOrder ?? 0,
  });

  if (error) {
    throw error;
  }

  return requireRpcId(data);
}

export async function joinCommunity(
  db: CoreDbClient,
  input: JoinCommunityInput,
): Promise<string> {
  const { data, error } = await db.rpc("join_community", {
    p_community_id: input.communityId,
  });

  if (error) {
    throw error;
  }

  return requireRpcId(data);
}

export async function createCommunityMessage(
  db: CoreDbClient,
  input: CreateCommunityMessageInput,
): Promise<string> {
  const { data, error } = await db.rpc("create_community_message", {
    p_channel_id: input.channelId,
    p_body: input.body ?? null,
    p_message_type: input.messageType ?? "message",
    p_reply_to_message_id: input.replyToMessageId ?? null,
    p_public_object_reference_ids: input.publicObjectReferenceIds ?? [],
  });

  if (error) {
    throw error;
  }

  return requireRpcId(data);
}

export async function reportCommunityContent(
  db: CoreDbClient,
  input: ReportCommunityContentInput,
): Promise<string> {
  const { data, error } = await db.rpc("report_community_content", {
    p_product_id: input.productId,
    p_community_id: input.communityId ?? null,
    p_channel_id: input.channelId ?? null,
    p_message_id: input.messageId ?? null,
    p_reported_entity_table: input.reportedEntityTable,
    p_reported_entity_id: input.reportedEntityId,
    p_reason: input.reason,
    p_details: input.details ?? null,
  });

  if (error) {
    throw error;
  }

  return requireRpcId(data);
}

export async function moderateCommunityContent(
  db: CoreDbClient,
  input: ModerateCommunityContentInput,
): Promise<string> {
  const { data, error } = await db.rpc("moderate_community_content", {
    p_report_id: input.reportId ?? null,
    p_product_id: input.productId,
    p_community_id: input.communityId ?? null,
    p_channel_id: input.channelId ?? null,
    p_message_id: input.messageId ?? null,
    p_target_entity_table: input.targetEntityTable,
    p_target_entity_id: input.targetEntityId,
    p_action_type: input.actionType,
    p_reason: input.reason ?? null,
    p_metadata: input.metadata ?? {},
  });

  if (error) {
    throw error;
  }

  return requireRpcId(data);
}
