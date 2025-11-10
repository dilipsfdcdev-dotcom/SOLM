import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import {CloseActionScreenEvent} from 'lightning/actions';
import {NavigationMixin} from 'lightning/navigation';

import MAIN_ACCOUNT from "@salesforce/schema/Opportunity.AccountId";
import BUSINESS_PARTNER_ACCOUNT from "@salesforce/schema/Opportunity.Business_Partner__c";
import RECORD_TYPE_DEV_NAME from "@salesforce/schema/Opportunity.Record_Type__c";

import {showError} from 'c/utilNotification';
import saveQuote from '@salesforce/apex/OpportunityNewQuoteCtrl.saveQuote';
import getContactInfo from '@salesforce/apex/OpportunityNewQuoteCtrl.getContactInfo';

const FIELDS = [MAIN_ACCOUNT, BUSINESS_PARTNER_ACCOUNT, RECORD_TYPE_DEV_NAME];

export default class OppNewQuote extends NavigationMixin(LightningElement) {
    @api recordId;
	isLoading = false;

    contactId;
    email;
    phone;

    showEmeaSection = false;

    @track form = {
		'sobjectType': 'Quote',
	};

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (error) {
            showError(error)
        } else if (data) {

            this.form['Bill_To_Account__c'] = data.fields.AccountId.value;
            this.form['Ship_To_Account__c'] = data.fields.Business_Partner__c.value ? data.fields.Business_Partner__c.value : data.fields.AccountId.value;
            this.form['AccountId'] = data.fields.AccountId.value;

            if(data.fields.Record_Type__c.value.includes('EMEA')){
                this.showEmeaSection = true;
            }
        }
    }

    handleFieldChange(event) {
		this.form[event.target.fieldName] = event.detail.value;
	}

    handleLookupFieldChange(event) {
		this.form[event.target.fieldName] = event.detail.value[0];
	}

    handleContactChange(event){
        this.form[event.target.fieldName] = event.detail.value[0];

        if(event.detail.value[0]){
            this.isLoading = true;
            getContactInfo({
                contactId: event.detail.value[0],
            })
            .then((result) => {
                this.form['Email'] = result.Email;
                this.form['Phone'] = result.Phone;
            })
            .catch((error) => {
                showError(error);
            })
            .finally(() => {
                this.isLoading = false;
            });
        }else{
            this.form['Email'] = '';
            this.form['Phone'] = '';
        }
    }

    handleSave(){
        const allValid = [
			...this.template.querySelectorAll('lightning-input-field'),
		].reduce((validSoFar, inputFields) => {
			return validSoFar && inputFields.reportValidity();
		}, true);

		if (allValid) {
            this.isLoading = true;
            this.save();
        }
    }

    save(){
        saveQuote({
            opportunityId: this.recordId,
            form: this.form,
        })
        .then((result) => {
            this.navigateToQuotePageRecord(result);
        })
        .catch((error) => {
            showError(error);
        })
        .finally(() => {
            this.isLoading = false;
        });
    }

    navigateToQuotePageRecord(quoteId){
        this[NavigationMixin.Navigate]({
			type: 'standard__recordPage',
			attributes: {
				recordId: quoteId,
				objectApiName: 'Quote',
				actionName: 'view'
			}
		});
    }

    handleCancel(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}