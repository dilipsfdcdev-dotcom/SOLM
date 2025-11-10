// transferToContact.js
import { LightningElement, track } from 'lwc';
import searchContacts from '@salesforce/apex/VoiceContactTransferController.searchContacts';

export default class TransferToContact extends LightningElement {
    @track searchKey = '';
    @track results = [];
    @track isLoading = false;

    handleSearchKeyChange(event) {
        this.searchKey = event.target.value;
    }

    async handleSearch() {
        this.isLoading = true;
        try {
            const contacts = await searchContacts({ searchTerm: this.searchKey });
            this.results = contacts;
        } catch (error) {
            console.error('Error fetching contacts:', error);
        }
        this.isLoading = false;
    }

    handleTransfer(event) {
        const phone = event.target.dataset.phone;
        if (window?.amazon_connect?.cti && phone) {
            window.amazon_connect.cti.transferCall(phone);
            console.log('🔁 Transferring current call to: ', phone);
        } else {
            console.error('❌ Cannot transfer — CTI or phone missing');
        }
    }
}