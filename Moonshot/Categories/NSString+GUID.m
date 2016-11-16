//
//  NSString+GUID.m
//  Moonshot
//
//  Created by Elena Jakjoska on 11/14/16.
//

#import "NSString+GUID.h"

@implementation NSString (GUID)

+ (NSString *)getUUID {
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    return (__bridge NSString *)string;
}
@end
