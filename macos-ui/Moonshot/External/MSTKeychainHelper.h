//
//  MSTKeychainHelper.h
//
//  Created by Elena Jakjoska on 11/29/16.
//

#import <Foundation/Foundation.h>

@interface MSTKeychainHelper : NSObject

#ifdef DEBUG
@property (strong, nonatomic, readonly) NSString *keyPrefix;
#endif
@property (assign, nonatomic, readonly) OSStatus lastStatus;

- (instancetype)initWithKeyPrefix:(NSString *)keyPrefix;
+ (BOOL)archiveObject:(id<NSSecureCoding>)object forKey:(NSString *)key accessibility:(CFTypeRef)accessibility;
+ (BOOL)archiveObject:(id<NSSecureCoding>)object forKey:(NSString *)key;
+ (id)unarchiveObjectForKey:(NSString *)key;

@end
