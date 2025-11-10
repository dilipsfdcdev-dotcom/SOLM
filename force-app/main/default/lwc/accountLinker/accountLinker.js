import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import searchAccounts from '@salesforce/apex/AccountLinkerController.searchAccounts';
import getAggregatedUnlinkedTraceSales from '@salesforce/apex/AccountLinkerController.getAggregatedUnlinkedTraceSales';
import getAggregatedLinkedTraceSales from '@salesforce/apex/AccountLinkerController.getAggregatedLinkedTraceSales';
import createTraceAccountMappings from '@salesforce/apex/AccountLinkerController.createTraceAccountMappings';
import unlinkTraceAccountMappings from '@salesforce/apex/AccountLinkerController.unlinkTraceAccountMappings';

export default class AccountLinker extends LightningElement {
    @track currentScreen = 'screen1';
    @track searchTerm = '';
    @track selectedAccount = null;
    @track accountOptions = [];
    @track showDropdown = false;
    @track isLoading = false;
    
    // Table data - now storing aggregated records
    @track allRecords = [];
    @track filteredRecords = [];
    @track paginatedRecords = [];
    @track selectedGroupKeys = new Set();
    @track isTableLoading = false;
    
    // Filter panel state
    @track isFilterPanelOpen = false;
    
    // Filters
    @track filters = {
        distributor: '',
        shipToName: '',
        timePeriod: '',
        contractName: '',
        country: '',
        state: '',
        city: '',
        zipCode: ''
    };
    
    // Pagination
    @track currentPage = 1;
    @track pageSize = 10;
    @track totalRecords = 0;

    // Screen navigation
    get isScreen1() {
        return this.currentScreen === 'screen1';
    }

    get isScreen2() {
        return this.currentScreen === 'screen2';
    }

    get isScreen3() {
        return this.currentScreen === 'screen3';
    }

    get isScreen4() {
        return this.currentScreen === 'screen4';
    }

    // Continue button state
    get isContinueDisabled() {
        return !this.selectedAccount;
    }
    
    // Table container class based on page size
    get tableContainerClass() {
        return this.pageSize <= 50 ? 'table-container small-view' : 'table-container large-view';
    }
    
    // Filter panel CSS classes
    get filterPanelClass() {
        return `filter-panel${this.isFilterPanelOpen ? ' open' : ''}`;
    }
    
    get filterOverlayClass() {
        return `filter-panel-overlay${this.isFilterPanelOpen ? ' active' : ''}`;
    }

    // Search input handlers
    handleSearchInput(event) {
        this.searchTerm = event.target.value;
        
        if (this.searchTerm.length >= 2) {
            this.performSearch();
        } else {
            this.accountOptions = [];
            this.showDropdown = false;
            this.selectedAccount = null;
        }
    }

    handleSearchFocus() {
        if (this.accountOptions.length > 0) {
            this.showDropdown = true;
            this.positionDropdown();
        }
    }

    handleSearchBlur() {
        setTimeout(() => {
            this.showDropdown = false;
        }, 300);
    }

    positionDropdown() {
        setTimeout(() => {
            const searchInput = this.template.querySelector('.search-input');
            const dropdown = this.template.querySelector('.dropdown-container');
            
            if (searchInput && dropdown) {
                const rect = searchInput.getBoundingClientRect();
                dropdown.style.top = (rect.bottom + window.scrollY + 8) + 'px';
                dropdown.style.left = rect.left + 'px';
                dropdown.style.width = Math.max(rect.width, 400) + 'px';
            }
        }, 10);
    }

    performSearch() {
        this.isLoading = true;
        
        searchAccounts({ searchTerm: this.searchTerm })
            .then(result => {
                this.accountOptions = result.slice(0, 10).map(account => ({
                    id: account.Id,
                    name: account.Name,
                    type: account.Type || 'Account'
                }));
                this.showDropdown = this.accountOptions.length > 0;
                if (this.showDropdown) {
                    this.positionDropdown();
                }
            })
            .catch(error => {
                console.error('Search error:', error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleAccountSelect(event) {
        event.preventDefault();
        event.stopPropagation();
        
        const accountId = event.currentTarget.dataset.id;
        const selectedAccountData = this.accountOptions.find(acc => acc.id === accountId);
        
        if (selectedAccountData) {
            this.selectedAccount = selectedAccountData;
            this.searchTerm = selectedAccountData.name;
            this.showDropdown = false;
        }
    }

    handleClearSelection() {
        this.selectedAccount = null;
        this.searchTerm = '';
        this.accountOptions = [];
        this.showDropdown = false;
        
        setTimeout(() => {
            const searchInput = this.template.querySelector('.search-input');
            if (searchInput) {
                searchInput.focus();
            }
        }, 100);
    }

    connectedCallback() {
        this.handleResize = this.handleResize.bind(this);
        window.addEventListener('resize', this.handleResize);
        window.addEventListener('scroll', this.handleResize);
    }

    disconnectedCallback() {
        window.removeEventListener('resize', this.handleResize);
        window.removeEventListener('scroll', this.handleResize);
    }

    handleResize() {
        if (this.showDropdown) {
            this.positionDropdown();
        }
    }

    handleContinue() {
        if (this.selectedAccount) {
            this.currentScreen = 'screen2';
        }
    }

    handleCancel() {
        this.resetToInitialState();
    }

    handleLinkAccounts() {
        this.currentScreen = 'screen3';
        this.loadUnlinkedTraceSales();
    }

    handleUnlinkAccounts() {
        this.currentScreen = 'screen4';
        this.loadLinkedTraceSales();
    }

    handleBackToAccountSelect() {
        this.currentScreen = 'screen1';
    }
    
    handleBackToScreen2() {
        this.currentScreen = 'screen2';
        this.resetTableData();
        this.isFilterPanelOpen = false;
    }
    
    // Filter panel handlers
    toggleFilterPanel() {
        this.isFilterPanelOpen = !this.isFilterPanelOpen;
    }
    
    closeFilterPanel() {
        this.isFilterPanelOpen = false;
    }
    
    // Computed properties for table
    get hasRecords() {
        return this.filteredRecords.length > 0;
    }
    
    get hasNoSelection() {
        return this.selectedGroupKeys.size === 0;
    }
    
    get recordCountText() {
        return `Total Records: ${this.totalRecords}`;
    }
    
    get selectedCountText() {
        return `Selected: ${this.selectedGroupKeys.size}`;
    }
    
    get allSelected() {
        if (this.paginatedRecords.length === 0) return false;
        return this.paginatedRecords.every(rec => this.selectedGroupKeys.has(rec.groupKey));
    }
    
    get totalPages() {
        return Math.ceil(this.filteredRecords.length / this.pageSize);
    }
    
    get isFirstPage() {
        return this.currentPage === 1;
    }
    
    get isLastPage() {
        return this.currentPage >= this.totalPages;
    }
    
    get paginationStart() {
        return this.filteredRecords.length === 0 ? 0 : (this.currentPage - 1) * this.pageSize + 1;
    }
    
    get paginationEnd() {
        const end = this.currentPage * this.pageSize;
        return end > this.filteredRecords.length ? this.filteredRecords.length : end;
    }
    
    // Load data methods - now using aggregated data
    loadUnlinkedTraceSales() {
        this.isTableLoading = true;
        getAggregatedUnlinkedTraceSales()
            .then(result => {
                this.allRecords = this.mapAggregatedDataToTableData(result);
                this.applyFiltersAndPagination();
            })
            .catch(error => {
                this.showToast('Error', 'Failed to load trace sales records', 'error');
                console.error('Load error:', error);
            })
            .finally(() => {
                this.isTableLoading = false;
            });
    }
    
    loadLinkedTraceSales() {
        this.isTableLoading = true;
        getAggregatedLinkedTraceSales({ accountId: this.selectedAccount.id })
            .then(result => {
                this.allRecords = this.mapAggregatedDataToTableData(result);
                this.applyFiltersAndPagination();
            })
            .catch(error => {
                this.showToast('Error', 'Failed to load linked records', 'error');
                console.error('Load error:', error);
            })
            .finally(() => {
                this.isTableLoading = false;
            });
    }
    
    mapAggregatedDataToTableData(records) {
        return records.map(record => ({
            groupKey: record.groupKey,
            distributor: record.distributor || '',
            shipToName: record.customer || '',
            timePeriod: record.timePeriod || '',
            totalRevenue: record.totalRevenue ? `${record.totalRevenue.toLocaleString()}` : '$0',
            contractName: record.contractNames || '',
            country: record.country || '',
            state: record.state || '',
            city: record.city || '',
            zipCode: record.zipCode || '',
            traceSaleIds: record.traceSaleIds || [],
            selected: this.selectedGroupKeys.has(record.groupKey),
            // Store raw data for linking
            rawData: {
                distributor: record.distributor,
                customer: record.customer,
                zipCode: record.zipCode,
                city: record.city,
                state: record.state,
                country: record.country,
                totalRevenue: record.totalRevenue,
                contractNames: record.contractNames,
                traceSaleIds: record.traceSaleIds,
                timePeriod: record.timePeriod
            }
        }));
    }
    
    // Filter handlers with dynamic filtering
    handleFilterChange(event) {
        const field = event.target.dataset.field;
        this.filters[field] = event.target.value;
        
        // Apply filters dynamically as user types
        this.currentPage = 1;
        this.applyFiltersAndPagination();
    }
    
    handleApplyFilters() {
        this.currentPage = 1;
        this.applyFiltersAndPagination();
        this.closeFilterPanel();
    }
    
    handleClearFilters() {
        this.filters = {
            distributor: '',
            shipToName: '',
            timePeriod: '',
            contractName: '',
            country: '',
            state: '',
            city: '',
            zipCode: ''
        };
        
        const inputs = this.template.querySelectorAll('.filter-input');
        inputs.forEach(input => {
            input.value = '';
        });
        
        this.currentPage = 1;
        this.applyFiltersAndPagination();
    }
    
    applyFiltersAndPagination() {
        this.filteredRecords = this.allRecords.filter(record => {
            return (
                (!this.filters.distributor || record.distributor.toLowerCase().includes(this.filters.distributor.toLowerCase())) &&
                (!this.filters.shipToName || record.shipToName.toLowerCase().includes(this.filters.shipToName.toLowerCase())) &&
                (!this.filters.timePeriod || record.timePeriod.includes(this.filters.timePeriod)) &&
                (!this.filters.contractName || record.contractName.toLowerCase().includes(this.filters.contractName.toLowerCase())) &&
                (!this.filters.country || record.country.toLowerCase().includes(this.filters.country.toLowerCase())) &&
                (!this.filters.state || record.state.toLowerCase().includes(this.filters.state.toLowerCase())) &&
                (!this.filters.city || record.city.toLowerCase().includes(this.filters.city.toLowerCase())) &&
                (!this.filters.zipCode || record.zipCode.includes(this.filters.zipCode))
            );
        });
        
        this.totalRecords = this.filteredRecords.length;
        
        // Reset to page 1 if current page is beyond available pages
        if (this.currentPage > this.totalPages && this.totalPages > 0) {
            this.currentPage = 1;
        }
        
        this.updatePaginatedRecords();
    }
    
    updatePaginatedRecords() {
        const start = (this.currentPage - 1) * this.pageSize;
        const end = start + this.pageSize;
        this.paginatedRecords = this.filteredRecords.slice(start, end).map(record => ({
            ...record,
            selected: this.selectedGroupKeys.has(record.groupKey)
        }));
    }
    
    // Selection handlers
    handleSelectAll(event) {
        const isChecked = event.target.checked;
        
        this.paginatedRecords.forEach(record => {
            if (isChecked) {
                this.selectedGroupKeys.add(record.groupKey);
            } else {
                this.selectedGroupKeys.delete(record.groupKey);
            }
        });
        
        this.updatePaginatedRecords();
    }
    
    handleRowSelect(event) {
        const groupKey = event.target.dataset.id;
        const isChecked = event.target.checked;
        
        if (isChecked) {
            this.selectedGroupKeys.add(groupKey);
        } else {
            this.selectedGroupKeys.delete(groupKey);
        }
        
        this.updatePaginatedRecords();
    }
    
    // Pagination handlers
    handlePreviousPage() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.updatePaginatedRecords();
        }
    }
    
    handleNextPage() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            this.updatePaginatedRecords();
        }
    }
    
    handlePageSizeChange(event) {
        this.pageSize = parseInt(event.target.value, 10);
        this.currentPage = 1;
        this.updatePaginatedRecords();
    }
    
    // Link/Unlink actions - now creating mapping records
    handleLinkSelectedAccounts() {
        if (this.selectedGroupKeys.size === 0) {
            this.showToast('Warning', 'Please select at least one record', 'warning');
            return;
        }
        
        this.isTableLoading = true;
        
        // Get the selected aggregated records
        const selectedRecords = this.allRecords.filter(rec => 
            this.selectedGroupKeys.has(rec.groupKey)
        ).map(rec => rec.rawData);
        
        // Convert to JSON for Apex
        const aggregatedDataJson = JSON.stringify(selectedRecords);
        
        createTraceAccountMappings({ 
            aggregatedDataJson: aggregatedDataJson,
            accountId: this.selectedAccount.id 
        })
            .then(() => {
                this.showToast('Success', `Successfully linked ${this.selectedGroupKeys.size} record(s)`, 'success');
                this.selectedGroupKeys.clear();
                this.loadUnlinkedTraceSales();
            })
            .catch(error => {
                this.showToast('Error', 'Failed to link records', 'error');
                console.error('Link error:', error);
                this.isTableLoading = false;
            });
    }
    
    handleUnlinkSelectedAccounts() {
        if (this.selectedGroupKeys.size === 0) {
            this.showToast('Warning', 'Please select at least one record', 'warning');
            return;
        }
        
        this.isTableLoading = true;
        
        // Get the selected aggregated records
        const selectedRecords = this.allRecords.filter(rec => 
            this.selectedGroupKeys.has(rec.groupKey)
        ).map(rec => rec.rawData);
        
        // Convert to JSON for Apex
        const aggregatedDataJson = JSON.stringify(selectedRecords);
        
        unlinkTraceAccountMappings({ aggregatedDataJson: aggregatedDataJson })
            .then(() => {
                this.showToast('Success', `Successfully unlinked ${this.selectedGroupKeys.size} record(s)`, 'success');
                this.selectedGroupKeys.clear();
                this.loadLinkedTraceSales();
            })
            .catch(error => {
                this.showToast('Error', 'Failed to unlink records', 'error');
                console.error('Unlink error:', error);
                this.isTableLoading = false;
            });
    }
    
    resetTableData() {
        this.allRecords = [];
        this.filteredRecords = [];
        this.paginatedRecords = [];
        this.selectedGroupKeys = new Set();
        this.currentPage = 1;
        this.filters = {
            distributor: '',
            shipToName: '',
            timePeriod: '',
            contractName: '',
            country: '',
            state: '',
            city: '',
            zipCode: ''
        };
    }

    resetToInitialState() {
        this.currentScreen = 'screen1';
        this.selectedAccount = null;
        this.searchTerm = '';
        this.accountOptions = [];
        this.showDropdown = false;
        this.isFilterPanelOpen = false;
        this.resetTableData();
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }
}