//
//  PrefController.m
//  wiipad
//
//  Created by Taylor Veltrop on 5/21/08.
//  Copyright 2008,2009 Taylor Veltrop. All rights reserved.
//  Read COPYRIGHT.txt for legal info.
//  See ChangeLog.txt as well.
//

#include <WiiRemote/wiimote_types.h>
#import "AppController.h"
#import "WiiMoteController.h"
#import "PrefController.h"

#define prefHelpString @"Click on a row in the above table to edit it."

// these indices corespond to wiimote_types.h
char buttonStrings[WiiNumberOfButtons][16] = {
	"Remote 1", "Remote 2", "Remote A", "Remote B", "Remote -", "Remote Home", "Remote +",  "Remote Up", "Remote Down", "Remote Left", "Remote Right",
	"Nunchuck Z", "Nunchuck C",
	"Classic Y", "Classic X", "Classic A", "Classic B", "Classic -", "Classic Home", "Classic +", "Classic Left", "Classic Right", "Classic Down", "Classic Up",     "Classic L", "Classic R", "Classic zL", "Classic zR"
};

#define numEmulatedKeys 98
// the indices of this corespond to the nstable for the prefs
char keyStrings[numEmulatedKeys][16] = {
	"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
	"0", "1", "2", "3", "4", "5", "6", "7", "8", "9",	
	"-", "+", "`", "[", "]", ";", "'", ",", ".", "/","\\", 	
	"Space", "Return", "Delete", "Tab", "Esc", "Caps Lock", "Num Lock", "Scroll Lock", "Pause", "Backspace", "Insert", 
	"Cursor Up", "Cursor Down", "Cursor Left", "Cursor Right", "Page Up", "Page Down", "Home", "End", 
	"KP 0", "KP 1", "KP 2", "KP 3", "KP 4", "KP 5", "KP 6", "KP 7", "KP 8", "KP 9", "KP Enter", "KP .", "KP +", "KP -", "KP *", "KP /", 
	"F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12", 
	"Shift", "Ctrl", "Option", "Command"
};
// the indices of this corespond to the nstable for the prefs
UInt8 keyCodes[numEmulatedKeys] = {
	  0, 11,  8,  2, 14,  3,  5,  4, 34, 38, 40, 37, 46, 45, 31, 35, 12, 15,  1, 17, 32,  9, 13,  7, 16,  6,  
	 29, 18, 19, 20, 21, 23, 22, 26, 28, 25,
	 27, 24, 10, 33, 30, 41, 39, 43, 47, 44, 42, 
	 49, 36,117, 48, 53, 57, 71,107,113, 51,114,
	126,125,123,124,116,121,115,119,
	 82, 83, 84, 85, 86, 87, 88, 89, 91, 92, 76, 65, 69, 78, 67, 75,
	122,120, 99,118, 96, 97, 98,100,101,109,103,111,
	 56, 59, 58, 55
};
int keyBindings[maxNumWiimotes][WiiNumberOfButtons] = {
	{  0, 11,  8,  2, 14,  3,  5,  4, 34, 38, 40, -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1 }, 
	{ 37, 46, 45, 31, 35, 12, 15,  1, 17, 32,  9, -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1 },
	{ -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1 },
	{ -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1 }
};

#define numEmulatedMouseKeys 5
// the indices of this corespond to the nstable for the prefs
char mouseKeyStrings[numEmulatedMouseKeys][16] = {
	"Left Button", "Double Left", "Triple Left", "Center Button", "Right Button", 
};
// the indices of this corespond to the nstable for the prefs
UInt8 mouseKeyCodes[numEmulatedMouseKeys] = {
	kCGMouseButtonLeft, 3, 4, kCGMouseButtonCenter, kCGMouseButtonRight
};
int mouseKeyBindings[maxNumWiimotes][WiiNumberOfButtons] = {
	{ -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1 }, 
	{ -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1 },
	{ -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1 },
	{ -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1 }
};
struct HIDsettingsStruct {
	int xyzSource;
	int rxyzSource;
	int orientation;
	int invertX;
	int invertY;
	int invertZ;
	int overlap;
};
struct HIDsettingsStruct HIDsettings[5] = {
 { 10, 11, 0, 0, 1, 0, 0},
 { 10, 11, 0, 0, 1, 0, 0},
 { 10, 11, 0, 0, 1, 0, 0},
 { 10, 11, 0, 0, 1, 0, 0},
 { 10, 11, 0, 0, 1, 0, 0}
}; 

@implementation PrefController

-(void)awakeFromNib
{
	_isSettingMousePreferences = _isSettingKeyPreferences = NO;

//	[self setIsUsingKBEmu:self];
//	[self setIsUsingMouseEmu:self];
//	[self setIsUsingVirtualHID:self];
//	[self syncHIDsettingsGUI:self];
	
//	if ([UpdateCheckEnabledButton state] == NSOnState)
//		[appControl checkForUpdates:self];
	BOOL updateCheck = [[NSUserDefaults standardUserDefaults] boolForKey:@"UpdateCheckEnabled"];
	if (updateCheck)
		[appControl checkForUpdates:self];
		
	[RxyzSourceButton setAutoenablesItems:NO];
}

- (void) saveKeyBindings
{
	int i,j;
	NSMutableArray* saveData = [NSMutableArray arrayWithCapacity:(maxNumWiimotes * WiiNumberOfButtons)];
	for (i = 0; i < maxNumWiimotes; i++) {
		for (j = 0; j < WiiNumberOfButtons; j++) {
			[saveData addObject:[NSNumber numberWithInt:keyBindings[i][j]]];
		}
	}
	
	NSUserDefaults* defs = [NSUserDefaults standardUserDefaults];
	[defs setObject:saveData forKey:@"Bindings"];
	[defs synchronize];
}

- (void) loadKeyBindings
{
	NSArray* loadData = [[NSUserDefaults standardUserDefaults] arrayForKey:@"Bindings"];
	int i,j;
	if (loadData != nil) {
		for (i = 0; i < maxNumWiimotes; i++) {
			for (j = 0; j < WiiNumberOfButtons; j++) {
				keyBindings[i][j] = [[loadData objectAtIndex:(i * WiiNumberOfButtons + j)] intValue];
			}
		}
		[keyTable reloadData];
	}
}

- (void) saveMouseBindings
{
	int i,j;
	NSMutableArray* saveData = [NSMutableArray arrayWithCapacity:(maxNumWiimotes * WiiNumberOfButtons)];
	for (i = 0; i < maxNumWiimotes; i++) {
		for (j = 0; j < WiiNumberOfButtons; j++) {
			[saveData addObject:[NSNumber numberWithInt:mouseKeyBindings[i][j]]];
		}
	}
	
	NSUserDefaults* defs = [NSUserDefaults standardUserDefaults];
	[defs setObject:saveData forKey:@"MouseBindings"];
	[defs synchronize];
}

- (void) loadMouseBindings
{
	NSArray* loadData = [[NSUserDefaults standardUserDefaults] arrayForKey:@"MouseBindings"];
	int i,j;
	if (loadData != nil) {
		for (i = 0; i < maxNumWiimotes; i++) {
			for (j = 0; j < WiiNumberOfButtons; j++) {
				mouseKeyBindings[i][j] = [[loadData objectAtIndex:(i * WiiNumberOfButtons + j)] intValue];
			}
		}
		[mouseKeyTable reloadData];
	}
}

- (void) saveHIDsettings
{
	int i;
	NSMutableArray* saveData = [NSMutableArray arrayWithCapacity:(7 * 5)];
	for (i = 0; i < 5; i++) {
		[saveData addObject:[NSNumber numberWithInt:HIDsettings[i].xyzSource]];
		[saveData addObject:[NSNumber numberWithInt:HIDsettings[i].rxyzSource]];
		[saveData addObject:[NSNumber numberWithInt:HIDsettings[i].invertX]];
		[saveData addObject:[NSNumber numberWithInt:HIDsettings[i].invertY]];
		[saveData addObject:[NSNumber numberWithInt:HIDsettings[i].invertZ]];
		[saveData addObject:[NSNumber numberWithInt:HIDsettings[i].orientation]];
		[saveData addObject:[NSNumber numberWithInt:HIDsettings[i].overlap]];
	}
	
	NSUserDefaults* defs = [NSUserDefaults standardUserDefaults];
	[defs setObject:saveData forKey:@"HIDsettings"];
	[defs synchronize];
}

- (void) loadHIDsettings
{
	NSArray* loadData = [[NSUserDefaults standardUserDefaults] arrayForKey:@"HIDsettings"];
	int i;
	if (loadData != nil) {
		for (i = 0; i < 5; i++) {
				HIDsettings[i].xyzSource   = [[loadData objectAtIndex:(i * 7 + 0)] intValue];
				HIDsettings[i].rxyzSource  = [[loadData objectAtIndex:(i * 7 + 1)] intValue];
				HIDsettings[i].invertX     = [[loadData objectAtIndex:(i * 7 + 2)] intValue];
				HIDsettings[i].invertY     = [[loadData objectAtIndex:(i * 7 + 3)] intValue];
				HIDsettings[i].invertZ     = [[loadData objectAtIndex:(i * 7 + 4)] intValue];
				HIDsettings[i].orientation = [[loadData objectAtIndex:(i * 7 + 5)] intValue];
				HIDsettings[i].overlap     = [[loadData objectAtIndex:(i * 7 + 6)] intValue];
		}
		
		[self syncHIDsettingsGUI:self];
	}	
}

#pragma mark -
#pragma mark GUI Delegates, DataSources, etc.
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if (aTableView == keyTable) {
		int colIndex = [[aTableColumn identifier]intValue];
		if (colIndex == 0) {
			return [NSString stringWithCString:keyStrings[rowIndex]];
		}
		else if (colIndex == 1) {
			int key_code = keyCodes[rowIndex];
			int i,j;
			for (i = 0; i < maxNumWiimotes; i++) {						// search to see if the hid key code is used anywhere
				for (j = 0; j < WiiNumberOfButtons; j++) {
					if (keyBindings[i][j] == key_code) {				// if a wii button is found to be bound to thi hid key code
						// return a string describing the wii remote
						return [NSString stringWithFormat:@"#%d %s", i+1, buttonStrings[j], nil];
					}
				}
			}
		}
	}
	else if (aTableView == mouseKeyTable) {
		int colIndex = [[aTableColumn identifier]intValue];
		if (colIndex == 0) {
			return [NSString stringWithCString:mouseKeyStrings[rowIndex]];
		}
		else if (colIndex == 1) {
			int key_code = mouseKeyCodes[rowIndex];
			int i,j;
			for (i = 0; i < maxNumWiimotes; i++) {
				for (j = 0; j < WiiNumberOfButtons; j++) {
					if (mouseKeyBindings[i][j] ==  key_code) {
						// return a string describing the wii remote
						return [NSString stringWithFormat:@"#%d %s", i+1, buttonStrings[j], nil];
					}
				}
			}
		}
	}
	
	return nil;
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	if (aTableView == keyTable) {
		return numEmulatedKeys;
	}
	else if (aTableView == mouseKeyTable) {
		return numEmulatedMouseKeys;
	}
	return 0;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
// TODO: these two very separate if statements could be merged a little bit for effictiency and ease to modify.. but will become difficult to read
	if ([aNotification object] == keyTable) {
		int selectedRow = [keyTable selectedRow];
		if (selectedRow >= 0 && selectedRow < numEmulatedKeys ) {
			_isSettingKeyPreferences = YES;
			NSString* string = [NSString stringWithFormat: @"Press desired button for %s on desired Wii remote now.", keyStrings[selectedRow], nil];
			[prefHelpText setStringValue:string];
			[prefHelpText setTextColor:[NSColor redColor]];
		}
		else {
			_isSettingKeyPreferences = NO;
			[prefHelpText setStringValue:prefHelpString];
			[prefHelpText setTextColor:[NSColor controlTextColor]];
		}
	}
	else if ([aNotification object] == mouseKeyTable) {
		int selectedRow = [mouseKeyTable selectedRow];
		if (selectedRow >= 0 && selectedRow < numEmulatedMouseKeys ) {
			_isSettingMousePreferences = YES;
			NSString* string = [NSString stringWithFormat: @"Press desired button for %s on desired Wii remote now.", mouseKeyStrings[selectedRow], nil];
			[prefHelpTextMouse setStringValue:string];
			[prefHelpTextMouse setTextColor:[NSColor redColor]];
		}
		else {
			_isSettingMousePreferences = NO;
			[prefHelpTextMouse setStringValue:prefHelpString];
			[prefHelpTextMouse setTextColor:[NSColor controlTextColor]];
		}
	}
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(int)rowIndex
{
	if (aTableView == keyTable) {
		if ([KBEnabledButton state] == NSOnState)
			return YES;
		else
			return NO;
	}
	else if (aTableView == mouseKeyTable) {
		if ([MouseEnabledButton state] == NSOnState)
			return YES;
		else
			return NO;
	}
	return NO;
}

#pragma mark -
#pragma mark GUI Callbacks
- (IBAction)setIsUsingMouseEmu:(id)sender
{
//	if (sender == MouseEnabledButton) {
		[mouseKeyTable selectRowIndexes:nil byExtendingSelection:NO];
		_isSettingMousePreferences = NO;
		if ([MouseEnabledButton state] == NSOnState) {
			[self setTable:mouseKeyTable isEnabled:YES];
			[prefHelpTextMouse setStringValue:prefHelpString];		
			[prefHelpTextMouse setTextColor:[NSColor blackColor]];
			[mouseControllerButton setEnabled:NSOnState];
			[mouseDataSourceButton setEnabled:NSOnState];
			[mouseInvertX setEnabled:NSOnState];
			[mouseInvertY setEnabled:NSOnState];
			[mouseSwapXY setEnabled:NSOnState];
			[mouseSensitivityTxt setTextColor:[NSColor blackColor]];
			[mouseSensitivity setEnabled:NSOnState];
			[mouseMovementStyle setEnabled:NSOnState];
		} else {
			[self setTable:mouseKeyTable isEnabled:NO];
			[prefHelpTextMouse setStringValue:@""];
			[mouseControllerButton setEnabled:NSOffState];
			[mouseDataSourceButton setEnabled:NSOffState];	
			[mouseInvertX setEnabled:NSOffState];
			[mouseInvertY setEnabled:NSOffState];
			[mouseSwapXY setEnabled:NSOffState];	
			[mouseSensitivityTxt setTextColor:[NSColor disabledControlTextColor]];
			[mouseSensitivity setEnabled:NSOffState];
			[mouseMovementStyle setEnabled:NSOffState];			
		}
		[wiiController syncEnableIR];
//	}
}

- (IBAction)setIsUsingKBEmu:(id)sender
{
//	if (sender == KBEnabledButton) {
		[keyTable selectRowIndexes:nil byExtendingSelection:NO];
		_isSettingKeyPreferences = NO;
		if ([KBEnabledButton state] == NSOnState) {
			[self setTable:keyTable isEnabled:YES];
			[prefHelpText setStringValue:prefHelpString];	
			[prefHelpText setTextColor:[NSColor blackColor]];	
		} else {
			[self setTable:keyTable isEnabled:NO];
			[prefHelpText setStringValue:@""];
		}
//	}
}

- (IBAction)setIsUsingVirtualHID:(id)sender
{
	if ([HIDEnabledButton state] == NSOnState) {
		if (sender == HIDEnabledButton)
			[wiiController syncVirtualDrivers];
		[xyzSourceButton setEnabled:NSOnState];
		[RxyzSourceButton setEnabled:NSOnState];
		[HIDinvertX setEnabled:NSOnState];
		[HIDinvertY setEnabled:NSOnState];
		[HIDinvertZ setEnabled:NSOnState];
		[HIDorientation setEnabled:NSOnState];
		[HIDoverlapCC setEnabled:NSOnState];
		[HIDsettingsSet setEnabled:NSOnState];
		[xyzSourceTxt setTextColor:[NSColor blackColor]];
		[rxyzSourceTxt setTextColor:[NSColor blackColor]];
		[noteBBTxt setTextColor:[NSColor blackColor]];
		[noteUnifiedTxt setTextColor:[NSColor blackColor]];
	}
	else {
		if (sender == HIDEnabledButton)
			[wiiController closeVirtualDriver];
		[xyzSourceButton setEnabled:NSOffState];
		[RxyzSourceButton setEnabled:NSOffState];
		[HIDinvertX setEnabled:NSOffState];
		[HIDinvertY setEnabled:NSOffState];
		[HIDinvertZ setEnabled:NSOffState];
		[HIDorientation setEnabled:NSOffState];
		[HIDoverlapCC setEnabled:NSOffState];
		[HIDsettingsSet setEnabled:NSOffState];
		[xyzSourceTxt setTextColor:[NSColor disabledControlTextColor]];
		[rxyzSourceTxt setTextColor:[NSColor disabledControlTextColor]];
		[noteBBTxt setTextColor:[NSColor disabledControlTextColor]];
		[noteUnifiedTxt setTextColor:[NSColor disabledControlTextColor]];
	}
}

- (IBAction)mouseSourceSelected:(id)sender
{
	[wiiController syncEnableMotion];
	[wiiController syncEnableIR];
}

- (IBAction)syncHIDsettingsGUI:(id)sender
{
	int set = [HIDsettingsSet selectedTag];
	if (sender == HIDsettingsSet || sender == self || sender == appControl) {								// we want to load from the variables
		[xyzSourceButton selectItemWithTag:HIDsettings[set].xyzSource];
		[RxyzSourceButton selectItemWithTag:HIDsettings[set].rxyzSource];
		[HIDinvertX setState:HIDsettings[set].invertX];
		[HIDinvertY setState:HIDsettings[set].invertY];
		[HIDinvertZ setState:HIDsettings[set].invertZ];
		[HIDorientation selectCellWithTag:HIDsettings[set].orientation];
		[HIDoverlapCC setState:HIDsettings[set].overlap];
		
		[wiiController syncEnableIR];
		[wiiController syncEnableMotion];
	} else {																						// we want to save to the variables
		HIDsettings[set].xyzSource   = [xyzSourceButton selectedTag];
		HIDsettings[set].rxyzSource  = [RxyzSourceButton selectedTag];
		HIDsettings[set].invertX     = [HIDinvertX state];
		HIDsettings[set].invertY     = [HIDinvertY state];
		HIDsettings[set].invertZ     = [HIDinvertZ state];
		HIDsettings[set].orientation = [HIDorientation selectedTag];
		HIDsettings[set].overlap     = [HIDoverlapCC state];
			
		[self saveHIDsettings];
		[wiiController syncEnableIR];
		[wiiController syncEnableMotion];
		[wiiController centerJoysticks];
	}
	
	int i;
	for (i = 0; i < [RxyzSourceButton numberOfItems]; i++)
		[[RxyzSourceButton itemAtIndex:i] setEnabled:YES];
	
	if ([xyzSourceButton selectedTag] != 0) {
		NSMenuItem* item = [[RxyzSourceButton menu] itemWithTag:[xyzSourceButton selectedTag]];
		[item setEnabled:NO];
		[item setState:NSOffState];
	}
		
	[self setIsUsingVirtualHID:self];
}		
		

#pragma mark -
#pragma mark Utility functions for interaction with WiiMoteController, AppController, self

// as of tiger, you cant simply enable/disable table views and their contents, so this is going to be ugly...
- (void)setTable:(NSTableView*)tableView isEnabled:(BOOL)enabled
{
	NSArray* columns = [tableView tableColumns];
	NSEnumerator* columnsEnumerator = [columns objectEnumerator];
	NSTableColumn* aColumn = nil;
	NSColor* color;
	if (enabled)
		color = [NSColor controlTextColor];
	else
		color = [NSColor disabledControlTextColor];
	while ((aColumn = [columnsEnumerator nextObject])) {
		[[aColumn headerCell] setEnabled:enabled];
		[[aColumn dataCell] setEnabled:enabled];
		[[aColumn dataCell] setTextColor:color];
	}
	[tableView setEnabled:enabled];
	[tableView reloadData];
}

- (void) setAutoUpdate:(int)state
{
	[UpdateCheckEnabledButton setState:state];
	NSUserDefaults* defs = [NSUserDefaults standardUserDefaults];
	[defs setValue:[NSNumber numberWithInt:state] forKey:@"UpdateCheckEnabled"];
	[defs synchronize];
}


- (BOOL)isKBEnabled
{
	return [KBEnabledButton state] == NSOnState;
}

- (BOOL)isHIDEnabled
{
	return [HIDEnabledButton state] == NSOnState;
}

- (BOOL)isMouseEnabled
{
	return [MouseEnabledButton state] == NSOnState;
}

- (BOOL)isSettingKeyPreferences
{
	return _isSettingKeyPreferences;
}

- (BOOL)isSettingMousePreferences
{
	return _isSettingMousePreferences;
}

- (void)setKey:(WiiButtonType)type controllerID:(int)cID
{
	int selectedRow = [keyTable selectedRow];
	if (selectedRow >= 0 && selectedRow < numEmulatedKeys) {
		int key_code = keyCodes[selectedRow];
		int i,j;
		for (i = 0; i < maxNumWiimotes; i++) {  // search to see if someone else was using the binding and clear it
			for (j = 0; j < WiiNumberOfButtons; j++) {
				if (keyBindings[i][j] ==  key_code) {
					keyBindings[i][j] = -1;
				}
			}
		}
		keyBindings[cID][type] = key_code;  // set the number in the bindings array
		[keyTable selectRowIndexes:nil byExtendingSelection:NO];
		[prefHelpText setStringValue:prefHelpString];
		[prefHelpText setTextColor:[NSColor controlTextColor]];
		[keyTable reloadData]; // set the button string in the view
		[self saveKeyBindings];
		_isSettingKeyPreferences = NO;
	}
}

- (void)setMouse:(WiiButtonType)type controllerID:(int)cID
{
	int selectedRow = [mouseKeyTable selectedRow];
	if (selectedRow >= 0 && selectedRow < numEmulatedKeys) {
		int key_code = mouseKeyCodes[selectedRow];
		int i,j;
		for (i = 0; i < maxNumWiimotes; i++) {  // search to see if someone else was using the binding and clear it
			for (j = 0; j < WiiNumberOfButtons; j++) {
				if (mouseKeyBindings[i][j] ==  key_code) {
					mouseKeyBindings[i][j] = -1;
				}
			}
		}
		mouseKeyBindings[cID][type] = key_code;  // set the number in the bindings array
		[mouseKeyTable selectRowIndexes:nil byExtendingSelection:NO];
		[prefHelpTextMouse setStringValue:prefHelpString];
		[prefHelpTextMouse setTextColor:[NSColor controlTextColor]];
		[mouseKeyTable reloadData]; // set the button string in the view
		[self saveMouseBindings];
		_isSettingMousePreferences = NO;
	}
}

- (BOOL)getMouseBinding:(WiiButtonType)type keyCode:(CGKeyCode*)key controllerID:(int)cID
{
	if (mouseKeyBindings[cID][type] != -1) {
		*key = mouseKeyBindings[cID][type];
		return TRUE;
	}
	
	return FALSE;
}

- (BOOL)getKeyBinding:(WiiButtonType)type keyCode:(CGKeyCode*)key controllerID:(int)cID;
{
	if (keyBindings[cID][type] != -1) {
		*key = keyBindings[cID][type];
		return TRUE;
	}
	
	return FALSE;
}

- (BOOL)isMotionRequired:(int)cID
{
	static int set;
	set = [HIDsettingsSet selectedTag];
	if (set != 0)
		set = cID+1;

	if ([self isHIDEnabled] && (HIDsettings[set].xyzSource == 3 || HIDsettings[set].rxyzSource == 3))
		return YES;
	else if ([self isMouseEnabled] && [mouseControllerButton selectedTag] == cID && 
	         ([mouseDataSourceButton selectedTag] == 5 || [mouseDataSourceButton selectedTag] == 6 || [mouseDataSourceButton selectedTag] == 7))	
		return YES;
	else
		return NO;
}

- (BOOL)isIRrequired:(int)cID
{
	static int set;
	set = [HIDsettingsSet selectedTag];
	if (set != 0)
		set = cID+1;

	if ([self isMouseEnabled] && [mouseDataSourceButton selectedTag] == 0 && [mouseControllerButton selectedTag] == cID)
		return YES;
	else if ([self isHIDEnabled] && (HIDsettings[set].xyzSource == 1 || HIDsettings[set].rxyzSource == 1))
		return YES;
	else
		return NO;
}

- (BOOL)isOverlapRequired:(int)cID
{
	static int set;
	set = [HIDsettingsSet selectedTag];
	if (set != 0)
		set = cID+1;

	return HIDsettings[set].overlap;
}

- (int)getMouseAssignment:(int)type controllerID:(int)cID
{	
	static int dataSourceTag;
	
	if (![self isMouseEnabled])
		return -1;

	if ([mouseControllerButton selectedTag] != cID)
		return -1;
	
	dataSourceTag = [mouseDataSourceButton selectedTag];
	
	switch (type) {
		case WiiIRSensor:
			if (dataSourceTag == 0)
				return 0;
			break;
		case WiiRemoteUpButton:
		case WiiRemoteDownButton:
		case WiiRemoteLeftButton:
		case WiiRemoteRightButton:
			if (dataSourceTag == 1)
				return 1;
			break;
		case WiiClassicControllerUpButton:
		case WiiClassicControllerDownButton:
		case WiiClassicControllerLeftButton:
		case WiiClassicControllerRightButton:
			if (dataSourceTag == 2)
				return 2;
			break;
		case WiiNunchukJoyStick:
		case WiiClassicControllerLeftJoyStick:
			if (dataSourceTag == 3)
				return 3;
			break;
		case WiiClassicControllerRightJoyStick:
			if (dataSourceTag == 4)
				return 4;
			break;
		case WiiRemoteAccelerationSensor:
			if (dataSourceTag >= 10 && dataSourceTag <= 15)
				return dataSourceTag;
			break;
		case WiiNunchukAccelerationSensor:
			if (dataSourceTag >= 20 && dataSourceTag <= 25)
				return dataSourceTag - 10;
			break;
		case WiiBalanceBoardPressureSensor:
			if (dataSourceTag == 30)
				return 30;
			break;
		default:
			return -1;
	}
	
	return -1;
}

- (int)getJoystickAssignment:(int)type controllerID:(int)cID
{
	static int set, xyzSource, rxyzSource;
	set = [HIDsettingsSet selectedTag];
	xyzSource = HIDsettings[set].xyzSource;
	rxyzSource = HIDsettings[set].rxyzSource;
	if (set != 0)
		set = cID+1;
	static int ret;
	ret = -1;

	switch (type) {
		case WiiNunchukJoyStick:
		case WiiClassicControllerLeftJoyStick:
			if (xyzSource == 10) 
				ret = hid_XYZ;
			else if (rxyzSource == 10) 
				ret = hid_rXYZ;
			break;
		case WiiClassicControllerRightJoyStick:
			if (xyzSource == 11) 
				ret = hid_XYZ;
			else if (rxyzSource == 11) 
				ret = hid_rXYZ;
			break;
		case WiiRemoteUpButton:
		case WiiRemoteDownButton:
		case WiiRemoteLeftButton:
		case WiiRemoteRightButton:
			if (xyzSource == 8) 
				ret = hid_XYZ;
			else if (rxyzSource == 8) 
				ret = hid_rXYZ;
			break;
		case WiiClassicControllerLeftButton:
		case WiiClassicControllerRightButton:
		case WiiClassicControllerDownButton:
		case WiiClassicControllerUpButton:
			if (xyzSource == 9) 
				ret = hid_XYZ;
			else if (rxyzSource == 9) 
				ret = hid_rXYZ;
			break;
		case WiiRemoteAccelerationSensor:
			if (xyzSource == 2) 
				ret = hid_XYZ;
			else if (rxyzSource == 2) 
				ret = hid_rXYZ;				
			break;
		case WiiNunchukAccelerationSensor:
			if (xyzSource == 5) 
				ret = hid_XYZ;
			else if (rxyzSource == 5) 
				ret = hid_rXYZ;			
			break;
		case WiiRemoteAccelerationSensorROT:
			if (xyzSource == 4) 
				ret = hid_XYZ;
			else if (rxyzSource == 4) 
				ret = hid_rXYZ;				
			break;
		case WiiNunchukAccelerationSensorROT:
			if (xyzSource == 7) 
				ret = hid_XYZ;
			else if (rxyzSource == 7) 
				ret = hid_rXYZ;			
			break;
	}
	
	return ret;
}

// orient must be size 4!
- (void)getJoystickOrientation:(int*)orient controllerID:(int)cID
{
	static int set;
	set = [HIDsettingsSet selectedTag];
	if (set != 0)
		set = cID+1;
	
	orient[0] = HIDsettings[set].orientation;
	orient[1] = HIDsettings[set].invertX;
	orient[2] = HIDsettings[set].invertY;
	orient[3] = HIDsettings[set].invertZ;
}

- (int) getMouseSensitivity
{
	return [mouseSensitivity intValue];
}

- (int)getMouseMovementStyle
{
	return [[mouseMovementStyle selectedCell] tag];
}

// orient must be size 3
- (void) getMouseOrientation:(int*)orient
{
	orient[0] = [mouseInvertX state];
	orient[1] = [mouseInvertY state];
	orient[2] = [mouseSwapXY state];
}

@end


/*

Event Types
Constants that specify the different types of input events.

enum _CGEventType {
   kCGEventNull                = NX_NULLEVENT,
   kCGEventLeftMouseDown       = NX_LMOUSEDOWN,
   kCGEventLeftMouseUp         = NX_LMOUSEUP,
   kCGEventRightMouseDown      = NX_RMOUSEDOWN,
   kCGEventRightMouseUp        = NX_RMOUSEUP,
   kCGEventMouseMoved          = NX_MOUSEMOVED,
   kCGEventLeftMouseDragged    = NX_LMOUSEDRAGGED,
   kCGEventRightMouseDragged   = NX_RMOUSEDRAGGED,
   kCGEventKeyDown             = NX_KEYDOWN,
   kCGEventKeyUp               = NX_KEYUP,
   kCGEventFlagsChanged        = NX_FLAGSCHANGED,
   kCGEventScrollWheel         = NX_SCROLLWHEELMOVED,
   kCGEventTabletPointer       = NX_TABLETPOINTER,
   kCGEventTabletProximity     = NX_TABLETPROXIMITY,
   kCGEventOtherMouseDown      = NX_OMOUSEDOWN,
   kCGEventOtherMouseUp        = NX_OMOUSEUP,
   kCGEventOtherMouseDragged   = NX_OMOUSEDRAGGED,
   kCGEventTapDisabledByTimeout = 0xFFFFFFFE,
   kCGEventTapDisabledByUserInput = 0xFFFFFFFF
};
typedef uint32_t CGEventType;

*/
