import { LightningElement, api, track } from 'lwc';
import searchMarketItems from '@salesforce/apex/OPP_MarketLineSearchModal_Ctrl.searchMarketItems';
import COM_LBL_SEARCH from '@salesforce/label/c.COM_LBL_SEARCH';
import COM_LBL_SELECT from '@salesforce/label/c.COM_LBL_SELECT';
import COM_LBL_ASOFDATE from '@salesforce/label/c.COM_LBL_ASOFDATE';

export default class OppMarketLineSearchModal extends LightningElement {
    // 📍 1. API 속성 (open 호출 시 전달받음)
    @api type;      // 'Security' (추후 'Reinsurer' 등 확장 가능)
    @api recordId;  // Opportunity Id
    @api parentId;  // MGA Id (for Security)

    labels = {
        COM_LBL_SEARCH,
        COM_LBL_SELECT,
        COM_LBL_ASOFDATE
    };

    // 📍 2. 추적 속성 (반응형)
    @track searchText = '';
    @track rows = [];
    @track columns = []; // 동적 컬럼 정보
    @track periodFromLabel = ''
    @track periodFromDate = null;

    isInit = false;
    isLoading = false;

    // 📍 4. Getter/Setter
    get hasRows() {
        return this.rows && this.rows.length > 0;
    }
    get msgPlaceholder() {
        return this.labels.COM_LBL_SEARCH + ' ...' ;
    }
    get lblNoDataRecords() {
        return this.labels.COM_MSG_NORECORDS;
    }
    // modalLabel은 부모(comModal)에서 처리하거나 필요 시 사용

    // 📍 6. 이벤트 핸들러
    handleSearchChange(event) {
        this.searchText = event.target.value;
    }

    handleKeyUp(event) {
        if (event.keyCode === 13) {
            void this.handleSearch();
        }
    }

    handleSelect(event) {
        const selectedId = event.currentTarget.dataset.id;
        const selectedName = event.currentTarget.dataset.name;
        const facilityParticipantId = event.currentTarget.dataset.facilityParticipantId;

        // 선택 결과 반환 (이벤트 발송)
        this.dispatchEvent(new CustomEvent('select', {
            detail: { id: selectedId, name: selectedName, facilityParticipantId}
        }));
    }

    async handleSearch() {
        this.isLoading = true;
        try {
            const result = await searchMarketItems({
                type: this.type,
                searchText: this.searchText,
                recordId: this.recordId,
                parentId: this.parentId
            });

            this.periodFromLabel = result.periodFromLabel;
            this.periodFromDate = result.periodFromDate;

            this.columns = (result.columns || []).map(col => {
                let alignClass = 'slds-text-align_center'; // 기본값: 중앙

                // Name 컬럼은 왼쪽 정렬
                if (col.fieldName === 'Name') {
                    alignClass = 'slds-text-align_left';
                }

                return { ...col, alignClass };
            });
            this.rows = (result.data || []).map((item, index) => ({
                ...item,
                no: index + 1,
                cells: this.columns.map(col => ({
                    fieldName: col.fieldName,
                    value: item[col.fieldName],
                    alignClass: col.alignClass
                }))
            }));
        } catch (e) {
            console.error(e);
            this.rows = [];
            this.columns = [];
        } finally {
            this.isLoading = false;
        }
    }

    // 📍 8. 라이프사이클 메서드
    connectedCallback() {
        if(this.isInit) return;
        void this.handleSearch();
        this.isInit = true;
    }
}