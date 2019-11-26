//
//  X509Cert.h
//  Moonshot
//
//  Created by alex on 26/11/2019.
//  Copyright © 2019 Devsy. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface X509Cert : NSObject
- (id) initWithHexString: (NSString*) hexstring;
- (id) initWithB64String: (NSString*) b64string;
- (id) initWithDerData: (NSData*) derdata;
@property NSString* hexfingerprint;
@property NSString* textsummary;
@end

NS_ASSUME_NONNULL_END
