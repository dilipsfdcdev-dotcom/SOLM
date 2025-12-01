import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import searchAccounts from '@salesforce/apex/AccountLinkerController.searchAccounts';
import getUnlinkedTraceAccountMappings from '@salesforce/apex/AccountLinkerController.getUnlinkedTraceAccountMappings';
import getLinkedTraceAccountMappings from '@salesforce/apex/AccountLinkerController.getLinkedTraceAccountMappings';
import linkTraceAccountMappings from '@salesforce/apex/AccountLinkerController.linkTraceAccountMappings';
import unlinkTraceAccountMappings from '@salesforce/apex/AccountLinkerController.unlinkTraceAccountMappings';

export default class AccountLinker extends LightningElement {
    @track currentScreen = 'screen1';
    @track searchTerm = '';
    @track selectedAccount = null;
    @track accountOptions = [];
    @track showDropdown = false;
    @track isLoading = false;

    // Table data - now storing Trace Account Mapping records
    @track paginatedRecords = [];
    @track selectedRecordIds = new Set();
    @track isTableLoading = false;

    // Filter panel state
    @track isFilterPanelOpen = false;

    // Filters - updated to match new object fields
    @track filters = {
        distributor: '',
        customer: '',
        invoiceYear: '',
        contractName: '',
        country: '',
        state: '',
        city: '',
        zipCode: ''
    };

    // Server-side pagination
    @track currentPage = 1;
    @track pageSize = 10;
    @track totalRecords = 0;
    @track totalPages = 0;

    // Debounce timer for filters
    filterDebounceTimer = null;

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
        if (this.filterDebounceTimer) {
            clearTimeout(this.filterDebounceTimer);
        }
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
        this.resetTableData();
        this.loadUnlinkedMappings();
    }

    handleUnlinkAccounts() {
        this.currentScreen = 'screen4';
        this.resetTableData();
        this.loadLinkedMappings();
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
        return this.paginatedRecords.length > 0;
    }

    get hasNoSelection() {
        return this.selectedRecordIds.size === 0;
    }

    get recordCountText() {
        return `Total Records: ${this.totalRecords}`;
    }

    get selectedCountText() {
        return `Selected: ${this.selectedRecordIds.size}`;
    }

    get allSelected() {
        if (this.paginatedRecords.length === 0) return false;
        return this.paginatedRecords.every(rec => this.selectedRecordIds.has(rec.id));
    }

    get isFirstPage() {
        return this.currentPage === 1;
    }

    get isLastPage() {
        return this.currentPage >= this.totalPages;
    }

    get paginationStart() {
        return this.totalRecords === 0 ? 0 : (this.currentPage - 1) * this.pageSize + 1;
    }

    get paginationEnd() {
        const end = this.currentPage * this.pageSize;
        return end > this.totalRecords ? this.totalRecords : end;
    }

    // Load unlinked Trace Account Mappings with server-side pagination
    loadUnlinkedMappings() {
        this.isTableLoading = true;

        getUnlinkedTraceAccountMappings({
            pageNumber: this.currentPage,
            pageSize: this.pageSize,
            distributor: this.filters.distributor || null,
            customer: this.filters.customer || null,
            zipCode: this.filters.zipCode || null,
            city: this.filters.city || null,
            state: this.filters.state || null,
            country: this.filters.country || null,
            invoiceYear: this.filters.invoiceYear || null,
            contractName: this.filters.contractName || null
        })
            .then(response => {
                this.processServerResponse(response);
            })
            .catch(error => {
                this.handleLoadError(error);
            })
            .finally(() => {
                this.isTableLoading = false;
            });
    }

    // Load linked Trace Account Mappings with server-side pagination
    loadLinkedMappings() {
        this.isTableLoading = true;

        getLinkedTraceAccountMappings({
            accountId: this.selectedAccount.id,
            pageNumber: this.currentPage,
            pageSize: this.pageSize,
            distributor: this.filters.distributor || null,
            customer: this.filters.customer || null,
            zipCode: this.filters.zipCode || null,
            city: this.filters.city || null,
            state: this.filters.state || null,
            country: this.filters.country || null,
            invoiceYear: this.filters.invoiceYear || null,
            contractName: this.filters.contractName || null
        })
            .then(response => {
                this.processServerResponse(response);
            })
            .catch(error => {
                this.handleLoadError(error);
            })
            .finally(() => {
                this.isTableLoading = false;
            });
    }

    processServerResponse(response) {
        if (response && response.records) {
            this.paginatedRecords = response.records.map(record => ({
                id: record.id,
                uniqueId: record.uniqueId || '',
                distributor: record.distributor || '',
                customer: record.customer || '',
                invoiceYear: record.invoiceYear || '',
                totalRevenue: record.totalRevenue ? `$${record.totalRevenue.toLocaleString()}` : '$0',
                contractName: record.contractNames || '',
                country: record.country || '',
                state: record.state || '',
                city: record.city || '',
                zipCode: record.zipCode || '',
                selected: this.selectedRecordIds.has(record.id)
            }));
            this.totalRecords = response.totalRecords || 0;
            this.totalPages = response.totalPages || 0;
            this.currentPage = response.pageNumber || 1;
        } else {
            this.paginatedRecords = [];
            this.totalRecords = 0;
            this.totalPages = 0;
        }
    }

    handleLoadError(error) {
        let errorMessage = 'Failed to load records';
        if (error?.body?.message) {
            errorMessage = error.body.message;
        }
        this.showToast('Error', errorMessage, 'error');
        console.error('Load error:', error);
        this.paginatedRecords = [];
        this.totalRecords = 0;
        this.totalPages = 0;
    }

    // Filter handlers with debounced server-side filtering
    handleFilterChange(event) {
        const field = event.target.dataset.field;
        this.filters[field] = event.target.value;

        // Debounce the server call
        if (this.filterDebounceTimer) {
            clearTimeout(this.filterDebounceTimer);
        }

        this.filterDebounceTimer = setTimeout(() => {
            this.currentPage = 1;
            this.loadCurrentScreenData();
        }, 500); // 500ms debounce
    }

    handleApplyFilters() {
        this.currentPage = 1;
        this.loadCurrentScreenData();
        this.closeFilterPanel();
    }

    handleClearFilters() {
        this.filters = {
            distributor: '',
            customer: '',
            invoiceYear: '',
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
        this.loadCurrentScreenData();
    }

    loadCurrentScreenData() {
        if (this.currentScreen === 'screen3') {
            this.loadUnlinkedMappings();
        } else if (this.currentScreen === 'screen4') {
            this.loadLinkedMappings();
        }
    }

    // Selection handlers
    handleSelectAll(event) {
        const isChecked = event.target.checked;

        // Create a new Set to trigger reactivity
        const updatedSelection = new Set(this.selectedRecordIds);

        this.paginatedRecords.forEach(record => {
            if (isChecked) {
                updatedSelection.add(record.id);
            } else {
                updatedSelection.delete(record.id);
            }
        });

        this.selectedRecordIds = updatedSelection;
        this.updateRecordSelection();
    }

    handleRowSelect(event) {
        const recordId = event.target.dataset.id;
        const isChecked = event.target.checked;

        // Create a new Set to trigger reactivity
        const updatedSelection = new Set(this.selectedRecordIds);

        if (isChecked) {
            updatedSelection.add(recordId);
        } else {
            updatedSelection.delete(recordId);
        }

        this.selectedRecordIds = updatedSelection;
        this.updateRecordSelection();
    }

    updateRecordSelection() {
        this.paginatedRecords = this.paginatedRecords.map(record => ({
            ...record,
            selected: this.selectedRecordIds.has(record.id)
        }));
    }

    // Pagination handlers
    handlePreviousPage() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.loadCurrentScreenData();
            this.scrollToTableTop();
        }
    }

    handleNextPage() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            this.loadCurrentScreenData();
            this.scrollToTableTop();
        }
    }

    scrollToTableTop() {
        // Scroll to top of table for better UX
        const tableContainer = this.template.querySelector('.table-container');
        if (tableContainer) {
            tableContainer.scrollIntoView({ behavior: 'smooth', block: 'start' });
        }
    }

    handlePageSizeChange(event) {
        this.pageSize = parseInt(event.target.value, 10);
        this.currentPage = 1;
        this.loadCurrentScreenData();
    }

    // Link action - update Account__c on selected Trace Account Mappings
    handleLinkSelectedAccounts() {
        if (this.selectedRecordIds.size === 0) {
            this.showToast('Warning', 'Please select at least one record to link', 'warning');
            return;
        }

        this.isTableLoading = true;
        const selectionCount = this.selectedRecordIds.size;

        // Convert Set to Array for Apex
        const mappingIds = Array.from(this.selectedRecordIds);

        linkTraceAccountMappings({
            mappingIds: mappingIds,
            accountId: this.selectedAccount.id
        })
            .then(() => {
                this.showToast('Success', `Successfully linked ${selectionCount} record(s) to ${this.selectedAccount.name}`, 'success');
                // Clear selections and reload
                this.selectedRecordIds = new Set();
                this.currentPage = 1;
                this.loadUnlinkedMappings();
            })
            .catch(error => {
                let errorMessage = 'Failed to link records';
                if (error?.body?.message) {
                    errorMessage = error.body.message;
                } else if (error?.message) {
                    errorMessage = error.message;
                }
                this.showToast('Error', errorMessage, 'error');
                console.error('Link error:', error);
                this.isTableLoading = false;
            });
    }

    // Unlink action - set Account__c to null on selected Trace Account Mappings
    handleUnlinkSelectedAccounts() {
        if (this.selectedRecordIds.size === 0) {
            this.showToast('Warning', 'Please select at least one record to unlink', 'warning');
            return;
        }

        this.isTableLoading = true;
        const selectionCount = this.selectedRecordIds.size;

        // Convert Set to Array for Apex
        const mappingIds = Array.from(this.selectedRecordIds);

        unlinkTraceAccountMappings({ mappingIds: mappingIds })
            .then(() => {
                this.showToast('Success', `Successfully unlinked ${selectionCount} record(s) from ${this.selectedAccount.name}`, 'success');
                // Clear selections and reload
                this.selectedRecordIds = new Set();
                this.currentPage = 1;
                this.loadLinkedMappings();
            })
            .catch(error => {
                let errorMessage = 'Failed to unlink records';
                if (error?.body?.message) {
                    errorMessage = error.body.message;
                } else if (error?.message) {
                    errorMessage = error.message;
                }
                this.showToast('Error', errorMessage, 'error');
                console.error('Unlink error:', error);
                this.isTableLoading = false;
            });
    }

    resetTableData() {
        this.paginatedRecords = [];
        this.selectedRecordIds = new Set();
        this.currentPage = 1;
        this.totalRecords = 0;
        this.totalPages = 0;
        this.filters = {
            distributor: '',
            customer: '',
            invoiceYear: '',
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
