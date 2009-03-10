//
//  PrefController.h
//  wiipad
//
//  Created by Taylor Veltrop on 5/21/08.
//  Copyright 2008,2009 Taylor Veltrop. All rights reserved.
//  Read COPYRIGHT.txt for legal info.
//  See ChangeLog.txt as well.
//

#import <Cocoa/Cocoa.h>
#import <WiiRemote/WiiRemote.h>

@class WiiMoteController;
@class AppController;

@interface PrefController : NSWindowController {
	IBOutlet NSTableView* keyTable;
	IBOutlet NSTableView* mouseKeyTable;
	IBOutlet NSButton* HIDEnabledButton;
	IBOutlet NSButton* HIDinvertX;
	IBOutlet NSButton* HIDinvertY;
	IBOutlet NSButton* HIDinvertZ;
	IBOutlet NSMatrix* HIDorientation;
	IBOutlet NSButton* HIDoverlapCC;
	IBOutlet NSButton* KBEnabledButton;
	IBOutlet NSButton* MouseEnabledButton;
	IBOutlet NSButton* mouseInvertX;
	IBOutlet NSButton* mouseInvertY;
	IBOutlet NSButton* mouseSwapXY;
	IBOutlet NSButton* UpdateCheckEnabledButton;
	IBOutlet NSTextField* prefHelpText;
	IBOutlet NSTextField* prefHelpTextMouse;
	IBOutlet NSPopUpButton* mouseControllerButton;
	IBOutlet NSPopUpButton* mouseDataSourceButton;
	IBOutlet NSPopUpButton* xyzSourceButton;
	IBOutlet NSPopUpButton* RxyzSourceButton;
	IBOutlet NSPopUpButton* HIDsettingsSet;
	IBOutlet NSTextField* xyzSourceTxt;
	IBOutlet NSTextField* rxyzSourceTxt;
	IBOutlet NSTextField* noteUnifiedTxt;
	IBOutlet NSTextField* noteBBTxt;
	IBOutlet NSTextField* mouseSensitivityTxt;
	IBOutlet NSSlider* mouseSensitivity;
	IBOutlet NSMatrix* mouseMovementStyle;
	
	IBOutlet WiiMoteController* wiiController;
	IBOutlet AppController* appControl;
	
	BOOL _isSettingKeyPreferences;						// for when the user is interactivly setting preferences
	BOOL _isSettingMousePreferences;
}
- (void) awakeFromNib;
- (void) saveKeyBindings;
- (void) loadKeyBindings;
- (void) saveMouseBindings;
- (void) loadMouseBindings;
- (void) saveHIDsettings;
- (void) loadHIDsettings;

#pragma mark -
#pragma mark GUI Delegates, DataSources, etc.
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification;
- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(int)rowIndex;

#pragma mark -
#pragma mark GUI Callbacks
- (IBAction)setIsUsingMouseEmu:(id)sender;
- (IBAction)setIsUsingKBEmu:(id)sender;
- (IBAction)setIsUsingVirtualHID:(id)sender;
- (IBAction)mouseSourceSelected:(id)sender;
- (IBAction)syncHIDsettingsGUI:(id)sender;

#pragma mark -
#pragma mark Utility functions for interaction with WiiMoteController, AppController
- (void)setTable:(NSTableView*)tableView isEnabled:(BOOL)enabled;	// work around for the fact that we cant disable a table as a whole
- (void)setAutoUpdate:(int)state;
- (BOOL)isKBEnabled;
- (BOOL)isHIDEnabled;
- (BOOL)isMouseEnabled;
- (BOOL)isSettingKeyPreferences;
- (BOOL)isSettingMousePreferences;
- (void)setKey:(WiiButtonType)type controllerID:(int)cID;
- (BOOL)getKeyBinding:(WiiButtonType)type keyCode:(CGKeyCode*)key controllerID:(int)cID;
- (void)setMouse:(WiiButtonType)type controllerID:(int)cID;
- (BOOL)getMouseBinding:(WiiButtonType)type keyCode:(CGKeyCode*)key controllerID:(int)cID;
- (BOOL)isMotionRequired:(int)cID;
- (BOOL)isIRrequired:(int)cID;
- (BOOL)isOverlapRequired:(int)cID;
- (int)getMouseAssignment:(int)type controllerID:(int)cID;
- (int)getJoystickAssignment:(int)type controllerID:(int)cID;
- (void)getJoystickOrientation:(int*)orient controllerID:(int)cID;
- (int) getMouseSensitivity;
- (int) getMouseMovementStyle;
- (void) getMouseOrientation:(int*)orient;

@end
