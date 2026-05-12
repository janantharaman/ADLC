/**********************************************************************************
 * @filename      : oppMarketLineTextEditorModal.js
 * @project-name  : LK보험중계_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-01-23 (금)
 * @group         :
 * @group-content :
 * @description   : 
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2026-01-23      i2max      Create
 **********************************************************************************/
import { LightningElement, api, track } from 'lwc';
import COM_MSG_ENTER_CONTENT from '@salesforce/label/c.COM_MSG_ENTER_CONTENT';

export default class OppMarketLineTextEditorModal extends LightningElement {

    labels = {
        COM_MSG_ENTER_CONTENT
    }

    // 📍 1. API 속성 (외부에서 설정 가능)
    @api recordId; // 이미지 업로드 등을 위한 레코드 ID (RichText용)
    
    @api
    get value() {
        return this._value;
    }
    set value(v) {
        this._value = v || '';
    }

    @api mode = 'text'; // 'text' | 'rich'
    @api isReadOnly = false;

    // 부모가 저장 버튼 클릭 시 호출하여 현재 값을 가져갈 수도 있음
    @api
    getValue() {
        return this._value;
    }

    // 📍 2. 추적 속성 (반응형)
    @track _value = '';

    // 📍 3. Private 속성

    // 📍 4. Getter/Setter
    get isRichText() {
        return this.mode === 'rich';
    }

    // 📍 5. Wire 메서드

    // 📍 6. 이벤트 핸들러
    handleChange(event) {
        this._value = event.detail.value; // RichText
        this._dispatchChange();
    }

    handleAutoGrow(event) {
        const el = event.target;
        
        // 1. 값 업데이트 (표준 textarea는 event.target.value)
        this._value = el.value;
        this._dispatchChange();

        // 2. 높이 조절
        el.style.height = 'auto'; // 높이 초기화 (줄어들 때를 대비)
        el.style.height = (el.scrollHeight) + 'px'; // 내용만큼 늘리기
    }

    // 📍 7. Private 메서드
    _dispatchChange() {
        this.dispatchEvent(new CustomEvent('change', {
            detail: { value: this._value }
        }));
    }

    // 📍 8. 라이프사이클 메서드
    renderedCallback() {
        // 초기 로드 시 높이 조절 (표준 textarea 사용 시 유효)
        if (!this.isRichText) {
            const textarea = this.template.querySelector('textarea');
            if (textarea) {
                // 초기값 설정 (표준 태그는 value 속성 바인딩이 단방향일 수 있음)
                // 렌더링 시점에 textarea.value가 비어있다면 _value로 채움
                if (textarea.value !== this._value) {
                    textarea.value = this._value || '';
                }
                textarea.style.height = 'auto';
                textarea.style.height = (textarea.scrollHeight) + 'px';
            }
        }
    }

    connectedCallback() {
    }

    disconnectedCallback() {
    }
}