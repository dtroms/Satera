import type { ReactNode } from "react";

type Column<T> = {
  key: string;
  header: string;
  render: (row: T) => ReactNode;
};

type InternalTableProps<T> = {
  columns: Column<T>[];
  rows: T[];
  emptyMessage: string;
};

export function InternalTable<T>({
  columns,
  rows,
  emptyMessage,
}: InternalTableProps<T>) {
  if (rows.length === 0) {
    return (
      <div className="border border-dashed border-neutral-300 px-4 py-8 text-sm text-neutral-600">
        {emptyMessage}
      </div>
    );
  }

  return (
    <div className="overflow-x-auto border border-neutral-300">
      <table className="min-w-full border-collapse text-left text-sm">
        <thead className="bg-neutral-100 text-xs uppercase tracking-[0.08em] text-neutral-600">
          <tr>
            {columns.map((column) => (
              <th
                key={column.key}
                scope="col"
                className="border-b border-neutral-300 px-3 py-2 font-semibold"
              >
                {column.header}
              </th>
            ))}
          </tr>
        </thead>
        <tbody className="divide-y divide-neutral-200 bg-white">
          {rows.map((row, index) => (
            <tr key={index} className="align-top">
              {columns.map((column) => (
                <td key={column.key} className="whitespace-nowrap px-3 py-2">
                  {column.render(row)}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
