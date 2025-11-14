/**
 * Forecast 2.0 Shared Utilities
 * Enhanced utilities with better error handling and additional helpers
 */

/**
 * Fulfillment method options
 */
export function fulfillmentOptions() {
    return [
        {
            label: 'Direct Shipment',
            value: 'directShipment'
        },
        {
            label: 'Local Warehouse',
            value: 'localWarehouse'
        }
    ];
}

/**
 * Volume unit options
 */
export function volumeOptions() {
    return [
        { label: 'Pieces', value: 'pieces' },
        { label: 'Cases', value: 'cases' }
    ];
}

/**
 * Get all label constants
 */
export const getConstants = () => {
    return {
        PRODUCT: 'Product',
        FULFILLMENT: 'Fulfillment',
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
        FORECAST_REVENUE: 'Forecast Revenue'
    };
};

/**
 * Convert map to array for display
 */
export function mapToArray(valuesMap) {
    if (!valuesMap || typeof valuesMap !== 'object') {
        return [];
    }
    return Object.keys(valuesMap).map(key => ({
        month: key,
        value: valuesMap[key].toLocaleString('en-US')
    }));
}

/**
 * Format currency value
 */
export function formatCurrency(value, currencyCode = 'USD') {
    if (value === null || value === undefined || isNaN(value)) {
        return '$0.00';
    }
    return new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: currencyCode,
        minimumFractionDigits: 2
    }).format(value);
}

/**
 * Format number with locale
 */
export function formatNumber(value) {
    if (value === null || value === undefined || isNaN(value)) {
        return '0';
    }
    return new Intl.NumberFormat('en-US').format(value);
}

/**
 * Parse CSV to JSON with validation
 */
export function parseCSV(csvContent, requiredColumns = []) {
    if (!csvContent || csvContent.trim() === '') {
        throw new Error('CSV content is empty');
    }

    const lines = csvContent.split('\n').filter(line => line.trim() !== '');

    if (lines.length < 2) {
        throw new Error('CSV must contain headers and at least one data row');
    }

    const headers = lines[0].split(',').map(h => h.trim());

    // Validate required columns
    for (const required of requiredColumns) {
        if (!headers.includes(required)) {
            throw new Error(`Missing required column: ${required}`);
        }
    }

    const result = [];
    const errors = [];

    for (let i = 1; i < lines.length; i++) {
        const line = lines[i].trim();
        if (!line) continue;

        const values = line.split(',').map(v => v.trim());

        if (values.length !== headers.length) {
            errors.push(`Row ${i + 1}: Column count mismatch (expected ${headers.length}, got ${values.length})`);
            continue;
        }

        const obj = {};
        headers.forEach((header, index) => {
            obj[header] = values[index];
        });
        result.push(obj);
    }

    return {
        data: result,
        errors: errors,
        rowCount: result.length,
        headers: headers
    };
}

/**
 * Validate file before upload
 */
export function validateFile(file, options = {}) {
    const {
        maxSize = 5 * 1024 * 1024, // 5MB default
        allowedTypes = ['text/csv', 'application/vnd.ms-excel'],
        allowedExtensions = ['.csv']
    } = options;

    const errors = [];

    if (!file) {
        errors.push('No file selected');
        return { valid: false, errors };
    }

    // Check file size
    if (file.size > maxSize) {
        errors.push(`File size (${formatFileSize(file.size)}) exceeds maximum allowed size (${formatFileSize(maxSize)})`);
    }

    // Check file type
    if (!allowedTypes.includes(file.type)) {
        const fileName = file.name.toLowerCase();
        const hasValidExtension = allowedExtensions.some(ext => fileName.endsWith(ext));
        if (!hasValidExtension) {
            errors.push(`Invalid file type. Allowed types: ${allowedExtensions.join(', ')}`);
        }
    }

    return {
        valid: errors.length === 0,
        errors
    };
}

/**
 * Format file size for display
 */
export function formatFileSize(bytes) {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
}

/**
 * Debounce function for search inputs
 */
export function debounce(func, wait = 300) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

/**
 * Show toast helper
 */
export function createToastEvent(title, message, variant) {
    return new CustomEvent('showtoast', {
        detail: {
            title: title,
            message: message,
            variant: variant
        },
        bubbles: true,
        composed: true
    });
}

/**
 * Deep clone object
 */
export function deepClone(obj) {
    return JSON.parse(JSON.stringify(obj));
}

/**
 * Check if user has edit permission
 */
export function hasEditPermission(permissionName) {
    // This will be checked via Apex in actual implementation
    return true;
}

/**
 * Generate month labels for forecast (12 months from current)
 */
export function generateMonthLabels(startDate = new Date()) {
    const months = [];
    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    for (let i = 0; i < 12; i++) {
        const date = new Date(startDate);
        date.setMonth(date.getMonth() + i);
        const monthName = monthNames[date.getMonth()];
        const year = date.getFullYear().toString().slice(-2);
        months.push(`${monthName}-${year}`);
    }

    return months;
}

/**
 * Batch array into chunks for processing
 */
export function batchArray(array, batchSize = 200) {
    const batches = [];
    for (let i = 0; i < array.length; i += batchSize) {
        batches.push(array.slice(i, i + batchSize));
    }
    return batches;
}

/**
 * Validate account ID format
 */
export function isValidSalesforceId(id, prefix = '') {
    if (!id) return false;
    const idPattern = /^[a-zA-Z0-9]{15}$|^[a-zA-Z0-9]{18}$/;
    if (!idPattern.test(id)) return false;
    if (prefix && !id.startsWith(prefix)) return false;
    return true;
}

/**
 * Error message extractor from Apex errors
 */
export function extractErrorMessage(error) {
    if (!error) return 'Unknown error occurred';

    if (error.body) {
        if (error.body.message) {
            return error.body.message;
        }
        if (error.body.pageErrors && error.body.pageErrors.length > 0) {
            return error.body.pageErrors[0].message;
        }
        if (error.body.fieldErrors) {
            const fieldErrors = Object.values(error.body.fieldErrors).flat();
            if (fieldErrors.length > 0) {
                return fieldErrors[0].message;
            }
        }
    }

    if (typeof error === 'string') {
        return error;
    }

    if (error.message) {
        return error.message;
    }

    return JSON.stringify(error);
}
