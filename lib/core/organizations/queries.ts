import type { CoreDbClient, InventoryItem } from "@/lib/core/inventory/types";
import { getOwnedInventoryItems } from "@/lib/core/inventory/queries";
import { filterInventoryByCategoryIds } from "@/lib/core/products/queries";

export async function getOrganizationInventory(
  db: CoreDbClient,
  organizationId: string,
  options?: { productId?: string | null; requireVertexProEntitlement?: boolean },
): Promise<InventoryItem[]> {
  const inventory = await getOwnedInventoryItems(db, { organizationId });

  if (!options?.productId) {
    return inventory;
  }

  if (options.requireVertexProEntitlement) {
    const { data: hasVertexPro, error: vertexProError } = await db.rpc(
      "has_organization_entitlement",
      {
        target_organization_id: organizationId,
        target_entitlement_key: "vertex_pro",
      },
    );
    const { data: hasCrossVertexInventory, error: crossVertexError } = await db.rpc(
      "has_organization_entitlement",
      {
        target_organization_id: organizationId,
        target_entitlement_key: "cross_vertex_inventory",
      },
    );

    if (vertexProError) {
      throw vertexProError;
    }
    if (crossVertexError) {
      throw crossVertexError;
    }
    if (!hasVertexPro && !hasCrossVertexInventory) {
      return [];
    }
  }

  const { data, error } = await db
    .from("product_categories")
    .select("category_id")
    .eq("product_id", options.productId);

  if (error) {
    throw error;
  }

  const categoryIds = (data ?? []).map(
    (productCategory: { category_id: string }) => productCategory.category_id,
  );

  return filterInventoryByCategoryIds(inventory, categoryIds);
}

export async function getOrganizationProductProfiles(
  db: CoreDbClient,
  organizationId: string,
) {
  const { data, error } = await db
    .from("organization_product_profiles")
    .select("*, product:products(*)")
    .eq("organization_id", organizationId)
    .order("created_at", { ascending: false });

  if (error) {
    throw error;
  }

  return data ?? [];
}
