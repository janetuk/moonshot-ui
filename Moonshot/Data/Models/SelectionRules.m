//
//  SelectionRules.m
//  Moonshot
//
//  Created by Elena Jakjoska on 12/28/17.
//  Copyright © 2017 Devsy. All rights reserved.
//

#import "SelectionRules.h"

@implementation SelectionRules

- (id)initWithDictionaryObject:(NSDictionary *)selectionDict {
    self = [super init];
    if(self){
        if([selectionDict isKindOfClass:[NSDictionary class]]){
            self.pattern = selectionDict[@"pattern"];
            self.alwaysConfirm = selectionDict[@"always-confirm"];
        }
    }
    return self;
}

- (NSDictionary *)getDictionaryRepresentation {
    NSMutableDictionary *resultDict = [[NSMutableDictionary alloc] init];
    [resultDict setObject:self.pattern forKey:@"pattern"];
    [resultDict setObject:self.alwaysConfirm forKey:@"always-confirm"];
    return resultDict;
}

- (id)initWithCoder:(NSCoder *)decoder {
    if((self = [super init])) {
        self.pattern = [decoder decodeObjectForKey:@"pattern"];
        self.alwaysConfirm = [decoder decodeObjectForKey:@"always-confirm"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.pattern forKey:@"pattern"];
    [encoder encodeObject:self.alwaysConfirm forKey:@"always-confirm"];
}

@end
