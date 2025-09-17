import { LightningElement, api, track, wire } from 'lwc';
import listCaseItems from '@salesforce/apex/CaseItemController.listCaseItems';
import { updateRecord, deleteRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

/**
 * @description CaseItemTable
 * @Date 16 September 2025
 */
export default class CaseItemTable extends LightningElement {
    @api recordId;
    @track rows = [];
    draftValues = [];
    selectedIds = new Set();
    isLoading = false;

    columns = [
        { label: 'Product Code', fieldName: 'productCode', type: 'text', cellAttributes: { alignment: 'left' } },
        { label: 'Product Name', fieldName: 'productName', type: 'text', cellAttributes: { alignment: 'left' } },
        { label: 'Quantity', fieldName: 'Quantity__c', type: 'number', editable: true }
    ];

    wiredResult;

    @wire(listCaseItems, { caseId: '$recordId' })
    wiredItems(result) {
        this.wiredResult = result;
        if (result.data) {
            this.rows = result.data.map(r => ({
                ...r,
                productName: r.Product__r?.Name || '',
                productCode: r.Product__r?.ProductCode || ''
            }));
            // change submit button status
            this.dispatchEvent(new CustomEvent('itemscountchange', {
                detail: this.rows.length,
                bubbles: true,
                composed: true
            }));
        } else if (result.error) {
            this.toast('Error loading items', this.err(result.error), 'error');
        }
    }

    @api async refresh() {
        this.isLoading = true;
        try {
            await refreshApex(this.wiredResult);
        } finally {
            this.isLoading = false;
        }
    }

    handleRowSelect(event) {
        const selected = event.detail.selectedRows || [];
        this.selectedIds = new Set(selected.map(r => r.Id));
    }

    get noSelection() {
        return this.selectedIds.size === 0;
    }

    async handleDelete() {
        if (this.selectedIds.size === 0) return;
        try {
            await Promise.all(Array.from(this.selectedIds).map(id => deleteRecord(id)));
            this.selectedIds.clear();
            this.toast('Deleted', 'Selected items deleted', 'success');
            await this.refresh(); // clear cache
        } catch (e) {
            this.toast('Delete failed', this.err(e), 'error');
        }
    }

    async handleSave(event) {
        const changes = event?.detail?.draftValues || this.draftValues;
        if (!changes || changes.length === 0) return;
        try {
            const records = changes.map(d => ({ fields: { Id: d.Id, Quantity__c: d.Quantity__c } }));
            await Promise.all(records.map(updateRecord));
            this.draftValues = [];
            this.toast('Saved', 'Items updated', 'success');
            await this.refresh(); // clear cache
        } catch (e) {
            this.toast('Save failed', this.err(e), 'error');
        }
    }

    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    err(error) {
        if (Array.isArray(error?.body)) return error.body.map(e => e?.message).filter(Boolean).join('; ');
        if (typeof error?.body?.message === 'string') return error.body.message;
        if (error?.body?.pageErrors?.length) return error.body.pageErrors.map(p => p.message).join('; ');
        if (typeof error?.message === 'string') return error.message;
        return 'Unknown error';
    }
}
