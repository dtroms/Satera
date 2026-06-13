import { describe, expect, it } from "vitest";
import { buildCompValueSummary } from "@/lib/core/comps/calculations";

describe("comp value summary", () => {
  it("uses median included comps as the estimated value", () => {
    const summary = buildCompValueSummary([
      {
        market_value: 100,
        include_in_valuation: true,
        verification_status: "user_submitted",
      },
      {
        market_value: 200,
        include_in_valuation: true,
        verification_status: "admin_verified",
      },
      {
        market_value: 900,
        include_in_valuation: false,
        verification_status: "excluded",
      },
      {
        market_value: 300,
        include_in_valuation: true,
        verification_status: "dealer_verified",
      },
    ]);

    expect(summary).toEqual({
      estimatedValue: 200,
      averageValue: 200,
      medianValue: 200,
      includedCount: 3,
      excludedCount: 1,
      verifiedCount: 2,
      userSubmittedCount: 1,
      confidenceLabel: "medium_confidence",
    });
  });

  it("reports unknown confidence when no comps affect valuation", () => {
    const summary = buildCompValueSummary([
      {
        market_value: 100,
        include_in_valuation: false,
        verification_status: "excluded",
      },
    ]);

    expect(summary.estimatedValue).toBeNull();
    expect(summary.confidenceLabel).toBe("unknown");
    expect(summary.excludedCount).toBe(1);
  });
});
