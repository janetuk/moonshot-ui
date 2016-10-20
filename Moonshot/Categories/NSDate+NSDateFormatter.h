//
//  NSDate+Helper.h
//  Moonshot
//
//  Created by Elena Jakjoska on 11/7/16.
//  Copyright © 2016 Devsy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (NSDateFormatter)
+ (NSString *)formatDate:(NSDate *)date withFormat:(NSString *)dateFormat;
@end
