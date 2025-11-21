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

    async handleMassUpload() {
        if (!this.massFile) {
            this.massFileError = 'Please select a file first';
            return;
        }

        this.isMassLoading = true;
        this.massUploadResult = '';

        try {
            const fileContent = await this.readFile(this.massFile);
            const jsonData = this.csvToJson(fileContent);

            if (!jsonData || jsonData.length === 0) {
                throw new Error('No valid data found in CSV file');
            }

            // Validate AccountId column exists
            if (!jsonData[0].hasOwnProperty('AccountId')) {
                throw new Error('AccountId column is required for mass upload');
            }

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
                    showNotification('Warning', 'Upload completed with some errors', 'warning');
                }
            }

        } catch (error) {
            this.massResultSuccess = false;
            this.massUploadResult = error.message || 'An error occurred during upload';
            showError('An error occurred while processing your request. Please check the file format and try again.');
            console.error('Mass upload error:', error);
        } finally {
            this.isMassLoading = false;
        }
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