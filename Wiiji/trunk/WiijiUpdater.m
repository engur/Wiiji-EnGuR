//
//  WiijiUpdater.m
//  wiipad
//
//  Created by Taylor Veltrop on 5/2/08.
//  Copyright 2008 Taylor Veltrop. All rights reserved.
//  Read COPYRIGHT.txt for legal info.
//  See ChangeLog.txt as well.
//

#import "AppController.h"
#import "WiiMoteController.h"
#import "PrefController.h"
#import "WiijiUpdater.h"

@implementation WiijiUpdater

+ (void)doUpdate:(id)sender 
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

	NSString* verUrlStr = @"http://wiiji.sourceforge.net/CurrentVersion.txt";
	NSURL * verUrl = [NSURL URLWithString:verUrlStr];
	NSError *theError;
	NSString* verStr = [NSString stringWithContentsOfURL:verUrl encoding:NSASCIIStringEncoding error:&theError];
	
   if (!verStr) {	// TODO: check theError???
		//NSAlert *theAlert = [NSAlert alertWithError:theError];
		//[theAlert runModal]; // ignore return value
		
		// we dont need to report the error
		//NSRunAlertPanel(@"Update Error!", @"An error occured while contacting update server.", @"OK", nil, nil);
	}
	else {
		NSDictionary* mainDict = [[NSBundle mainBundle] infoDictionary];
		NSString* myVer = [mainDict objectForKey:@"CFBundleVersion"];										// CFBundleVersion key in infoDictionary

		//NSLog(@"Current Version: %f local: %f", [verStr floatValue], [myVer floatValue]);

		int ret = 0;
		[NSApp activateIgnoringOtherApps:YES];
		if ([verStr floatValue] > [myVer floatValue]) {
			if ([sender class] != [AppController class])
				ret = NSRunAlertPanel(@"Update Available!", @"An update to Wiiji is available!", @"Download", @"Cancel", nil); // 1, 0, -1
			else	// only permit disabling the check if the sender was a programmed response
				ret = NSRunAlertPanel(@"Update Available!", @"An update to Wiiji is available!", @"Download", @"Cancel", @"Disable Check");
			
			if (ret == 1) {
				NSWorkspace * ws = [NSWorkspace sharedWorkspace];
				NSString* urlstr = [NSString stringWithFormat:@"http://downloads.sourceforge.net/wiiji/Wiiji-%@.dmg",verStr, nil];
				NSURL * url = [NSURL URLWithString:urlstr];
				[ws openURL: url];
			}
		}
		else {
			if ([sender class] != [PrefController class]) // only show the dialog if the sender was not a programed response (only show if we clicked the menu)
				ret = NSRunAlertPanel(@"No Update Available", @"No update to Wiiji is available.", @"OK", nil, nil);
		}
		
		if (ret == -1) {
			if ([sender respondsToSelector:@selector(setAutoUpdate:)]) {
				PrefController* sent_from = sender;
				[sent_from setAutoUpdate:NSOffState];
			}
		}
	}
	
	[pool release];
}

@end
