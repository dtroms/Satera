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
  createPurchaseTransaction,
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
