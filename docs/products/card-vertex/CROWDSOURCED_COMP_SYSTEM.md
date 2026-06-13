# Card Vertex Crowdsourced Comp System

## Overview

Card Vertex should eventually include a crowdsourced comp system that lets
collectors save, submit, and organize pricing evidence while researching cards
across the web. This document is product planning documentation, not an active
UI or browser extension implementation.

The goal is not to create a black-box price guide. The goal is a transparent,
evidence-backed portfolio experience where every estimated value can be traced
to visible comps, user research, and verified data over time.

Guiding principle:

**Every value should have evidence. Every comp should have context. Every
estimate should have confidence.**

## Core Concept

Users should be able to add comps from marketplaces, auction houses, price
guides, private sales, card shows, local card shops, dealer transactions, and
user-to-user trades or sales.

Each comp should attach either to a specific inventory item in a user's
portfolio or, later, to a master card/catalog record that product lenses can
reference. Core inventory remains owner-scoped and private by default. Products
such as Card Vertex do not own inventory.

Each comp should clearly show:

- where it came from
- who submitted it
- whether it was user-entered, system-assisted, or verified
- whether it is included in estimated value
- why it may have been excluded

## Supported Comp Sources

Supported sources may include:

- eBay
- Card Ladder
- Goldin
- Heritage
- Fanatics Collect
- MySlabs
- Pristine Auctions
- private sales
- card shows
- local card shops
- dealer transactions
- user-to-user trades or sales

## Browser Extension: Card Vertex Companion

Card Vertex may eventually include a Chrome and Firefox extension called
**Card Vertex Companion**.

The extension must be a user-initiated comp clipper, not a scraper. Users may
click the extension while viewing a listing, auction result, price-guide page,
or research page, then confirm the details before saving evidence to Card
Vertex.

The extension must never automatically harvest, crawl, bulk collect, or
silently extract pricing data from third-party websites. Every comp saved to
Card Vertex must be initiated and confirmed by the user.

## Extension MVP

The first extension version should allow a user to:

- save the current page URL
- save the page title
- identify the source domain
- enter or confirm sale price
- enter or confirm sale date
- enter or confirm grade and grading company
- select an existing Card Vertex portfolio item
- create a new card record if the card is not already in the portfolio
- add notes
- mark match quality or exclusion state
- optionally attach a screenshot as supporting evidence
- submit the comp to Card Vertex

## Capture Modes

### Manual Capture

The user manually enters comp details. This should be the default mode for most
sources in the early product.

### Smart Capture

The extension may attempt to detect visible page title, price, image, URL, and
other allowed information from supported websites. Smart capture should be
introduced carefully, starting only with sources where parsing is reliable and
permitted. User confirmation is still required.

### Reference-Only Capture

Some sources should be treated as reference-only unless Card Vertex has written
permission or a formal integration. Card Ladder and similar price-guide
platforms should initially be reference/manual-only. Users may save a URL,
notes, and manually entered details, but Card Vertex should not automatically
scrape or bulk ingest pricing tables, charts, sales histories, or value
estimates from those platforms.

## Source Types

Recommended source types:

- `marketplace`
- `auction_house`
- `price_guide`
- `private_sale`
- `local_card_shop`
- `card_show`
- `dealer_verified`
- `user_submitted`
- `admin_verified`
- `partner_feed`

## Verification Statuses

Recommended statuses:

- `user_submitted`
- `system_assisted`
- `needs_review`
- `admin_verified`
- `dealer_verified`
- `excluded`
- `disputed`

## Inclusion And Exclusion Logic

Not every comp should affect estimated value. Users and admins should be able
to include or exclude comps from valuation. Excluded comps should remain visible
as part of the research trail, but they should not affect estimated value.

Common exclusion reasons:

- wrong card
- wrong parallel
- wrong grade
- raw versus graded mismatch
- multi-card lot
- reprint
- custom card
- suspicious price
- unpaid or canceled sale
- damaged card
- altered card
- poor image match
- old comp
- not enough information

## Pricing Confidence Model

Estimated values should not be presented as absolute truth. They should include
a confidence level based on comp count, recency, verification state, source
quality, and exclusions.

Recommended confidence labels:

- Unknown
- User-entered
- Low confidence
- Medium confidence
- High confidence
- Verified

Example:

```text
Estimated Value: $425
Confidence: Medium
Based on 4 recent comps
2 verified comps
1 user-submitted comp
1 excluded comp due to wrong parallel
```

## User Value

Users can:

- track their own market research
- save comps while browsing
- justify card values
- compare cards before buying
- prepare cards for sale or trade
- document private purchases
- build evidence trails for insurance or portfolio review
- understand how confident a value really is

## Platform Value

The system can help Satera and Card Vertex learn:

- which cards users are researching
- which cards need verified pricing
- which sources users trust
- where comps conflict
- which players, sets, and grades are gaining attention
- which cards are watched before price movement occurs

This creates a realistic path toward pricing intelligence without ingesting the
entire sports card market on day one.

## Admin Review Queue

Card Vertex should eventually include an admin review queue for comps that need
verification. Comps may enter review when:

- value is above a threshold
- price impact is large
- users submit conflicting comps
- the source is private or hard to verify
- the card is high-interest
- the card is being prepared for trade or sale
- the user requests verification
- the comp may be wrong parallel, lot, reprint, or suspicious sale

## Premium Opportunities

Potential premium features:

- verified card value reviews
- monthly portfolio review
- insurance report export
- trade value report
- sale prep report
- grading ROI analysis
- dealer/shop verified comps
- priority comp verification
- private collection valuation

## Development Stages

1. Manual comp system in the web app.
2. Comp display and confidence labels.
3. Admin review queue.
4. Browser extension MVP.
5. eBay smart capture with user confirmation.
6. Reference-only handling for price-guide platforms unless permission exists.
7. Dealer and shop verification.

## Relationship To Satera Core

Satera Core is the truth layer. Card Vertex is a product lens. Any comp data
that lives in Core must remain owner-scoped or catalog-scoped, respect RLS, and
stay separate from cost basis.

Current Core alignment:

- Comp records are owner-scoped through `owner_user_id`, `workspace_id`, or
  `organization_id`.
- Comp records may attach to an `inventory_item_id`.
- Existing `category_id`, `asset_family_id`, and `asset_variant_id` fields can
  support catalog/master-card attachment later.
- Source URL, source domain, source type, sale price, sale date, grade,
  verifier, submitter, inclusion/exclusion, confidence, and evidence fields are
  represented as early schema infrastructure.
- Comp code must not write to `inventory_items.true_basis`.
- Comp code must not write to `basis_events`.
- Market value must never be treated as cost basis.
- Excluded comps must remain in the evidence trail but must not affect value
  summaries.
- RLS must remain owner/member/admin-scoped.
- Direct app/client comp writes are not active yet; a future write workflow
  should be reviewed and likely RPC-backed before exposure.
