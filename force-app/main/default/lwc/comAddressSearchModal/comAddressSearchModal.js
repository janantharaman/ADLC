/**********************************************************************************
 * @filename      : comAddressSearchModal.js
 * @project-name  : LK보험중계_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-02-03 (화)
 * @group         :
 * @group-content :
 * @description   :
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2026-02-03      i2max      Create
 **********************************************************************************/
import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import { toast, callApex, reduceErrors } from 'c/com';
import { updateRecord, notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import getAddressInfo from '@salesforce/apex/COM_GoogleMapService.getAddressInfo';
import findGeoInfo from '@salesforce/apex/COM_GoogleMapService.findGeoInfo';

// Custom Labels
import COM_LBL_ROAD_ADDRESS from '@salesforce/label/c.COM_LBL_ROAD_ADDRESS';
import COM_LBL_ROAD_ADDRESS_EXAMPLE from '@salesforce/label/c.COM_LBL_ROAD_ADDRESS_EXAMPLE';
import COM_LBL_ADDRESS_SEARCH from '@salesforce/label/c.COM_LBL_ADDRESS_SEARCH';
import COM_LBL_SEARCH_RESULT from '@salesforce/label/c.COM_LBL_SEARCH_RESULT';
import COM_LBL_LATITUDE from '@salesforce/label/c.COM_LBL_LATITUDE';
import COM_LBL_LONGITUDE from '@salesforce/label/c.COM_LBL_LONGITUDE';
import COM_LBL_COORDINATE_SEARCH from '@salesforce/label/c.COM_LBL_COORDINATE_SEARCH';
import COM_MSG_TARGET_FIELD_NOT_FOUND from '@salesforce/label/c.COM_MSG_TARGET_FIELD_NOT_FOUND';
import COM_MSG_NO_SEARCH_RESULT from '@salesforce/label/c.COM_MSG_NO_SEARCH_RESULT';
import COM_MSG_SEARCH_ERROR from '@salesforce/label/c.COM_MSG_SEARCH_ERROR';
import COM_MSG_SELECT_ADDRESS_REQUIRED from '@salesforce/label/c.COM_MSG_SELECT_ADDRESS_REQUIRED';
import COM_MSG_ADDRESS_LOAD_FAILED from '@salesforce/label/c.COM_MSG_ADDRESS_LOAD_FAILED';
import COM_MSG_ADDRESS_REQUIRED from '@salesforce/label/c.COM_MSG_ADDRESS_REQUIRED';
import COM_MSG_COORDINATES_REQUIRED from '@salesforce/label/c.COM_MSG_COORDINATES_REQUIRED';
import COM_MSG_INVALID_FIELD_TYPE from '@salesforce/label/c.COM_MSG_INVALID_FIELD_TYPE';
import COM_LBL_INCLUDING_KOREAN_ADDRESS from '@salesforce/label/c.COM_LBL_INCLUDING_KOREAN_ADDRESS';

import COM_LBL_SEARCH from '@salesforce/label/c.COM_LBL_SEARCH';
import COM_BTN_CANCEL from '@salesforce/label/c.COM_BTN_CANCEL';
import COM_BTN_SAVE from '@salesforce/label/c.COM_BTN_SAVE';
import COM_MSG_SAVE_SUCCESS from '@salesforce/label/c.COM_MSG_SAVE_SUCCESS';
import COM_MSG_SAVE_FAILED from '@salesforce/label/c.COM_MSG_SAVE_FAILED';

export default class comAddressSearchModal extends NavigationMixin(LightningElement) {

    // Labels
    labels = {
        COM_LBL_ROAD_ADDRESS,
        COM_LBL_ROAD_ADDRESS_EXAMPLE,
        COM_LBL_ADDRESS_SEARCH,
        COM_LBL_SEARCH_RESULT,
        COM_LBL_LATITUDE,
        COM_LBL_LONGITUDE,
        COM_LBL_COORDINATE_SEARCH,
        COM_MSG_TARGET_FIELD_NOT_FOUND,
        COM_MSG_NO_SEARCH_RESULT,
        COM_MSG_SEARCH_ERROR,
        COM_MSG_SELECT_ADDRESS_REQUIRED,
        COM_MSG_ADDRESS_LOAD_FAILED,
        COM_MSG_ADDRESS_REQUIRED,
        COM_MSG_COORDINATES_REQUIRED,
        COM_LBL_SEARCH,
        COM_BTN_CANCEL,
        COM_BTN_SAVE,
        COM_MSG_SAVE_SUCCESS,
        COM_MSG_SAVE_FAILED,
        COM_MSG_INVALID_FIELD_TYPE,
        COM_LBL_INCLUDING_KOREAN_ADDRESS
    };

    // 📍 1. API 속성
    @api recordId;
    @api targetFieldApiName = 'Address__c';

    // 📍 2. 추적 속성
    @track currentData = {};
    @track searchMode = 'ADDRESS';
    @track addressQuery = '';
    @track latQuery = '';
    @track lngQuery = '';

    @track searchResults = null;
    @track selectedResult = null;
    @track isSaveDisabled = true;
    @track searchModeOptions = [];


    // 📍 3. Private 속성
    wiredAddressResult;
    hasGPSField = false;
    hasStateField = false;
    hasAddressKOField = false;
    includeKorean = false;

    // 📍 4. Getter/Setter

    get isAddressMode() {
        return this.searchMode === 'ADDRESS';
    }

    get inputNumStep() {
        return '0.000000000000001';
    }

    get resultCnt() {
        return this.searchResults ? ( '('+ this.searchResults.length + ')') : 0;
    }

    // 📍 5. Wire 메서드
    @wire(getAddressInfo, { recordId: '$recordId', addressField: '$targetFieldApiName' })
    wiredAddress(result) {
        this.wiredAddressResult = result;
        const { error, data } = result;

        if (data) {
            if (data.error === 'TARGET_FIELD_NOT_FOUND') {
                const msg = this.labels.COM_MSG_TARGET_FIELD_NOT_FOUND.replace('{0}', this.targetFieldApiName);
                toast(this, 'Error', msg, 'error');
                this.handleClose();
                return;
            }
            if (data.error === 'INVALID_FIELD_TYPE') {
                toast(this, 'Error', this.labels.COM_MSG_INVALID_FIELD_TYPE, 'error');
                this.handleClose();
                return;
            }

            this.currentData = data;
            this.searchModeOptions = data?.searchModeOptions || [];
            this.hasGPSField = data?.hasGPSField || false;
            this.hasStateField = data?.hasStateField || false;
            this.hasAddressKOField = data?.hasAddressKOField || false;
            this.includeKorean = data?.isKrSearchDefault || false;
            this._initSearchMode();
        } else if (error) {
            console.error('Error loading address info', error);
            this.currentData = {};
            toast(this, 'Error', this.labels.COM_MSG_ADDRESS_LOAD_FAILED, 'error');
        }
    }

    // 📍 6. 이벤트 핸들러
    handleModeChange(event) {
        this.searchMode = event.detail.value;
        this.searchResults = null;
        this.selectedResult = null;
        this.isSaveDisabled = true;
    }

    handleAddressChange(event) { this.addressQuery = event.target.value; }
    handleLatChange(event) { this._handleCoordinateChange(event, 'latQuery'); }
    handleLngChange(event) { this._handleCoordinateChange(event, 'lngQuery'); }
    handleKoreanToggle(event) { this.includeKorean = event.target.checked; }

    _handleCoordinateChange(event, fieldName) {
        // console.log('>>>>>>>>>>>>>> after ', this[fieldName], ', fieldName=['+ fieldName +']')
        let val = event.target.value;
        if (val && val.includes('.')) {
            const parts = val.split('.');
            if (parts[1].length > 15) {
                val = parts[0] + '.' + parts[1].substring(0, 15);
                event.target.value = val;
            }
        }
        this[fieldName] = val;
        // console.log('>>>>>>>>>>>>>> before ', this[fieldName])
    }

    // 엔터 키 입력 시 검색 실행
    handleEnter(event) {
        if (event.key === 'Enter') {
            void this.handleSearch();
        }
    }

    async handleSearch() {
        if(this.searchMode === 'ADDRESS' && !this.addressQuery?.trim()) {
            toast(this, 'Warning', this.labels.COM_MSG_ADDRESS_REQUIRED, 'warning');
            return;
        }
        if (this.searchMode === 'COORDINATES') {
            const isLatEmpty = this.latQuery === null || this.latQuery === undefined || String(this.latQuery).trim() === '';
            const isLngEmpty = this.lngQuery === null || this.lngQuery === undefined || String(this.lngQuery).trim() === '';

            if (isLatEmpty || isLngEmpty) {
                toast(this, 'Warning', this.labels.COM_MSG_COORDINATES_REQUIRED, 'warning');
                return;
            }
        }

        const request = {
            mode: this.searchMode === 'ADDRESS' ? 'ADDRESS' : 'COORDINATES',
            address: this.addressQuery,
            lat: this.latQuery ? parseFloat(this.latQuery) : null,
            lng: this.lngQuery ? parseFloat(this.lngQuery) : null
        };

        try {
            const resultList = await callApex(this, findGeoInfo, { geoRequest: JSON.stringify(request) });
            if (resultList && resultList.length > 0) {
                if (resultList[0].status !== 'OK') {
                    this.searchResults = [];
                    const msg = resultList[0].errorMessage || this.labels.COM_MSG_NO_SEARCH_RESULT;
                    toast(this, 'Info', msg, 'info');
                } else {
                    // this.searchResults = resultList;
                    // this.selectedResult = null;
                    // this.isSaveDisabled = true;
                    // 한국어 주소 병렬 조회
                    if (this.includeKorean && this.hasAddressKOField) {
                        const koPromises = resultList.map(result => {
                            const koReq = { mode: 'ADDRESS', language: 'ko', address: result.address };
                            // const koReq = { mode: 'ADDRESS', language: 'ko', address: this.addressQuery };
                            return callApex(this, findGeoInfo, { geoRequest: JSON.stringify(koReq) }, { toastOnError: false });
                            // const koReq = { mode: 'COORDINATES', language: 'ko', lat: result.lat, lng: result.lng };
                            // return callApex(this, findGeoInfo, { geoRequest: JSON.stringify(koReq) }, { toastOnError: false });
                        });
                        const koResultsList = await Promise.all(koPromises);
                        resultList.forEach((result, idx) => {
                            const ko = koResultsList[idx];
                            result.addressKo = ko?.[0]?.status === 'OK' ? ko[0].address : '';
                            result.koResult = ko?.[0]?.status === 'OK' ? ko[0] : null;
                        });
                    }

                    this.searchResults = resultList;
                    this.selectedResult = null;
                    this.isSaveDisabled = true;

                }
            } else {
                this.searchResults = [];
                toast(this, 'Info', this.labels.COM_MSG_NO_SEARCH_RESULT, 'info');
            }
        } catch (error) {
            this.searchResults = [];
        }
    }

    handleResultSelect(event) {
        const placeId = event.currentTarget.dataset.id;

        this.template.querySelectorAll('.slds-is-selected').forEach(item => {
            item.classList.remove('slds-is-selected');
        });
        event.currentTarget.classList.add('slds-is-selected');

        // 선택된 객체 저장
        this.selectedResult = this.searchResults.find(item => item.placeId === placeId);
        this.isSaveDisabled = !(this.selectedResult);
    }

    async handleSave() {
        if (!this.selectedResult) {
            toast(this, 'Warning', this.labels.COM_MSG_SELECT_ADDRESS_REQUIRED, 'warning');
            return;
        }

        const fields = {};
        fields['Id'] = this.recordId;

        const baseName = this.targetFieldApiName.replace('__c', '');

        fields[`${baseName}__Street__s`] = this.selectedResult.address || '';
        fields[`${baseName}__City__s`] = this.selectedResult.city || '';
        fields[`${baseName}__PostalCode__s`] = this.selectedResult.postalCode;
        fields[`${baseName}__CountryCode__s`] = this.selectedResult.countryCode;
        fields[`${baseName}__StateCode__s`] = this.selectedResult.stateCode;
        fields[`${baseName}__Latitude__s`] = this.selectedResult.lat;
        fields[`${baseName}__Longitude__s`] = this.selectedResult.lng;

        if (this.includeKorean && this.hasAddressKOField && this.selectedResult.koResult) {
            const ko = this.selectedResult.koResult;
            fields['AddressKO__Street__s'] = ko.address || '';
            fields['AddressKO__City__s'] = ko.city || '';
            fields['AddressKO__PostalCode__s'] = ko.postalCode;
            fields['AddressKO__CountryCode__s'] = ko.countryCode;
            fields['AddressKO__StateCode__s'] = ko.stateCode;
            fields['AddressKO__Latitude__s'] = ko.lat;
            fields['AddressKO__Longitude__s'] = ko.lng;
        }
        // console.log('🏅🏅🏅🏅🏅🏅🏅🏅🏅🏅 this.selectedResult.stateCode', this.selectedResult.stateCode)
        // console.log('🏅🏅🏅🏅🏅🏅🏅🏅🏅🏅 this.selectedResult.state', this.selectedResult.state)
        // console.log('🏅🏅🏅🏅🏅🏅🏅🏅🏅🏅 this.hasStateField', this.hasStateField)

        if(this.hasGPSField) {
            const gpsFieldName = 'GPSCoordinates';
            fields[`${gpsFieldName}__Latitude__s`] = this.selectedResult.lat;
            fields[`${gpsFieldName}__Longitude__s`] = this.selectedResult.lng;
        }
        if(this.hasStateField) {
            const updateFieldName = 'State__c';
            fields[`${updateFieldName}`] = this.selectedResult.state;
        }

        const recordInput = { fields };

        updateRecord(recordInput)
            .then(() => {
                toast(this, 'Success', this.labels.COM_MSG_SAVE_SUCCESS, 'success');
                void notifyRecordUpdateAvailable([{ recordId: String(this.recordId) }]);
                return refreshApex(this.wiredAddressResult);
            })
            .then(() => {
                this.handleClose();
            })
            .catch(error => {
                toast(this, 'Error', this.labels.COM_MSG_SAVE_FAILED + ': ' + reduceErrors(error).join(', '), 'error');
            });
    }

    handleClose() {
        this.dispatchEvent(new CloseActionScreenEvent());
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view'
            }
        }, true);
    }

    // 📍 7. Private 메서드
    _initSearchMode() {
        if (this.currentData.street) {
            this.addressQuery = this.currentData.street;
        }
        if (this.currentData.latitude) {
            this.latQuery = this.currentData.latitude;
            this.lngQuery = this.currentData.longitude;
        }
    }

    // 📍 8. 라이프사이클 메서드
    connectedCallback() {
    }

    disconnectedCallback() {
    }

    renderedCallback() {
        window.addEventListener('keydown', (event) => {
            if (event.key === 'Escape') {
                this.handleClose();
            }
        });
    }


}