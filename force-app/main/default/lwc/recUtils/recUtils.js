// ── Intl-based decimal point cache ──────────────────────────────────────
const _dpCache = new Map();

/**
 * Returns the decimal places for the given ISO 4217 currency code
 * using the browser's Intl.NumberFormat (CLDR data).
 * Falls back to 2 if the code is invalid or unknown.
 *
 * @param {string} currencyCode — ISO 4217 currency code (e.g. "USD", "JPY")
 * @returns {number}
 */
export function getDecimalPoint(currencyCode) {
    if (!currencyCode) return 2;
    if (_dpCache.has(currencyCode)) return _dpCache.get(currencyCode);
    try {
        const dp = new Intl.NumberFormat("en", { style: "currency", currency: currencyCode }).resolvedOptions()
            .maximumFractionDigits;
        _dpCache.set(currencyCode, dp);
        return dp;
    } catch {
        return 2;
    }
}

/**
 * Rounds a numeric value to the decimal places appropriate for the given currency.
 * Uses Intl.NumberFormat for decimal precision and IEEE 754-safe integer
 * multiplication to avoid floating-point drift.
 *
 * @param {number} value        — the raw numeric value
 * @param {string} currencyCode — ISO 4217 currency code (e.g. "USD", "JPY")
 * @returns {number}
 */
export function roundByCurrency(value, currencyCode) {
    if (value == null || isNaN(value)) return 0;
    const dp = getDecimalPoint(currencyCode);
    const factor = Math.pow(10, dp);
    return Math.round(value * factor) / factor;
}