# Forecasting 2.0 - CSV Upload Templates

## Overview
Forecasting 2.0 supports two types of CSV uploads:
1. **Single Account Upload** - Upload forecast data for one account
2. **Mass Upload** - Upload forecast data for multiple accounts simultaneously

## CSV Format Requirements

### Column Descriptions

| Column Name | Required | Description | Example |
|------------|----------|-------------|---------|
| **AccountId** | Yes (Mass Upload) | Salesforce Account ID | 0012i000001Y1Y1AAA |
| **PRODUCT2ID** | Yes | Salesforce Product2 ID | a012i000001X1X1AAA |
| **Direct** | No | Enable Direct Shipment (true/false) | true |
| **Local** | No | Enable Local Warehouse (true/false) | false |
| **Month** | Yes | Forecast month (MM/DD/YYYY) | 01/01/2025 |
| **UNITPRICE** | No | Product unit price | 100.00 |
| **Quantity** | Yes | Forecast quantity | 50 |
| **Warehouse** | No | Warehouse name (for local) | Main Warehouse |

### Important Notes

1. **AccountId Column**:
   - **REQUIRED** for mass upload mode
   - Optional for single account mode (uses selected account)

2. **Date Format**:
   - Supports: MM/DD/YYYY (e.g., 01/15/2025)
   - Supports: YYYY-MM-DD (e.g., 2025-01-15)

3. **Boolean Values**:
   - Accepts: true, false, TRUE, FALSE, True, False
   - Defaults to false if blank

4. **File Requirements**:
   - Format: CSV (Comma-Separated Values)
   - Maximum size: 5 MB
   - Encoding: UTF-8

## Template 1: Single Account Upload

Use this template when uploading forecast data for the currently selected account.

### Template CSV
```csv
PRODUCT2ID,Direct,Local,Month,UNITPRICE,Quantity,Warehouse
a012i000001X1X1AAA,true,false,01/01/2025,100.00,50,
a012i000001X1X2AAA,false,true,01/01/2025,75.50,100,Regional Warehouse
a012i000001X1X3AAA,true,true,02/01/2025,120.00,75,Main Warehouse
a012i000001X1X1AAA,true,false,02/01/2025,100.00,60,
a012i000001X1X2AAA,false,true,02/01/2025,75.50,110,Regional Warehouse
```

### Example Data Explanation

**Row 1**: Product X1X1
- Direct shipment enabled
- January 2025
- Price: $100.00
- Quantity: 50 units

**Row 2**: Product X1X2
- Local warehouse enabled
- January 2025
- Price: $75.50
- Quantity: 100 units
- Warehouse: Regional Warehouse

**Row 3**: Product X1X3
- Both Direct AND Local enabled
- February 2025
- Price: $120.00
- Quantity: 75 units
- Warehouse: Main Warehouse

## Template 2: Mass Upload (Multiple Accounts)

Use this template when uploading forecast data for multiple accounts in one file.

### Template CSV
```csv
AccountId,PRODUCT2ID,Direct,Local,Month,UNITPRICE,Quantity,Warehouse
0012i000001Y1Y1AAA,a012i000001X1X1AAA,true,false,01/01/2025,100.00,50,
0012i000001Y1Y1AAA,a012i000001X1X2AAA,false,true,01/01/2025,75.50,100,Regional Warehouse
0012i000001Y1Y2AAA,a012i000001X1X1AAA,true,false,01/01/2025,100.00,80,
0012i000001Y1Y2AAA,a012i000001X1X3AAA,true,true,01/01/2025,120.00,60,Central Warehouse
0012i000001Y1Y3AAA,a012i000001X1X2AAA,false,true,02/01/2025,75.50,120,Regional Warehouse
0012i000001Y1Y3AAA,a012i000001X1X3AAA,true,true,02/01/2025,120.00,90,Central Warehouse
```

### Example Data Explanation

**Account Y1Y1AAA**:
- Product X1X1: Direct shipment, 50 units in January
- Product X1X2: Local warehouse, 100 units in January

**Account Y1Y2AAA**:
- Product X1X1: Direct shipment, 80 units in January
- Product X1X3: Both methods, 60 units in January

**Account Y1Y3AAA**:
- Product X1X2: Local warehouse, 120 units in February
- Product X1X3: Both methods, 90 units in February

## Advanced Examples

### Example 1: Quarterly Forecast for One Product

Upload forecast for same product across multiple months:

```csv
AccountId,PRODUCT2ID,Direct,Local,Month,UNITPRICE,Quantity,Warehouse
0012i000001Y1Y1AAA,a012i000001X1X1AAA,true,false,01/01/2025,100.00,50,
0012i000001Y1Y1AAA,a012i000001X1X1AAA,true,false,02/01/2025,100.00,60,
0012i000001Y1Y1AAA,a012i000001X1X1AAA,true,false,03/01/2025,100.00,55,
```

### Example 2: Multiple Products with Different Fulfillment Methods

```csv
AccountId,PRODUCT2ID,Direct,Local,Month,UNITPRICE,Quantity,Warehouse
0012i000001Y1Y1AAA,a012i000001X1X1AAA,true,false,01/01/2025,100.00,50,
0012i000001Y1Y1AAA,a012i000001X1X2AAA,false,true,01/01/2025,75.50,100,Regional Warehouse
0012i000001Y1Y1AAA,a012i000001X1X3AAA,true,true,01/01/2025,120.00,75,Main Warehouse
```

### Example 3: Price Changes Over Time

Same product with different prices in different months:

```csv
AccountId,PRODUCT2ID,Direct,Local,Month,UNITPRICE,Quantity,Warehouse
0012i000001Y1Y1AAA,a012i000001X1X1AAA,true,false,01/01/2025,100.00,50,
0012i000001Y1Y1AAA,a012i000001X1X1AAA,true,false,02/01/2025,105.00,50,
0012i000001Y1Y1AAA,a012i000001X1X1AAA,true,false,03/01/2025,110.00,50,
```

## How to Use

### Single Account Upload
1. Select an account in Forecasting 2.0
2. Click "Single Account" mode toggle
3. Choose your CSV file
4. Click "Import File"
5. Confirm the upload

### Mass Upload
1. Open Forecasting 2.0
2. Click "Multiple Accounts" mode toggle
3. Choose your CSV file (must include AccountId column)
4. Click "Import Mass Upload"
5. Confirm the upload
6. Review success/error messages

## Validation Rules

The system validates:
1. **AccountId exists** (for mass upload)
2. **Product2ID exists** in Salesforce
3. **Warehouse name exists** (if provided)
4. **Date format is valid**
5. **Numeric values are valid** (Price, Quantity)
6. **File size is under 5MB**

## Error Messages

### Common Errors

**"AccountId column is required for mass upload"**
- Solution: Add AccountId as the first column in your CSV

**"One or more AccountIds in the CSV do not exist"**
- Solution: Verify all Account IDs are valid Salesforce IDs

**"File size exceeds maximum limit"**
- Solution: Split your file into smaller files (under 5MB each)

**"Error parsing date"**
- Solution: Use MM/DD/YYYY or YYYY-MM-DD format

**"Warehouse not found"**
- Solution: Check warehouse name spelling or create warehouse first

## Best Practices

1. **Test with Small Files First**: Start with 5-10 rows to test
2. **Use Valid IDs**: Copy IDs directly from Salesforce
3. **Check Your Data**: Review CSV before upload
4. **One Month at a Time**: For large uploads, split by month
5. **Backup First**: Export existing forecasts before mass upload
6. **Use Templates**: Start from these templates
7. **UTF-8 Encoding**: Save CSV with UTF-8 encoding
8. **No Special Characters**: Avoid special characters in warehouse names

## Tips for Excel Users

### Creating CSV from Excel

1. Open Excel file
2. Format date columns as "MM/DD/YYYY"
3. Ensure no formulas remain (values only)
4. File > Save As > CSV (Comma delimited) (*.csv)
5. Choose UTF-8 encoding if prompted
6. Click Save

### Common Excel Issues

**Problem**: Dates showing as numbers (e.g., 44928)
- **Solution**: Format cells as Date before saving

**Problem**: Leading zeros removed from IDs
- **Solution**: Format cells as Text before entering IDs

**Problem**: Extra commas in file
- **Solution**: Remove empty columns before saving

## Getting IDs from Salesforce

### Account IDs
1. Go to Account record
2. Copy the ID from the URL (18 characters)
3. Example: `0012i000001Y1Y1AAA`

### Product IDs
1. Go to Product record
2. Copy the ID from the URL (18 characters)
3. Example: `a012i000001X1X1AAA`

### Warehouse Names
1. Go to Warehouse records
2. Use the exact Name field value
3. Names are case-sensitive

## Download Templates

### Single Account Template
[Download: forecast_single_account_template.csv]

### Mass Upload Template
[Download: forecast_mass_upload_template.csv]

## Support

If you encounter issues:
1. Verify CSV format matches templates
2. Check all IDs are valid
3. Ensure file size is under 5MB
4. Review error messages carefully
5. Test with a small sample first
6. Contact system administrator if problems persist

---

**Last Updated**: 2025-11-11
**Version**: 2.0.0
