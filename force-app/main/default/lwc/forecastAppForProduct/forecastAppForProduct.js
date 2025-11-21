import {LightningElement,api,track,wire} from 'lwc';
import {showError} from 'c/utilNotification';

import search from '@salesforce/apex/ForecastLookupProductCtrl.searchProducts';
import getProductData from '@salesforce/apex/ForecastCtrl.getProductData';
import checkForecast from '@salesforce/apex/ForecastCtrl.checkForecast';
import {volumeOptions, getConstants} from 'c/forecastUtils';
import hasManagePermission from '@salesforce/customPermission/Forecasting_Manage';
const CONSTANTS = getConstants();
export default class ForecastAppForProduct extends LightningElement {
    isLoading = false;
    @track products = [];
    AccountId;
    productId;
    selectedProduct ;
    forecast = new Map();
    displayTable = false;
    price;
    direct;
    step = 0;
    pageNumber = 1;
    errors = [];
    handleSearchByProduct = true;
    selectedVolume = 'pieces';
    showProductsList = false;
    showProductDetails = false;
    labels = {
        productSelect: 'Select Product to access Forecasting.',
        modalHeader: "Enable Forecasting for new Products",
        lookupInputLabel: "Product:",
        lookupInputPlaceholder: "Search...",
        productColumn: CONSTANTS.PRODUCT,
        fulfillmentColumn: CONSTANTS.FULFILLMENT,
        direct: CONSTANTS.DIRECT_SHIPMENT,
        local: CONSTANTS.LOCAL_WAREHOUSE,
        enableProducts: 'Enable Products',
        searchProductLabel: 'Product:',
    }

    get isReadOnlyPermission(){
        return !hasManagePermission;
    }

    get showList(){
        return this.showProductsList && this.productId != undefined;
    }

    get displayNoProductSelection(){
        return !this.productId;
    }

    handleLookupSearch(event) {
        const lookupElement = event.target;
        search({
                searchTerm: event.detail.searchTerm,
                selectedIds: event.detail.selectedIds,
            })
            .then((results) => {
                lookupElement.setSearchResults(results);
            })
            .catch((error) => {
                        // showError(error);
                        showError('An error occurred while processing your request. Please reach out to system admin to resolve this issue.');
                        console.log('error-->'+error);
                this.errors = [error];
            });
    }

    handleLookupSelectionChange(event){
        this.showProductsList = true;
        this.showProductDetails = false;
        this.productId = event.detail[0];
        console.log('productId'+this.productId)
    }

    handleProductSelect(event){
        this.showProductsList = false;
        this.showProductDetails = true;

        this.selectedProduct = event.detail.product;
        this.price = event.detail.price;
        this.direct = event.detail.direct;
        this.AccountId = event.detail.accountId;
        console.log('this.AccountId',this.AccountId);
        this.checkForecast();
    }

    checkForecast(){
        this.isLoading = true;

        checkForecast({
            accountId: this.AccountId
        })
        .then((result) => {
            this.localWarehouseCodes = result.availableWarehouses;
            this.isLoading = false;
        })
        .catch((error) => {
           // showError(error);
            showError('An error occurred while processing your request. Please reach out to system admin to resolve this issue.');
            console.log('error-->'+error);
            this.isLoading = false;
        });
    }

    handlePageSelect(event){
        this.pageNumber = event.detail.page;
    }

    handleBack(){
        this.showProductDetails = false;
        this.showProductsList = true;
    }

    handleDisabled(){
        this.showProductDetails = false;
        this.showProductsList = true;
        this.checkForecast();
    }
}