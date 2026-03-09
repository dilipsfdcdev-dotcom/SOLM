import { LightningElement, api, wire } from 'lwc';
import getVoiceCalls from '@salesforce/apex/VoiceCallController.getVoiceCalls';
import { NavigationMixin } from 'lightning/navigation';
import { getFocusedTabInfo, openSubtab } from 'lightning/platformWorkspaceApi';

export default class RelatedVoiceCalls extends NavigationMixin(LightningElement) {
    @api recordId;
    voiceCalls;
    error;
    isLoading = true;

    columns = [
        {
            label: 'Name',
            type: 'button',
            typeAttributes: {
                label: { fieldName: 'Name' },
                name: 'openRecord',
                variant: 'base'
            },
            cellAttributes: { class: 'min-width' }
        },
        { label: 'Case', fieldName: 'Case__c' },
        { label: 'Contact', fieldName: 'Contact__c' },
        { label: 'Call Category', fieldName: 'Call_Category__c' },
        { label: 'IVR Selection', fieldName: 'IVR_Selection__c' },
        { label: 'Call Origin', fieldName: 'CallOrigin' },
        { label: 'Queue Name', fieldName: 'QueueName' },
        { label: 'Call Type', fieldName: 'CallType' },
        { label: 'Duration (s)', fieldName: 'CallDurationInSeconds', type: 'number' },
        { label: 'Created Date', fieldName: 'CreatedDate', type: 'date' }
    ];

    @wire(getVoiceCalls, { recordId: '$recordId' })
    wiredCalls({ error, data }) {
        console.log('🔄 Fetching voice calls...');
        this.isLoading = true;

        if (data) {
            console.log('✅ Voice calls received:', data);
            this.voiceCalls = data;
            this.error = undefined;
        } else if (error) {
            console.error('❌ Error fetching voice calls:', error);
            this.error = error;
            this.voiceCalls = undefined;
        }

        this.isLoading = false;
    }

    get hasData() {
        return this.voiceCalls && this.voiceCalls.length > 0;
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        if (actionName === 'openRecord') {
            this.openVoiceCallInSubtab(row.Id, row.Name);
        }
    }

    async openVoiceCallInSubtab(recordId, name) {
        try {
            console.log('🔍 Attempting to open record:', recordId);

            const tabInfo = await getFocusedTabInfo();
            console.log('🧩 tabInfo:', JSON.stringify(tabInfo));

            let parentTabId = tabInfo?.isSubtab ? tabInfo?.parentTabId : tabInfo?.tabId;

            if (typeof parentTabId !== 'string') {
                console.error('❌ parentTabId is not a string:', parentTabId);
                throw new Error('Invalid parentTabId');
            }

            const pageRef = {
                type: 'standard__recordPage',
                attributes: {
                    recordId: recordId,
                    objectApiName: 'VoiceCall',
                    actionName: 'view'
                }
            };

            console.log('🚀 Opening subtab with parentTabId:', parentTabId);
            console.log('📄 Page Reference:', JSON.stringify(pageRef));

            await openSubtab({
                parentTabId: parentTabId,
                pageReference: pageRef,
                focus: true
            });

            console.log('✅ Subtab opened successfully for:', name);
        } catch (error) {
            console.error('❌ Failed to open subtab, falling back to navigation:', error);

            // Fallback if subtab fails
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: recordId,
                    objectApiName: 'VoiceCall',
                    actionName: 'view'
                }
            });
        }
    }
}