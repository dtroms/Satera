import type { LotAllocationMethod } from "@/lib/core/types";

export type LotItem = {
  id: string;
  estimatedValue?: number;
  manualBasis?: number;
  isAnchor?: boolean;
};

export type LotAllocation = {
  id: string;
  allocatedBasis: number;
};

export function allocateLotBasis(input: {
  totalBasis: number;
  items: LotItem[];
  method: LotAllocationMethod;
  anchorItemId?: string;
  anchorBasis?: number;
}): LotAllocation[] {
  if (input.items.length === 0) {
    return [];
  }

  if (input.method === "equal_split") {
    const equalBasis = input.totalBasis / input.items.length;
    return input.items.map((item) => ({ id: item.id, allocatedBasis: equalBasis }));
  }

  if (input.method === "manual") {
    return input.items.map((item) => ({
      id: item.id,
      allocatedBasis: item.manualBasis ?? 0,
    }));
  }

  if (input.method === "anchor_item") {
    const anchorItemId =
      input.anchorItemId ?? input.items.find((item) => item.isAnchor)?.id;
    const anchorBasis = input.anchorBasis ?? 0;
    const remainingItems = input.items.filter((item) => item.id !== anchorItemId);
    const remainingBasis = Math.max(0, input.totalBasis - anchorBasis);
    const remainingTotalValue = remainingItems.reduce(
      (sum, item) => sum + (item.estimatedValue ?? 0),
      0,
    );

    return input.items.map((item) => {
      if (item.id === anchorItemId) {
        return { id: item.id, allocatedBasis: anchorBasis };
      }

      if (remainingTotalValue <= 0) {
        return {
          id: item.id,
          allocatedBasis: remainingBasis / Math.max(1, remainingItems.length),
        };
      }

      return {
        id: item.id,
        allocatedBasis:
          remainingBasis * ((item.estimatedValue ?? 0) / remainingTotalValue),
      };
    });
  }

  const totalEstimatedValue = input.items.reduce(
    (sum, item) => sum + (item.estimatedValue ?? 0),
    0,
  );

  if (totalEstimatedValue <= 0) {
    const equalBasis = input.totalBasis / input.items.length;
    return input.items.map((item) => ({ id: item.id, allocatedBasis: equalBasis }));
  }

  return input.items.map((item) => ({
    id: item.id,
    allocatedBasis:
      input.totalBasis * ((item.estimatedValue ?? 0) / totalEstimatedValue),
  }));
}
