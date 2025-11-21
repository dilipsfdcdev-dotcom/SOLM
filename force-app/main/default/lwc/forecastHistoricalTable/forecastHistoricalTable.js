import { LightningElement, wire, api } from 'lwc';
import getHistoricalForecastByAccount from '@salesforce/apex/ForecastCtrl.getHistoricalForecastByAccount';
import getHistoricalForecastByProduct from '@salesforce/apex/ForecastCtrl.getHistoricalForecastByProduct';
import getForecastProduct from '@salesforce/apex/ForecastCtrl.getForecastProduct';

export default class ForecastHistoricalTable extends LightningElement {
    @api accountId;
    @api productId;
    data;
    forecastData;
    showTable = false;
    connectedCallback(){
        if (this.productId != null && this.productId){
            this.getHistoricalForecastByProduct();
        } else {
            this.getHistoricalForecastByAccount();
        }
        

    }

    getHistoricalForecastByAccount(){
        getHistoricalForecastByAccount({
            accountId: this.accountId
        }).then((result) => {
            console.log('result-->'+JSON.stringify(result))
            this.data = result;
            console.log('this.data.length-->'+this.data.length)
            console.log('this.data-->'+this.data)
            if(this.data.length > 0 || this.data != undefined) {
                this.showTable = true;
            } else {
                this.showTable = false;
            }
            
        })
        .catch((error) => {
           // showError(error);
            showError('An error occurred while processing your request. Please reach out to system admin to resolve this issue.');
            console.log('error-->'+error);
        })
        .finally(() => {
            this.getForecastProduct();
        });
    }

    getHistoricalForecastByProduct(){
        getHistoricalForecastByProduct({
            accountId: this.accountId,
            productId: this.productId
        }).then((result) => {
            console.log('result-->'+JSON.stringify(result))
            this.data = result;
            console.log('this.data.length-->'+this.data.length)
            console.log('this.data-->'+this.data)
            if(this.data.length > 0 || this.data != undefined) {
                this.showTable = true;
            } else {
                this.showTable = false;
            }
            
        })
        .catch((error) => {
           // showError(error);
            showError('An error occurred while processing your request. Please reach out to system admin to resolve this issue.');
            console.log('error-->'+error);
        })
        .finally(() => {
            this.getForecastProduct();
        });
    }

        getForecastProduct(){
            getForecastProduct({
                accountId: this.accountId
            }).then((result) => {
                console.log('forecastData-->'+JSON.stringify(result))
                this.forecastData = result;
               
            })
            .catch((error) => {
               // showError(error);
                showError('An error occurred while processing your request. Please reach out to system admin to resolve this issue.');
                console.log('error-->'+error);
            })
            .finally(() => {
                if(this.data && this.forecastData){
                    this.handleExitingForecast();
                }

                        
        //this.handleExitingForecast();
        console.log('this.data callback -->'+JSON.stringify(this.data))
            });
        }

        handleExitingForecast(){

        // Step 1: Create a mutable copy of 'data' if necessary
        let mutableData = JSON.parse(JSON.stringify(this.data));

        // Step 2: Iterate through 'mutableData' to find matches in 'forecastData'
        mutableData.forEach(dataItem => {
            // Check if 'forecastData' contains a matching 'ProductCode'
            const isAvailable = this.forecastData.some(forecastItem => 
                forecastItem.Product__r && dataItem.Product__r && 
                forecastItem.Product__r.ProductCode === dataItem.Product__r.ProductCode);

            // Step 3: Set 'IsAvailable' based on the match result
            dataItem.IsAvailable = isAvailable;
        });

        this.data = mutableData;

        // Debug: Check if the process is working as expected
        console.log('Updated Data:', mutableData);
        }
}