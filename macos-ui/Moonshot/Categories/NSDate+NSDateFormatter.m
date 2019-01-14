//
//  NSDate+Helper.m
//  Moonshot
//
//  Created by Elena Jakjoska on 11/7/16.
//

#import "NSDate+NSDateFormatter.h"

@implementation NSDate (NSDateFormatter)

#pragma mark - NSDateFormatter Date to String

+ (NSString *)formatDate:(NSDate *)date withFormat:(NSString *)dateFormat {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:dateFormat];
    return [dateFormatter stringFromDate:date];
}
@end
