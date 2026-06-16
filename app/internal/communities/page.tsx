import Link from "next/link";
import {
  InternalPageHeader,
  InternalTable,
  OwnerContextBadge,
  ShortId,
} from "@/components/internal";
import { requireInternalAccess } from "@/lib/core/internal/access";
import { formatDateTime } from "@/lib/core/internal/format";
import {
  getInternalCommunities,
  type InternalRecord,
} from "@/lib/core/internal/queries";

export const dynamic = "force-dynamic";

function nullableShortId(id: string | null | undefined) {
  return id ? <ShortId id={id} /> : "-";
}

export default async function InternalCommunitiesPage() {
  await requireInternalAccess();
  const communities = await getInternalCommunities();

  return (
    <main className="mx-auto max-w-7xl px-6 py-10">
      <InternalPageHeader
        title="Communities"
        description="Read-only product-scoped Community Core records. Product-specific community UX belongs in products."
        backHref="/internal"
        backLabel="Internal home"
      />

      <section className="mt-8">
        <InternalTable
          rows={communities}
          emptyMessage="No communities are visible to this internal session."
          columns={[
            {
              key: "id",
              header: "Community",
              render: (community) => (
                <Link
                  href={`/internal/communities/${community.id}`}
                  className="underline-offset-4 hover:underline"
                >
                  <ShortId id={community.id} />
                </Link>
              ),
            },
            { key: "name", header: "Name", render: (community) => community.name },
            { key: "slug", header: "Slug", render: (community) => community.slug },
            {
              key: "product",
              header: "Product",
              render: (community) => nullableShortId(community.product_id),
            },
            {
              key: "owner",
              header: "Owner",
              render: (community: InternalRecord) => (
                <OwnerContextBadge record={community} />
              ),
            },
            {
              key: "type",
              header: "Type",
              render: (community) => community.community_type,
            },
            {
              key: "visibility",
              header: "Visibility",
              render: (community) => community.visibility,
            },
            {
              key: "status",
              header: "Status",
              render: (community) => community.status,
            },
            {
              key: "created_by",
              header: "Created By",
              render: (community) => nullableShortId(community.created_by),
            },
            {
              key: "created",
              header: "Created",
              render: (community) => formatDateTime(community.created_at),
            },
            {
              key: "updated",
              header: "Updated",
              render: (community) => formatDateTime(community.updated_at),
            },
          ]}
        />
      </section>
    </main>
  );
}
