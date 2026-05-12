/**********************************************************************************
 * @filename      : comUi.js
 * @project-name  : LK보험중계_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-01-02 (금)
 * @group         :
 * @group-content :
 * @description   : toast, navigation, format 등 UI 유틸
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2026-01-02      i2max      Create
 **********************************************************************************/
import Toast from 'lightning/toast';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getFieldValue as getLwcFieldValue } from 'lightning/uiRecordApi';
import ComConfirmModal from 'c/comConfirmModal';
import COM_LBL_NOTICE from '@salesforce/label/c.COM_LBL_NOTICE';

/**
 * toast(cmp, title, message?, variant?, mode?, channel?)
 * - cmp: this (생략 가능. 생략 시 첫번째 인자가 title로 인식됨)
 * - channel: 'toast' | 'event'
 * - mode: 'dismissible' | 'sticky' | 'pester'
 *
 * @example
 * // 1. 간단 사용 (cmp 생략, 자동 사라짐)
 * toast('저장 성공', '데이터가 저장되었습니다.');
 * toast('오류 발생', '필수 항목을 입력하세요.', 'error');
 *
 * // 2. cmp 포함 (기존 방식)
 * toast(this, '알림', '메시지');
 *
 * // 3. 옵션 사용 (sticky: 닫기 전까지 유지)
 * toast('경고', '중요한 알림입니다.', 'warning', 'sticky');
 */
export function toast(arg1, arg2, arg3, arg4, arg5, arg6) {
    let cmp = arg1;
    let title = arg2;
    let message = arg3;
    let variant = arg4;
    let mode = arg5;
    let channel = arg6;

    const VARIANTS = ['info', 'success', 'warning', 'error'];

    // 1. 첫 번째 인자가 문자열이면 cmp가 생략된 것 (toast('Title', 'Msg', ...))
    if (typeof arg1 === 'string') {
        cmp = null;
        title = arg1;
        message = arg2;
        variant = arg3;
        mode = arg4;
        channel = arg5;
    }

    // 2. 스마트 추론: (cmp, msg, variant) 형태인지 확인
    // 조건: title 자리에 문자열이 있고, message 자리에 variant 키워드가 있는 경우
    // 예: toast(this, '저장했습니다.', 'success')
    // 예: toast('저장했습니다.', 'success') -> 위 1번 로직 후 title='저장', msg='success' 상태임
    if (typeof title === 'string' && VARIANTS.includes(message)) {
        // toast(this, 'Msg', 'Type') 패턴
        variant = message;
        message = title;
        title = COM_LBL_NOTICE;
    } else if (typeof title === 'string' && VARIANTS.includes(arg2) && cmp === null) {
        // toast('Msg', 'Type') 패턴 (위 1번 로직을 탔을 때 arg2가 variant인 경우)
        // 1번 로직에서 title=arg1('Msg'), message=arg2('Type')가 된 상태
        // 하지만 arg2가 variant라면? -> title은 Notice가 되고, message는 arg1이 되어야 함
        variant = arg2;
        message = arg1;
        title = COM_LBL_NOTICE;
    }

    // 기본값 처리
    if (!message) message = '';
    if (!variant) variant = 'info';
    if (!mode) mode = 'dismissible';
    if (!channel) channel = 'toast';

    // Toast.show 용 config
    const config = {
        label: title || COM_LBL_NOTICE, // title이 없으면 기본값 Notice
        message: message,
        variant: variant
    };

    // title이 명시적으로 빈 문자열('')인 경우 -> 공백(' ')으로 치환하여 제목 숨김 처리
    if (title === '') {
        config.label = ' ';
    }

    if (mode === 'dismissible' || mode === 'sticky') {
        config.mode = mode;
    }

    // cmp가 있고 channel이 event인 경우에만 이벤트 발송
    if (cmp && channel === 'event') {
        try {
            const eventConfig = {
                message: message,
                variant: variant,
                mode: mode
            };
            if (config.label && config.label !== ' ') eventConfig.title = config.label;

            cmp.dispatchEvent(new ShowToastEvent(eventConfig));
            return;
        } catch (error) {
            // 실패 시 아래 Toast.show로 fallback
        }
    }

    // cmp가 없거나, channel이 toast거나, event 실패 시
    Toast.show(config, cmp || undefined);
}

/**
 * confirm(message, label?, theme?)
 * 비동기로 동작하며 true(확인)/false(취소)를 반환합니다.
 *
 * @example
 * // 1. 기본 사용
 * if (await confirm('저장하시겠습니까?')) {
 *     // 저장 로직
 * }
 *
 * // 2. 제목 및 테마 지정
 * const isOk = await confirm('삭제하시겠습니까?', '삭제 확인', 'warning');
 * if (isOk) { ... }
 */
export async function confirm(message, label = '확인', theme = 'default') {
    const result = await ComConfirmModal.open({
        label,
        message,
        theme,
        size: 'small'
    });
    return result === true;
}


/**
 * 에러 객체에서 사용자 친화적인 메시지를 추출합니다.
 * Apex 호출 에러, JS 에러 등 다양한 형식을 지원합니다.
 *
 * @param {object|string} errors - 에러 객체 또는 에러 배열
 * @returns {string[]} 에러 메시지 배열
 *
 * @example
 * .catch(error => {
 *     const msgs = reduceErrors(error);
 *     toast('오류', msgs.join(', '), 'error');
 * });
 */
export function reduceErrors(errors) {
    if (!errors) {
        return [];
    }
    if (typeof errors === 'string') {
        return [errors];
    }
    if (Array.isArray(errors)) {
        return errors.filter((error) => !!error)
            .map((error) => reduceErrors(error))
            .flat();
    }

    // 1. JS Error 객체
    if (errors instanceof Error) {
        return [errors.message];
    }

    // 2. Apex Error (body.message)
    if (errors.body && typeof errors.body.message === 'string') {
        return [errors.body.message];
    }

    // 3. Apex Error (body.pageErrors)
    if (errors.body && Array.isArray(errors.body.pageErrors) && errors.body.pageErrors.length > 0) {
        return errors.body.pageErrors.map((e) => e.message);
    }

    // 4. Apex Error (body.fieldErrors)
    if (errors.body && errors.body.fieldErrors && Object.keys(errors.body.fieldErrors).length > 0) {
        const fieldErrors = [];
        Object.values(errors.body.fieldErrors).forEach((errorArray) => {
            fieldErrors.push(...errorArray.map((e) => e.message));
        });
        return fieldErrors;
    }

    // 5. 일반 message 속성
    if (typeof errors.message === 'string') {
        return [errors.message];
    }

    // 6. statusText (fetch 등)
    if (typeof errors.statusText === 'string') {
        return [errors.statusText];
    }

    return ['알 수 없는 오류가 발생했습니다.'];
}

/**
 * 레코드 데이터에서 필드 값을 안전하게 추출합니다.
 * 표준 getFieldValue를 래핑하여 문자열 경로('Account.Name') 접근을 지원합니다.
 *
 * @param {object} data - getRecord로 가져온 데이터 객체
 * @param {object|string} field - 필드 임포트 객체 또는 필드 경로 문자열
 * @returns {any} 필드 값 (없으면 undefined)
 *
 * @example
 * // 1. 표준 방식 (필드 임포트 사용)
 * import NAME_FIELD from '@salesforce/schema/Account.Name';
 * const name = getFieldValue(data, NAME_FIELD);
 *
 * // 2. 문자열 경로 사용 (편의성)
 * const ownerName = getFieldValue(data, 'Owner.Name');
 * const city = getFieldValue(data, 'BillingAddress.city');
 */
export function getFieldValue(data, field) {
    if (!data) return undefined;

    // 1. 표준 필드 객체인 경우 (import된 필드)
    if (typeof field === 'object' && field.fieldApiName) {
        return getLwcFieldValue(data, field);
    }

    // 2. 문자열 경로인 경우 ('Account.Name')
    if (typeof field === 'string') {
        const split = field.split('.');
        let current = data.fields || data; // data 구조에 따라 유연하게 대응

        // data가 바로 fields를 가지고 있지 않은 경우(표준 응답 구조)를 위해 조정
        if (data.fields) {
            current = data.fields;
        }

        for (let i = 0; i < split.length; i++) {
            const key = split[i];

            // 현재 레벨에 키가 없으면 종료
            if (!current || !current[key]) {
                return undefined;
            }

            // 마지막 키가 아니면 value 속성을 타고 내려가야 함 (Salesforce 응답 구조 특성)
            // 예: Account(참조) -> value -> fields -> Name
            if (i < split.length - 1) {
                // 참조 필드인 경우 value 안에 다시 fields가 있을 수 있음
                if (current[key].value && typeof current[key].value === 'object') {
                    current = current[key].value.fields || current[key].value;
                } else {
                    // 구조가 예상과 다르면 중단
                    return undefined;
                }
            } else {
                // 마지막 키: 값 반환 (value 속성 또는 displayValue)
                return current[key].displayValue || current[key].value;
            }
        }
    }

    return undefined;
}

/**
 * 통화별 설정 (심볼 및 소수점 자릿수)
 */
export const CURRENCY_CONFIG = {
    // 소수점 0자리 (Scale: 0)
    KRW: { symbol: "₩", scale: 0 }, // 대한민국 원
    VND: { symbol: "₫", scale: 0 }, // 베트남 동
    IDR: { symbol: "Rp", scale: 0 }, // 인도네시아 루피아
    CLP: { symbol: "CLP$", scale: 0 }, // 칠레 페소
    JPY: { symbol: "¥", scale: 0 }, // 일본 엔

    // 소수점 2자리 (Scale: 2)
    USD: { symbol: "$", scale: 2 }, // 미국 달러
    EUR: { symbol: "€", scale: 2 }, // 유로 (유럽 연합)
    GBP: { symbol: "£", scale: 2 }, // 영국 파운드
    SGD: { symbol: "S$", scale: 2 }, // 싱가포르 달러
    HKD: { symbol: "HK$", scale: 2 }, // 홍콩 달러
    CNY: { symbol: "¥", scale: 2 }, // 중국 위안
    AUD: { symbol: "A$", scale: 2 }, // 호주 달러
    CAD: { symbol: "C$", scale: 2 }, // 캐나다 달러
    THB: { symbol: "฿", scale: 2 }, // 태국 바트
};

/**
 통화 코드로 소수점 자릿수 반환
 * * @example
 * getCurrencyScale('KRW') // 0
 * getCurrencyScale('USD') // 2
 * getCurrencyScale('XYZ', 3) // 3 (매핑 없을 때 fallback 적용)
 * @param {string} currencyCode - ISO 통화 코드 (e.g., 'USD', 'KRW')
 * @param {number} [fallback=2] - 매핑된 값이 없을 경우 반환할 기본값
 * @returns {number} 소수점 자릿수 (매핑값이 없으면 fallback 값 반환)
 */
export function getCurrencyScale(currencyCode, fallback = 2) {
    return CURRENCY_CONFIG[currencyCode]?.scale ?? fallback;
}

/**
 * 소수점 자릿수 → input step 값 변환
 * @param {number} scale - 소수점 자릿수
 * @returns {string} '1', '0.01' 등
 */
export function scaleToStep(scale) {
    if (scale <= 0) return '1';
    return (1 / Math.pow(10, scale)).toFixed(scale);
}

/**
 * 금액을 통화별 소수점 설정(Scale)에 맞춰 포맷팅 (세 자리 콤마 포함)
 * * @example
 * formatCurrency(1234.5, 'KRW');            // "1,235" (0자리, 반올림)
 * formatCurrency(1234.5, 'USD');            // "1,234.50" (2자리 고정)
 * formatCurrency(1234.5, 'JPY');            // "1,234.50" (설정된 2자리 적용)
 * formatCurrency(1234.567, 'VND');          // "1,235" (0자리)
 * formatCurrency(1234.5, 'USD', true);      // "$1,234.50" (심볼 포함)
 * @param {number|string} amount - 포맷팅할 금액 (숫자형 또는 숫자 문자열)
 * @param {string} currencyCode - ISO 통화 코드 (예: 'KRW', 'USD')
 * @param {boolean} [showSymbol=false] - 심볼($, ₩ 등) 표시 여부
 * @returns {string} 포맷팅된 문자열. 유효하지 않은 숫자일 경우 "0" 반환.
 */
export function formatCurrency(amount, currencyCode, showSymbol = false) {
    const num = Number(amount);
    if (isNaN(num)) return "0";

    const scale = getCurrencyScale(currencyCode);
    const symbol = CURRENCY_CONFIG[currencyCode]?.symbol ?? "";
    const formatted = num.toLocaleString("en-US", {
        minimumFractionDigits: scale,
        maximumFractionDigits: scale,
    });

    return showSymbol ? `${symbol}${formatted}` : formatted;
}