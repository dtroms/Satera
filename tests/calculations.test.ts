import { describe, expect, it } from "vitest";
import { applyBasisEvent, calculatePurchaseBasis } from "@/lib/calculations/basis";
import { allocateLotBasis } from "@/lib/calculations/lot";
import {
  calculateNetSale,
  calculateRealizedProfit,
  calculateROI,
  calculateUnrealizedGain,
} from "@/lib/calculations/profit";
import {
  allocateTradeBasis,
  calculateTradeBasisPool,
} from "@/lib/calculations/trade";

describe("basis calculations", () => {
  it("calculates purchase basis", () => {
    expect(
      calculatePurchaseBasis({
        purchasePrice: 100,
        buyerFees: 10,
        tax: 8,
        shipping: 5,
        directAcquisitionCosts: 2,
      }),
    ).toBe(125);
  });

  it("applies a basis event from previous basis to new basis", () => {
    expect(applyBasisEvent({ previousBasis: 100, amount: 25 })).toEqual({
      previousBasis: 100,
      newBasis: 125,
    });
  });
});

describe("profit calculations", () => {
  it("calculates net sale", () => {
    expect(
      calculateNetSale({
        salePrice: 200,
        platformFees: 20,
        shipping: 5,
        supplies: 3,
        consignmentFees: 12,
      }),
    ).toBe(160);
  });

  it("calculates realized profit", () => {
    expect(calculateRealizedProfit({ netSale: 160, trueBasis: 110 })).toBe(50);
  });

  it("calculates unrealized gain", () => {
    expect(calculateUnrealizedGain({ currentValue: 180, trueBasis: 125 })).toBe(
      55,
    );
  });

  it("calculates ROI", () => {
    expect(calculateROI({ profit: 50, trueBasis: 200 })).toBe(0.25);
  });
});

describe("trade calculations", () => {
  it("calculates trade basis pool", () => {
    expect(
      calculateTradeBasisPool({
        outgoingItemBasis: 100,
        cashPaid: 20,
        cashReceived: 10,
        tradeRelatedCosts: 5,
      }),
    ).toBe(115);
  });

  it("allocates one-for-one trade basis", () => {
    expect(
      allocateTradeBasis({
        basisPool: 120,
        incomingItems: [{ id: "incoming-1", tradeValue: 300 }],
      }).allocations,
    ).toEqual([{ id: "incoming-1", allocatedBasis: 120 }]);
  });

  it("allocates multi-item trade basis by trade value", () => {
    expect(
      allocateTradeBasis({
        basisPool: 120,
        incomingItems: [
          { id: "a", tradeValue: 100 },
          { id: "b", tradeValue: 300 },
        ],
      }).allocations,
    ).toEqual([
      { id: "a", allocatedBasis: 30 },
      { id: "b", allocatedBasis: 90 },
    ]);
  });

  it("handles trade with cash paid", () => {
    expect(
      calculateTradeBasisPool({ outgoingItemBasis: 100, cashPaid: 25 }),
    ).toBe(125);
  });

  it("handles trade with cash received", () => {
    expect(
      calculateTradeBasisPool({ outgoingItemBasis: 100, cashReceived: 25 }),
    ).toBe(75);
  });

  it("handles trade with fees", () => {
    expect(
      calculateTradeBasisPool({ outgoingItemBasis: 100, tradeRelatedCosts: 12 }),
    ).toBe(112);
  });

  it("sets incoming basis to zero when basis pool is negative", () => {
    expect(
      allocateTradeBasis({
        basisPool: -40,
        incomingItems: [
          { id: "a", tradeValue: 100 },
          { id: "b", tradeValue: 100 },
        ],
      }),
    ).toEqual({
      allocations: [
        { id: "a", allocatedBasis: 0 },
        { id: "b", allocatedBasis: 0 },
      ],
      excessRealizedProfit: 40,
    });
  });

  it("sets incoming basis to zero when basis pool is zero", () => {
    expect(
      allocateTradeBasis({
        basisPool: 0,
        incomingItems: [{ id: "incoming-1", tradeValue: 100 }],
      }),
    ).toEqual({
      allocations: [{ id: "incoming-1", allocatedBasis: 0 }],
      excessRealizedProfit: 0,
    });
  });
});

describe("lot calculations", () => {
  it("allocates lots equally", () => {
    expect(
      allocateLotBasis({
        totalBasis: 90,
        method: "equal_split",
        items: [{ id: "a" }, { id: "b" }, { id: "c" }],
      }),
    ).toEqual([
      { id: "a", allocatedBasis: 30 },
      { id: "b", allocatedBasis: 30 },
      { id: "c", allocatedBasis: 30 },
    ]);
  });

  it("allocates lots proportionally", () => {
    expect(
      allocateLotBasis({
        totalBasis: 100,
        method: "proportional_by_estimated_value",
        items: [
          { id: "a", estimatedValue: 25 },
          { id: "b", estimatedValue: 75 },
        ],
      }),
    ).toEqual([
      { id: "a", allocatedBasis: 25 },
      { id: "b", allocatedBasis: 75 },
    ]);
  });

  it("allocates lots manually", () => {
    expect(
      allocateLotBasis({
        totalBasis: 100,
        method: "manual",
        items: [
          { id: "a", manualBasis: 60 },
          { id: "b", manualBasis: 40 },
        ],
      }),
    ).toEqual([
      { id: "a", allocatedBasis: 60 },
      { id: "b", allocatedBasis: 40 },
    ]);
  });

  it("allocates lots with an anchor item", () => {
    expect(
      allocateLotBasis({
        totalBasis: 100,
        method: "anchor_item",
        anchorItemId: "a",
        anchorBasis: 40,
        items: [
          { id: "a", estimatedValue: 100 },
          { id: "b", estimatedValue: 20 },
          { id: "c", estimatedValue: 40 },
        ],
      }),
    ).toEqual([
      { id: "a", allocatedBasis: 40 },
      { id: "b", allocatedBasis: 20 },
      { id: "c", allocatedBasis: 40 },
    ]);
  });
});
