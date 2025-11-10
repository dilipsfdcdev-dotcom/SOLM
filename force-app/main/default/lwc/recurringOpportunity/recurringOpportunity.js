import {LightningElement, api} from 'lwc';
import {showError, showNotification} from 'c/utilNotification';
import {CloseActionScreenEvent} from 'lightning/actions';
import makeOpportunityRecurring from '@salesforce/apex/OpportunityRecurring.makeOpportunityRecurring';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';

export default class RecurringOpportunity extends LightningElement {
    @api recordId;
	isLoading = false;

    frequency = 'Monthly';
    endDate;

    get options() {
        return [{
                label: 'Weekly',
                value: 'Weekly'
            },
            {
                label: 'Monthly',
                value: 'Monthly'
            },
            {
                label: 'Yearly',
                value: 'Yearly'
            },
        ];
    }

    handleDateChange(event) {
		this.endDate= event.detail.value;
	}

    handleFrequencyChange(event) {
		this.frequency= event.detail.value;
	}

    handleCancel(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleSave(){
        const allValid = [
			...this.template.querySelectorAll('lightning-input'),
            ...this.template.querySelectorAll('lightning-radio-group'),
		].reduce((validSoFar, inputFields) => {
			return validSoFar && inputFields.reportValidity();
		}, true);

		if (allValid) {
            this.isLoading = true;
            this.save();
        }
    }

    save(){
        makeOpportunityRecurring({
            recordId: this.recordId,
            endDate: this.endDate,
            frequency: this.frequency,
        })
        .then(() => {
            showNotification('Success', 'Recurring Opportunities created.', 'success');
            this.dispatchEvent(new CloseActionScreenEvent());
            getRecordNotifyChange([{recordId: this.recordId}]);
        })
        .catch((error) => {
            showError(error);
        })
        .finally(() => {
            this.isLoading = false;
        });
    }
}