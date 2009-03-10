//
//  WiiMoteController.h
//  wiipad
//
//  Created by Taylor Veltrop on 3/26/08.
//  Copyright 2008,2009 Taylor Veltrop. All rights reserved.
//  Read COPYRIGHT.txt for legal info.
//  See comments in WiiMoteController.m for a synopsis.
//  See ChangeLog.txt as well.

#import <Cocoa/Cocoa.h>
#import <WiiRemote/WiiRemoteDiscovery.h>

#define kMyDriversIOKitClassName 	"com_veltrop_taylor_driver_virtualhid"
#define maxNumWiimotes					4

@class PrefController;
@class AppController;

@interface WiiMoteController : NSObject {
	WiiRemoteDiscovery *_wii_discovery;
	WiiRemote* _wiimote[maxNumWiimotes];
	//io_connect_t	_connect;
	io_service_t	_service[maxNumWiimotes];

	IBOutlet PrefController* prefs;
	IBOutlet AppController* app;

	BOOL _isVirtualHIDOpen;
	BOOL _draggingMouse;
}
- (id) init;
- (void) dealloc;
- (void) awakeFromNib;

#pragma mark -
#pragma mark OSX Application Delegation Stuff
- (void)applicationWillTerminate:(NSNotification *)aNotification;

#pragma mark -
#pragma mark GUI Delegates, DataSources, CallBacks, etc.
- (IBAction)tryAgain:(id)sender;
- (IBAction)disconnect:(id)sender;

#pragma mark -
#pragma mark WiiRemote delegates
- (void) buttonChanged:(WiiButtonType)type isPressed:(BOOL)isPressed controllerID:(int)cID;
- (void) joyStickChanged:(WiiJoyStickType) type tiltX:(unsigned short) tiltX tiltY:(unsigned short) tiltY controllerID:(int)cID;
//- (void) analogButtonChanged:(WiiButtonType) type amount:(unsigned short) press;
- (void) accelerationChanged:(WiiAccelerationSensorType)type accX:(unsigned short)accX accY:(unsigned short)accY accZ:(unsigned short)accZ controllerID:(int)cID;
- (void) irPointMovedX:(float)px Y:(float)py controllerID:(int)cID;
//- (void) rawIRData: (IRData[4])irData controllerID:(int)cID;
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
#pragma mark Virtual HID kernel and system Interface Stuff
- (BOOL) syncVirtualDrivers;
- (void) closeVirtualDriver;
- (void) doJoystick:(UInt8*)properties controllerID:(int)cID; 
//- (void) setVirtualDriverProperties:(void*)properties length:(int)length;
void setVirtualDriverPropertiesFast(io_service_t service, void* properties, int size); 
- (void) centerJoysticks;
- (void) mouseIncrementX:(float)x Y:(float)y;
- (void) mouseSetX:(float)x Y:(float)y;
- (void) doMouseX:(float)x Y:(float)y;

#pragma mark -
#pragma mark Utility functions for other controllers
- (void) syncEnableMotion;
- (void) syncEnableIR;


@end
