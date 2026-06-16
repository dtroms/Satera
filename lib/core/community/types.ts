import type { CoreDbClient, OwnerContext } from "@/lib/core/inventory/types";

export type { CoreDbClient };

export type CommunityType =
  | "collector_group"
  | "shop"
  | "show"
  | "event"
  | "trade_room"
  | "support"
  | "private_group";

export type CommunityVisibility =
  | "private"
  | "invite_only"
  | "product_visible"
  | "public";

export type CommunityStatus = "active" | "archived" | "suspended";

export type CommunityRole =
  | "owner"
  | "admin"
  | "moderator"
  | "staff"
  | "member"
  | "viewer";

export type CommunityMembershipStatus =
  | "invited"
  | "active"
  | "muted"
  | "restricted"
  | "banned"
  | "left";

export type ChannelType =
  | "conversation"
  | "announcement"
  | "trade_sale"
  | "looking_for"
  | "comps_research"
  | "show_floor"
  | "support";

export type ChannelVisibility = "community" | "moderators" | "staff" | "public";

export type ChannelStatus = "active" | "archived" | "locked";

export type MessageType =
  | "message"
  | "announcement"
  | "trade_sale"
  | "looking_for"
  | "system";

export type MessageStatus = "active" | "hidden" | "removed" | "deleted";

export type MessageReferenceType =
  | "shared_object"
  | "trade_candidate"
  | "sale_candidate"
  | "comp_reference"
  | "discussion_reference";

export type ModerationReportStatus =
  | "open"
  | "reviewing"
  | "resolved"
  | "dismissed"
  | "escalated";

export type ModerationActionType =
  | "allow"
  | "hide"
  | "remove"
  | "delete"
  | "quarantine"
  | "mark_sensitive"
  | "mute_user"
  | "restrict_user"
  | "ban_from_channel"
  | "ban_from_community"
  | "platform_suspend"
  | "escalate_to_admin";

export type UserRestrictionType =
  | "muted"
  | "restricted"
  | "read_only"
  | "posting_disabled"
  | "community_banned"
  | "channel_banned"
  | "platform_suspended";

export type UserRestrictionStatus =
  | "active"
  | "expired"
  | "lifted"
  | "replaced";

export type ModerationNoteVisibility =
  | "moderators"
  | "product_admins"
  | "platform_admins";

export type ModerationAppealStatus =
  | "open"
  | "reviewing"
  | "accepted"
  | "denied"
  | "closed";

export type Community = {
  id: string;
  product_id: string;
  organization_id: string | null;
  owner_user_id: string | null;
  workspace_id: string | null;
  name: string;
  slug: string;
  description: string | null;
  community_type: CommunityType;
  visibility: CommunityVisibility;
  status: CommunityStatus;
  created_by: string | null;
  updated_by: string | null;
  created_at: string;
  updated_at: string;
};

export type CommunityChannel = {
  id: string;
  community_id: string;
  product_id: string;
  name: string;
  slug: string;
  description: string | null;
  channel_type: ChannelType;
  visibility: ChannelVisibility;
  status: ChannelStatus;
  sort_order: number;
  created_by: string | null;
  updated_by: string | null;
  created_at: string;
  updated_at: string;
};

export type CommunityMembership = {
  id: string;
  community_id: string;
  product_id: string;
  user_id: string;
  role: CommunityRole;
  status: CommunityMembershipStatus;
  joined_at: string;
  invited_by: string | null;
  created_at: string;
  updated_at: string;
};

export type CommunityMessage = {
  id: string;
  community_id: string;
  channel_id: string;
  product_id: string;
  author_user_id: string;
  body: string | null;
  message_type: MessageType;
  status: MessageStatus;
  reply_to_message_id: string | null;
  edited_at: string | null;
  deleted_at: string | null;
  created_at: string;
  updated_at: string;
};

export type CommunityMessageReference = {
  id: string;
  message_id: string;
  community_id: string;
  channel_id: string;
  product_id: string;
  public_object_reference_id: string;
  reference_type: MessageReferenceType;
  display_snapshot: Record<string, unknown>;
  created_by: string | null;
  created_at: string;
};

export type ModerationReport = {
  id: string;
  product_id: string;
  community_id: string | null;
  channel_id: string | null;
  message_id: string | null;
  reported_entity_table: string;
  reported_entity_id: string;
  reported_by: string;
  reason: string;
  details: string | null;
  status: ModerationReportStatus;
  created_at: string;
  updated_at: string;
};

export type ModerationAction = {
  id: string;
  product_id: string;
  community_id: string | null;
  channel_id: string | null;
  message_id: string | null;
  report_id: string | null;
  actor_user_id: string;
  action_type: ModerationActionType;
  target_entity_table: string;
  target_entity_id: string;
  reason: string | null;
  metadata: Record<string, unknown>;
  created_at: string;
};

export type UserRestriction = {
  id: string;
  product_id: string;
  community_id: string | null;
  channel_id: string | null;
  user_id: string;
  restriction_type: UserRestrictionType;
  status: UserRestrictionStatus;
  reason: string | null;
  starts_at: string;
  expires_at: string | null;
  created_by: string;
  lifted_by: string | null;
  lifted_at: string | null;
  metadata: Record<string, unknown>;
  created_at: string;
  updated_at: string;
};

export type ModerationNote = {
  id: string;
  product_id: string;
  community_id: string | null;
  report_id: string | null;
  action_id: string | null;
  subject_user_id: string | null;
  note: string;
  visibility: ModerationNoteVisibility;
  created_by: string;
  created_at: string;
  updated_at: string;
};

export type ModerationAppeal = {
  id: string;
  product_id: string;
  community_id: string | null;
  report_id: string | null;
  action_id: string | null;
  restriction_id: string | null;
  submitted_by: string;
  reason: string;
  status: ModerationAppealStatus;
  reviewed_by: string | null;
  reviewed_at: string | null;
  decision_reason: string | null;
  created_at: string;
  updated_at: string;
};

export type CreateCommunityInput = OwnerContext & {
  productId: string;
  name: string;
  slug: string;
  description?: string | null;
  communityType?: CommunityType;
  visibility?: CommunityVisibility;
};

export type CreateCommunityChannelInput = {
  communityId: string;
  name: string;
  slug: string;
  description?: string | null;
  channelType?: ChannelType;
  visibility?: ChannelVisibility;
  sortOrder?: number | null;
};

export type JoinCommunityInput = {
  communityId: string;
};

export type CreateCommunityMessageInput = {
  channelId: string;
  body?: string | null;
  messageType?: MessageType;
  replyToMessageId?: string | null;
  publicObjectReferenceIds?: string[];
};

export type ReportCommunityContentInput = {
  productId: string;
  communityId?: string | null;
  channelId?: string | null;
  messageId?: string | null;
  reportedEntityTable: string;
  reportedEntityId: string;
  reason: string;
  details?: string | null;
};

export type ModerateCommunityContentInput = {
  reportId?: string | null;
  productId: string;
  communityId?: string | null;
  channelId?: string | null;
  messageId?: string | null;
  targetEntityTable: string;
  targetEntityId: string;
  actionType: ModerationActionType;
  reason?: string | null;
  metadata?: Record<string, unknown> | null;
};

export type LiftUserRestrictionInput = {
  restrictionId: string;
  reason?: string | null;
};

export type AddModerationNoteInput = {
  productId: string;
  communityId?: string | null;
  reportId?: string | null;
  actionId?: string | null;
  subjectUserId?: string | null;
  note: string;
  visibility?: ModerationNoteVisibility;
};

export type SubmitModerationAppealInput = {
  productId: string;
  communityId?: string | null;
  reportId?: string | null;
  actionId?: string | null;
  restrictionId?: string | null;
  reason: string;
};
