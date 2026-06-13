export type CompSourceType =
  | "marketplace"
  | "auction_house"
  | "price_guide"
  | "private_sale"
  | "local_card_shop"
  | "card_show"
  | "dealer_verified"
  | "user_submitted"
  | "admin_verified"
  | "partner_feed";

export type CompCaptureMode = "manual" | "smart" | "reference_only";

export type CompVerificationStatus =
  | "user_submitted"
  | "system_assisted"
  | "needs_review"
  | "admin_verified"
  | "dealer_verified"
  | "excluded"
  | "disputed";

export type CompMatchQuality =
  | "exact_match"
  | "same_card_different_grade"
  | "same_player_different_parallel"
  | "similar_card"
  | "reference_only"
  | "excluded";

export type CompExclusionReason =
  | "wrong_card"
  | "wrong_parallel"
  | "wrong_grade"
  | "raw_vs_graded_mismatch"
  | "multi_card_lot"
  | "reprint"
  | "custom_card"
  | "suspicious_price"
  | "unpaid_or_canceled_sale"
  | "damaged_card"
  | "altered_card"
  | "poor_image_match"
  | "old_comp"
  | "not_enough_information";

export type CompConfidenceLabel =
  | "unknown"
  | "user_entered"
  | "low_confidence"
  | "medium_confidence"
  | "high_confidence"
  | "verified";

export type CompSnapshot = {
  id: string;
  owner_user_id: string | null;
  workspace_id: string | null;
  organization_id: string | null;
  category_id: string;
  asset_family_id: string | null;
  asset_variant_id: string | null;
  inventory_item_id: string | null;
  source: string | null;
  source_url: string | null;
  market_value: number | string;
  currency_code: string;
  method: string | null;
  number_of_comps: number | null;
  condition_or_grade: string | null;
  observed_at: string;
  snapshot_data: Record<string, unknown>;
  source_type: CompSourceType;
  capture_mode: CompCaptureMode;
  verification_status: CompVerificationStatus;
  match_quality: CompMatchQuality;
  include_in_valuation: boolean;
  exclusion_reason: CompExclusionReason | null;
  exclusion_notes: string | null;
  sale_date: string | null;
  sale_title: string | null;
  source_domain: string | null;
  grading_company: string | null;
  screenshot_url: string | null;
  notes: string | null;
  submitted_by: string | null;
  verified_by: string | null;
  verified_at: string | null;
  confidence_label: CompConfidenceLabel;
  review_requested: boolean;
  review_reason: string | null;
  created_by: string | null;
  created_at: string;
};

export type CompValueSummary = {
  estimatedValue: number | null;
  averageValue: number | null;
  medianValue: number | null;
  includedCount: number;
  excludedCount: number;
  verifiedCount: number;
  userSubmittedCount: number;
  confidenceLabel: CompConfidenceLabel;
};
