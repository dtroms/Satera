import {
  EmptyState,
  InternalPageHeader,
  InternalTable,
  JsonBlock,
  ShortId,
} from "@/components/internal";
import { requireInternalAccess } from "@/lib/core/internal/access";
import {
  formatDateTime,
  formatEnumLabel,
} from "@/lib/core/internal/format";
import {
  getInternalAssetFamilies,
  getInternalAssetVariants,
  getInternalCategories,
  getInternalProductCategories,
  getInternalProducts,
  type InternalRecord,
} from "@/lib/core/internal/queries";

export const dynamic = "force-dynamic";

function relationLabel(record: InternalRecord, relation: string, fallback = "-") {
  const related = record[relation] as InternalRecord | null | undefined;
  return related?.name ?? related?.slug ?? related?.variant_key ?? fallback;
}

function Section({
  title,
  children,
}: {
  title: string;
  children: React.ReactNode;
}) {
  return (
    <section className="mt-8">
      <h2 className="mb-3 text-lg font-semibold text-neutral-950">{title}</h2>
      {children}
    </section>
  );
}

async function getRowsSafely(
  label: string,
  loader: Promise<InternalRecord[]>,
): Promise<{ rows: InternalRecord[]; errorMessage: string | null }> {
  try {
    return { rows: await loader, errorMessage: null };
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown error";
    return { rows: [], errorMessage: `${label} could not be loaded: ${message}` };
  }
}

export default async function InternalProductsPage() {
  await requireInternalAccess();
  const [
    products,
    productCategories,
    categories,
    assetFamilies,
    assetVariants,
  ] = await Promise.all([
    getRowsSafely("Products", getInternalProducts()),
    getRowsSafely("Product categories", getInternalProductCategories()),
    getRowsSafely("Categories", getInternalCategories()),
    getRowsSafely("Asset families", getInternalAssetFamilies()),
    getRowsSafely("Asset variants", getInternalAssetVariants()),
  ]);

  return (
    <main className="mx-auto max-w-7xl px-6 py-10">
      <InternalPageHeader
        title="Products And Catalog"
        description="Read-only product/category lens map. Card Vertex, Vertex Pro, and Satera Portfolio are product lenses over Core categories, not inventory owners."
        backHref="/internal"
        backLabel="Internal home"
      />

      <Section title="Products">
        {products.errorMessage ? (
          <EmptyState message={products.errorMessage} />
        ) : (
          <InternalTable
          rows={products.rows}
          emptyMessage="No products are visible to this internal session."
          columns={[
            { key: "slug", header: "Slug", render: (row) => row.slug },
            { key: "name", header: "Name", render: (row) => row.name },
            {
              key: "type",
              header: "Type",
              render: (row) => formatEnumLabel(row.product_type),
            },
            {
              key: "status",
              header: "Status",
              render: (row) => formatEnumLabel(row.status),
            },
            {
              key: "created",
              header: "Created",
              render: (row) => formatDateTime(row.created_at),
            },
          ]}
          />
        )}
      </Section>

      <Section title="Product Categories">
        {productCategories.errorMessage ? (
          <EmptyState message={productCategories.errorMessage} />
        ) : (
          <InternalTable
            rows={productCategories.rows}
            emptyMessage="No product/category mappings are visible to this internal session."
            columns={[
              {
                key: "product",
                header: "Product",
                render: (row) => relationLabel(row, "product", row.product_id),
              },
              {
                key: "category",
                header: "Category",
                render: (row) => relationLabel(row, "category", row.category_id),
              },
              {
                key: "mapping",
                header: "Mapping ID",
                render: (row) => <ShortId id={row.id} />,
              },
              {
                key: "created",
                header: "Created",
                render: (row) => formatDateTime(row.created_at),
              },
            ]}
          />
        )}
      </Section>

      <Section title="Categories">
        {categories.errorMessage ? (
          <EmptyState message={categories.errorMessage} />
        ) : (
          <InternalTable
            rows={categories.rows}
            emptyMessage="No categories are visible to this internal session."
            columns={[
              { key: "slug", header: "Slug", render: (row) => row.slug },
              { key: "name", header: "Name", render: (row) => row.name },
              {
                key: "description",
                header: "Description",
                render: (row) => row.description ?? "-",
              },
            ]}
          />
        )}
      </Section>

      <Section title="Asset Families">
        {assetFamilies.errorMessage ? (
          <EmptyState message={assetFamilies.errorMessage} />
        ) : (
          <InternalTable
            rows={assetFamilies.rows}
            emptyMessage="No asset families are visible to this internal session."
            columns={[
              { key: "name", header: "Name", render: (row) => row.name },
              {
                key: "category",
                header: "Category",
                render: (row) => relationLabel(row, "category", row.category_id),
              },
              {
                key: "collection",
                header: "Collection",
                render: (row) => relationLabel(row, "collection"),
              },
              {
                key: "canonical",
                header: "Canonical Key",
                render: (row) => row.canonical_key ?? "-",
              },
              {
                key: "attributes",
                header: "Attributes",
                render: (row) => <JsonBlock value={row.attributes} />,
              },
            ]}
          />
        )}
      </Section>

      <Section title="Asset Variants">
        {assetVariants.errorMessage ? (
          <EmptyState message={assetVariants.errorMessage} />
        ) : (
          <InternalTable
            rows={assetVariants.rows}
            emptyMessage="No asset variants are visible to this internal session."
            columns={[
              { key: "name", header: "Name", render: (row) => row.name },
              {
                key: "family",
                header: "Family",
                render: (row) =>
                  relationLabel(row, "asset_family", row.asset_family_id),
              },
              {
                key: "category",
                header: "Category",
                render: (row) => relationLabel(row, "category", row.category_id),
              },
              {
                key: "variant",
                header: "Variant Key",
                render: (row) => row.variant_key ?? "-",
              },
              {
                key: "attributes",
                header: "Attributes",
                render: (row) => <JsonBlock value={row.attributes} />,
              },
            ]}
          />
        )}
      </Section>
    </main>
  );
}
