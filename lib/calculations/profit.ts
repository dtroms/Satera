export type NetSaleInput = {
  salePrice: number;
  platformFees?: number;
  shipping?: number;
  supplies?: number;
  consignmentFees?: number;
};

export function calculateNetSale(input: NetSaleInput): number {
  return (
    input.salePrice -
    (input.platformFees ?? 0) -
    (input.shipping ?? 0) -
    (input.supplies ?? 0) -
    (input.consignmentFees ?? 0)
  );
}

export function calculateRealizedProfit(input: {
  netSale: number;
  trueBasis: number;
}): number {
  return input.netSale - input.trueBasis;
}

export function calculateUnrealizedGain(input: {
  currentValue: number;
  trueBasis: number;
}): number {
  return input.currentValue - input.trueBasis;
}

export function calculateROI(input: { profit: number; trueBasis: number }): number {
  if (input.trueBasis === 0) {
    return input.profit > 0 ? Infinity : 0;
  }

  return input.profit / input.trueBasis;
}
