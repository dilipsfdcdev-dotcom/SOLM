# SOLM Quote & Margin Simulation -- User Guide

## What Is This System?

This is Sol Millennium's **Quote Management System** in Salesforce. It helps the sales team:

- Create quotes for customers with product pricing
- Automatically calculate profit margins (how much money we make on each product)
- Route quotes for manager approval when discounts exceed 10%
- Generate professional PDF quotes to send to customers
- Create reusable price lists from approved quotes

---

## Step-by-Step: Creating and Managing a Quote

### Step 1: Create a New Quote

1. Navigate to an **Opportunity** in Salesforce.
2. Click **New Quote** from the related list.
3. Fill in the required fields:

| Field | What to Enter |
|---|---|
| **Quote Name** | Enter "Autofill" -- the system will automatically rename it to the Quote Number. |
| **Incoterm** | Select the trade terms for this deal: **FOB** (Free on Board), **EXW** (Ex Works), or **DAP** (Delivered at Place). This affects the cost calculations. |
| **Deliver it by** | Choose the shipping method: **LTL** (Less Than Truckload), **FTL** (Full Truckload), or **Parcel**. |
| **Offer Validity** | Set the date until which this quote is valid. If left blank, the PDF will default to 30 days from today. |

4. Save the Quote.

> **Important:** The **Incoterm** you select determines which standard cost the system uses for profit calculations. Make sure this is correct before adding products.

---

### Step 2: Add Products to the Quote

1. On the Quote record page, click the **"Add Product"** button.
2. A search window opens showing products from your assigned Price Book.

**Searching for Products:**
- Type a product name in the search box and press **Enter** to search.
- Use the **filter icon** to open advanced filters:
  - **Product Code**: Filter by specific product code.
  - **Product Family**: Check one or more product families to narrow results.
  - Click **Apply** to filter, or **Cancel** to clear filters.

**Selecting Products:**
- Check the boxes next to the products you want to add.
- The counter at the top shows how many products are selected.
- Click **"Show Selected"** to review only your chosen products.
- Click **"Back to Result"** to return to the full list.
- Click **Next** when you have selected all desired products.

**Setting Line Item Details (Page 2):**

| Column | What to Enter |
|---|---|
| **Quantity** | Number of units (required -- cannot be zero). |
| **Sales Price** | The price per piece you are offering the customer. |
| **Date** | Optional service/delivery date for this line. |
| **Line Description** | Optional description for this line item. |

- Use the **trash icon** to remove a product you no longer want.
- Click **Back** to return to product selection.
- Click **Save** to add all products to the quote.

> **What happens next:** Once you save, the system automatically calculates the profit margins for each line item (see Step 3).

---

### Step 3: Understanding the Margin Simulation (Automatic)

After you add or edit products, the system **automatically calculates** the following for each line item:

| Field | What It Means |
|---|---|
| **Standard Cost** | The base cost of the product (pulled from the Standard Price records based on the product and your selected Incoterm). |
| **GP $** (Gross Profit Dollars) | How much profit in dollars: `(Your Price - Standard Cost) x Quantity` |
| **GP %** (Gross Profit Percentage) | Profit as a percentage: `(Your Price - Standard Cost) / Your Price x 100` |
| **Discount** | How much discount from list price: `(List Price - Your Price) / List Price x 100` |
| **Price per Box** | Your price multiplied by the box quantity for this product. |
| **Price per Case** | Your price multiplied by the case quantity for this product. |
| **Qty box/Case** | Shows the packaging format, e.g., "100/12" means 100 per box, 12 per case. |
| **Total Price** | Your price multiplied by the quantity ordered. |

**At the Quote level, you will also see summary totals:**

| Quote Field | What It Means |
|---|---|
| **Total Deal Quantity** | Sum of all line item quantities. |
| **Total Standard Cost** | Sum of all line item standard costs. |
| **Total Price Summary** | Sum of all line item total prices. |
| **Total GP $** | Overall gross profit dollars for the entire quote. |
| **Total GP %** | Overall gross profit percentage for the entire quote. |

> **Tip:** If you change the Sales Price on a line item, the GP%, GP$, and other calculated fields will update automatically. Use this to simulate different pricing scenarios and see how they affect your margins.

---

### Step 4: Submitting for Approval

When you are satisfied with the quote, change the **Status** to **"Presented"**.

**What happens automatically:**

1. **If any product has more than 10% discount from list price:**
   - The system automatically submits the quote for approval.
   - The Quote Status changes to **"In Revision"** (you can no longer edit it).
   - You receive a confirmation email: "Quote Submitted for Approval."
   - High-priority tasks are created and assigned to the Business Unit managers responsible for the discounted products.
   - The assigned approver receives an email asking them to review the quote.

2. **If no product exceeds 10% discount:**
   - No approval is required. The quote remains in "Presented" status and you can proceed to generate the PDF.

> **Note:** You cannot recall a quote once it is submitted for approval. Make sure all pricing is finalized before changing the status to "Presented."

---

### Step 5: Approval Outcomes

**If the quote is APPROVED:**
- The Status changes to **"Approved"**.
- The record is **locked** (no further edits unless an Admin unlocks it).
- You receive an email: "Quote Approved - Ready to Move Forward."
- You can now generate the PDF and create a price list.

**If the quote is REJECTED:**
- The Status changes to **"Rejected"**.
- The record is **unlocked** so you can make changes.
- You receive an email: "Quote Not Approved."
- Adjust pricing as needed and resubmit by setting Status back to "Presented."

---

### Step 6: Generating a Quote PDF

You have two options:

**Option A: View the PDF (Preview)**
1. On the Quote record, click the **"View Quote PDF"** quick action button.
2. The PDF opens in a preview window showing:
   - Sol Millennium logo and company details
   - Customer name and billing address
   - Contact information
   - Quote date and offer validity date
   - Incoterm
   - Product table with: Reference (SKU), Description, Qty box/Case, Price per Piece, Price per Box, Total
   - Subtotal and Grand Total with currency symbol

**Option B: Save the PDF to the Quote**
1. Click the **"Save PDF to Quote"** quick action button.
2. The system generates the PDF and saves it to the **Quote PDFs** related list.
3. You will see a green success message: "Quote PDF generated Successfully and added."
4. The saved PDF can be shared with the customer or attached to emails.

---

### Step 7: Creating a Price List (Optional)

After a quote is finalized, you can create a reusable Salesforce Price Book from the quoted prices:

1. Click the **"Create Pricelist"** button on the Quote page.
2. A new window opens running the Pricelist Creation flow.
3. The system:
   - Creates a new Price Book named after the Quote.
   - Adds all quoted products to the new Price Book with the negotiated prices.
4. You will see a success message when complete.

> **When to use this:** Use this feature when you want to reuse the same negotiated pricing for future orders from the same customer or similar deals.

---

## Quick Reference: Quote Status Flow

```
  DRAFT                    You are building the quote
    |
    v
  PRESENTED                You set this when pricing is finalized
    |
    +-- (no discount > 10%) --> Stay in PRESENTED
    |
    +-- (discount > 10%)
          |
          v
        IN REVISION          Automatically submitted for approval
          |
          +-- Approved --> APPROVED (locked, generate PDF)
          |
          +-- Rejected --> REJECTED (unlocked, edit and resubmit)
```

---

## Quick Reference: Key Fields at a Glance

### On the Quote

| Field | Where to Find | Purpose |
|---|---|---|
| Incoterm | Quote detail section | Sets the cost basis (FOB/EXW/DAP) |
| Deliver it by | Quote detail section | Shipping method (LTL/FTL/Parcel) |
| Offer Validity | Quote detail section | When the quote expires |
| Total GP % | Quote detail section | Overall profit margin |
| Total GP $ | Quote detail section | Overall profit dollars |
| Total Deal Quantity | Quote detail section | Total units across all products |

### On Each Line Item

| Field | Purpose |
|---|---|
| Sales Price (Unit Price) | The price you offer per piece |
| Standard Cost | Internal cost (auto-filled) |
| GP % | Profit margin on this line |
| GP $ | Profit dollars on this line |
| Discount | Discount from list price (triggers approval if > 10%) |

---

## Frequently Asked Questions

**Q: Why can't I edit my quote?**
A: If the status is "Approved," the record is locked. Ask your Salesforce Admin to unlock it if changes are needed. If it's "In Revision," it's waiting for approval.

**Q: How do I know if my quote needs approval?**
A: If any line item has a discount greater than 10% from the list price, approval is required automatically when you set the status to "Presented."

**Q: Who approves quotes?**
A: The designated approver. Additionally, tasks are created for Business Unit managers of the products that have high discounts.

**Q: What if the Standard Cost shows blank or zero?**
A: The system looks up the standard cost using the product code and the Incoterm on the quote. Make sure:
  - The Incoterm field is filled in on the Quote.
  - A Standard Price record exists for that product + incoterm combination.

**Q: Can I change the GP% directly and have the system calculate the price?**
A: This feature (reverse margin calculation) was designed in the system but is currently in an obsolete state. Contact your Salesforce Admin to enable it if needed.

**Q: What does the "Create Pricelist" button do?**
A: It creates a new Salesforce Price Book containing all the products from this quote at the negotiated prices. This lets you reuse those prices for future quotes or orders.

**Q: What currencies are supported?**
A: The PDF generation supports USD ($), EUR, GBP, PLN (zl), CAD (C$), and AUD (A$). The system uses Salesforce multi-currency features.

**Q: What are the Business Units (BUs)?**
A: Sol Millennium is organized into 11 Business Units:
  - BU01: Injection and Pharma
  - BU02: Diagnostics
  - BU03: Diabetes Care
  - BU04: Vascular Access & Infusion Therapy
  - BU05: Oncology
  - BU06: Injection Prevention
  - BU07: Kitting
  - BU08: Advanced Wound Care
  - BU09: Medical Supplies
  - BU10: SolCotton
  - BU11: Clothing

Each BU has a designated manager who receives approval tasks when discounts exceed 10% on their products.

---

## Need Help?

- **For pricing or approval questions:** Contact your Sales Operations team.
- **For system issues or errors:** Contact your Salesforce Administrator.
- **For product data or standard cost questions:** Contact your Supply Chain or Finance team.
