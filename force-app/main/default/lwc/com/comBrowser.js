/**********************************************************************************
 * @filename      : comBrowser.js
 * @project-name  : LK보험중계_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-01-02 (금)
 * @group         :
 * @group-content :
 * @description   : fullscreen 같은 브라우저 API 유틸
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2026-01-02      i2max      Create
 **********************************************************************************/
let _bodyOverflowBackup = null;
let _escHandler = null; // ESC 키 핸들러 저장용

function lockBodyScroll(lock) {
    try {
        if (lock) {
            if (_bodyOverflowBackup == null) _bodyOverflowBackup = document.body.style.overflow;
            document.body.style.overflow = 'hidden';
        } else {
            if (_bodyOverflowBackup != null) document.body.style.overflow = _bodyOverflowBackup;
            _bodyOverflowBackup = null;
        }
    } catch (error) {
        console.error('lockBodyScroll error', error);
    }
}

/**
 * 클립보드에 텍스트 복사
 * 최신 API(navigator.clipboard)를 우선 사용하고, 실패 시 execCommand로 대체
 *
 * @param {string} text - 복사할 텍스트
 * @returns {Promise<boolean>} 성공 여부
 *
 * @example
 * const success = await copyToClipboard('복사할 내용');
 * if (success) {
 *     toast('성공', '클립보드에 복사되었습니다.');
 * }
 */
export async function copyToClipboard(text) {
    if (!text) return false;

    try {
        // 1. 최신 API 시도
        if (navigator.clipboard && navigator.clipboard.writeText) {
            await navigator.clipboard.writeText(text);
            return true;
        }
        throw new Error('Clipboard API unavailable');
    } catch (err) {
        // 2. Fallback: textarea 생성 후 execCommand 사용
        try {
            const textArea = document.createElement('textarea');
            textArea.value = text;

            // 화면 밖으로 숨김 처리
            textArea.style.position = 'fixed';
            textArea.style.left = '-9999px';
            textArea.style.top = '0';

            document.body.appendChild(textArea);
            textArea.focus();
            textArea.select();

            const success = document.execCommand('copy');
            document.body.removeChild(textArea);

            return success;
        } catch (fallbackErr) {
            console.error('copyToClipboard failed', fallbackErr);
            return false;
        }
    }
}

/**
 * CSS 클래스를 이용한 전체화면 토글
 *
 * @example
 * const container = this.template.querySelector('.container');
 * const isFull = togglePseudoFullscreen(container);
 * // isFull: true(켜짐) / false(꺼짐)
 */
export function togglePseudoFullscreen(targetEl, {
    className = 'pseudo-fs',
    lockScroll = true
} = {}) {
    if (!targetEl) throw new Error('togglePseudoFullscreen: targetEl is required');

    const on = targetEl.classList.toggle(className);

    if (lockScroll) lockBodyScroll(on);

    // ESC 키 처리 로직
    if (on) {
        // 1. 포커스 강제 이동 (키보드 이벤트 수신을 위해 필수)
        if (!targetEl.hasAttribute('tabindex')) {
            targetEl.setAttribute('tabindex', '-1');
        }
        targetEl.focus();

        // 2. 핸들러 정리 (안전장치)
        if (_escHandler) window.removeEventListener('keydown', _escHandler, true);

        // 3. 새 핸들러 생성
        _escHandler = (e) => {
            if (e.key === 'Escape' || e.key === 'Esc') {
                e.preventDefault();
                e.stopPropagation();

                // 다시 토글하여 끄기
                togglePseudoFullscreen(targetEl, { className, lockScroll });
            }
        };

        // 4. 캡처링 단계(true)에서 이벤트 감지
        window.addEventListener('keydown', _escHandler, true);
    } else {
        // 꺼질 때 핸들러 제거
        if (_escHandler) {
            window.removeEventListener('keydown', _escHandler, true);
            _escHandler = null;
        }
    }

    return on;
}

/**
 * 브라우저 전체화면 토글
 * 지원하지 않거나 에러 발생 시 CSS 기반 전체화면(pseudo)으로 대체
 *
 * @example
 * const container = this.template.querySelector('.video-player');
 * const isFull = await toggleFullscreen(container);
 *
 * // 결과에 따라 아이콘 변경 등 처리
 * if (isFull) {
 *     this.iconName = 'utility:contract_alt';
 * } else {
 *     this.iconName = 'utility:expand_alt';
 * }
 */
export async function toggleFullscreen(targetEl, opts = {}) {
    try {
        // 이미 전체화면인지 확인
        const isFullscreen = document.fullscreenElement ||
            document.webkitFullscreenElement ||
            document.mozFullScreenElement ||
            document.msFullscreenElement;

        if (isFullscreen) {
            // 전체화면 끄기
            const exit = document.exitFullscreen ||
                document.webkitExitFullscreen ||
                document.mozCancelFullScreen ||
                document.msExitFullscreen;
            if (exit) {
                await exit.call(document);
                return false; // 꺼짐
            }
        } else {
            // 전체화면 켜기
            const req = targetEl?.requestFullscreen ||
                targetEl?.webkitRequestFullscreen ||
                targetEl?.mozRequestFullScreen ||
                targetEl?.msRequestFullscreen;

            if (typeof req !== 'function') throw new Error('requestFullscreen not available');
            await req.call(targetEl);
            return true; // 켜짐
        }
    } catch (error) {
        console.warn('toggleFullscreen failed, fallback to pseudo', error);
        return togglePseudoFullscreen(targetEl, opts);
    }
}