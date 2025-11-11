import { LightningElement, api } from 'lwc';

export default class ForecastProductDetailsV2 extends LightningElement {
    @api productId;
    @api disabled;
    @api price;
    @api direct;
    @api accountId;
    @api volume;
    @api localWarehouseCodes;
    @api currencyCode;

    handleBack(event) {
        this.dispatchEvent(new CustomEvent('back', { detail: event.detail }));
    }

    handleDisabled(event) {
        this.dispatchEvent(new CustomEvent('disabled', { detail: event.detail }));
    }
}
