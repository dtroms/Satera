# Card Vertex Card Identity And Catalog Strategy

This document defines the proposed Card Vertex strategy for card identity,
catalog structure, owned-card identity, grading/certification identity,
provisional intake, aliases, external source mappings, and image provenance.
It is product-domain decision documentation only. It does not authorize schema,
RPC, route, UI, provider-integration, migration, seed, or build-tooling work.

Satera Core owns canonical inventory, ownership, privacy, permissions,
transaction truth, basis, lineage, audit, and safe public-object-reference
infrastructure. Card Vertex owns sports-card semantics, card identity
interpretation, catalog behavior, card-specific search, card-specific intake,
card-specific matching, card-specific market context, and collector-facing
workflows.

A Card Vertex-specific catalog record may live in the shared Satera database
without becoming a generic Satera Core catalog abstraction. The existing
generic `asset_families` and `asset_variants` tables are useful current
infrastructure, but they are not an approved sports-card catalog design.

## Identity Model

Card Vertex should keep four identity layers distinct.

### 1. Catalog Card Identity

Catalog Card Identity represents the collectible definition independent of
ownership. It describes what the card was issued as.

Examples:

- 2018 Panini Prizm Luka Doncic Silver #280
- 2020 Topps Chrome Luis Robert Base Rookie #60
- 2024 Topps Chrome Elly De La Cruz Orange Refractor #/25

Catalog identity should hold the issued-card meaning: sport, league,
manufacturer/brand, product/release, set/subset, card number, subject, team,
rookie designation, issued parallel or variation, issued print run,
program-issued autograph or memorabilia designation, language/region, and
error/correction status when those are part of the issued card.

### 2. Owned Card Instance

Owned Card Instance represents one specific physical copy owned by a collector.

Owned-copy information includes owner/workspace, acquisition history, basis,
storage location, private notes, intent, availability, condition, item images,
exact serial number when applicable, current inventory state, sale/trade or
consignment history, private tags, aftermarket signatures, alterations, damage,
and copy-specific history.

### 3. Evaluation / Certification State

Evaluation / Certification State represents grading or certification
information tied to an owned physical copy.

Examples include grading company, grade, certification number, grading
submission history, evaluation notes, evaluation costs, result date, and later
reholder or crossover history.

Grade and certification must not create a new catalog-card identity by default.
A PSA 10 and a raw copy of the same issued card usually share the same Catalog
Card Identity. Their difference belongs to the owned card and its evaluation
state.

### 4. Public Card Reference

Public Card Reference is the safe, shareable version of an owned card
instance. It may show card identity, a safe image, grade if intentionally
exposed, market context, trade/sale availability if intentionally exposed, and
approved public metadata.

It must never expose basis, purchase price, profit, location, private notes,
private tags, ownership history, transaction history, grading costs, or private
strategy.

### Why The Layers Stay Separate

These layers answer different questions:

- Catalog Card Identity: What card is this?
- Owned Card Instance: Which physical copy does this collector own?
- Evaluation / Certification State: What has been assessed or certified about
  this copy?
- Public Card Reference: What has the owner intentionally exposed?

Combining them would corrupt core workflows. A grade would accidentally fork
catalog identity, a private serial number could leak into public search, a
sale or trade could mutate catalog truth, or a user-uploaded photo could become
assumed global catalog evidence. Keeping the layers separate lets Card Vertex
search and match cards accurately while Satera preserves ownership, basis,
privacy, lineage, and safe sharing guarantees.

## Catalog Hierarchy

Card Vertex should use this conceptual hierarchy for sports cards:

```text
Sport
-> League
-> Manufacturer / Brand
-> Release Year
-> Product / Release
-> Set
-> Subset / Insert Set
-> Card Number
-> Card Subject(s)
-> Parallel / Variation
-> Catalog Card Identity
```

This is a conceptual hierarchy only, not a final schema. Some products blur
these layers, and the future data model should preserve enough flexibility for
multi-subject cards, multi-team cards, regional releases, inserts, image
variations, and checklist inconsistencies.

### Concept Placement

| Concept | Recommended home | Notes |
| --- | --- | --- |
| Sport | Catalog identity | Card Vertex semantic context, not owner data. |
| League | Catalog identity | Useful for search, filters, and product meaning. |
| Manufacturer | Catalog identity | Company that issued the card or product. |
| Brand | Catalog identity | May differ from manufacturer, such as Topps Chrome under Topps. |
| Release year | Catalog identity | Usually product/release year, not acquisition year. |
| Product / release | Catalog identity | Defines the issued product line. |
| Set | Catalog identity | Main checklist grouping. |
| Subset or insert | Catalog identity | Insert sets and subsets are issued-card meaning. |
| Card number | Catalog identity | Normalize display and search formats. |
| Player / subject | Catalog identity | Multi-subject support is required later. |
| Team | Catalog identity | Team shown or assigned on the issued card; ownership-independent. |
| Rookie designation | Catalog identity, with source/evidence policy | Requires controlled rules because collectors and sources disagree. |
| Parallel | Catalog identity | Usually defines a distinct issued card identity. |
| Print run | Catalog identity | `/25` is usually issued-card meaning. |
| Serial-numbered issue | Catalog identity | The fact the issue is serial-numbered belongs to the catalog. |
| Exact serial number | Owned-card instance | `07/25` identifies the physical copy. |
| Autograph | Catalog identity when program-issued; owned-card history when aftermarket | Distinguish pack-issued/certified auto from in-person signing. |
| Memorabilia / relic | Catalog identity when program-issued | Relic designation is issued-card meaning. |
| Patch variation | Catalog identity when product-issued; owned-card copy detail when patch uniqueness matters | Needs later product decision for patch-quality and unique swatch details. |
| Image variation | Catalog identity | If issued as a recognized variation. |
| Error / correction | Catalog identity | Preserve issued error/correction status and source evidence. |
| Language / region | Catalog identity | Important for international releases. |
| Raw | Owned-card instance / evaluation state | Not a catalog identity by default. |
| Graded | Evaluation / certification state | Not a catalog identity by default. |
| Certification number | Evaluation / certification state | Copy-specific and tied to a grader/certification event. |

Future variant/modification layers may be needed for aftermarket signatures,
alterations, restoration, trimming, damage, custom slabs, buybacks, reholders,
crossover history, and copy-specific patch details. Those should not be forced
into Catalog Card Identity without a product decision.

## Catalog Source Strategy

Card Vertex should use a phased hybrid source strategy.

### Source Options

- User-created catalog records are necessary for speed and long-tail coverage,
  but they need certainty states, review, provenance, and merge policies.
- Internal curated catalog records provide control and consistency for MVP
  scope, but cannot cover the entire hobby quickly.
- Approved or licensed data providers can accelerate enrichment later, but
  provider IDs and names must map to internal Card Vertex identity rather than
  replace it.
- Manufacturer data is valuable when available, especially for checklists,
  print runs, and product-issued attributes, but coverage and format vary.
- User-supplied evidence is useful for provisional creation and corrections,
  but evidence must not become global truth without review.
- Browser-extension capture should be user-initiated evidence capture, not
  scraping or automated catalog ingestion.
- External source mappings preserve provenance and source-specific names while
  maintaining one internal identity.
- Scraping is not approved for catalog or image ingestion.

### Phased Recommendation

Phase 1:

- Use controlled Card Vertex catalog records.
- Allow user-assisted creation and provisional intake.
- Allow user-supplied images and evidence under provenance rules.
- Do not scrape.
- Do not depend on unapproved external images or catalog feeds.
- Assign stable internal Card Vertex IDs.
- Keep catalog scope intentionally narrow for MVP.

Phase 2:

- Add approved/licensed provider or manufacturer mappings.
- Store external identifiers as mappings to Card Vertex canonical identity.
- Review catalog enrichment before it affects shared catalog truth.
- Establish controlled catalog image policy before showing default catalog
  images broadly.

Phase 3:

- Consider broader ingestion only after provenance, licensing, matching,
  moderation, correction, and maintenance policies are proven.

Outside source names and IDs must be mappings because external sources change
names, merge records differently, omit hobby-relevant distinctions, disagree
on rookie/parallel/error labels, and may become unavailable. Card Vertex needs
stable internal identity so inventory, comps, public references, aliases, and
history do not break when a provider changes.

## Provisional Identity And Show-Floor Intake

Card Vertex must support fast, incomplete intake without corrupting the global
catalog. Collectors may have an unknown card at a show, a partially identified
card, an uncertain parallel, a sealed product item, a bulk lot with unresolved
cards, a card needing image review, or uncertain grade/certification details.

Recommended identity certainty states:

- Canonical: approved Card Vertex catalog identity.
- Provisional: controlled temporary identity with enough structure to save and
  continue work.
- Unresolved: free-text or partial details not suitable as global identity.
- Needs Review: candidate identity or correction awaiting review.
- Archived / Superseded: old identity preserved for history and redirected to
  the current identity when appropriate.

Collectors should be able to save incomplete intake into a Draft Lot or Card
Vertex preparation workflow. Final transaction commitment into canonical
inventory should require either a stable approved card identity or an
intentionally created controlled provisional catalog identity.

Unresolved free-text identity must not silently become permanent global catalog
truth.

Draft-only data may include raw notes, quick photos, uncertain player/set
guesses, dealer/show context, unresolved groups, allocation working notes, and
cards not yet split from a bulk lot.

The Draft Lot Workspace architecture defines how those incomplete intake
records move through identity review and final commit:
[`DRAFT_LOT_WORKSPACE_ARCHITECTURE.md`](DRAFT_LOT_WORKSPACE_ARCHITECTURE.md).
The Grading Workspace and Certification Lifecycle contract defines how grading
submissions, grades, certification numbers, reholder/crossover/resubmission
history, Return Review, and grading costs remain owned-card/evaluation state:
[`GRADING_WORKSPACE_AND_CERTIFICATION_LIFECYCLE.md`](GRADING_WORKSPACE_AND_CERTIFICATION_LIFECYCLE.md).

Private provisional identity may be appropriate when the collector needs to
track a physical item privately before review but the identity is not ready for
shared catalog use.

A shared Card Vertex catalog candidate may be created when the user provides
structured fields and evidence sufficient for review.

Use in public references, comps, Trade Network, community sharing, or public
search should require review or explicit provisional labeling. Later
resolution must preserve the original intake story: original text, evidence,
photos, who changed it, when it changed, and which inventory or draft records
were affected.

## Aliases, Normalization, And Corrections

Card Vertex should maintain one stable canonical Card Vertex identity with
multiple aliases and source-specific names mapped to it.

The catalog strategy should support:

- canonical display name
- normalized search name
- aliases
- common collector shorthand
- player naming variants
- manufacturer naming variants
- set naming variations
- parallel naming variations
- numbering formats
- error/correction cards
- catalog merges
- superseded records
- source-specific naming differences

Recommended policy:

- One stable canonical Card Vertex identity per issued card identity.
- Multiple aliases and source-specific names can map to it.
- Canonical display names may improve over time without changing the identity
  ID.
- Merges should not destroy historical references.
- Superseded records should redirect or resolve to the accepted identity while
  preserving lineage.
- Source names should be preserved where relevant for provenance.
- Search should understand aliases later, but normalization must not overwrite
  collector-entered historical notes, source evidence, or original intake text.

## Images And Provenance

Card identity must function without an image. Images improve confidence and
collector experience, but they are evidence and presentation assets, not the
identity itself.

### Image Categories

1. Catalog reference images: default/reference images for an issued card.
2. User-owned inventory photos: front, back, slab, and user-provided item
   photos tied to an owned copy.
3. Grading/slab/certification photos: provider or user photos tied to
   evaluation/certification state.
4. Condition-detail photos: corners, surface, centering, edges, damage, patch,
   autograph, serial number, or other copy-specific details.
5. Public-reference images: intentionally exposed safe images for sharing.
6. Source/evidence screenshots: screenshots or page captures used as evidence
   with attribution and allowed-use constraints.
7. Community attachments: user/shared attachments in Card Vertex community
   contexts.

### Policy

- Catalog images require a clearly documented rights/provenance strategy.
- User-uploaded images belong to the user/workspace context and require
  privacy rules.
- Public sharing must use intentional exposure rules.
- Screenshots and evidence must preserve source attribution and not become
  assumed catalog truth.
- A user-uploaded image should not automatically become the public/default
  catalog image.
- Do not rely on scraped third-party images.
- Public Card References may use safe user-selected images, but private
  storage location, purchase context, and hidden condition photos must remain
  private.

## Mapping To Current Satera Core

Current Core remains useful, but it is not yet a Card Vertex card catalog.

### Useful Core Infrastructure

- `categories` and `product_categories` scope Card Vertex inventory to product
  categories.
- `collections` can act as coarse grouping but are not a full product/release,
  set, subset, and checklist model.
- `asset_families` and `asset_variants` provide current generic pointers for
  inventory, comps, public references, and seeded demo data.
- `inventory_items` represent owned physical items with owner/workspace/org
  scope, status, availability, intent, condition type, location, basis, and
  notes.
- `asset_images` can attach images to generic variants or inventory items, but
  current image roles/provenance are not a complete Card Vertex policy.
- `public_object_references` provide the safe sharing bridge from private
  inventory to public/community/listing/trade contexts.
- `comp_snapshots` provide early owner-scoped value evidence infrastructure
  with source, verification, inclusion/exclusion, grade/company, and evidence
  fields.
- `evaluation_cases` and `evaluation_case_items` provide product-neutral
  grading/certification lifecycle primitives with grade and certification
  result fields.
- Product-lens services support product-scoped reads without overriding
  inventory privacy.
- `packages/satera-core` is the future package boundary product apps should
  use for Core services.

### Temporary Or Generic Placeholders

- `asset_families` and `asset_variants` should be treated as generic current
  placeholders for Core references, not as the approved sports-card catalog
  hierarchy.
- JSON `attributes` may help seed/demo data, but they should not become the
  long-term source of truth for normalized card identity without an explicit
  Card Vertex schema proposal.
- `condition_type = raw` or `graded` is useful owner-item state, not catalog
  identity.
- Current `asset_images` do not settle rights, source, image role, or public
  exposure policy.

### Do Not Repurpose Blindly

- Do not use generic collections as a full sports-card set/subset/release
  system without a product decision.
- Do not make grade or certification number part of `asset_variants` by
  default.
- Do not store exact serial number as catalog identity.
- Do not turn user free text into global catalog truth.
- Do not generalize Card Vertex catalog semantics into Satera Core before
  another product proves matching reusable semantics.

### Likely Later Card Vertex Needs

Later schema design will likely need Card Vertex-specific records or
relationships for canonical card identities, source mappings, aliases,
subjects/teams, product/release/set/subset structure, issued parallels,
provisional identities, catalog review, image provenance, and card-specific
search/matching. This document intentionally does not propose exact SQL or
table names.

## Decision Matrix

| Concept | Recommended home | Why | Current Core support | Data/source risk | Decision status | Required before schema? | Required before MVP UI? |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Card catalog identity | Card Vertex catalog identity | Defines issued card independent of owner | Generic family/variant only | High | Recommend Card Vertex-specific model | Yes | Yes |
| Player/subject | Catalog identity | Card meaning and search | Generic attributes only | Medium | Recommend normalized later | Yes | Yes |
| Team | Catalog identity | Issued-card meaning | Generic attributes only | Medium | Recommend normalized later | Yes | Yes |
| Sport/league | Catalog identity | Product/search context | Categories partially | Low | Recommend catalog context | Yes | Yes |
| Release/product | Catalog identity | Checklist source context | Collections partially | High | Recommend explicit concept later | Yes | Yes |
| Set/subset | Catalog identity | Distinguishes base, inserts, subsets | Collections partially | High | Recommend explicit concept later | Yes | Yes |
| Card number | Catalog identity | Core card identifier in hobby | Generic attributes only | Medium | Recommend catalog field/concept later | Yes | Yes |
| Parallel | Catalog identity | Usually distinct issued card | Generic attributes only | High | Recommend catalog-level | Yes | Yes |
| Print run | Catalog identity | `/25` is issued-card meaning | Generic attributes only | Medium | Recommend catalog-level | Yes | Yes |
| Exact serial number | Owned-card instance | Identifies physical copy | No dedicated field | Medium privacy risk | Recommend owned-copy-level | Yes | Yes |
| Program-issued autograph | Catalog identity | Part of issued card | Generic attributes only | Medium | Recommend catalog-level | Yes | Yes |
| Program-issued memorabilia | Catalog identity | Part of issued card | Generic attributes only | Medium | Recommend catalog-level | Yes | Yes |
| Aftermarket autograph/modification | Owned-card history/condition; future modification layer | Copy-specific event | Notes/images/evaluation only | High | Needs later product decision | Yes | No, except display caution |
| Raw/graded state | Owned-card/evaluation state | Not issued-card identity by default | `condition_type`, evaluation lifecycle | Low | Recommend not catalog-level | Yes | Yes |
| Grade | Evaluation/certification state | Result tied to physical copy | `evaluation_case_items.result_grade`, public reference label | Medium normalization | Recommend evaluation-level | Yes | Yes |
| Certification number | Evaluation/certification state | Copy/provider-specific | `result_certification_number` | Medium privacy/source | Recommend evaluation-level | Yes | Yes |
| User photos | Owned-card instance / public reference by exposure | User/workspace asset | `asset_images` generic | Medium privacy/rights | Recommend private by default | Yes | Yes |
| Catalog images | Catalog identity with provenance | Shared display asset | `asset_images` generic only | High licensing | Needs policy before build | Yes | No if fallback exists |
| Aliases | Card Vertex catalog/search | Search and source variation | No dedicated support | Medium | Recommend mapped aliases | Yes | Yes |
| External source IDs | External-source mapping | Provider IDs are not canonical | Comp source fields only | High | Recommend mapping-only | Yes | No for MVP manual |
| Provisional identities | Draft/provisional Card Vertex identity | Supports incomplete intake safely | No dedicated support | High | Recommend explicit certainty model | Yes | Yes if intake exists |
| Catalog candidate review | Card Vertex catalog governance | Prevents free-text corruption | No dedicated support | High | Recommend review gate | Yes | No for smallest MVP |
| Public card reference | Public object reference | Safe exposure layer | Implemented generic Core | Medium privacy | Existing Core useful; Card Vertex display contract needed | Yes | Yes |
| Comp matching identity | Card Vertex market/comps interpretation | Matching needs card/grade/parallel clarity | `comp_snapshots` generic links | High | Recommend after identity decisions | Yes | No if comps deferred |
| Search normalization | Card Vertex search/catalog | Needed for collector shorthand | No dedicated support | Medium | Recommend aliases + normalized names | Yes | Yes |

## Recommended Decisions For Founder Review

1. Approve strict separation between Catalog Card Identity, Owned Card
   Instance, Evaluation / Certification State, and Public Card Reference.
2. Approve raw/graded/certification placement as owned-copy/evaluation state,
   not catalog identity by default.
3. Approve parallel and print-run placement at catalog level, with exact serial
   number at owned-copy level.
4. Approve program-issued autograph/relic as catalog-level, and aftermarket
   autograph, alteration, damage, or modification as owned-copy history or a
   future modification layer.
5. Approve a phased hybrid catalog-source strategy: controlled Card
   Vertex-first records, later licensed/provider/manufacturer mappings, broader
   ingestion only after governance is proven.
6. Approve no-scraping and image-provenance policy: no unlicensed scraped
   images, no automatic conversion of user images into default catalog images,
   and identity must work without images.
7. Approve provisional intake policy: Draft Lots and preparation workflows may
   hold incomplete identity, but unresolved free text must not silently become
   permanent global catalog truth.
8. Approve alias/correction policy: stable internal identity, aliases and
   source names mapped to it, no destructive merges that lose provenance.
9. Approve external source mapping policy: outside source IDs map to Card
   Vertex canonical identity and never replace it.
10. Approve MVP catalog scope: sports cards only, no universal catalog
    coverage, controlled/manual Card Vertex catalog creation, provisional
    intake through Draft Lots later, curated/approved enrichment later, and no
    automated catalog ingestion in MVP.

## Follow-On Sequence

1. Review and approve Card Vertex Grading Workspace and Certification
   Lifecycle.
2. Define Card Vertex Trade Network and logged trade contract.
3. Define Card Vertex collector profile and trust contract.
4. Define Card Vertex Goals and Signals contract.
5. Define Card Vertex Search, Dashboard, and comp write-path contract.
6. Define Card Vertex MVP Product Experience Specification.
7. Create a Card Vertex schema-design proposal only after the preceding
   decisions are approved.
8. Plan real workspace/build configuration for `apps/card-vertex`.
9. Create a real Card Vertex app root only after the product-domain plan is
   approved.
10. Build Card Vertex Inventory Workspace shell.
11. Add Card Vertex workflows incrementally.

## Do Not Build Yet

- Card Vertex UI.
- Real app routes.
- Migrations.
- Provider catalog integrations.
- Unlicensed image ingestion.
- Scraping.
- Automated identity matching.
- OCR/scanning.
- Browser-extension write path.
- Full catalog import.
- Marketplace listings/payments.
- Formal trade proposals.
- Goals implementation.
- Signals implementation.
- Comp write path.
- Generic Satera catalog system.
- Generic Satera Goals/Search/Signals systems.

## Verification Plan

Because this is documentation-only, no Supabase reset is required. Required
verification commands:

```text
npm run test
npm run typecheck
npm run build
```

Do not claim success unless each command actually passes.
