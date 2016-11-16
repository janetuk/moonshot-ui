//
//  NSDate+Helper.h
//  Moonshot
//
//  Created by Elena Jakjoska on 11/7/16.
//

#import <Foundation/Foundation.h>

@interface NSDate (NSDateFormatter)
+ (NSString *)formatDate:(NSDate *)date withFormat:(NSString *)dateFormat;
@end
