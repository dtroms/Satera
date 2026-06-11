import type { CreateInventoryItemInput, CoreDbClient } from "./types";
import {
  BLOCKED_INVENTORY_UPDATE_FIELDS,
  SAFE_INVENTORY_UPDATE_FIELDS,
  type SafeInventoryItemUpdate,
} from "./types";

export function assertOwnerContext(input: {
  ownerUserId?: string | null;
  workspaceId?: string | null;
  organizationId?: string | null;
}) {
  if (!input.ownerUserId && !input.workspaceId && !input.organizationId) {
    throw new Error("Inventory item requires a user, workspace, or organization owner context.");
  }
}

export function sanitizeSafeInventoryUpdate(
  input: Record<string, unknown>,
): SafeInventoryItemUpdate {
  const blockedField = BLOCKED_INVENTORY_UPDATE_FIELDS.find((field) =>
    Object.prototype.hasOwnProperty.call(input, field),
  );

  if (blockedField) {
    throw new Error(`Direct inventory mutation of ${blockedField} is not allowed.`);
  }

  return SAFE_INVENTORY_UPDATE_FIELDS.reduce<SafeInventoryItemUpdate>(
    (safeUpdate, field) => {
      if (Object.prototype.hasOwnProperty.call(input, field)) {
        return { ...safeUpdate, [field]: input[field] };
      }

      return safeUpdate;
    },
    {},
  );
}

export async function createInventoryItem(
  db: CoreDbClient,
  input: CreateInventoryItemInput,
) {
  void db;
  void input;
  throw new Error(
    "Direct inventory creation is disabled. Use a transaction workflow instead.",
  );
}

export async function updateInventoryItemSafeFields(
  db: CoreDbClient,
  inventoryItemId: string,
  input: Record<string, unknown>,
  updatedBy: string,
) {
  const safeUpdate = sanitizeSafeInventoryUpdate(input);
  void updatedBy;

  const hasOwn = (field: keyof SafeInventoryItemUpdate) =>
    Object.prototype.hasOwnProperty.call(safeUpdate, field);

  const { data, error } = await db.rpc("update_inventory_item_safe_fields", {
    p_target_inventory_item_id: inventoryItemId,
    p_new_notes: safeUpdate.notes ?? null,
    p_new_intent: safeUpdate.intent ?? null,
    p_new_location_id: safeUpdate.location_id ?? null,
    p_new_availability: safeUpdate.availability ?? null,
    p_update_notes: hasOwn("notes"),
    p_update_intent: hasOwn("intent"),
    p_update_location_id: hasOwn("location_id"),
    p_update_availability: hasOwn("availability"),
  });

  if (error) {
    throw error;
  }

  return data;
}
