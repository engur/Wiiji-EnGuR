//
//  wiimote_manager.h
//  wiipad
//
//  Created by Taylor Veltrop on 3/26/08.
//  Copyright 2008 Taylor Veltrop. All rights reserved.
//  Read COPYRIGHT.txt for legal info.
//  See comments in wiimote_manager.m for a synopsis.

#import <Cocoa/Cocoa.h>
#import "WiiRemoteFramework/WiiRemoteDiscovery.h"

#define kMyDriversIOKitClassName 	"com_veltrop_taylor_driver_virtualhid"
#define maxNumWiimotes					4

@interface wiimote_manager : NSObject {
	WiiRemoteDiscovery *_wii_discovery;
	WiiRemote* _wiimote[maxNumWiimotes];
	//io_connect_t	_connect;
	io_service_t	_service[maxNumWiimotes];
	
	NSStatusItem *wii_menu;
	NSTimer*	animationTimer;
	
	IBOutlet NSMenu* mainMenu;
	IBOutlet NSMenuItem* scanMenuTextItem;
	IBOutlet NSWindow* prefWindow;
	IBOutlet NSWindow* aboutWindow;
	IBOutlet NSWindow* helpWindow;
	IBOutlet NSTableView* keyTable;
	IBOutlet NSButton* HIDEnabledButton;
	IBOutlet NSButton* KBEnabledButton;
	IBOutlet NSTextField* prefHelpText;
	
	NSImage* icons[4];
	
	BOOL _isSettingPreferences; // cpu saving bool so we dont have to do extra objective-c messaging when we recieve wiimote events
	BOOL _isUsingKBEmu;			 //  ^-- it turns out that we probably didn't need to go to this length...
	BOOL _isVirtualHIDOpen;
}
- (id) init;
- (void) dealloc;
- (void) awakeFromNib;
- (void) saveKeyBindings;
- (void) loadKeyBindings;

// Note: yes I know I am listing more functions here than neccessary, but it's helpful for my brain!

#pragma mark -
#pragma mark OSX Application Delegation Stuff
- (void)applicationWillTerminate:(NSNotification *)aNotification;

#pragma mark -
#pragma mark GUI Delegates, DataSources, CallBacks, etc.
- (void)tick;
- (IBAction)stopScanDoConnect:(id)sender;
- (IBAction)tryAgain:(id)sender;
- (IBAction)disconnect:(id)sender;
- (IBAction)setIsUsingKBEmu:(id)sender;
- (IBAction)setIsUsingVirtualHID:(id)sender;
- (void)setTable:(NSTableView*)tableView isEnabled:(BOOL)enabled;
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(int)rowIndex;
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification;
- (IBAction)openWindow:(id)sender;
- (IBAction)donate:(id)sender;

#pragma mark -
#pragma mark WiiRemote delegates
- (void) buttonChanged:(WiiButtonType)type isPressed:(BOOL)isPressed controllerID:(int)cID;
- (void) joyStickChanged:(WiiJoyStickType) type tiltX:(unsigned short) tiltX tiltY:(unsigned short) tiltY controllerID:(int)cID;
- (void) accelerationChanged:(WiiAccelerationSensorType) type accX:(unsigned short) accX accY:(unsigned short) accY accZ:(unsigned short) accZ controllerID:(int)cID;
//- (void) analogButtonChanged:(WiiButtonType) type amount:(unsigned short) press;
- (void) wiiRemoteDisconnected:(IOBluetoothDevice*) device remote:(WiiRemote*)remote controllerID:(int)cID;
- (void) expansionPortChanged:(NSNotification *)nc;
- (void) pressureChanged:(WiiPressureSensorType) type pressureTR:(unsigned short) bPressureTR pressureBR:(unsigned short) bPressureBR 
			  pressureTL:(unsigned short) bPressureTL pressureBL:(unsigned short) bPressureBL controllerID:(int)cID;

#pragma mark -
#pragma mark WiiRemoteDiscovery delegates
- (void) willStartWiimoteConnections;
- (void) willStartDiscovery;
- (void) willStopDiscovery;
- (void) WiiRemoteDiscoveryError:(int)code;
- (void) WiiRemoteDiscovered:(WiiRemote*)wiimote;

#pragma mark -
#pragma mark Virtual HID kernel Interface Stuff
- (BOOL) syncVirtualDrivers;
- (void) closeVirtualDriver;
//- (void) setVirtualDriverProperties:(void*)properties length:(int)length;
void setVirtualDriverPropertiesFast(io_service_t service, void* properties, int size); 

@end
