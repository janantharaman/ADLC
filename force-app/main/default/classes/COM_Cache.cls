/**********************************************************************************
 * @filename      : COM_Cache.cls
 * @project-name  : LK보험중계 신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-03-24 (화)
 * @group         :
 * @group-content :
 * @description   : Common Cache Utility Class
 * 					Caches data using Salesforce Platform Cache.
 * 					Implements the Loader interface to load data on cache miss.
 * @test-class    : COM_Cache_ts.cls
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-03-24      i2max     Create
 **********************************************************************************/
public with sharing class COM_Cache {
    /*=========================================================================
     * Why COM_Cache instead of the built-in Cache.CacheBuilder interface
     *=========================================================================*/
    /**
     * 1. Key flexibility — CacheBuilder keys must be alphanumeric only, so business
     *    keys like 'LK_KR' cannot be used directly. COM_Cache separates the cache key
     *    (sanitized / SHA-256 hashed) from the original key passed to Loader.load().
     * 2. Null caching — CacheBuilder does not cache null returns from doLoad(), causing
     *    repeated SOQL on every miss. NullValue sentinel lets COM_Cache cache null results.
     * 3. Custom TTL — CacheBuilder offers no per-entry TTL control. withTtl() allows
     *    callers to set case-specific expiration.
     * 4. In-memory fallback — Gracefully degrades to a static Map when Platform Cache
     *    is unavailable (e.g. Scratch Orgs, certain editions).
     * 5. Explicit eviction — remove() and clear() provide programmatic cache invalidation,
     *    which CacheBuilder does not support out of the box.
     */

    /*=========================================================================
     * CONSTANTS
     *=========================================================================*/

    @TestVisible
    private static final String PARTITION_NAME = 'ApexCache';

    /** Default time-to-live for cached entries in seconds (12 hours) */
    private static final Integer DEFAULT_TTL_SECONDS = 43200;

    /** Maximum length for Platform Cache keys */
    private static final Integer MAX_KEY_LENGTH = 50;

    public static final NullValue NULL_VALUE = new NullValue();

    /*=========================================================================
     * INSTANCE VARIABLES
     *=========================================================================*/

    private Loader loader;
    private Cache.OrgPartition partition;
    private String namespace;
    private Integer ttlSeconds;

    /** In-memory fallback when Platform Cache is unavailable */
    @TestVisible
    private static Map<String, Object> localFallback = new Map<String, Object>();
    @TestVisible
    private static Boolean useFallback = false;

    /*=========================================================================
     * STATIC FACTORY METHODS
     *=========================================================================*/

    /**
     * @description Creates a COM_Cache instance with the given Loader.
     *              Namespace is derived from the Loader's class name.
     * @param loader Loader instance to load data on cache miss
     * @return COM_Cache instance
     */
    public static COM_Cache of(Loader loader) {
        return new COM_Cache(loader);
    }

    /**
     * @description Creates a COM_Cache instance with the given Loader type.
     *              Namespace is derived from the type name for cache key isolation.
     * @param loaderType Type of the class implementing the Loader interface
     * @return COM_Cache instance
     */
    public static COM_Cache of(Type loaderType) {
        return new COM_Cache((Loader) loaderType.newInstance(), sanitize(String.valueOf(loaderType)));
    }

    /**
     * @description Clears all cached data in the partition and local fallback.
     */
    public static void clear() {
        try {
            Cache.OrgPartition p = Cache.Org.getPartition(PARTITION_NAME);
            for (String key : p.getKeys()) {
                p.remove(key);
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'COM_Cache.clear: ' + e.getMessage());
        }
        localFallback.clear();
    }

    /**
     * @description Bulk-registers key-value pairs into the cache.
     * @param dataSource Map of keys to values
     */
    public static void register(Map<String, Object> dataSource) {
        COM_Cache cache = COM_Cache.of(new BulkRegister(dataSource));

        for (String key : dataSource.keySet()) {
            cache.lookup(key);
        }
    }

    /*=========================================================================
     * CONSTRUCTORS
     *=========================================================================*/

    /**
     * @description COM_Cache constructor. Namespace is derived from the Loader's class name.
     * @param loader Loader instance to load data on cache miss
     */
    public COM_Cache(Loader loader) {
        this(loader, deriveNamespace(loader));
    }

    private COM_Cache(Loader loader, String namespace) {
        this.loader = loader;
        this.namespace = namespace;
        this.ttlSeconds = DEFAULT_TTL_SECONDS;
        try {
            this.partition = Cache.Org.getPartition(PARTITION_NAME);
        } catch (Exception e) {
            useFallback = true;
        }
    }

    /*=========================================================================
     * BUILDER METHODS
     *=========================================================================*/

    /**
     * @description Sets a custom TTL (time-to-live) in seconds for cached entries.
     * @param seconds TTL in seconds
     * @return this COM_Cache instance (fluent API)
     */
    public COM_Cache withTtl(Integer seconds) {
        this.ttlSeconds = seconds;
        return this;
    }

    /*=========================================================================
     * PUBLIC METHODS
     *=========================================================================*/

    /**
     * @description Generates a deterministic cache key from namespace + original key.
     *              No MappingTable — eliminates race conditions and extra cache I/O.
     * @param key Original key
     * @return Cache-safe key (alphanumeric, max 50 chars)
     */
    public String getCacheKey(String key) {
        String raw = this.namespace + key;
        String sanitized = sanitize(raw);

        if (sanitized.length() > MAX_KEY_LENGTH) {
            sanitized =
                'K' + EncodingUtil.convertToHex(Crypto.generateDigest('SHA256', Blob.valueOf(raw))).left(MAX_KEY_LENGTH - 1);
        }

        return sanitized;
    }

    /**
     * @description Looks up data from cache.
     *              On cache miss, loads data via Loader and stores it.
     *              Falls back to in-memory Map when Platform Cache is unavailable.
     * @param key Key to look up
     * @return Cached data or newly loaded data (null if the loaded value was null)
     */
    public Object lookup(String key) {
        String cacheKey = getCacheKey(key);

        if (useFallback || this.partition == null) {
            return lookupFromFallback(key, cacheKey);
        }

        try {
            Boolean isMiss = !this.partition.contains(cacheKey);
            if (isMiss) {
                Object loadedValue = this.loader.load(key);
                Object toCache = loadedValue != null ? loadedValue : NULL_VALUE;
                this.partition.put(cacheKey, toCache, this.ttlSeconds);
                System.debug(LoggingLevel.FINEST, 'COM_Cache MISS [' + this.namespace + '] key=' + key);
                return loadedValue;
            } else {
                System.debug(LoggingLevel.FINEST, 'COM_Cache HIT  [' + this.namespace + '] key=' + key);
            }

            Object cachedValue = this.partition.get(cacheKey);
            return cachedValue instanceof NullValue ? null : cachedValue;
        } catch (Exception e) {
            useFallback = true;
            return lookupFromFallback(key, cacheKey);
        }
    }

    /**
     * @description Removes a specific key from cache.
     * @param key Key to remove
     */
    public void remove(String key) {
        String cacheKey = getCacheKey(key);
        try {
            this.partition?.remove(cacheKey);
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'COM_Cache.remove: ' + e.getMessage());
        }
        localFallback.remove(cacheKey);
    }

    /*=========================================================================
     * PRIVATE METHODS
     *=========================================================================*/

    private Object lookupFromFallback(String key, String cacheKey) {
        if (!localFallback.containsKey(cacheKey)) {
            Object loadedValue = this.loader.load(key);
            localFallback.put(cacheKey, loadedValue == null ? NULL_VALUE : loadedValue);
            System.debug(LoggingLevel.FINEST, 'COM_Cache MISS (fallback) [' + this.namespace + '] key=' + key);
        } else {
            System.debug(LoggingLevel.FINEST, 'COM_Cache HIT  (fallback) [' + this.namespace + '] key=' + key);
        }
        Object val = localFallback.get(cacheKey);
        return val instanceof NullValue ? null : val;
    }

    /**
     * @description Derives a namespace prefix from an object's class name.
     *              Uses Apex's String.valueOf() which returns "ClassName:[fields...]".
     */
    private static String deriveNamespace(Object obj) {
        String repr = String.valueOf(obj);
        Integer idx = repr.indexOf(':[');
        String name = idx > 0 ? repr.substring(0, idx) : repr;
        return sanitize(name);
    }

    /**
     * @description Removes all non-alphanumeric characters from a string.
     */
    private static String sanitize(String input) {
        return input.replaceAll('[^a-zA-Z0-9]', '');
    }

    /*=========================================================================
     * INNER CLASSES
     *=========================================================================*/

    /**
     * @description Wrapper class to represent null values in cache.
     *              Platform Cache cannot store null directly.
     */
    public class NullValue {
    }

    /*=========================================================================
     * INNER INTERFACES
     *=========================================================================*/

    /**
     * @description Interface for loading data on cache miss
     */
    public interface Loader {
        /**
         * @description Loads data for the given key.
         * @param key Key of the data to load
         * @return Loaded data
         */
        Object load(String key);
    }

    /**
     * @description BulkRegister Loader
     */
    public class BulkRegister implements Loader {
        Map<String, Object> dataSource;

        public BulkRegister(Map<String, Object> dataSource) {
            this.dataSource = dataSource;
        }

        public Object load(String key) {
            return this.dataSource.get(key);
        }
    }
}