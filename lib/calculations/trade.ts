export type TradeBasisPoolInput = {
  outgoingItemBasis: number;
  cashPaid?: number;
  cashReceived?: number;
  tradeRelatedCosts?: number;
};

export type IncomingTradeItem = {
  id: string;
  tradeValue: number;
};

export type TradeBasisAllocation = {
  id: string;
  allocatedBasis: number;
};

export type TradeBasisAllocationResult = {
  allocations: TradeBasisAllocation[];
  excessRealizedProfit: number;
};

export function calculateTradeBasisPool(input: TradeBasisPoolInput): number {
  return (
    input.outgoingItemBasis +
    (input.cashPaid ?? 0) -
    (input.cashReceived ?? 0) +
    (input.tradeRelatedCosts ?? 0)
  );
}

export function allocateTradeBasis(input: {
  basisPool: number;
  incomingItems: IncomingTradeItem[];
}): TradeBasisAllocationResult {
  if (input.incomingItems.length === 0) {
    return { allocations: [], excessRealizedProfit: Math.max(0, -input.basisPool) };
  }

  if (input.basisPool <= 0) {
    return {
      allocations: input.incomingItems.map((item) => ({
        id: item.id,
        allocatedBasis: 0,
      })),
      excessRealizedProfit: Math.abs(input.basisPool),
    };
  }

  if (input.incomingItems.length === 1) {
    return {
      allocations: [
        { id: input.incomingItems[0].id, allocatedBasis: input.basisPool },
      ],
      excessRealizedProfit: 0,
    };
  }

  const totalTradeValue = input.incomingItems.reduce(
    (sum, item) => sum + item.tradeValue,
    0,
  );

  if (totalTradeValue <= 0) {
    const equalBasis = input.basisPool / input.incomingItems.length;
    return {
      allocations: input.incomingItems.map((item) => ({
        id: item.id,
        allocatedBasis: equalBasis,
      })),
      excessRealizedProfit: 0,
    };
  }

  return {
    allocations: input.incomingItems.map((item) => ({
      id: item.id,
      allocatedBasis: input.basisPool * (item.tradeValue / totalTradeValue),
    })),
    excessRealizedProfit: 0,
  };
}
