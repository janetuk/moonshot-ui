//
//  MSTIdentityImporter.h
//  Moonshot
//
//  Created by Ivan on 1/16/18.
//  Copyright © 2018 Devsy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Identity.h"

@interface MSTIdentityImporter : NSObject <NSXMLParserDelegate>
- (void)importIdentitiesFromFile:(NSURL *)fileUrl withBlock:(void (^)(NSArray <Identity *> *items))block;
@end
