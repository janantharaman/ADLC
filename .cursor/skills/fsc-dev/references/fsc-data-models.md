# FSC data model deep dive with ERD diagrams and field definitions

**Industry**: Financial Services Cloud
**Generated**: 2026-03-01T03:58:11.730Z

---

## Overview

### FinServ__FinancialAccount__c

Core financial account object for tracking customer accounts, balances, and account types

**Key Fields**:
- `FinServ__Balance__c`
- `FinServ__AccountType__c`
- `FinServ__Status__c`
- `FinServ__AccountNumber__c`
- `FinServ__OpenDate__c`

**Relationships**:
- FinServ__FinancialAccountRole__c
- Account
- FinServ__FinancialGoal__c

### FinServ__Securities__c

Investment securities tracking for stocks, bonds, and other financial instruments

**Key Fields**:
- `FinServ__Price__c`
- `FinServ__Symbol__c`
- `FinServ__AssetClass__c`
- `FinServ__CUSIP__c`
- `FinServ__Exchange__c`

**Relationships**:
- FinServ__FinancialAccount__c
- FinServ__FinancialHolding__c

### FinServ__FinancialGoal__c

Client financial goals for retirement planning, education savings, etc.

**Key Fields**:
- `FinServ__TargetValue__c`
- `FinServ__TargetDate__c`
- `FinServ__Status__c`
- `FinServ__Type__c`

**Relationships**:
- FinServ__FinancialAccount__c
- Account

## FinancialAccount and Roles

[Detailed content for FinancialAccount and Roles]

## Securities and Holdings

[Detailed content for Securities and Holdings]

## Financial Goals

[Detailed content for Financial Goals]

## Household Relationships

[Detailed content for Household Relationships]

## Best Practices

[Detailed content for Best Practices]

---

**Reference**: See `../SKILL.md` for complete Financial Services Cloud skill definition.
