import type {
  ConditionType,
  InventoryAvailability,
  InventoryIntent,
  InventoryStatus,
} from "@/lib/core/types";

export type CoreDbClient = {
  from: (table: string) => any;
  rpc: (fn: string, args?: Record<string, unknown>) => any;
};

export type OwnerContext = {
  ownerUserId?: string | null;
  workspaceId?: string | null;
  organizationId?: string | null;
};

export type InventoryItem = {
  id: string;
  owner_user_id: string | null;
  workspace_id: string | null;
  organization_id: string | null;
  category_id: string;
  asset_variant_id: string;
  condition_type: ConditionType;
  status: InventoryStatus;
  availability: InventoryAvailability;
  intent: InventoryIntent;
  location_id: string | null;
  true_basis: number | null;
  current_value_snapshot_id: string | null;
  acquired_at: string | null;
  notes: string | null;
  created_by: string | null;
  updated_by: string | null;
  created_at: string;
  updated_at: string;
  current_value_snapshot?: {
    id: string;
    market_value: number;
    currency_code: string;
    observed_at: string;
  } | null;
};

export type CreateInventoryItemInput = OwnerContext & {
  categoryId: string;
  assetVariantId: string;
  conditionType?: ConditionType;
  status?: InventoryStatus;
  availability?: InventoryAvailability;
  intent?: InventoryIntent;
  locationId?: string | null;
  acquiredAt?: string | null;
  notes?: string | null;
  createdBy: string;
};

export type SafeInventoryItemUpdate = {
  notes?: string | null;
  intent?: InventoryIntent;
  location_id?: string | null;
  availability?: InventoryAvailability;
};

export const SAFE_INVENTORY_UPDATE_FIELDS = [
  "notes",
  "intent",
  "location_id",
  "availability",
] as const;

export const BLOCKED_INVENTORY_UPDATE_FIELDS = [
  "true_basis",
  "current_value_snapshot_id",
  "owner_user_id",
  "workspace_id",
  "organization_id",
  "category_id",
  "asset_variant_id",
] as const;
