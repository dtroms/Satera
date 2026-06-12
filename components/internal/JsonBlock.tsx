export function JsonBlock({ value }: { value: unknown }) {
  return (
    <pre className="overflow-x-auto border border-neutral-300 bg-neutral-950 p-3 text-xs leading-5 text-neutral-50">
      {JSON.stringify(value, null, 2)}
    </pre>
  );
}
