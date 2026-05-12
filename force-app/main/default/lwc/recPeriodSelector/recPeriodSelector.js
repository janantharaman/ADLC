/**
 * @group        : Trestle
 * @description  :
 * @author       : Yugon Hwang
 * Modifications Log
 * Ver   Date         Author        Modification
 * 1.0   01-08-2026   Yugon Hwang   Initial Version
 **/
import { LightningElement, api } from "lwc";

export default class RecPeriodSelector extends LightningElement {
    @api variant = "label-hidden";
    @api placeholder_from = "from";
    @api placeholder_to = "to";
    @api label_from = "Period From";
    @api label_to = "Period To";

    // Template binds to these directly (value={_periodFromDate}),
    // so they must always hold a valid ISO 8601 string (YYYY-MM-DD) or null.
    _periodFromDate = null;
    _periodToDate = null;
    _errorMessage = null;

    // ── @api ──────────────────────────────────────────────────────────────────

    @api
    get periodFromDate() {
        return this._periodFromDate ?? null;
    }
    set periodFromDate(value) {
        this._periodFromDate = value ?? null;
    }

    @api
    get periodToDate() {
        return this._periodToDate ?? null;
    }
    set periodToDate(value) {
        this._periodToDate = value ?? null;
    }

    @api
    reset() {
        this._periodFromDate = null;
        this._periodToDate = null;
        this._errorMessage = null;
    }

    // ── Menu items ────────────────────────────────────────────────────────────

    menuItems = [
        { value: "Period_LastMonth", label: "Last Month" },
        { value: "Period_ThisMonth", label: "This Month" },
        { value: "Period_Last30Days", label: "Last 30 Days" }
    ];

    // ── Handlers ─────────────────────────────────────────────────────────────

    /** lightning-input fires event.detail.value; name targets the private field */
    handleDateChange(event) {
        const name = event.target.name;
        const value = event.detail.value || null;
        this._errorMessage = null;

        if (name === "_periodFromDate") {
            if (value && this._periodToDate && value > this._periodToDate) {
                // Force clear: set to value first so LWC detects the subsequent null change
                this._periodFromDate = value;
                // eslint-disable-next-line @lwc/lwc/no-async-operation
                Promise.resolve().then(() => {
                    this._periodFromDate = null;
                });
                this._errorMessage = "From date cannot be later than To date.";
                return;
            }
            this._periodFromDate = value;
        } else if (name === "_periodToDate") {
            if (value && this._periodFromDate && value < this._periodFromDate) {
                // Force clear: set to value first so LWC detects the subsequent null change
                this._periodToDate = value;
                // eslint-disable-next-line @lwc/lwc/no-async-operation
                Promise.resolve().then(() => {
                    this._periodToDate = null;
                });
                this._errorMessage = "To date cannot be earlier than From date.";
                return;
            }
            this._periodToDate = value;
        }
    }

    get wrapperClass() {
        return this._errorMessage ? "rps-wrap rps-error" : "rps-wrap";
    }

    handlePeriodButtonSelect(event) {
        const now = new Date();
        const y = now.getFullYear();
        const m = now.getMonth(); // 0-indexed

        switch (event.detail.value) {
            case "Period_LastMonth":
                // month-1 day-1 → month-1 last-day (day=0 rolls back to prev month's last day)
                this._setRange(this._toISODate(y, m - 1, 1), this._toISODate(y, m, 0));
                break;
            case "Period_ThisMonth":
                this._setRange(this._toISODate(y, m, 1), this._toISODate(y, m + 1, 0));
                break;
            case "Period_Last30Days":
                this._setRange(this._toISODate(y, m, now.getDate() - 30), this._toISODate(y, m, now.getDate()));
                break;
            default:
                break;
        }
    }

    // ── Private helpers ───────────────────────────────────────────────────────

    _setRange(from, to) {
        this._periodFromDate = from;
        this._periodToDate = to;
        this._errorMessage = null;
    }

    /**
     * Returns a zero-padded ISO 8601 date string (YYYY-MM-DD).
     * Accepts overflowing day/month values — the Date constructor normalises them
     * (e.g. month=-1 → December of previous year, day=0 → last day of prev month).
     */
    _toISODate(year, month, day) {
        const d = new Date(year, month, day);
        const mm = String(d.getMonth() + 1).padStart(2, "0");
        const dd = String(d.getDate()).padStart(2, "0");
        return `${d.getFullYear()}-${mm}-${dd}`;
    }
}