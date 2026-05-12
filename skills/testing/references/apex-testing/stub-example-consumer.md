---
source_url: https://raw.githubusercontent.com/trailheadapps/apex-recipes/main/force-app/main/default/classes/Testing%20Recipes/StubExampleConsumer.cls
date_fetched: 2026-05-01
phase: testing
category: apex-testing
page_title: Stub Example Consumer
---

```apex
public with sharing class StubExampleConsumer {
    StubExample stub;

    public StubExampleConsumer(StubExample stub) {
        this.stub = stub;
    }

    public Boolean getIsTrue() {
        return this.stub.getIsTrue();
    }

    public String getGreeting() {
        return this.stub.getGreeting();
    }

    public void setGreeting(String greeting) {
        this.stub.setGreeting(greeting);
    }

    public void setGreeting(Integer someInt) {
        this.stub.setGreeting(someInt);
    }

    public void setGreeting(Boolean someBoolean) {
        this.stub.setGreeting(String.valueOf(someBoolean));
    }
}

```

