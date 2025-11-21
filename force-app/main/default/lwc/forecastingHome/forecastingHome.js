import { LightningElement, track } from 'lwc';
import { showError, showNotification } from 'c/utilNotification';
import insertProductMass from '@salesforce/apex/ForecastCtrl.insertProductMass';

export default class ForecastingHome extends LightningElement {
    searchByAccount = false;
    searchByProduct = false;
    showMassUpload = false;

    // Mass upload properties
    @track massFile = null;
    massFileName = '';
    massFileError = '';
    isMassLoading = false;
    massUploadResult = '';
    massResultSuccess = false;

    MAX_FILE_SIZE = 5000000; // 5MB

    get showBackButton() {
        return this.searchByAccount || this.searchByProduct || this.showMassUpload;
    }

    get isMassUploadDisabled() {
        return !this.massFile || this.isMassLoading;
    }

    get massResultClass() {
        return this.massResultSuccess
            ? 'slds-box slds-theme_success slds-text-color_inverse'
            : 'slds-box slds-theme_error slds-text-color_inverse';
    }

    get massResultIcon() {
        return this.massResultSuccess ? 'utility:success' : 'utility:error';
    }

    handleBackToMenu() {
        this.searchByAccount = false;
        this.searchByProduct = false;
        this.showMassUpload = false;
        this.resetMassUpload();
    }

    hanldeSearchByAccount() {
        this.searchByAccount = true;
        this.searchByProduct = false;
        this.showMassUpload = false;
    }

    hanldeSearchByProduct() {
        this.searchByProduct = true;
        this.searchByAccount = false;
        this.showMassUpload = false;
    }

    handleMassUploadClick() {
        this.showMassUpload = true;
        this.searchByAccount = false;
        this.searchByProduct = false;
    }

    resetMassUpload() {
        this.massFile = null;
        this.massFileName = '';
        this.massFileError = '';
        this.massUploadResult = '';
        this.massResultSuccess = false;
    }

    handleMassFileSelect(event) {
        this.massFileError = '';
        this.massUploadResult = '';

        if (event.target.files && event.target.files.length > 0) {
            const file = event.target.files[0];

            if (file.size > this.MAX_FILE_SIZE) {
                this.massFileError = 'File size exceeds 5MB limit';
                this.massFile = null;
                this.massFileName = '';
                return;
            }

            if (!file.name.toLowerCase().endsWith('.csv')) {
                this.massFileError = 'Only CSV files are allowed';
                this.massFile = null;
                this.massFileName = '';
                return;
            }

            this.massFile = file;
            this.massFileName = file.name;
        }
    }

    downloadMassTemplate() {
        const template = 'AccountId,PRODUCT2ID,Direct,Local,Month,UNITPRICE,Quantity,Warehouse\n' +
            '001XXXXXXXXXXXX,01tXXXXXXXXXXXX,true,false,01/01/2025,100.00,50,';

        // Use data URL approach for better LWC compatibility
        const encodedData = encodeURIComponent(template);
        const dataUrl = 'data:text/csv;charset=utf-8,' + encodedData;

        const link = document.createElement('a');
        link.setAttribute('href', dataUrl);
        link.setAttribute('download', 'forecast_mass_upload_template.csv');
        link.style.visibility = 'hidden';
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
    }

    // Required columns for mass upload
    MASS_REQUIRED_COLUMNS = ['AccountId', 'PRODUCT2ID', 'Direct', 'Local', 'Month', 'UNITPRICE', 'Quantity', 'Warehouse'];

    async handleMassUpload() {
        if (!this.massFile) {
            this.massFileError = 'Please select a file first';
            return;
        }

        this.isMassLoading = true;
        this.massUploadResult = '';
        this.massFileError = '';

        try {
            const fileContent = await this.readFile(this.massFile);

            // Validate and convert CSV
            const validationResult = this.validateMassUploadCSV(fileContent);

            if (!validationResult.success) {
                throw new Error(validationResult.error);
            }

            const jsonData = validationResult.data;

            const result = await insertProductMass({
                prodJson: JSON.stringify(jsonData)
            });

            if (result.startsWith('Success')) {
                this.massResultSuccess = true;
                this.massUploadResult = result;
                showNotification('Success', result, 'success');
            } else {
                this.massResultSuccess = false;
                this.massUploadResult = result;
                if (result.includes('errors')) {
                    showNotification('Warning', 'Upload completed with some errors. Check the details below.', 'warning');
                } else {
                    showError(result);
                }
            }

        } catch (error) {
            this.massResultSuccess = false;
            this.massUploadResult = error.message || 'An error occurred during upload';
            showError(error.message || 'An error occurred while processing your request. Please check the file format and try again.');
            console.error('Mass upload error:', error);
        } finally {
            this.isMassLoading = false;
        }
    }

    validateMassUploadCSV(csv) {
        const lines = csv.split(/\r\n|\n/);

        if (lines.length < 2) {
            return {
                success: false,
                error: 'CSV file is empty or has no data rows. Please download and use the template.'
            };
        }

        const headers = lines[0].split(',').map(h => h.trim());

        // Check for missing required columns
        const missingColumns = [];
        for (const col of this.MASS_REQUIRED_COLUMNS) {
            if (!headers.includes(col)) {
                missingColumns.push(col);
            }
        }

        if (missingColumns.length > 0) {
            return {
                success: false,
                error: `Invalid template. Missing required columns: ${missingColumns.join(', ')}. Please download and use the correct template.`
            };
        }

        // Parse and validate data rows
        const result = [];
        const errors = [];

        for (let i = 1; i < lines.length; i++) {
            if (!lines[i].trim()) continue;

            const obj = {};
            const currentLine = lines[i].split(',');

            // Check column count
            if (currentLine.length !== headers.length) {
                errors.push(`Row ${i}: Expected ${headers.length} columns but found ${currentLine.length}`);
                continue;
            }

            for (let j = 0; j < headers.length; j++) {
                obj[headers[j]] = currentLine[j] ? currentLine[j].trim() : '';
            }

            // Validate required fields
            const rowErrors = [];

            if (!obj.AccountId) {
                rowErrors.push('AccountId is required');
            } else if (obj.AccountId.length !== 15 && obj.AccountId.length !== 18) {
                rowErrors.push('AccountId must be 15 or 18 characters');
            }

            if (!obj.PRODUCT2ID) {
                rowErrors.push('PRODUCT2ID is required');
            }

            if (!obj.Month) {
                rowErrors.push('Month is required');
            } else {
                // Validate date format MM/DD/YYYY
                const dateRegex = /^(0[1-9]|1[0-2])\/(0[1-9]|[12]\d|3[01])\/\d{4}$/;
                if (!dateRegex.test(obj.Month)) {
                    rowErrors.push('Month must be in MM/DD/YYYY format (e.g., 01/01/2025)');
                }
            }

            if (obj.Quantity && isNaN(parseFloat(obj.Quantity))) {
                rowErrors.push('Quantity must be a number');
            }

            if (obj.UNITPRICE && isNaN(parseFloat(obj.UNITPRICE))) {
                rowErrors.push('UNITPRICE must be a number');
            }

            if (obj.Direct && !['true', 'false'].includes(obj.Direct.toLowerCase())) {
                rowErrors.push('Direct must be true or false');
            }

            if (obj.Local && !['true', 'false'].includes(obj.Local.toLowerCase())) {
                rowErrors.push('Local must be true or false');
            }

            if (rowErrors.length > 0) {
                errors.push(`Row ${i}: ${rowErrors.join(', ')}`);
            } else {
                result.push(obj);
            }
        }

        if (result.length === 0) {
            let errorMsg = 'No valid data found in CSV file.';
            if (errors.length > 0) {
                errorMsg += '\n\nErrors found:\n' + errors.slice(0, 5).join('\n');
                if (errors.length > 5) {
                    errorMsg += `\n... and ${errors.length - 5} more errors`;
                }
            }
            return {
                success: false,
                error: errorMsg
            };
        }

        // Log warnings for partially valid data
        if (errors.length > 0) {
            console.warn(`${errors.length} rows had validation errors and were skipped:`, errors);
        }

        return {
            success: true,
            data: result,
            warnings: errors.length > 0 ? `${errors.length} rows were skipped due to validation errors` : null
        };
    }

    readFile(file) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = () => resolve(reader.result);
            reader.onerror = () => reject(new Error('Failed to read file'));
            reader.readAsText(file);
        });
    }

    csvToJson(csv) {
        const lines = csv.split(/\r\n|\n/);
        const result = [];
        const headers = lines[0].split(',').map(h => h.trim());

        for (let i = 1; i < lines.length; i++) {
            if (!lines[i].trim()) continue;

            const obj = {};
            const currentLine = lines[i].split(',');

            for (let j = 0; j < headers.length; j++) {
                obj[headers[j]] = currentLine[j] ? currentLine[j].trim() : '';
            }

            result.push(obj);
        }

        return result;
    }
}