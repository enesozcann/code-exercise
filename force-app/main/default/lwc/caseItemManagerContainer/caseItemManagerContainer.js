import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';

/**
 * @description CaseItemManagerContainer
 * @Date 16 September 2025
 */
export default class CaseItemManagerContainer extends LightningElement {
    @api recordId;

    addModalOpen = false;
    itemsCount = 0;
    isSubmitting = false;

    @wire(CurrentPageReference)
    setStateFromUrl(stateRef) {
        if (!this.recordId && stateRef?.state?.c__recordId) {
            this.recordId = stateRef.state.c__recordId;
        }
    }
    // ui helpers
    get disableSubmit() {
        return this.isSubmitting || !this.recordId || this.itemsCount === 0;
    }
    get itemsBadge() {
        return `Items: ${this.itemsCount}`;
    }
    // modal handlers
    handleOpenAddModal() { this.addModalOpen = true; }
    handleCloseAddModal() { this.addModalOpen = false; }
    handleAddItemConfirm() {
        this.addModalOpen = false;
        this.template.querySelector('c-case-item-table')?.refresh();
    }

    // get from table
    handleItemsCountChange(event) {
        this.itemsCount = Number(event.detail) || 0;
    }

    // submit Case: sets Case.Status = "Submit to Vendor"
    async handleSubmitCase() {
        if (this.disableSubmit) return;
        this.isSubmitting = true;
        try {
            const fields = { Id: this.recordId, Status: 'Submit to Vendor' };
            await updateRecord({ fields });
            getRecordNotifyChange([{ recordId: this.recordId }]);
            this.dispatchEvent(new ShowToastEvent({
                title: 'Submitted',
                message: 'Case status set to "Submit to Vendor".',
                variant: 'success'
            }));
        } catch (e) {
            const msg =
                (e?.body?.message) ||
                (Array.isArray(e?.body) ? e.body.map(x => x.message).join('; ') : null) ||
                e?.message || 'Unknown error';
            this.dispatchEvent(new ShowToastEvent({
                title: 'Submit failed',
                message: msg,
                variant: 'error'
            }));
        } finally {
            this.isSubmitting = false;
        }
    }
}
