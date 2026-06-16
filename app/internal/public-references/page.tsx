import {
  InternalPageHeader,
  InternalTable,
  OwnerContextBadge,
  ShortId,
} from "@/components/internal";
import { requireInternalAccess } from "@/lib/core/internal/access";
import { formatDateTime } from "@/lib/core/internal/format";
import {
  getInternalPublicObjectReferences,
  type InternalRecord,
} from "@/lib/core/internal/queries";

export const dynamic = "force-dynamic";

function nullableShortId(id: string | null | undefined) {
  return id ? <ShortId id={id} /> : "-";
}

function ownerContext(record: InternalRecord) {
  return <OwnerContextBadge record={record} />;
}

export default async function InternalPublicReferencesPage() {
  await requireInternalAccess();
  const references = await getInternalPublicObjectReferences();

  return (
    <main className="mx-auto max-w-7xl px-6 py-10">
      <InternalPageHeader
        title="Public References"
        description="Read-only safe exposure records. These are not private inventory truth records."
        backHref="/internal"
        backLabel="Internal home"
      />

      <section className="mt-8">
        <InternalTable
          rows={references}
          emptyMessage="No public object references are visible to this internal session."
          columns={[
            {
              key: "id",
              header: "Ref",
              render: (reference) => <ShortId id={reference.id} />,
            },
            {
              key: "object_type",
              header: "Object",
              render: (reference) => reference.object_type,
            },
            {
              key: "product",
              header: "Product",
              render: (reference) => <ShortId id={reference.product_id} />,
            },
            {
              key: "category",
              header: "Category",
              render: (reference) => nullableShortId(reference.category_id),
            },
            {
              key: "inventory",
              header: "Inventory",
              render: (reference) =>
                nullableShortId(reference.inventory_item_id),
            },
            {
              key: "title",
              header: "Title",
              render: (reference) => reference.display_title,
            },
            {
              key: "visibility",
              header: "Visibility",
              render: (reference) => reference.visibility,
            },
            {
              key: "state",
              header: "State",
              render: (reference) => reference.exposure_state,
            },
            {
              key: "created_for",
              header: "Created For",
              render: (reference) => reference.created_for ?? "-",
            },
            {
              key: "created_from",
              header: "Created From",
              render: (reference) => reference.created_from ?? "-",
            },
            {
              key: "owner",
              header: "Owner",
              render: ownerContext,
            },
            {
              key: "created",
              header: "Created",
              render: (reference) => formatDateTime(reference.created_at),
            },
            {
              key: "updated",
              header: "Updated",
              render: (reference) => formatDateTime(reference.updated_at),
            },
          ]}
        />
      </section>
    </main>
  );
}
