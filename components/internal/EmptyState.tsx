export function EmptyState({ message }: { message: string }) {
  return (
    <div className="border border-dashed border-neutral-300 px-4 py-8 text-sm text-neutral-600">
      {message}
    </div>
  );
}
