import type {
  CompConfidenceLabel,
  CompSnapshot,
  CompValueSummary,
} from "./types";

function toNumber(value: number | string | null | undefined): number | null {
  if (value === null || value === undefined || value === "") {
    return null;
  }

  const parsed = typeof value === "number" ? value : Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

function median(values: number[]): number | null {
  if (values.length === 0) {
    return null;
  }

  const sorted = [...values].sort((a, b) => a - b);
  const middle = Math.floor(sorted.length / 2);

  if (sorted.length % 2 === 1) {
    return sorted[middle];
  }

  return (sorted[middle - 1] + sorted[middle]) / 2;
}

function average(values: number[]): number | null {
  if (values.length === 0) {
    return null;
  }

  return values.reduce((sum, value) => sum + value, 0) / values.length;
}

function confidenceForCounts({
  includedCount,
  verifiedCount,
  userSubmittedCount,
}: {
  includedCount: number;
  verifiedCount: number;
  userSubmittedCount: number;
}): CompConfidenceLabel {
  if (includedCount === 0) {
    return "unknown";
  }

  if (verifiedCount >= 3 && includedCount >= 5) {
    return "verified";
  }

  if (verifiedCount >= 2 && includedCount >= 4) {
    return "high_confidence";
  }

  if (includedCount >= 3 && verifiedCount >= 1) {
    return "medium_confidence";
  }

  if (includedCount >= 2) {
    return "low_confidence";
  }

  return userSubmittedCount > 0 ? "user_entered" : "low_confidence";
}

export function buildCompValueSummary(
  comps: Pick<
    CompSnapshot,
    "include_in_valuation" | "market_value" | "verification_status"
  >[],
): CompValueSummary {
  const included = comps.filter((comp) => comp.include_in_valuation);
  const values = included
    .map((comp) => toNumber(comp.market_value))
    .filter((value): value is number => value !== null);
  const verifiedCount = included.filter((comp) =>
    ["admin_verified", "dealer_verified"].includes(comp.verification_status),
  ).length;
  const userSubmittedCount = included.filter(
    (comp) => comp.verification_status === "user_submitted",
  ).length;
  const averageValue = average(values);
  const medianValue = median(values);

  return {
    estimatedValue: medianValue ?? averageValue,
    averageValue,
    medianValue,
    includedCount: values.length,
    excludedCount: comps.length - included.length,
    verifiedCount,
    userSubmittedCount,
    confidenceLabel: confidenceForCounts({
      includedCount: values.length,
      verifiedCount,
      userSubmittedCount,
    }),
  };
}
