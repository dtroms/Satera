import type { PurchaseBasisInput } from "@/lib/calculations/basis";
import type {
  ConditionType,
  InventoryAvailability,
  InventoryIntent,
  InventoryStatus,
} from "@/lib/core/types";
import type { OwnerContext } from "@/lib/core/inventory/types";

export type StartingInventoryBasis = number | null | undefined;

export type StartingInventoryTransactionInput = OwnerContext & {
  categoryId: string;
  assetVariantId: string;
  conditionType?: ConditionType;
  status?: InventoryStatus;
  availability?: InventoryAvailability;
  intent?: InventoryIntent;
  locationId?: string | null;
  acquiredAt?: string | null;
  transactionDate: string;
  source?: string | null;
  counterparty?: string | null;
  notes?: string | null;
  initialBasis?: StartingInventoryBasis;
  createdBy: string;
};

export type PurchaseTransactionInput = OwnerContext & {
  categoryId: string;
  assetVariantId: string;
  conditionType?: ConditionType;
  status?: InventoryStatus;
  availability?: InventoryAvailability;
  intent?: InventoryIntent;
  locationId?: string | null;
  acquiredAt?: string | null;
  transactionDate: string;
  source?: string | null;
  counterparty?: string | null;
  notes?: string | null;
  marketValueAtTime?: number | null;
  purchaseBasis: PurchaseBasisInput;
  createdBy: string;
};

export type TradeOutgoingItemInput = {
  inventoryItemId: string;
  tradeValue: number;
};

export type TradeIncomingItemInput = {
  categoryId: string;
  assetVariantId: string;
  conditionType?: ConditionType;
  status?: InventoryStatus;
  availability?: InventoryAvailability;
  intent?: InventoryIntent;
  locationId?: string | null;
  tradeValue: number;
  notes?: string | null;
};

export type TradeTransactionInput = OwnerContext & {
  transactionDate?: string | null;
  source?: string | null;
  counterparty?: string | null;
  notes?: string | null;
  outgoingItems: TradeOutgoingItemInput[];
  incomingItems: TradeIncomingItemInput[];
  cashPaid?: number;
  cashReceived?: number;
  tradeRelatedCosts?: number;
  createdBy: string;
};

export type SaleTransactionInput = OwnerContext & {
  inventoryItemId: string;
  salePrice: number;
  platformFees?: number;
  paymentProcessingFees?: number;
  shippingCost?: number;
  suppliesCost?: number;
  consignmentFees?: number;
  otherSellingCosts?: number;
  transactionDate?: string | null;
  source?: string | null;
  counterparty?: string | null;
  notes?: string | null;
  createdBy: string;
};

export type LotAllocationMethod = "manual" | "equal";

export type CreateLotPurchaseItemInput = {
  assetVariantId: string;
  conditionType?: ConditionType;
  allocatedBasis?: number;
  collectionId?: string | null;
  locationId?: string | null;
  acquisitionNotes?: string | null;
  privateNotes?: string | null;
  inventoryStatus?: InventoryStatus;
  availability?: InventoryAvailability;
  intent?: InventoryIntent;
};

export type CreateLotPurchaseTransactionInput = {
  workspaceId: string;
  productId?: string | null;
  purchasePrice: number;
  purchasedAt?: string | null;
  sellerReference?: string | null;
  marketplace?: string | null;
  orderReference?: string | null;
  buyerFees?: number;
  tax?: number;
  shipping?: number;
  otherAcquisitionCosts?: number;
  allocationMethod?: LotAllocationMethod;
  items: CreateLotPurchaseItemInput[];
  notes?: string | null;
  createdBy: string;
};

export type NormalizedBasis = {
  basisProvided: boolean;
  trueBasis: number | null;
};

export type AtomicTransactionResult = {
  inventoryItemId: string;
  transactionId: string;
};

export type TradeTransactionResult = {
  transactionId: string;
  incomingInventoryItemIds: string[];
  outgoingInventoryItemIds: string[];
};

export type SaleTransactionResult = {
  transactionId: string;
  inventoryItemId: string;
  grossSalePrice: number;
  sellingCosts: number;
  netProceeds: number;
  basisAtSale: number;
  realizedProfitLoss: number;
};

export type CreateLotPurchaseTransactionResult = {
  transactionId: string;
  inventoryItemIds: string[];
  totalLotBasis: number;
};
