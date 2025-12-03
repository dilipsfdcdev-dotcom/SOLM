import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getActiveTemplates from '@salesforce/apex/CustomEmailComposerController.getActiveTemplates';
import loadTemplate from '@salesforce/apex/CustomEmailComposerController.loadTemplate';
import sendMail from '@salesforce/apex/CustomEmailComposerController.sendMail';

export default class CustomEmailComposer extends LightningElement {
    @api recordId;        // automatically passed on record pages
    @api objectApiName;   // available if needed later

    @track templateOptions = [];
    @track selectedTemplateId;

    @track toAddress = '';
    @track ccAddress = '';
    @track bccAddress = '';
    @track subject = '';
    @track body = '';

    isLoading = false;
    showComposer = false;   // <--- controls "button only" vs full layout

    connectedCallback() {
        this.loadTemplates();
    }

    get isLoadDisabled() {
        return !this.selectedTemplateId || this.isLoading;
    }

    get isSendDisabled() {
        return !this.toAddress || !this.subject || !this.body || this.isLoading;
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

    /* UI handlers */

    handleOpenComposer() {
        this.showComposer = true;
    }

    handleCloseComposer() {
        this.showComposer = false;
        // Optional: clear everything on close
        this.handleClear();
    }

    handleTemplateChange(event) {
        this.selectedTemplateId = event.detail.value;
    }

    handleToChange(event) {
        this.toAddress = event.target.value;
    }

    handleCcChange(event) {
        this.ccAddress = event.target.value;
    }

    handleBccChange(event) {
        this.bccAddress = event.target.value;
    }

    handleSubjectChange(event) {
        this.subject = event.target.value;
    }

    handleBodyChange(event) {
        this.body = event.target.value;
    }

    handleClear() {
        this.subject = '';
        this.body = '';
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
        this.isLoading = true;

        sendMail({
            toAddress: this.toAddress,
            ccAddress: this.ccAddress,
            bccAddress: this.bccAddress,
            subject: this.subject,
            htmlBody: this.body,
            recordId: this.recordId
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