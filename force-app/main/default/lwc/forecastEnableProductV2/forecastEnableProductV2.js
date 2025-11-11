import { LightningElement, api } from 'lwc';

export default class ForecastEnableProductV2 extends LightningElement {
    @api disabled;
    @api accountId;
    @api volume;
    @api localWarehouseCodes;
    @api currencyCode;

    handleRefresh(event) {
        this.dispatchEvent(new CustomEvent('refresh', { detail: event.detail }));
    }
}
