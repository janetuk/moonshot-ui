//
//  Identity.h
//  Moonshot
//
//  Created by Elena Jakjoska on 10/20/16.
//

#import <Foundation/Foundation.h>

@interface Identity : NSObject
@property (nonatomic,strong) NSString *identityId;// GUID
@property (nonatomic,strong) NSString *displayName;
@property (nonatomic,strong) NSString *username;
@property (nonatomic,strong) NSString *password;
@property (nonatomic,strong) NSString *realm;
@property (nonatomic, assign) BOOL passwordRemembered;
@property (nonatomic, strong) NSDate *dateAdded;
@property (nonatomic, retain) NSMutableArray *identitiesArray;
@property (nonatomic, retain) NSMutableArray *servicesArray;
@property (nonatomic, retain) NSArray *trustAnchorArray;
@property (nonatomic, assign) BOOL caCertificate;
@property (nonatomic, strong) NSString *trustAnchor;


- (id)initWithDictionaryObject:(NSDictionary *)identityDict;
- (id)initWithCoder:(NSCoder *)decoder;
- (void)encodeWithCoder:(NSCoder *)encoder;

@end
