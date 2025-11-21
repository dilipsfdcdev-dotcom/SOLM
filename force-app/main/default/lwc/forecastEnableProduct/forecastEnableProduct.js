import {LightningElement,api,track,wire} from 'lwc';
import {showError} from 'c/utilNotification';

import search from '@salesforce/apex/ForecastLookupProductCtrl.search';
import getDateRange from '@salesforce/apex/ForecastCtrl.getDateRange';
import getProductData from '@salesforce/apex/ForecastCtrl.getProductData';
import enableProductForecast from '@salesforce/apex/ForecastCtrl.enableProductForecast';

import modal90 from '@salesforce/resourceUrl/modal90';
import modal70 from '@salesforce/resourceUrl/modal70';

import {loadStyle} from 'lightning/platformResourceLoader';
import {volumeOptions, getConstants} from 'c/forecastUtils';

const CONSTANTS = getConstants();

export default class ForecastEnableProduct extends LightningElement {
    isLoading = false;
    @api accountId;
    @api disabled;

    @api volume;
    dateRange;

    @track products = [];
    @track _productIds = [];
    forecast = new Map();
    displayTable = false;

    step = 0;

    errors = [];
    @api currencyCode ;

    labels = {
        modalHeader: "Enable Forecasting for new Products",
        lookupInputLabel: "Select Products",
        lookupInputPlaceholder: "Search...",
        productColumn: CONSTANTS.PRODUCT,
        fulfillmentColumn: CONSTANTS.FULFILLMENT,
        direct: CONSTANTS.DIRECT_SHIPMENT,
        local: CONSTANTS.LOCAL_WAREHOUSE,
        enableProducts: 'Enable Products',
    }

    @api localWarehouseCodes; 

    /* Getters */ 

    get volumeOptions() {
        return volumeOptions();
    }

    get saveDisabled(){
        return this._productIds.length === 0;
    }

    /* Callbacks */

    connectedCallback() {
        Promise.all([loadStyle(this, modal90)]);
        this.getDateRange();
        console.log('localWarehouseCodes'+JSON.stringify(this.localWarehouseCodes))
    }

    /* Modal Actions */ 

    handleSave() {

        const allValid = [...this.template.querySelectorAll('lightning-combobox,lightning-input,select')]
            .reduce((validSoFar, inputFields) => {
                inputFields.reportValidity();
                if (!inputFields.validity.valid && !firstFocus) {
                    inputFields.focus();
                    firstFocus = true;
                }
                return validSoFar && inputFields.checkValidity();
            }, true);
        if(allValid){

            this.isLoading = true;

            let forecast = Array.from(this.forecast, ([key, value]) => {
                return {
                    productId: key,
                    directEnabled: value.direct.enabled,
                    localEnabled: value.local.enabled,
                    directForecast: Array.from(value.direct.quantities, ([key, value]) => {
                        return {
                            externalId: key,
                            quantity: value,
                        };
                    }),
                    localForecast: Array.from(value.local.quantities, ([key, value]) => {
                        return {
                            externalId: key,
                            quantity: value,
                        };
                    }),
                    uom: value.uom,
                    directWarehouse: value.direct.warehouse,  
                    localWarehouse: value.local.warehouse,
                    directPrice: value.direct.price,
                    localPrice: value.local.price
                };
            });
    
            enableProductForecast({
                    accountId: this.accountId,
                    forecast: JSON.stringify(forecast),
                    volume: this.volume,
                })
                .then(() => {
                    this.hideModal();
                    this.dispatchEvent(new CustomEvent('refresh'));
                })
                .catch((error) => {
                        // showError(error);
                        showError('An error occurred while processing your request. Please reach out to system admin to resolve this issue.');
                        console.log('error-->'+error);
                })
                .finally(() => {
                    this.isLoading = false;
                });
        }

    }

    showModal() {
        this.template.querySelector('c-modal').show();
    }

    hideModal() {
        this.template.querySelector('c-modal').hide();
        this.template.querySelector('c-lookup').clearSelection();
        this.forecast.clear();
        this.products = []
        this._productIds = [];
        this.displayTable = false;

        Promise.all([loadStyle(this, modal70)]);
    }

    /* Apex Functions */

    getDateRange() {
        getDateRange()
            .then((results) => {
                this.dateRange = results;
            })
            .catch((error) => {
                        // showError(error);
                        showError('An error occurred while processing your request. Please reach out to system admin to resolve this issue.');
                        console.log('error-->'+error);
            });
    }

    /* Input handlers */

    handleWarehouseSelect(event){
        const selectElement = event.target;
        let productId = selectElement.getAttribute('data-product');
        let method = selectElement.getAttribute('data-method');
        this.forecast.get(productId)[method].warehouse = selectElement.value;
    }

    handlepriceChange(event){
        let price = event.detail.value;
        let productId = event.currentTarget.dataset.product;
        let method = event.currentTarget.dataset.method;

        this.forecast.get(productId)[method].price = price;
    }

    handleInputChange(event) {
        let quantity = event.detail.value;
        let productId = event.currentTarget.dataset.product;
        let method = event.currentTarget.dataset.method;
        let month = event.currentTarget.dataset.month;

        this.forecast.get(productId)[method].quantities.set(month, quantity);

        if(!quantity){
            this.forecast.get(productId)[method].quantities.delete(month);
        }
    }

    handleSelectionChange(event){
        let checked = event.detail.checked;
        let productId = event.currentTarget.dataset.product;
        let method = event.currentTarget.dataset.method;

        this.forecast.get(productId)[method].enabled = checked;

        this.template.querySelectorAll(`[data-type="number"][data-method="${method}"][data-product="${productId}"]`).forEach((input) => {
            input.disabled = !checked
        });

        if(method === CONSTANTS.DIRECT_SHORT){
            let directPriceInput = this.template.querySelector(`[data-type="priceDirect"][data-method="${method}"][data-product="${productId}"]`);
            directPriceInput.disabled = !checked;

            let warehouseInput = this.template.querySelector(`[data-type="directwarehouse"][data-product="${productId}"]`);
            warehouseInput.disabled = !checked;
        }

        if(method === CONSTANTS.LOCAL_SHORT){
            let warehouseInput = this.template.querySelector(`[data-type="localwarehouse"][data-product="${productId}"]`);
            warehouseInput.disabled = !checked;

            let localPriceInput = this.template.querySelector(`[data-type="priceLocal"][data-method="${method}"][data-product="${productId}"]`);
            localPriceInput.disabled = !checked;
        }
    }

    handleVolumeChange(event) {
        this.volume = event.detail.value;
        this.step = this.volume === 'cases' ? 0.0001 : 0;

        this.template.querySelectorAll(`[data-type="number"]`).forEach((input) => {
            let uom = this.forecast.get(input.dataset.product).uom;
            if(input.value){
                if(this.volume === 'cases') {
                    input.value = (input.value / uom).toFixed(2);
                } else {
                    input.value = parseInt(input.value * uom);
                }
                
                this.forecast.get(input.dataset.product)[input.dataset.method].quantities.set(input.dataset.month, input.value);
            }
        });
    }

    handleLookupSearch(event) {
        const lookupElement = event.target;
        search({
                searchTerm: event.detail.searchTerm,
                selectedIds: event.detail.selectedIds,
                accountId: this.accountId,
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

    handleLookupSelectionChange(event) {
        let selectedProducts = Object.keys(event.detail)
            .map(function (key) {
                return event.detail[key];
            });

        if (selectedProducts.length > this._productIds.length){
            getProductData({
                productId: selectedProducts.at(-1),
            })
            .then((results) => {
                this.addProduct(results);
            })
            .catch((error) => {
                        // showError(error);
                        showError('An error occurred while processing your request. Please reach out to system admin to resolve this issue.');
                        console.log('error-->'+error);
            });
        }else{
            let difference = this._productIds.filter(x => !selectedProducts.includes(x));
            this._productIds = selectedProducts;
            this.removeProduct(difference[0]);
        }
    }

    removeProduct(productId){
        this.forecast.delete(productId);
        this.products = this.products.filter(function(value, index, arr){ 
            return value.productId !== productId;
        });

        if(this._productIds.length === 0){
            this.displayTable = false;
        }
    }

    addProduct(wrapper) {
        this._productIds = [... this._productIds, wrapper.productId];
        this.products = [...this.products, {
            productId: wrapper.productId,
            name: wrapper.name,
            productCode: wrapper.productCode,
            productLine: wrapper.productLine,
            uom: wrapper.uom ? `Case: ${wrapper.uom}` : 'Case: N/A',
        }];
       
        this.forecast.set(wrapper.productId, {
            direct: {
                enabled : true,
                quantities: new Map(),
            },
            local: {
                enabled : true,
                quantities: new Map(),
            },
            uom: wrapper.uom,
        });

        this.displayTable = true;
    }
}