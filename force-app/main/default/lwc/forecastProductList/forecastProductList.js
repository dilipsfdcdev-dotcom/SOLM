import {LightningElement, api, track} from 'lwc';
import {getConstants, mapToArray} from 'c/forecastUtils';
import getForecast from '@salesforce/apex/ForecastCtrl.getForecast';
import getForecastByProduct from '@salesforce/apex/ForecastCtrl.getForecastByProduct';

const CONSTANTS = getConstants();

export default class ForecastProductList extends LightningElement {
    isLoading = false;

    @api searchTerm;
    @api searchByProduct;
    @api disabled;
    @api accountId;
    @api productId;
    _volume;

    @track products = [];
    @track dateRange = []

    @api
    get volume() {
        return this._volume;
    }

    set volume(value) {
        this._volume = value;
        this.isLoading = true;
        this.getForecast();
    }

    recordEnd = 0;
    recordStart = 0;
    @api pageNumber;
    totalRecords = 0;
    totalPages = 0;
    pageSize = 5;    
    isPrev = true;
    isNext = true;
    @api currencyCode ;
    labels = {
        local: CONSTANTS.LOCAL_SHORT,
        direct: CONSTANTS.DIRECT_SHORT,
        data: CONSTANTS.DATA,
        product: CONSTANTS.PRODUCT,
        previousOrders: CONSTANTS.PREVIOUS_YEAR_ORDERS,
        currentOrders: CONSTANTS.CURRENT_YEAR_ORDERS,
        oppTotal: CONSTANTS.OPP_TOTAL,
        adjTotal: CONSTANTS.ADJUSTMENT_TOTAL,
        forecastTotal: CONSTANTS.FORECAST_TOTAL,
        baseTotal: CONSTANTS.BASE_TOTAL,
        directShipment: CONSTANTS.DIRECT_SHIPMENT,
        localWarehouse: CONSTANTS.LOCAL_WAREHOUSE,
        searchNoData: "No product data found. Try using different search term.",
        forecastRevenue: "Forecast Revenue"
    }

    @api search() {
        this.isLoading = true;
        this.pageNumber = 1;
        this.getForecast();
    }

    displayDetails(event) {
        console.log('Direct-->',event.target.dataset.id);
        this.dispatchEvent(new CustomEvent("productselect", {
            detail: {
                product: event.target.value,
                price: event.target.name,
                direct: event.target.dataset.id,
                accountId :event.target.dataset.accountId,
            }
        }));
    }

    get detailsBtnLabel() {
        return this.disabled ? 'Details' : 'Edit/Details';
    }

    get dataSet() {
        return this.products.length > 0;
    }

    get searchNoData(){
        return this.products.length === 0 && this.dateRange.length > 0;
    }

    @api getForecast() {
        if (this.searchByProduct) {
            getForecastByProduct({
                productId: this.productId,
                volume: this._volume,
                searchTerm: this.searchTerm,
                pageSize: this.pageSize,
                pageNumber: this.pageNumber,
            })
            .then((result) => {
                this.dateRange = result.dateRange;
                this.products = this.setProducts(result.forecastProducts);
                this.accountId = result.accountId;
                this.recordEnd = result.recordEnd;
                this.totalRecords = result.totalRecords;
                this.recordStart = result.recordStart;
                this.totalPages = Math.ceil(result.totalRecords / this.pageSize);
                this.isNext = (this.pageNumber == this.totalPages || this.totalPages == 0);
                this.isPrev = (this.pageNumber == 1 || this.totalRecords < this.pageSize);
            })
            .catch((error) => {
                showError('An error occurred while processing your request. Please reach out to system admin to resolve this issue.');
                console.log('error-->'+error);
            })
            .finally(() => {
                this.isLoading = false;
            });
        } else {
            getForecast({
                accountId: this.accountId,
                volume: this._volume,
                searchTerm: this.searchTerm,
                pageSize: this.pageSize,
                pageNumber: this.pageNumber,
            })
            .then((result) => {
                this.dateRange = result.dateRange;
                this.products = this.setProducts(result.forecastProducts);
                this.recordEnd = result.recordEnd;
                this.totalRecords = result.totalRecords;
                this.recordStart = result.recordStart;
                this.totalPages = Math.ceil(result.totalRecords / this.pageSize);
                this.isNext = (this.pageNumber == this.totalPages || this.totalPages == 0);
                this.isPrev = (this.pageNumber == 1 || this.totalRecords < this.pageSize);
                console.log('products--->'+JSON.stringify(products))
            })
            .catch((error) => {
                showError('An error occurred while processing your request. Please reach out to system admin to resolve this issue.');
                console.log('error-->'+error);
            })
            .finally(() => {
                this.isLoading = false;
            });
        }
    }

    setProducts(products){
        return products.map(product => {
            let methodsInfo = 'Methods: ';
            let warehouseName = 'Warehouse ';
            if(product.directEnabled && product.localEnabled){
                methodsInfo += 'Both';
            }else if(product.directEnabled){
                methodsInfo += 'Direct';
                warehouseName +=  'Direct: '+ (product.warehouseNameDirect ? product.warehouseNameDirect : '-');
            }else if(product.localEnabled){
                methodsInfo += 'Local';
                warehouseName +=  'Local: '+ (product.warehouseNameLocal ? product.warehouseNameLocal : '-');
            }else{
                methodsInfo += '-';
            }

          // Step A: Convert forecastTotalMap into an array
            const forecastTotalArr = mapToArray(product.forecastTotalMap);
            console.log('forecastTotalArr --->', forecastTotalArr);

            // Step B: Parse the unitPrice as a number
            const rawUnitPrice = product.productInfo?.UnitPrice ?? 0;
            const unitPrice = Number(rawUnitPrice);
            console.log('unitPrice --->', unitPrice);

            // Step C: Map forecastTotalArr to forecastRevenueArr
            const forecastRevenueArr = forecastTotalArr.map(item => {
            console.log('\n-- Item in map:', item);

            // Remove commas (and potentially other characters) to ensure proper numeric parsing
            let numericValue = parseFloat(String(item.value).replace(/,/g, ''));
            if (isNaN(numericValue)) {
                numericValue = 0;
            }

            const finalValue = numericValue * unitPrice;
            console.log('-- numericValue:', numericValue, '| unitPrice:', unitPrice, '| finalValue:', finalValue);
            const finalValueRounded = Number(finalValue.toFixed(2));
            return {
                month: item.month,
                value: finalValueRounded
            };
            });

            console.log('\nforecastRevenueArr --->', forecastRevenueArr);

            console.log('\nforecastRevenueArr --->', JSON.stringify(forecastRevenueArr));
            
            console.log('forecastRevenueArr --->', forecastRevenueArr);
            return {
                productInfo: product.productInfo,
                localEnabled: product.localEnabled,
                directEnabled: product.directEnabled,
                methodsInfo: methodsInfo,
                warehouseName: warehouseName,
                previousYearOrders: mapToArray(product.previousYearOrdersMap),
                currentYearOrders: mapToArray(product.currentYearOrdersMap),
                baseTotal: mapToArray(product.baseTotalMap),
                opportunitiesTotal: mapToArray(product.opportunitiesTotalMap),
                adjustmentsTotal: mapToArray(product.adjustmentsTotalMap),
                forecastTotal: forecastTotalArr,
                forecastRevenue: forecastRevenueArr
            }
        })
    }

    handlePageNextAction(){
        this.isLoading = true;
        this.pageNumber += 1;

        this.dispatchEvent(new CustomEvent("currentpage", {
            detail: {
                page: this.pageNumber
            }
        }));

        this.getForecast();
    }

    handlePagePrevAction(){
        this.isLoading = true;
        this.pageNumber -= 1;

        this.dispatchEvent(new CustomEvent("currentpage", {
            detail: {
                page: this.pageNumber
            }
        }));

        this.getForecast();
    }
}