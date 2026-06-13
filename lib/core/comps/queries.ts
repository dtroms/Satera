import type { CoreDbClient } from "@/lib/core/inventory/types";
import type { CompSnapshot } from "./types";

export async function getCompSnapshotsForInventoryItem(
  db: CoreDbClient,
  inventoryItemId: string,
): Promise<CompSnapshot[]> {
  const { data, error } = await db
    .from("comp_snapshots")
    .select("*")
    .eq("inventory_item_id", inventoryItemId)
    .order("sale_date", { ascending: false, nullsFirst: false })
    .order("observed_at", { ascending: false });

  if (error) {
    throw error;
  }

  return data ?? [];
}
