const COLUMN_MAP = [
    { uploadColumn: "입금일", sliField: "TransactionDate__c", type: "date", required: true },
    { uploadColumn: "원수사 ERP Code", sliField: "Insurer_lk__c", type: "lookup", required: true },
    { uploadColumn: "계약일", sliField: "InceptionDate__c", type: "date", required: true },
    { uploadColumn: "증권번호", sliField: "PolicyNo__c", type: "text", required: false },
    { uploadColumn: "계약자", sliField: "PolicyHolder__c", type: "text" },
    { uploadColumn: "계약자 ERP Code", sliField: "PolicyHolder_lk__c", type: "lookup", required: true },
    {
        uploadColumn: "보험종목",
        sliField: "LOB3__c",
        type: "picklist",
        objectApiName: "StatementLineItem__c",
        fieldApiName: "LOB3__c",
        required: true
    },
    { uploadColumn: "상품명", sliField: "LOBDetails__c", type: "text", required: false },
    { uploadColumn: "보험료", sliField: "Premium__c", type: "number", required: true },
    { uploadColumn: "수수료", sliField: "Brokerage__c", type: "number", required: true },
    { uploadColumn: "수수료율", sliField: "BrokerageRatePct__c", type: "percent", required: true },
    { uploadColumn: "비고", sliField: "Remarks__c", type: "text", required: false },
    { uploadColumn: "팀", sliField: "Team__c", type: "text", required: true }
];

const EXPECTED_COLUMNS = COLUMN_MAP.filter((col) => col.required).map((col) => col.uploadColumn);

// ── Excel Read ──────────────────────────────────────────────────────────────

function readExcel(XLSX, file) {
    return new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.onload = () => {
            try {
                const workbook = XLSX.read(reader.result, { type: "array", cellDates: true });
                const sheet = workbook.Sheets[workbook.SheetNames[0]];
                const data = XLSX.utils.sheet_to_json(sheet, { header: 1, raw: true });
                resolve(data);
            } catch (e) {
                reject(e);
            }
        };
        reader.onerror = reject;
        reader.readAsArrayBuffer(file);
    });
}

// ── Date Utilities ──────────────────────────────────────────────────────────

function excelSerialToDate(serial) {
    const dateInfo = new Date(Math.round((serial - 25569) * 86400 * 1000));
    const offset = dateInfo.getTimezoneOffset() * 60 * 1000;
    return new Date(dateInfo.getTime() + offset);
}

function formatDate(dateVal) {
    if (!dateVal) return "";
    const d = dateVal instanceof Date ? dateVal : new Date(dateVal);
    if (isNaN(d.getTime())) return String(dateVal);
    const pad = (n) => String(n).padStart(2, "0");
    return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
}

// ── Validation ──────────────────────────────────────────────────────────────

function validateAndExtractRows(sheetData, picklistValuesCache) {
    const headers = sheetData[0].map((h) => String(h || "").trim());

    // Validate required columns
    const missingColumns = EXPECTED_COLUMNS.filter((col) => !headers.includes(col));
    if (missingColumns.length > 0) {
        return { error: `필수 컬럼이 누락되었습니다: ${missingColumns.join(", ")}` };
    }

    // Build column index map
    const colIndexMap = {};
    COLUMN_MAP.forEach((col) => {
        colIndexMap[col.uploadColumn] = headers.indexOf(col.uploadColumn);
    });

    const errors = [];
    const erpCodesToResolve = new Set();
    const rawRows = [];

    for (let i = 1; i < sheetData.length; i++) {
        const row = sheetData[i];
        if (!row || !row.length || row.every((cell) => cell == null || String(cell).trim() === "")) continue;

        const rowNum = i + 1;
        const rawRow = { _rowNumber: rowNum };

        for (const col of COLUMN_MAP) {
            let cellValue = row[colIndexMap[col.uploadColumn]];

            // Handle Date objects from SheetJS
            if (col.type === "date" && cellValue instanceof Date) {
                cellValue = formatDate(cellValue);
            } else if (col.type === "date" && typeof cellValue === "number") {
                cellValue = formatDate(excelSerialToDate(cellValue));
            }

            const cellStr = cellValue != null ? String(cellValue).trim() : "";

            // Empty check (required only)
            if (!cellStr) {
                if (col.required) {
                    errors.push({
                        rowNumber: rowNum,
                        column: col.uploadColumn,
                        message: `${col.uploadColumn} 값이 비어있습니다.`
                    });
                }
                continue;
            }

            rawRow[col.uploadColumn] = col.type === "number" || col.type === "percent" ? cellValue : cellStr;

            // Type-specific validation
            switch (col.type) {
                case "date":
                    if (!/^\d{4}-\d{2}-\d{2}$/.test(cellStr)) {
                        errors.push({
                            rowNumber: rowNum,
                            column: col.uploadColumn,
                            message: `날짜 형식이 올바르지 않습니다. (YYYY-MM-DD)`
                        });
                    }
                    break;
                case "number": {
                    if (typeof cellValue === "number") break;
                    if (!/^-?[\d,.]+$/.test(cellStr)) {
                        errors.push({
                            rowNumber: rowNum,
                            column: col.uploadColumn,
                            message: `숫자 형식이 올바르지 않습니다.`
                        });
                    } else {
                        const cleaned = cellStr.replace(/,/g, "");
                        if (isNaN(Number(cleaned))) {
                            errors.push({
                                rowNumber: rowNum,
                                column: col.uploadColumn,
                                message: `숫자 형식이 올바르지 않습니다.`
                            });
                        }
                    }
                    break;
                }
                case "percent": {
                    if (typeof cellValue === "number") break;
                    const pctStr = cellStr.replace(/%/g, "").trim();
                    if (!/^-?[\d,.]+$/.test(pctStr)) {
                        errors.push({
                            rowNumber: rowNum,
                            column: col.uploadColumn,
                            message: `퍼센트 형식이 올바르지 않습니다.`
                        });
                    } else {
                        const cleaned = pctStr.replace(/,/g, "");
                        if (isNaN(Number(cleaned))) {
                            errors.push({
                                rowNumber: rowNum,
                                column: col.uploadColumn,
                                message: `퍼센트 형식이 올바르지 않습니다.`
                            });
                        }
                    }
                    break;
                }
                case "picklist": {
                    const plCache = picklistValuesCache[col.uploadColumn];
                    if (plCache && !plCache.validLabels.has(cellStr) && !plCache.validValues.has(cellStr)) {
                        errors.push({
                            rowNumber: rowNum,
                            column: col.uploadColumn,
                            message: `유효하지 않은 값입니다. (${cellStr})`
                        });
                    }
                    break;
                }
                case "lookup":
                    erpCodesToResolve.add(cellStr);
                    break;
                default:
                    break;
            }
        }
        rawRows.push(rawRow);
    }

    return { errors, rawRows, erpCodesToResolve };
}

// ── Lookup Validation ───────────────────────────────────────────────────────

function validateLookups(rawRows, accountMap) {
    const errors = [];
    const lookupColumns = COLUMN_MAP.filter((c) => c.type === "lookup");
    for (const rawRow of rawRows) {
        for (const col of lookupColumns) {
            const erpCode = rawRow[col.uploadColumn];
            if (erpCode && !accountMap[erpCode]) {
                errors.push({
                    rowNumber: rawRow._rowNumber,
                    column: col.uploadColumn,
                    message: `ERP Code를 찾을 수 없습니다. (${erpCode})`
                });
            }
        }
    }
    return errors;
}

// ── Mapping ─────────────────────────────────────────────────────────────────

function mapToSliFields(rawRows, accountMap, picklistValuesCache) {
    return rawRows.map((rawRow) => {
        const record = {};
        for (const col of COLUMN_MAP) {
            const rawValue = rawRow[col.uploadColumn];
            if (rawValue == null) continue;

            switch (col.type) {
                case "date":
                    record[col.sliField] = String(rawValue);
                    break;
                case "number":
                    record[col.sliField] =
                        typeof rawValue === "number" ? rawValue : parseFloat(String(rawValue).replace(/,/g, ""));
                    break;
                case "percent": {
                    if (typeof rawValue === "number") {
                        record[col.sliField] = rawValue;
                    } else {
                        record[col.sliField] = parseFloat(String(rawValue).replace(/%/g, "").replace(/,/g, "").trim());
                    }
                    break;
                }
                case "lookup":
                    record[col.sliField] = accountMap[String(rawValue)];
                    break;
                case "picklist": {
                    const plCache = picklistValuesCache[col.uploadColumn];
                    const strVal = String(rawValue);
                    if (plCache && plCache.validValues.has(strVal)) {
                        record[col.sliField] = strVal;
                    } else if (plCache && plCache.labelToValue.has(strVal)) {
                        record[col.sliField] = plCache.labelToValue.get(strVal);
                    } else {
                        record[col.sliField] = strVal;
                    }
                    break;
                }
                case "text":
                    record[col.sliField] = String(rawValue);
                    break;
                default:
                    break;
            }
        }
        return record;
    });
}

// ── Error Formatting ────────────────────────────────────────────────────────

function formatErrors(errors) {
    const summary = errors
        .slice(0, 5)
        .map((e) => `[Row ${e.rowNumber}] ${e.column}: ${e.message}`)
        .join("\n");
    const suffix = errors.length > 5 ? `\n...외 ${errors.length - 5}건` : "";
    return summary + suffix;
}

export { COLUMN_MAP, readExcel, validateAndExtractRows, validateLookups, mapToSliFields, formatErrors };

//statementParser.js에서 사용된 한글 메시지 목록:

//#	현재 메시지	위치	용도
//1	필수 컬럼이 누락되었습니다: ${missingColumns}	statementParser.js:79	필수 헤더 컬럼 누락
//2	${col.uploadColumn} 값이 비어있습니다.	statementParser.js:103	셀 값 빈값 체크
//3	날짜 형식이 올바르지 않습니다. (YYYY-MM-DD)	statementParser.js:117	날짜 형식 오류
//4	숫자 형식이 올바르지 않습니다.	statementParser.js:125, statementParser.js:131	숫자 형식 오류 (2곳)
//5	퍼센트 형식이 올바르지 않습니다.	statementParser.js:140, statementParser.js:146	퍼센트 형식 오류 (2곳)
//6	유효하지 않은 값입니다. (${cellStr})	statementParser.js:155	픽리스트 값 불일치
//7	ERP Code를 찾을 수 없습니다. (${erpCode})	statementParser.js:180	Lookup 계정 미존재
// line 272

//Custom Label 후보 정리 (중복 제거, 7개):

//Label Name (제안)	Value	비고
//SLI_Upload_Missing_Columns	필수 컬럼이 누락되었습니다: {0}	파라미터: 컬럼명 목록
//SLI_Upload_Empty_Value	{0} 값이 비어있습니다.	파라미터: 컬럼명
//SLI_Upload_Invalid_Date	날짜 형식이 올바르지 않습니다. (YYYY-MM-DD)
//SLI_Upload_Invalid_Number	숫자 형식이 올바르지 않습니다.
//SLI_Upload_Invalid_Percent	퍼센트 형식이 올바르지 않습니다.
//SLI_Upload_Invalid_Picklist	유효하지 않은 값입니다. ({0})	파라미터: 입력값
//SLI_Upload_ERP_Not_Found	ERP Code를 찾을 수 없습니다. ({0})	파라미터: ERP 코드