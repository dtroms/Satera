export function calculateConsignmentNet(input: {
  salePrice: number;
  consignmentFees?: number;
  shipping?: number;
  otherFees?: number;
}): number {
  return (
    input.salePrice -
    (input.consignmentFees ?? 0) -
    (input.shipping ?? 0) -
    (input.otherFees ?? 0)
  );
}
