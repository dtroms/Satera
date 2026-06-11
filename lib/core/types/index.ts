export type ProductType = "vertical" | "pro_console" | "portfolio";

export type ProductStatus = "draft" | "active" | "paused" | "retired";

export type PlatformAdminRole =
  | "super_admin"
  | "platform_admin"
  | "platform_support"
  | "trust_and_safety"
  | "read_only";

export type ProductAdminRole =
  | "product_owner"
  | "product_admin"
  | "product_support"
  | "product_moderator"
  | "product_analyst";

export type EntitlementKey =
  | "cross_vertex_portfolio"
  | "advanced_analytics"
  | "insurance_exports"
  | "bulk_import"
  | "premium_saved_views"
  | "vertex_pro"
  | "cross_vertex_inventory"
  | "multi_product_presence"
  | "staff_accounts"
  | "multi_location_inventory"
  | "organization_analytics"
  | "dealer_verification";

export type ConditionType =
  | "raw"
  | "graded"
  | "sealed"
  | "authenticated"
  | "parts"
  | "unknown";

export type InventoryStatus =
  | "active"
  | "pending"
  | "sold"
  | "traded"
  | "consigned"
  | "at_grading"
  | "archived";

export type InventoryAvailability =
  | "available"
  | "unavailable"
  | "pending_return"
  | "committed"
  | "archived";

export type InventoryIntent =
  | "hold"
  | "sell"
  | "trade"
  | "grade"
  | "research"
  | "unknown";

export type TransactionType =
  | "starting_inventory"
  | "purchase_single"
  | "purchase_lot"
  | "sale"
  | "trade"
  | "grading_submission"
  | "grading_return"
  | "consignment_send"
  | "consignment_sale"
  | "adjustment"
  | "correction"
  | "location_transfer";

export type OwnershipEventType =
  | "starting_inventory"
  | "purchase"
  | "lot_purchase"
  | "trade_in"
  | "trade_out"
  | "sale"
  | "grading_submission"
  | "grading_return"
  | "consignment_send"
  | "consignment_sale"
  | "adjustment"
  | "correction"
  | "location_transfer"
  | "archive";

export type BasisEventType =
  | "starting_basis"
  | "purchase_basis"
  | "lot_allocation"
  | "trade_allocation"
  | "grading_cost"
  | "consignment_fee"
  | "correction"
  | "adjustment";

export type LotAllocationMethod =
  | "proportional_by_estimated_value"
  | "equal_split"
  | "manual"
  | "anchor_item";
