import { LightningElement, api } from 'lwc';
import { FlowNavigationFinishEvent } from 'lightning/flowSupport';

export default class VoiceCallRecordingAutoDownload extends LightningElement {
  @api url;          // required
  @api autoClose;    // boolean from Flow
  @api closeDelayMs; // integer from Flow

  // one-shot guard to prevent multiple fires if the component re-renders
  _fired = false;

  get shouldAutoClose() {
    return !(this.autoClose === false || this.autoClose === 'false');
  }
  get delayMs() {
    const n = parseInt(this.closeDelayMs, 10);
    return Number.isFinite(n) && n >= 0 ? n : 800;
  }

  connectedCallback() {
    if (this._fired) return;     // <= stop second execution
    this._fired = true;

    if (!this.url) return;

    const a = document.createElement('a');
    a.href = this.url;
    a.setAttribute('download', '');
    a.style.display = 'none';
    document.body.appendChild(a);
    a.click();
    a.remove();

    // IMPORTANT: remove automatic window.open fallback to avoid double
    // If you still want a manual fallback, keep a visible link in the template.

    if (this.shouldAutoClose) {
      window.setTimeout(() => {
        try {
          this.dispatchEvent(new FlowNavigationFinishEvent());
        } catch (e) {
          // last resort
          window.history.back();
        }
      }, this.delayMs);
    }
  }
}