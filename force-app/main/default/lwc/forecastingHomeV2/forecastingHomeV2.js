import { LightningElement } from 'lwc';

export default class ForecastingHomeV2 extends LightningElement {
    searchByAccount = false;
    searchByProduct = false;

    get showSelection() {
        return !this.searchByAccount && !this.searchByProduct;
    }

    handleSearchByAccount() {
        this.searchByAccount = true;
        this.searchByProduct = false;
    }

    handleSearchByProduct() {
        this.searchByProduct = true;
        this.searchByAccount = false;
    }
}
