import { formatOwnerContext } from "@/lib/core/internal/format";

type OwnerContextRecord = {
  owner_user_id?: string | null;
  workspace_id?: string | null;
  organization_id?: string | null;
};

export function OwnerContextBadge({ record }: { record: OwnerContextRecord }) {
  return (
    <span className="inline-flex border border-neutral-300 bg-neutral-50 px-2 py-1 text-xs text-neutral-700">
      {formatOwnerContext(record)}
    </span>
  );
}
