//
//  Identity.h
//  Moonshot
//
//  Created by Elena Jakjoska on 10/20/16.
//

#import <Foundation/Foundation.h>
#import "SelectionRules.h"
#import "TrustAnchor.h"


@interface Identity : NSObject

//Identity details
@property (nonatomic, strong) NSString *identityId;
@property (nonatomic, strong) NSString *displayName;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) NSString *realm;
@property (nonatomic, assign) BOOL passwordRemembered;
@property (nonatomic, assign) BOOL has2fa;
@property (nonatomic, strong) NSDate *dateAdded;
@property (nonatomic, strong) TrustAnchor *trustAnchor;
@property (nonatomic, retain) NSMutableArray *servicesArray;
@property (nonatomic, strong) NSMutableArray<SelectionRules *> *selectionRules;

- (id)initWithDictionaryObject:(NSDictionary *)identityDict;
- (id)initWithCoder:(NSCoder *)decoder;
- (void)encodeWithCoder:(NSCoder *)encoder;

@end
