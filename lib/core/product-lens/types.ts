import type { Community } from "@/lib/core/community/types";
import type { EvaluationCase } from "@/lib/core/evaluations/types";
import type { InventoryItem, OwnerContext } from "@/lib/core/inventory/types";
import type { Notification } from "@/lib/core/notifications/types";
import type { PublicObjectReference } from "@/lib/core/public-references/types";
import type { EntitlementKey, ProductStatus, ProductType } from "@/lib/core/types";

export type ProductLensProduct = {
  id: string;
  slug: string;
  name: string;
  product_type: ProductType;
  status: ProductStatus;
  created_at: string;
  updated_at: string;
};

export type ProductLens =
  | { productId: string; productSlug?: never }
  | { productSlug: string; productId?: never };

export type ProductLensProfile = {
  id: string;
  user_id?: string;
  organization_id?: string;
  product_id: string;
  display_name: string;
  handle: string | null;
  profile_data: Record<string, unknown>;
  created_at: string;
  updated_at: string;
};

export type ProductLensEntitlements = {
  account: EntitlementKey[];
  organization: EntitlementKey[];
  hasCrossVertexPortfolio: boolean;
  hasVertexPro: boolean;
  hasCrossVertexInventory: boolean;
};

export type ProductLensAccess = {
  canAccessProduct: boolean;
  hasProductProfile: boolean;
  hasOrganizationProductProfile: boolean;
  hasAccountEntitlements: boolean;
  hasOrganizationEntitlements: boolean;
  hasWorkspaceContext: boolean;
};

export type ProductLensContext = {
  product: ProductLensProduct;
  productProfile: ProductLensProfile | null;
  organizationProductProfile: ProductLensProfile | null;
  entitlements: ProductLensEntitlements;
  productCategoryIds: string[];
  access: ProductLensAccess;
  workspaceId: string | null;
  organizationId: string | null;
};

export type ProductLensContextInput = ProductLens & {
  currentUserId?: string | null;
  workspaceId?: string | null;
  organizationId?: string | null;
};

export type ProductLensInventoryFilters = {
  status?: string;
  availability?: string;
  intent?: string;
};

export type ProductLensInventoryInput = ProductLens & {
  workspaceId: string;
  filters?: ProductLensInventoryFilters;
};

export type ProductLensPublicReferenceFilters = {
  visibility?: string | string[];
  exposureState?: string;
};

export type ProductLensPublicReferencesInput = ProductLens & {
  filters?: ProductLensPublicReferenceFilters;
};

export type ProductLensNotificationsInput = ProductLens & {
  includeGlobal?: boolean;
  status?: string;
};

export type ProductLensEvaluationCasesInput = ProductLens & {
  workspaceId: string;
  status?: string;
};

export type ProductLensEntitlementsInput = ProductLens & {
  organizationId?: string | null;
};

export type ProductLensSummaryInput = ProductLens & {
  workspaceId?: string | null;
};

export type ProductLensInventoryItem = InventoryItem;
export type ProductLensPublicReference = PublicObjectReference;
export type ProductLensCommunity = Community;
export type ProductLensNotification = Notification;
export type ProductLensEvaluationCase = EvaluationCase;

export type ProductLensSummary = {
  productId: string;
  inventoryCount: number;
  publicReferenceCount: number;
  communityCount: number;
  unreadNotificationCount: number;
  evaluationCaseCount: number;
  entitlementFlags: ProductLensEntitlements;
};

export type ProductLensOwnerContext = OwnerContext;
