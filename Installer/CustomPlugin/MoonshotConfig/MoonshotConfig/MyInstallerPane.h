//
//  MyInstallerPane.h
//  MoonshotConfig
//
//  Created by Ivan on 9/5/17.
//  Copyright © 2017 Jisc. All rights reserved.
//

#import <InstallerPlugins/InstallerPlugins.h>

@interface MyInstallerPane : InstallerPane
@property (weak) IBOutlet NSTextField *txtUsername;
@property (weak) IBOutlet NSSecureTextField *txtPassword;

@end
