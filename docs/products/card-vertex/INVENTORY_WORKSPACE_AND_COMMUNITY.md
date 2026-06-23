# Card Vertex Inventory Workspace And Community

This document is Card Vertex product planning documentation only. It does not
describe implemented UI, routes, realtime features, product moderation
workflows, or Card Vertex community pages. The reusable Satera Community Core
backend now exists in Core, but Card Vertex has not implemented the Community
Dock or product-specific community surfaces.

Satera Evaluation / Certification Lifecycle now exists in Core as a
product-neutral backbone. Future Card Vertex grading submissions, certification
numbers, review states, and slab/cert assets should translate that Core
lifecycle into card-specific language. This document does not implement Card
Vertex grading UI, submission UI, PSA/SGC/BGS integrations, uploads,
notifications, or product-specific grading workflows.

The Product Lens Framework is now hardened in Satera Core. Future Card Vertex
surfaces should query card category inventory, Card Vertex communities, Card
Vertex notifications, Card Vertex evaluation cases, and Card Vertex public
object references through product-lens services. Card Vertex remains a scoped
experience over shared Core truth, not a separate inventory or community data
silo. Product access does not override private inventory, and public object
references remain the safe sharing boundary.

This experience plan is governed by
[`PRODUCT_DOMAIN_AND_WORKFLOWS.md`](PRODUCT_DOMAIN_AND_WORKFLOWS.md) and the
canonical
[`SATERA_CARD_VERTEX_OWNERSHIP.md`](../../architecture/SATERA_CARD_VERTEX_OWNERSHIP.md)
boundary. Card Vertex is not only presentation: it owns card-specific meaning,
workflow behavior, signals, goals, search interpretation, and collector-facing
trust while Core preserves canonical truth and reusable guarantees.

## Product Philosophy

Card Vertex should feel like one connected environment, not a set of separate
applications or dashboard pages. Inventory is the center of Card Vertex, and
everything else should support inventory work.

Operating principle:

```text
Inventory is the database.
Community is the conversation.
Context is the intelligence layer.
```

Inventory, Community, and Card Context should coexist without forcing page
transitions during normal workflows. The user should feel like they are working
inside a single instrument rather than navigating between screens.

Favor:

- one continuous surface
- subtle dividers
- spacing over borders
- persistent context
- object-driven interactions
- table-first inventory
- right-side contextual intelligence
- community dock inside the workspace
- primitive components composed into larger surfaces

Avoid:

- box-in-box layouts
- floating dashboard cards
- excessive shadows
- modal-heavy navigation
- large nested cards
- unnecessary page transitions

## Main Layout

```text
App Shell
|-- Left Rail
`-- Inventory Workspace
    |-- Search
    |-- Saved Filter Chips
    |-- Inline Controls
    |-- Inventory Table
    |-- Community Dock
    `-- Card Context Drawer
```

Inventory should command most user attention. Community should be persistent
but secondary. Card Context should be available without navigating away from the
table.

## Inventory Workspace

Inventory is the primary surface. It should feel polished, analytical,
spreadsheet-inspired, quiet, database-like, dense, and understandable.

Rows are objects. Rows are not cards.

Prefer:

- tables
- rows
- cells
- subtle separators
- selected-row accent
- dense information
- persistent context

Avoid:

- shadows
- large borders
- nested card UI
- card grids as the primary inventory model

Inventory architecture:

```text
Left Rail
`-- Inventory Workspace
    |-- Search
    |-- Saved Filter Chips
    |-- Filter
    |-- Sort
    |-- Columns
    |-- Save Filter
    |-- Inventory Table
    |-- Community Dock
    `-- Card Context Drawer
```

### Saved Filters

Card Vertex should not use a dedicated Inventory Views rail. Inventory views
are replaced by saved filters above the table.

Example saved filters:

- All Cards
- Trade Bait
- PSA Submission #7
- Watchlist
- Cards > $500
- For Sale
- Vaulted

Future saved filter capabilities may include create, rename, delete, reorder,
and pin favorite filters. Filters are user-specific.

### Top Controls

Inline controls live beside saved filter chips:

- Filter
- Sort
- Columns
- Save Filter

Controls should remain visually quiet until needed. The inventory table should
stay dominant.

### Search

Search is global within the current filter and should update results
immediately. It should eventually match:

- card name
- player
- set
- year
- grade
- tags
- notes
- serial number
- collection

### Table Behavior

The table is a database, not a collection of cards. It should take cues from
Bloomberg Terminal, Airtable, Linear, and Card Ladder.

Rows are never manually reordered. Rows represent data, and sorting controls
ordering.

### Column Behavior

Columns are personal. Users may eventually reorder, resize, hide, and restore
default columns. Columns should be draggable, column order and visibility should
be saved, and layouts should be stored per filter.

Example Trade Bait filter columns:

- Card
- Value
- Trade Value
- Grade
- 30D

Example PSA Submission filter columns:

- Card
- Submission Number
- Estimated Grade
- Population

The Card column should always remain visible. Additional pinned columns such as
Grade or Value may be supported later.

### Density Modes

Supported density modes:

- Comfortable
- Compact
- Ultra

Density affects row height, image size, and spacing. It does not change the
information shown.

### Bulk Mode

Checkboxes should not always be visible.

Normal mode:

- no persistent checkboxes
- hovering reveals the checkbox

Bulk mode:

- checkboxes remain visible
- selecting rows reveals a bulk toolbar

Possible bulk actions:

- Move
- Tag
- Grade
- Trade
- Sell
- Export

## Community Dock

Community is persistent and product-scoped. It should not force users away from
inventory. Users should be able to organize inventory, compare cards, discuss
cards, trade cards, and participate in channels without leaving the workspace.

Dock states:

1. Collapsed: persistent bar, community name, active channel, unread count, and
   compact height.
2. Expanded: channel list, conversation, resizable height, and a workspace that
   shrinks inventory as community grows.
3. Full Community Workspace: separate full community page for deeper engagement
   with community rail, channel rail, conversation, and context drawer.

Between Inventory and Community there should eventually be a draggable
splitter. Dragging should resize the actual dock: inventory shrinks when
community grows, community shrinks when inventory grows, and empty space should
never appear.

Composer rules:

- The composer is sacred.
- The composer must never scroll.
- The composer must never disappear.
- Only the message feed scrolls.

Conversation structure:

- Header
- Messages, scrollable
- Composer, fixed

## Card Sharing And Drag And Drop

Signature interaction:

```text
Inventory Row
-> Drag
-> Community Composer
-> Drop
-> Attached Public Card Reference
-> Send Message
```

Initial drag source:

- inventory row

Future drag sources:

- card context
- watchlists
- comp results
- trades
- messages

The drop target is the community composer. During drag, the composer indicates
"Drop card to attach." After drop, Card Vertex should display an attached
public card reference, let the user add text, and send the message with the
safe reference attached.

Dragging creates a card reference object. No private card data is duplicated.
The card reference updates automatically when safe public display data changes.
The Core implementation for this bridge is `public_object_references`; Card
Vertex should use that platform table/RPC layer and Satera Community Core
message reference RPCs when this UI is built later.

Critical privacy rule:

```text
Inventory Item does not equal Public Card Reference.
```

Inventory Item is private and may contain:

- purchase price
- true cost basis
- profit
- location
- notes
- tags
- ownership history
- grading costs
- private strategy

Public Card Reference is shareable and may contain:

- card identity
- public image
- grade
- market value or current value estimate
- market movement
- safe catalog information

Public/shared references must never expose:

- purchase price
- cost basis
- profit
- private notes
- storage location
- private tags
- ownership history
- private transaction history
- internal strategy

Current implementation status:

- Satera Community Core Pass 1 implements product-scoped communities, channels,
  memberships, messages, safe public reference message attachments, basic
  moderation records, audit events, and RLS.
- Card Vertex inventory workspace UI, Community Dock, drag/drop composer,
  realtime presence, LiveKit, voice, video, screenshare, uploaded video, and
  media processing remain future work.

## Card Context Drawer

Card Context is not a page. Card Context is a right-side drawer that should
never navigate away from inventory.

Pattern:

```text
Select Object
-> Context Drawer Updates
```

The drawer opens from inventory rows, card references, watchlists, trades,
grading submissions, and community posts. It sits on the right side, defaults
around 380-440px wide, and may later become resizable and pinnable.

Card Header contains:

- card image
- card identity
- grade
- current value
- 30 day movement
- primary actions

Example primary actions:

- Add Comp
- Edit
- Discuss

Drawer tabs should feel like real tabs and occupy their own dedicated row.

Supported tabs:

- Overview: default quick understanding with market signal, ownership summary,
  recent comps, and community mentions.
- Comps: evidence, recent sales, source, date, included/excluded state, and
  confidence.
- Lineage: owner-only ownership history, including purchase, grading, trade,
  sale, and basis changes.
- Images: front, back, slab, and condition photos.
- Notes: owner-only private notes such as condition observations, grading
  thoughts, and seller notes.
- Activity: timeline events such as added to inventory, comp attached, shared
  to community, moved to trade bait, submitted for grading, and sold.

## Permission Views

Owner View shows:

- purchase price
- cost basis
- ROI
- profit/loss
- location
- private notes
- lineage
- tags

Public View shows:

- identity
- grade
- market value
- population
- comps
- market movement
- community references

Public View never shows purchase price, basis, profit, location, notes, private
tags, lineage, private ownership history, or private transaction history.

## Object Philosophy

Eventually all objects should follow the same pattern:

```text
Object
-> Context Drawer
-> Tabs
-> Actions
```

Examples include cards, trades, people, messages, grading submissions, and
comps. This pattern should scale beyond Card Vertex and become foundational to
Satera.

## Tailwind And Component Philosophy

Avoid giant page components. Prefer primitives such as:

- Surface
- Divider
- Row
- Cell
- Badge
- Dock
- Drawer
- Splitter
- Channel
- Message
- Composer
- CardReference
- Tabs
- Toolbar

Complex layouts should emerge from primitives, not monolithic components.

Design rules:

- Inventory is primary.
- Card Context is temporary.
- Community is persistent.
- No page transitions should be required for normal workflows.
- Everything should feel like one connected surface.
