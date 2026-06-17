import { describe, expect, it, vi } from "vitest";
import type { InventoryItem } from "@/lib/core/inventory/types";
import {
  createInventoryItem,
  sanitizeSafeInventoryUpdate,
  updateInventoryItemSafeFields,
} from "@/lib/core/inventory/mutations";
import { filterInventoryByCategoryIds } from "@/lib/core/products/queries";
import { buildPortfolioSummary } from "@/lib/core/portfolio/queries";
import { calculatePurchaseBasis } from "@/lib/calculations/basis";
import {
  createLotPurchaseTransaction,
  createPurchaseTransaction,
  createSaleTransaction,
  createStartingInventoryTransaction,
  createTradeTransaction,
  normalizeInitialBasis,
} from "@/lib/core/transactions/mutations";
import {
  assertPublicReferenceMetadataSafe,
  createPublicObjectReference,
  revokePublicObjectReference,
  updatePublicObjectReferenceDisplay,
} from "@/lib/core/public-references/mutations";
import {
  addModerationNote,
  createCommunity,
  createCommunityChannel,
  createCommunityMessage,
  joinCommunity,
  liftUserRestriction,
  moderateCommunityContent,
  reportCommunityContent,
  submitModerationAppeal,
} from "@/lib/core/community/mutations";
import type { CreateCommunityMessageInput } from "@/lib/core/community/types";
import {
  archiveNotification,
  assertNotificationMetadataSafe,
  createNotificationEvent,
  dismissNotification,
  markNotificationRead,
  markNotificationsRead,
} from "@/lib/core/notifications/mutations";
import {
  getNotificationById,
  getNotificationDeliveryAttempts,
  getNotificationEvents,
  getNotificationsForCurrentUser,
  getUnreadNotificationsForCurrentUser,
} from "@/lib/core/notifications/queries";
import {
  getProductLensCommunities,
  getProductLensEvaluationCases,
  getProductLensInventory,
  getProductLensNotifications,
  getProductLensPublicReferences,
  getProductLensSummary,
} from "@/lib/core/product-lens/queries";
import {
  addEvaluationCaseItem,
  applyEvaluationBasisIncrease,
  createEvaluationCase,
  recordEvaluationResult,
  updateEvaluationCaseStatus,
} from "@/lib/core/evaluations/mutations";

function inventoryItem(
  overrides: Partial<InventoryItem> & { id: string },
): InventoryItem {
  const { id, ...rest } = overrides;

  return {
    id,
    owner_user_id: "user-1",
    workspace_id: null,
    organization_id: null,
    category_id: "category-1",
    asset_variant_id: "variant-1",
    condition_type: "raw",
    status: "active",
    availability: "available",
    intent: "hold",
    location_id: null,
    true_basis: null,
    current_value_snapshot_id: null,
    acquired_at: null,
    notes: null,
    created_by: "user-1",
    updated_by: "user-1",
    created_at: "2026-01-01T00:00:00.000Z",
    updated_at: "2026-01-01T00:00:00.000Z",
    ...rest,
  };
}

function createRpcMockDb() {
  const rpc = vi.fn().mockResolvedValue({
    data: [
      {
        inventory_item_id: "inventory-1",
        transaction_id: "transaction-1",
      },
    ],
    error: null,
  });

  return {
    rpc,
    db: {
      from: vi.fn(),
      rpc,
    },
  };
}

function createSelectMockDb(data: unknown[] = []) {
  const query: any = {
    select: vi.fn(() => query),
    eq: vi.fn(() => query),
    in: vi.fn(() => query),
    or: vi.fn(() => query),
    order: vi.fn(() => query),
    limit: vi.fn(() => query),
    maybeSingle: vi.fn(() => Promise.resolve({ data: data[0] ?? null, error: null })),
    then: (resolve: (value: unknown) => unknown) =>
      Promise.resolve({ data, error: null }).then(resolve),
  };
  const from = vi.fn(() => query);

  return { db: { from, rpc: vi.fn() }, from, query };
}

function createProductLensMockDb(tableRows: Record<string, any[]>) {
  const queries: Record<string, any[]> = {};

  function createQuery(table: string) {
    const filters: Array<{ column: string; value: unknown }> = [];
    const inFilters: Array<{ column: string; values: unknown[] }> = [];

    const applyFilters = () =>
      (tableRows[table] ?? []).filter((row) => {
        const matchesEq = filters.every((filter) => row[filter.column] === filter.value);
        const matchesIn = inFilters.every((filter) =>
          filter.values.includes(row[filter.column]),
        );

        return matchesEq && matchesIn;
      });

    const query: any = {
      table,
      filters,
      select: vi.fn(() => query),
      eq: vi.fn((column: string, value: unknown) => {
        filters.push({ column, value });
        return query;
      }),
      in: vi.fn((column: string, values: unknown[]) => {
        inFilters.push({ column, values });
        return query;
      }),
      or: vi.fn(() => query),
      order: vi.fn(() => query),
      limit: vi.fn(() => query),
      maybeSingle: vi.fn(() =>
        Promise.resolve({ data: applyFilters()[0] ?? null, error: null }),
      ),
      then: (resolve: (value: unknown) => unknown) =>
        Promise.resolve({ data: applyFilters(), error: null }).then(resolve),
    };

    queries[table] = [...(queries[table] ?? []), query];
    return query;
  }

  const from = vi.fn((table: string) => createQuery(table));
  const rpc = vi.fn().mockResolvedValue({ data: true, error: null });

  return { db: { from, rpc }, from, rpc, queries };
}

describe("inventory service protections", () => {
  it("direct inventory creation is disabled", async () => {
    await expect(
      createInventoryItem(
        { from: vi.fn(), rpc: vi.fn() },
        {
          ownerUserId: "user-1",
          categoryId: "category-1",
          assetVariantId: "variant-1",
          createdBy: "user-1",
        },
      ),
    ).rejects.toThrow(
      "Direct inventory creation is disabled. Use a transaction workflow instead.",
    );
  });

  it("safe inventory update rejects true_basis mutation", () => {
    expect(() =>
      sanitizeSafeInventoryUpdate({
        notes: "allowed",
        true_basis: 100,
      }),
    ).toThrow("Direct inventory mutation of true_basis is not allowed.");
  });

  it("safe inventory update keeps only allowed fields", () => {
    expect(
      sanitizeSafeInventoryUpdate({
        notes: "new note",
        intent: "sell",
        location_id: "location-1",
        availability: "committed",
        ignored_field: "ignored",
      }),
    ).toEqual({
      notes: "new note",
      intent: "sell",
      location_id: "location-1",
      availability: "committed",
    });
  });

  it("safe inventory update calls the RPC with allowed fields", async () => {
    const rpc = vi.fn().mockResolvedValue({
      data: inventoryItem({
        id: "inventory-1",
        notes: "new note",
        intent: "sell",
        location_id: "location-1",
        availability: "committed",
      }),
      error: null,
    });
    const db = { from: vi.fn(), rpc };

    await updateInventoryItemSafeFields(
      db,
      "inventory-1",
      {
        notes: "new note",
        intent: "sell",
        location_id: "location-1",
        availability: "committed",
        ignored_field: "ignored",
      },
      "user-1",
    );

    expect(rpc).toHaveBeenCalledWith("update_inventory_item_safe_fields", {
      p_target_inventory_item_id: "inventory-1",
      p_new_notes: "new note",
      p_new_intent: "sell",
      p_new_location_id: "location-1",
      p_new_availability: "committed",
      p_update_notes: true,
      p_update_intent: true,
      p_update_location_id: true,
      p_update_availability: true,
    });
  });

  it("safe inventory update rejects blocked fields before RPC call", async () => {
    const rpc = vi.fn();
    const db = { from: vi.fn(), rpc };

    await expect(
      updateInventoryItemSafeFields(
        db,
        "inventory-1",
        { notes: "allowed", true_basis: 100 },
        "user-1",
      ),
    ).rejects.toThrow("Direct inventory mutation of true_basis is not allowed.");

    expect(rpc).not.toHaveBeenCalled();
  });
});

describe("transaction service basis rules", () => {
  it("service preserves missing starting basis and calls the atomic RPC", async () => {
    expect(normalizeInitialBasis(undefined)).toEqual({
      basisProvided: false,
      trueBasis: null,
    });
    expect(normalizeInitialBasis(null)).toEqual({
      basisProvided: false,
      trueBasis: null,
    });

    const { db, rpc } = createRpcMockDb();

    await expect(
      createStartingInventoryTransaction(db, {
      ownerUserId: "user-1",
      categoryId: "category-1",
      assetVariantId: "variant-1",
      transactionDate: "2026-01-01T00:00:00.000Z",
      createdBy: "user-1",
      }),
    ).resolves.toEqual({
      inventoryItemId: "inventory-1",
      transactionId: "transaction-1",
    });

    expect(rpc).toHaveBeenCalledWith("create_starting_inventory_transaction", {
      p_owner_user_id: "user-1",
      p_workspace_id: null,
      p_organization_id: null,
      p_category_id: "category-1",
      p_asset_variant_id: "variant-1",
      p_condition_type: "unknown",
      p_status: "active",
      p_availability: "available",
      p_intent: "hold",
      p_location_id: null,
      p_initial_basis: null,
      p_acquired_at: null,
      p_notes: null,
      p_transaction_date: "2026-01-01T00:00:00.000Z",
      p_source: null,
    });
  });

  it("service preserves zero starting basis and calls the atomic RPC", async () => {
    expect(normalizeInitialBasis(0)).toEqual({
      basisProvided: true,
      trueBasis: 0,
    });

    const { db, rpc } = createRpcMockDb();

    await createStartingInventoryTransaction(db, {
      ownerUserId: "user-1",
      categoryId: "category-1",
      assetVariantId: "variant-1",
      transactionDate: "2026-01-01T00:00:00.000Z",
      initialBasis: 0,
      createdBy: "user-1",
    });

    expect(rpc).toHaveBeenCalledWith(
      "create_starting_inventory_transaction",
      expect.objectContaining({
        p_initial_basis: 0,
      }),
    );
  });

  it("purchase transaction calls the atomic RPC with basis inputs", async () => {
    expect(
      calculatePurchaseBasis({
        purchasePrice: 100,
        buyerFees: 5,
        tax: 8,
        shipping: 7,
        directAcquisitionCosts: 10,
      }),
    ).toBe(130);

    const { db, rpc } = createRpcMockDb();

    await expect(
      createPurchaseTransaction(db, {
      ownerUserId: "user-1",
      categoryId: "category-1",
      assetVariantId: "variant-1",
      transactionDate: "2026-01-01T00:00:00.000Z",
      marketValueAtTime: 999,
      purchaseBasis: {
        purchasePrice: 100,
        buyerFees: 5,
        tax: 8,
        shipping: 7,
        directAcquisitionCosts: 10,
      },
      createdBy: "user-1",
      }),
    ).resolves.toEqual({
      inventoryItemId: "inventory-1",
      transactionId: "transaction-1",
    });

    expect(rpc).toHaveBeenCalledWith("create_purchase_transaction", {
      p_owner_user_id: "user-1",
      p_workspace_id: null,
      p_organization_id: null,
      p_category_id: "category-1",
      p_asset_variant_id: "variant-1",
      p_condition_type: "unknown",
      p_status: "active",
      p_availability: "available",
      p_intent: "hold",
      p_location_id: null,
      p_purchase_price: 100,
      p_buyer_fees: 5,
      p_tax: 8,
      p_shipping: 7,
      p_direct_acquisition_costs: 10,
      p_acquired_at: null,
      p_notes: null,
      p_transaction_date: "2026-01-01T00:00:00.000Z",
      p_source: null,
      p_counterparty: null,
    });
  });

  it("trade transaction calls the atomic RPC with trade payloads", async () => {
    const rpc = vi.fn().mockResolvedValue({
      data: [
        {
          transaction_id: "trade-transaction-1",
          incoming_inventory_item_ids: ["incoming-1"],
          outgoing_inventory_item_ids: ["outgoing-1"],
        },
      ],
      error: null,
    });
    const db = { from: vi.fn(), rpc };

    await expect(
      createTradeTransaction(db, {
        ownerUserId: "user-1",
        transactionDate: "2026-01-01T00:00:00.000Z",
        source: "manual",
        counterparty: "Trade partner",
        notes: "Trade note",
        outgoingItems: [{ inventoryItemId: "outgoing-1", tradeValue: 125 }],
        incomingItems: [
          {
            categoryId: "category-1",
            assetVariantId: "variant-2",
            conditionType: "raw",
            tradeValue: 175,
            notes: "Incoming note",
          },
        ],
        cashPaid: 25,
        cashReceived: 0,
        tradeRelatedCosts: 5,
        createdBy: "user-1",
      }),
    ).resolves.toEqual({
      transactionId: "trade-transaction-1",
      incomingInventoryItemIds: ["incoming-1"],
      outgoingInventoryItemIds: ["outgoing-1"],
    });

    expect(rpc).toHaveBeenCalledWith("create_trade_transaction", {
      p_owner_user_id: "user-1",
      p_workspace_id: null,
      p_organization_id: null,
      p_transaction_date: "2026-01-01T00:00:00.000Z",
      p_source: "manual",
      p_counterparty: "Trade partner",
      p_notes: "Trade note",
      p_outgoing_items: [
        { inventory_item_id: "outgoing-1", trade_value: 125 },
      ],
      p_incoming_items: [
        {
          category_id: "category-1",
          asset_variant_id: "variant-2",
          condition_type: "raw",
          status: "active",
          availability: "available",
          intent: "hold",
          location_id: null,
          trade_value: 175,
          notes: "Incoming note",
        },
      ],
      p_cash_paid: 25,
      p_cash_received: 0,
      p_trade_related_costs: 5,
    });
  });

  it("sale transaction calls the atomic RPC with sale math inputs", async () => {
    const rpc = vi.fn().mockResolvedValue({
      data: [
        {
          transaction_id: "sale-transaction-1",
          inventory_item_id: "inventory-1",
          gross_sale_price: 200,
          selling_costs: 25,
          net_proceeds: 175,
          basis_at_sale: 130,
          realized_profit_loss: 45,
        },
      ],
      error: null,
    });
    const db = { from: vi.fn(), rpc };

    await expect(
      createSaleTransaction(db, {
        ownerUserId: "user-1",
        inventoryItemId: "inventory-1",
        salePrice: 200,
        platformFees: 10,
        paymentProcessingFees: 3,
        shippingCost: 5,
        suppliesCost: 2,
        consignmentFees: 4,
        otherSellingCosts: 1,
        transactionDate: "2026-01-01T00:00:00.000Z",
        source: "manual",
        counterparty: "Buyer",
        notes: "Sale note",
        createdBy: "user-1",
      }),
    ).resolves.toEqual({
      transactionId: "sale-transaction-1",
      inventoryItemId: "inventory-1",
      grossSalePrice: 200,
      sellingCosts: 25,
      netProceeds: 175,
      basisAtSale: 130,
      realizedProfitLoss: 45,
    });

    expect(rpc).toHaveBeenCalledWith("create_sale_transaction", {
      p_inventory_item_id: "inventory-1",
      p_sale_price: 200,
      p_platform_fees: 10,
      p_payment_processing_fees: 3,
      p_shipping_cost: 5,
      p_supplies_cost: 2,
      p_consignment_fees: 4,
      p_other_selling_costs: 1,
      p_owner_user_id: "user-1",
      p_workspace_id: null,
      p_organization_id: null,
      p_transaction_date: "2026-01-01T00:00:00.000Z",
      p_source: "manual",
      p_counterparty: "Buyer",
      p_notes: "Sale note",
    });
    expect(db.from).not.toHaveBeenCalled();
  });

  it("sale transaction rejects negative sale inputs before RPC", async () => {
    const rpc = vi.fn();
    const db = { from: vi.fn(), rpc };

    await expect(
      createSaleTransaction(db, {
        ownerUserId: "user-1",
        inventoryItemId: "inventory-1",
        salePrice: -1,
        createdBy: "user-1",
      }),
    ).rejects.toThrow("Sale price cannot be negative.");

    await expect(
      createSaleTransaction(db, {
        ownerUserId: "user-1",
        inventoryItemId: "inventory-1",
        salePrice: 10,
        platformFees: -1,
        createdBy: "user-1",
      }),
    ).rejects.toThrow("Sale fees and costs cannot be negative.");

    expect(rpc).not.toHaveBeenCalled();
  });

  it("lot purchase transaction calls the atomic RPC with item payloads", async () => {
    const rpc = vi.fn().mockResolvedValue({
      data: [
        {
          transaction_id: "lot-transaction-1",
          inventory_item_ids: ["inventory-1", "inventory-2"],
          total_lot_basis: 130,
        },
      ],
      error: null,
    });
    const db = { from: vi.fn(), rpc };

    await expect(
      createLotPurchaseTransaction(db, {
        workspaceId: "workspace-1",
        productId: "product-1",
        purchasePrice: 100,
        purchasedAt: "2026-01-01T00:00:00.000Z",
        sellerReference: "Seller",
        marketplace: "manual",
        orderReference: "ORDER-1",
        buyerFees: 5,
        tax: 8,
        shipping: 7,
        otherAcquisitionCosts: 10,
        allocationMethod: "manual",
        items: [
          {
            assetVariantId: "variant-1",
            conditionType: "raw",
            allocatedBasis: 60,
            acquisitionNotes: "First item",
          },
          {
            assetVariantId: "variant-2",
            conditionType: "sealed",
            allocatedBasis: 70,
            locationId: "location-1",
            inventoryStatus: "active",
            availability: "available",
            intent: "hold",
          },
        ],
        notes: "Lot note",
        createdBy: "user-1",
      }),
    ).resolves.toEqual({
      transactionId: "lot-transaction-1",
      inventoryItemIds: ["inventory-1", "inventory-2"],
      totalLotBasis: 130,
    });

    expect(rpc).toHaveBeenCalledWith("create_lot_purchase_transaction", {
      p_workspace_id: "workspace-1",
      p_product_id: "product-1",
      p_purchase_price: 100,
      p_purchased_at: "2026-01-01T00:00:00.000Z",
      p_seller_reference: "Seller",
      p_marketplace: "manual",
      p_order_reference: "ORDER-1",
      p_buyer_fees: 5,
      p_tax: 8,
      p_shipping: 7,
      p_other_acquisition_costs: 10,
      p_allocation_method: "manual",
      p_items: [
        {
          asset_variant_id: "variant-1",
          condition_type: "raw",
          allocated_basis: 60,
          collection_id: null,
          location_id: null,
          acquisition_notes: "First item",
          private_notes: null,
          inventory_status: "active",
          availability: "available",
          intent: "hold",
        },
        {
          asset_variant_id: "variant-2",
          condition_type: "sealed",
          allocated_basis: 70,
          collection_id: null,
          location_id: "location-1",
          acquisition_notes: null,
          private_notes: null,
          inventory_status: "active",
          availability: "available",
          intent: "hold",
        },
      ],
      p_notes: "Lot note",
    });
    expect(db.from).not.toHaveBeenCalled();
  });

  it("lot purchase transaction defaults optional numeric fields and equal allocation", async () => {
    const rpc = vi.fn().mockResolvedValue({
      data: {
        transaction_id: "lot-transaction-1",
        inventory_item_ids: ["inventory-1"],
        total_lot_basis: 10,
      },
      error: null,
    });
    const db = { from: vi.fn(), rpc };

    await createLotPurchaseTransaction(db, {
      workspaceId: "workspace-1",
      purchasePrice: 10,
      allocationMethod: "equal",
      items: [{ assetVariantId: "variant-1" }],
      createdBy: "user-1",
    });

    expect(rpc).toHaveBeenCalledWith(
      "create_lot_purchase_transaction",
      expect.objectContaining({
        p_buyer_fees: 0,
        p_tax: 0,
        p_shipping: 0,
        p_other_acquisition_costs: 0,
        p_allocation_method: "equal",
        p_items: [
          expect.objectContaining({
            asset_variant_id: "variant-1",
            allocated_basis: null,
          }),
        ],
      }),
    );
    expect(db.from).not.toHaveBeenCalled();
  });

  it("lot purchase transaction rejects invalid inputs before RPC", async () => {
    const rpc = vi.fn();
    const db = { from: vi.fn(), rpc };

    await expect(
      createLotPurchaseTransaction(db, {
        workspaceId: "workspace-1",
        purchasePrice: -1,
        items: [{ assetVariantId: "variant-1", allocatedBasis: 0 }],
        createdBy: "user-1",
      }),
    ).rejects.toThrow("Lot purchase cost inputs cannot be negative.");

    await expect(
      createLotPurchaseTransaction(db, {
        workspaceId: "workspace-1",
        purchasePrice: 1,
        items: [],
        createdBy: "user-1",
      }),
    ).rejects.toThrow("Lot purchase requires at least one item.");

    await expect(
      createLotPurchaseTransaction(db, {
        workspaceId: "workspace-1",
        purchasePrice: 1,
        items: [{ assetVariantId: "variant-1", allocatedBasis: -1 }],
        createdBy: "user-1",
      }),
    ).rejects.toThrow("Lot purchase items require valid nonnegative basis inputs.");

    expect(rpc).not.toHaveBeenCalled();
  });
});

describe("public object reference service protections", () => {
  it("rejects private fields in public metadata", () => {
    expect(() =>
      assertPublicReferenceMetadataSafe({
        display: "safe",
        nested: { true_basis: 100 },
      }),
    ).toThrow(
      "Public reference metadata cannot include private field true_basis.",
    );

    expect(() =>
      assertPublicReferenceMetadataSafe({
        safe_context: "community attachment",
      }),
    ).not.toThrow();
  });

  it("create public reference calls the RPC and not direct table writes", async () => {
    const rpc = vi.fn().mockResolvedValue({
      data: "public-reference-1",
      error: null,
    });
    const db = { from: vi.fn(), rpc };

    await expect(
      createPublicObjectReference(db, {
        inventoryItemId: "inventory-1",
        productId: "product-1",
        visibility: "community",
        createdFor: "test",
        displayTitle: "Safe title",
        publicMetadata: { safe_context: "test" },
      }),
    ).resolves.toBe("public-reference-1");

    expect(rpc).toHaveBeenCalledWith("create_public_object_reference", {
      p_inventory_item_id: "inventory-1",
      p_product_id: "product-1",
      p_visibility: "community",
      p_created_for: "test",
      p_display_title: "Safe title",
      p_display_subtitle: null,
      p_display_label: null,
      p_display_image_url: null,
      p_condition_label: null,
      p_grade_label: null,
      p_value_label: null,
      p_value_snapshot_id: null,
      p_public_metadata: { safe_context: "test" },
    });
    expect(db.from).not.toHaveBeenCalled();
  });

  it("update public reference display calls the RPC and not direct table writes", async () => {
    const rpc = vi.fn().mockResolvedValue({
      data: "public-reference-1",
      error: null,
    });
    const db = { from: vi.fn(), rpc };

    await updatePublicObjectReferenceDisplay(db, {
      publicObjectReferenceId: "public-reference-1",
      displayTitle: "Updated title",
      displayLabel: "Updated label",
    });

    expect(rpc).toHaveBeenCalledWith(
      "update_public_object_reference_display",
      {
        p_public_object_reference_id: "public-reference-1",
        p_display_title: "Updated title",
        p_display_subtitle: null,
        p_display_label: "Updated label",
        p_display_image_url: null,
        p_condition_label: null,
        p_grade_label: null,
        p_value_label: null,
        p_value_snapshot_id: null,
        p_public_metadata: null,
      },
    );
    expect(db.from).not.toHaveBeenCalled();
  });

  it("revoke public reference calls the RPC and not direct table writes", async () => {
    const rpc = vi.fn().mockResolvedValue({
      data: "public-reference-1",
      error: null,
    });
    const db = { from: vi.fn(), rpc };

    await revokePublicObjectReference(db, "public-reference-1", "test");

    expect(rpc).toHaveBeenCalledWith("revoke_public_object_reference", {
      p_public_object_reference_id: "public-reference-1",
      p_reason: "test",
    });
    expect(db.from).not.toHaveBeenCalled();
  });
});

describe("community service protections", () => {
  it("community creation calls the RPC and not direct table writes", async () => {
    const rpc = vi.fn().mockResolvedValue({ data: "community-1", error: null });
    const db = { from: vi.fn(), rpc };

    await expect(
      createCommunity(db, {
        productId: "product-1",
        ownerUserId: "user-1",
        name: "Collectors",
        slug: "collectors",
        description: "A safe community",
        communityType: "collector_group",
        visibility: "private",
      }),
    ).resolves.toBe("community-1");

    expect(rpc).toHaveBeenCalledWith("create_community", {
      p_product_id: "product-1",
      p_organization_id: null,
      p_workspace_id: null,
      p_owner_user_id: "user-1",
      p_name: "Collectors",
      p_slug: "collectors",
      p_description: "A safe community",
      p_community_type: "collector_group",
      p_visibility: "private",
    });
    expect(db.from).not.toHaveBeenCalled();
  });

  it("community channel creation calls the RPC and not direct table writes", async () => {
    const rpc = vi.fn().mockResolvedValue({ data: "channel-1", error: null });
    const db = { from: vi.fn(), rpc };

    await createCommunityChannel(db, {
      communityId: "community-1",
      name: "General",
      slug: "general",
      channelType: "conversation",
      visibility: "community",
      sortOrder: 10,
    });

    expect(rpc).toHaveBeenCalledWith("create_community_channel", {
      p_community_id: "community-1",
      p_name: "General",
      p_slug: "general",
      p_description: null,
      p_channel_type: "conversation",
      p_visibility: "community",
      p_sort_order: 10,
    });
    expect(db.from).not.toHaveBeenCalled();
  });

  it("joining a community calls the RPC and not direct table writes", async () => {
    const rpc = vi.fn().mockResolvedValue({ data: "membership-1", error: null });
    const db = { from: vi.fn(), rpc };

    await joinCommunity(db, { communityId: "community-1" });

    expect(rpc).toHaveBeenCalledWith("join_community", {
      p_community_id: "community-1",
    });
    expect(db.from).not.toHaveBeenCalled();
  });

  it("community message creation passes public object reference ids to the RPC", async () => {
    const rpc = vi.fn().mockResolvedValue({ data: "message-1", error: null });
    const db = { from: vi.fn(), rpc };

    await createCommunityMessage(db, {
      channelId: "channel-1",
      body: "Sharing a safe reference",
      messageType: "message",
      replyToMessageId: "message-0",
      publicObjectReferenceIds: ["public-reference-1"],
    });

    expect(rpc).toHaveBeenCalledWith("create_community_message", {
      p_channel_id: "channel-1",
      p_body: "Sharing a safe reference",
      p_message_type: "message",
      p_reply_to_message_id: "message-0",
      p_public_object_reference_ids: ["public-reference-1"],
    });
    expect(db.from).not.toHaveBeenCalled();
  });

  it("message reference inputs do not include private inventory payload fields", () => {
    const input = {
      channelId: "channel-1",
      body: "Safe public reference only",
      publicObjectReferenceIds: ["public-reference-1"],
    } satisfies CreateCommunityMessageInput;

    expect(Object.keys(input)).toEqual([
      "channelId",
      "body",
      "publicObjectReferenceIds",
    ]);
    expect(input).not.toHaveProperty("inventoryItemId");
    expect(input).not.toHaveProperty("trueBasis");
    expect(input).not.toHaveProperty("purchasePrice");
    expect(input).not.toHaveProperty("privateNotes");
    expect(input).not.toHaveProperty("privateTags");
  });

  it("reporting community content calls the RPC and not direct table writes", async () => {
    const rpc = vi.fn().mockResolvedValue({ data: "report-1", error: null });
    const db = { from: vi.fn(), rpc };

    await reportCommunityContent(db, {
      productId: "product-1",
      communityId: "community-1",
      channelId: "channel-1",
      messageId: "message-1",
      reportedEntityTable: "community_messages",
      reportedEntityId: "message-1",
      reason: "spam",
      details: "Possible spam",
    });

    expect(rpc).toHaveBeenCalledWith("report_community_content", {
      p_product_id: "product-1",
      p_community_id: "community-1",
      p_channel_id: "channel-1",
      p_message_id: "message-1",
      p_reported_entity_table: "community_messages",
      p_reported_entity_id: "message-1",
      p_reason: "spam",
      p_details: "Possible spam",
    });
    expect(db.from).not.toHaveBeenCalled();
  });

  it("moderating community content calls the RPC and not direct table writes", async () => {
    const rpc = vi.fn().mockResolvedValue({ data: "action-1", error: null });
    const db = { from: vi.fn(), rpc };

    await moderateCommunityContent(db, {
      reportId: "report-1",
      productId: "product-1",
      communityId: "community-1",
      channelId: "channel-1",
      messageId: "message-1",
      targetEntityTable: "community_messages",
      targetEntityId: "message-1",
      actionType: "hide",
      reason: "moderation",
      metadata: { safe_note: "reviewed" },
    });

    expect(rpc).toHaveBeenCalledWith("moderate_community_content", {
      p_report_id: "report-1",
      p_product_id: "product-1",
      p_community_id: "community-1",
      p_channel_id: "channel-1",
      p_message_id: "message-1",
      p_target_entity_table: "community_messages",
      p_target_entity_id: "message-1",
      p_action_type: "hide",
      p_reason: "moderation",
      p_metadata: { safe_note: "reviewed" },
    });
    expect(db.from).not.toHaveBeenCalled();
  });

  it("lifting a user restriction calls the RPC and not direct table writes", async () => {
    const rpc = vi.fn().mockResolvedValue({ data: "restriction-1", error: null });
    const db = { from: vi.fn(), rpc };

    await liftUserRestriction(db, {
      restrictionId: "restriction-1",
      reason: "reviewed",
    });

    expect(rpc).toHaveBeenCalledWith("lift_user_restriction", {
      p_restriction_id: "restriction-1",
      p_reason: "reviewed",
    });
    expect(db.from).not.toHaveBeenCalled();
  });

  it("adding a moderation note calls the RPC and not direct table writes", async () => {
    const rpc = vi.fn().mockResolvedValue({ data: "note-1", error: null });
    const db = { from: vi.fn(), rpc };

    await addModerationNote(db, {
      productId: "product-1",
      communityId: "community-1",
      reportId: "report-1",
      actionId: "action-1",
      subjectUserId: "user-1",
      note: "Internal note",
      visibility: "moderators",
    });

    expect(rpc).toHaveBeenCalledWith("add_moderation_note", {
      p_product_id: "product-1",
      p_community_id: "community-1",
      p_report_id: "report-1",
      p_action_id: "action-1",
      p_subject_user_id: "user-1",
      p_note: "Internal note",
      p_visibility: "moderators",
    });
    expect(db.from).not.toHaveBeenCalled();
  });

  it("submitting a moderation appeal calls the RPC and not direct table writes", async () => {
    const rpc = vi.fn().mockResolvedValue({ data: "appeal-1", error: null });
    const db = { from: vi.fn(), rpc };

    await submitModerationAppeal(db, {
      productId: "product-1",
      communityId: "community-1",
      reportId: "report-1",
      actionId: "action-1",
      restrictionId: "restriction-1",
      reason: "appeal reason",
    });

    expect(rpc).toHaveBeenCalledWith("submit_moderation_appeal", {
      p_product_id: "product-1",
      p_community_id: "community-1",
      p_report_id: "report-1",
      p_action_id: "action-1",
      p_restriction_id: "restriction-1",
      p_reason: "appeal reason",
    });
    expect(db.from).not.toHaveBeenCalled();
  });
});

describe("notification service protections", () => {
  it("rejects private fields in notification safe metadata", () => {
    expect(() =>
      assertNotificationMetadataSafe({
        safe_context: "notification",
        nested: { purchase_price: 100 },
      }),
    ).toThrow(
      "Notification metadata cannot include private field purchase_price.",
    );

    expect(() =>
      assertNotificationMetadataSafe({ safe_context: "notification" }),
    ).not.toThrow();
  });

  it("create notification event calls the RPC and not direct table writes", async () => {
    const rpc = vi.fn().mockResolvedValue({ data: "notification-event-1", error: null });
    const db = { from: vi.fn(), rpc };

    await expect(
      createNotificationEvent(db, {
        productId: "product-1",
        actorUserId: "actor-1",
        eventType: "community.message.created",
        entityTable: "community_messages",
        entityId: "message-1",
        relatedEntityTable: "communities",
        relatedEntityId: "community-1",
        title: "Community message",
        body: "Safe body",
        safeMetadata: { safe_context: "test" },
        recipientUserIds: ["recipient-1"],
        notificationType: "community",
        priority: "normal",
      }),
    ).resolves.toBe("notification-event-1");

    expect(rpc).toHaveBeenCalledWith("create_notification_event", {
      p_product_id: "product-1",
      p_actor_user_id: "actor-1",
      p_event_type: "community.message.created",
      p_entity_table: "community_messages",
      p_entity_id: "message-1",
      p_related_entity_table: "communities",
      p_related_entity_id: "community-1",
      p_title: "Community message",
      p_body: "Safe body",
      p_safe_metadata: { safe_context: "test" },
      p_recipient_user_ids: ["recipient-1"],
      p_notification_type: "community",
      p_priority: "normal",
    });
    expect(db.from).not.toHaveBeenCalled();
  });

  it("create notification event rejects private metadata before RPC call", async () => {
    const rpc = vi.fn();
    const db = { from: vi.fn(), rpc };

    await expect(
      createNotificationEvent(db, {
        eventType: "unsafe",
        title: "Unsafe",
        safeMetadata: { private_notes: "hidden" },
      }),
    ).rejects.toThrow(
      "Notification metadata cannot include private field private_notes.",
    );

    expect(rpc).not.toHaveBeenCalled();
    expect(db.from).not.toHaveBeenCalled();
  });

  it("mark/dismiss/archive notification mutations call RPCs only", async () => {
    const rpc = vi
      .fn()
      .mockResolvedValueOnce({ data: "notification-1", error: null })
      .mockResolvedValueOnce({ data: 2, error: null })
      .mockResolvedValueOnce({ data: "notification-1", error: null })
      .mockResolvedValueOnce({ data: "notification-1", error: null });
    const db = { from: vi.fn(), rpc };

    await expect(
      markNotificationRead(db, { notificationId: "notification-1" }),
    ).resolves.toBe("notification-1");
    await expect(
      markNotificationsRead(db, { notificationIds: ["notification-1", "notification-2"] }),
    ).resolves.toBe(2);
    await expect(
      dismissNotification(db, { notificationId: "notification-1" }),
    ).resolves.toBe("notification-1");
    await expect(
      archiveNotification(db, { notificationId: "notification-1" }),
    ).resolves.toBe("notification-1");

    expect(rpc).toHaveBeenNthCalledWith(1, "mark_notification_read", {
      p_notification_id: "notification-1",
    });
    expect(rpc).toHaveBeenNthCalledWith(2, "mark_notifications_read", {
      p_notification_ids: ["notification-1", "notification-2"],
    });
    expect(rpc).toHaveBeenNthCalledWith(3, "dismiss_notification", {
      p_notification_id: "notification-1",
    });
    expect(rpc).toHaveBeenNthCalledWith(4, "archive_notification", {
      p_notification_id: "notification-1",
    });
    expect(db.from).not.toHaveBeenCalled();
  });

  it("notification query functions use the expected tables", async () => {
    const { db, from, query } = createSelectMockDb();

    await getNotificationsForCurrentUser(db);
    await getUnreadNotificationsForCurrentUser(db);
    await getNotificationById(db, "notification-1");
    await getNotificationEvents(db, { productId: "product-1" });
    await getNotificationDeliveryAttempts(db, "notification-1");

    expect(from).toHaveBeenNthCalledWith(1, "notifications");
    expect(from).toHaveBeenNthCalledWith(2, "notifications");
    expect(from).toHaveBeenNthCalledWith(3, "notifications");
    expect(from).toHaveBeenNthCalledWith(4, "notification_events");
    expect(from).toHaveBeenNthCalledWith(5, "notification_delivery_attempts");
    expect(query.eq).toHaveBeenCalledWith("status", "unread");
    expect(query.eq).toHaveBeenCalledWith("id", "notification-1");
    expect(query.eq).toHaveBeenCalledWith("product_id", "product-1");
    expect(query.eq).toHaveBeenCalledWith("notification_id", "notification-1");
  });
});

describe("evaluation service protections", () => {
  it("create evaluation case calls the RPC and not direct table writes", async () => {
    const rpc = vi.fn().mockResolvedValue({ data: "evaluation-case-1", error: null });
    const db = { from: vi.fn(), rpc };

    await expect(
      createEvaluationCase(db, {
        workspaceId: "workspace-1",
        productId: "product-1",
        caseType: "grading",
        providerName: "Manual Provider",
        providerReference: "CASE-1",
        openedAt: "2026-06-01T00:00:00.000Z",
        expectedReturnAt: "2026-07-01T00:00:00.000Z",
        totalDeclaredValue: 500,
        totalEvaluationCost: 40,
        totalShippingCost: 10,
        totalInsuranceCost: 5,
        totalOtherCosts: 2,
        notes: "Evaluation note",
        metadata: { safe_context: "test" },
      }),
    ).resolves.toBe("evaluation-case-1");

    expect(rpc).toHaveBeenCalledWith("create_evaluation_case", {
      p_workspace_id: "workspace-1",
      p_product_id: "product-1",
      p_case_type: "grading",
      p_provider_name: "Manual Provider",
      p_provider_reference: "CASE-1",
      p_opened_at: "2026-06-01T00:00:00.000Z",
      p_expected_return_at: "2026-07-01T00:00:00.000Z",
      p_total_declared_value: 500,
      p_total_evaluation_cost: 40,
      p_total_shipping_cost: 10,
      p_total_insurance_cost: 5,
      p_total_other_costs: 2,
      p_notes: "Evaluation note",
      p_metadata: { safe_context: "test" },
    });
    expect(db.from).not.toHaveBeenCalled();
  });

  it("add evaluation case item calls the RPC and not direct table writes", async () => {
    const rpc = vi.fn().mockResolvedValue({ data: "evaluation-case-item-1", error: null });
    const db = { from: vi.fn(), rpc };

    await expect(
      addEvaluationCaseItem(db, {
        evaluationCaseId: "evaluation-case-1",
        inventoryItemId: "inventory-1",
        declaredValue: 250,
        allocatedEvaluationCost: 25,
        allocatedShippingCost: 5,
        allocatedInsuranceCost: 3,
        allocatedOtherCosts: 2,
        providerItemReference: "ITEM-1",
        notes: "Item note",
      }),
    ).resolves.toBe("evaluation-case-item-1");

    expect(rpc).toHaveBeenCalledWith("add_evaluation_case_item", {
      p_evaluation_case_id: "evaluation-case-1",
      p_inventory_item_id: "inventory-1",
      p_declared_value: 250,
      p_allocated_evaluation_cost: 25,
      p_allocated_shipping_cost: 5,
      p_allocated_insurance_cost: 3,
      p_allocated_other_costs: 2,
      p_provider_item_reference: "ITEM-1",
      p_notes: "Item note",
    });
    expect(db.from).not.toHaveBeenCalled();
  });

  it("update evaluation case status calls the RPC and not direct table writes", async () => {
    const rpc = vi.fn().mockResolvedValue({ data: "evaluation-case-1", error: null });
    const db = { from: vi.fn(), rpc };

    await updateEvaluationCaseStatus(db, {
      evaluationCaseId: "evaluation-case-1",
      status: "submitted",
      occurredAt: "2026-06-02T00:00:00.000Z",
      notes: "Submitted",
      metadata: { safe_context: "status" },
    });

    expect(rpc).toHaveBeenCalledWith("update_evaluation_case_status", {
      p_evaluation_case_id: "evaluation-case-1",
      p_status: "submitted",
      p_occurred_at: "2026-06-02T00:00:00.000Z",
      p_notes: "Submitted",
      p_metadata: { safe_context: "status" },
    });
    expect(db.from).not.toHaveBeenCalled();
  });

  it("record evaluation result calls the RPC without basis or current value mutation payloads", async () => {
    const rpc = vi.fn().mockResolvedValue({ data: "evaluation-case-item-1", error: null });
    const db = { from: vi.fn(), rpc };

    await recordEvaluationResult(db, {
      evaluationCaseItemId: "evaluation-case-item-1",
      itemStatus: "completed",
      resultSummary: "Certified",
      resultGrade: "10",
      resultAuthenticity: "authentic",
      resultCertificationNumber: "CERT-1",
      resultMetadata: { safe_result: "ok" },
      notes: "Result note",
    });

    expect(rpc).toHaveBeenCalledWith("record_evaluation_result", {
      p_evaluation_case_item_id: "evaluation-case-item-1",
      p_item_status: "completed",
      p_result_summary: "Certified",
      p_result_grade: "10",
      p_result_authenticity: "authentic",
      p_result_certification_number: "CERT-1",
      p_result_metadata: { safe_result: "ok" },
      p_notes: "Result note",
    });
    expect(rpc.mock.calls[0][1]).not.toHaveProperty("p_true_basis");
    expect(rpc.mock.calls[0][1]).not.toHaveProperty("p_current_value");
    expect(rpc.mock.calls[0][1]).not.toHaveProperty("p_current_value_snapshot_id");
    expect(db.from).not.toHaveBeenCalled();
  });

  it("apply evaluation basis increase calls the RPC only", async () => {
    const rpc = vi.fn().mockResolvedValue({ data: "evaluation-case-item-1", error: null });
    const db = { from: vi.fn(), rpc };

    await applyEvaluationBasisIncrease(db, {
      evaluationCaseItemId: "evaluation-case-item-1",
      basisIncreaseAmount: 35,
      notes: "Explicit basis increase",
    });

    expect(rpc).toHaveBeenCalledWith("apply_evaluation_basis_increase", {
      p_evaluation_case_item_id: "evaluation-case-item-1",
      p_basis_increase_amount: 35,
      p_notes: "Explicit basis increase",
    });
    expect(db.from).not.toHaveBeenCalled();
  });
});

describe("product and portfolio service helpers", () => {
  it("product-scoped inventory filters by product category", () => {
    const items = [
      inventoryItem({ id: "sports-card", category_id: "sports_cards" }),
      inventoryItem({ id: "comic", category_id: "comics" }),
    ];

    expect(filterInventoryByCategoryIds(items, ["sports_cards"])).toEqual([
      items[0],
    ]);
  });

  it("portfolio summary counts missing basis separately from zero basis", () => {
    const summary = buildPortfolioSummary([
      inventoryItem({ id: "missing", true_basis: null }),
      inventoryItem({ id: "zero", true_basis: 0 }),
      inventoryItem({
        id: "known",
        true_basis: 125,
        current_value_snapshot_id: "snapshot-1",
        current_value_snapshot: {
          id: "snapshot-1",
          market_value: 200,
          currency_code: "USD",
          observed_at: "2026-01-01T00:00:00.000Z",
        },
      }),
    ]);

    expect(summary).toEqual({
      itemCount: 3,
      missingBasisCount: 1,
      knownZeroBasisCount: 1,
      totalKnownBasis: 125,
      totalCurrentValue: 200,
      noCompSavedCount: 2,
    });
  });
});

describe("product lens service helpers", () => {
  const product = {
    id: "product-card",
    slug: "card_vertex",
    name: "Card Vertex",
    product_type: "vertical",
    status: "active",
    created_at: "2026-01-01T00:00:00.000Z",
    updated_at: "2026-01-01T00:00:00.000Z",
  };

  function createProductLensDb() {
    return createProductLensMockDb({
      products: [product],
      product_categories: [{ product_id: "product-card", category_id: "sports_cards" }],
      inventory_items: [
        inventoryItem({
          id: "workspace-card",
          workspace_id: "workspace-1",
          owner_user_id: null,
          category_id: "sports_cards",
        }),
        inventoryItem({
          id: "workspace-comic",
          workspace_id: "workspace-1",
          owner_user_id: null,
          category_id: "comics",
        }),
      ],
      public_object_references: [
        {
          id: "reference-card",
          product_id: "product-card",
          visibility: "community",
          exposure_state: "active",
          public_metadata: { safe: true },
        },
        {
          id: "reference-hidden",
          product_id: "product-card",
          visibility: "community",
          exposure_state: "hidden",
          public_metadata: { safe: true },
        },
      ],
      communities: [
        {
          id: "community-card",
          product_id: "product-card",
          created_at: "2026-01-01T00:00:00.000Z",
        },
      ],
      notifications: [
        {
          id: "notification-card",
          product_id: "product-card",
          recipient_user_id: "user-1",
          status: "unread",
          created_at: "2026-01-01T00:00:00.000Z",
        },
        {
          id: "notification-read",
          product_id: "product-card",
          recipient_user_id: "user-1",
          status: "read",
          created_at: "2026-01-01T00:00:00.000Z",
        },
      ],
      evaluation_cases: [
        {
          id: "evaluation-card",
          product_id: "product-card",
          workspace_id: "workspace-1",
          status: "draft",
          opened_at: "2026-01-01T00:00:00.000Z",
          created_at: "2026-01-01T00:00:00.000Z",
        },
      ],
      account_entitlements: [
        { entitlement_key: "cross_vertex_portfolio" },
      ],
      organization_entitlements: [],
    });
  }

  it("product lens inventory starts from scoped inventory and filters product categories", async () => {
    const { db, queries } = createProductLensDb();

    await expect(
      getProductLensInventory(db, {
        productSlug: "card_vertex",
        workspaceId: "workspace-1",
      }),
    ).resolves.toEqual([
      expect.objectContaining({ id: "workspace-card", category_id: "sports_cards" }),
    ]);

    expect(queries.products[0].eq).toHaveBeenCalledWith("slug", "card_vertex");
    expect(queries.product_categories[0].eq).toHaveBeenCalledWith(
      "product_id",
      "product-card",
    );
    expect(queries.inventory_items[0].or).toHaveBeenCalledWith(
      "workspace_id.eq.workspace-1",
    );
  });

  it("product lens public references use product scope and safe exposure filters", async () => {
    const { db, queries } = createProductLensDb();

    await expect(
      getProductLensPublicReferences(db, { productId: "product-card" }),
    ).resolves.toEqual([
      expect.objectContaining({ id: "reference-card", product_id: "product-card" }),
    ]);

    expect(queries.public_object_references[0].eq).toHaveBeenCalledWith(
      "product_id",
      "product-card",
    );
    expect(queries.public_object_references[0].eq).toHaveBeenCalledWith(
      "exposure_state",
      "active",
    );
    expect(queries.public_object_references[0].in).toHaveBeenCalledWith(
      "visibility",
      ["community", "listing", "showcase", "trade", "public"],
    );
  });

  it("product lens communities use product_id scope", async () => {
    const { db, queries } = createProductLensDb();

    await getProductLensCommunities(db, { productId: "product-card" });

    expect(queries.communities[0].eq).toHaveBeenCalledWith(
      "product_id",
      "product-card",
    );
  });

  it("product lens notifications use product scope plus recipient RLS", async () => {
    const { db, queries } = createProductLensDb();

    await getProductLensNotifications(db, {
      productId: "product-card",
      status: "unread",
    });

    expect(queries.notifications[0].eq).toHaveBeenCalledWith(
      "product_id",
      "product-card",
    );
    expect(queries.notifications[0].eq).toHaveBeenCalledWith("status", "unread");
  });

  it("product lens evaluations use product and workspace scope", async () => {
    const { db, queries } = createProductLensDb();

    await getProductLensEvaluationCases(db, {
      productId: "product-card",
      workspaceId: "workspace-1",
    });

    expect(queries.evaluation_cases[0].eq).toHaveBeenCalledWith(
      "workspace_id",
      "workspace-1",
    );
    expect(queries.evaluation_cases[0].eq).toHaveBeenCalledWith(
      "product_id",
      "product-card",
    );
  });

  it("product lens summary composes scoped query helpers", async () => {
    const { db } = createProductLensDb();

    await expect(
      getProductLensSummary(db, {
        productId: "product-card",
        workspaceId: "workspace-1",
      }),
    ).resolves.toEqual({
      productId: "product-card",
      inventoryCount: 1,
      publicReferenceCount: 1,
      communityCount: 1,
      unreadNotificationCount: 1,
      evaluationCaseCount: 1,
      entitlementFlags: {
        account: ["cross_vertex_portfolio"],
        organization: [],
        hasCrossVertexPortfolio: true,
        hasVertexPro: false,
        hasCrossVertexInventory: false,
      },
    });
  });
});
