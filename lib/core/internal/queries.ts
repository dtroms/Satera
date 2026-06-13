import { createClient } from "@/lib/supabase/server";
import type { CompSnapshot } from "@/lib/core/comps/types";

export type InternalRecord = Record<string, any>;

const INVENTORY_SELECT = `
  *,
  category:categories(id, slug, name),
  asset_variant:asset_variants(id, name, variant_key),
  current_value_snapshot:comp_snapshots!inventory_items_current_value_snapshot_id_fkey(
    id,
    market_value,
    currency_code,
    observed_at
  )
`;

const TRANSACTION_SELECT = "*";
const COMP_SNAPSHOT_SELECT = "*";

function throwIfError(error: unknown): void {
  if (error) {
    throw error;
  }
}

export async function getInternalInventoryItems(): Promise<InternalRecord[]> {
  const db = await createClient();
  const { data, error } = await db
    .from("inventory_items")
    .select(INVENTORY_SELECT)
    .order("updated_at", { ascending: false })
    .limit(100);

  throwIfError(error);
  return data ?? [];
}

export async function getInternalInventoryItemById(
  id: string,
): Promise<InternalRecord | null> {
  const db = await createClient();
  const { data, error } = await db
    .from("inventory_items")
    .select(INVENTORY_SELECT)
    .eq("id", id)
    .maybeSingle();

  throwIfError(error);
  return data ?? null;
}

export async function getInternalTransactions(): Promise<InternalRecord[]> {
  const db = await createClient();
  const { data, error } = await db
    .from("transactions")
    .select(TRANSACTION_SELECT)
    .order("transaction_date", { ascending: false })
    .order("created_at", { ascending: false })
    .limit(100);

  throwIfError(error);
  return data ?? [];
}

export async function getInternalTransactionById(
  id: string,
): Promise<InternalRecord | null> {
  const db = await createClient();
  const { data, error } = await db
    .from("transactions")
    .select(TRANSACTION_SELECT)
    .eq("id", id)
    .maybeSingle();

  throwIfError(error);
  return data ?? null;
}

export async function getInternalOwnershipEventsForItem(
  inventoryItemId: string,
): Promise<InternalRecord[]> {
  const db = await createClient();
  const { data, error } = await db
    .from("ownership_events")
    .select("*, transaction:transactions(id, transaction_type, transaction_date)")
    .eq("inventory_item_id", inventoryItemId)
    .order("event_date", { ascending: true })
    .order("created_at", { ascending: true });

  throwIfError(error);
  return data ?? [];
}

export async function getInternalBasisEventsForItem(
  inventoryItemId: string,
): Promise<InternalRecord[]> {
  const db = await createClient();
  const { data, error } = await db
    .from("basis_events")
    .select("*, transaction:transactions(id, transaction_type, transaction_date)")
    .eq("inventory_item_id", inventoryItemId)
    .order("created_at", { ascending: true });

  throwIfError(error);
  return data ?? [];
}

export async function getInternalBasisLineageForItem(
  inventoryItemId: string,
): Promise<InternalRecord[]> {
  const db = await createClient();
  const { data, error } = await db
    .from("basis_lineage_edges")
    .select("*, transaction:transactions(id, transaction_type, transaction_date)")
    .or(
      `source_inventory_item_id.eq.${inventoryItemId},target_inventory_item_id.eq.${inventoryItemId}`,
    )
    .order("created_at", { ascending: true });

  throwIfError(error);
  return data ?? [];
}

export async function getInternalTransactionLinesForItem(
  inventoryItemId: string,
): Promise<InternalRecord[]> {
  const db = await createClient();
  const { data, error } = await db
    .from("transaction_lines")
    .select("*, transaction:transactions(id, transaction_type, transaction_date)")
    .eq("inventory_item_id", inventoryItemId)
    .order("created_at", { ascending: true });

  throwIfError(error);
  return data ?? [];
}

export async function getInternalCompSnapshotsForItem(
  inventoryItemId: string,
): Promise<CompSnapshot[]> {
  const db = await createClient();
  const { data, error } = await db
    .from("comp_snapshots")
    .select(COMP_SNAPSHOT_SELECT)
    .eq("inventory_item_id", inventoryItemId)
    .order("sale_date", { ascending: false, nullsFirst: false })
    .order("observed_at", { ascending: false });

  throwIfError(error);
  return (data ?? []) as CompSnapshot[];
}

export async function getInternalBasisLineageEdges(): Promise<InternalRecord[]> {
  const db = await createClient();
  const { data, error } = await db
    .from("basis_lineage_edges")
    .select("*")
    .order("created_at", { ascending: false })
    .limit(100);

  throwIfError(error);
  return data ?? [];
}

export async function getInternalAuditEvents(): Promise<InternalRecord[]> {
  const db = await createClient();
  const { data, error } = await db
    .from("audit_events")
    .select("*")
    .order("created_at", { ascending: false })
    .limit(100);

  throwIfError(error);
  return data ?? [];
}

export async function getInternalProducts(): Promise<InternalRecord[]> {
  const db = await createClient();
  const { data, error } = await db
    .from("products")
    .select("*")
    .order("slug", { ascending: true });

  throwIfError(error);
  return data ?? [];
}

export async function getInternalProductCategories(): Promise<InternalRecord[]> {
  const db = await createClient();
  const { data, error } = await db
    .from("product_categories")
    .select("*, product:products(id, slug, name), category:categories(id, slug, name)")
    .order("created_at", { ascending: true });

  throwIfError(error);
  return data ?? [];
}

export async function getInternalCategories(): Promise<InternalRecord[]> {
  const db = await createClient();
  const { data, error } = await db
    .from("categories")
    .select("*")
    .order("slug", { ascending: true });

  throwIfError(error);
  return data ?? [];
}

export async function getInternalAssetFamilies(): Promise<InternalRecord[]> {
  const db = await createClient();
  const { data, error } = await db
    .from("asset_families")
    .select("*, category:categories(id, slug, name), collection:collections(id, slug, name)")
    .order("created_at", { ascending: false })
    .limit(50);

  throwIfError(error);
  return data ?? [];
}

export async function getInternalAssetVariants(): Promise<InternalRecord[]> {
  const db = await createClient();
  const { data, error } = await db
    .from("asset_variants")
    .select("*, asset_family:asset_families(id, name), category:categories(id, slug, name)")
    .order("created_at", { ascending: false })
    .limit(100);

  throwIfError(error);
  return data ?? [];
}

export async function getInternalTransactionLinesForTransaction(
  transactionId: string,
): Promise<InternalRecord[]> {
  const db = await createClient();
  const { data, error } = await db
    .from("transaction_lines")
    .select("*, inventory_item:inventory_items(id, category_id, asset_variant_id)")
    .eq("transaction_id", transactionId)
    .order("created_at", { ascending: true });

  throwIfError(error);
  return data ?? [];
}

export async function getInternalOwnershipEventsForTransaction(
  transactionId: string,
): Promise<InternalRecord[]> {
  const db = await createClient();
  const { data, error } = await db
    .from("ownership_events")
    .select("*")
    .eq("transaction_id", transactionId)
    .order("event_date", { ascending: true })
    .order("created_at", { ascending: true });

  throwIfError(error);
  return data ?? [];
}

export async function getInternalBasisEventsForTransaction(
  transactionId: string,
): Promise<InternalRecord[]> {
  const db = await createClient();
  const { data, error } = await db
    .from("basis_events")
    .select("*")
    .eq("transaction_id", transactionId)
    .order("created_at", { ascending: true });

  throwIfError(error);
  return data ?? [];
}

export async function getInternalBasisLineageForTransaction(
  transactionId: string,
): Promise<InternalRecord[]> {
  const db = await createClient();
  const { data, error } = await db
    .from("basis_lineage_edges")
    .select("*")
    .eq("transaction_id", transactionId)
    .order("created_at", { ascending: true });

  throwIfError(error);
  return data ?? [];
}

export async function getInternalAuditEventsForEntity(
  entityTable: string,
  entityId: string,
): Promise<InternalRecord[]> {
  const db = await createClient();
  const { data, error } = await db
    .from("audit_events")
    .select("*")
    .eq("entity_table", entityTable)
    .eq("entity_id", entityId)
    .order("created_at", { ascending: true });

  throwIfError(error);
  return data ?? [];
}
