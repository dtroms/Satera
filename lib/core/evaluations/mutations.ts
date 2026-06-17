import type {
  AddEvaluationCaseItemInput,
  ApplyEvaluationBasisIncreaseInput,
  CoreDbClient,
  CreateEvaluationCaseInput,
  RecordEvaluationResultInput,
  UpdateEvaluationCaseStatusInput,
} from "./types";

function requireRpcId(data: string | { id?: string } | null): string {
  if (typeof data === "string" && data) {
    return data;
  }

  if (data && typeof data === "object" && typeof data.id === "string") {
    return data.id;
  }

  throw new Error("Evaluation RPC did not return an id.");
}

export async function createEvaluationCase(
  db: CoreDbClient,
  input: CreateEvaluationCaseInput,
): Promise<string> {
  const { data, error } = await db.rpc("create_evaluation_case", {
    p_workspace_id: input.workspaceId,
    p_product_id: input.productId ?? null,
    p_case_type: input.caseType,
    p_provider_name: input.providerName ?? null,
    p_provider_reference: input.providerReference ?? null,
    p_opened_at: input.openedAt ?? null,
    p_expected_return_at: input.expectedReturnAt ?? null,
    p_total_declared_value: input.totalDeclaredValue ?? null,
    p_total_evaluation_cost: input.totalEvaluationCost ?? 0,
    p_total_shipping_cost: input.totalShippingCost ?? 0,
    p_total_insurance_cost: input.totalInsuranceCost ?? 0,
    p_total_other_costs: input.totalOtherCosts ?? 0,
    p_notes: input.notes ?? null,
    p_metadata: input.metadata ?? {},
  });

  if (error) {
    throw error;
  }

  return requireRpcId(data);
}

export async function addEvaluationCaseItem(
  db: CoreDbClient,
  input: AddEvaluationCaseItemInput,
): Promise<string> {
  const { data, error } = await db.rpc("add_evaluation_case_item", {
    p_evaluation_case_id: input.evaluationCaseId,
    p_inventory_item_id: input.inventoryItemId,
    p_declared_value: input.declaredValue ?? null,
    p_allocated_evaluation_cost: input.allocatedEvaluationCost ?? 0,
    p_allocated_shipping_cost: input.allocatedShippingCost ?? 0,
    p_allocated_insurance_cost: input.allocatedInsuranceCost ?? 0,
    p_allocated_other_costs: input.allocatedOtherCosts ?? 0,
    p_provider_item_reference: input.providerItemReference ?? null,
    p_notes: input.notes ?? null,
  });

  if (error) {
    throw error;
  }

  return requireRpcId(data);
}

export async function updateEvaluationCaseStatus(
  db: CoreDbClient,
  input: UpdateEvaluationCaseStatusInput,
): Promise<string> {
  const { data, error } = await db.rpc("update_evaluation_case_status", {
    p_evaluation_case_id: input.evaluationCaseId,
    p_status: input.status,
    p_occurred_at: input.occurredAt ?? null,
    p_notes: input.notes ?? null,
    p_metadata: input.metadata ?? {},
  });

  if (error) {
    throw error;
  }

  return requireRpcId(data);
}

export async function recordEvaluationResult(
  db: CoreDbClient,
  input: RecordEvaluationResultInput,
): Promise<string> {
  const { data, error } = await db.rpc("record_evaluation_result", {
    p_evaluation_case_item_id: input.evaluationCaseItemId,
    p_item_status: input.itemStatus ?? "completed",
    p_result_summary: input.resultSummary ?? null,
    p_result_grade: input.resultGrade ?? null,
    p_result_authenticity: input.resultAuthenticity ?? null,
    p_result_certification_number: input.resultCertificationNumber ?? null,
    p_result_metadata: input.resultMetadata ?? {},
    p_notes: input.notes ?? null,
  });

  if (error) {
    throw error;
  }

  return requireRpcId(data);
}

export async function applyEvaluationBasisIncrease(
  db: CoreDbClient,
  input: ApplyEvaluationBasisIncreaseInput,
): Promise<string> {
  const { data, error } = await db.rpc("apply_evaluation_basis_increase", {
    p_evaluation_case_item_id: input.evaluationCaseItemId,
    p_basis_increase_amount: input.basisIncreaseAmount,
    p_notes: input.notes ?? null,
  });

  if (error) {
    throw error;
  }

  return requireRpcId(data);
}
