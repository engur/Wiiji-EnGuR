//
//  WiiMoteController.m
//  wiipad
//
//  Created by Taylor Veltrop on 3/26/08.
//  Copyright 2008,2009 Taylor Veltrop. All rights reserved.
//  Read COPYRIGHT.txt for legal info.
//  See ChangeLog.txt as well.
//

/**  Design synopsis  **
 *
 * This program accompanies the virtual HID driver.
 * The virtual HID driver automatically instantiates for each wii remote it sees connecting to the system.
 * But the kernel-land drivers aren't allowed to access the bluetooth devices how we want to.
 * But we need a kernel-land counterpart to provide nice systemwide HID support.
 * This program connects to the wii remotes, and maintains a list, and connects to their respective kernel virtual driver counterparts.
 * It then gets data from the wii remotes and sends it to its driver as 2 or 3 or 4 numbers: the button/joystick #, and its value(s).
 *
 */

/* Project todo list:

 TODO: BUGS
 1 when we connect to our virtualhid kext: make sure that it exists and is the right version; recomend to reinstall if not the right version
 2 while menu open: the menu-bar item doesn't animate and menu doesnt redraw contents
 3 Bluetooth mouse gets choppy sometimes after connect (framework)
 4 Real help guide
 5 wiimotes dont always connect, especialy PPC (framework or kernel)
 6 Enabling the IR in the framework also enables the motion
 7 The framework enables and disables everything with that stupid new init bug. TO FIX: have it just save those state variables before shitting on them...

 TODO: FEATURES
 1 analog joysticks to support keyboard controls
 3 CC analog button -> rudder/throttle support
 4 creation of virtual keyboards and mouses?(VirtualHID)
 5 User calibration?, save calibration data between uses... possible?
 6 DPad in hid spec (VirtualHID)
 7 auto Calibration of max min and center (framework <- the base to do so is there, but unused/untested)
 8 Application modes, such as paintbrush, presentation, desktop, web, etc.?(Wiiji) creation of wacom tablet?(VirtualHID)
 9 Japanese localization
 10 No limit to the # of wiimotes connected, and dynamicly built menu list of wiimotes
 11 Advanced user feature to set length of bt search query, also quering options such as continuous vs one-shot syncing.
*/

#include <WiiRemote/wiimote_types.h>
#import "AppController.h"
#import "PrefController.h"
#import "WiijiUpdater.h"
#import "WiiMoteController.h"

#define desiredVirtualHIDVersion	@"1.2"

@implementation WiiMoteController
- (id)init
{
	_isVirtualHIDOpen = NO;
	_draggingMouse = FALSE;
	
	if (!(_wii_discovery = [[WiiRemoteDiscovery alloc] init])) {
		NSRunCriticalAlertPanel(@"Can't Initialize", 
					@"Wiiji cant initialize discovery.\nPerhaps you don't have bluetooth hardware.",
					@"OK", nil, nil);
		//[NSApp terminate];
		//return nil;
		//_wii_discovery = nil;
	}
	else {
		[_wii_discovery setDelegate:self];
		[_wii_discovery retain];
	}
	
	int i;
	for (i = 0; i < maxNumWiimotes; i++)  {
		_service[i] = IO_OBJECT_NULL;
		_wiimote[i] = nil;
	}
		
	return self;
}

- (void) cleanUp
{
	[self closeVirtualDriver];

	int i;
	for (i=0; i < maxNumWiimotes; i++) {
		if (_wiimote[i] != nil) {
			[_wiimote[i] closeConnection]; 
			[_wiimote[i] release];
		}
	}

	if (_wii_discovery != nil) {
		if ([_wii_discovery isDiscovering]) {
	//		[_wii_discovery stop];
			[_wii_discovery close];
		}
		[_wii_discovery release];
	}
	
	// delete images
	
	// delete menu item
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) dealloc
{
	[self cleanUp];
	[super dealloc];
}

-(void)awakeFromNib
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(expansionPortChanged:) name:@"WiiRemoteExpansionPortChangedNotification" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:NSApplicationWillTerminateNotification object:nil];
	
	if (_wii_discovery != nil)
		[_wii_discovery start];
}

#pragma mark -
#pragma mark OSX Application Delegation Stuff
- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	//NSLog(@"applicationWillTerminate");
	[self cleanUp];
}

#pragma mark -
#pragma mark GUI Delegates, DataSources, CallBacks, etc.
- (IBAction)tryAgain:(id)sender
{
	if (_wii_discovery != nil) {
		if ([_wii_discovery isDiscovering])
			[_wii_discovery close];
		else
			[_wii_discovery start];
	}
}

- (IBAction)disconnect:(id)sender
{
	int the_id = [sender tag] - 500;
	if (the_id >= 0 && the_id < maxNumWiimotes) {
		if (_wiimote[the_id]) {
			[_wiimote[the_id] closeConnection];
			_wiimote[the_id] = nil;
		}
	}
}

#pragma mark -
#pragma mark WiiRemote delegates
// these callbacks need to work very fast, their (impossible) goals are to not allocate memory when called, nor send objective-c messages 
//  (except in preference setting mode where performance doesnt matter)

- (void) buttonChanged:(WiiButtonType)type isPressed:(BOOL)isPressed controllerID:(int)cID
{	
	static UInt8 properties[4] = {0, 0, 0, 0};
	static CGKeyCode hid_key;
	static CGEventRef event = NULL;
	static int assignment;
	static WiiButtonType typeTmp;
	static float x,y;
	
	//NSLog(@"but: %d cont: %d",type,cID);
	
	if (cID < 0 || cID >= maxNumWiimotes)
		return;

	if ([prefs isSettingKeyPreferences]) {
		[prefs setKey:type controllerID:cID];
	} else if ([prefs isSettingMousePreferences]) {
		[prefs setMouse:type controllerID:cID];
	} else {
		if ([prefs isKBEnabled]) {
			// TODO: the KBEmu doesn't seem to repeat typed keys..., but it is in fact holding them down, it must have to do with the text input engine of os-x somehow
			if ([prefs getKeyBinding:type keyCode:&hid_key controllerID:cID]) {
				CFRelease(CGEventCreate(NULL)); // Tiger's bug. see: http://www.cocoabuilder.com/archive/message/cocoa/2006/10/4/172206
				event = CGEventCreateKeyboardEvent(NULL, hid_key, isPressed);
				//CGEventSetType(event, kCGKeyboardEventKeycode);
				CGEventPost(kCGHIDEventTap, event);
				CFRelease(event);
				//usleep(10000);
			}
		}
		if ([prefs isMouseEnabled]) {
			if ([prefs getMouseBinding:type keyCode:&hid_key controllerID:cID]) {
				int dispHeight = CGDisplayPixelsHigh(kCGDirectMainDisplay);
				CGPoint point;
				NSPoint clickPoint = [NSEvent mouseLocation];
				point.x = clickPoint.x;
				point.y = dispHeight - clickPoint.y;
			
				CFRelease(CGEventCreate(NULL)); // this is Tiger's bug.
				switch (hid_key) {
					case 3:
					case 4:
						if (!isPressed) {
							event = CGEventCreate(NULL);
							break;
						}
						event = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseDown, point, kCGMouseButtonLeft);
						CGEventSetIntegerValueField(event, kCGMouseEventClickState, hid_key - 1);
						CGEventSetType(event, kCGEventLeftMouseDown);
						CGEventPost(kCGHIDEventTap, event);
						CGEventSetType(event, kCGEventLeftMouseUp);
						//CGEventPost(kCGHIDEventTap, event);
						//CGEventSetType(event, kCGEventLeftMouseDown);
						//CGEventPost(kCGHIDEventTap, event);
						//CGEventSetType(event, kCGEventLeftMouseUp);
						//CGEventPost(kCGHIDEventTap, event);
						break;
					case kCGMouseButtonLeft:
						//kCGEventLeftMouseDragged
						_draggingMouse = isPressed;
						event = CGEventCreateMouseEvent(NULL, (isPressed) ? kCGEventLeftMouseDown : kCGEventLeftMouseUp, point, kCGMouseButtonLeft);	
						CGEventSetType(event, (isPressed) ? kCGEventLeftMouseDown : kCGEventLeftMouseUp); // tiger bug
						break;
					case kCGMouseButtonRight:
						event = CGEventCreateMouseEvent(NULL, (isPressed) ? kCGEventRightMouseDown : kCGEventRightMouseUp, point, kCGMouseButtonRight);
						CGEventSetType(event, (isPressed) ? kCGEventRightMouseDown : kCGEventRightMouseUp); // tiger bug
						break;
					case kCGMouseButtonCenter:
						event = CGEventCreateMouseEvent(NULL, (isPressed) ? kCGEventOtherMouseDown : kCGEventOtherMouseUp, point, kCGMouseButtonCenter);
						CGEventSetType(event, (isPressed) ? kCGEventOtherMouseDown : kCGEventOtherMouseUp); // tiger bug
						break;
					default:
						event = CGEventCreate(NULL);
						break;
				}
				CGEventPost(kCGHIDEventTap, event);
				CFRelease(event);
			}
			
			if ([prefs getMouseAssignment:type controllerID:cID] != -1) {
				typeTmp = type;
				x = 0;
				y = 0;
				if (typeTmp >= WiiClassicControllerYButton)
					typeTmp -= WiiClassicControllerYButton;
				//if (type == WiiRemoteRightButton || type == WiiRemoteLeftButton)
					x = isPressed * ((type == WiiRemoteRightButton) - (type == WiiRemoteLeftButton));		
				//if (type == WiiRemoteUpButton || type == WiiRemoteDownButton)
					y = isPressed * ((type == WiiRemoteDownButton) - (type == WiiRemoteUpButton));
				[self doMouseX:x Y:y];
			}
		}
		if (_isVirtualHIDOpen) {
			if ([prefs isOverlapRequired:cID] && type >= WiiClassicControllerYButton) // lets overlap the classic conroller with the wiimote/nunchuck buttons
				type -= WiiClassicControllerYButton;
			assignment = [prefs getJoystickAssignment:type controllerID:cID];
			if (assignment != -1) {
				properties[0] = assignment;
				properties[1] = properties[2] = properties[3] = 0;
				if (type >= WiiClassicControllerYButton) // safe becuase the above assignment check had original value, subtraction done here to simplify following if
						type -= WiiClassicControllerYButton;
				//if (type == WiiRemoteRightButton || type == WiiRemoteLeftButton)
					properties[1] = isPressed * ((type == WiiRemoteRightButton)*(127) - (type == WiiRemoteLeftButton)*(127));		
				//if (type == WiiRemoteUpButton || type == WiiRemoteDownButton)
					properties[2] = isPressed * ((type == WiiRemoteDownButton)*(127) - (type == WiiRemoteUpButton)*(127));
				[self doJoystick:properties controllerID:cID];
			} else if ([_wiimote[cID] expansionPortType] == WiiBalanceBoard) {				// force balance board button to button one
						type = WiiRemoteOneButton;
				properties[0] = type;
				properties[1] = isPressed;
				properties[2] = properties[3] = 0;
				setVirtualDriverPropertiesFast(_service[cID], properties, 4);
			}
		}
	}
}


// type: WiiNunchukJoyStick 0, WiiClassicControllerLeftJoyStick 1, WiiClassicControllerRightJoyStick 2
- (void) joyStickChanged:(WiiJoyStickType) type tiltX:(unsigned short) tiltX tiltY:(unsigned short) tiltY controllerID:(int)cID
{
	//NSLog(@"%d,%d", tiltX, tiltY, nil);	
	
	static UInt8 properties[4] = {0, 0, 0, 0};
	static UInt8 factor;
	static int assignment;
	static float x,y;
	
	if (cID < 0 || cID >= maxNumWiimotes)
		return;
	
	if (type == WiiNunchukJoyStick)
		factor = 128;
	else if (type == WiiClassicControllerLeftJoyStick)
		factor = 32;
	else // WiiClassicControllerRightJoyStick
		factor = 16;
		
	// TODO: calibration and centering (but we should put it into the framework...)
		
	assignment = [prefs getJoystickAssignment:type controllerID:cID]; //hid_XYZ + (type == WiiClassicControllerRightJoyStick);
	if (assignment != -1) {
		properties[0] = assignment;
		properties[1] = /*0x00 |*/ (tiltX - factor)*128/factor;
		properties[2] = /*0x00 | */ ((factor*2+1 - tiltY) - factor)*128/factor;
		properties[3] = 0;
		//setVirtualDriverPropertiesFast(_service[cID], properties, 4);
		[self doJoystick:properties controllerID:cID];
	}
	
	if ([prefs getMouseAssignment:type controllerID:cID] != -1) {
		x = ((float)tiltX - (float)factor)/(float)factor;
		y = ((float)tiltY - (float)factor)/(float)factor;
		[self doMouseX:x Y:y];
	}
}

// This could go into a rudder/throttle category of joystick hid
/*- (void) analogButtonChanged:(WiiButtonType) type amount:(unsigned short) press;
{
	if (cID < 0 || cID >= maxNumWiimotes)
		return;
}*/

// WiiRemoteAccelerationSensor	
//	WiiNunchukAccelerationSensor
- (void) accelerationChanged:(WiiAccelerationSensorType)type accX:(unsigned short)accX accY:(unsigned short)accY accZ:(unsigned short)accZ controllerID:(int)cID
{
	if (cID < 0 || cID >= maxNumWiimotes)
		return;	
		
	static double *xprev, *yprev, *zprev;
	static double ax, ay, az;
	static UInt8 diffx, diffy, diffz, roll, pitch, yaw;
	static float mouseX, mouseY;
	static double xprev_[maxNumWiimotes] = {0, 0, 0, 0};
	static double yprev_[maxNumWiimotes] = {0, 0, 0, 0};
	static double zprev_[maxNumWiimotes] = {0, 0, 0, 0};
	static int mouseAssignment, accelHIDassignment, rotHIDassignment;
	static UInt8 properties[4] = {0, 0, 0, 0};
	static WiiAccCalibData c;
	
	//
	// SMOOTHING: round off fractions, so high precision at first steps, then round at  end (low precision at first steps will rpopagate error)
	//  then, take the distance traveled in xyz plane from last position
	//  // what to do with that?  perhaps see if 
	//
	//  or, take vector between now and last position.
	//   if this vector, and the vector of the last position are in a similar direction, allow
	//   but if we are in different directions, modify the point that we will report
	//   modyfy it by the scale of the difference in directions 
	//   * make sure that the vector is not unit length, so that we can maintain the length from prev idea.  this length factor is key in scaling becuase a greater angle difference, as well as a further distance needs to be factored into the scale
	//
	//  when we consider "last position" shhould we use the last real point or the last reported point?
	//  
	// add smoothing options to preferences, new pref sub window or a checkbox that disables/enables on both mouse and joystick page, maybe a smoothness slider
	//

	mouseAssignment = [prefs getMouseAssignment:type controllerID:cID];
	accelHIDassignment = [prefs getJoystickAssignment:type controllerID:cID];
	rotHIDassignment = [prefs getJoystickAssignment:type+1 controllerID:cID];

	if (mouseAssignment == -1 && accelHIDassignment == -1 && rotHIDassignment == -1)
		return;

	c = [_wiimote[cID] accCalibData:type];	// this data constantly changes as the wii remote is used

	ax = (double)(accX - c.accX_zero) / (double)(c.accX_1g - c.accX_zero);
	ay = (double)(accY - c.accY_zero) / (double)(c.accY_1g - c.accY_zero);
	az = (double)(accZ - c.accZ_zero) / (double)(c.accZ_1g - c.accZ_zero) - 1.0;

	xprev = &xprev_[cID];
	yprev = &yprev_[cID];
	zprev = &zprev_[cID];		
	diffx = (ax - *xprev)*255.0;
	diffy = (ay - *yprev)*255.0;
	diffz = (az - *zprev)*255.0;	
	*xprev = ax;
	*yprev = ay;
	*zprev = az;
		
	roll  = atan(ax) / 3.14159 * 2.0 * 255.0; // atan(ax) * 180.0 / 3.14 * 2.0;
	pitch = atan(ay) / 3.14159 * 2.0 * 255.0;
	yaw   = atan(az) / 3.14159 * 2.0 * 255.0;
	
	if (accelHIDassignment != -1) {
		properties[0] = accelHIDassignment;
		properties[1] = diffx;
		properties[2] = diffy;
		properties[3] = diffz;
		[self doJoystick:properties controllerID:cID];
	}	
	
	if (rotHIDassignment != -1) {			
		properties[0] = rotHIDassignment;
		properties[1] = roll;  // (roll/180)*255;
		properties[2] = pitch;
		properties[3] = yaw;
		[self doJoystick:properties controllerID:cID];
	}
	
	if (mouseAssignment != -1) {
		switch (mouseAssignment) {
			case 10:
				mouseX = diffx;
				mouseY = diffy;
				break;
			case 11:
				mouseX = diffx;
				mouseY = diffz;
				break;
			case 12:
				mouseX = diffy;
				mouseY = diffz;
				break;
			case 13:
				mouseX = yaw;
				mouseY = roll;
				break;
			case 14:
				mouseX = yaw;
				mouseY = pitch;
				break;
			case 15:
				mouseX = roll;
				mouseY = pitch;
				break;
			default:
				mouseX = 0;
				mouseY = 0;
				break;
		}
		[self doMouseX:(float)mouseX/255.0 Y:(float)mouseY/255.0];
	}
	
	//NSLog(@"accel: %6.2f, %6.2f, %6.2f    %6.2f, %6.2f, %6.2f"  , ax, ay, az, roll, pitch, yaw, nil);
	
	//UInt8 properties[4] = {hid_rXYZ, (roll/180)*255, (pitch/180)*255, (yaw/180)*255};
	//UInt8 properties[4] = {hid_XYZ, ax*255, ay*255, az*255};
	//setVirtualDriverPropertiesFast(_service[cID], properties, 4);

	//UInt8 properties2[4] = {hid_XYZ, diffx, diffy, diffz};
	//setVirtualDriverPropertiesFast(_service[cID], properties2, 4);
	
	// my two favorite styles
	//[self mouseIncrementX:diffx Y:-diffy];
	//[self mouseSetX:roll/180 Y:-pitch/180];
}

- (void) pressureChanged:(WiiPressureSensorType) type pressureTR:(unsigned short) bPressureTR pressureBR:(unsigned short) bPressureBR 
			  pressureTL:(unsigned short) bPressureTL pressureBL:(unsigned short) bPressureBL controllerID:(int)cID
{
	static UInt8 properties[4] = {0, 0, 0, 0};
	static double totalWeight;
	static UInt8 x, y;
	static int mouseAssignment;
	
	totalWeight = bPressureTR + bPressureBR + bPressureTL + bPressureBL;
	if (totalWeight > 0) {
		x = ((double)((bPressureTR + bPressureBR) - (bPressureTL + bPressureBL)) / totalWeight) * 127.0;
		y = ((double)((bPressureTR + bPressureTL) - (bPressureBR + bPressureBL)) / totalWeight) * -127.0;
	} else {
		x = 0;
		y = 0;
	}
	
	properties[0] = hid_XYZ; // force the balance board to be XYZ
	properties[1] = x;
	properties[2] = y;
	properties[3] = 0;
	//setVirtualDriverPropertiesFast(_service[cID], properties, 4);
	[self doJoystick:properties controllerID:cID];
	
	mouseAssignment = [prefs getMouseAssignment:type controllerID:cID];
	if (mouseAssignment != -1) {
		[self doMouseX:(float)x/255.0 Y:(float)y/255.0];
	}
	
	// NSLog(@"%d %d",x,y);
}

- (void) irPointMovedX:(float)px Y:(float)py controllerID:(int)cID;
{
	static UInt8 properties[4] = {0, 0, 0, 0};
	static int joyAssignment;

	if (cID < 0 || cID >= maxNumWiimotes)
		return;	
		
	if (px == -100 && py == -100)
		return;
		
	if ([prefs getMouseAssignment:WiiIRSensor controllerID:cID] != -1)
		[self doMouseX:px Y:py];
		
	joyAssignment = [prefs getJoystickAssignment:WiiIRSensor controllerID:cID];
	if (joyAssignment != -1) {
		properties[0] = joyAssignment; // force the balance board to be XYZ
		properties[1] = px * 127.0;
		properties[2] = py * 127.0;
		properties[3] = 0;
		[self doJoystick:properties controllerID:cID];
	}
				
	//NSLog(@"ir: %f %f",px,py);
}

- (void) wiiRemoteDisconnected:(IOBluetoothDevice*)device remote:(WiiRemote*)remote controllerID:(int)cID
{
	if (cID < 0 || cID >= maxNumWiimotes)
		return;

	[_wiimote[cID] autorelease];		// should this full release? (but it called this function... and is busy)
	_wiimote[cID] = nil;	

	[app setMenuItem:cID enabled:NO];
		
	int i;
	for (i=0; i < maxNumWiimotes; i++) {
		if (_wiimote[i] != nil)
			break;
	}
	if (i == maxNumWiimotes)				// if no wiimots are connected
		[app setMenuConnectedIconState:NO];
		
	//	[self syncVirtualDrivers];
}	

- (void)expansionPortChanged:(NSNotification *)nc
{	
	WiiRemote* inWiimote = (WiiRemote*)[nc object];
	
	if (!inWiimote)
		return;
	
	if ([inWiimote isExpansionPortAttached]){
		[inWiimote setExpansionPortEnabled:YES];
		// add string of attached peripheral to menu?  (no reason to really)
	} else {
		[inWiimote setExpansionPortEnabled:NO];
		[self centerJoysticks];
	}	
}


#pragma mark -
#pragma mark WiiRemoteDiscovery delegates
- (void) willStartWiimoteConnections
{
	//	NSLog(@"willStartWiimoteConnections:");
}

- (void) willStartDiscovery
{
	[app setMenuAnimationEnabled:YES];
}

- (void) willStopDiscovery
{
	[app setMenuAnimationEnabled:NO];
	int i;
	for (i = 0; i < maxNumWiimotes; i++) {
		if (_wiimote[i] != nil) {
			[app setMenuConnectedIconState:YES];
			break;
		}
	}
	if (i == maxNumWiimotes) {
		[app setMenuConnectedIconState:NO];
	}
}

- (void) WiiRemoteDiscoveryError:(int)code
{
	if (code == 56) {
		[NSApp activateIgnoringOtherApps:YES];
		NSRunCriticalAlertPanel(@"No Bluetooth Available", 
                        @"Wiiji is Unable to open bluetooth.\nPlease enable bluetooth.",
                        @"OK", nil, nil);
	}
	else if (code != 4) /*if (code == 536870195 || code == -536870195 )*/ {		// 4 is a timeout error
		NSLog(@"WiiRemoteDiscoveryError: %i", code, nil);
		if (_wii_discovery != nil) {
			//[_wii_discovery stop];
			//[_wii_discovery close];
			[_wii_discovery start];
			NSLog(@"Restarting discovery after error.");
			//[_wii_discovery resume];
		}
	}

}

- (void) WiiRemoteDiscovered:(WiiRemote*)wiimote
{
	//	NSLog(@"WiiRemoteDiscovered:");
	int the_id;
	int i;
	for (i = 0; i < maxNumWiimotes; i++) {
		if (_wiimote[i] == nil) {
			the_id = i;
			break;
		}
	}
	if (i == maxNumWiimotes) {
		[wiimote closeConnection];
		[wiimote autorelease];
		return;
	}

	[wiimote setControllerID:the_id]; 
	[wiimote retain];
	[wiimote setDelegate:self];
	
	[app setMenuItem:i enabled:YES];
	
	_wiimote[the_id] = wiimote;

	if ([prefs isHIDEnabled])
		[self syncVirtualDrivers];
	
	if ([_wiimote[the_id]  expansionPortType] == WiiBalanceBoard)	
		[_wiimote[the_id]  setLEDEnabled1:YES enabled2:NO enabled3:NO enabled4:NO];
	else
		[_wiimote[the_id]  setLEDEnabled:the_id];
	
	[_wii_discovery start];
	
	
	
	[self syncEnableMotion];
	[self syncEnableIR];			// this doesnt seem to work...
}


#pragma mark -
#pragma mark Virtual HID kernel and system Interface Stuff
- (BOOL) syncVirtualDrivers
{
	kern_return_t	kernResult; 
	BOOL ret_val = YES;
	
	int i;
	for (i = 0; i < maxNumWiimotes; i++) {
		if (_wiimote[i] != nil) {
			break;
		}
	}
	if (i == maxNumWiimotes)
		return YES;				// there were no wiimotes to connect to.
	
	if (_isVirtualHIDOpen)
		[self closeVirtualDriver];
	
	io_iterator_t 	iterator;
	CFDictionaryRef	classToMatch;
	
	classToMatch = IOServiceMatching(kMyDriversIOKitClassName);
	if (classToMatch == NULL) {
		NSLog(@"IOServiceMatching returned a NULL dictionary.");
		ret_val = NO;
		goto fail0;
	}
	
	kernResult = IOServiceGetMatchingServices(kIOMasterPortDefault, classToMatch, &iterator);
	if (kernResult != KERN_SUCCESS) {
		NSLog(@"IOServiceGetMatchingServices returned 0x%08x", kernResult, nil);
		ret_val = NO;
		goto fail0;
	}

	//while ((_service[i++] = IOIteratorNext(iterator)) && i < maxNumWiimotes);	//this gets driver # out of sync with _wiimote ID #, but it looked nice, now we need a complex for loop
	for (i = 0; i < maxNumWiimotes; i++) {
		if (_wiimote[i]) {
			//[_wiimote[i] setLEDEnabled:i];
			if (!(_service[i] = IOIteratorNext(iterator))) {
				ret_val = NO;
				NSLog(@"Couldn't connect to kernel driver #%d.", i);
			}
		}
	}
	IOObjectRelease(iterator);

	// we aren't in need of a full user client, maybe someday we will be
	//kernResult = UserClientOpen(service, &connect);
	//IOObjectRelease(service);
		
fail0:
	if (ret_val == NO) {
		[NSApp activateIgnoringOtherApps:YES];
		NSRunCriticalAlertPanel(@"No Virtual HID Driver Available", 
                        @"Wiiji is Unable to open the Virtual HID Driver.\nHID joypad emulation unavailable.",
                        @"OK", nil, nil);
	}
	//NSLog(@"Wiiji found %d virtual hid drivers to load.", i-1, nil);
	
	_isVirtualHIDOpen = ret_val;
	return ret_val;
}

- (void) closeVirtualDriver
{
	int i;
	for (i= 0; i < maxNumWiimotes; i++) {
		if (_service[i]) {
			IOObjectRelease(_service[i]);
			_service[i] = IO_OBJECT_NULL;
		}
	}
	//IOObjectRelease(_connect);
	_isVirtualHIDOpen = NO;
}

- (void) doJoystick:(UInt8*)properties controllerID:(int)cID
{
	static int orientation[4] = {0, 0, 0, 0};
	[prefs getJoystickOrientation:orientation controllerID:cID];
	
	static UInt8 tmp;
	switch (orientation[0]) {
		case 0:
			break;
		case 1:
			tmp = properties[1];
			properties[1] = properties[2];
			properties[2] = tmp;
			break;
		case 2:
			tmp = properties[2];
			properties[2] = properties[3];
			properties[3] = tmp;
			break;
		case 3:
			tmp = properties[1];
			properties[1] = properties[2];
			properties[2] = properties[3];
			properties[3] = tmp;
			break;
		case 4:
			tmp = properties[1];
			properties[1] = properties[3];
			properties[3] = tmp;
			break;	
		case 5:
			tmp = properties[1];
			properties[1] = properties[3];
			properties[3] = properties[2];
			properties[2] = tmp;
			break;
	}
	
	static int i;
	for (i=1; i < 4; i++) {
		if (orientation[i])
			properties[i] = 255 - properties[i] + 1;
	}
	
	setVirtualDriverPropertiesFast(_service[cID], properties, 4);
}

// this is perhaps slow becuase it copies data, and also is an objective-c message, see below for faster version
/*- (void) setVirtualDriverProperties:(void*)properties length:(int)length
{
//	if (_isVirtualHIDOpen) {
		IOReturn ret;

		NSData *request = [NSData dataWithBytes:properties length:length];
		if (request == nil) {
			NSLog(@"Failed to allocate memory for virtual driver communication");
			return;
		}
		
		ret = IORegistryEntrySetCFProperties (_service, (CFDataRef*)request);
		if (ret != kIOReturnSuccess)
			NSLog(@"Failed setting driver properties: 0x%x", ret);
			
	//	if (request != nil)
			[request autorelease]; 
//	}
}*/

void setVirtualDriverPropertiesFast(io_service_t service, void* properties, int size)
{
	//NSData *request = [NSData dataWithBytes/*NoCopy*/:properties length:size];
	if (!service)
		return;
		
	static IOReturn ret;
	CFDataRef request = CFDataCreateWithBytesNoCopy(NULL, properties, size, kCFAllocatorNull);
	
	ret = IORegistryEntrySetCFProperties (service, request);
	if (ret != kIOReturnSuccess)
		NSLog(@"Failed setting driver properties: 0x%x", ret);
	CFRelease(request);
}

- (void)centerJoysticks
{
	if (_isVirtualHIDOpen) {
		int i;
		for (i = 0; i < maxNumWiimotes; i++) {
			if (_wiimote[i] != nil) {
				UInt8 properties[4] = {0, 0, 0, 0};
				properties[0] = hid_XYZ;
				setVirtualDriverPropertiesFast(_service[i], properties, 4);
				properties[0] = hid_rXYZ;
				setVirtualDriverPropertiesFast(_service[i], properties, 4);
			}
		}
	}
}

- (void) mouseIncrementX:(float)x Y:(float)y
{
	int dispWidth = CGDisplayPixelsWide(kCGDirectMainDisplay);
	int dispHeight = CGDisplayPixelsHigh(kCGDirectMainDisplay);
	
	float sens2 = (float)[prefs getMouseSensitivity] / (float)100.0;//0.5; // * 0.5;
	
	float newx = x*sens2*dispWidth/100; // + dispWidth/2;
	float newy = -y*sens2*dispHeight/100; // + dispHeight/2;
	
	CGPoint point;
	NSPoint nowPoint = [NSEvent mouseLocation];
	point.x = nowPoint.x;
	point.y = dispHeight - nowPoint.y;
	
	//NSLog(@"ir: %f %f",newx,newy);	
	
	point.x += newx;
	point.y += newy;
	
	if (point.x < 0) point.x = 0;
	if (point.y < 0) point.y = 0;
	if (point.x >= dispWidth) point.x = dispWidth-1;
	if (point.y >= dispHeight) point.y = dispHeight-1; 
	
	//NSLog(@"mouse: %f %f",point.x,point.y);		
		
	CFRelease(CGEventCreate(NULL));		 // this is Tiger's bug.
	
	CGEventRef event = CGEventCreateMouseEvent(NULL, kCGEventMouseMoved, point, kCGMouseButtonLeft);
	CGEventSetType(event, kCGEventMouseMoved); // this is Tiger's bug.
	CGEventPost(kCGHIDEventTap, event);
	CFRelease(event);
}

- (void) mouseSetX:(float)x Y:(float)y
{
	int dispWidth = CGDisplayPixelsWide(kCGDirectMainDisplay);
	int dispHeight = CGDisplayPixelsHigh(kCGDirectMainDisplay);
	
	float sens2 = (float)[prefs getMouseSensitivity] / (float)100.0;//0.5; // * 0.5;
	
	float newx = x*sens2*dispWidth + dispWidth/2;
	float newy = -y*sens2*dispHeight + dispHeight/2;
	
	if (newx < 0) newx = 0;
	if (newy < 0) newy = 0;
	if (newx >= dispWidth) newx = dispWidth-1;
	if (newy >= dispHeight) newy = dispHeight-1;

	CGPoint point;
	//NSPoint nowPoint = [NSEvent mouseLocation];
	//point.x = nowPoint.x;
	//point.y = dispHeight - nowPoint.y;
	
	//NSLog(@"ir: %f %f",newx,newy);	
	
	point.x = newx;
	point.y = newy;
	
	//NSLog(@"mouse: %f %f",point.x,point.y);		
		
	CFRelease(CGEventCreate(NULL));		 // this is Tiger's bug.
	CGEventRef event = CGEventCreateMouseEvent(NULL, (_draggingMouse) ? kCGEventLeftMouseDragged : kCGEventMouseMoved, point, kCGMouseButtonLeft);
	CGEventSetType(event, (_draggingMouse) ? kCGEventLeftMouseDragged : kCGEventMouseMoved); // this is Tiger's bug.
	CGEventPost(kCGHIDEventTap, event);
	CFRelease(event);
}

- (void) doMouseX:(float)x Y:(float)y
{
	static int orient[3] = {0, 0, 0};
	static int tmp;
	[prefs getMouseOrientation:orient];
	
	NSLog(@"mouse: %f %f",x,y,nil);	
	
	if (orient[2]) {
		tmp = x;
		x = y;
		y = tmp;
	}
	if (orient[0])
		x = -x;
	if (orient[1])
		y = -y;

	if ([prefs getMouseMovementStyle] == 0)
		[self mouseIncrementX:x Y:y];
	else
		[self mouseSetX:x Y:y];
}

#pragma mark -
#pragma mark Utility functions for other controllers
- (void) syncEnableMotion
{
	int i;
	for (i = 0; i < maxNumWiimotes; i++) {
		if (_wiimote[i] != nil) {
			[_wiimote[i] setMotionSensorEnabled:[prefs isMotionRequired:i]];
			//[_wiimote[i] doUpdateReportMode];
			//NSLog(@"set motion %d to %d" , i, [prefs isMotionRequired:i]);
		}
	}
}

- (void) syncEnableIR
{
	int i;
	for (i = 0; i < maxNumWiimotes; i++) {
		if (_wiimote[i] != nil) {
			[_wiimote[i] setIRSensorEnabled:[prefs isIRrequired:i]];
			//NSLog(@"set IR %d to %d" , i, [prefs isIRrequired:i]);
		}
	}
}

@end
