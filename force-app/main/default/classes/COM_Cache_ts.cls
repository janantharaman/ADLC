/**
 * @description Test class for COM_Cache
 */
@IsTest
private class COM_Cache_ts {
    /**
     * @description Mock Loader implementation for testing
     */
    private class MockLoader implements COM_Cache.Loader {
        private Map<String, Object> dataStore;

        public MockLoader() {
            this.dataStore = new Map<String, Object>();
        }

        public MockLoader(Map<String, Object> dataStore) {
            this.dataStore = dataStore;
        }

        public Object load(String key) {
            return this.dataStore.get(key);
        }
    }

    private class LoaderFailureException extends Exception {
    }

    private class FlakyLoader implements COM_Cache.Loader {
        @TestVisible
        Integer invocationCount = 0;

        public Object load(String key) {
            this.invocationCount++;
            if (this.invocationCount == 1) {
                throw new LoaderFailureException();
            }
            return 'recoveredValue';
        }
    }

    /**
     * @description Test: of(Loader) factory method creates instance correctly
     */
    @IsTest
    static void testOfWithLoaderInstance() {
        // Given
        MockLoader loader = new MockLoader();

        // When
        COM_Cache cache = COM_Cache.of(loader);

        // Then
        Assert.isNotNull(cache, 'Cache instance should not be null');
    }

    /**
     * @description Test: of(Type) factory method creates instance correctly
     */
    @IsTest
    static void testOfWithLoaderType() {
        // When
        COM_Cache cache = COM_Cache.of(MockLoader.class);

        // Then
        Assert.isNotNull(cache, 'Cache instance should not be null');
    }

    /**
     * @description Test: getCacheKey returns consistent key for same input
     */
    @IsTest
    static void testGetCacheKeyConsistency() {
        // Given
        MockLoader loader = new MockLoader();
        COM_Cache cache = COM_Cache.of(loader);
        String originalKey = 'testKey';

        // When
        String cacheKey1 = cache.getCacheKey(originalKey);
        String cacheKey2 = cache.getCacheKey(originalKey);

        // Then
        Assert.isNotNull(cacheKey1, 'Cache key should not be null');
        Assert.areEqual(cacheKey1, cacheKey2, 'Same key should return same cache key');
    }

    /**
     * @description Test: getCacheKey returns different keys for different inputs
     */
    @IsTest
    static void testGetCacheKeyUniqueness() {
        // Given
        MockLoader loader = new MockLoader();
        COM_Cache cache = COM_Cache.of(loader);

        // When
        String cacheKey1 = cache.getCacheKey('key1');
        String cacheKey2 = cache.getCacheKey('key2');

        // Then
        Assert.areNotEqual(cacheKey1, cacheKey2, 'Different keys should return different cache keys');
    }

    /**
     * @description Test: lookup returns data from loader on cache miss
     */
    @IsTest
    static void testLookupCacheMiss() {
        // Given
        Map<String, Object> dataStore = new Map<String, Object>{ 'testKey' => 'testValue' };
        MockLoader loader = new MockLoader(dataStore);
        COM_Cache cache = COM_Cache.of(loader);

        // When
        Test.startTest();
        Object result = cache.lookup('testKey');
        Test.stopTest();

        // Then
        Assert.areEqual('testValue', result, 'Should return value from loader');
    }

    /**
     * @description Test: lookup returns cached data on cache hit
     */
    @IsTest
    static void testLookupCacheHit() {
        // Given
        Map<String, Object> dataStore = new Map<String, Object>{ 'testKey' => 'testValue' };
        MockLoader loader = new MockLoader(dataStore);
        COM_Cache cache = COM_Cache.of(loader);

        // When - First call (cache miss)
        Test.startTest();
        Object result1 = cache.lookup('testKey');
        Object result2 = cache.lookup('testKey');
        Test.stopTest();

        // Then
        Assert.areEqual('testValue', result1, 'First lookup should return value');
        Assert.areEqual('testValue', result2, 'Second lookup should return cached value');
    }

    /**
     * @description Test: clear removes all cached data
     */
    @IsTest
    static void testClear() {
        // Given
        Map<String, Object> dataStore = new Map<String, Object>{ 'key1' => 'value1', 'key2' => 'value2' };
        MockLoader loader = new MockLoader(dataStore);
        COM_Cache cache = COM_Cache.of(loader);

        // Populate cache
        cache.lookup('key1');
        cache.lookup('key2');

        // When
        COM_Cache.useFallback = true;
        COM_Cache.clear();

        // Then
        Assert.areEqual(0, COM_Cache.localFallback.size(), 'Clear should empty the fallback cache as well');
        COM_Cache.useFallback = false;
    }

    /**
     * @description Test: lookup with null value from loader
     *              Platform Cache cannot store null, so COM_Cache wraps null internally.
     */
    @IsTest
    static void testLookupWithNullValue() {
        // Given
        Map<String, Object> dataStore = new Map<String, Object>{ 'nullKey' => null };
        MockLoader loader = new MockLoader(dataStore);
        COM_Cache cache = COM_Cache.of(loader);

        // When - First call (cache miss with null value)
        Test.startTest();
        Object result1 = cache.lookup('nullKey');
        Object result2 = cache.lookup('nullKey');
        Test.stopTest();

        // Then
        Assert.isNull(result1, 'First lookup should return null');
        Assert.isNull(result2, 'Second lookup should also return null (from cache)');
    }

    /**
     * @description Test: lookup with complex object value
     */
    @IsTest
    static void testLookupWithComplexObject() {
        // Given
        Map<String, String> complexValue = new Map<String, String>{ 'nested' => 'data' };
        Map<String, Object> dataStore = new Map<String, Object>{ 'complexKey' => complexValue };
        MockLoader loader = new MockLoader(dataStore);
        COM_Cache cache = COM_Cache.of(loader);

        // When
        Object result = cache.lookup('complexKey');

        // Then
        Assert.areEqual(complexValue, result, 'Should handle complex objects correctly');
    }

    /**
     * @description Test: withTtl builder method returns same instance (fluent API)
     */
    @IsTest
    static void testWithTtl() {
        // Given
        MockLoader loader = new MockLoader(new Map<String, Object>{ 'k' => 'v' });

        // When
        Test.startTest();
        COM_Cache cache = COM_Cache.of(loader).withTtl(3600);
        Object result = cache.lookup('k');
        Test.stopTest();

        // Then
        Assert.isNotNull(cache, 'withTtl should return the cache instance');
        Assert.areEqual('v', result, 'Lookup should still work with custom TTL');
    }

    /**
     * @description Test: remove deletes a specific key from cache
     */
    @IsTest
    static void testRemove() {
        // Given
        Map<String, Object> dataStore = new Map<String, Object>{ 'removeKey' => 'removeValue' };
        MockLoader loader = new MockLoader(dataStore);
        COM_Cache cache = COM_Cache.of(loader);
        cache.lookup('removeKey'); // populate cache

        // When
        Test.startTest();
        cache.remove('removeKey');

        // Then — after remove, next lookup triggers a cache miss and reloads
        Object result = cache.lookup('removeKey');
        Test.stopTest();
        Assert.areEqual('removeValue', result, 'Should reload value after remove');
    }

    /**
     * @description Test: lookup falls back to local Map when Platform Cache is unavailable
     */
    @IsTest
    static void testLocalFallback() {
        // Given
        Map<String, Object> dataStore = new Map<String, Object>{ 'fbKey' => 'fbValue' };
        MockLoader loader = new MockLoader(dataStore);
        COM_Cache cache = COM_Cache.of(loader);

        // Simulate Platform Cache unavailable
        COM_Cache.useFallback = true;
        COM_Cache.localFallback.clear();

        // When
        Test.startTest();
        Object result1 = cache.lookup('fbKey');
        Object result2 = cache.lookup('fbKey'); // should hit local fallback
        Test.stopTest();

        // Then
        Assert.areEqual('fbValue', result1, 'Fallback should return loaded value');
        Assert.areEqual('fbValue', result2, 'Fallback should return cached value on second call');

        // Cleanup
        COM_Cache.useFallback = false;
        COM_Cache.localFallback.clear();
    }

    /**
     * @description Test: lookup switches to fallback when the platform-path load fails
     */
    @IsTest
    static void testLookupFallsBackAfterLoaderFailure() {
        FlakyLoader loader = new FlakyLoader();
        COM_Cache cache = COM_Cache.of(loader);

        COM_Cache.useFallback = false;
        COM_Cache.localFallback.clear();

        Test.startTest();
        Object firstResult = cache.lookup('flakyKey');
        Object secondResult = cache.lookup('flakyKey');
        Test.stopTest();

        Assert.areEqual('recoveredValue', firstResult, 'Fallback retry should recover from the initial loader failure');
        Assert.areEqual('recoveredValue', secondResult, 'Subsequent lookup should use the fallback cache');
        Assert.isTrue(COM_Cache.useFallback, 'Loader failure on the platform path should enable fallback mode');
        Assert.areEqual(2, loader.invocationCount, 'The first miss should retry once through the fallback path');

        COM_Cache.useFallback = false;
        COM_Cache.localFallback.clear();
    }

    /**
     * @description Test: different Loader types produce different cache keys (namespace isolation)
     */
    @IsTest
    static void testNamespaceIsolation() {
        // Given — two different loaders with the same key
        MockLoader loader1 = new MockLoader(new Map<String, Object>{ 'sameKey' => 'value1' });
        AnotherMockLoader loader2 = new AnotherMockLoader(new Map<String, Object>{ 'sameKey' => 'value2' });
        COM_Cache cache1 = COM_Cache.of(loader1);
        COM_Cache cache2 = COM_Cache.of(loader2);

        // When
        String cacheKey1 = cache1.getCacheKey('sameKey');
        String cacheKey2 = cache2.getCacheKey('sameKey');

        // Then — different loaders produce different cache keys
        Assert.areNotEqual(
            cacheKey1,
            cacheKey2,
            'Different loaders should produce different cache keys for the same original key'
        );
    }

    /**
     * @description Test: getCacheKey handles long keys by hashing
     */
    @IsTest
    static void testGetCacheKeyWithLongKey() {
        // Given
        MockLoader loader = new MockLoader();
        COM_Cache cache = COM_Cache.of(loader);
        String longKey = 'a'.repeat(100);

        // When
        String cacheKey = cache.getCacheKey(longKey);

        // Then
        Assert.isTrue(cacheKey.length() <= 50, 'Cache key should not exceed 50 characters');
        // Deterministic — same input produces same output
        Assert.areEqual(cacheKey, cache.getCacheKey(longKey), 'Long key hashing should be deterministic');
    }

    /**
     * @description Test: register bulk-loads entries into the fallback cache
     */
    @IsTest
    static void testRegisterPopulatesFallbackEntries() {
        Map<String, Object> dataStore = new Map<String, Object>{ 'bulkKey' => 'bulkValue', 'bulkNull' => null };

        COM_Cache.useFallback = true;
        COM_Cache.localFallback.clear();

        Test.startTest();
        COM_Cache.register(dataStore);
        Test.stopTest();

        Assert.areEqual(dataStore.size(), COM_Cache.localFallback.size(), 'Register should cache every supplied entry');
        Assert.isTrue(
            COM_Cache.localFallback.values().contains(COM_Cache.NULL_VALUE),
            'Register should cache nulls using the sentinel value'
        );

        COM_Cache.useFallback = false;
        COM_Cache.localFallback.clear();
    }

    /**
     * @description Another mock loader for namespace isolation testing
     */
    private class AnotherMockLoader implements COM_Cache.Loader {
        private Map<String, Object> dataStore;

        public AnotherMockLoader(Map<String, Object> dataStore) {
            this.dataStore = dataStore;
        }

        public Object load(String key) {
            return this.dataStore.get(key);
        }
    }
}