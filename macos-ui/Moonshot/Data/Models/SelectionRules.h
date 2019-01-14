//
//  SelectionRules.h
//  Moonshot
//
//  Created by Elena Jakjoska on 12/28/17.
//

#import <Foundation/Foundation.h>

@interface SelectionRules : NSObject

@property (nonatomic, strong) NSString *pattern;
@property (nonatomic, strong) NSString *alwaysConfirm;

- (id)initWithDictionaryObject:(NSDictionary *)selectionDict;

@end
