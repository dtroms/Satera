import { assertOwnerContext } from "@/lib/core/inventory/mutations";
import type { CoreDbClient } from "@/lib/core/inventory/types";
import type {
  AtomicTransactionResult,
  NormalizedBasis,
  PurchaseTransactionInput,
  StartingInventoryBasis,
  StartingInventoryTransactionInput,
  TradeTransactionInput,
  TradeTransactionResult,
} from "./types";

export function normalizeInitialBasis(
  initialBasis: StartingInventoryBasis,
): NormalizedBasis {
  if (initialBasis === undefined || initialBasis === null) {
    return { basisProvided: false, trueBasis: null };
  }

  if (initialBasis < 0) {
    throw new Error("Initial basis cannot be negative.");
  }

  return { basisProvided: true, trueBasis: initialBasis };
}

function requireRpcResult(
  data:
    | { inventory_item_id: string; transaction_id: string }
    | { inventory_item_id: string; transaction_id: string }[]
    | null,
): AtomicTransactionResult {
  const row = Array.isArray(data) ? data[0] : data;

  if (!row?.inventory_item_id || !row.transaction_id) {
    throw new Error("Transaction RPC did not return created IDs.");
  }

  return {
    inventoryItemId: row.inventory_item_id,
    transactionId: row.transaction_id,
  };
}

function requireTradeRpcResult(
  data:
    | {
        transaction_id: string;
        incoming_inventory_item_ids: string[];
        outgoing_inventory_item_ids: string[];
      }
    | {
        transaction_id: string;
        incoming_inventory_item_ids: string[];
        outgoing_inventory_item_ids: string[];
      }[]
    | null,
): TradeTransactionResult {
  const row = Array.isArray(data) ? data[0] : data;

  if (!row?.transaction_id) {
    throw new Error("Trade transaction RPC did not return created IDs.");
  }

  return {
    transactionId: row.transaction_id,
    incomingInventoryItemIds: row.incoming_inventory_item_ids ?? [],
    outgoingInventoryItemIds: row.outgoing_inventory_item_ids ?? [],
  };
}

export async function createStartingInventoryTransaction(
  db: CoreDbClient,
  input: StartingInventoryTransactionInput,
): Promise<AtomicTransactionResult> {
  assertOwnerContext(input);

  // Keep local validation for fast feedback; the RPC is the atomic source of truth.
  normalizeInitialBasis(input.initialBasis);

  const { data, error } = await db.rpc("create_starting_inventory_transaction", {
    p_owner_user_id: input.ownerUserId ?? null,
    p_workspace_id: input.workspaceId ?? null,
    p_organization_id: input.organizationId ?? null,
    p_category_id: input.categoryId,
    p_asset_variant_id: input.assetVariantId,
    p_condition_type: input.conditionType ?? "unknown",
    p_status: input.status ?? "active",
    p_availability: input.availability ?? "available",
    p_intent: input.intent ?? "hold",
    p_location_id: input.locationId ?? null,
    p_initial_basis: input.initialBasis ?? null,
    p_acquired_at: input.acquiredAt ?? null,
    p_notes: input.notes ?? null,
    p_transaction_date: input.transactionDate ?? null,
    p_source: input.source ?? null,
  });

  if (error) {
    throw error;
  }

  return requireRpcResult(data);
}

export async function createPurchaseTransaction(
  db: CoreDbClient,
  input: PurchaseTransactionInput,
): Promise<AtomicTransactionResult> {
  assertOwnerContext(input);

  const { data, error } = await db.rpc("create_purchase_transaction", {
    p_owner_user_id: input.ownerUserId ?? null,
    p_workspace_id: input.workspaceId ?? null,
    p_organization_id: input.organizationId ?? null,
    p_category_id: input.categoryId,
    p_asset_variant_id: input.assetVariantId,
    p_condition_type: input.conditionType ?? "unknown",
    p_status: input.status ?? "active",
    p_availability: input.availability ?? "available",
    p_intent: input.intent ?? "hold",
    p_location_id: input.locationId ?? null,
    p_purchase_price: input.purchaseBasis.purchasePrice,
    p_buyer_fees: input.purchaseBasis.buyerFees ?? 0,
    p_tax: input.purchaseBasis.tax ?? 0,
    p_shipping: input.purchaseBasis.shipping ?? 0,
    p_direct_acquisition_costs: input.purchaseBasis.directAcquisitionCosts ?? 0,
    p_acquired_at: input.acquiredAt ?? null,
    p_notes: input.notes ?? null,
    p_transaction_date: input.transactionDate ?? null,
    p_source: input.source ?? null,
    p_counterparty: input.counterparty ?? null,
  });

  if (error) {
    throw error;
  }

  return requireRpcResult(data);
}

export async function createTradeTransaction(
  db: CoreDbClient,
  input: TradeTransactionInput,
): Promise<TradeTransactionResult> {
  assertOwnerContext(input);

  const { data, error } = await db.rpc("create_trade_transaction", {
    p_owner_user_id: input.ownerUserId ?? null,
    p_workspace_id: input.workspaceId ?? null,
    p_organization_id: input.organizationId ?? null,
    p_transaction_date: input.transactionDate ?? null,
    p_source: input.source ?? null,
    p_counterparty: input.counterparty ?? null,
    p_notes: input.notes ?? null,
    p_outgoing_items: input.outgoingItems.map((item) => ({
      inventory_item_id: item.inventoryItemId,
      trade_value: item.tradeValue,
    })),
    p_incoming_items: input.incomingItems.map((item) => ({
      category_id: item.categoryId,
      asset_variant_id: item.assetVariantId,
      condition_type: item.conditionType ?? "unknown",
      status: item.status ?? "active",
      availability: item.availability ?? "available",
      intent: item.intent ?? "hold",
      location_id: item.locationId ?? null,
      trade_value: item.tradeValue,
      notes: item.notes ?? null,
    })),
    p_cash_paid: input.cashPaid ?? 0,
    p_cash_received: input.cashReceived ?? 0,
    p_trade_related_costs: input.tradeRelatedCosts ?? 0,
  });

  if (error) {
    throw error;
  }

  return requireTradeRpcResult(data);
}
