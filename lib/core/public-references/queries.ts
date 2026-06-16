import type {
  CoreDbClient,
  PublicObjectReference,
  PublicObjectReferenceOwnerContext,
} from "./types";

const PUBLIC_OBJECT_REFERENCE_SELECT = "*";

function ownerContextOrFilter(
  context: PublicObjectReferenceOwnerContext,
): string {
  const filters = [
    context.ownerUserId ? `owner_user_id.eq.${context.ownerUserId}` : null,
    context.workspaceId ? `workspace_id.eq.${context.workspaceId}` : null,
    context.organizationId
      ? `organization_id.eq.${context.organizationId}`
      : null,
  ].filter(Boolean);

  if (filters.length === 0) {
    throw new Error("At least one owner context is required.");
  }

  return filters.join(",");
}

export async function getPublicObjectReferenceById(
  db: CoreDbClient,
  publicObjectReferenceId: string,
): Promise<PublicObjectReference | null> {
  const { data, error } = await db
    .from("public_object_references")
    .select(PUBLIC_OBJECT_REFERENCE_SELECT)
    .eq("id", publicObjectReferenceId)
    .maybeSingle();

  if (error) {
    throw error;
  }

  return data ?? null;
}

export async function getPublicObjectReferencesForInventoryItem(
  db: CoreDbClient,
  inventoryItemId: string,
): Promise<PublicObjectReference[]> {
  const { data, error } = await db
    .from("public_object_references")
    .select(PUBLIC_OBJECT_REFERENCE_SELECT)
    .eq("inventory_item_id", inventoryItemId)
    .order("created_at", { ascending: false });

  if (error) {
    throw error;
  }

  return data ?? [];
}

export async function getPublicObjectReferencesForProduct(
  db: CoreDbClient,
  productId: string,
): Promise<PublicObjectReference[]> {
  const { data, error } = await db
    .from("public_object_references")
    .select(PUBLIC_OBJECT_REFERENCE_SELECT)
    .eq("product_id", productId)
    .eq("exposure_state", "active")
    .in("visibility", ["community", "listing", "showcase", "trade", "public"])
    .order("created_at", { ascending: false });

  if (error) {
    throw error;
  }

  return data ?? [];
}

export async function getOwnedPublicObjectReferences(
  db: CoreDbClient,
  context: PublicObjectReferenceOwnerContext,
): Promise<PublicObjectReference[]> {
  const { data, error } = await db
    .from("public_object_references")
    .select(PUBLIC_OBJECT_REFERENCE_SELECT)
    .or(ownerContextOrFilter(context))
    .order("created_at", { ascending: false });

  if (error) {
    throw error;
  }

  return data ?? [];
}
