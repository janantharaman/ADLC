---
source_url: https://raw.githubusercontent.com/trailheadapps/lwc-recipes/main/force-app/main/default/lwc/wireGetPicklistValues/wireGetPicklistValues.js
date_fetched: 2026-05-01
phase: implementation
category: lwc
page_title: Wire Get Picklist Values
---

```javascript
import { LightningElement, wire } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import TYPE_FIELD from '@salesforce/schema/Account.Type';

export default class WireGetPicklistValues extends LightningElement {
    @wire(getPicklistValues, {
        recordTypeId: '012000000000000AAA',
        fieldApiName: TYPE_FIELD
    })
    picklistValues;
}

```

