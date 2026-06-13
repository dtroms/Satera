import { describe, expect, it } from "vitest";
import {
  formatBasis,
  formatCurrentValue,
  formatEnumLabel,
  formatOwnerContext,
  formatShortId,
} from "@/lib/core/internal/format";

describe("internal formatting helpers", () => {
  it("formats missing basis distinctly", () => {
    expect(formatBasis(null)).toBe("Missing basis");
  });

  it("formats known zero basis distinctly", () => {
    expect(formatBasis(0)).toBe("$0.00 known");
  });

  it("formats positive basis as currency", () => {
    expect(formatBasis(125)).toBe("$125.00");
  });

  it("formats missing current value distinctly", () => {
    expect(formatCurrentValue(null)).toBe("No comp saved");
  });

  it("formats enum labels for internal display", () => {
    expect(formatEnumLabel("same_card_different_grade")).toBe(
      "Same Card Different Grade",
    );
    expect(formatEnumLabel(null)).toBe("-");
  });

  it("shortens UUIDs and handles null safely", () => {
    expect(formatShortId("70000000-0000-0000-0000-000000000001")).toBe(
      "70000000...0001",
    );
    expect(formatShortId(null)).toBe("None");
  });

  it("identifies user, workspace, organization, and unknown owner contexts", () => {
    expect(
      formatOwnerContext({
        owner_user_id: "00000000-0000-0000-0000-0000000000a1",
      }),
    ).toBe("User 00000000...00a1");

    expect(
      formatOwnerContext({
        workspace_id: "30000000-0000-0000-0000-000000000001",
      }),
    ).toBe("Workspace 30000000...0001");

    expect(
      formatOwnerContext({
        organization_id: "40000000-0000-0000-0000-000000000001",
      }),
    ).toBe("Organization 40000000...0001");

    expect(formatOwnerContext({})).toBe("Unknown");
  });
});
