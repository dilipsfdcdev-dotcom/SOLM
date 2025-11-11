import { LightningElement, api, wire, track } from 'lwc';
import LightningConfirm from "lightning/confirm";
import { showError, showNotification } from 'c/utilNotification';
import { volumeOptions } from 'c/forecastUtils';
import { CurrentPageReference } from 'lightning/navigation';

import search from '@salesforce/apex/CustomLookupAccountCtrl.search';
import enableForecast from '@salesforce/apex/ForecastCtrl.enableForecast';
import disableForecast from '@salesforce/apex/ForecastCtrl.disableForecast';
import checkForecast from '@salesforce/apex/ForecastCtrl.checkForecast';
import insertProduct from '@salesforce/apex/ForecastCtrl.insertProduct';
import insertProductMassUpload from '@salesforce/apex/ForecastCtrlV2.insertProductMassUpload';
import deleteForecastData from '@salesforce/apex/ForecastCtrl.deleteForecasting';
import getCurrencyCode from '@salesforce/apex/ForecastCtrl.getCurrencyCode';
import DISABLE_FORECASTING_CONFIRMATION from '@salesforce/label/c.Disable_Forecasting_Confirmation';
import hasManagePermission from '@salesforce/customPermission/Forecasting_Manage';

export default class ForecastAppV2 extends LightningElement {
    @track data;
    @track showLoadingSpinner = false;
    @track massUploadMode = false;

    MAX_FILE_SIZE = 5000000; // Max file size 5.0 MB (increased for mass upload)
    filesUploaded = [];
    filename;
    isLoading = false;

    @api recordId;
    productId;
    price;
    direct;
    _forecastEnabled = false;
    _forecastNoData = false;

    labels = {
        accountSelectLabel: 'Account:',
        accountSelect: 'Select Account to Access Forecasting',
        disableForecast: DISABLE_FORECASTING_CONFIRMATION,
        forecastEnable: 'Forecasting is not enabled for selected Account.',
        forecastNoData: 'No products configured for forecasting.',
        volumeSelectLabel: 'Display/input volumes in:',
        searchProductLabel: 'Product:',
        searchProductPlaceHolder: 'Search by product name, code, or line...',
    }

    initialSelection;
    selectedVolume = 'pieces';
    pageNumber = 1;
    openModal = false;
    currencyCODE;

    @track localWarehouseCodes = [];
    errors = [];
    doneTypingInterval = 300;
    typingTimer;
    searchTerm;

    /* Computed Properties */

    get isReadOnlyPermission() {
        return !hasManagePermission;
    }

    get volumeOptions() {
        return volumeOptions();
    }

    get displayDisableForecasting() {
        return this.recordId && this._forecastEnabled && !this.isLoading && !this.isReadOnlyPermission;
    }

    get displayVolumeFilter() {
        return this.recordId && this._forecastEnabled && !this._forecastNoData;
    }

    get displayProductSearch() {
        return this.recordId && this._forecastEnabled && !this.isLoading && !this.productId && !this._forecastNoData;
    }

    get displayAddProduct() {
        return this.recordId && this._forecastEnabled && !this._forecastNoData;
    }

    get displayHistoricalForecast() {
        return this.recordId && this._forecastEnabled && !this._forecastNoData;
    }

    get displayNoAccountSelection() {
        return !this.recordId;
    }

    get displayNoForecastEnabled() {
        return this.recordId && !this._forecastEnabled && !this.isLoading;
    }

    get displayNoForecastData() {
        return this._forecastNoData && this.recordId && !this.isLoading;
    }

    get displayProductList() {
        return this.recordId && this._forecastEnabled && !this.isLoading && !this.productId && !this._forecastNoData;
    }

    get displayProductDetails() {
        return this.recordId && this.productId && !this.isLoading;
    }

    get singleAccountVariant() {
        return !this.massUploadMode ? 'brand' : 'neutral';
    }

    get multipleAccountsVariant() {
        return this.massUploadMode ? 'brand' : 'neutral';
    }

    get uploadButtonLabel() {
        return this.massUploadMode ? 'Import Mass Upload' : 'Import File';
    }

    /* Lifecycle */

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference?.state?.c__recordId) {
            this.recordId = currentPageReference.state?.c__recordId;
            this.checkForecast();

            this.initialSelection = {
                id: this.recordId,
                sObjectType: 'Account',
                icon: 'standard:account',
                title: currentPageReference.state?.c__name,
            }
        }
    }

    /* Apex Calls */

    getCurrencyCode(accId) {
        getCurrencyCode({
            accountId: accId
        })
            .then((result) => {
                this.currencyCODE = result;
            })
            .catch((error) => {
                showError('An error occurred while processing your request. Please reach out to system admin to resolve this issue.');
                console.error('Currency Code Error:', error);
            });
    }

    checkForecast() {
        this.isLoading = true;

        checkForecast({
            accountId: this.recordId
        })
            .then((result) => {
                this.localWarehouseCodes = result.availableWarehouses;

                if (result.enabled) {
                    this._forecastEnabled = true;

                    if (result.forecastedProducts > 0) {
                        this._forecastNoData = false;
                    } else {
                        this._forecastNoData = true;
                    }
                } else {
                    this._forecastEnabled = false;
                    this._forecastNoData = false;
                }
            })
            .catch((error) => {
                showError('An error occurred while processing your request. Please reach out to system admin to resolve this issue.');
                console.error('Check Forecast Error:', error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    deleteForecastData() {
        deleteForecastData({
            accountId: this.recordId
        })
            .then(() => {
                this._forecastNoData = true;
                showNotification('Success', 'All forecast data deleted successfully', 'success');
            })
            .catch((error) => {
                showError('An error occurred while processing your request. Please reach out to system admin to resolve this issue.');
                console.error('Delete Error:', error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    enableForecasting() {
        this.isLoading = true;
        enableForecast({
            accountId: this.recordId
        })
            .then(() => {
                showNotification('Success', "Forecasting Enabled", 'success');
                this._forecastEnabled = true;
                this.checkForecast();
            })
            .catch((error) => {
                showError('An error occurred while processing your request. Please reach out to system admin to resolve this issue.');
                console.error('Enable Error:', error);
                this.isLoading = false;
            })
    }

    /* Event Handlers */

    async deleteAllProducts() {
        const result = await LightningConfirm.open({
            message: "Are you sure you want to permanently delete all forecast data for this account?",
            variant: "default",
            label: "Confirmation"
        });

        if (result) {
            this.isLoading = true;
            this.deleteForecastData();
        }
    }

    disableForecasting() {
        this.openModal = true;
    }

    handleCloseModal() {
        this.openModal = false;
    }

    handleDisableForecasting() {
        this.isLoading = true;
        disableForecast({
            accountId: this.recordId
        })
            .then(() => {
                showNotification('Success', "Forecasting Disabled", 'success');
                this._forecastEnabled = false;
                this.checkForecast();
            })
            .catch((error) => {
                showError('An error occurred while processing your request. Please reach out to system admin to resolve this issue.');
                console.error('Disable Error:', error);
                this.isLoading = false;
            })
            .finally(() => {
                this.openModal = false;
            });
    }

    handleLookupSearch(event) {
        const lookupElement = event.target;
        search(event.detail)
            .then((results) => {
                lookupElement.setSearchResults(results);
            })
            .catch((error) => {
                showError('An error occurred while processing your request. Please reach out to system admin to resolve this issue.');
                console.error('Lookup Error:', error);
                this.errors = [error];
            });
    }

    handleLookupSelectionChange(event) {
        if (Object.keys(event.detail).length === 0) {
            this.recordId = undefined;
            this.productId = undefined;
            this.pageNumber = 1;
            this.searchTerm = '';
        } else {
            this.recordId = event.detail[0];
            this.getCurrencyCode(this.recordId);
            this.checkForecast();
        }
    }

    handleVolumeChange(event) {
        this.selectedVolume = event.detail.value;
    }

    handleRefresh() {
        this.checkForecast();
    }

    handleBack() {
        this.productId = null;
    }

    handleDisabled() {
        this.productId = null;
        this.checkForecast();
    }

    handleProductSelect(event) {
        this.productId = event.detail.product;
        this.price = event.detail.price;
        this.direct = event.detail.direct;
    }

    handlePageSelect(event) {
        this.pageNumber = event.detail.page;
    }

    handleProductSearch(event) {
        clearTimeout(this.typingTimer);

        let value = event.target.value;
        this.searchTerm = value;

        this.typingTimer = setTimeout(() => {
            const productList = this.template.querySelector('c-forecast-product-list-v2');
            if (productList) {
                productList.search();
            }
        }, this.doneTypingInterval);
    }

    /* Upload Mode Handlers */

    handleSingleAccountMode() {
        this.massUploadMode = false;
        this.filename = '';
        this.filesUploaded = [];
    }

    handleMultipleAccountsMode() {
        this.massUploadMode = true;
        this.filename = '';
        this.filesUploaded = [];
    }

    /* File Upload Handlers */

    importcsv(event) {
        if (event.target.files.length > 0) {
            const file = event.target.files[0];

            if (file.size > this.MAX_FILE_SIZE) {
                this.filename = 'File size is too large. Maximum 5MB allowed.';
                showError('File size exceeds maximum limit of 5MB');
                return;
            }

            this.filesUploaded = event.target.files;
            this.filename = file.name;
        }
    }

    async handleFileImport() {
        const message = this.massUploadMode
            ? "You are about to upload forecast data for multiple accounts. This will update forecasts for all accounts included in the CSV. Do you want to continue?"
            : "By uploading this file, you will update only the items included in the attachment. For any items not included in the attachment, the current forecast will remain unchanged. Do you want to continue?";

        const result = await LightningConfirm.open({
            message: message,
            variant: "default",
            label: "Confirmation"
        });

        if (result) {
            this.showLoadingSpinner = true;
            this.readFiles();
        }
    }

    readFiles() {
        [...this.filesUploaded].forEach(async file => {
            try {
                const result = await this.load(file);
                this.data = this.csvJSON(result);

                if (this.massUploadMode) {
                    // Mass upload - call new Apex method
                    insertProductMassUpload({
                        prodJson: this.data
                    })
                        .then((result) => {
                            if (result === 'Success') {
                                showNotification('Success', 'Mass upload completed successfully', 'success');
                                this._forecastEnabled = true;
                                this.checkForecast();
                            } else {
                                showError(result);
                            }
                        })
                        .catch((error) => {
                            showError('An error occurred while processing your request. Please reach out to system admin to resolve this issue.');
                            console.error('Mass Upload Error:', error);
                        })
                        .finally(() => {
                            this.showLoadingSpinner = false;
                        });
                } else {
                    // Single account upload - use existing method
                    insertProduct({
                        prodJson: this.data,
                        accountId: this.recordId
                    })
                        .then((result) => {
                            if (result === 'Success') {
                                showNotification('Success', 'File imported successfully', 'success');
                                this._forecastEnabled = true;
                                this.checkForecast();
                            } else {
                                showError(result);
                            }
                        })
                        .catch((error) => {
                            showError('An error occurred while processing your request. Please reach out to system admin to resolve this issue.');
                            console.error('Upload Error:', error);
                        })
                        .finally(() => {
                            this.showLoadingSpinner = false;
                        });
                }

            } catch (e) {
                console.error('File Load Exception:', e);
                showError('Failed to read file. Please ensure it is a valid CSV file.');
                this.showLoadingSpinner = false;
            }
        });
    }

    async load(file) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = function () {
                resolve(reader.result);
            };
            reader.onerror = function () {
                reject(reader.error);
            };
            reader.readAsText(file);
        });
    }

    csvJSON(csv) {
        const lines = csv.split(/\r\n|\n/);
        const result = [];
        const headers = lines[0].split(",");

        for (let i = 1; i < lines.length - 1; i++) {
            if (lines[i].trim() === '') continue;

            const obj = {};
            const currentline = lines[i].split(",");

            for (let j = 0; j < headers.length; j++) {
                obj[headers[j].trim()] = currentline[j]?.trim();
            }

            result.push(obj);
        }

        return JSON.stringify(result);
    }

    /* Drag and Drop Handlers */

    handleDragOver(event) {
        event.preventDefault();
        event.currentTarget.classList.add('fc2-upload-area--dragover');
    }

    handleDragLeave(event) {
        event.preventDefault();
        event.currentTarget.classList.remove('fc2-upload-area--dragover');
    }

    handleDrop(event) {
        event.preventDefault();
        event.currentTarget.classList.remove('fc2-upload-area--dragover');

        if (event.dataTransfer.files.length > 0) {
            const file = event.dataTransfer.files[0];

            if (file.type === 'text/csv' || file.name.endsWith('.csv')) {
                if (file.size > this.MAX_FILE_SIZE) {
                    showError('File size exceeds maximum limit of 5MB');
                    return;
                }

                this.filesUploaded = event.dataTransfer.files;
                this.filename = file.name;
            } else {
                showError('Please upload a valid CSV file');
            }
        }
    }
}
