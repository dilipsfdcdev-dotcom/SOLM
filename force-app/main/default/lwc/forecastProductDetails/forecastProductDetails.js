import {LightningElement, api, track} from 'lwc';

import getForecast from '@salesforce/apex/ForecastCtrl.getForecastDetailsForProduct';
import upsertBaseForecast from '@salesforce/apex/ForecastCtrl.upsertBaseForecast';
import upsertForecastAdjustments from '@salesforce/apex/ForecastCtrl.upsertForecastAdjustments';
import setFulfillmentMethod from '@salesforce/apex/ForecastCtrl.setFulfillmentMethod';
import disableProduct from '@salesforce/apex/ForecastCtrl.disableProduct';
import deactivateAdjustment from '@salesforce/apex/ForecastCtrl.deactivateAdjustment';
import forecastOpportunityApproval from '@salesforce/apex/ForecastCtrl.forecastOpportunityApproval';
import updateWarehouse from '@salesforce/apex/ForecastCtrl.updateWarehouse';
import updatePriceFP from '@salesforce/apex/ForecastCtrl.updatePriceFP';

import {showError, showNotification} from 'c/utilNotification';
import {getConstants, mapToArray} from 'c/forecastUtils';

const FULFILLMENT_DEFAULT_ROW_SPAN = 4;

const CONSTANTS = getConstants();

const NEW_ADJUSTMENT_ID = "new";

export default class ForecastProductDetails extends LightningElement {
    @api accountId;
    @api productId;
    @api disabled;
    @api price;
    @api direct;
    _volume;
    @api currencyCode ;
    isLoading = false;
    recalculateVolumes = false;

    step = 0;

    @api
    get volume() {
        return this._volume;
    }

    set volume(value) {
        this._volume = value;
        this.isLoading = true;
        this.recalculateVolumes = true;
        this.step = this._volume === 'cases' ? 0.0001 : 0;

        this.getForecast();

        this.setVolumeOnNewAdjustment(this.labels.direct);
        this.setVolumeOnNewAdjustment(this.labels.local);
    }

    setVolumeOnNewAdjustment(method){
        if(!this.methods[method].displayNewForm){
            return;
        }

        this.template.querySelectorAll(`[data-type="number"][data-id="${NEW_ADJUSTMENT_ID}"][data-method="${method}"]`).forEach((input) => {
            let uom = this.productWrapper.productInfo.uom
            let draftValue = this.methods.direct.draftAdjustments.get(NEW_ADJUSTMENT_ID).quantities.get(input.dataset.month);

            if(input.value){
                if(this._volume === 'cases') {
                    input.value = (draftValue / uom).toFixed(2);
                } else {
                    input.value = parseInt(draftValue * uom);
                }
                this.methods.direct.draftAdjustments.get(NEW_ADJUSTMENT_ID).quantities.set(input.dataset.month, input.value);
            }
        });
    }

    newAdjustmentId = NEW_ADJUSTMENT_ID;

    labels = {
        backButtonLabel: '> All Products',
        enableDirect: 'Enable Direct Shipment',
        enableLocal: 'Enable Local Warehouse',
        disableDirect: 'Disable Direct Shipment',
        disableLocal: 'Disable Local Warehouse',
        disableProduct: 'Disable Product',
        local: CONSTANTS.LOCAL_SHORT,
        direct: CONSTANTS.DIRECT_SHORT,
        data: CONSTANTS.DATA,
        action: CONSTANTS.ACTION,
        product: CONSTANTS.PRODUCT,
        fulfillment: CONSTANTS.FULFILLMENT,
        previousOrders: CONSTANTS.PREVIOUS_YEAR_ORDERS,
        currentOrders: CONSTANTS.CURRENT_YEAR_ORDERS,
        oppTotal: CONSTANTS.OPP_TOTAL,
        newAdj: CONSTANTS.NEW_ADJUSTMENT,
        adjTotal: CONSTANTS.ADJUSTMENT_TOTAL,
        forecastTotal: CONSTANTS.FORECAST_TOTAL,
        summary: CONSTANTS.SUMMARY,
        base: CONSTANTS.BASE,
        baseTotal: CONSTANTS.BASE_TOTAL,
        directShipment: CONSTANTS.DIRECT_SHIPMENT,
        localWarehouse: CONSTANTS.LOCAL_WAREHOUSE,
        approveOpp: "Approve Opportunity",
        rejectOpp: "Reject Opportunity",
        showRejected: "Show Rejected Opportunities",
        hideRejected: "Hide Rejected Opportunities",
        approved: "Approved",
        rejected: "Rejected",
    }

    editClass = 'input--edited';

    @track productWrapper;

    @track methods = {
        direct:{
            rowSpan: FULFILLMENT_DEFAULT_ROW_SPAN,
            displayNewForm: false,
            adjustments: [],
            adjustmentsInit: new Map(),
            draftAdjustments: new Map(),
            baseEditDisabled: true,
            base: [],
            baseInit: new Map(),
            baseDraft: new Map(),
            opportunities: [],
            displayRejected: false,
            rejectedOpps: 0,
            hasRejectedOpps: false,
            oppOptions: [],
        },
        local:{
            rowSpan: FULFILLMENT_DEFAULT_ROW_SPAN,
            displayNewForm: false,
            adjustments: [],
            adjustmentsInit: new Map(),
            draftAdjustments: new Map(),
            baseEditDisabled: true,
            base: [],
            baseInit: new Map(),
            baseDraft: new Map(),
            opportunities: [],
            displayRejected: false,
            rejectedOpps: 0,
            hasRejectedOpps: false,
            oppOptions: [],
        },
    }; 

    @api localWarehouseCodes = []; 
    
    selectedWarehouse;
    selectedWarehouselabel;
    /* Getters */

    get dataSet(){
        return this.productWrapper
    }

    get displayDirect(){
        return this.productWrapper?.directEnabled;
    }

    get displayLocal(){
        return this.productWrapper?.localEnabled;
    }

    get displaySummary(){
        return this.productWrapper?.directEnabled && this.productWrapper?.localEnabled;
    }

    getForecast(){
        getForecast({
            accountId: this.accountId,
            productId: this.productId,
            volume: this._volume,
            direct: this.direct
        })
        .then((result) => {
            this.productWrapper = this.setProductData(result);

            if(!this.productWrapper.directEnabled && !this.productWrapper.localEnabled){
                this.dispatchEvent(new CustomEvent('disabled'));
                showNotification('Success','Product has been disabled','success');
            }else{
                this.setBase(this.productWrapper.baseDirectMap, this.labels.direct);
                this.setBase(this.productWrapper.baseLocalMap, this.labels.local);

                this.methods.direct.adjustments = this.setAdjustments(this.productWrapper.directAdjustmentEntries, this.labels.direct);
                this.methods.local.adjustments = this.setAdjustments(this.productWrapper.localAdjustmentEntries, this.labels.local);

                this.methods.direct.opportunities = this.setOpportunities(this.productWrapper.directOppsEntries, this.labels.direct);
                this.methods.local.opportunities = this.setOpportunities(this.productWrapper.localOppsEntries, this.labels.local);

                this.setRowSpan(this.labels.direct);
                this.setRowSpan(this.labels.local);
                this.setWarehouse(result.warehouse);
            }
        })
        .catch((error) => {
                        // showError(error);
                        showError('An error occurred while processing your request. Please reach out to system admin to resolve this issue.');
                        console.log('error-->'+error);
        })
        .finally(() => {
            this.isLoading = false;
            this.recalculateVolumes = false;
        });
    }

    setProductData(wrapper){
        return {
            productInfo: wrapper.productInfo,
            directEnabled: wrapper.directEnabled,
            localEnabled: wrapper.localEnabled,
            dateRange: wrapper.dateRange,
            baseDirectMap: wrapper.baseDirectMap,
            baseLocalMap: wrapper.baseLocalMap,
            directAdjustmentEntries: wrapper.directAdjustmentEntries,
            localAdjustmentEntries: wrapper.localAdjustmentEntries,
            directOppsEntries: wrapper.directOppsEntries,
            localOppsEntries: wrapper.localOppsEntries,
            previousYearOrders: mapToArray(wrapper.previousYearOrdersMap),
            currentYearOrders: mapToArray(wrapper.currentYearOrdersMap),
            opportunitiesTotalDirect: mapToArray(wrapper.opportunitiesTotalDirectMap),
            adjustmentsTotalDirect: mapToArray(wrapper.adjustmentsTotalDirectMap),
            forecastTotalDirect: mapToArray(wrapper.forecastTotalDirectMap),
            opportunitiesTotalLocal: mapToArray(wrapper.opportunitiesTotalLocalMap),
            adjustmentsTotalLocal: mapToArray(wrapper.adjustmentsTotalLocalMap),
            forecastTotalLocal: mapToArray(wrapper.forecastTotalLocalMap),
            baseSummary: mapToArray(wrapper.baseSummaryMap),
            opportunitiesSummary: mapToArray(wrapper.opportunitiesSummaryMap),
            adjustmentsSummary: mapToArray(wrapper.adjustmentsSummaryMap),
            forecastSummary: mapToArray(wrapper.forecastSummaryMap),
        }
    }

    setRowSpan(method){
        this.methods[method].rowSpan = FULFILLMENT_DEFAULT_ROW_SPAN + 
            this.methods[method].adjustments.length + this.methods[method].opportunities.length + this.methods[method].draftAdjustments.size;

        if(this.methods[method].displayNewForm){
            this.methods[method].rowSpan =  this.methods[method].rowSpan + 1;
        }

        if(!this.methods[method].displayRejected){
            this.methods[method].rowSpan = this.methods[method].rowSpan - this.methods[method].rejectedOpps;
        }
    }

    setWarehouse(warehouse){
        if(!warehouse){
            return;
        }

       /* if(!warehouse.active){
            this.localWarehouseCodes = [...this.localWarehouseCodes, {
                label: warehouse.label,
                value: warehouse.value
            }];
        }*/

        this.selectedWarehouse = warehouse.value;
        this.selectedWarehouselabel = warehouse.label;
        console.log('this.selectedWarehouse-->'+this.selectedWarehouse)
    }

    /* Event Handlers */

    backToList(){
        this.dispatchEvent(new CustomEvent('back'));
    }

    /* Input Handlers */

    handlePriceChange(event){
        this.price = event.detail.value;
    }
    updatePrice(){
        this.isLoading = true;

        updatePriceFP({
            accountId: this.accountId,
            productId: this.productId,
            price: this.price,
        })
        .then(() => {
            showNotification('Success','Price has been updated','success');
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

    handleWarehouseSelect(event){
        this.selectedWarehouse = event.target.value;
        console.log('this.selectedWarehouse '+this.selectedWarehouse );
        this.isLoading = true;
        console.log('productId-->'+this.productId)
        updateWarehouse({
            accountId: this.accountId,
            productId: this.productId,
            warehouseId: this.selectedWarehouse === '-' ? '' : this.selectedWarehouse,
            direct: this.direct
        })
        .then(() => {
            showNotification('Success','Local Warehouse has been updated','success');
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

    /* Button Methods */

    enableFulfillment(event){
        this.isLoading = true;
        let method = event.currentTarget.dataset.method

        setFulfillmentMethod({
            accountId: this.accountId,
            productId: this.productId,
            method: method,
            value: true,
        })
        .then(() => {
            this.getForecast();
            showNotification('Success','Fulfillment method has been enabled','success');
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

    disableFulfillment(event){
        this.isLoading = true;
        let method = event.currentTarget.dataset.method

        setFulfillmentMethod({
            accountId: this.accountId,
            productId: this.productId,
            method: method,
            value: false,
        })
        .then(() => {
            this.getForecast();
            showNotification('Success','Fulfillment method has been disabled','success');
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

    disableProduct(event){
        this.isLoading = true;

        disableProduct({
            accountId: this.accountId,
            productId: this.productId,
            direct : this.direct
        })
        .then(() => {
            this.dispatchEvent(new CustomEvent('disabled'));
            showNotification('Success','Product has been disabled','success');
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

    /* Adjustments */

    setAdjustments(adjustments, method){
        return adjustments.map(wrapper => {
            let initMap = new Map();
            let entries = [];
            let hasDraft = this.methods[method].draftAdjustments.has(wrapper.recordId);
            let uom = this.productWrapper.productInfo.uom;

            for (let key in wrapper.forecastNumbers) {
                let value = wrapper.forecastNumbers[key];
                initMap.set(key, value);

                if(hasDraft){
                    let draftValue = this.methods[method].draftAdjustments.get(wrapper.recordId).quantities.get(key);

                    if(draftValue){
                        if(this.recalculateVolumes){
                            if(this._volume === 'cases') {
                                draftValue = (draftValue / uom).toFixed(2);
                            } else {
                                draftValue = parseInt(draftValue * uom);
                            }
                        }
                        value = draftValue;
                        this.methods[method].draftAdjustments.get(wrapper.recordId).quantities.set(key, value);
                    }
                }

                entries.push({ 
                    month: key, 
                    value: value,
                });
            }

            this.methods[method].adjustmentsInit.set(wrapper.recordId, {
                comment: wrapper.comment,
                name: wrapper.name,
                quantities: initMap,
            });

            let tooltipComment = wrapper.comment ?  wrapper.comment : '-';
            let tooltipOpportunityText = wrapper.opportunityForecastId ? wrapper.opportunityName : '-';

            let rowSpan = 1;
            let editDisabled = true;

            if(hasDraft){
                rowSpan = 2;
                editDisabled = false;
            }

            return {
                recordId: wrapper.recordId,
                name: wrapper.name,
                comment: wrapper.comment,
                opportunity: wrapper.opportunityForecastId,
                tooltipComment: `
                        <p><b>Comment</b>: </p>
                        <p>${tooltipComment}</p>
                        <p><b>Opportunity</b>: </p>
                        <p>${tooltipOpportunityText}</p>
                        `,
                entries: entries,
                editDisabled: editDisabled,
                rowSpan: rowSpan, 
            }
        })
    }

    adjustmentDeactivate(event){
        this.isLoading = true;
        let adjustmentId = event.currentTarget.dataset.id;

        deactivateAdjustment({
            adjustmentId: adjustmentId,
        })
        .then(() => {
            showNotification('Success','Adjustment has been removed','success');
            this.getForecast();
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

    adjustmentNewForm(event){
        let adjustmentId = event.currentTarget.dataset.id;
        let method = event.currentTarget.dataset.method;
        
        this.methods[method].displayNewForm = true;
        this.methods[method].rowSpan = this.methods[method].rowSpan + 2;

        this.methods[method].draftAdjustments.set(adjustmentId, {
            comment: '',
            name: '',
            quantities: new Map(),
        })
    }

    adjustmentClearHandle(event){
        let method = event.currentTarget.dataset.method;
        let adjustmentId = event.currentTarget.dataset.id;
        this.adjustmentClear(method, adjustmentId, true);
    }

    /* refreshOriginalValues - to avoid showing init values before data is saved to database */
    adjustmentClear(method, adjustmentId, refreshOriginalValues){
        if(adjustmentId !== this.newAdjustmentId){
            this.methods[method].adjustments.forEach(function(item, index) {
                if(item.recordId === adjustmentId){
                    item.editDisabled = true;
                    item.rowSpan = 1;
                }
            });
            
            this.methods[method].rowSpan = this.methods[method].rowSpan - 1;

            if(refreshOriginalValues){
                let adjustmentsInit = this.methods[method].adjustmentsInit.get(adjustmentId);

                this.template.querySelectorAll(`[data-type="number"][data-method="${method}"][data-id="${adjustmentId}"]`).forEach((input) => {
                    input.value = adjustmentsInit.quantities.get(input.dataset.month);
                });
            }
        }else{
            this.methods[method].displayNewForm = false;
            this.methods[method].rowSpan = this.methods[method].rowSpan - 2;
        }

        this.methods[method].draftAdjustments.delete(adjustmentId)

        this.template.querySelectorAll(`[data-method="${method}"][data-id="${adjustmentId}"]`).forEach((input) => {
            input.classList.remove(this.editClass);
        });   
    }

    adjustmentNameChange(event){
        let adjustmentId = event.currentTarget.dataset.id;
        let method = event.currentTarget.dataset.method;

        this.methods[method].draftAdjustments.get(adjustmentId).name = event.detail.value;

        let input = this.template.querySelector(`[data-type="name"][data-method="${method}"][data-id="${adjustmentId}"]`);
        input.classList.add(this.editClass);
    }

    adjustmentOpportunityChange(event){
        let adjustmentId = event.currentTarget.dataset.id;
        let method = event.currentTarget.dataset.method;

        this.methods[method].draftAdjustments.get(adjustmentId).opportunity = event.detail.value;

        let input = this.template.querySelector(`[data-type="opportunity"][data-method="${method}"][data-id="${adjustmentId}"]`);
        input.classList.add(this.editClass);
    }

    adjustmentCommentChange(event){
        let adjustmentId = event.currentTarget.dataset.id;
        let method = event.currentTarget.dataset.method;

        this.methods[method].draftAdjustments.get(adjustmentId).comment = event.detail.value;

        let input = this.template.querySelector(`[data-type="comment"][data-method="${method}"][data-id="${adjustmentId}"]`);
        input.classList.add(this.editClass);
    }

    adjustmentQuantityChange(event){
        let adjustmentId = event.currentTarget.dataset.id;
        let method = event.currentTarget.dataset.method;
        let month = event.currentTarget.dataset.month;
        let quantity = event.detail.value;

        let input = this.template.querySelector(`[data-type="number"][data-method="${method}"][data-month="${month}"][data-id="${adjustmentId}"]`);
        input.classList.add(this.editClass);

        if(!quantity){
            quantity = 0;
        }

        this.methods[method].draftAdjustments.get(adjustmentId).quantities.set(month, quantity);
    }

    adjustmentSave(event){
        this.isLoading = true;

        let adjustmentId = event.currentTarget.dataset.id;
        let method = event.currentTarget.dataset.method;
        let adjustment = this.methods[method].draftAdjustments.get(adjustmentId);
        console.log('adjustmentId-->'+adjustmentId)
        console.log('method-->'+method)
        console.log('adjustment-->'+adjustment)
        let array = Array.from(adjustment.quantities, ([key, value]) => {
            return {
                externalId: key,
                quantity: value,
                fulfillment: method,
            };
        });

        upsertForecastAdjustments({
            accountId: this.accountId,
            productId: this.productId,
            adjustmentId: adjustmentId,
            opportunityId: adjustment.opportunity,
            name: adjustment.name,
            comment: adjustment.comment,
            forecastDataMap: JSON.stringify(array),
            volume: this._volume,
            uom: this.productWrapper.productInfo.uom,        
        })
        .then(() => {
            this.getForecast();
            this.adjustmentClear(method, adjustmentId, false);
            showNotification('Success','Adjustment has been added','success');
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

    adjustmentEdit(event){
        let adjustmentId = event.currentTarget.dataset.id;
        let method = event.currentTarget.dataset.method;
        let comment;
        let name;
        let opp;

        this.methods[method].adjustments.forEach(function(item, index) {
            if(item.recordId === adjustmentId){
                item.editDisabled = false;
                item.rowSpan = 2;
                name = item.name;
                comment = item.comment;
                opp = item.opportunity;
            }
        });
        this.methods[method].rowSpan = this.methods[method].rowSpan + 1  

        this.methods[method].draftAdjustments.set(adjustmentId, {
            comment: comment,
            opportunity: opp,
            name: name,
            quantities: new Map(),
        })
    }

    /* Base */

    setBase(base, method){
        this.methods[method].base = [];
        let uom = this.productWrapper.productInfo.uom;

        for (let key in base) {
            let value = base[key];
            let draft = this.methods[method].baseDraft.get(key);
            this.methods[method].baseInit.set(key, value);

            if(draft){
                if(this.recalculateVolumes){
                    if(this._volume === 'cases') {
                        draft = (draft / uom).toFixed(2);
                    } else {
                        draft = parseInt(draft * uom);
                    }
                }
                value = draft;
                this.methods[method].baseDraft.set(key, draft);
            }

            this.methods[method].base.push({ 
                month: key, 
                value: value,
            });
        }
    }

    baseEdit(event){
        let method = event.currentTarget.dataset.method;
        this.methods[method].baseEditDisabled = false;
    }

    baseChange(event){
        let method = event.currentTarget.dataset.method;
        let month = event.currentTarget.dataset.month;
        let quantity = event.detail.value;

        let input = this.template.querySelector(`[data-type="base"][data-method="${method}"][data-month="${month}"]`);
        input.classList.add(this.editClass);

        if(!quantity){
            quantity = 0;
        }

        this.methods[method].baseDraft.set(month, quantity);
    }

    baseClearHandle(event){
        this.baseClear(event.currentTarget.dataset.method, true)
    }

    /* refreshOriginalValues - to avoid showing init values before data is saved to database */
    baseClear(method, refreshOriginalValues){
        this.methods[method].baseDraft.clear();
        this.methods[method].baseEditDisabled = true;

        this.template.querySelectorAll(`[data-type="base"][data-method="${method}"]`).forEach((input) => {
            input.classList.remove(this.editClass);
            if(refreshOriginalValues){  
                input.value = this.methods[method].baseInit.get(input.dataset.month)
            }
        });
    }

    baseSave(event){
        let method = event.currentTarget.dataset.method;

        this.isLoading = true;

        let array = Array.from(this.methods[method].baseDraft, ([key, value]) => {
            return {
                externalId: key,
                quantity: value,
                fulfillment: method,
            };
        });

        upsertBaseForecast({
            accountId: this.accountId,
            productId: this.productId,
            baseForecastMap: JSON.stringify(array),
            volume: this._volume,
            uom: this.productWrapper.productInfo.uom,
            direct : this.direct
        })
        .then(() => {
            this.getForecast();
            this.baseClear(method, false);
            showNotification('Success',"Base forecast has been updated",'success');
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

    /* Opportunities */

    setOpportunities(opportunities, method){
        this.methods[method].oppOptions = [];

        this.methods[method].oppOptions.push({ 
            label: '--None--', 
            value: '-',
        });

        this.methods[method].rejectedOpps = 0;
        this.methods[method].hasRejectedOpps = false;

        return opportunities.map(wrapper => {
            let display = true;
            let rowColor = 'row--orange';
        
            if(wrapper.approved){
                this.methods[method].oppOptions.push({ 
                    label: wrapper.name, 
                    value: wrapper.recordId, 
                });
                rowColor = 'row--green';
            }

            if(wrapper.rejected){
               this.methods[method].rejectedOpps = this.methods[method].rejectedOpps + 1;
               this.methods[method].hasRejectedOpps = true;

               if(!this.methods[method].displayRejected){
                    display = false;
               }
               rowColor = 'row--red';
            }

            let tooltipComment = wrapper.comment ?  wrapper.comment : '-';
            return {
                recordId: wrapper.recordId,
                name: wrapper.name,
                comment: wrapper.comment,
                display: display,
                rejected: wrapper.rejected,
                displayApproveButton: wrapper.pending || wrapper.rejected,
                displayRejectButton: wrapper.pending || wrapper.approved,
                tooltipComment: `
                        <p><b>Comment</b>: </p>
                        <p>${tooltipComment}</p>
                        <p><b>Approval</b>: </p>
                        <p>${wrapper.buApproval}</p>
                        `,
                entries: Object.keys(wrapper.forecastNumbers).map(function (key) {
                    return {
                        month: key,
                        value: wrapper.forecastNumbers[key],
                    }
                }),
                rowColor: rowColor,
                link: `/${ wrapper.opportunityId}`,
            }
        })
    }

    opportunityApproval(event){
        let approval = event.currentTarget.dataset.approval;
        let oppForecastId = event.currentTarget.dataset.id;

        this.isLoading = true;

        forecastOpportunityApproval({
            oppForecastId: oppForecastId,
            approvalStatus: approval,
        })
        .then(() => {
            this.getForecast();
            showNotification('Success',`Opportunity has been ${approval}`,'success');
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

    oppShowRejected(event){
        let method = event.currentTarget.dataset.method;

        this.methods[method].displayRejected = true;
        this.methods[method].opportunities.forEach(function(item, index) {
            if(!item.display){
                item.display = true;
            }
        });

        this.setRowSpan(method);
    }

    oppHideRejected(event){
        let method = event.currentTarget.dataset.method;

        this.methods[method].displayRejected = false;
        this.methods[method].opportunities.forEach(function(item, index) {
            if(item.display && item.rejected){
                item.display = false;
            }
        });

        this.setRowSpan(method);
    }


 
}