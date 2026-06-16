import type {
  CoreDbClient,
  CreatePublicObjectReferenceInput,
  UpdatePublicObjectReferenceDisplayInput,
} from "./types";
import { BLOCKED_PUBLIC_REFERENCE_METADATA_KEYS as BLOCKED_KEYS } from "./types";

type PublicMetadata = Record<string, unknown>;

function containsBlockedMetadataKey(value: unknown): string | null {
  if (!value || typeof value !== "object") {
    return null;
  }

  if (Array.isArray(value)) {
    for (const item of value) {
      const blocked = containsBlockedMetadataKey(item);
      if (blocked) {
        return blocked;
      }
    }

    return null;
  }

  for (const [key, nestedValue] of Object.entries(value)) {
    const blockedKey = BLOCKED_KEYS.find(
      (blocked) => blocked.toLowerCase() === key.toLowerCase(),
    );

    if (blockedKey) {
      return blockedKey;
    }

    const nestedBlocked = containsBlockedMetadataKey(nestedValue);
    if (nestedBlocked) {
      return nestedBlocked;
    }
  }

  return null;
}

export function assertPublicReferenceMetadataSafe(
  metadata: PublicMetadata | null | undefined,
): void {
  const blockedKey = containsBlockedMetadataKey(metadata);

  if (blockedKey) {
    throw new Error(
      `Public reference metadata cannot include private field ${blockedKey}.`,
    );
  }
}

function requireReferenceId(data: string | { id?: string } | null): string {
  if (typeof data === "string" && data) {
    return data;
  }

  if (data && typeof data === "object" && typeof data.id === "string") {
    return data.id;
  }

  throw new Error("Public object reference RPC did not return an id.");
}

export async function createPublicObjectReference(
  db: CoreDbClient,
  input: CreatePublicObjectReferenceInput,
): Promise<string> {
  assertPublicReferenceMetadataSafe(input.publicMetadata);

  const { data, error } = await db.rpc("create_public_object_reference", {
    p_inventory_item_id: input.inventoryItemId,
    p_product_id: input.productId,
    p_visibility: input.visibility ?? "private_reference",
    p_created_for: input.createdFor ?? null,
    p_display_title: input.displayTitle ?? null,
    p_display_subtitle: input.displaySubtitle ?? null,
    p_display_label: input.displayLabel ?? null,
    p_display_image_url: input.displayImageUrl ?? null,
    p_condition_label: input.conditionLabel ?? null,
    p_grade_label: input.gradeLabel ?? null,
    p_value_label: input.valueLabel ?? null,
    p_value_snapshot_id: input.valueSnapshotId ?? null,
    p_public_metadata: input.publicMetadata ?? {},
  });

  if (error) {
    throw error;
  }

  return requireReferenceId(data);
}

export async function updatePublicObjectReferenceDisplay(
  db: CoreDbClient,
  input: UpdatePublicObjectReferenceDisplayInput,
): Promise<string> {
  assertPublicReferenceMetadataSafe(input.publicMetadata);

  const { data, error } = await db.rpc(
    "update_public_object_reference_display",
    {
      p_public_object_reference_id: input.publicObjectReferenceId,
      p_display_title: input.displayTitle ?? null,
      p_display_subtitle: input.displaySubtitle ?? null,
      p_display_label: input.displayLabel ?? null,
      p_display_image_url: input.displayImageUrl ?? null,
      p_condition_label: input.conditionLabel ?? null,
      p_grade_label: input.gradeLabel ?? null,
      p_value_label: input.valueLabel ?? null,
      p_value_snapshot_id: input.valueSnapshotId ?? null,
      p_public_metadata: input.publicMetadata ?? null,
    },
  );

  if (error) {
    throw error;
  }

  return requireReferenceId(data);
}

export async function revokePublicObjectReference(
  db: CoreDbClient,
  publicObjectReferenceId: string,
  reason?: string | null,
): Promise<string> {
  const { data, error } = await db.rpc("revoke_public_object_reference", {
    p_public_object_reference_id: publicObjectReferenceId,
    p_reason: reason ?? null,
  });

  if (error) {
    throw error;
  }

  return requireReferenceId(data);
}
