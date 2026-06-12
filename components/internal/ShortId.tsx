import { formatShortId } from "@/lib/core/internal/format";

export function ShortId({ id }: { id: string | null | undefined }) {
  return (
    <span className="font-mono text-xs tabular-nums text-neutral-800">
      {formatShortId(id)}
    </span>
  );
}
