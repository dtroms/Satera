import type { CoreDbClient } from "@/lib/core/inventory/types";
import type {
  BasisLineage,
  InventoryLineageSummary,
  OwnershipTimelineEntry,
} from "./types";

export async function getOwnershipTimeline(
  db: CoreDbClient,
  inventoryItemId: string,
): Promise<OwnershipTimelineEntry[]> {
  const { data, error } = await db
    .from("ownership_events")
    .select("*, transaction:transactions(*)")
    .eq("inventory_item_id", inventoryItemId)
    .order("event_date", { ascending: true })
    .order("created_at", { ascending: true });

  if (error) {
    throw error;
  }

  return data ?? [];
}

export async function getBasisLineage(
  db: CoreDbClient,
  inventoryItemId: string,
): Promise<BasisLineage> {
  const [basisEventsResult, lineageEdgesResult, transactionLinesResult] =
    await Promise.all([
      db
        .from("basis_events")
        .select("*, transaction:transactions(*)")
        .eq("inventory_item_id", inventoryItemId)
        .order("created_at", { ascending: true }),
      db
        .from("basis_lineage_edges")
        .select(
          "*, transaction:transactions(*), source_inventory_item:inventory_items!basis_lineage_edges_source_inventory_item_id_fkey(*), target_inventory_item:inventory_items!basis_lineage_edges_target_inventory_item_id_fkey(*)",
        )
        .or(
          `source_inventory_item_id.eq.${inventoryItemId},target_inventory_item_id.eq.${inventoryItemId}`,
        )
        .order("created_at", { ascending: true }),
      db
        .from("transaction_lines")
        .select("*, transaction:transactions(*)")
        .eq("inventory_item_id", inventoryItemId)
        .order("created_at", { ascending: true }),
    ]);

  if (basisEventsResult.error) {
    throw basisEventsResult.error;
  }
  if (lineageEdgesResult.error) {
    throw lineageEdgesResult.error;
  }
  if (transactionLinesResult.error) {
    throw transactionLinesResult.error;
  }

  return {
    basisEvents: basisEventsResult.data ?? [],
    lineageEdges: lineageEdgesResult.data ?? [],
    transactionLines: transactionLinesResult.data ?? [],
  };
}

export async function getInventoryLineageSummary(
  db: CoreDbClient,
  inventoryItemId: string,
): Promise<InventoryLineageSummary> {
  const [inventoryResult, ownershipTimeline, basisLineage] = await Promise.all([
    db
      .from("inventory_items")
      .select("id, true_basis")
      .eq("id", inventoryItemId)
      .maybeSingle(),
    getOwnershipTimeline(db, inventoryItemId),
    getBasisLineage(db, inventoryItemId),
  ]);

  if (inventoryResult.error) {
    throw inventoryResult.error;
  }

  return {
    inventoryItemId,
    entryEvent: ownershipTimeline[0] ?? null,
    latestOwnershipEvent: ownershipTimeline[ownershipTimeline.length - 1] ?? null,
    basisEventCount: basisLineage.basisEvents.length,
    lineageEdgeCount: basisLineage.lineageEdges.length,
    transactionLineCount: basisLineage.transactionLines.length,
    currentBasis: inventoryResult.data?.true_basis ?? null,
  };
}
