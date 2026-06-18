import { describe, expect, it } from "vitest";
import { createSaleTransaction } from "@/packages/satera-core/src/transactions";
import { getProductLensSummary } from "@/packages/satera-core/src/product-lens";
import { createEvaluationCase } from "@/packages/satera-core/src/evaluations";
import { markNotificationRead } from "@/packages/satera-core/src/notifications";
import {
  evaluations,
  notifications,
  productLens,
  transactions,
} from "@/packages/satera-core/src";
import type { SaleTransactionInput } from "@/packages/satera-core/src/transactions";

describe("Satera Core package boundary", () => {
  it("re-exports representative service functions", () => {
    expect(transactions.createSaleTransaction).toBe(createSaleTransaction);
    expect(productLens.getProductLensSummary).toBe(getProductLensSummary);
    expect(evaluations.createEvaluationCase).toBe(createEvaluationCase);
    expect(notifications.markNotificationRead).toBe(markNotificationRead);
  });

  it("re-exports representative service types", () => {
    const input: SaleTransactionInput = {
      ownerUserId: "user-1",
      inventoryItemId: "inventory-1",
      transactionDate: "2026-06-18T00:00:00.000Z",
      salePrice: 100,
      createdBy: "user-1",
    };

    expect(input.inventoryItemId).toBe("inventory-1");
  });
});
