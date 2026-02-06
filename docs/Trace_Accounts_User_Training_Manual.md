# Trace Accounts - User Training Manual

## Table of Contents

1. [Overview](#overview)
2. [Accessing Trace Accounts](#accessing-trace-accounts)
3. [Step 1 - Select an Account](#step-1---select-an-account)
4. [Step 2 - Choose an Action](#step-2---choose-an-action)
5. [Step 3A - Link Accounts](#step-3a---link-accounts)
6. [Step 3B - Unlink Accounts](#step-3b---unlink-accounts)
7. [Working with the Data Table](#working-with-the-data-table)
8. [Using Filters](#using-filters)
9. [Troubleshooting](#troubleshooting)

---

## Overview

The **Trace Accounts** feature allows you to manage the relationship between Salesforce Accounts and Trace Account Mapping records. Trace Account Mappings contain distributor and customer revenue data (distributor name, customer name, invoice year, total revenue, contract information, and geographic details). Using this tool, you can:

- **Link** unassigned trace account mappings to a specific Salesforce Account
- **Unlink** previously linked trace account mappings from an Account

This helps maintain accurate account-level data by associating the correct trace records with their corresponding accounts.

---

## Accessing Trace Accounts

1. Log in to Salesforce.
2. In the top navigation bar, click the **Trace Accounts** tab.
   - If you do not see this tab, click the **App Launcher** (the grid icon in the top-left corner), search for "Trace Accounts", and select it.
3. The **Select Account** screen will load as the first step.

---

## Step 1 - Select an Account

This is the starting screen where you choose which Account you want to work with.

### How to search for an Account

1. Click into the **search bar** that displays the placeholder text "Select account to continue...".
2. Begin typing the name of the Account you are looking for. You must type at least **2 characters** before search results appear.
3. A **dropdown list** will appear below the search bar showing matching accounts. Each result shows:
   - The **Account Name**
   - The **Account Type** (e.g., "Account", "Prospect")
4. Click on the desired Account from the dropdown to select it.
5. A green checkmark with the text **"Selected: [Account Name]"** will appear below the search bar to confirm your selection.

### Changing your selection

- To clear your selection and search for a different account, click the **X** (clear) button on the right side of the search bar.
- The search field will be cleared so you can type a new account name.

### Navigating forward

- Once an Account is selected, the **Continue** button becomes active (it is grayed out until a selection is made).
- Click **Continue** to proceed to Step 2.
- Click **Cancel** to reset the screen and start over.

---

## Step 2 - Choose an Action

After selecting an Account, you will see the **Account Actions** screen. This screen displays:

- The selected Account's **name** and **type** in a card at the top
- Two action cards to choose from

### Available Actions

| Action | Description |
|--------|-------------|
| **Link Accounts** | Link unassigned trace account mappings to the selected Account. Use this when you need to associate trace records that are not yet linked to any Account. |
| **Unlink Accounts** | Remove trace account mappings that are currently linked to the selected Account. Use this when records were linked to the wrong Account or the association is no longer valid. |

### How to proceed

- Click the **Link Accounts** card to go to the Link screen (Step 3A).
- Click the **Unlink Accounts** card to go to the Unlink screen (Step 3B).
- Click the **Back** button to return to Step 1 and select a different Account.

---

## Step 3A - Link Accounts

This screen displays all **unassigned** Trace Account Mapping records (records that are not currently linked to any Account). From here you can select one or more records and link them to the Account you chose in Step 1.

### Screen layout

- **Header**: Shows "Link Accounts" and the name of the selected Account.
- **Action buttons** (top-right):
  - **Back to Actions** - Returns to Step 2
  - **Link Selected Records** - Links the selected records to the Account (disabled until you select at least one record)
- **FILTERS** tab - On the right side of the screen; opens the filter panel (see [Using Filters](#using-filters))
- **Data table** - Shows trace account mapping records with columns for Distributor, Customer, Invoice Year, Total Revenue, Contract Name/Number, Country, State, City, and Zip Code

### How to link records

1. Browse the data table to find the records you want to link. Use [filters](#using-filters) and [pagination](#pagination) to locate specific records.
2. Select records by clicking the **checkbox** on the left side of each row.
   - Use the **header checkbox** (top-left of the table) to select or deselect all records on the current page.
3. The **Selected** count (displayed in green above the table) updates in real time as you check/uncheck records.
4. You can navigate across pages and select records on different pages. Your selections are preserved when changing pages.
5. Once you have selected all the records you want to link, click the **Link Selected Records** button in the top-right corner.
6. A **success message** will confirm how many records were linked. The table will refresh automatically, and the linked records will no longer appear in the list (since they are now assigned).

---

## Step 3B - Unlink Accounts

This screen displays all Trace Account Mapping records that are **currently linked** to the selected Account. From here you can select records to remove their association with the Account.

### Screen layout

- **Header**: Shows "Unlink Accounts" and the name of the selected Account.
- **Action buttons** (top-right):
  - **Back to Actions** - Returns to Step 2
  - **Unlink Selected Records** - Removes the link between the selected records and the Account (disabled until you select at least one record)
- **FILTERS** tab - On the right side of the screen; opens the filter panel (see [Using Filters](#using-filters))
- **Data table** - Shows trace account mapping records currently linked to this Account

### How to unlink records

1. Browse the data table to find the records you want to unlink. Use [filters](#using-filters) and [pagination](#pagination) to locate specific records.
2. Select records by clicking the **checkbox** on the left side of each row.
   - Use the **header checkbox** to select or deselect all records on the current page.
3. The **Selected** count updates in real time.
4. Once you have selected all the records you want to unlink, click the **Unlink Selected Records** button in the top-right corner.
5. A **success message** will confirm how many records were unlinked. The table will refresh automatically, and the unlinked records will no longer appear in this list.

---

## Working with the Data Table

The data table is used on both the Link and Unlink screens. Here is how to work with its features.

### Table Columns

| Column | Description |
|--------|-------------|
| Checkbox | Select/deselect the row |
| Distributor | Name of the distributor company |
| Customer | Name of the customer |
| Invoice Year | Year of the invoice (e.g., 2024, 2025) |
| Total Revenue | Revenue amount in dollars |
| Contract Name/Number | Associated contract identifier |
| Country | Country of the record |
| State | State or province |
| City | City name |
| Zip Code | Postal/ZIP code |

### Selecting Records

- **Individual selection**: Click the checkbox next to any row to select or deselect it.
- **Select all on page**: Click the checkbox in the table header row to select all records on the current page.
- **Cross-page selection**: Navigate between pages using pagination. Your selections are remembered across pages.
- The **Selected** counter (shown in green text above the table) always reflects the total number of currently selected records.

### Pagination

The table supports pagination to handle large datasets. Controls are located at the bottom of the table.

- **Rows per page**: Use the dropdown in the top-right of the table to choose how many rows to display per page. Options: **10**, **25**, **50**, or **100**.
- **Page navigation**: Use the left (**<**) and right (**>**) arrow buttons at the bottom-right to move between pages.
- **Page indicator**: Shows "Page X of Y" so you know your current position.
- **Record indicator**: Shows "Showing X to Y of Z records" at the bottom-left so you know how many total records exist.

---

## Using Filters

Filters allow you to narrow down the records displayed in the data table. The filter panel is available on both the Link and Unlink screens.

### Opening the filter panel

1. Click the **FILTERS** tab on the right edge of the screen.
2. A filter panel slides in from the right side.

### Available filters

| Filter | Description | Example |
|--------|-------------|---------|
| Distributor | Filter by distributor name | "CARDINAL HEALTH" |
| Customer | Filter by customer name | "ADMIRAL" |
| Invoice Year | Filter by invoice year | "2024" or "2025" |
| Contract Name/Number | Filter by contract identifier | "SOLMB123" |
| Country | Filter by country | "Canada" |
| State | Filter by state/province | "ON" or "QC" |
| City | Filter by city name | "TORONTO" |
| Zip Code | Filter by postal/ZIP code | "M4Y" |

### How to apply filters

1. Open the filter panel by clicking **FILTERS**.
2. Type your filter criteria into one or more filter fields. Filters use partial matching, so you do not need to type the full value.
3. Click the **Apply** button at the bottom of the filter panel.
4. The data table will reload showing only records that match your filter criteria.
5. The filter panel will close automatically after applying.

### Clearing filters

1. Open the filter panel.
2. Click the **Clear** button at the bottom of the filter panel.
3. All filter fields will be reset and the table will reload showing all records.

### Closing the filter panel

- Click the **X** button in the top-right corner of the filter panel.
- Or click anywhere outside the filter panel (on the dimmed overlay area).

---

## Troubleshooting

| Issue | Resolution |
|-------|------------|
| **No accounts appear in search results** | Make sure you have typed at least 2 characters. Verify the account exists in Salesforce. |
| **Continue button is grayed out** | You must select an Account from the dropdown before continuing. |
| **No records appear in the Link table** | All trace account mappings may already be linked to accounts. Try adjusting or clearing your filters. |
| **No records appear in the Unlink table** | The selected Account may not have any trace account mappings linked to it. |
| **Link/Unlink Selected Records button is grayed out** | You must select at least one record using the checkboxes before this button becomes active. |
| **Error message appears after linking/unlinking** | The records may have already been modified by another user. Refresh the page and try again. |
| **Filters are not returning expected results** | Filters use partial matching. Try using shorter search terms. Check for typos or extra spaces. |
| **Page loads slowly** | This is normal for large datasets. Try reducing the "Rows per page" value or use filters to narrow results. |

---

## Quick Reference - Full Workflow

```
1. Navigate to the Trace Accounts tab
       |
2. Search for and select an Account
       |
3. Click Continue
       |
4. Choose an action:
   |                        |
   Link Accounts            Unlink Accounts
   |                        |
5. Browse/filter the        5. Browse/filter the
   unlinked records            linked records
       |                        |
6. Select records            6. Select records
   using checkboxes             using checkboxes
       |                        |
7. Click "Link Selected     7. Click "Unlink Selected
   Records"                    Records"
       |                        |
8. Success notification      8. Success notification
```
