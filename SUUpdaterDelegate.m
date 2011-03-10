/*
 Author: Jan Lehnardt <jan@apache.org>
 This is Apache 2.0 licensed free software
 */

#import "SUUpdaterDelegate.h"
#import "Sparkle/Sparkle.h"

@implementation SUUpdaterDelegate

-(void)willInstallUpdate:(SUAppcastItem *)update
{
	[[[NSApplication sharedApplication] delegate] ensureFullCommit];
}


@end
