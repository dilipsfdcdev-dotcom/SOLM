import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import validateCSV from '@salesforce/apex/Forecast2MassUploadCtrl.validateCSV';
import processMassUpload from '@salesforce/apex/Forecast2MassUploadCtrl.processMassUpload';
import getCSVTemplate from '@salesforce/apex/Forecast2MassUploadCtrl.getCSVTemplate';
import { validateFile, formatFileSize, extractErrorMessage } from 'c/forecast2Utils';

export default class Forecast2MassUpload extends LightningElement {
    @track fileName = '';
    @track fileSize = '';
    @track csvContent = '';
    @track isProcessing = false;
    @track showValidation = false;
    @track validationSuccess = false;
    @track validationError = '';
    @track rowCount = 0;
    @track showResults = false;
    @track uploadResult = null;

    /**
     * Computed Properties
     */
    get fileSelectLabel() {
        return this.fileName ? 'Choose Different File' : 'Choose File';
    }

    get disableValidate() {
        return !this.fileName || this.isProcessing;
    }

    get disableUpload() {
        return !this.fileName || this.isProcessing || !this.validationSuccess;
    }

    get hasErrors() {
        return this.uploadResult && this.uploadResult.errors && this.uploadResult.errors.length > 0;
    }

    /**
     * Handle select file button click
     */
    handleSelectFile() {
        const fileInput = this.template.querySelector('#fileInput');
        if (fileInput) {
            fileInput.click();
        }
    }

    /**
     * Handle file selection
     */
    handleFileChange(event) {
        const file = event.target.files[0];

        if (!file) {
            return;
        }

        // Validate file
        const validation = validateFile(file, {
            maxSize: 5 * 1024 * 1024, // 5MB
            allowedTypes: ['text/csv', 'application/vnd.ms-excel'],
            allowedExtensions: ['.csv']
        });

        if (!validation.valid) {
            this.showToast('File Validation Failed', validation.errors.join(', '), 'error');
            this.handleClearFile();
            return;
        }

        this.fileName = file.name;
        this.fileSize = formatFileSize(file.size);

        // Read file content
        const reader = new FileReader();
        reader.onload = (e) => {
            this.csvContent = e.target.result;
            this.resetValidation();
            this.showToast('File Loaded', 'CSV file loaded successfully. Click "Validate CSV" to check the format.', 'success');
        };
        reader.onerror = () => {
            this.showToast('File Read Error', 'Failed to read the file. Please try again.', 'error');
            this.handleClearFile();
        };
        reader.readAsText(file);
    }

    /**
     * Handle clear file
     */
    handleClearFile() {
        this.fileName = '';
        this.fileSize = '';
        this.csvContent = '';
        this.resetValidation();
        this.resetResults();

        const fileInput = this.template.querySelector('#fileInput');
        if (fileInput) {
            fileInput.value = '';
        }
    }

    /**
     * Handle validate CSV
     */
    handleValidate() {
        if (!this.csvContent) {
            this.showToast('No File', 'Please select a CSV file first', 'warning');
            return;
        }

        this.isProcessing = true;
        this.resetValidation();
        this.resetResults();

        validateCSV({ csvContent: this.csvContent })
            .then(result => {
                this.showValidation = true;

                if (result.valid) {
                    this.validationSuccess = true;
                    this.rowCount = result.rowCount;
                    this.showToast('Validation Passed', `CSV is valid with ${result.rowCount} data rows`, 'success');
                } else {
                    this.validationSuccess = false;
                    this.validationError = result.error;
                    this.showToast('Validation Failed', result.error, 'error');
                }
            })
            .catch(error => {
                this.showValidation = true;
                this.validationSuccess = false;
                this.validationError = extractErrorMessage(error);
                this.showToast('Validation Error', this.validationError, 'error');
            })
            .finally(() => {
                this.isProcessing = false;
            });
    }

    /**
     * Handle upload
     */
    handleUpload() {
        if (!this.csvContent) {
            this.showToast('No File', 'Please select a CSV file first', 'warning');
            return;
        }

        if (!this.validationSuccess) {
            this.showToast('Validation Required', 'Please validate the CSV before uploading', 'warning');
            return;
        }

        this.isProcessing = true;
        this.resetResults();

        processMassUpload({ csvContent: this.csvContent })
            .then(result => {
                this.uploadResult = result;
                this.showResults = true;

                if (result.success) {
                    this.showToast('Upload Successful', result.message, 'success');
                } else {
                    this.showToast('Upload Failed', result.message, 'error');
                }
            })
            .catch(error => {
                const errorMessage = extractErrorMessage(error);
                this.showToast('Upload Error', errorMessage, 'error');

                this.uploadResult = {
                    totalRows: 0,
                    successRows: 0,
                    errorRows: 0,
                    errors: [errorMessage],
                    message: 'Upload failed with error',
                    success: false
                };
                this.showResults = true;
            })
            .finally(() => {
                this.isProcessing = false;
            });
    }

    /**
     * Handle reset
     */
    handleReset() {
        this.handleClearFile();
        this.resetValidation();
        this.resetResults();
        this.showToast('Reset Complete', 'Form has been reset', 'info');
    }

    /**
     * Handle download template
     */
    handleDownloadTemplate() {
        getCSVTemplate()
            .then(template => {
                const blob = new Blob([template], { type: 'text/csv' });
                const url = window.URL.createObjectURL(blob);
                const link = document.createElement('a');
                link.href = url;
                link.download = 'forecast_upload_template.csv';
                link.click();
                window.URL.revokeObjectURL(url);
                this.showToast('Download Started', 'Template CSV is being downloaded', 'success');
            })
            .catch(error => {
                this.showToast('Download Error', extractErrorMessage(error), 'error');
            });
    }

    /**
     * Handle view sample
     */
    handleViewSample() {
        const sampleText = `Sample CSV Format:

AccountId,ProductId,Month,Quantity,UnitPrice,Direct,Local,Warehouse
001XXXXXXXXXXXXXXX,01tXXXXXXXXXXXXXXX,01/15/2025,100,50.00,true,false,Main Warehouse
001XXXXXXXXXXXXXXX,01tYYYYYYYYYYYYYYY,02/15/2025,200,75.00,false,true,Regional Warehouse

Notes:
- AccountId: 15 or 18 character Salesforce Account ID
- ProductId: 15 or 18 character Salesforce Product2 ID
- Month: Date in MM/DD/YYYY format
- Quantity: Numeric value
- UnitPrice: Decimal value (optional)
- Direct: true/false for Direct Shipment (optional)
- Local: true/false for Local Warehouse (optional)
- Warehouse: Warehouse name (optional)`;

        this.showToast('Sample CSV Format', sampleText, 'info');
    }

    /**
     * Reset validation state
     */
    resetValidation() {
        this.showValidation = false;
        this.validationSuccess = false;
        this.validationError = '';
        this.rowCount = 0;
    }

    /**
     * Reset results state
     */
    resetResults() {
        this.showResults = false;
        this.uploadResult = null;
    }

    /**
     * Show toast notification
     */
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}
