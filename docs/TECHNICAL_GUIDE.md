# SOLM Margin Simulation & Quote Approval -- Technical Guide

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Data Model](#2-data-model)
3. [Custom Fields Reference](#3-custom-fields-reference)
4. [Automation Components](#4-automation-components)
5. [Apex Classes & Trigger](#5-apex-classes--trigger)
6. [Lightning Web Component](#6-lightning-web-component)
7. [Flows](#7-flows)
8. [Approval Process & Workflow](#8-approval-process--workflow)
9. [PDF Generation](#9-pdf-generation)
10. [Pricelist Creation](#10-pricelist-creation)
11. [End-to-End Technical Flow](#11-end-to-end-technical-flow)

---

## 1. Architecture Overview

This package implements a **Quote Margin Simulation and Approval System** for Sol Millennium (SOLM). It extends the standard Salesforce Quote object with custom margin/GP (Gross Profit) calculation fields, automated discount-based approval routing, PDF generation, and pricelist creation.

### Component Map

```
Quote (Standard Object)
  |-- Custom Fields (Incoterm, GP totals, delivery, validity)
  |-- QuoteLineItem (Standard Object)
  |     |-- Custom Fields (GP$, GP%, Standard Cost, Price per Box/Case, Discount, Total Price)
  |     |-- Flow: QLI_Screen_Data (After Insert/Update) -- margin calculations
  |     |-- Flow: QLI_2 (Before Insert/Update) -- OBSOLETE
  |
  |-- QuoteTrigger (After Update)
  |     |-- QuoteDiscountTaskHandler (creates Tasks for >10% discount)
  |
  |-- Flow: Quote_Approval (Record-Triggered, After Update)
  |     |-- Submits to Approval Process when Status = "Presented" & any QLI has Discount > 10%
  |
  |-- Approval Process: Quote_Approval
  |     |-- Workflow Alerts (email notifications)
  |     |-- Workflow Field Updates (Status changes)
  |
  |-- Quick Actions: View Quote PDF, Save PDF to Quote
  |-- WebLink: Create Pricelist (launches Pricelist_Reversal_Creation flow)
  |
  |-- LWC: addNewProductCustom (custom product search & add modal)
  |-- Apex: customAddProductModalClass (server-side controller for LWC)

Standard_Price__c (Custom Object)
  |-- Stores standard cost data per product + incoterm combination
  |-- Used by flows to look up cost basis for GP calculations

BU_Task_Owner__mdt (Custom Metadata Type)
  |-- Maps Business Units to Task Owners for discount approval routing

Product2 (Standard Object)
  |-- GP_Threshold__c (GP% threshold per product)
```

---

## 2. Data Model

### Object Relationships

```
Quote (1) ---< (Many) QuoteLineItem
  |                      |
  |                      |-- PricebookEntry --> Product2
  |                      |                       |-- BU__c (Business Unit)
  |                      |                       |-- GP_Threshold__c
  |                      |
  |                      |-- Standard_Price__c (looked up by ProductCode + Incoterm)
  |
  |-- Incoterm__c (drives Standard_Price__c lookup)
  |-- Roll-up summaries from QuoteLineItem

BU_Task_Owner__mdt
  |-- BU__c --> Product2.BU__c (logical relationship)
  |-- Owner__c --> User.Id (stores approver/task owner)
```

### Key Standard Fields Used

| Object | Standard Field | Usage |
|---|---|---|
| Quote | Status | Drives approval flow ("Presented" triggers submission) |
| Quote | TotalPrice | Used in GP% formula at quote level |
| Quote | QuoteNumber | Displayed in task subjects |
| Quote | Pricebook2Id | Links to price book for product lookup |
| Quote | CurrencyIsoCode | Multi-currency support |
| QuoteLineItem | UnitPrice | Sales price per piece (user-entered) |
| QuoteLineItem | Quantity | Number of units |
| QuoteLineItem | Product2Id | Links to Product |
| PricebookEntry | UnitPrice | List price (used for discount calculation) |

---

## 3. Custom Fields Reference

### 3.1 Quote Custom Fields

| API Name | Label | Type | Definition |
|---|---|---|---|
| `Incoterm__c` | Incoterm | Picklist | Trade terms: **FOB**, **EXW**, **DAP**. Determines which Standard_Price__c record is matched for cost lookup. |
| `Deliver_it_by__c` | Deliver it by | Picklist | Shipping method: **LTL** (Less Than Truckload), **FTL** (Full Truckload), **Parcel**. |
| `Offer_Validity__c` | Offer Validity | Date | Expiration date of the quote offer. Defaults to today + 30 days in PDF if blank. |
| `Total_Deal_Quantity__c` | Total Deal Quantity | Roll-Up Summary | `SUM(QuoteLineItem.Quantity)` -- total units across all line items. |
| `Total_Standard_Cost__c` | Total Standard Cost | Roll-Up Summary | `SUM(QuoteLineItem.Standard_Cost__c)` -- total cost basis. |
| `Total_Price_Summary__c` | Total Price Summary | Roll-Up Summary | `SUM(QuoteLineItem.Total_Price__c)` -- total revenue from custom total price. |
| `Total_GP_Dollars__c` | Total GP$ | Formula (Currency) | `(TotalPrice - Total_Standard_Cost__c) * Total_Deal_Quantity__c` |
| `Total_GP_Percent__c` | Total GP% | Formula (Percent) | `(TotalPrice - Total_Standard_Cost__c) / TotalPrice` |

### 3.2 QuoteLineItem Custom Fields

| API Name | Label | Type | Definition |
|---|---|---|---|
| `Standard_Cost__c` | Standard Cost | Currency | Populated by flow from `Standard_Price__c.Standard_Cost__c`. The base cost of the product for the given incoterm. |
| `GPDollar__c` | GP $ | Currency | `(UnitPrice - Standard_Cost) * Quantity`. Gross profit in dollars for this line. |
| `GPPercentage__c` | GP % | Percent | `((UnitPrice - Standard_Cost) / UnitPrice) * 100`. Gross profit margin percentage. |
| `Discount_Custom__c` | Discount | Formula (Percent) | `(PricebookEntry.UnitPrice - UnitPrice) / PricebookEntry.UnitPrice`. Discount from list price. **This is the field that triggers approval when > 10%.** |
| `Price_per_Box__c` | Price per Box | Currency | `Product2.NACA_Box_Quantity__c * UnitPrice`. Calculated by flow. |
| `Price_per_Case__c` | Price per Case | Currency | `Product2.NACA_Case_Qty__c * UnitPrice`. Calculated by flow. |
| `Qty_box_Case__c` | Qty box/Case | Text | `"{BoxQty}/{CaseQty}"` string. Populated by flow from product packaging data. |
| `Total_Price__c` | Total Price | Currency | `UnitPrice * Quantity`. Custom total price field. |

### 3.3 Standard_Price__c Custom Object Fields

This object stores the **standard cost matrix** -- each record represents a product's cost structure for a specific incoterm/warehouse combination.

| API Name | Label | Type | Purpose |
|---|---|---|---|
| `ItemCode__c` | ItemCode | Text(80) | Product code -- matched against `Product2.ProductCode` in flow lookups. |
| `Incoterms__c` | Incoterms | Picklist | Trade terms (DAP, DDP, EXW, FCA, FOB, INACTIVE). Matched against `Quote.Incoterm__c`. |
| `Standard_Cost__c` | Standard Cost | Currency | The aggregated standard cost per piece. This is the cost basis for all GP calculations. |
| `Branch__c` | Branch | Text(12) | Branch/location identifier. |
| `WhsCode__c` | WhsCode | Text(12) | Warehouse code. |
| `Duty_Cost_Piece__c` | Duty Cost Piece | Currency | Import duty cost per piece. |
| `InboundCostPiece__c` | Inbound Cost Piece | Currency | Inbound freight cost per piece. |
| `Outbound_Cost_Piece__c` | Outbound Cost Piece | Currency | Outbound freight cost per piece. |
| `Warehouse_Cost_Piece__c` | Warehouse Cost Piece | Currency | Warehousing cost per piece. |

### 3.4 Product2 Custom Field

| API Name | Label | Type | Purpose |
|---|---|---|---|
| `GP_Threshold__c` | GP % Threshold | Percent | Minimum acceptable gross profit margin for the product. Used as a reference threshold. |

### 3.5 BU_Task_Owner__mdt (Custom Metadata Type)

Maps each Business Unit to a designated task owner/approver.

| API Name | Label | Type | Purpose |
|---|---|---|---|
| `BU__c` | BU | Picklist | Business Unit name (11 values: BU01 through BU11). |
| `Owner__c` | OwnerId | Text(18) | Salesforce User ID of the designated approver for that BU. |

**Configured Records:** Ewelina, Ewelina_3, Ewelina_4, Siva

---

## 4. Automation Components

### Execution Order

When a QuoteLineItem is created or updated:

```
1. [Before Save] Flow: QLI_2 (OBSOLETE - status Obsolete, would not fire)
2. [After Save]  Flow: QLI_Screen_Data
   a. Get parent Quote (for Incoterm__c)
   b. Get Standard_Price__c (by ProductCode + Incoterm)
   c. Calculate: GPDollars, GPPercent, PricePerBox, PricePerCase, QtyboxCase, TotalPrice
   d. Update the QuoteLineItem record with calculated values
```

When a Quote is updated to Status = "Presented":

```
1. [After Update] Apex Trigger: QuoteTrigger
   a. QuoteDiscountTaskHandler.handlePresentedQuotes()
   b. Queries QLIs where Discount_Custom__c > 10%
   c. Looks up BU_Task_Owner__mdt for each affected BU
   d. Creates Task records assigned to BU owners (prevents duplicates)

2. [After Save]  Flow: Quote_Approval (Record-Triggered)
   a. Queries QuoteLineItem where Discount_Custom__c > 10%
   b. If found, submits the Quote to the "Quote_Approval" approval process
```

When the Approval Process runs:

```
3. Approval Process: Quote_Approval
   a. Entry Criteria: Quote.Status = "Presented"
   b. Initial Submission Actions:
      - Field Update: Status -> "In Revision"
      - Email Alert: Quote_Approval_Acknowledge (confirmation to submitter)
   c. Step 1 "BU Approval": Assigned to dkumar@solm.com
      - On Approve:
        - Field Update: Status -> "Approved"
        - Email Alert: Quote_Approved
        - Record locked
      - On Reject:
        - Field Update: Status -> "Rejected"
        - Email Alert: Quote_Rejected
        - Record unlocked
```

---

## 5. Apex Classes & Trigger

### 5.1 QuoteTrigger

**File:** `force-app/main/default/triggers/QuoteTrigger.trigger`

```apex
trigger QuoteTrigger on Quote (After update) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        QuoteDiscountTaskHandler.handlePresentedQuotes(Trigger.new, Trigger.oldMap);
    }
}
```

Fires on **After Update** only. Delegates to handler class.

### 5.2 QuoteDiscountTaskHandler

**File:** `force-app/main/default/classes/QuoteDiscountTaskHandler.cls`

**Purpose:** When a Quote's Status changes to "Presented", creates high-priority Task records for BU owners of products that have > 10% discount.

**Logic:**
1. Detects quotes where `Status` changed to `"Presented"` (compares `Trigger.new` vs `Trigger.oldMap`).
2. Queries `QuoteLineItem` records where `Discount_Custom__c > 10` AND `Product2.BU__c != null`.
3. Loads `BU_Task_Owner__mdt` metadata to map BU names to owner User IDs.
4. For each quote, resolves the set of owner IDs from the affected BUs.
5. Checks for existing Tasks on those quotes (prevents duplicates using `WhatId + OwnerId` composite key).
6. Creates new Tasks with:
   - Subject: `"Quote Approval : {QuoteNumber} for more than 10% discount"`
   - Status: `"Not Started"`
   - Priority: `"High"`
   - WhatId: Quote ID
   - OwnerId: BU owner from metadata

### 5.3 QuotePdfExactController

**File:** `force-app/main/default/classes/QuotePdfExactController.cls`

**Purpose:** Visualforce controller for rendering Quote PDFs and an invocable method for programmatic PDF generation.

**Key Features:**
- Standard controller extension for Quote.
- Queries quote header (account, contact, currency, incoterm, offer validity).
- Queries all QuoteLineItems with custom fields (Qty_box_Case__c, Price_per_Box__c, etc.).
- Wraps each line item in a `LineItemWrapper` with formatted currency values.
- Multi-currency support via `getCurrencySymbol()` (USD, EUR, GBP, PLN, CAD, AUD).
- Date formatting: `DD.MM.YYYY` (European style).
- `@InvocableMethod generateQuotePdfAndAddToQuote(List<Id>)`: Renders the VF page to PDF blob and inserts it as a `QuoteDocument`.

### 5.4 customAddProductModalClass

**File:** `force-app/main/default/classes/customAddProductModalClass.cls`

**Purpose:** Server-side controller for the `addNewProductCustom` LWC. Provides product search and save functionality.

**Methods:**
- `findProducts(recordId, name, productCode, productFamily, RecordLimit)`:
  - Queries the Quote's pricebook and currency.
  - Excludes products already added as QuoteLineItems.
  - Searches PricebookEntry by name, product code, and family filters.
  - Returns JSON-serialized list of `ProductWrapper` objects (max 300 results).
- `getproductfamily()`:
  - Returns Product2.Family picklist values for the filter UI.
- `saveProducts(recordData, recId)`:
  - Deserializes selected products and creates QuoteLineItem records.
  - Sets PricebookEntryId, Quantity, UnitPrice, ServiceDate, Description.

---

## 6. Lightning Web Component

### addNewProductCustom

**File:** `force-app/main/default/lwc/addNewProductCustom/`

**Purpose:** Custom modal UI for searching and adding products to a Quote, replacing the standard "Add Products" experience.

**Two-Page Modal Flow:**

1. **Page 1 -- Product Selection:**
   - Search box with type-ahead (calls `findProducts` on keyup).
   - Filter panel (toggle) with Product Code text filter and Product Family checkbox group.
   - Lightning datatable showing products (Name, Code, List Price, Description, Family).
   - Multi-select with "Show Selected" toggle.
   - "Next" button (disabled until products selected).

2. **Page 2 -- Line Item Details:**
   - Table of selected products with editable fields:
     - Quantity (required, must be non-zero)
     - Sales Price
     - Date
     - Line Description
   - Delete button per row.
   - "Back" and "Save" buttons.

**Events:** Dispatches `ShowToastEvent` on success/error and `RefreshEvent` to reload the page.

---

## 7. Flows

### 7.1 Quote_Approval (Record-Triggered Flow)

**File:** `force-app/main/default/flows/Quote_Approval.flow-meta.xml`
**Status:** Active
**Trigger:** Quote, After Update, when `Status = "Presented"`

**Logic:**
1. `Get_QLI`: Queries first QuoteLineItem where `Discount_Custom__c > 10` for this Quote.
2. `Approval_Decision`: If QLI found (not blank), proceed.
3. `Submit_for_Approval`: Submits the Quote to the `Quote_Approval` approval process.

### 7.2 QLI_Screen_Data (Record-Triggered Flow)

**File:** `force-app/main/default/flows/QLI_Screen_Data.flow-meta.xml`
**Status:** Obsolete (but labeled "QLI - After Insert/Update")
**Trigger:** QuoteLineItem, After Save, on Create and Update
**Description:** "To get QLI Margin Simulation details"

**Logic:**
1. `Get_Quote`: Fetches the parent Quote (for `Incoterm__c`).
2. `Get_StandardCost`: Queries `Standard_Price__c` where `ItemCode__c = Product2.ProductCode` AND `Incoterms__c = Quote.Incoterm__c`.
3. `Update_QLI`: Updates the triggering QLI with:
   - `GPDollar__c` = `(UnitPrice - Standard_Cost) * Quantity`
   - `GPPercentage__c` = `((UnitPrice - Standard_Cost) / UnitPrice) * 100`
   - `Price_per_Box__c` = `NACA_Box_Quantity * UnitPrice`
   - `Price_per_Case__c` = `NACA_Case_Qty * UnitPrice`
   - `Qty_box_Case__c` = `"{BoxQty}/{CaseQty}"`
   - `Standard_Cost__c` = value from Standard_Price__c
   - `Total_Price__c` = `UnitPrice * Quantity`
   - `Incoterm__c` = from parent Quote

### 7.3 QLI_2 (Record-Triggered Flow)

**File:** `force-app/main/default/flows/QLI_2.flow-meta.xml`
**Status:** Obsolete
**Trigger:** QuoteLineItem, Before Save, on Create and Update

Contains the same calculation logic as QLI_Screen_Data but runs before save. Additionally handles a bidirectional calculation:
- **If Sales Price changed:** Calculates GP%, GP$, Price per Box, Price per Case, etc. (same as QLI_Screen_Data).
- **If GP% changed:** Reverse-calculates `UnitPrice = Standard_Cost / (1 - GP% / 100)`, allowing users to input a target GP% and have the system derive the sales price.

**Formula for reverse calculation:**
```
SalesPrice = Standard_Cost / (1 - (GPPercentage / 100))
```

### 7.4 Quotepdf (Screen Flow)

**File:** `force-app/main/default/flows/Quotepdf.flow-meta.xml`
**Status:** Active

**Logic:**
1. Receives `recordId` (Quote ID) as input.
2. Calls `@InvocableMethod QuotePdfExactController.generateQuotePdfAndAddToQuote()`.
3. Displays success screen: "Quote PDF generated Successfully and added".

Launched via the **Save PDF to Quote** quick action.

### 7.5 Pricelist_Reversal_Creation (Screen Flow)

**File:** `force-app/main/default/flows/Pricelist_Reversal_Creation.flow-meta.xml`
**Status:** Active

**Logic:**
1. Receives `recordId` (Quote ID) as input.
2. `Get_Quote`: Fetches the Quote record.
3. `Create_Pricelist`: Creates a new `Pricebook2` record named after the Quote.
4. `Get_QLI`: Fetches all QuoteLineItems for the Quote.
5. `Loop_QLI` + `Assign_PBEs`: For each QLI, creates a `PricebookEntry` with:
   - `Product2Id` from the QLI
   - `Pricebook2Id` = the newly created pricebook
   - `UnitPrice` = the QLI's sales price
   - `IsActive = true`
6. `Create_Pricebook_Entry`: Bulk inserts all PricebookEntry records.
7. Shows success screen.

Launched via the **Create Pricelist** web link button on the Quote page.

---

## 8. Approval Process & Workflow

### 8.1 Approval Process: Quote_Approval

**File:** `force-app/main/default/approvalProcesses/Quote.Quote_Approval.approvalProcess-meta.xml`

| Property | Value |
|---|---|
| Active | `true` |
| Entry Criteria | `Quote.Status = "Presented"` |
| Allowed Submitters | Record Owner |
| Allow Recall | `false` |
| Record Editability | Admin Only (during approval) |
| Show Approval History | `true` |

**Step 1: "BU Approval"**
- Approver: `dkumar@solm.com` (User)
- When Multiple Approvers: First Response

**Initial Submission Actions:**
- Field Update `Update_Sent`: Sets `Status = "In Revision"`
- Email Alert `Quote_Approval_Acknowledge`: Sends "Quote Submitted for Approval" email

**Final Approval Actions:**
- Field Update `If_Appoved`: Sets `Status = "Approved"`
- Email Alert `Quote_Approved`: Sends "Quote Approved" email
- Record is **locked**

**Final Rejection Actions:**
- Field Update `If_Rejected`: Sets `Status = "Rejected"`
- Email Alert `Quote_Rejected`: Sends "Quote Not Approved" email
- Record is **unlocked**

### 8.2 Workflow Rules & Actions

**File:** `force-app/main/default/workflows/Quote.workflow-meta.xml`

**Workflow Rule: "Quote - Update Name"**
- Trigger: On Create Only
- Criteria: `Quote.Name = "Autofill"`
- Action: Field Update sets `Quote.Name = QuoteNumber` (formula)
- Purpose: Auto-names new quotes with their system-generated QuoteNumber.

**Workflow Alerts (4):**

| Alert Name | Template | Description |
|---|---|---|
| `Quote_Approval` | Quote_Approval | Sent to approver requesting review |
| `Quote_Approval_Acknowledge` | Quote_Approval_Submitted | Confirmation that quote was submitted |
| `Quote_Approved` | Quote_Approved | Notification that quote was approved |
| `Quote_Rejected` | Quote_Rejected | Notification that quote was rejected |

All alerts send to `dkumar@solm.com` from the current user.

**Workflow Field Updates (4):**

| Update Name | Field | New Value |
|---|---|---|
| `If_Appoved` | Status | "Approved" |
| `If_Rejected` | Status | "Rejected" |
| `Update_Sent` | Status | "In Revision" |
| `Quote_Update_Name` | Name | `QuoteNumber` (formula) |

### 8.3 Email Templates

| Template | Subject | Content Summary |
|---|---|---|
| `Quote_Approval` | "Please accept the offer with price list" | Shows Quote Name, Account, Total Price, Standard Cost, GP%, GP$, Deal Quantity. Includes approve/reject link. |
| `Quote_Approval_Submitted` | "Quote Submitted for Approval" | Confirmation with Quote Name, Account, Total Price, Deal Quantity. |
| `Quote_Approved` | "Quote Approved - Ready to Move Forward" | Includes link to quote. Asks team to proceed. |
| `Quote_Rejected` | "Quote Not Approved" | Includes link to quote. Suggests regrouping. |

---

## 9. PDF Generation

### Visualforce Page: QuotePDF

Rendered by `QuotePdfExactController` as a standard controller extension.

**Quick Actions:**
- **View Quote PDF** (`Quote.Create_PDF`): Opens the VF page `QuotePDF` directly (preview).
- **Save PDF to Quote** (`Quote.Save_to_Quote`): Runs the `Quotepdf` screen flow, which calls the `@InvocableMethod` to render the page to a PDF blob and store it as a `QuoteDocument`.

**PDF Content:**
- Header with company logo (SolMillenniumLogo static resource)
- Quote details: Account name/address, contact, date, offer validity, incoterm
- Line items table: Reference (SKU/ProductCode), Description, Qty box/Case, Unit Price, Price per Box, Total Price
- Subtotal and Total with currency formatting
- Multi-currency support (USD, EUR, GBP, PLN, CAD, AUD)
- European date format (DD.MM.YYYY)

---

## 10. Pricelist Creation

**Web Link Button:** `Create_Pricelist`
- URL: `/flow/Pricelist_Reversal_Creation?recordId={!Quote.Id}&retURL=/{!Quote.Id}`
- Opens in a new window.

**Flow Logic (Pricelist_Reversal_Creation):**
1. Creates a new Pricebook2 named after the Quote.
2. For each QuoteLineItem, creates a PricebookEntry in the new pricebook with the negotiated unit price.
3. This effectively "locks in" the quoted prices into a reusable price book for future orders.

---

## 11. End-to-End Technical Flow

### Complete Lifecycle of a Quote

```
                    +-----------------------+
                    |  1. CREATE QUOTE      |
                    |  (Status: Draft)      |
                    |  Set: Incoterm,       |
                    |  Deliver By, Validity |
                    +-----------+-----------+
                                |
                    +-----------v-----------+
                    |  2. ADD PRODUCTS      |
                    |  LWC: addNewProduct   |
                    |  Apex: customAddProd  |
                    |  Creates QLI records  |
                    +-----------+-----------+
                                |
                    +-----------v-----------+
                    |  3. MARGIN SIMULATION |
                    |  Flow: QLI_Screen_Data|
                    |  - Lookup Std Cost    |
                    |    (by ProductCode +  |
                    |     Incoterm)         |
                    |  - Calculate GP$, GP% |
                    |  - Price per Box/Case |
                    |  - Total Price        |
                    |  - Roll-ups update    |
                    |    Quote totals       |
                    +-----------+-----------+
                                |
                    +-----------v-----------+
                    |  4. REVIEW & ADJUST   |
                    |  User edits UnitPrice |
                    |  or GP% on QLI        |
                    |  Flow recalculates    |
                    +-----------+-----------+
                                |
                    +-----------v-----------+
                    |  5. SET STATUS =      |
                    |     "PRESENTED"       |
                    +-----------+-----------+
                                |
               +----------------+----------------+
               |                                 |
  +------------v------------+     +--------------v--------------+
  | 6a. TRIGGER fires       |     | 6b. FLOW: Quote_Approval    |
  | QuoteDiscountTaskHandler|     | Checks if any QLI has       |
  | - Checks QLIs >10% disc |     | Discount_Custom__c > 10%    |
  | - Creates Tasks for BU  |     | If yes: submits to          |
  |   owners via metadata   |     | Approval Process            |
  +-------------------------+     +--------------+--------------+
                                                 |
                                  +--------------v--------------+
                                  | 7. APPROVAL PROCESS         |
                                  | - Status -> "In Revision"   |
                                  | - Email: Submission Ack     |
                                  | - Approver: dkumar@solm.com |
                                  +---------+----------+--------+
                                            |          |
                                  +---------v--+  +----v--------+
                                  | APPROVED   |  | REJECTED    |
                                  | Status ->  |  | Status ->   |
                                  | "Approved" |  | "Rejected"  |
                                  | Record     |  | Record      |
                                  | Locked     |  | Unlocked    |
                                  | Email sent |  | Email sent  |
                                  +-----+------+  +-------------+
                                        |
                          +-------------v--------------+
                          | 8. POST-APPROVAL ACTIONS    |
                          | - View Quote PDF (VF page)  |
                          | - Save PDF to Quote         |
                          |   (QuoteDocument)           |
                          | - Create Pricelist          |
                          |   (new Pricebook2 with      |
                          |    negotiated prices)        |
                          +-----------------------------+
```

### Quote Status State Machine

```
Draft -> Presented -> In Revision -> Approved (locked)
                                  -> Rejected (unlocked, editable)
```

### Margin Calculation Formulas

**At Line Item Level (QuoteLineItem):**
```
Standard_Cost   = Standard_Price__c.Standard_Cost__c (looked up by ProductCode + Incoterm)
GP$             = (UnitPrice - Standard_Cost) * Quantity
GP%             = ((UnitPrice - Standard_Cost) / UnitPrice) * 100
Discount%       = (ListPrice - UnitPrice) / ListPrice * 100
Price_per_Box   = NACA_Box_Quantity * UnitPrice
Price_per_Case  = NACA_Case_Qty * UnitPrice
Total_Price     = UnitPrice * Quantity
```

**Reverse Calculation (from QLI_2 flow, currently Obsolete):**
```
UnitPrice = Standard_Cost / (1 - GP% / 100)
```
This allows entering a target GP% and having the system back-calculate the required sales price.

**At Quote Level (Roll-Ups & Formulas):**
```
Total_Deal_Quantity  = SUM(QLI.Quantity)
Total_Standard_Cost  = SUM(QLI.Standard_Cost)
Total_Price_Summary  = SUM(QLI.Total_Price)
Total_GP$            = (TotalPrice - Total_Standard_Cost) * Total_Deal_Quantity
Total_GP%            = (TotalPrice - Total_Standard_Cost) / TotalPrice
```

### Discount Threshold Logic

The 10% discount threshold is evaluated in three places:
1. **QuoteDiscountTaskHandler** (Apex): `DISCOUNT_THRESHOLD = 10` -- creates tasks.
2. **Quote_Approval Flow**: `Discount_Custom__c > 10` -- triggers approval submission.
3. **Discount_Custom__c formula**: `(PricebookEntry.UnitPrice - UnitPrice) / PricebookEntry.UnitPrice` -- the calculated discount percentage.

---

## Appendix: File Inventory

| Component Type | API Name | File Path |
|---|---|---|
| Apex Class | QuoteDiscountTaskHandler | `classes/QuoteDiscountTaskHandler.cls` |
| Apex Class | QuotePdfExactController | `classes/QuotePdfExactController.cls` |
| Apex Class | customAddProductModalClass | `classes/customAddProductModalClass.cls` |
| Apex Trigger | QuoteTrigger | `triggers/QuoteTrigger.trigger` |
| Flow | Quote_Approval | `flows/Quote_Approval.flow-meta.xml` |
| Flow | QLI_Screen_Data | `flows/QLI_Screen_Data.flow-meta.xml` |
| Flow | QLI_2 | `flows/QLI_2.flow-meta.xml` |
| Flow | Quotepdf | `flows/Quotepdf.flow-meta.xml` |
| Flow | Pricelist_Reversal_Creation | `flows/Pricelist_Reversal_Creation.flow-meta.xml` |
| Approval Process | Quote.Quote_Approval | `approvalProcesses/Quote.Quote_Approval.approvalProcess-meta.xml` |
| Workflow | Quote | `workflows/Quote.workflow-meta.xml` |
| LWC | addNewProductCustom | `lwc/addNewProductCustom/` |
| VF Page | QuotePDF | `pages/QuotePDF.page` |
| Quick Action | Quote.Create_PDF | `quickActions/Quote.Create_PDF.quickAction-meta.xml` |
| Quick Action | Quote.Save_to_Quote | `quickActions/Quote.Save_to_Quote.quickAction-meta.xml` |
| WebLink | Create_Pricelist | `objects/Quote/webLinks/Create_Pricelist.webLink-meta.xml` |
| Custom Object | Standard_Price__c | `objects/Standard_Price__c/` |
| Custom Metadata | BU_Task_Owner__mdt | `objects/BU_Task_Owner__mdt/` |
| Static Resource | SolMillenniumLogo | `staticresources/SolMillenniumLogo` |
| Email Template | Quote_Approval (x4) | `email/unfiled$public/` |

All paths are relative to `force-app/main/default/`.
