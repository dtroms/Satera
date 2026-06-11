import type { CoreDbClient, InventoryItem, OwnerContext } from "@/lib/core/inventory/types";
import { getOwnedInventoryItems } from "@/lib/core/inventory/queries";

export type ProductReference =
  | { productId: string; productSlug?: never }
  | { productSlug: string; productId?: never };

export async function getActiveProducts(db: CoreDbClient) {
  const { data, error } = await db
    .from("products")
    .select("*")
    .eq("status", "active")
    .order("name", { ascending: true });

  if (error) {
    throw error;
  }

  return data ?? [];
}

export async function getProductBySlug(db: CoreDbClient, slug: string) {
  const { data, error } = await db
    .from("products")
    .select("*")
    .eq("slug", slug)
    .maybeSingle();

  if (error) {
    throw error;
  }

  return data ?? null;
}

export async function getProductCategories(
  db: CoreDbClient,
  productRef: ProductReference,
) {
  const product =
    "productId" in productRef
      ? { id: productRef.productId }
      : await getProductBySlug(db, productRef.productSlug);

  if (!product?.id) {
    return [];
  }

  const { data, error } = await db
    .from("product_categories")
    .select("*, category:categories(*)")
    .eq("product_id", product.id);

  if (error) {
    throw error;
  }

  return data ?? [];
}

export function filterInventoryByCategoryIds(
  inventoryItems: InventoryItem[],
  categoryIds: string[],
): InventoryItem[] {
  const supportedCategoryIds = new Set(categoryIds);
  return inventoryItems.filter((item) => supportedCategoryIds.has(item.category_id));
}

export async function getProductScopedInventory(
  db: CoreDbClient,
  productRef: ProductReference,
  ownerContext: OwnerContext,
): Promise<InventoryItem[]> {
  const [productCategories, ownedInventory] = await Promise.all([
    getProductCategories(db, productRef),
    getOwnedInventoryItems(db, ownerContext),
  ]);

  const categoryIds = productCategories.map(
    (productCategory: { category_id: string }) => productCategory.category_id,
  );

  return filterInventoryByCategoryIds(ownedInventory, categoryIds);
}
