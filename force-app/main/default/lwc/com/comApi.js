/**********************************************************************************
 * @filename      : comApi.js
 * @project-name  : LK보험중계_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-01-02 (금)
 * @group         :
 * @group-content :
 * @description   : Apex 호출 래퍼(에러 표준화 포함), UI Record API(create/update/delete) 래퍼
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2026-01-02      i2max      Create
 **********************************************************************************/
import { toast, reduceErrors } from './comUi';

/**
 * callApex(this, apexMethod, params?, options?)
 * - apexMethod: import된 Apex 메서드 레퍼런스 (@salesforce/apex/Cls.method)
 *
 * @example
 * import getContactList from '@salesforce/apex/ContactController.getContactList';
 *
 * // 기본 사용 (에러 시 자동 토스트)
 * const contacts = await callApex(this, getContactList, { accountId: '001...' });
 *
 * // 에러 토스트 끄기
 * try {
 *     await callApex(this, getContactList, {}, { toastOnError: false });
 * } catch (e) {
 *     // 직접 처리
 * }
 */
export async function callApex(
    cmp,
    apexMethod,
    params = {},
    { toastOnError = true, toastTitle = 'Error' } = {}
) {
    try {
        return await apexMethod(params);
    } catch (e) {
        if (toastOnError && cmp) {
            // reduceErrors는 배열을 반환하므로 join으로 합침
            const msgs = reduceErrors(e).join(', ');
            toast(cmp, toastTitle, msgs, 'error');
        }
        throw e;
    }
}