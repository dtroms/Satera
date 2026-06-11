export type PurchaseBasisInput = {
  purchasePrice: number;
  buyerFees?: number;
  tax?: number;
  shipping?: number;
  directAcquisitionCosts?: number;
};

export type BasisEventInput = {
  previousBasis: number;
  amount: number;
};

export type BasisEventResult = {
  previousBasis: number;
  newBasis: number;
};

export function calculatePurchaseBasis(input: PurchaseBasisInput): number {
  return (
    input.purchasePrice +
    (input.buyerFees ?? 0) +
    (input.tax ?? 0) +
    (input.shipping ?? 0) +
    (input.directAcquisitionCosts ?? 0)
  );
}

export function applyBasisEvent(input: BasisEventInput): BasisEventResult {
  return {
    previousBasis: input.previousBasis,
    newBasis: input.previousBasis + input.amount,
  };
}
