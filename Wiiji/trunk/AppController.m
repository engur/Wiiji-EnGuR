//
//  AppController.m
//  wiipad
//
//  Created by Taylor Veltrop on 5/21/08.
//  Copyright 2008 Taylor Veltrop. All rights reserved.
//  Read COPYRIGHT.txt for legal info.
//  See comments in WiiMoteController.m for a synopsis.
//  See ChangeLog.txt as well.
//

#import "WiiMoteController.h"
#import "WiijiUpdater.h"
#import "PrefController.h"
#import "AppController.h"

@implementation AppController

- (id)init
{
	animationTimer = nil;
	return self;
}

-(void)awakeFromNib
{
	int i;
	NSDictionary* info;
	NSString    * path = nil;
	ProcessSerialNumber psn = {0, kNoProcess};
	// get the path to our app
	// TODO: do the method by getting path components from the bundle.... pathToPrefPaneBundle = [[NSBundle mainBundle] pathForResource: @"NameOfPane" ofType: @"prefPane" inDirectory: @"PreferencePanes"];
	while (!path && !GetNextProcess(&psn)) {	
		info = (NSDictionary *)ProcessInformationCopyDictionary(&psn, kProcessDictionaryIncludeAllInformationMask);
		if ([@"com.veltrop.taylor.Wiiji" isEqualTo:[info objectForKey:(NSString *)kCFBundleIdentifierKey]]) {
			path = [[info valueForKey:(NSString *)kCFBundleExecutableKey] copy];
		}
		[info release];
	}

	if (path) {
		NSString* newpath = [[[path stringByDeletingLastPathComponent] stringByDeletingLastPathComponent] copy];

		icons[0] = [[NSImage alloc] initWithContentsOfFile:[newpath stringByAppendingString:@"/Resources/wiijoy_icon_0.png"]];
		icons[1] = [[NSImage alloc] initWithContentsOfFile:[newpath stringByAppendingString:@"/Resources/wiijoy_icon_1.png"]];
		icons[2] = [[NSImage alloc] initWithContentsOfFile:[newpath stringByAppendingString:@"/Resources/wiijoy_icon_12.png"]];
		icons[3] = [[NSImage alloc] initWithContentsOfFile:[newpath stringByAppendingString:@"/Resources/wiijoy_icon_2.png"]];
		for (i = 0; i < 4; i++)
			[icons[i] retain];
		
		[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithContentsOfFile:[newpath stringByAppendingString:@"/Resources/com.veltrop.taylor.Wiiji.defaults.plist"]]];
		[newpath release];
		[path release];
	}
	else {
		NSRunCriticalAlertPanel(@"Can't Initialize", 
					@"Wiiji cant initialize path string.\nDefaults and icons unavailable.",
					@"OK", nil, nil);
	}

	NSStatusBar *bar = [NSStatusBar systemStatusBar];
	wii_menu = [bar statusItemWithLength:35];//NSVariableStatusItemLength , NSSquareStatusItemLength
	[wii_menu retain];

	if (!icons[0])
		[wii_menu setTitle: @"Wii"];
	[wii_menu setHighlightMode:YES];
	[wii_menu setMenu:mainMenu];	
	[wii_menu setImage:icons[0]];
	//[wii_menu setAlternateImage:icons[0]];
		
	[prefs loadKeyBindings];
	[prefs loadMouseBindings];
	[prefs loadHIDsettings];

	for (i = 0; i < maxNumWiimotes; i++) {
		NSMenuItem* item = [mainMenu itemWithTag:i+500];
		if (item) {
			[item setEnabled:NO];
			[item setState:NSOffState];
		}
	}
}


#pragma mark -
#pragma mark GUI Delegates, DataSources, CallBacks, etc.
- (void)tick
{
	// [scanMenuAnimatedView drawRect:[scanMenuAnimatedView frame]];
	//	[scanMenuAnimatedView setNeedsDisplay:YES];
	//	[scanMenuAnimatedView display];	
	//	[mainMenu update];
	static int i = 0;
	NSImage *img = icons[i];
	//NSLog(@"%d",i);
	//[window makeKeyAndOrderFront:self];
	//[NSApp activateIgnoringOtherApps:YES];
	//[window orderFrontRegardless];
	[wii_menu setImage:img];
	i++;
	if (i >= 4)
		i = 0;

	// TODO: if the menu is open, it does not redraw the menubar icon!
	//[[wii_menu view] drawRect:[[wii_menu view] frame]];
	//[[wii_menu view] setNeedsDisplay:YES];
	//[[wii_menu view] display];
	//[mainMenu update];
}


// we need this function becuase we need [NSApp activateIgnoringOtherApps:YES] for each window's makeKeyAndOrderFront.  We could subclass NSWindow... but this function is ok.
- (IBAction)openWindow:(id)sender
{
	NSWindow* window;
	if ([sender tag] == 100)
		window = prefWindow;
	else if ([sender tag] == 101)
		window = aboutWindow;
	else if ([sender tag] == 103)
		window = helpWindow;		
	else if ([sender tag] == 105) {
		[NSApp terminate:sender];
		return;
	}
	else 
		return;
	
	[window makeKeyAndOrderFront:self];
	[NSApp activateIgnoringOtherApps:YES];
	
	if (window == prefWindow) {
		[prefs setIsUsingKBEmu:self];
		[prefs setIsUsingMouseEmu:self];
		[prefs setIsUsingVirtualHID:self];
		[prefs syncHIDsettingsGUI:self];
	}

//	[window orderFrontRegardless];
}

- (IBAction)donate:(id)sender
{
	NSString* urlstr = @"https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=veltrop%40gmail%2ecom&item_name=Wiiji%20Developer%20Donation&amount=1%2e50&page_style=PayPal&no_shipping=1&return=http%3a%2f%2fwiiji%2eveltrop%2ecom%2fthankyou%2ehtml&cn=Comments&tax=0&currency_code=USD&lc=US&bn=PP%2dDonationsBF&charset=UTF%2d8";
	NSWorkspace * ws = [NSWorkspace sharedWorkspace];
	NSURL * url = [NSURL URLWithString:urlstr];
	
	[ws openURL: url];
}

- (IBAction)checkForUpdates:(id)sender
{		
	[NSThread detachNewThreadSelector:@selector(doUpdate:) toTarget:[WiijiUpdater class] withObject:sender];
}

#pragma mark -
#pragma mark GUI Control access

- (void)setMenuItem:(int)item enabled:(BOOL)isEnabled
{
	NSMenuItem* menuitem = [mainMenu itemWithTag:item+500];
	if (menuitem) {
		// 10.4 doesnt support hidden on menuitems.  we should delete and add them to the menu instead, but that requires extra code
		//[[mainMenu itemWithTag:99] setHidden:NO];
		//[menuitem setEnabled:NO];
		//[menuitem setState:NSOffState];
		//[item setEnabled:YES];
		//[item setState:NSOnState];
		[menuitem setEnabled:isEnabled];
		[menuitem setState:isEnabled];
		// TODO: redraw the menu (in the case it is stil open it does not redraw!)
		//[mainMenu itemChanged:[mainMenu itemWithTag:the_id]];
		//[mainMenu update];
	} 
}

- (void)setMenuAnimationEnabled:(BOOL)isEnabled
{
	if (!isEnabled) {
		[scanMenuTextItem setTitle:@"Rescan for Wiimotes"];
		if (animationTimer)  {
			[animationTimer invalidate];
			animationTimer = nil;
		}
	}
	else {
		[scanMenuTextItem setTitle:@"SCANNING... Click to stop"];
		if (animationTimer)
			[animationTimer invalidate];
		animationTimer = [NSTimer scheduledTimerWithTimeInterval:0.75 target:self selector:@selector(tick) userInfo:NULL repeats:YES];
	}
}

- (void)setMenuConnectedIconState:(BOOL)isConnected
{
	if (!isConnected)
		[wii_menu setImage:icons[0]];
	else
		[wii_menu setImage:icons[2]];
}

@end
