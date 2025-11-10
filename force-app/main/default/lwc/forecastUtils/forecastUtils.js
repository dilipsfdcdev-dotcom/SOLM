export function fulfillmentOptions() {
    return [
        {
            label: 'Direct Shipment',
            value: 'directShipment'
        },
        {
            label: 'Local Warehouse',
            value: 'localWarehouse'
        },
    ];
}

export function volumeOptions() {
    return [
        { label: 'Pieces', value: 'pieces' },
        { label: 'Cases', value: 'cases' },
    ];
}

const getConstants = () =>{
    return {
        PRODUCT : 'Product',
        FULFILLMENT : 'Fulfillment',
        DATA: 'Data',
        ACTION: 'Action',
        PREVIOUS_YEAR_ORDERS: 'Last Year Orders',
        CURRENT_YEAR_ORDERS: 'Current Year Orders',
        OPP_TOTAL: 'Opportunities Total',
        NEW_ADJUSTMENT: 'New Adjustment',
        ADJUSTMENT_TOTAL: 'Adjustments Total',
        FORECAST_TOTAL: 'Forecast Total',
        SUMMARY: 'Summary',
        BASE: 'Base',
        BASE_TOTAL: 'Base Total',
        DIRECT_SHIPMENT: 'Direct Shipment',
        DIRECT_SHIPMENT_COMBOBOX_VALUE: 'directShipment',
        LOCAL_WAREHOUSE: 'Local Warehouse',
        LOCAL_WAREHOUSE_COMBOBOX_VALUE: 'localWarehouse',
        DIRECT_SHORT: 'direct',
        LOCAL_SHORT: 'local',
    }
 }

export { getConstants };

export function mapToArray(valuesMap){
    return Object.keys(valuesMap).map(function (key) {
        return {
            month: key,
            value: valuesMap[key].toLocaleString('en-US'),
        }
    })
}