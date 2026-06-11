export function calculateGradingBasisIncrease(input: {
  gradingFees: number;
  shipping?: number;
  insurance?: number;
  supplies?: number;
}): number {
  return (
    input.gradingFees +
    (input.shipping ?? 0) +
    (input.insurance ?? 0) +
    (input.supplies ?? 0)
  );
}
