import { LightningElement } from 'lwc';

export default class ForecastingHome extends LightningElement {
    searchByAccount = false;
    searchByProduct = false;

    hanldeSearchByAccount(){
        this.searchByAccount = true;
        this.searchByProduct = false;
    }

    hanldeSearchByProduct(){
        this.searchByProduct = true;
        this.searchByAccount = false;
    }
}