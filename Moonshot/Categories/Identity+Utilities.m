//
//  Identity+Utilities.m
//  Moonshot
//
//  Created by Elena Jakjoska on 12/15/16.
//  Copyright © 2016 Devsy. All rights reserved.
//

#import "Identity+Utilities.h"
#import "MSTConstants.h"

@implementation Identity (Utilities)

#pragma mark - Get Services String

+ (NSString *)getServicesStringForIdentity:(Identity *)identityObject {
    BOOL areWeDealingWithNoIdentity = [identityObject.identityId isEqualToString:MST_NO_IDENTITY];
    BOOL areWeDealingWithEmptyServicesList = identityObject.servicesArray.count == 0;
    NSArray *reversedArray = [[identityObject.servicesArray reverseObjectEnumerator] allObjects];
    if (areWeDealingWithNoIdentity) {
        return NSLocalizedString(@"No_Identity", @"");
    } else if (areWeDealingWithEmptyServicesList) {
        return NSLocalizedString(@"None", @"");
    } else {
        return [reversedArray componentsJoinedByString: @"; "];
    }
}

@end
