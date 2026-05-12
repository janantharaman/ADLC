---
source_url: https://raw.githubusercontent.com/trailheadapps/lwc-recipes/main/force-app/main/default/lwc/apexWireMethodToProperty/apexWireMethodToProperty.js
date_fetched: 2026-05-01
phase: implementation
category: lwc
page_title: Apex Wire Method To Property
---

```javascript
import { LightningElement, wire } from 'lwc';
import getContactList from '@salesforce/apex/ContactController.getContactList';

export default class ApexWireMethodToProperty extends LightningElement {
    @wire(getContactList) contacts;
}

```

