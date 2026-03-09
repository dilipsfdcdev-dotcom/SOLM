import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import getActiveTemplates from '@salesforce/apex/CustomEmailComposerController.getActiveTemplates';
import getFromAddressOptions from '@salesforce/apex/CustomEmailComposerController.getFromAddressOptions';
import loadTemplate from '@salesforce/apex/CustomEmailComposerController.loadTemplate';
import sendMail from '@salesforce/apex/CustomEmailComposerController.sendMail';

// Dynamic field reference for Form_Submission__c.Email__c
const FORM_SUBMISSION_EMAIL_FIELD = 'Form_Submission__c.Email__c';

export default class CustomEmailComposer extends LightningElement {
    @api recordId;        // automatically passed on record pages
    @api objectApiName;   // available if needed later

    @track templateOptions = [];
    @track selectedTemplateId;

    // From address options
    @track fromAddressOptions = [];
    @track selectedFromAddressId = '';

    // Multi-email support - arrays of email addresses
    @track toAddresses = [];
    @track ccAddresses = [];
    @track bccAddresses = [];

    // Current input values for each field
    @track toInputValue = '';
    @track ccInputValue = '';
    @track bccInputValue = '';

    @track subject = '';
    @track body = '';

    isLoading = false;
    showComposer = false;
    emailAutoPopulated = false;
    fromAddressesLoaded = false;

    // Wire to get Email__c field from Form_Submission__c
    @wire(getRecord, {
        recordId: '$recordId',
        fields: '$dynamicFields'
    })
    wiredRecord({ error, data }) {
        if (data && !this.emailAutoPopulated) {
            // Check if this is a Form_Submission__c record
            if (this.objectApiName === 'Form_Submission__c') {
                const emailValue = getFieldValue(data, FORM_SUBMISSION_EMAIL_FIELD);
                if (emailValue && this.isValidEmail(emailValue)) {
                    this.toAddresses = [emailValue];
                    this.emailAutoPopulated = true;
                }
            }
        }
        if (error) {
            // Silent fail - email field might not exist on this object
            console.log('Could not fetch Email__c field:', error);
        }
    }

    // Dynamically build fields array based on object type
    get dynamicFields() {
        if (this.objectApiName === 'Form_Submission__c') {
            return [FORM_SUBMISSION_EMAIL_FIELD];
        }
        return [];
    }

    connectedCallback() {
        this.loadTemplates();
    }

    get isLoadDisabled() {
        return !this.selectedTemplateId || this.isLoading;
    }

    get isSendDisabled() {
        return this.toAddresses.length === 0 || !this.subject || !this.body || this.isLoading;
    }

    // Check if there are any To addresses
    get hasToAddresses() {
        return this.toAddresses.length > 0;
    }

    get hasCcAddresses() {
        return this.ccAddresses.length > 0;
    }

    get hasBccAddresses() {
        return this.bccAddresses.length > 0;
    }

    // Check if from address options are available
    get hasFromAddressOptions() {
        return this.fromAddressOptions.length > 0;
    }

    // Email validation helper
    isValidEmail(email) {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return emailRegex.test(email);
    }

    // Load all templates (Solcotton folder only via Apex)
    loadTemplates() {
        this.isLoading = true;
        getActiveTemplates()
            .then(result => {
                this.templateOptions = result.map(tpl => ({
                    label: tpl.name,
                    value: tpl.id
                }));
            })
            .catch(error => {
                this.showToast('Error loading templates', this.reduceError(error), 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    // Load From address options (owner email + org-wide addresses)
    loadFromAddressOptions() {
        if (this.fromAddressesLoaded) {
            return;
        }

        getFromAddressOptions({ recordId: this.recordId })
            .then(result => {
                this.fromAddressOptions = result.map(opt => ({
                    label: opt.displayName,
                    value: opt.id,
                    email: opt.email,
                    type: opt.type
                }));

                // Auto-select the first option (usually owner) if available
                if (this.fromAddressOptions.length > 0 && !this.selectedFromAddressId) {
                    this.selectedFromAddressId = this.fromAddressOptions[0].value;
                }

                this.fromAddressesLoaded = true;
            })
            .catch(error => {
                console.log('Could not load from address options:', error);
                // Silent fail - from addresses are optional
            });
    }

    /* UI handlers */

    handleOpenComposer() {
        this.showComposer = true;
        // Load from address options when composer opens
        this.loadFromAddressOptions();
    }

    handleCloseComposer() {
        this.showComposer = false;
        this.handleClear();
    }

    handleTemplateChange(event) {
        this.selectedTemplateId = event.detail.value;
    }

    handleFromAddressChange(event) {
        this.selectedFromAddressId = event.detail.value;
    }

    // To field handlers
    handleToInputChange(event) {
        this.toInputValue = event.target.value;
    }

    handleToKeyDown(event) {
        if (event.key === 'Enter' || event.key === 'Tab' || event.key === ',') {
            event.preventDefault();
            this.addToAddress();
        } else if (event.key === 'Backspace' && !this.toInputValue && this.toAddresses.length > 0) {
            // Remove last email on backspace if input is empty
            this.toAddresses = this.toAddresses.slice(0, -1);
        }
    }

    handleToBlur() {
        this.addToAddress();
    }

    addToAddress() {
        const email = this.toInputValue.trim().replace(/,/g, '');
        if (email && this.isValidEmail(email)) {
            if (!this.toAddresses.includes(email)) {
                this.toAddresses = [...this.toAddresses, email];
            }
            this.toInputValue = '';
        } else if (email) {
            this.showToast('Invalid Email', `"${email}" is not a valid email address.`, 'warning');
        }
    }

    handleRemoveToAddress(event) {
        const emailToRemove = event.currentTarget.dataset.email;
        this.toAddresses = this.toAddresses.filter(email => email !== emailToRemove);
    }

    // CC field handlers
    handleCcInputChange(event) {
        this.ccInputValue = event.target.value;
    }

    handleCcKeyDown(event) {
        if (event.key === 'Enter' || event.key === 'Tab' || event.key === ',') {
            event.preventDefault();
            this.addCcAddress();
        } else if (event.key === 'Backspace' && !this.ccInputValue && this.ccAddresses.length > 0) {
            this.ccAddresses = this.ccAddresses.slice(0, -1);
        }
    }

    handleCcBlur() {
        this.addCcAddress();
    }

    addCcAddress() {
        const email = this.ccInputValue.trim().replace(/,/g, '');
        if (email && this.isValidEmail(email)) {
            if (!this.ccAddresses.includes(email)) {
                this.ccAddresses = [...this.ccAddresses, email];
            }
            this.ccInputValue = '';
        } else if (email) {
            this.showToast('Invalid Email', `"${email}" is not a valid email address.`, 'warning');
        }
    }

    handleRemoveCcAddress(event) {
        const emailToRemove = event.currentTarget.dataset.email;
        this.ccAddresses = this.ccAddresses.filter(email => email !== emailToRemove);
    }

    // BCC field handlers
    handleBccInputChange(event) {
        this.bccInputValue = event.target.value;
    }

    handleBccKeyDown(event) {
        if (event.key === 'Enter' || event.key === 'Tab' || event.key === ',') {
            event.preventDefault();
            this.addBccAddress();
        } else if (event.key === 'Backspace' && !this.bccInputValue && this.bccAddresses.length > 0) {
            this.bccAddresses = this.bccAddresses.slice(0, -1);
        }
    }

    handleBccBlur() {
        this.addBccAddress();
    }

    addBccAddress() {
        const email = this.bccInputValue.trim().replace(/,/g, '');
        if (email && this.isValidEmail(email)) {
            if (!this.bccAddresses.includes(email)) {
                this.bccAddresses = [...this.bccAddresses, email];
            }
            this.bccInputValue = '';
        } else if (email) {
            this.showToast('Invalid Email', `"${email}" is not a valid email address.`, 'warning');
        }
    }

    handleRemoveBccAddress(event) {
        const emailToRemove = event.currentTarget.dataset.email;
        this.bccAddresses = this.bccAddresses.filter(email => email !== emailToRemove);
    }

    handleSubjectChange(event) {
        this.subject = event.target.value;
    }

    handleBodyChange(event) {
        this.body = event.target.value;
    }

    handleClear() {
        // Only clear addresses if not auto-populated from Email__c
        if (!this.emailAutoPopulated) {
            this.toAddresses = [];
        } else {
            // Re-fetch the original email if it was auto-populated
            // Keep only the original email
        }
        this.ccAddresses = [];
        this.bccAddresses = [];
        this.toInputValue = '';
        this.ccInputValue = '';
        this.bccInputValue = '';
        this.subject = '';
        this.body = '';
        // Reset from address to first option
        if (this.fromAddressOptions.length > 0) {
            this.selectedFromAddressId = this.fromAddressOptions[0].value;
        }
    }

    // Call Apex to render template
    handleLoadTemplate() {
        if (!this.selectedTemplateId || !this.recordId) {
            this.showToast('Missing Info', 'Select a template and ensure recordId is available.', 'warning');
            return;
        }

        this.isLoading = true;
        loadTemplate({ templateId: this.selectedTemplateId, recordId: this.recordId })
            .then(res => {
                this.subject = res.subject || '';
                // Prefer HTML body; fallback to plain
                this.body = res.htmlBody || res.plainBody || '';
            })
            .catch(error => {
                this.showToast('Error loading template', this.reduceError(error), 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    // Call Apex to send email
    handleSend() {
        // Validate at least one To address
        if (this.toAddresses.length === 0) {
            this.showToast('Missing Recipient', 'Please add at least one email address in the To field.', 'warning');
            return;
        }

        this.isLoading = true;

        // Convert arrays to comma-separated strings for Apex
        const toAddressesStr = this.toAddresses.join(',');
        const ccAddressesStr = this.ccAddresses.join(',');
        const bccAddressesStr = this.bccAddresses.join(',');

        sendMail({
            toAddresses: toAddressesStr,
            ccAddresses: ccAddressesStr,
            bccAddresses: bccAddressesStr,
            subject: this.subject,
            htmlBody: this.body,
            recordId: this.recordId,
            fromAddressId: this.selectedFromAddressId || null
        })
            .then(() => {
                this.showToast('Success', 'Email sent successfully.', 'success');
                // Optionally close composer after send
                this.handleCloseComposer();
            })
            .catch(error => {
                this.showToast('Error sending email', this.reduceError(error), 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    /* Helpers */

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }

    reduceError(error) {
        if (Array.isArray(error?.body)) {
            return error.body.map(e => e.message).join(', ');
        } else if (error?.body?.message) {
            return error.body.message;
        }
        return error?.message || 'Unknown error';
    }
}