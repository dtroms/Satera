import type { ReactNode } from "react";

type KeyValueItem = {
  label: string;
  value: ReactNode;
};

export function KeyValueGrid({ items }: { items: KeyValueItem[] }) {
  return (
    <dl className="grid grid-cols-1 border border-neutral-300 bg-white sm:grid-cols-2 lg:grid-cols-3">
      {items.map((item) => (
        <div key={item.label} className="border-b border-r border-neutral-200 p-3">
          <dt className="text-xs uppercase tracking-[0.08em] text-neutral-500">
            {item.label}
          </dt>
          <dd className="mt-1 break-words text-sm text-neutral-950">
            {item.value ?? "-"}
          </dd>
        </div>
      ))}
    </dl>
  );
}
