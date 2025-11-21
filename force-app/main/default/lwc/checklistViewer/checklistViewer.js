import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getChecklistItems from '@salesforce/apex/ChecklistViewerController.getChecklistItems';
import getCompletedChecklistActions from '@salesforce/apex/ChecklistViewerController.getCompletedChecklistActions';
import createChecklistAction from '@salesforce/apex/ChecklistViewerController.createChecklistAction';

export default class ChecklistViewer extends LightningElement {
    @api recordId;
    @api objectApiName;
    @track checklistItems = [];
    isLoading = true;
    error;

    connectedCallback() {
        this.fetchChecklistData();
    }

    async fetchChecklistData() {
    this.isLoading = true;
    try {
        // Fetch checklist items and completed actions
        const [items, completedActions] = await Promise.all([
            getChecklistItems({ recordId: this.recordId, objectName: this.objectApiName }),
            getCompletedChecklistActions({ relatedRecordId: this.recordId }),
        ]);

        const completedItemIds = new Set(completedActions.map((action) => action.Checklist_Item__c));

        // Sort items by Order__c
        const sortedItems = [...items].sort((a, b) => a.Order__c - b.Order__c);

        // Track if the previous item is completed
        let previousCompleted = true;

        // Map through sorted items to calculate properties
        this.checklistItems = sortedItems.map((item) => {
            const isCompleted = completedItemIds.has(item.Id);

            // Current item is selectable if the previous item was completed
            const isSelectable = previousCompleted;

            // Update previousCompleted for the next iteration
            previousCompleted = isCompleted;

            return {
                ...item,
                isCompleted,
                isDisabled: !isSelectable || isCompleted, // Disable if not selectable or already completed
                rowClass: isCompleted ? 'checklist-item completed-row' : 'checklist-item',
            };
        });
    } catch (error) {
        console.error('Error in fetchChecklistData:', error);
        this.error = error?.body?.message || error?.message || 'An unexpected error occurred.';
    } finally {
        this.isLoading = false;
    }
}





    // Handle checkbox change
    handleCheckboxChange(event) {
        const itemId = event.target.dataset.id;

        // Find the checklist item
        const checklistItem = this.checklistItems.find((item) => item.Id === itemId);

        if (checklistItem && !checklistItem.isDisabled) {
            this.isLoading = true;
            createChecklistAction({
                checklistItemId: itemId,
                relatedRecordId: this.recordId,
                objectType: this.objectApiName,
            })
                .then(() => {
                    // Update the UI to mark the item as completed
                    checklistItem.isCompleted = true;
                    checklistItem.isDisabled = true;
                    checklistItem.rowClass = 'checklist-item completed-row';

                    // Update isDisabled for the next item in sequence
                    this.updateSelectableItems();

                    this.showToast(
                        'Success',
                        `Checklist Item "${checklistItem.Checklist__c}" marked as completed!`
                    );
                })
                .catch((error) => {
                    this.showToast('Error', `Failed to create checklist action: ${error.body.message}`, 'error');
                })
                .finally(() => {
                    this.isLoading = false;
                });
        }
    }

    // Update isDisabled for all items
    updateSelectableItems() {
        this.checklistItems = this.checklistItems.map((item, index, sortedItems) => {
            const isSelectable =
                index === 0 || sortedItems[index - 1].isCompleted; // First item or previous is completed
            return { ...item, isDisabled: !isSelectable || item.isCompleted };
        });
    }

    // Show toast message
    showToast(title, message, variant = 'success') {
        const event = new ShowToastEvent({ title, message, variant });
        this.dispatchEvent(event);
    }
}