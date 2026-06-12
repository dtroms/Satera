import Link from "next/link";

type InternalPageHeaderProps = {
  title: string;
  eyebrow?: string;
  description?: string;
  backHref?: string;
  backLabel?: string;
};

export function InternalPageHeader({
  title,
  eyebrow = "Satera Core Internal Inspector",
  description,
  backHref,
  backLabel = "Back",
}: InternalPageHeaderProps) {
  return (
    <header className="border-b border-neutral-300 pb-5">
      {backHref ? (
        <Link
          href={backHref}
          className="mb-4 inline-block text-sm text-neutral-600 underline-offset-4 hover:underline"
        >
          {backLabel}
        </Link>
      ) : null}
      <p className="text-xs font-semibold uppercase tracking-[0.14em] text-neutral-500">
        {eyebrow}
      </p>
      <h1 className="mt-2 text-3xl font-semibold text-neutral-950">{title}</h1>
      {description ? (
        <p className="mt-3 max-w-3xl text-sm leading-6 text-neutral-700">
          {description}
        </p>
      ) : null}
    </header>
  );
}
