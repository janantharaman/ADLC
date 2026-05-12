---
source_url: https://raw.githubusercontent.com/trailheadapps/apex-recipes/main/force-app/main/default/classes/Testing%20Recipes/StubExample.cls
date_fetched: 2026-05-01
phase: testing
category: apex-testing
page_title: Stub Example
---

```apex
public with sharing class StubExample {
    public Boolean isTrue = false;
    public String greeting = 'hello';
    public Boolean notMocked; // this is null on purpose for testing.

    public Boolean getIsTrue() {
        return this.isTrue;
    }

    public String getGreeting() {
        return this.greeting;
    }

    public void setGreeting(String greeting) {
        this.greeting = greeting;
    }

    public void setGreeting(Integer greeting) {
        this.greeting = String.valueOf(greeting);
    }
}

```

