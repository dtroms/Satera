import type { CoreDbClient, InventoryItem, OwnerContext } from "./types";

const INVENTORY_SELECT = `
  *,
  current_value_snapshot:comp_snapshots!inventory_items_current_value_snapshot_id_fkey(
    id,
    market_value,
    currency_code,
    observed_at
  )
`;

function ownerContextOrFilter(context: OwnerContext): string {
  const filters = [
    context.ownerUserId ? `owner_user_id.eq.${context.ownerUserId}` : null,
    context.workspaceId ? `workspace_id.eq.${context.workspaceId}` : null,
    context.organizationId ? `organization_id.eq.${context.organizationId}` : null,
  ].filter(Boolean);

  if (filters.length === 0) {
    throw new Error("At least one owner context is required.");
  }

  return filters.join(",");
}

export async function getOwnedInventoryItems(
  db: CoreDbClient,
  context: OwnerContext,
): Promise<InventoryItem[]> {
  const { data, error } = await db
    .from("inventory_items")
    .select(INVENTORY_SELECT)
    .or(ownerContextOrFilter(context))
    .order("created_at", { ascending: false });

  if (error) {
    throw error;
  }

  return data ?? [];
}

export async function getInventoryItemById(
  db: CoreDbClient,
  inventoryItemId: string,
): Promise<InventoryItem | null> {
  const { data, error } = await db
    .from("inventory_items")
    .select(INVENTORY_SELECT)
    .eq("id", inventoryItemId)
    .maybeSingle();

  if (error) {
    throw error;
  }

  return data ?? null;
}
