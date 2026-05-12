---
source_url: https://architect.salesforce.com/docs/architect/reference-diagrams/guide/claim-check.html
date_fetched: 2026-05-01
section: reference-diagrams
page_title: Claim Check
---

## Description

Shows an event being published when a record is modified. The message body of the event is stored in a separate data store while the header, which contains a claim check is passed onto a subscriber. The subscriber then uses the claim check to retrieve the message body when it's ready to process the information when necessary.

## Downloadable Links

- [Lucid](https://lucid.app/lucidchart/editNewOrRegister/0699a470-11ca-4291-88d6-a6399142a1ca)
- [Image](https://architect.salesforce.com/ns-assets/legacy/templateseventdrivenarchitecturediagrams-claimcheck.png)
