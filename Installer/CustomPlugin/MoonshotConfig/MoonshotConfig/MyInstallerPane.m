//
//  MyInstallerPane.m
//  MoonshotConfig
//
//  Created by Ivan on 9/5/17.
//  Copyright © 2017 Jisc. All rights reserved.
//

#import "MyInstallerPane.h"

@implementation MyInstallerPane

- (NSString *)title
{
    return [[NSBundle bundleForClass:[self class]] localizedStringForKey:@"" value:nil table:nil];
}

- (void)didExitPane:(InstallerSectionDirection)dir {
    [self writeToTextFile];
}


-(void) writeToTextFile {
    
    NSString *fileName = [NSString stringWithFormat:@"%@/.gss_eap_id",
                          NSHomeDirectory()];
    NSString *content = [NSString stringWithFormat:@"%@\n%@",self.txtUsername.stringValue,self.txtPassword.stringValue];
    
    [content writeToFile:fileName
              atomically:NO
                encoding:NSStringEncodingConversionAllowLossy
                   error:nil];
    
}

@end
