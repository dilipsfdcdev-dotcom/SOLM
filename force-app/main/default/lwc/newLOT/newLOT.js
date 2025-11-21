import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import {CloseActionScreenEvent} from 'lightning/actions';
import {NavigationMixin} from 'lightning/navigation';
import {showError} from 'c/utilNotification';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

import OPP from '@salesforce/schema/Opportunity';
import ACCOUNT from "@salesforce/schema/Opportunity.AccountId";
import CLOSE_DATE from "@salesforce/schema/Opportunity.CloseDate";
import PRICEBOOK from "@salesforce/schema/Opportunity.Pricebook2Id";
import STAGE from "@salesforce/schema/Opportunity.StageName";
import PROBABILITY from "@salesforce/schema/Opportunity.Probability";
import CURRENCY from "@salesforce/schema/Opportunity.CurrencyIsoCode";
import NAME from "@salesforce/schema/Opportunity.Name";

const FIELDS = [ACCOUNT, CLOSE_DATE, PRICEBOOK, STAGE, PROBABILITY, CURRENCY, NAME];

import saveLOT from '@salesforce/apex/OpportunityNewLOTCtrl.saveLOT';

export default class NewLOT extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectInfo;
    @api recordTypeId;

	isLoading = false;
    parentOppName;

    @track form = {
		'sobjectType': 'Opportunity',
	};

    @wire(getObjectInfo, { objectApiName: OPP })
    objectInfo;

    get recordTypeId() {
        const recordTypes = this.objectInfo.data.recordTypeInfos;
        return Object.keys(recordTypes).find(recordType => recordTypes[recordType].name === 'EMEA Tender LOT');
    }

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (error) {
            showError(error)
        } else if (data) {
            this.form['AccountId'] = data.fields.AccountId.value;
            this.form['CloseDate'] = data.fields.CloseDate.value;
            this.form['Pricebook2Id'] = data.fields.Pricebook2Id.value;
            this.form['StageName'] = data.fields.StageName.value;
            this.form['Probability'] = data.fields.Probability.value;
            this.form['Opportunity__c'] = this.recordId;
            this.form['RecordTypeId'] = this.recordTypeId;
            this.form['CurrencyIsoCode'] = data.fields.CurrencyIsoCode.value;
            this.parentOppName = data.fields.Name.value;
        }
    }

    handleFieldChange(event) {
		this.form[event.target.fieldName] = event.detail.value;
	}

    handleSave(){
        const allValid = [
			...this.template.querySelectorAll('lightning-input-field'),
		].reduce((validSoFar, inputFields) => {
			return validSoFar && inputFields.reportValidity();
		}, true);

        if(!this.form['Pricebook2Id']){
            showError('Tender Opportunity must have selected Price Book before creating any LOT.');
        }else if(allValid){
            this.isLoading = true;
            this.form['Name'] = `${this.parentOppName}-${this.form['Name']}`;
            this.save();
        }
    }

    save(){
        saveLOT({
            lot: this.form,
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
				objectApiName: 'Opportunity',
				actionName: 'view'
			}
		});
    }

    handleCancel(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }

}