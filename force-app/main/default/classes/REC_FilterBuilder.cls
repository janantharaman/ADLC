/**
 * REC_FilterBuilder — Dynamic SOQL WHERE-clause builder.
 *
 * Parses a JSON filter string from LWC and builds bind-variable-safe
 * conditions for use with Database.queryWithBinds().
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *  Supported value shapes (auto-detected from JSON)
 * ═══════════════════════════════════════════════════════════════════════════
 *   null  /  ""           → skipped (no condition added)
 *   "string"              → equality   field = :bind
 *   "%string%" (contains %)→ LIKE       field LIKE :bind
 *   number (Decimal)      → equality   field = :bind
 *   boolean               → equality   field = :bind
 *   { "from": v, "to": v} → range      field >= :bind_from AND/OR field <= :bind_to
 *   [ v1, v2, … ]         → IN clause  field IN :bind
 *
 *   Keys ending with '__exclude':
 *   field__exclude: [ v1, v2, … ] → NOT IN clause  field NOT IN :bind
 *
 *   Date-like strings  (yyyy-MM-dd)      are auto-cast to Date.
 *   Datetime-like strings (yyyy-MM-ddT…) are auto-cast to Datetime.
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *  Usage
 * ═══════════════════════════════════════════════════════════════════════════
 *   REC_FilterBuilder fb = new REC_FilterBuilder(filtersJson)
 *       .addCondition('IsDeleted = :isDeleted')
 *       .addBind('isDeleted', false);
 *
 *   String query = String.format(
 *       'SELECT {0} FROM MyObject__c WHERE {1} ORDER BY Name',
 *       new List<String>{ fieldsCsv, fb.toWhereClause() }
 *   );
 *   List<SObject> rows = Database.queryWithBinds(query, fb.getBinds(), AccessLevel.USER_MODE);
 */
public with sharing class REC_FilterBuilder {
    // ── ISO date / datetime patterns ─────────────────────────────────────
    private static final Pattern DATE_PATTERN = Pattern.compile('^\\d{4}-\\d{2}-\\d{2}$');
    private static final Pattern DATETIME_PATTERN = Pattern.compile('^\\d{4}-\\d{2}-\\d{2}T');

    // ── Internal state ───────────────────────────────────────────────────
    private final List<String> conditions = new List<String>();
    private final Map<String, Object> binds = new Map<String, Object>();
    private final Set<String> relationshipFields = new Set<String>();
    private final Schema.SObjectType baseSObjectType;

    // ═══════════════════════════════════════════════════════════════════════
    //  Constructor
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * @param filtersJson  JSON string produced by LWC filter component.
     *                     Null / blank is safe — results in zero conditions.
     */
    public REC_FilterBuilder(String filtersJson) {
        this(filtersJson, null);
    }

    /**
     * Schema-aware constructor.  When baseSObjectType is provided the builder
     * can resolve the actual field type (including across relationships) and
     * skip Date/Datetime auto-casting for Text / TextArea columns.
     *
     * @param filtersJson      JSON string produced by LWC filter component.
     * @param baseSObjectType  SObjectType of the queried object (nullable).
     */
    public REC_FilterBuilder(String filtersJson, Schema.SObjectType baseSObjectType) {
        this.baseSObjectType = baseSObjectType;

        if (String.isBlank(filtersJson)) {
            return;
        }

        Map<String, Object> filterMap = (Map<String, Object>) JSON.deserializeUntyped(filtersJson);

        for (String fieldName : filterMap.keySet()) {
            processFilter(fieldName, filterMap.get(fieldName));
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    //  Public API
    // ═══════════════════════════════════════════════════════════════════════

    /** Append a manual WHERE fragment (e.g. 'IsDeleted = :isDeleted'). Chainable. */
    public REC_FilterBuilder addCondition(String condition) {
        conditions.add(condition);
        return this;
    }

    /** Register a manual bind variable. Chainable. */
    public REC_FilterBuilder addBind(String key, Object value) {
        binds.put(key, value);
        return this;
    }

    /** All accumulated condition fragments. */
    public List<String> getConditions() {
        return conditions;
    }

    /** Full bind-variable map (dynamic + manual). */
    public Map<String, Object> getBinds() {
        return binds;
    }

    /** True when at least one condition has been registered. */
    public Boolean hasConditions() {
        return !conditions.isEmpty();
    }

    /**
     * Returns the set of relationship (dot-notation) field paths found in the
     * filter keys.  These are fields the caller should include in the SELECT
     * clause so that WHERE references resolve correctly.
     * e.g. filter key 'RefClaim__r.LossDate__c' → collected automatically.
     */
    public Set<String> getRelationshipFields() {
        return relationshipFields;
    }

    /**
     * Returns conditions joined by ' AND '.
     * Falls back to 'Id != null' when no conditions exist (always-true, SOQL-safe).
     */
    public String toWhereClause() {
        String clause = conditions.isEmpty() ? 'Id != null' : String.join(conditions, ' AND ');

        System.debug(LoggingLevel.FINEST, '[REC_FilterBuilder] WHERE ' + clause);

        return clause;
    }

    // ═══════════════════════════════════════════════════════════════════════
    //  Private — filter dispatch
    // ═══════════════════════════════════════════════════════════════════════

    private void processFilter(String field, Object value) {
        if (value == null) {
            return;
        }

        // Auto-collect relationship (dot-notation) fields for SELECT inclusion
        if (field.contains('.') && !field.endsWith('__exclude')) {
            relationshipFields.add(field);
        }

        // Keys ending with '__exclude' → NOT IN clause
        if (field.endsWith('__exclude')) {
            String realField = field.removeEnd('__exclude');
            if (value instanceof List<Object>) {
                handleNotIn(realField, (List<Object>) value);
            }
            return;
        }

        if (value instanceof Map<String, Object>) {
            // Range object  { "from": …, "to": … }
            handleRange(field, (Map<String, Object>) value);
        } else if (value instanceof List<Object>) {
            // List → IN clause
            handleIn(field, (List<Object>) value);
        } else if (value instanceof String) {
            // Scalar string
            if (String.isBlank((String) value)) {
                return;
            }

            String strVal = (String) value;

            if (strVal.contains('%')) {
                addLike(field, strVal);
            } else {
                addEquality(field, isStringField(field) ? value : castValue(value));
            }
        } else {
            // Decimal / Boolean / other primitives
            addEquality(field, value);
        }
    }

    // ── Range ────────────────────────────────────────────────────────────

    private void handleRange(String field, Map<String, Object> range) {
        Object fromVal = range.get('from');
        Object toVal = range.get('to');
        String safeField = toBindKey(field);
        Boolean keepAsString = isStringField(field);

        if (fromVal != null && !(fromVal instanceof String && String.isBlank((String) fromVal))) {
            String key = safeField + '_from';
            conditions.add(field + ' >= :' + key);
            binds.put(key, keepAsString ? fromVal : castValue(fromVal));
        }

        if (toVal != null && !(toVal instanceof String && String.isBlank((String) toVal))) {
            String key = safeField + '_to';
            conditions.add(field + ' <= :' + key);
            binds.put(key, keepAsString ? toVal : castValue(toVal));
        }
    }

    // ── IN clause ────────────────────────────────────────────────────────

    // ── IN clause ────────────────────────────────────────────────────────

    private void handleIn(String field, List<Object> values) {
        List<Object> parsed = new List<Object>();
        Boolean keepAsString = isStringField(field);

        for (Object v : values) {
            if (v != null) {
                parsed.add(keepAsString ? v : castValue(v));
            }
        }

        if (parsed.isEmpty()) {
            return;
        }

        String key = toBindKey(field) + '_in';
        conditions.add(field + ' IN :' + key);

        // Database.queryWithBinds requires a concretely-typed list.
        // List<Object> is treated as ANY and rejected for typed columns (e.g. String, Date).
        Object first = parsed[0];
        if (first instanceof String) {
            List<String> typed = new List<String>();
            for (Object v : parsed) {
                typed.add((String) v);
            }
            binds.put(key, typed);
        } else if (first instanceof Decimal) {
            List<Decimal> typed = new List<Decimal>();
            for (Object v : parsed) {
                typed.add((Decimal) v);
            }
            binds.put(key, typed);
        } else if (first instanceof Date) {
            List<Date> typed = new List<Date>();
            for (Object v : parsed) {
                typed.add((Date) v);
            }
            binds.put(key, typed);
        } else if (first instanceof Datetime) {
            List<Datetime> typed = new List<Datetime>();
            for (Object v : parsed) {
                typed.add((Datetime) v);
            }
            binds.put(key, typed);
        } else {
            binds.put(key, parsed);
        }
    }

    // ── NOT IN clause ────────────────────────────────────────────────────

    private void handleNotIn(String field, List<Object> values) {
        List<Object> parsed = new List<Object>();
        Boolean keepAsString = isStringField(field);

        for (Object v : values) {
            if (v != null) {
                parsed.add(keepAsString ? v : castValue(v));
            }
        }

        if (parsed.isEmpty()) {
            return;
        }

        String key = toBindKey(field) + '_notIn';
        conditions.add(field + ' NOT IN :' + key);

        Object first = parsed[0];
        if (first instanceof String) {
            List<String> typed = new List<String>();
            for (Object v : parsed) {
                typed.add((String) v);
            }
            binds.put(key, typed);
        } else if (first instanceof Decimal) {
            List<Decimal> typed = new List<Decimal>();
            for (Object v : parsed) {
                typed.add((Decimal) v);
            }
            binds.put(key, typed);
        } else {
            binds.put(key, parsed);
        }
    }

    // ── Equality ─────────────────────────────────────────────────────────

    private void addEquality(String field, Object value) {
        String key = toBindKey(field);
        conditions.add(field + ' = :' + key);
        binds.put(key, value);
    }

    // ── LIKE ──────────────────────────────────────────────────────────────

    private void addLike(String field, String value) {
        String key = toBindKey(field);
        conditions.add(field + ' LIKE :' + key);
        binds.put(key, value);
    }

    // ═══════════════════════════════════════════════════════════════════════
    //  Private — schema-aware type resolution
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Returns true when the target field is a Text / TextArea column.
     * Used to skip Date/Datetime auto-casting for string-typed columns
     * that happen to store date-like values (e.g. Claim.LossDate__c).
     * Falls back to false (= allow casting) when the type cannot be resolved.
     */
    private Boolean isStringField(String fieldPath) {
        Schema.DisplayType dt = resolveFieldType(fieldPath);
        return dt == Schema.DisplayType.STRING || dt == Schema.DisplayType.TEXTAREA;
    }

    /**
     * Resolves the Schema.DisplayType for a field path, navigating
     * relationship hops as needed.
     *
     * Examples:
     *   'Name'                    → resolved directly on baseSObjectType
     *   'RefClaim__r.LossDate__c' → RefClaim__r hop → Claim → LossDate__c
     *
     * Returns null when baseSObjectType is not set or resolution fails.
     */
    private Schema.DisplayType resolveFieldType(String fieldPath) {
        if (baseSObjectType == null)
            return null;

        try {
            List<String> parts = fieldPath.split('\\.');
            Schema.SObjectType currentType = baseSObjectType;

            // Navigate through relationship parts (all except the last)
            for (Integer i = 0; i < parts.size() - 1; i++) {
                Schema.SObjectField lookupField = findFieldByRelName(currentType, parts[i]);
                if (lookupField == null)
                    return null;

                List<Schema.SObjectType> refs = lookupField.getDescribe().getReferenceTo();
                if (refs.isEmpty())
                    return null;
                currentType = refs[0];
            }

            // Resolve the leaf field
            String leafName = parts[parts.size() - 1];
            Schema.SObjectField leaf = currentType.getDescribe().fields.getMap().get(leafName.toLowerCase());
            return leaf != null ? leaf.getDescribe().getType() : null;
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * Finds the SObjectField whose relationship name matches the given value.
     */
    private Schema.SObjectField findFieldByRelName(Schema.SObjectType sObjType, String relName) {
        for (Schema.SObjectField f : sObjType.getDescribe().fields.getMap().values()) {
            if (f.getDescribe().getRelationshipName() == relName) {
                return f;
            }
        }
        return null;
    }

    // ═══════════════════════════════════════════════════════════════════════
    //  Private — value casting
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Converts a SOQL field path to a valid bind-variable key.
     * Dots (from relationship notation like 'RefClaim__r.Name') are replaced
     * with underscores so the key is a valid SOQL bind identifier.
     */
    private static String toBindKey(String field) {
        return field.contains('.') ? field.replace('.', '_') : field;
    }

    /**
     * Auto-casts string values to Date / Datetime when they match ISO patterns.
     * Non-string values pass through unchanged.
     */
    private Object castValue(Object value) {
        if (!(value instanceof String)) {
            return value;
        }

        String s = (String) value;

        // yyyy-MM-dd  →  Date
        if (DATE_PATTERN.matcher(s).matches()) {
            return Date.valueOf(s);
        }

        // yyyy-MM-ddT…  →  Datetime  (handles Z, +09:00, etc.)
        if (DATETIME_PATTERN.matcher(s).find()) {
            return (Datetime) JSON.deserialize('"' + s + '"', Datetime.class);
        }

        return s;
    }
}

/**
 * ═══════════════════════════════════════════════════════════════════════════
 *  Example — Sample JSON input & resulting WHERE clause
 * ═══════════════════════════════════════════════════════════════════════════
 *  Input JSON:
 *  {
 *    "BankAccount__c"      : null,
 *    "Status__c"           : ["None", "Clear"],
 *    "TransactionDate__c"  : { "from": "2026-02-01", "to": "2026-02-28" },
 *    "Currency__c"         : "USD",
 *    "AccountName__c"      : "001JO00000Gw7ceYAB",
 *    "OriginAmount__c"     : 253900,
 *    "Depositor__c"        : "TestDepo"
 *  }
 *
 *  Processing per field:
 *    BankAccount__c      → null          → skipped
 *    Status__c           → list          → IN clause
 *    TransactionDate__c  → range object  → date strings auto-cast to Date
 *    Currency__c         → plain string  → equality
 *    AccountName__c      → plain string  → equality
 *    OriginAmount__c     → Decimal       → equality
 *    Depositor__c        → plain string  → equality
 *
 *  toWhereClause() result:
 *    Status__c IN :Status__c_in
 *    AND TransactionDate__c >= :TransactionDate__c_from
 *    AND TransactionDate__c <= :TransactionDate__c_to
 *    AND Currency__c = :Currency__c
 *    AND AccountName__c = :AccountName__c
 *    AND OriginAmount__c = :OriginAmount__c
 *    AND Depositor__c = :Depositor__c
 *
 *  getBinds() result:
 *    {
 *      Status__c_in            → ['None', 'Clear'],
 *      TransactionDate__c_from → Date(2026-02-01),
 *      TransactionDate__c_to   → Date(2026-02-28),
 *      Currency__c             → 'USD',
 *      AccountName__c          → '001JO00000Gw7ceYAB',
 *      OriginAmount__c         → 253900,
 *      Depositor__c            → 'TestDepo'
 *    }
 */