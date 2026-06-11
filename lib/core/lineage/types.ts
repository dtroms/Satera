export type OwnershipTimelineEntry = {
  id: string;
  inventory_item_id: string;
  transaction_id: string | null;
  event_type: string;
  event_date: string;
  previous_status: string | null;
  new_status: string | null;
  previous_owner_context: Record<string, unknown> | null;
  new_owner_context: Record<string, unknown> | null;
  notes: string | null;
  created_at: string;
  transaction?: Record<string, unknown> | null;
};

export type BasisLineage = {
  basisEvents: Record<string, unknown>[];
  lineageEdges: Record<string, unknown>[];
  transactionLines: Record<string, unknown>[];
};

export type InventoryLineageSummary = {
  inventoryItemId: string;
  entryEvent: OwnershipTimelineEntry | null;
  latestOwnershipEvent: OwnershipTimelineEntry | null;
  basisEventCount: number;
  lineageEdgeCount: number;
  transactionLineCount: number;
  currentBasis: number | null;
};
