//
//  AppController.h
//  wiipad
//
//  Created by Taylor Veltrop on 5/21/08.
//  Copyright 2008 Taylor Veltrop. All rights reserved.
//  Read COPYRIGHT.txt for legal info.
//  See comments in WiiMoteController.m for a synopsis.
//  See ChangeLog.txt as well.
//

#import <Cocoa/Cocoa.h>

@class PrefController;

@interface AppController : NSController {
	NSStatusItem *wii_menu;
	NSTimer*	animationTimer;
	
	IBOutlet NSMenu* mainMenu;
	IBOutlet NSMenuItem* scanMenuTextItem;
	IBOutlet NSWindow* prefWindow;
	IBOutlet NSWindow* aboutWindow;
	IBOutlet NSWindow* helpWindow;
	
	IBOutlet PrefController* prefs;
	
	NSImage* icons[4];
}
- (id) init;
- (void) awakeFromNib;

#pragma mark -
#pragma mark GUI Delegates, DataSources, CallBacks, etc.
- (void)tick;
- (IBAction)openWindow:(id)sender;
- (IBAction)donate:(id)sender;
- (IBAction)checkForUpdates:(id)sender;

#pragma mark -
#pragma mark GUI Control access
- (void)setMenuItem:(int)item enabled:(BOOL)isEnabled;
- (void)setMenuAnimationEnabled:(BOOL)isEnabled;
- (void)setMenuConnectedIconState:(BOOL)isConnected;

@end
