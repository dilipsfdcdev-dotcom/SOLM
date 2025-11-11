import { LightningElement } from 'lwc';

export default class Forecast2Home extends LightningElement {
    showNavigation = true;
    showMassUpload = false;
    showAccountView = false;
    showProductView = false;

    /**
     * Handle Mass Upload option selection
     */
    handleMassUpload() {
        this.resetViews();
        this.showMassUpload = true;
    }

    /**
     * Handle Search by Account option selection
     */
    handleSearchByAccount() {
        this.resetViews();
        this.showAccountView = true;
    }

    /**
     * Handle Search by Product option selection
     */
    handleSearchByProduct() {
        this.resetViews();
        this.showProductView = true;
    }

    /**
     * Handle back to navigation
     */
    handleBackToNav() {
        this.resetViews();
        this.showNavigation = true;
    }

    /**
     * Reset all views
     */
    resetViews() {
        this.showNavigation = false;
        this.showMassUpload = false;
        this.showAccountView = false;
        this.showProductView = false;
    }
}
