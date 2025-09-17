import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

/**
 * @description AddItemModal
 * @Date 16 September 2025
 */
export default class AddItemModal extends LightningElement {
    @api recordId;
    @api open = false;

    handleCancel() {
        this.dispatchEvent(new CustomEvent('cancel'));
    }

    handleSubmit(event) {
        event.preventDefault();
        const fields = { ...event.detail.fields, Case__c: this.recordId };
        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }

    handleSuccess() {
        this.dispatchEvent(new ShowToastEvent({ title: 'Added', message: 'Item added', variant: 'success' }));
        this.dispatchEvent(new CustomEvent('confirm'));
    }

    handleError(e) {
        const message = e?.detail?.message || 'Unknown error';
        this.dispatchEvent(new ShowToastEvent({ title: 'Add failed', message, variant: 'error' }));
    }
}
