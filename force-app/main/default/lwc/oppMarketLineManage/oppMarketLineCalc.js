/**********************************************************************************
 * @filename      : oppMarketLineCalc.js
 * @description   : oppMarketLineManage 컴포넌트의 계산식 처리 로직 분리
 **********************************************************************************/

/**
 * 계산식 컴파일 및 의존성 분석 초기화
 * @param {Array} columns - 그리드 컬럼 메타데이터
 * @param {Array} calcRules - 서버에서 받은 계산 규칙 리스트
 * @param {Object} ctx - 컨텍스트 변수 (ctx_*)
 * @returns {Object} { calcRules, calcRulesByDependencyKey }
 */
export function initCalcRules(columns, calcRules, ctx) {
    const rules = Array.isArray(calcRules) ? calcRules.map(r => ({ ...r })) : [];
    
    _compileCalcRules(columns, rules, ctx);
    const rulesByKey = _buildCalcRulesByDependencyKey(rules);

    return {
        calcRules: rules,
        calcRulesByDependencyKey: rulesByKey
    };
}

/**
 * 로드 시 계산식 유효성 검사
 * @param {Array} calcRules 
 * @returns {Array} errors
 */
export function validateCalcRulesOnLoad(calcRules) {
    const errors = [];
    for (const rule of (calcRules || [])) {
        if (!rule?.targetKey) continue;

        if (rule._compileError) {
            errors.push({ targetKey: rule.targetKey, expression: rule.expression, error: rule._compileError });
            continue;
        }

        if (typeof rule._compiledFunction !== 'function') {
            errors.push({ targetKey: rule.targetKey, expression: rule.expression, error: 'compiled function is null' });
            continue;
        }

        try {
            const get = () => 0;
            const nvl = (v, d) => (v === null || v === undefined || v === '') ? d : v;
            const round = (v, digits) => {
                const num = (typeof v === 'number') ? v : Number(v);
                if (Number.isNaN(num)) return null;
                const d = (digits === null || digits === undefined) ? 0 : Number(digits);
                const factor = Math.pow(10, d);
                return Math.round(num * factor) / factor;
            };
            const choose = (value, ...args) => {
                if (value === null || value === undefined || String(value).trim() === '') return null;
                const defaultValue = (args.length % 2 === 1) ? args[args.length - 1] : null;
                const pairLength = (args.length % 2 === 1) ? args.length - 1 : args.length;
                for (let i = 0; i < pairLength; i += 2) {
                    if (value === args[i]) return args[i + 1];
                }
                return defaultValue;
            };
            rule._compiledFunction(get, nvl, round, choose);
        } catch (error) {
            errors.push({ targetKey: rule.targetKey, expression: rule.expression, error: error?.message || String(error) });
        }
    }
    return errors;
}

/**
 * 특정 필드 변경 시 영향받는 계산식 적용
 * @param {Object} row - 현재 행 데이터
 * @param {String} changedKey - 변경된 필드 키
 * @param {Array} calcRules - 전체 계산 규칙
 * @param {Object} calcRulesByDependencyKey - 의존성 맵
 * @param {Object} ctx - 컨텍스트 변수
 * @returns {Object} updatedRow
 */
export function applyCalcRulesForChange(row, changedKey, calcRules, calcRulesByDependencyKey, ctx) {
    // console.log('applyCalcRulesForChange called', changedKey);
    // console.log('CTX:', JSON.stringify(ctx));
    if (!row || !changedKey || !calcRules || !calcRules.length) return row;
    // if (!row || !changedKey || !calcRules || !calcRules.length || ctx?.ctx_isTreaty) return row;

    // 동적 TSI 값 주입
    const dynamicCtx = _buildDynamicCtx(row, ctx);
    // console.log('Row Currency:', row.Currency__c);
    // console.log('Current TSI:', currentTSI);
    // console.log('BrkgBase__c Value:', row.BrkgBase__c, 'Type:', typeof row.BrkgBase__c);
    // console.log('GrossPremDP__c Value:', row.GrossPremDP__c, 'Type:', typeof row.GrossPremDP__c);
    // console.log('🧮🧮🧮🧮🧮🧮🧮 CobrokingType__c Value:', row.CobrokingType__c, ', Type:', typeof row.CobrokingType__c);
    // console.log('🧮🧮🧮🧮🧮🧮🧮 PlacingSettlementType__c Value:', row.PlacingSettlementType__c, ', Type:', typeof row.PlacingSettlementType__c);
    // console.log('🧮🧮🧮🧮🧮🧮🧮 CoBroker_lk__c Value:', row.CoBroker_lk__c, ', Type:', typeof row.CoBroker_lk__c);

    const affectedRules = _collectAffectedCalcRules(changedKey, calcRulesByDependencyKey);
    // console.log('Affected Rules:', affectedRules.map(r => r.targetKey));
    if (!affectedRules.length) return row;

    affectedRules.sort((a, b) => (a?.executionOrder ?? 999999) - (b?.executionOrder ?? 999999));

    let updatedRow = { ...row };

    for (const rule of affectedRules) {
        const targetKey = rule?.targetKey;
        const compiledFunction = rule?._compiledFunction;
        if (!targetKey || typeof compiledFunction !== 'function') continue;

        // overwriteWhenEmptyOnly 옵션
        if (rule?.overwriteWhenEmptyOnly) {
            const currentValue = updatedRow[targetKey];
            const hasValue = !(currentValue === null || currentValue === undefined || currentValue === '');
            if (hasValue) continue;
        }
        // console.log(`🧮🧮🧮🧮🧮🧮🧮 Calc dynamicCtx:`, dynamicCtx); // 결과값 확인
        // console.log(`🧮🧮🧮🧮🧮🧮🧮 Calc rule:`, rule); // 결과값 확인
        const result = _evaluateCalcRule(compiledFunction, updatedRow, dynamicCtx, rule?.scale, rule);
        // console.log(`🧮🧮🧮🧮🧮🧮🧮 Calc Result [${targetKey}]:`, result); // 결과값 확인
        updatedRow[targetKey] = result;
        //updatedRow[targetKey] = _evaluateCalcRule(compiledFunction, updatedRow, dynamicCtx, rule?.scale, rule);
        //updatedRow[targetKey] = _evaluateCalcRule(compiledFunction, updatedRow, ctx, rule?.scale, rule);
    }

    return updatedRow;
}

/**
 * 모든 계산식 일괄 적용 (초기 로드, ctx 변경 시)
 * @param {Object} row 
 * @param {Array} calcRules 
 * @param {Object} ctx 
 * @returns {Object} updatedRow
 */
export function applyAllCalcRules(row, calcRules, ctx) {
    if (!row || !calcRules || !calcRules.length) return row;
    // if (!row || !calcRules || !calcRules.length || ctx?.ctx_isTreaty) return row;

    // 동적 TSI 값 주입
    const dynamicCtx = _buildDynamicCtx(row, ctx);

    const sortedRules = [...calcRules].sort(
        (a, b) => (a?.executionOrder ?? 999999) - (b?.executionOrder ?? 999999)
    );

    let updatedRow = { ...row };
    for (const rule of sortedRules) {
        const targetKey = rule?.targetKey;
        const compiledFunction = rule?._compiledFunction;
        if (!targetKey || typeof compiledFunction !== 'function') continue;

        if (rule?.overwriteWhenEmptyOnly) {
            const currentValue = updatedRow[targetKey];
            const hasValue = !(currentValue === null || currentValue === undefined || currentValue === '');
            if (hasValue) continue;
        }
        // ctx 대신 dynamicCtx 전달
        updatedRow[targetKey] = _evaluateCalcRule(compiledFunction, updatedRow, dynamicCtx, rule?.scale, rule);
        //updatedRow[targetKey] = _evaluateCalcRule(compiledFunction, updatedRow, ctx, rule?.scale, rule);
    }
    return updatedRow;
}

/**
 * BrkgAdj 행 전용 후처리 — calculateSpecialRow(서버) 로직의 클라이언트 미러링
 * applyAllCalcRules 이후 호출하여, BrkgAdj 행의 TotalBrkg__c 및 연쇄 필드를 재산출한다.
 * @param {Array} rows - 전체 행 배열 (applyAllCalcRules 적용 완료 상태)
 * @param {Object} ctx - 컨텍스트
 * @returns {Array} 갱신된 rows
 */
export function recalcBrkgAdjRows(rows, ctx) {
    if (!rows?.length) return rows;

    const brkgIdx = rows.findIndex(r => r.BrkgAdj_is__c === true);
    if (brkgIdx < 0) return rows;

    const brkgRow = { ...rows[brkgIdx] };
    const currency = brkgRow.Currency__c;

    const nvl = (v) => (v == null || v === '' ? 0 : Number(v));

    const hasLKProducingTogetherClient = !!ctx?.ctx_hasLKProducingTogetherClient;
    const hasProducingTogetherClient = !!ctx?.ctx_hasProducingTogetherClient;
    const hasLKPlacingTogether = !!ctx?.ctx_hasLKPlacingTogether;
    const hasLKProducingSeparateNonClient = !!ctx?.ctx_hasLKProducingSeparateNonClient;
    const hasProducingSeparateNonClient = !!ctx?.ctx_hasProducingSeparateNonClient;

    const masterRICommPct = nvl(ctx?.ctx_masterRICommPct) / 100;
    const masterOtherDeductionsPct = nvl(ctx?.ctx_masterOtherDeductionsPct) / 100;
    const masterTotalOrderPct = nvl(ctx?.ctx_masterTotalOrderPct) / 100;

    // const isPlacementDeclaration = !!ctx?.ctx_isPlacementDeclaration;
    const grossPrem = (!!ctx?.ctx_isDeclaration)
        ? nvl(ctx?.ctx_grossPremDeclarationByCurrency?.[currency])
        : nvl(ctx?.ctx_tsiSumByGrossPrem?.[currency]);

    const netToLKPremFromCedant = grossPrem * (1 - masterRICommPct - masterOtherDeductionsPct) * masterTotalOrderPct;

    let sumNetToLKPrem = 0;
    let sumNetProducingCoBroker = 0;

    for (const r of rows) {
        if (r.BrkgAdj_is__c || r.CO_is__c) continue;
        sumNetToLKPrem += nvl(r.NetToLKPrem__c);
        sumNetProducingCoBroker += nvl(r.NetProducingCobrker__c);
    }

    brkgRow.TotalBrkg__c = netToLKPremFromCedant - ((hasLKProducingTogetherClient || hasProducingTogetherClient) ? sumNetProducingCoBroker : sumNetToLKPrem);
    brkgRow.NetProducingCobrker__c = (hasLKProducingTogetherClient || hasProducingTogetherClient) ? brkgRow.TotalBrkg__c : 0;
    brkgRow.ProducingTPPBrkg__c = brkgRow.TotalBrkg__c * (nvl(brkgRow.ProducingSharingPct__c) / 100);
    brkgRow.PlacingTPPBrkge__c = 0;

    const insuredAmt = nvl(ctx?.ctx_tsiSumByCurrency?.[currency]);
    brkgRow.ActualAdjRatePct__c = insuredAmt === 0 ? 0
        : (brkgRow.BrkgBase__c === 'Gross'
            ? (nvl(brkgRow.GrossPremDP__c) / insuredAmt)
            : (((1 - (nvl(brkgRow.RICommPct__c) / 100) - (nvl(brkgRow.OtherDeductionPct__c) / 100)) * nvl(brkgRow.GrossPremDP__c)) / insuredAmt));

    brkgRow.LKProducingTPPBrkg__c = (brkgRow.TotalBrkg__c - brkgRow.PlacingTPPBrkge__c) * (nvl(brkgRow.LKProducingSharingPct__c) / 100);
    brkgRow.LKPlacingTPPBrkg__c = (brkgRow.TotalBrkg__c - brkgRow.ProducingTPPBrkg__c) * (nvl(brkgRow.LKPlacingSharingPct__c) / 100);
    brkgRow.LKReBrkge__c = brkgRow.TotalBrkg__c - brkgRow.ProducingTPPBrkg__c - brkgRow.LKProducingTPPBrkg__c - brkgRow.PlacingTPPBrkge__c - brkgRow.LKPlacingTPPBrkg__c;
    brkgRow.ToProducingAdminFee__c = -(brkgRow.TotalBrkg__c - brkgRow.ProducingTPPBrkg__c) * (nvl(brkgRow.ProducingTPPAdminFeePct__c) / 100);

    brkgRow.NetToLKPrem__c = (hasLKProducingTogetherClient || hasProducingTogetherClient)
        ? (brkgRow.NetProducingCobrker__c - brkgRow.ProducingTPPBrkg__c - brkgRow.LKProducingTPPBrkg__c + brkgRow.ToProducingAdminFee__c)
        : brkgRow.TotalBrkg__c;

    const coBrkPlacingTogether = (brkgRow.CoBroker_lk__c != null && brkgRow.PlacingSettlementType__c === 'Together');
    brkgRow.ToLKAdminFee__c = brkgRow.PlacingTPPBrkge__c * (nvl(brkgRow.PlacingTPPAdminFeePct__c) / 100);
    brkgRow.NetRI__c = (coBrkPlacingTogether || hasLKPlacingTogether) ? 0 : nvl(brkgRow.NetToUW__c);
    brkgRow.NetProducingTPP__c = hasProducingSeparateNonClient ? brkgRow.ProducingTPPBrkg__c : 0;
    brkgRow.LKNetProducingTPP__c = hasLKProducingSeparateNonClient ? brkgRow.LKProducingTPPBrkg__c : 0;
    brkgRow.NetPlacingTPP__c = (coBrkPlacingTogether ? nvl(brkgRow.NetToUW__c) : 0) + brkgRow.PlacingTPPBrkge__c - brkgRow.ToLKAdminFee__c;
    brkgRow.LKNetPlacingTPP__c = (hasLKPlacingTogether ? nvl(brkgRow.NetToUW__c) : 0) + brkgRow.LKPlacingTPPBrkg__c;

    const result = [...rows];
    result[brkgIdx] = brkgRow;
    return result;
}

function _buildDynamicCtx(row, ctx) {
    const currency = row.Currency__c;
    return {
        ...ctx,
        ctx_currentTSI: ctx?.ctx_tsiSumByCurrency?.[currency] || 0,
        ctx_tsiSumDPAdjustable: ctx?.ctx_tsiDPAdjustableByCurrency?.[currency] || 0,
        ctx_tsiSumDPFull: ctx?.ctx_tsiDPFullByCurrency?.[currency] || 0,
        ctx_tsiGrossPremDPAdjustable: ctx?.ctx_tsiGrossPremDPAdjustableByCurrency?.[currency] || 0,
        ctx_tsiGrossPremDPFull: ctx?.ctx_tsiGrossPremDPFullByCurrency?.[currency] || 0,
        ctx_grossPremDeclaration: ctx?.ctx_grossPremDeclarationByCurrency?.[currency] || 0,
        ctx_isSOA: !!ctx?.ctx_isSOAByCurrency?.[currency],
        ctx_tsiGrossPremBfDP: ctx?.ctx_tsiGrossPremBfDPByCurrency?.[currency] || 0,
        ctx_tsiActualAdjAfterDP: ctx?.ctx_tsiActualAdjAfterDPByCurrency?.[currency] || 0,
        ctx_tsiDPAppliedSum: ctx?.ctx_tsiDPAppliedSumByCurrency?.[currency] || 0,
        ctx_tsiGrossPrem: ctx?.ctx_tsiSumByGrossPrem?.[currency] || 0,
    };
}

// =================================================================================================
// Private Helper Functions (Internal Use Only)
// =================================================================================================
function _compileCalcRules(columns, calcRules, ctx) {
    const keySet = new Set((columns || []).map(c => c?.key).filter(Boolean));
    const colTypeMap = new Map((columns || []).filter(c => c?.key).map(c => [c.key, c.type]));

    for (const rule of (calcRules || [])) {
        if (rule?.targetKey) keySet.add(rule.targetKey);
        rule._colType = colTypeMap.get(rule?.targetKey) || null;
        for (const dep of (rule?.dependsOn || [])) if (dep) keySet.add(dep);
    }

    // ctx_* 도 식에서 직접 참조하므로 tokenizing 대상에 포함
    for (const k of Object.keys(ctx || {})) keySet.add(k);
    keySet.add('ctx_currentTSI');
    keySet.add('ctx_tsiSumDPAdjustable');
    keySet.add('ctx_tsiSumDPFull');
    keySet.add('ctx_tsiGrossPremDPAdjustable');
    keySet.add('ctx_tsiGrossPremDPFull');
    keySet.add('ctx_grossPremDeclaration');
    keySet.add('ctx_isSOA');
    keySet.add('ctx_tsiGrossPremBfDP');
    keySet.add('ctx_tsiActualAdjAfterDP');
    keySet.add('ctx_tsiDPAppliedSum');
    keySet.add('ctx_isPlacementEND');
    keySet.add('ctx_proration');
    keySet.add('ctx_tsiGrossPrem');

    const keysForTokenizing = [...keySet].sort((a, b) => b.length - a.length);

    for (const rule of (calcRules || [])) {
        rule._compiledFunction = null;
        rule._compileError = null;

        try {
            rule._compiledFunction = _compileExpressionToFunction(rule?.expression, keysForTokenizing);
        } catch (error) {
            rule._compileError = error?.message || String(error);
            rule._compiledFunction = null;
        }
    }
}

function _compileExpressionToFunction(expression, keysForTokenizing) {
    if (!expression || typeof expression !== 'string') return null;

    const escapedKeys = (keysForTokenizing || [])
        .map(k => k.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'));

    let transformed = expression;

    if (escapedKeys.length) {
        const tokenRegex = new RegExp(`(^|[^\\w])(${escapedKeys.join('|')})(?=[^\\w]|$)`, 'g');
        transformed = transformed.replace(tokenRegex, (match, prefix, token) => {
            return `${prefix}get('${token}')`;
        });
    }

    const fnBody = `return (${transformed});`;
    return new Function('get', 'nvl', 'round', 'choose', fnBody);
}

function _buildCalcRulesByDependencyKey(calcRules) {
    const rulesByDependencyKey = {};
    for (const rule of (calcRules || [])) {
        const dependencies = rule?.dependsOn || [];
        for (const dependencyKey of dependencies) {
            if (!dependencyKey) continue;
            if (!rulesByDependencyKey[dependencyKey]) rulesByDependencyKey[dependencyKey] = [];
            rulesByDependencyKey[dependencyKey].push(rule);
        }
    }
    return rulesByDependencyKey;
}

function _collectAffectedCalcRules(changedKey, rulesByDependencyKey) {
    const rulesMap = rulesByDependencyKey || {};
    const pendingKeys = [changedKey];
    const visitedKeys = new Set();
    const addedTargetKeys = new Set();
    const affectedRules = [];

    while (pendingKeys.length) {
        const currentKey = pendingKeys.shift();
        if (!currentKey || visitedKeys.has(currentKey)) continue;
        visitedKeys.add(currentKey);

        const directlyAffectedRules = rulesMap[currentKey] || [];
        for (const rule of directlyAffectedRules) {
            const targetKey = rule?.targetKey;
            if (!targetKey || addedTargetKeys.has(targetKey)) continue;

            addedTargetKeys.add(targetKey);
            affectedRules.push(rule);

            // targetKey 자체가 다른 rule들의 dependency일 수 있으므로 연쇄 추적
            pendingKeys.push(targetKey);
        }
    }
    return affectedRules;
}

function _evaluateCalcRule(compiledFunction, row, ctx, scale, ruleForLog) {
    const nvl = (value, defaultValue) => {
        if (value === null || value === undefined || value === '') return defaultValue;
        if (typeof value === 'number' && Number.isNaN(value)) return defaultValue;
        return value;
    };

    const round = (value, digits) => {
        const numberValue = (typeof value === 'number') ? value : Number(value);
        if (numberValue === null || numberValue === undefined || Number.isNaN(numberValue)) return null;

        const decimalDigits = (digits === null || digits === undefined) ? 0 : Number(digits);
        const factor = Math.pow(10, decimalDigits);
        return Math.round(numberValue * factor) / factor;
    };

    const get = (key) => {
        // 1) row 우선
        let value = row?.[key];

        // 2) 없으면 ctx_* 에서
        if ((value === undefined || value === null || value === '') && ctx && Object.prototype.hasOwnProperty.call(ctx, key)) {
            value = ctx[key];
        }

        if (typeof value === 'string') {
            const trimmed = value.trim();
            if (trimmed === '') return null;
            const numberValue = Number(trimmed.replace(/,/g, ''));
            if (!Number.isNaN(numberValue) && trimmed.match(/^[+-]?\d+(\.\d+)?$/)) return numberValue;
            return value;
        }
        return value;
    };

    const choose = (value, ...args) => {
        if (value === null || value === undefined || String(value).trim() === '') return null;

        const defaultValue = (args.length % 2 === 1) ? args[args.length - 1] : null;
        const pairLength = (args.length % 2 === 1) ? args.length - 1 : args.length;

        for (let i = 0; i < pairLength; i += 2) {
            if (value === args[i]) return args[i + 1];
        }
        return defaultValue;
    };

    let result;
    try {
        result = compiledFunction(get, nvl, round, choose);
    } catch (error) {
        console.error('CalcRule runtime error', {
            targetKey: ruleForLog?.targetKey,
            expression: ruleForLog?.expression,
            error: error?.message || String(error)
        });
        return null;
    }

    // if (result !== null && result !== undefined && typeof result === 'number' && scale !== null && scale !== undefined) {
    //     result = round(result, scale);
    // }
    if (result !== null && result !== undefined && typeof result === 'number') {
        const isPercent = ruleForLog?._colType === 'percent';
        const finalScale = isPercent ? (scale ?? 2) : (ctx?.currencyScale ?? scale ?? 0);
        result = round(result, finalScale);
    }

    return result;
}