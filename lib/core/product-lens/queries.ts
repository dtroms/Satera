import { getCommunitiesForProduct } from "@/lib/core/community/queries";
import { getEvaluationCases } from "@/lib/core/evaluations/queries";
import { getOwnedInventoryItems } from "@/lib/core/inventory/queries";
import type { CoreDbClient } from "@/lib/core/inventory/types";
import { getPublicObjectReferencesForProduct } from "@/lib/core/public-references/queries";
import type { EntitlementKey } from "@/lib/core/types";
import {
  type ProductLens,
  type ProductLensContext,
  type ProductLensContextInput,
  type ProductLensEntitlements,
  type ProductLensEntitlementsInput,
  type ProductLensEvaluationCasesInput,
  type ProductLensEvaluationCase,
  type ProductLensInventoryInput,
  type ProductLensInventoryItem,
  type ProductLensNotificationsInput,
  type ProductLensNotification,
  type ProductLensProduct,
  type ProductLensPublicReference,
  type ProductLensPublicReferencesInput,
  type ProductLensSummary,
  type ProductLensSummaryInput,
} from "./types";

const PRODUCT_LENS_ENTITLEMENT_KEYS: EntitlementKey[] = [
  "cross_vertex_portfolio",
  "advanced_analytics",
  "insurance_exports",
  "bulk_import",
  "premium_saved_views",
  "vertex_pro",
  "cross_vertex_inventory",
  "multi_product_presence",
  "staff_accounts",
  "multi_location_inventory",
  "organization_analytics",
  "dealer_verification",
];

async function resolveProduct(
  db: CoreDbClient,
  productRef: ProductLens,
): Promise<ProductLensProduct | null> {
  const query = db.from("products").select("*");

  const { data, error } =
    "productId" in productRef
      ? await query.eq("id", productRef.productId).maybeSingle()
      : await query.eq("slug", productRef.productSlug).maybeSingle();

  if (error) {
    throw error;
  }

  return data ?? null;
}

function requireProduct(product: ProductLensProduct | null): ProductLensProduct {
  if (!product) {
    throw new Error("Product lens requires an existing product.");
  }

  return product;
}

async function getProductCategoryIds(
  db: CoreDbClient,
  productId: string,
): Promise<string[]> {
  const { data, error } = await db
    .from("product_categories")
    .select("category_id")
    .eq("product_id", productId);

  if (error) {
    throw error;
  }

  return (data ?? []).map(
    (productCategory: { category_id: string }) => productCategory.category_id,
  );
}

function hasEntitlement(entitlements: EntitlementKey[], key: EntitlementKey) {
  return entitlements.includes(key);
}

async function getAccountEntitlementKeys(db: CoreDbClient): Promise<EntitlementKey[]> {
  const { data, error } = await db
    .from("account_entitlements")
    .select("entitlement_key")
    .in("entitlement_key", PRODUCT_LENS_ENTITLEMENT_KEYS);

  if (error) {
    throw error;
  }

  return (data ?? []).map(
    (entitlement: { entitlement_key: EntitlementKey }) => entitlement.entitlement_key,
  );
}

async function getOrganizationEntitlementKeys(
  db: CoreDbClient,
  organizationId?: string | null,
): Promise<EntitlementKey[]> {
  if (!organizationId) {
    return [];
  }

  const { data, error } = await db
    .from("organization_entitlements")
    .select("entitlement_key")
    .eq("organization_id", organizationId)
    .in("entitlement_key", PRODUCT_LENS_ENTITLEMENT_KEYS);

  if (error) {
    throw error;
  }

  return (data ?? []).map(
    (entitlement: { entitlement_key: EntitlementKey }) => entitlement.entitlement_key,
  );
}

export async function getProductLensEntitlements(
  db: CoreDbClient,
  input: ProductLensEntitlementsInput,
): Promise<ProductLensEntitlements> {
  const product = requireProduct(await resolveProduct(db, input));
  const [account, organization] = await Promise.all([
    getAccountEntitlementKeys(db),
    getOrganizationEntitlementKeys(db, input.organizationId),
  ]);

  void product;

  return {
    account,
    organization,
    hasCrossVertexPortfolio: hasEntitlement(account, "cross_vertex_portfolio"),
    hasVertexPro: hasEntitlement(organization, "vertex_pro"),
    hasCrossVertexInventory: hasEntitlement(organization, "cross_vertex_inventory"),
  };
}

export async function getProductLensContext(
  db: CoreDbClient,
  input: ProductLensContextInput,
): Promise<ProductLensContext> {
  const product = requireProduct(await resolveProduct(db, input));
  const [
    productCategoryIds,
    entitlements,
    accessResult,
    productProfileResult,
    organizationProductProfileResult,
  ] = await Promise.all([
    getProductCategoryIds(db, product.id),
    getProductLensEntitlements(db, {
      productId: product.id,
      organizationId: input.organizationId,
    }),
    db.rpc("can_access_product", { target_product_id: product.id }),
    input.currentUserId
      ? db
          .from("product_profiles")
          .select("*")
          .eq("product_id", product.id)
          .eq("user_id", input.currentUserId)
          .maybeSingle()
      : Promise.resolve({ data: null, error: null }),
    input.organizationId
      ? db
          .from("organization_product_profiles")
          .select("*")
          .eq("product_id", product.id)
          .eq("organization_id", input.organizationId)
          .maybeSingle()
      : Promise.resolve({ data: null, error: null }),
  ]);

  if (accessResult.error) {
    throw accessResult.error;
  }
  if (productProfileResult.error) {
    throw productProfileResult.error;
  }
  if (organizationProductProfileResult.error) {
    throw organizationProductProfileResult.error;
  }

  return {
    product,
    productProfile: productProfileResult.data ?? null,
    organizationProductProfile: organizationProductProfileResult.data ?? null,
    entitlements,
    productCategoryIds,
    access: {
      canAccessProduct: Boolean(accessResult.data),
      hasProductProfile: Boolean(productProfileResult.data),
      hasOrganizationProductProfile: Boolean(organizationProductProfileResult.data),
      hasAccountEntitlements: entitlements.account.length > 0,
      hasOrganizationEntitlements: entitlements.organization.length > 0,
      hasWorkspaceContext: Boolean(input.workspaceId),
    },
    workspaceId: input.workspaceId ?? null,
    organizationId: input.organizationId ?? null,
  };
}

function filterInventoryByProductCategoryIds(
  inventoryItems: ProductLensInventoryItem[],
  categoryIds: string[],
): ProductLensInventoryItem[] {
  const productCategoryIds = new Set(categoryIds);
  return inventoryItems.filter((item) => productCategoryIds.has(item.category_id));
}

export async function getProductLensInventory(
  db: CoreDbClient,
  input: ProductLensInventoryInput,
): Promise<ProductLensInventoryItem[]> {
  const product = requireProduct(await resolveProduct(db, input));
  const [productCategoryIds, inventory] = await Promise.all([
    getProductCategoryIds(db, product.id),
    getOwnedInventoryItems(db, { workspaceId: input.workspaceId }),
  ]);

  return filterInventoryByProductCategoryIds(inventory, productCategoryIds).filter(
    (item) =>
      (!input.filters?.status || item.status === input.filters.status) &&
      (!input.filters?.availability ||
        item.availability === input.filters.availability) &&
      (!input.filters?.intent || item.intent === input.filters.intent),
  );
}

export async function getProductLensPublicReferences(
  db: CoreDbClient,
  input: ProductLensPublicReferencesInput,
): Promise<ProductLensPublicReference[]> {
  const product = requireProduct(await resolveProduct(db, input));
  let references = await getPublicObjectReferencesForProduct(db, product.id);

  if (input.filters?.exposureState) {
    references = references.filter(
      (reference) => reference.exposure_state === input.filters?.exposureState,
    );
  }

  if (input.filters?.visibility) {
    const visibilities = Array.isArray(input.filters.visibility)
      ? input.filters.visibility
      : [input.filters.visibility];
    references = references.filter((reference) =>
      visibilities.includes(reference.visibility),
    );
  }

  return references;
}

export async function getProductLensCommunities(db: CoreDbClient, input: ProductLens) {
  const product = requireProduct(await resolveProduct(db, input));
  return getCommunitiesForProduct(db, product.id);
}

export async function getProductLensNotifications(
  db: CoreDbClient,
  input: ProductLensNotificationsInput,
): Promise<ProductLensNotification[]> {
  const product = requireProduct(await resolveProduct(db, input));
  let query = db
    .from("notifications")
    .select("*")
    .order("created_at", { ascending: false })
    .limit(100);

  query = input.includeGlobal
    ? query.or(`product_id.eq.${product.id},product_id.is.null`)
    : query.eq("product_id", product.id);

  if (input.status) {
    query = query.eq("status", input.status);
  }

  const { data, error } = await query;

  if (error) {
    throw error;
  }

  return data ?? [];
}

export async function getProductLensEvaluationCases(
  db: CoreDbClient,
  input: ProductLensEvaluationCasesInput,
): Promise<ProductLensEvaluationCase[]> {
  const product = requireProduct(await resolveProduct(db, input));

  return getEvaluationCases(db, {
    productId: product.id,
    workspaceId: input.workspaceId,
    status: input.status,
  });
}

export async function getProductLensSummary(
  db: CoreDbClient,
  input: ProductLensSummaryInput,
): Promise<ProductLensSummary> {
  const product = requireProduct(await resolveProduct(db, input));
  const [
    inventory,
    publicReferences,
    communities,
    unreadNotifications,
    evaluationCases,
    entitlementFlags,
  ] = await Promise.all([
    input.workspaceId
      ? getProductLensInventory(db, {
          productId: product.id,
          workspaceId: input.workspaceId,
        })
      : Promise.resolve([]),
    getProductLensPublicReferences(db, { productId: product.id }),
    getProductLensCommunities(db, { productId: product.id }),
    getProductLensNotifications(db, { productId: product.id, status: "unread" }),
    input.workspaceId
      ? getProductLensEvaluationCases(db, {
          productId: product.id,
          workspaceId: input.workspaceId,
        })
      : Promise.resolve([]),
    getProductLensEntitlements(db, { productId: product.id }),
  ]);

  return {
    productId: product.id,
    inventoryCount: inventory.length,
    publicReferenceCount: publicReferences.length,
    communityCount: communities.length,
    unreadNotificationCount: unreadNotifications.length,
    evaluationCaseCount: evaluationCases.length,
    entitlementFlags,
  };
}
