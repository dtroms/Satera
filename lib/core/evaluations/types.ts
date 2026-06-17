import type { CoreDbClient } from "@/lib/core/inventory/types";

export type { CoreDbClient };

export type EvaluationCaseType =
  | "grading"
  | "authentication"
  | "appraisal"
  | "certification"
  | "condition_review"
  | "restoration_review"
  | "service"
  | "provenance_review"
  | "other";

export type EvaluationCaseStatus =
  | "draft"
  | "prepared"
  | "submitted"
  | "in_review"
  | "received"
  | "completed"
  | "returned"
  | "canceled"
  | "lost"
  | "on_hold";

export type EvaluationCaseItemStatus =
  | "included"
  | "submitted"
  | "in_review"
  | "completed"
  | "returned"
  | "canceled"
  | "rejected"
  | "lost"
  | "damaged";

export type EvaluationCase = {
  id: string;
  workspace_id: string;
  product_id: string | null;
  organization_id: string | null;
  case_type: EvaluationCaseType;
  provider_name: string | null;
  provider_reference: string | null;
  status: EvaluationCaseStatus;
  opened_at: string;
  submitted_at: string | null;
  received_at: string | null;
  completed_at: string | null;
  canceled_at: string | null;
  returned_at: string | null;
  expected_return_at: string | null;
  total_declared_value: number | null;
  total_evaluation_cost: number;
  total_shipping_cost: number;
  total_insurance_cost: number;
  total_other_costs: number;
  total_case_cost: number;
  notes: string | null;
  metadata: Record<string, unknown>;
  created_by: string;
  created_at: string;
  updated_at: string;
};

export type EvaluationCaseItem = {
  id: string;
  evaluation_case_id: string;
  inventory_item_id: string;
  product_id: string | null;
  item_status: EvaluationCaseItemStatus;
  declared_value: number | null;
  allocated_evaluation_cost: number;
  allocated_shipping_cost: number;
  allocated_insurance_cost: number;
  allocated_other_costs: number;
  allocated_total_cost: number;
  basis_increase_amount: number;
  provider_item_reference: string | null;
  result_summary: string | null;
  result_grade: string | null;
  result_authenticity: string | null;
  result_certification_number: string | null;
  result_metadata: Record<string, unknown>;
  notes: string | null;
  created_at: string;
  updated_at: string;
};

export type EvaluationEvent = {
  id: string;
  evaluation_case_id: string;
  evaluation_case_item_id: string | null;
  event_type: string;
  from_status: string | null;
  to_status: string | null;
  occurred_at: string;
  notes: string | null;
  metadata: Record<string, unknown>;
  created_by: string;
  created_at: string;
};

export type EvaluationAttachment = {
  id: string;
  evaluation_case_id: string;
  evaluation_case_item_id: string | null;
  attachment_type: string;
  storage_path: string | null;
  external_url: string | null;
  provider_asset_id: string | null;
  title: string | null;
  metadata: Record<string, unknown>;
  created_by: string;
  created_at: string;
};

export type CreateEvaluationCaseInput = {
  workspaceId: string;
  productId?: string | null;
  caseType: EvaluationCaseType;
  providerName?: string | null;
  providerReference?: string | null;
  openedAt?: string | null;
  expectedReturnAt?: string | null;
  totalDeclaredValue?: number | null;
  totalEvaluationCost?: number;
  totalShippingCost?: number;
  totalInsuranceCost?: number;
  totalOtherCosts?: number;
  notes?: string | null;
  metadata?: Record<string, unknown>;
};

export type AddEvaluationCaseItemInput = {
  evaluationCaseId: string;
  inventoryItemId: string;
  declaredValue?: number | null;
  allocatedEvaluationCost?: number;
  allocatedShippingCost?: number;
  allocatedInsuranceCost?: number;
  allocatedOtherCosts?: number;
  providerItemReference?: string | null;
  notes?: string | null;
};

export type UpdateEvaluationCaseStatusInput = {
  evaluationCaseId: string;
  status: EvaluationCaseStatus;
  occurredAt?: string | null;
  notes?: string | null;
  metadata?: Record<string, unknown>;
};

export type RecordEvaluationResultInput = {
  evaluationCaseItemId: string;
  itemStatus?: EvaluationCaseItemStatus;
  resultSummary?: string | null;
  resultGrade?: string | null;
  resultAuthenticity?: string | null;
  resultCertificationNumber?: string | null;
  resultMetadata?: Record<string, unknown>;
  notes?: string | null;
};

export type ApplyEvaluationBasisIncreaseInput = {
  evaluationCaseItemId: string;
  basisIncreaseAmount: number;
  notes?: string | null;
};
