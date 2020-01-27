//
//  MSTKeychainHelper.m
//
//  Created by Elena Jakjoska on 11/29/16.
//

#import "MSTKeychainHelper.h"
#import <Security/Security.h>

#define DEFAULT_ACCESSIBILITY kSecAttrAccessibleWhenUnlocked
#define MSTKEYCHAIN_ID __bridge id
#define MSTKEYCHAIN_DICTREF __bridge CFDictionaryRef

static MSTKeychainHelper *_keychainHelper = nil;
static NSString *_defaultKeyPrefix = nil;

@interface MSTKeychainHelper()
@property (strong, nonatomic, readwrite) NSString *keyPrefix;
@end

@implementation MSTKeychainHelper

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _defaultKeyPrefix = [[[NSBundle bundleForClass:[self class]] infoDictionary] objectForKey:(NSString *)kCFBundleIdentifierKey];
        _keychainHelper = [[MSTKeychainHelper alloc] init];
    });
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.keyPrefix = _defaultKeyPrefix;
    }
    return self;
}

- (instancetype)initWithKeyPrefix:(NSString *)keyPrefix {
    self = [self init];
    if (self) {
        if (keyPrefix)
            self.keyPrefix = keyPrefix;
    }
    return self;
}

- (NSMutableDictionary *)_service {
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    [dict setObject: (MSTKEYCHAIN_ID) kSecClassGenericPassword  forKey: (MSTKEYCHAIN_ID) kSecClass];

    return dict;
}

- (NSMutableDictionary *)_query {
    NSMutableDictionary* query = [NSMutableDictionary dictionary];
    [query setObject: (MSTKEYCHAIN_ID) kSecClassGenericPassword forKey: (MSTKEYCHAIN_ID) kSecClass];
    [query setObject: (MSTKEYCHAIN_ID) kCFBooleanTrue           forKey: (MSTKEYCHAIN_ID) kSecReturnData];

    return query;
}

- (NSString *)_hierarchicalKey:(NSString *)key {
    return [_keyPrefix stringByAppendingFormat:@".%@", key];
}

- (BOOL)setObject:(NSString *)obj forKey:(NSString *)key accessibility:(CFTypeRef)accessibility {
    NSString *hierKey = [self _hierarchicalKey:key];
    if (!obj) {
        NSMutableDictionary *query = [self _query];
        [query setObject:hierKey forKey:(MSTKEYCHAIN_ID)kSecAttrService];
        _lastStatus = SecItemDelete((MSTKEYCHAIN_DICTREF)query);
        return (_lastStatus == errSecSuccess);
    }
    NSMutableDictionary *dict = [self _service];
    [dict setObject: hierKey forKey: (MSTKEYCHAIN_ID) kSecAttrService];
    [dict setObject: (MSTKEYCHAIN_ID)(accessibility) forKey: (MSTKEYCHAIN_ID) kSecAttrAccessible];
    [dict setObject: [obj dataUsingEncoding:NSUTF8StringEncoding] forKey: (MSTKEYCHAIN_ID) kSecValueData];
    
    _lastStatus = SecItemAdd ((MSTKEYCHAIN_DICTREF) dict, NULL);
    if (_lastStatus == errSecDuplicateItem) {
        NSMutableDictionary *query = [self _query];
        [query setObject:hierKey forKey:(MSTKEYCHAIN_ID)kSecAttrService];
        _lastStatus = SecItemDelete((MSTKEYCHAIN_DICTREF)query);
        if (_lastStatus == errSecSuccess)
            _lastStatus = SecItemAdd((MSTKEYCHAIN_DICTREF) dict, NULL);
    }
    return (_lastStatus == errSecSuccess);
}

- (NSString *)objectForKey:(NSString *)key {
    NSString *hierKey = [self _hierarchicalKey:key];
    NSMutableDictionary *query = [self _query];
    [query setObject:hierKey forKey: (MSTKEYCHAIN_ID)kSecAttrService];

    CFDataRef data = nil;
    _lastStatus =
    SecItemCopyMatching ( (MSTKEYCHAIN_DICTREF) query, (CFTypeRef *) &data );
    if (_lastStatus != errSecSuccess && _lastStatus != errSecItemNotFound)
    
    if (!data)
        return nil;

    NSString *s = [[NSString alloc] initWithData:(__bridge_transfer NSData *)data encoding: NSUTF8StringEncoding];
    
    return s;
}

- (BOOL)setData:(NSData *)obj forKey:(NSString *)key accessibility:(CFTypeRef)accessibility {
    NSString *hierKey = [self _hierarchicalKey:key];
    if (!obj) {
        NSMutableDictionary *query = [self _query];
        [query setObject:hierKey forKey:(MSTKEYCHAIN_ID)kSecAttrService];
        _lastStatus = SecItemDelete((MSTKEYCHAIN_DICTREF)query);
        return (_lastStatus == errSecSuccess);
    }
    NSMutableDictionary *dict = [self _service];
    [dict setObject: hierKey forKey: (MSTKEYCHAIN_ID) kSecAttrService];
    [dict setObject: (MSTKEYCHAIN_ID)(accessibility) forKey: (MSTKEYCHAIN_ID) kSecAttrAccessible];
    [dict setObject: obj forKey: (MSTKEYCHAIN_ID) kSecValueData];
    
    _lastStatus = SecItemAdd ((MSTKEYCHAIN_DICTREF) dict, NULL);
    if (_lastStatus == errSecDuplicateItem) {
        NSMutableDictionary *query = [self _query];
        [query setObject:hierKey forKey:(MSTKEYCHAIN_ID)kSecAttrService];
        _lastStatus = SecItemDelete((MSTKEYCHAIN_DICTREF)query);
        if (_lastStatus == errSecSuccess)
            _lastStatus = SecItemAdd((MSTKEYCHAIN_DICTREF) dict, NULL);
    }
    return (_lastStatus == errSecSuccess);
}

- (NSData *)dataForKey:(NSString *)key {
    NSString *hierKey = [self _hierarchicalKey:key];
    
    NSMutableDictionary *query = [self _query];
    [query setObject:hierKey forKey: (MSTKEYCHAIN_ID)kSecAttrService];
    
    CFDataRef data = nil;
    _lastStatus =
    SecItemCopyMatching ( (MSTKEYCHAIN_DICTREF) query, (CFTypeRef *) &data );
    
    if (!data)
        return nil;

    return (__bridge_transfer NSData *)data;
}

- (BOOL)archiveObject:(id<NSSecureCoding>)object forKey:(NSString *)key {
    return [self archiveObject:object forKey:key accessibility:DEFAULT_ACCESSIBILITY];
}

- (BOOL)archiveObject:(id<NSSecureCoding>)object forKey:(NSString *)key accessibility:(CFTypeRef)accessibility {
    NSMutableData *data = [NSMutableData new];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:object forKey:key];
    [archiver finishEncoding];
    
    return [self setData:data forKey:key accessibility:accessibility];
}

- (id)unarchiveObjectForKey:(NSString *)key {
    NSData *data = [self dataForKey:key];
    if (!data)
        return nil;

    id object = nil;
    @try {
        NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        object = [unarchiver decodeObjectForKey:key];
    }
    @catch (NSException *exception) {
    }
    return object;
}

#pragma mark - Class methods

+ (BOOL)archiveObject:(id<NSSecureCoding>)object forKey:(NSString *)key {
    return [_keychainHelper archiveObject:object forKey:key];
}

+ (BOOL)archiveObject:(id<NSSecureCoding>)object forKey:(NSString *)key accessibility:(CFTypeRef)accessibility {
    return [_keychainHelper archiveObject:object forKey:key accessibility:accessibility];
}

+ (id)unarchiveObjectForKey:(NSString *)key {
    return [_keychainHelper unarchiveObjectForKey:key];
}

@end
