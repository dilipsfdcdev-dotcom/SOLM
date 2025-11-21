import { LightningElement, api, wire, track} from 'lwc';
import LightningConfirm from "lightning/confirm";
import {showError, showNotification} from 'c/utilNotification';
import {volumeOptions} from 'c/forecastUtils';

import search from '@salesforce/apex/CustomLookupAccountCtrl.search';
import enableForecast from '@salesforce/apex/ForecastCtrl.enableForecast';
import disableForecast from '@salesforce/apex/ForecastCtrl.disableForecast';
import checkForecast from '@salesforce/apex/ForecastCtrl.checkForecast';
import insertProduct from '@salesforce/apex/ForecastCtrl.insertProduct';
import deleteForecastData from '@salesforce/apex/ForecastCtrl.deleteForecasting';
import DISABLE_FORECASTING_CONFIRMATION from '@salesforce/label/c.Disable_Forecasting_Confirmation';
import getCurrencyCode from '@salesforce/apex/ForecastCtrl.getCurrencyCode';
import hasManagePermission from '@salesforce/customPermission/Forecasting_Manage';

import { CurrentPageReference } from 'lightning/navigation';



export default class ForecastApp extends LightningElement {
    @track data;
    @track showLoadingSpinner = false;
    MAX_FILE_SIZE = 2000000; //Max file size 2.0 MB
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
        accountSelect : 'Select Account to access Forecasting.',
        disableForecast: DISABLE_FORECASTING_CONFIRMATION,
        forecastEnable : 'Forecasting is not enabled for selected Account.',
        forecastNoData : 'Forecasting is not enabled for any of Product.',
        volumeSelectLabel : 'Display/input volumes in:',
        searchProductLabel: 'Product:',
        searchProductPlaceHolder: 'Search...',
    }

    initialSelection;

    selectedVolume = 'pieces';
    pageNumber = 1;

    openModal = false;
    currencyCODE;

    getCurrencyCode(accId){
        getCurrencyCode({
            accountId: accId
        }).then((result) => {
            this.currencyCODE = result;
            console.log('currencyISO CODE-->'+JSON.stringify(result))
        })
        .catch((error) => {
           // showError(error);
            showError('An error occurred while processing your request. Please reach out to system admin to resolve this issue.');
            console.log('error-->'+JSON.stringify(error));
        });
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if(currentPageReference?.state?.c__recordId){
            this.recordId = currentPageReference.state?.c__recordId;
            this.checkForecast();

            this.initialSelection = {
                id : this.recordId,
                sObjectType: 'Account',
                icon: 'standard:account',
                title: currentPageReference.state?.c__name,
            }
        }
    }
    @track localWarehouseCodes = [];

    /* Getters */ 

    get isReadOnlyPermission(){
        return !hasManagePermission;
    }

    get volumeOptions() {
        return volumeOptions();
    }

    get displayDisableForecasting(){
        return this.recordId && this._forecastEnabled && !this.isLoading && !this.isReadOnlyPermission;
    }

    get displayVolumeFilter(){
        return this.recordId && this._forecastEnabled && !this._forecastNoData;
    }

    get displayProductSearch(){
        return this.recordId && this._forecastEnabled && !this.isLoading && !this.productId  && !this._forecastNoData;
    }

    get displayAddProduct(){
        return this.recordId && this._forecastEnabled && !this._forecastNoData;
    }

    get displayHisttoricalForecast(){
        return this.recordId && this._forecastEnabled && !this._forecastNoData;
    }

    get displayNoAccountSelection(){
        return !this.recordId;
    }

    get displayNoForecastEnabled(){
        return this.recordId && !this._forecastEnabled && !this.isLoading;
    }

    get displayNoForecastData(){
        return this._forecastNoData && this.recordId && !this.isLoading;
    }

    get displayProductList(){
        return this.recordId && this._forecastEnabled && !this.isLoading && !this.productId  && !this._forecastNoData;
    }

    get displayProductDetails(){
        return this.recordId && this.productId && !this.isLoading;
    }

    async deleteAllProducts() {
        const result = await LightningConfirm.open({
            message: "Are you sure you want to permanently delete all forecast data for this account?",
            variant: "default", // headerless
            label: "Confirmation"
        });

        //Confirm has been closed

        //result is true if OK was clicked
        if (result) {
            this.isLoading = true;
            this.deleteForecastData();
        } else {

        }
    }

    /* Apex Functions */

    deleteForecastData(){
        deleteForecastData({
            accountId: this.recordId
        }).then((result) => {
            this._forecastNoData = true;
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

    checkForecast(){
        this.isLoading = true;

        checkForecast({
            accountId: this.recordId
        })
        .then((result) => {
            this.localWarehouseCodes = result.availableWarehouses;

            if(result.enabled){
                this._forecastEnabled = true;

                if(result.forecastedProducts > 0){
                    this._forecastNoData = false;
                }else{
                    this._forecastNoData = true;
                }
            }else{
                this._forecastEnabled = false;
                this._forecastNoData = false;
            }
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

    disableForecasting() {
        this.openModal = true;
    }

    enableForecasting() {
        this.isLoading = true;
        enableForecast({
                accountId: this.recordId
            })
            .then(() => {
                showNotification('Success',"Forecasting Enabled",'success');
                this._forecastEnabled = true;
                this.checkForecast();
            })
            .catch((error) => {
           // showError(error);
           showError('An error occurred while processing your request. Please reach out to system admin to resolve this issue.');
           console.log('error-->'+error);
                this.isLoading = false;
            })
    }

    handleCloseModal(event) {
        this.openModal = false;
    }

    handleDisableForecasting() {
        this.isLoading = true;
        disableForecast({
            accountId: this.recordId
        })
            .then(() => {
                showNotification('Success',"Forecasting Disabled",'success');
                this._forecastEnabled = false;
                this.checkForecast();
            })
            .catch((error) => {
           // showError(error);
           showError('An error occurred while processing your request. Please reach out to system admin to resolve this issue.');
           console.log('error-->'+error);
                this.isLoading = false;
            })
            .finally(() => {
                this.openModal = false;
            });
    }

    /* Input Handlers */
    errors = [];
    handleLookupSearch(event) {
        const lookupElement = event.target;
        search(event.detail)
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
        if(Object.keys(event.detail).length === 0){
            this.recordId = undefined;
            this.productId = undefined;
            this.pageNumber = 1;
            this.searchTerm = '';
        }else{
            this.recordId = event.detail[0];
            this.getCurrencyCode(this.recordId);
            this.checkForecast();
        }
    }

    handleVolumeChange(event){
        this.selectedVolume = event.detail.value;
    }

    /* Event Handlers */

    handleRefresh(){
        this.checkForecast();
    }

    handleBack(){
        this.productId = null;
    }

    handleDisabled(){
        this.productId = null;
        this.checkForecast();
    }

    handleProductSelect(event){
        this.productId = event.detail.product;
        this.price = event.detail.price;
        this.direct = event.detail.direct;
        console.log('this.direct',this.direct);
    }

    handlePageSelect(event){
        this.pageNumber = event.detail.page;
    }

    doneTypingInterval = 300;
    typingTimer;
    searchTerm;

    handleProductSearch(event){
        clearTimeout(this.typingTimer);

        let value = event.target.value;
        this.searchTerm = value;

        this.typingTimer = setTimeout(() => {
            this.template.querySelector('c-forecast-product-list').search();
        }, this.doneTypingInterval);
    }
 
    importcsv(event){
        if (event.target.files.length > 0) {
            this.filesUploaded = event.target.files;
            this.filename = event.target.files[0].name;
            console.log(this.filename);
            console.log(this.filesUploaded);
            if (this.filesUploaded.size > this.MAX_FILE_SIZE) {
                this.filename = 'File Size is to long to process';
            } 
    }
    }

    async handleFileImport() {
        const result = await LightningConfirm.open({
            message: "By uploading this file, you will update only the items included in the attachment. For any items not included in the attachment, the current forecast will remain unchanged. Do you want to continue?",
            variant: "default", // headerless
            label: "Confirmation"
        });

        //Confirm has been closed

        //result is true if OK was clicked
        if (result) {
            this.isLoading = true;
            this.readFiles();
        } else {

        }
    }


    readFiles() {
        console.log('inside read files');
        console.log(this.filesUploaded);
        [...this.filesUploaded].forEach(async file => {
                try {
                    console.log(file);
                    const result = await this.load(file);
                    // Process the CSV here
                  this.showLoadingSpinner = false;

                    console.log(result);
                   // this.processData(result);
                     this.data=this.csvJSON(result);
                     console.log(this.data);
                    console.log('data..'+JSON.parse(this.data));
                    insertProduct({
                        prodJson: this.data,
                        accountId : this.recordId
                    })
                    .then((result) => {
                       if(result=='Success'){
                           this._forecastEnabled = true;
                           this.checkForecast();
                           //this.template.querySelector("c-forecast-product-list").search();
                       }
                       else {
                            // showError(result);
                            showError('An error occurred while processing your request. Please reach out to system admin to resolve this issue.');
                            console.log('error-->'+result);
                       }
                    })
                    .catch((error) => {
                        // showError(error);
                        showError('An error occurred while processing your request. Please reach out to system admin to resolve this issue.');
                        console.log('error-->'+error);
                        this.isLoading = false;
                    })

                } catch(e) {
                    // handle file load exception
                    console.log('exception....',e);
                }
            });
    }
    async load(file) {
        return new Promise((resolve, reject) => {
        this.showLoadingSpinner = true;
            const reader = new FileReader();
            // Read file into memory as UTF-8      
            //reader.readAsText(file);
            reader.onload = function() {
                resolve(reader.result);
            };
            reader.onerror = function() {
                reject(reader.error);
            };
            reader.readAsText(file);
        });
    }

     
//process CSV input to JSON
 
    csvJSON(csv){

        var lines=csv.split(/\r\n|\n/);

        var result = [];

        var headers=lines[0].split(",");
        console.log('headers..'+JSON.stringify(headers));
        for(var i=1;i<lines.length-1;i++){

        var obj = {};
        var currentline=lines[i].split(",");

        for(var j=0;j<headers.length;j++){
            obj[headers[j]] = currentline[j];
        }

        result.push(obj);

        }
        console.log('result..'+JSON.stringify(result));
        //return result; //JavaScript object
        return JSON.stringify(result); //JSON
    }
}