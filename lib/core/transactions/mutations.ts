import { assertOwnerContext } from "@/lib/core/inventory/mutations";
import type { CoreDbClient } from "@/lib/core/inventory/types";
import type {
  AtomicTransactionResult,
  CreateLotPurchaseTransactionInput,
  CreateLotPurchaseTransactionResult,
  NormalizedBasis,
  PurchaseTransactionInput,
  SaleTransactionInput,
  SaleTransactionResult,
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

function requireSaleRpcResult(
  data:
    | {
        transaction_id: string;
        inventory_item_id: string;
        gross_sale_price: number;
        selling_costs: number;
        net_proceeds: number;
        basis_at_sale: number;
        realized_profit_loss: number;
      }
    | {
        transaction_id: string;
        inventory_item_id: string;
        gross_sale_price: number;
        selling_costs: number;
        net_proceeds: number;
        basis_at_sale: number;
        realized_profit_loss: number;
      }[]
    | null,
): SaleTransactionResult {
  const row = Array.isArray(data) ? data[0] : data;

  if (!row?.transaction_id || !row.inventory_item_id) {
    throw new Error("Sale transaction RPC did not return sale details.");
  }

  return {
    transactionId: row.transaction_id,
    inventoryItemId: row.inventory_item_id,
    grossSalePrice: Number(row.gross_sale_price),
    sellingCosts: Number(row.selling_costs),
    netProceeds: Number(row.net_proceeds),
    basisAtSale: Number(row.basis_at_sale),
    realizedProfitLoss: Number(row.realized_profit_loss),
  };
}

function requireLotPurchaseRpcResult(
  data:
    | {
        transaction_id: string;
        inventory_item_ids: string[];
        total_lot_basis: number;
      }
    | {
        transaction_id: string;
        inventory_item_ids: string[];
        total_lot_basis: number;
      }[]
    | null,
): CreateLotPurchaseTransactionResult {
  const row = Array.isArray(data) ? data[0] : data;

  if (!row?.transaction_id) {
    throw new Error("Lot purchase transaction RPC did not return created IDs.");
  }

  return {
    transactionId: row.transaction_id,
    inventoryItemIds: row.inventory_item_ids ?? [],
    totalLotBasis: Number(row.total_lot_basis),
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

export async function createSaleTransaction(
  db: CoreDbClient,
  input: SaleTransactionInput,
): Promise<SaleTransactionResult> {
  assertOwnerContext(input);

  if (input.salePrice < 0) {
    throw new Error("Sale price cannot be negative.");
  }

  if (
    (input.platformFees ?? 0) < 0 ||
    (input.paymentProcessingFees ?? 0) < 0 ||
    (input.shippingCost ?? 0) < 0 ||
    (input.suppliesCost ?? 0) < 0 ||
    (input.consignmentFees ?? 0) < 0 ||
    (input.otherSellingCosts ?? 0) < 0
  ) {
    throw new Error("Sale fees and costs cannot be negative.");
  }

  const { data, error } = await db.rpc("create_sale_transaction", {
    p_inventory_item_id: input.inventoryItemId,
    p_sale_price: input.salePrice,
    p_platform_fees: input.platformFees ?? 0,
    p_payment_processing_fees: input.paymentProcessingFees ?? 0,
    p_shipping_cost: input.shippingCost ?? 0,
    p_supplies_cost: input.suppliesCost ?? 0,
    p_consignment_fees: input.consignmentFees ?? 0,
    p_other_selling_costs: input.otherSellingCosts ?? 0,
    p_owner_user_id: input.ownerUserId ?? null,
    p_workspace_id: input.workspaceId ?? null,
    p_organization_id: input.organizationId ?? null,
    p_transaction_date: input.transactionDate ?? null,
    p_source: input.source ?? null,
    p_counterparty: input.counterparty ?? null,
    p_notes: input.notes ?? null,
  });

  if (error) {
    throw error;
  }

  return requireSaleRpcResult(data);
}

export async function createLotPurchaseTransaction(
  db: CoreDbClient,
  input: CreateLotPurchaseTransactionInput,
): Promise<CreateLotPurchaseTransactionResult> {
  if (!input.workspaceId) {
    throw new Error("Lot purchase requires a workspace.");
  }

  if (!Array.isArray(input.items) || input.items.length === 0) {
    throw new Error("Lot purchase requires at least one item.");
  }

  if (
    input.purchasePrice < 0 ||
    (input.buyerFees ?? 0) < 0 ||
    (input.tax ?? 0) < 0 ||
    (input.shipping ?? 0) < 0 ||
    (input.otherAcquisitionCosts ?? 0) < 0
  ) {
    throw new Error("Lot purchase cost inputs cannot be negative.");
  }

  if (
    input.items.some(
      (item) =>
        !item.assetVariantId ||
        (item.allocatedBasis !== undefined && item.allocatedBasis < 0),
    )
  ) {
    throw new Error("Lot purchase items require valid nonnegative basis inputs.");
  }

  const { data, error } = await db.rpc("create_lot_purchase_transaction", {
    p_workspace_id: input.workspaceId,
    p_product_id: input.productId ?? null,
    p_purchase_price: input.purchasePrice,
    p_purchased_at: input.purchasedAt ?? null,
    p_seller_reference: input.sellerReference ?? null,
    p_marketplace: input.marketplace ?? null,
    p_order_reference: input.orderReference ?? null,
    p_buyer_fees: input.buyerFees ?? 0,
    p_tax: input.tax ?? 0,
    p_shipping: input.shipping ?? 0,
    p_other_acquisition_costs: input.otherAcquisitionCosts ?? 0,
    p_allocation_method: input.allocationMethod ?? "manual",
    p_items: input.items.map((item) => ({
      asset_variant_id: item.assetVariantId,
      condition_type: item.conditionType ?? "unknown",
      allocated_basis: item.allocatedBasis ?? null,
      collection_id: item.collectionId ?? null,
      location_id: item.locationId ?? null,
      acquisition_notes: item.acquisitionNotes ?? null,
      private_notes: item.privateNotes ?? null,
      inventory_status: item.inventoryStatus ?? "active",
      availability: item.availability ?? "available",
      intent: item.intent ?? "hold",
    })),
    p_notes: input.notes ?? null,
  });

  if (error) {
    throw error;
  }

  return requireLotPurchaseRpcResult(data);
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
