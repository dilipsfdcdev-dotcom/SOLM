import { LightningElement, api } from 'lwc';
import {NavigationMixin} from 'lightning/navigation';
import {showError} from 'c/utilNotification';

import generateOrder from '@salesforce/apex/QuoteToOrderCtrl.generateOrder';

export default class NewOrderFromQuote extends NavigationMixin(LightningElement)  {
    @api recordId;
    isLoading = false;

    generateOrder(){
        this.isLoading = true;
        generateOrder({
            quoteId: this.recordId,
        })
        .then((result) => {
            this.navigateToOrderPageRecord(result);
        })
        .catch((error) => {
            showError(error);
        })
        .finally(() => {
            this.isLoading = false;
        });
    }

    navigateToOrderPageRecord(orderId){
        this[NavigationMixin.Navigate]({
			type: 'standard__recordPage',
			attributes: {
				recordId: orderId,
				objectApiName: 'Order',
				actionName: 'view'
			}
		});
    }
}