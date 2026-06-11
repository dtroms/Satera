import type { CoreDbClient, InventoryItem } from "@/lib/core/inventory/types";
import { getOwnedInventoryItems } from "@/lib/core/inventory/queries";

export type PortfolioSummary = {
  itemCount: number;
  missingBasisCount: number;
  knownZeroBasisCount: number;
  totalKnownBasis: number;
  totalCurrentValue: number;
  noCompSavedCount: number;
};

export function buildPortfolioSummary(
  inventoryItems: InventoryItem[],
): PortfolioSummary {
  return inventoryItems.reduce<PortfolioSummary>(
    (summary, item) => {
      const currentValue = item.current_value_snapshot?.market_value;

      return {
        itemCount: summary.itemCount + 1,
        missingBasisCount:
          summary.missingBasisCount + (item.true_basis === null ? 1 : 0),
        knownZeroBasisCount:
          summary.knownZeroBasisCount + (item.true_basis === 0 ? 1 : 0),
        totalKnownBasis:
          summary.totalKnownBasis + (item.true_basis === null ? 0 : item.true_basis),
        totalCurrentValue:
          summary.totalCurrentValue + (typeof currentValue === "number" ? currentValue : 0),
        noCompSavedCount:
          summary.noCompSavedCount + (typeof currentValue === "number" ? 0 : 1),
      };
    },
    {
      itemCount: 0,
      missingBasisCount: 0,
      knownZeroBasisCount: 0,
      totalKnownBasis: 0,
      totalCurrentValue: 0,
      noCompSavedCount: 0,
    },
  );
}

export async function getPortfolioInventory(
  db: CoreDbClient,
  userId: string,
): Promise<InventoryItem[]> {
  const { data: hasEntitlement, error } = await db.rpc("has_account_entitlement", {
    target_user_id: userId,
    target_entitlement_key: "cross_vertex_portfolio",
  });

  if (error) {
    throw error;
  }

  if (!hasEntitlement) {
    return getOwnedInventoryItems(db, { ownerUserId: userId });
  }

  return getOwnedInventoryItems(db, { ownerUserId: userId });
}

export async function getPortfolioSummary(
  db: CoreDbClient,
  userId: string,
): Promise<PortfolioSummary> {
  const inventory = await getPortfolioInventory(db, userId);
  return buildPortfolioSummary(inventory);
}
