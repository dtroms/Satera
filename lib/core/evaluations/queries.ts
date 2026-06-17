import type {
  CoreDbClient,
  EvaluationCase,
  EvaluationCaseItem,
  EvaluationEvent,
} from "./types";

const EVALUATION_CASE_SELECT = "*";
const EVALUATION_CASE_ITEM_SELECT = "*";
const EVALUATION_EVENT_SELECT = "*";

export async function getEvaluationCases(
  db: CoreDbClient,
  filters: { workspaceId?: string; productId?: string; status?: string } = {},
): Promise<EvaluationCase[]> {
  let query = db
    .from("evaluation_cases")
    .select(EVALUATION_CASE_SELECT)
    .order("opened_at", { ascending: false })
    .order("created_at", { ascending: false })
    .limit(100);

  if (filters.workspaceId) {
    query = query.eq("workspace_id", filters.workspaceId);
  }

  if (filters.productId) {
    query = query.eq("product_id", filters.productId);
  }

  if (filters.status) {
    query = query.eq("status", filters.status);
  }

  const { data, error } = await query;

  if (error) {
    throw error;
  }

  return data ?? [];
}

export async function getEvaluationCaseById(
  db: CoreDbClient,
  evaluationCaseId: string,
): Promise<EvaluationCase | null> {
  const { data, error } = await db
    .from("evaluation_cases")
    .select(EVALUATION_CASE_SELECT)
    .eq("id", evaluationCaseId)
    .maybeSingle();

  if (error) {
    throw error;
  }

  return data ?? null;
}

export async function getEvaluationCaseItems(
  db: CoreDbClient,
  evaluationCaseId: string,
): Promise<EvaluationCaseItem[]> {
  const { data, error } = await db
    .from("evaluation_case_items")
    .select(EVALUATION_CASE_ITEM_SELECT)
    .eq("evaluation_case_id", evaluationCaseId)
    .order("created_at", { ascending: true });

  if (error) {
    throw error;
  }

  return data ?? [];
}

export async function getEvaluationEvents(
  db: CoreDbClient,
  evaluationCaseId: string,
): Promise<EvaluationEvent[]> {
  const { data, error } = await db
    .from("evaluation_events")
    .select(EVALUATION_EVENT_SELECT)
    .eq("evaluation_case_id", evaluationCaseId)
    .order("occurred_at", { ascending: true })
    .order("created_at", { ascending: true });

  if (error) {
    throw error;
  }

  return data ?? [];
}
