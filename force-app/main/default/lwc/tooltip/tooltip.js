import { LightningElement, track, api } from 'lwc';

export default class Tooltip extends LightningElement {
    @api withoutIcon = false;
    @api text = '';
    @api color = '';
    @api link = '';
    @api leftSide = false;
    @api tooltipIcon;
    @api variantIcon;
    @api wide = false;
    @api veryWide = false;
    @api custom = false;
    @track isVisible = false;

    get hasLink() {
        return this.link && this.link.length;
    }

    get iconName() {
        if (this.tooltipIcon) {
            return this.tooltipIcon;
        }else{
            return 'utility:info'
        }
    }

    get iconVariant(){
        if (this.variantIcon) {
            return this.variantIcon;
        }else{
            return 'bare'
        }
    }


    handleMouseOver() {
        if (this.text) {
            this.isVisible = true;
        }
    }

    handleMouseOut() {
        this.isVisible = false;
    }

    get classes() {
        let topClass = '';

        if (this.withoutIcon) {
            topClass = 'tooltip__popover-without-icon'
        }

        const { horizontal, vertical, nubbin } = this.getPositionClass();

        const visibilityClass = this.isVisible ? 'tooltip__popover--visible' : 'tooltip__popover--hidden';

        return `slds-popover slds-popover_tooltip tooltip__popover ${this.wide ? 'wide' : this.veryWide ? 'very-wide' : ''} ${visibilityClass} ${topClass} ${vertical || 'tooltip__popover-left'} ${horizontal || 'tooltip__popover-top'} ${nubbin}`
    }

    get mainClasses(){
        return `tooltip ${this.withoutIcon === true ? 'no-margin' : ''}`;
    }

    getPositionClass() {
        const returnClasses = {};
        const tooltip = this.template.querySelector('.tooltip__popover');
        const icon = this.template.querySelector('.tooltip');

        if (!tooltip || !icon) {
            return returnClasses;
        }

        let nubbinHorizontal;
        let nubbinVertical;
        const dimensions = tooltip.getBoundingClientRect();
        const iconPosition = icon.getBoundingClientRect();

        const willFitToRight = (dimensions.width + iconPosition.left) < window.innerWidth;
        if (willFitToRight && !this.leftSide) {
            returnClasses.horizontal = 'tooltip__popover-left';
            nubbinHorizontal = 'left'
        } else {
            returnClasses.horizontal = 'tooltip__popover-right';
            nubbinHorizontal = 'right';
        }

        const topPadding = sessionStorage.getItem('headerHeight') || 0;
        const TOOLTIP_SHIFT = 34;
        const willFitToTop = (iconPosition.top - dimensions.height - TOOLTIP_SHIFT) > 0 + topPadding;
        if (willFitToTop) {
            returnClasses.vertical = 'tooltip__popover-top';
            nubbinVertical = 'bottom';
        } else {
            returnClasses.vertical = 'tooltip__popover-bottom';
            nubbinVertical = 'top';
        }

        returnClasses.nubbin = `slds-nubbin_${nubbinVertical}-${nubbinHorizontal}`

        return returnClasses;
    }
}