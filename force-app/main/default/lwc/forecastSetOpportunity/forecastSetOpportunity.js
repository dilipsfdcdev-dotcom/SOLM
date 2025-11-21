import {LightningElement, api, track} from 'lwc';
import {CloseActionScreenEvent} from 'lightning/actions';
import {showError, showNotification} from 'c/utilNotification';

import {fulfillmentOptions} from 'c/forecastUtils';
import { loadStyle} from 'lightning/platformResourceLoader';

import modal90 from '@salesforce/resourceUrl/modal90';
import modal70 from '@salesforce/resourceUrl/modal70';

import getDateRange from '@salesforce/apex/ForecastCtrl.getDateRange';
import getForecastingOpportunityDataToProcess from '@salesforce/apex/OpportunitySetForecastController.getForecastingOpportunityDataToProcess';
import saveForecasting from '@salesforce/apex/OpportunitySetForecastController.saveForecasting';
import NO_FORECASTING_FOR_OPP_PRODUCTS_LABEL from '@salesforce/label/c.No_forecasting_for_opp_products_enabled';

import {volumeOptions, getConstants} from 'c/forecastUtils';

const CONSTANTS = getConstants();

export default class ForecastSetOpportunity extends LightningElement {
    @api recordId;
    oppRecordType;

    disableConfirmButton = false;
    isLoading = false;
    isModalOpen = false;
    showForecastTable = false;
    showNoProductsLabel = false;

    @track products;
    productsMap = new Map();
    @track selectedProductsIds = new Set();

    enabledColumnHeaderInfo = 'Enabled fulfillments';
    noProductsLabel = NO_FORECASTING_FOR_OPP_PRODUCTS_LABEL;

    dateRange;
    selectedVolume;
    step = 0;

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

    findSchedule(productId, scheduleDate){
        let product = this.productsMap.get(productId);
        return product.scheduleWrappers.find(schedule => schedule.scheduleDate == scheduleDate);
    }

    handleCancel(){
        this.closeModal();
    }

    handleCommentChange(event) {
        let product = this.productsMap.get(event.currentTarget.dataset.product);
        product.comment = event.detail.value;
        if(product.fulfillment === CONSTANTS.DIRECT_SHIPMENT_COMBOBOX_VALUE) {
            product.commentDirect = event.detail.value;
        } else {
            product.commentLocal = event.detail.value;
        }
    }

    handleConfirm() {
        this.disableConfirmButton = true;
        this.isLoading = true;
        let productsToInsert = [];
        this.selectedProductsIds.forEach((value) => {
            productsToInsert.push(this.productsMap.get(value));
        });

        productsToInsert.forEach(product => {
            product.scheduleWrappers.forEach(schedule => {
                if(!schedule.quantity) {
                    schedule.quantity = 0;
                }
            });
        });

        saveForecasting({productWrappers: productsToInsert, opportunityRecordType: this.oppRecordType})
            .then(result => {
                showNotification('Success',"Opportunity Forecasting updated",'success');
                this.closeModal();
            }).catch(error => {
                        // showError(error);
                        showError('An error occurred while processing your request. Please reach out to system admin to resolve this issue.');
                        console.log('error-->'+error);
            }).finally(() => {
                this.isLoading = false;
                this.disableConfirmButton = false;
            });
    }

    handleFulfillmentChange(event) {
        let product = this.productsMap.get(event.currentTarget.dataset.product);
        product.fulfillment = event.detail.value;
        if(event.detail.value === CONSTANTS.DIRECT_SHIPMENT_COMBOBOX_VALUE) {
            product.comment = product.commentDirect;

        } else {
            product.comment = product.commentLocal;
        }
    }

    handleInputChange(event){
        this.findSchedule(event.currentTarget.dataset.product, event.currentTarget.dataset.scheduledate).quantity = event.detail.value;
    }

    handleVolumeChange(event){
        let value = event.detail.value;
        this.step = value === 'cases' ? 0.01 : 0;

        this.template.querySelectorAll(`[data-type="number"]`).forEach((input) => {
            let product = this.productsMap.get(input.dataset.product);
            if(input.value) {
                if(value === 'cases') {
                    input.value /= product.caseQuantity;
                } else {
                    input.value *= product.caseQuantity;
                }
                this.findSchedule(input.dataset.product, input.dataset.scheduledate).quantity = input.value;
            }
            product.volume = value;
        });
    }

    handleSelectionChange(event) {
        let checked = event.detail.checked;
        let productId = event.currentTarget.dataset.product;
        if(checked) {
            this.selectedProductsIds.add(productId);
        } else {
            this.selectedProductsIds.delete(productId);
        }

        if(this.selectedProductsIds.size === 0) {
            this.disableConfirmButton = true;
        } else {
            this.disableConfirmButton = false;
        }
    }

    get fulfillmentOptions() {
        return fulfillmentOptions();
    }

    get volumeOptions() {
        return volumeOptions();
    }

    renderedCallback() {
        if(this.recordId && !this.isModalOpen) {
            this.isLoading = true;
            this.isModalOpen = true;
            getForecastingOpportunityDataToProcess({opportunityId: this.recordId})
                .then(result => {
                    if(result) {
                        this.oppRecordType = result.recordType;
                        if(this.oppRecordType === 'NACA') {
                            this.selectedVolume = 'cases';
                            this.step = 0.01;
                        } else {
                            this.selectedVolume = 'pieces'
                        }

                        this.products = JSON.parse(JSON.stringify(result.products));
                        this.products.forEach(product => {
                            this.productsMap.set(product.opportunityLineItemId, product);
                            this.selectedProductsIds.add(product.opportunityLineItemId);

                            product.disableFulfillmentMethodCombobox = false;

                            if(product.isDirectEnabled && !product.isLocalEnabled) {
                                product.disableFulfillmentMethodCombobox = true;
                                product.fulfillment = CONSTANTS.DIRECT_SHIPMENT_COMBOBOX_VALUE;
                            } else if (!product.isDirectEnabled && product.isLocalEnabled) {
                                product.fulfillment = CONSTANTS.LOCAL_WAREHOUSE_COMBOBOX_VALUE;
                                product.disableFulfillmentMethodCombobox = true;
                            } else if (!product.fulfillment) {
                                product.fulfillment = CONSTANTS.DIRECT_SHIPMENT_COMBOBOX_VALUE;
                            }

                            if(product.fulfillment === CONSTANTS.DIRECT_SHIPMENT_COMBOBOX_VALUE) {
                                product.comment = product.commentDirect;
                            } else if(product.fulfillment === CONSTANTS.LOCAL_WAREHOUSE_COMBOBOX_VALUE) {
                                product.comment = product.commentLocal;
                            }
                        });
                        this.showForecastTable = true;
                    } else {
                        this.disableConfirmButton = true;
                        this.showNoProductsLabel = true;
                    }
                }).catch(error => {
                        // showError(error);
                        showError('An error occurred while processing your request. Please reach out to system admin to resolve this issue.');
                        console.log('error-->'+error);
            }).finally(() => {
                this.isLoading = false;
            });
        }
    }

    connectedCallback() {
        Promise.all([
             loadStyle(this, modal90)
         ]);
        this.getDateRange();
    }

    disconnectedCallback() {
        Promise.all([
             loadStyle(this, modal70)
         ])
    }

    closeModal(){        
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}