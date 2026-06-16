import type { CoreDbClient, OwnerContext } from "@/lib/core/inventory/types";

export type { CoreDbClient };

export type PublicObjectReferenceVisibility =
  | "private_reference"
  | "community"
  | "listing"
  | "showcase"
  | "trade"
  | "public";

export type PublicObjectReferenceExposureState =
  | "active"
  | "hidden"
  | "removed"
  | "expired"
  | "revoked";

export type PublicObjectReference = {
  id: string;
  owner_user_id: string | null;
  workspace_id: string | null;
  organization_id: string | null;
  product_id: string;
  category_id: string | null;
  inventory_item_id: string | null;
  asset_family_id: string | null;
  asset_variant_id: string | null;
  object_type: string;
  display_title: string;
  display_subtitle: string | null;
  display_label: string | null;
  display_image_url: string | null;
  condition_label: string | null;
  grade_label: string | null;
  value_label: string | null;
  value_snapshot_id: string | null;
  visibility: PublicObjectReferenceVisibility;
  exposure_state: PublicObjectReferenceExposureState;
  created_for: string | null;
  created_from: string | null;
  public_metadata: Record<string, unknown>;
  created_by: string | null;
  updated_by: string | null;
  created_at: string;
  updated_at: string;
};

export type PublicReferenceDisplayInput = {
  displayTitle?: string | null;
  displaySubtitle?: string | null;
  displayLabel?: string | null;
  displayImageUrl?: string | null;
  conditionLabel?: string | null;
  gradeLabel?: string | null;
  valueLabel?: string | null;
  valueSnapshotId?: string | null;
  publicMetadata?: Record<string, unknown> | null;
};

export type CreatePublicObjectReferenceInput = PublicReferenceDisplayInput & {
  inventoryItemId: string;
  productId: string;
  visibility?: PublicObjectReferenceVisibility;
  createdFor?: string | null;
};

export type UpdatePublicObjectReferenceDisplayInput =
  PublicReferenceDisplayInput & {
    publicObjectReferenceId: string;
  };

export type PublicObjectReferenceOwnerContext = OwnerContext;

export const PUBLIC_OBJECT_REFERENCE_VISIBILITIES = [
  "private_reference",
  "community",
  "listing",
  "showcase",
  "trade",
  "public",
] as const;

export const PUBLIC_OBJECT_REFERENCE_EXPOSURE_STATES = [
  "active",
  "hidden",
  "removed",
  "expired",
  "revoked",
] as const;

export const BLOCKED_PUBLIC_REFERENCE_METADATA_KEYS = [
  "purchase_price",
  "true_basis",
  "cost_basis",
  "basis",
  "profit",
  "roi",
  "location",
  "private_notes",
  "private_tags",
  "ownership_history",
  "private_transaction_history",
  "grading_costs",
] as const;
