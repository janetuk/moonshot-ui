//
//  Identity+Utilities.m
//  Moonshot
//
//  Created by Elena Jakjoska on 12/15/16.
//

#import "Identity+Utilities.h"
#import "MSTConstants.h"

@implementation Identity (Utilities)

#pragma mark - Get Services String

+ (NSString *)getServicesStringForIdentity:(Identity *)identityObject {
    BOOL areWeDealingWithEmptyServicesList = identityObject.servicesArray.count == 0;
    NSArray *reversedArray = [[identityObject.servicesArray reverseObjectEnumerator] allObjects];
    if (areWeDealingWithEmptyServicesList) {
        return NSLocalizedString(@"None", @"");
    } else {
        return [reversedArray componentsJoinedByString: @"; "];
    }
}

@end
