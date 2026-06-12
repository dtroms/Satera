import { formatMoney } from "@/lib/core/internal/format";

export function MoneyDisplay({
  value,
}: {
  value: number | string | null | undefined;
}) {
  return <span className="font-mono tabular-nums">{formatMoney(value)}</span>;
}
