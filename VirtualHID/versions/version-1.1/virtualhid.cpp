//
//  virtualhid.cpp
//  virtualhid
//
//  Created by Taylor Veltrop on 3/26/08.
//  Copyright 2008 Taylor Veltrop. All rights reserved.
//  Read COPYRIGHT.txt for legal info.
//  See comments in wiimote_manager.m in accompanying wiipad project for a synopsis.
//  See ChangeLog.txt as well.

//com_veltrop_taylor_driver_virtualhid

#include <IOKit/IOLib.h>
#include <IOKit/hid/IOHIDDevice.h>
#include <IOKit/usb/IOUSBHIDDriver.h>

// I can't use bluetooth devices directly in the context of the kernel, only the hubs
// Bluetooth really wants to be dealt with in userland... 
// Wiiji can deal with that, and send the commands to set our descriptor with setproperties
/*#include <IOKit/bluetooth/Bluetooth.h>
#include <IOKit/bluetooth/IOBluetoothTypes.h>
#include <IOKit/bluetooth/IOBluetoothInternal.h>
#include <IOKit/bluetooth/BluetoothAssignedNumbers.h>
#include <IOKit/bluetooth/IOBluetoothHCIController.h>
#include <IOKit/bluetooth/IOBluetoothHCIRequest.h> */

#include <wiimote_types.h>
#include "virtualhid.h"

extern "C" {
#include <pexpert/pexpert.h> //This is for debugging
}

#define myReportSize 6				// size of actual report in bytes
#define myReportDescSize 61		// size of following report descriptor in bytes
static char myHIDReportDescriptor[myReportDescSize] = {
	// initial defaults
	0x05, 0x01,                    // USAGE_PAGE (Generic Desktop)
	0x15, 0x00,                    // LOGICAL_MINIMUM (0)
	0x09, 0x04,                    // USAGE (Joystick)  // joystick = 4, gamepad = 5
	0xa1, 0x01,                    // COLLECTION (Application)
	0x15, 0x81,                    //   LOGICAL_MINIMUM (-127)
	0x25, 0x7f,                    //   LOGICAL_MAXIMUM (127)
	0x75, 0x08,                    //   REPORT_SIZE (8)

	// throttle
//	0x05, 0x02,                    //   USAGE_PAGE (Simulation Controls)
//	0x09, 0xbb,                    //   USAGE (Throttle)
//	0x95, 0x01,                    //   REPORT_COUNT (1)						// 0 byte
//	0x81, 0x02,                    //   INPUT (Data,Var,Abs)

	// rudder
//	0x09, 0xba,                    //     USAGE (Rudder)    
//	0x95, 0x01,                    //     REPORT_COUNT (1)					// 0 byte
//	0x81, 0x02,                    //     INPUT (Data,Var,Abs) 

	// primary axis
	0x05, 0x01,                    //   USAGE_PAGE (Generic Desktop)
	0x09, 0x01,                    //   USAGE (Pointer)
	0xa1, 0x00,                    //   COLLECTION (Physical)
	0x09, 0x30,                    //     USAGE (X)
	0x09, 0x31,                    //     USAGE (Y)
//	0x09, 0x32,                    //     USAGE (Z)
	0x95, 0x02,                    //     REPORT_COUNT (2)					// 2 bytes
	0x81, 0x02,                    //     INPUT (Data,Var,Abs)
	0xc0,                          //   END_COLLECTION

	// secondary axis
	0xa1, 0x00,                    //   COLLECTION (Physical)
	0x09, 0x33,                    //     USAGE (Rx)
	0x09, 0x34,                    //     USAGE (Ry)
//	0x09, 0x35,                    //     USAGE (Rz)
	0x95, 0x02,                    //     REPORT_COUNT (2)					// 2 bytes
	0x81, 0x02,                    //     INPUT (Data,Var,Abs)
	0xc0,                          //   END_COLLECTION
	
	// third axis ?
	
	// d-pad ? X,Y seems best for most compatibility

	// buttons
	// need 28 (1c, 3.5 bytes) if we separate wii remote and classic
	0x05, 0x09,                    //   USAGE_PAGE (Button)
	0x19, 0x01,                    //   USAGE_MINIMUM (Button 1)
	0x29, 0x0B,                    //   USAGE_MAXIMUM (Button 11)
	0x15, 0x00,                    //   LOGICAL_MINIMUM (0)
	0x25, 0x01,                    //   LOGICAL_MAXIMUM (1)
	0x75, 0x01,                    //   REPORT_SIZE (1)
	0x95, 0x0B,                    //   REPORT_COUNT (11)						// 2 bytes
	0x55, 0x00,                    //   UNIT_EXPONENT (0)
	0x65, 0x00,                    //   UNIT (None)
	0x81, 0x02,                    //   INPUT (Data,Var,Abs)

	// hat switch, does anyone care?
//	0x09, 0x39,                    //   USAGE (Hat switch)
//	0x15, 0x00,                    //   LOGICAL_MINIMUM (0)
//	0x25, 0x07,                    //   LOGICAL_MAXIMUM (7)
//	0x35, 0x00,                    //   PHYSICAL_MINIMUM (0)
//	0x46, 0x3b, 0x01,              //   PHYSICAL_MAXIMUM (315)
//	0x65, 0x14,                    //   UNIT (Eng Rot:Angular Pos)
//	0x75, 0x04,                    //   REPORT_SIZE (4)	// 0.5 bytes	// 0
//	0x95, 0x01,                    //   REPORT_COUNT (1)
//	0x81, 0x02,                    //   INPUT (Data,Var,Abs)

	0xc0                           // END_COLLECTION
};

#define super IOHIDDevice

OSDefineMetaClassAndStructors(com_veltrop_taylor_driver_virtualhid, IOHIDDevice)
 
bool com_veltrop_taylor_driver_virtualhid::init(OSDictionary *dict)
{
	IOLog("Initializing\n");
	if (!super::init(dict)) {
		return false;
	}
	
	_deviceUsage = 0;
	_deviceUsagePage = 0;
	_maxReportSize = kMaxHIDReportSize;
	_maxOutReportSize = kMaxHIDReportSize;

	_myReportBufferDesc = IOBufferMemoryDescriptor::withCapacity(myReportSize, kIODirectionIn);
	if (!_myReportBufferDesc) {
		IOLog("com_veltrop_taylor_driver_virtualhid::init: can't allocate memory: _myReportBufferDesc\n");
		_myReportBufferDescInternal = NULL;
		return false;
	}
	else {
		_myReportBufferDescInternal = (UInt8*)(_myReportBufferDesc->getBytesNoCopy());
		for (int i = 0; i < myReportSize; i++)
			_myReportBufferDescInternal[i] = 0;
	}
	
	return true;
}
 
void com_veltrop_taylor_driver_virtualhid::free(void)
{
	//IOLog("Freeing\n");
	//if (_myReportBufferDesc) {
	//	_myReportBufferDesc->free();
	//	delete 	_myReportBufferDesc;
	//}
	super::free();
}
 
bool com_veltrop_taylor_driver_virtualhid::start(IOService *provider)
{
	//IOLog("Starting\n");
	bool res = super::start(provider);
	
	return res;
}
 
void com_veltrop_taylor_driver_virtualhid::stop(IOService *provider)
{
	//IOLog("Stopping\n");
	super::stop(provider);
}

int num_kids(IOService *provider)
{
	int total = 1;
	//total++;
	OSIterator *kids;
	const char* poo = provider->getName();
	IOLog("name: %s \n", poo);
	if (kids = provider->getChildIterator(gIOServicePlane)) {
		IOService *nextkid;
		while (nextkid = (IOService*)kids->getNextObject()) {
			total += num_kids(nextkid);
		}
		kids->release();
	}
	return total;
}

// matching on IOBluetoothDevice is best... except we cant access that object in the kernel... which is a problem here
// this is a huge hack...
// Better ways to match the right device (or deal with the driver loading problem in general):
//		1. if we could access IOBluetoothDevice(Ref) here, just ask it what its Manufacture, etc is.
//		2. Setup a meta-driver up to match on ioresources and be a virtual driver, that meta-driver will always be loaded
//			That driver will be told by wiiji.app when to manually instanciate the right number of instances of this driver
//		3. Instead of merely counting all of the child resources, look at them specificly to see if we find any recognized driver strings such as "Apple"
//       If none are found, then lets claim it.  This is unreasonable, we'd have to know all possible things to search for...
//		4. Figure out which properties we can put in the driver's personality to match with IOBluetoothDevices (there doesn't seem to be any useful properties available)
// TODO: make the probe better, or find a different solution!
// On second thought... this is somewhat convinient...
IOService *com_veltrop_taylor_driver_virtualhid::probe(IOService *provider, SInt32 *score)
{
	IOService *res = super::probe(provider, score);
	//IOLog("Probing\n");
	
	// worst hack ever: count the number of children to determine if we are indeed the right driver for this device!
	int total_kids;
	total_kids = num_kids(provider);
	IOLog("Total Kids: %d \n", total_kids);
	// 3 if the device is fresh, 9 if wiiji already grabbed it, X? if os-x tried to claim it in the hid device nodes but can't
	// 4 if osculator driver grabbed one of the L2Cap kids but osculator.app not open, 12 if osculator.app is open
	if (total_kids == 3 || total_kids == 9 || total_kids == 4 || total_kids == 12)		
		return res;

	return NULL;
}

bool com_veltrop_taylor_driver_virtualhid::handleStart(IOService * provider)
{
	//IOLog("handleStart\n");
	HIDPreparsedDataRef parseData;
	HIDCapabilities 	  myHIDCaps;
	UInt32          	  hidDescSize = myReportDescSize;
	IOReturn		        err = kIOReturnSuccess;
	
	if( !super::handleStart(provider)) {			// fails if I use IOUSBHIDDriver as a base class, IOUSBHIDDriver really needs real hardware...
		IOLog("com_veltrop_taylor_driver_virtualhid: super failed in handlestart\n");
		return false;
	}
	
	err = HIDOpenReportDescriptor(myHIDReportDescriptor, hidDescSize, &parseData, 0);
	if (err == kIOReturnSuccess) {        
		err = HIDGetCapabilities(parseData, &myHIDCaps);
		if (err == kIOReturnSuccess) {
			_deviceUsage = myHIDCaps.usage;
			_deviceUsagePage = myHIDCaps.usagePage;
			_maxOutReportSize = myHIDCaps.outputReportByteLength;
			_maxReportSize = (myHIDCaps.inputReportByteLength > myHIDCaps.featureReportByteLength) ? myHIDCaps.inputReportByteLength : myHIDCaps.featureReportByteLength;
		}
		else
			IOLog("com_veltrop_taylor_driver_virtualhid: HIDGetCapabilities failed in handlestart\n");
		
		HIDCloseReportDescriptor(parseData);
	}
	else
		IOLog("com_veltrop_taylor_driver_virtualhid: HIDOpenReportDescriptor failed in handlestart\n");
		
	return true;
}

void com_veltrop_taylor_driver_virtualhid::handleStop(IOService * provider)
{
	//	IOLog("handleStop\n");
	super::handleStop(provider);
}

IOReturn com_veltrop_taylor_driver_virtualhid::newReportDescriptor(IOMemoryDescriptor ** desc) const
{
	//	IOLog("newReportDescriptor\n");

	IOBufferMemoryDescriptor * bufferDesc = NULL;
	UInt32 inOutSize = myReportDescSize;
	
	bufferDesc = IOBufferMemoryDescriptor::withCapacity(inOutSize, kIODirectionOutIn);
	
	if (bufferDesc) {
		UInt8* buff = (UInt8*)(bufferDesc->getBytesNoCopy());
		memcpy(buff, myHIDReportDescriptor, inOutSize);
	} 
	else
		return kIOReturnError;

	*desc = bufferDesc;
	
	// Note: I do not need to free bufferDesc, the caller will!

	return kIOReturnSuccess;
}

OSString* com_veltrop_taylor_driver_virtualhid::newManufacturerString() const
{
	//	IOLog("newManufacturerString\n");
	return OSString::withCString("Nintedo");
}

OSString* com_veltrop_taylor_driver_virtualhid::newProductString() const
{
	//	IOLog("newProductString\n");
	return OSString::withCString("Wiimote VirtualHID Interface");
}

OSString* com_veltrop_taylor_driver_virtualhid::newTransportString() const
{
	//	IOLog("newTransportString\n");
	return OSString::withCString("Virtual");
}

OSNumber* com_veltrop_taylor_driver_virtualhid::newPrimaryUsageNumber() const
{
//	IOLog("newPrimaryUsageNumber\n");
	return OSNumber::withNumber(_deviceUsage, 32);
}

OSNumber* com_veltrop_taylor_driver_virtualhid::newPrimaryUsagePageNumber() const
{
//	IOLog("newPrimaryUsagePageNumber\n");
	return OSNumber::withNumber(_deviceUsagePage, 32);
}

// TODO: We should traverse the IORegistry to make this accurately represent our level in it
//			Also, we should increment this for each instance of this driver so that it is unique
OSNumber* com_veltrop_taylor_driver_virtualhid::newLocationIDNumber() const
{
	return OSNumber::withNumber(0x66666666, 32);
}

// TODO: is it safe to make the data in here static?  It would speed things up slightly.
IOReturn com_veltrop_taylor_driver_virtualhid::setProperties( OSObject * properties )
{
	//IOLog("set properties to driver!!\n");
	OSData* data = OSDynamicCast(OSData, properties);
	if (data) {
		//	int length = data->getLength();	// passing a Hacked/Broken OSData object to this could make us unreliable, lets manually set 3 below, and later only explicitly access known memory!
		const UInt8* button_vector = (const UInt8*)data->getBytesNoCopy(0,3);
		// button_vector[0] -> button number / joystick number
		// button_vector[1] -> button state / button data
		// button_vector[2] -> button data 2
		
		if (_myReportBufferDescInternal) {
			UInt8 target = button_vector[0];
			if (target == hid_XYZ) {
				_myReportBufferDescInternal[0] = button_vector[1];
				_myReportBufferDescInternal[1] = button_vector[2];
			}
			else if (target == hid_rXYZ) {
				_myReportBufferDescInternal[2] = button_vector[1];
				_myReportBufferDescInternal[3] = button_vector[2];
			}
			else if (target == WiiRemoteUpButton || target == WiiRemoteDownButton) {	// swap x with y, the wii mote is probably rotated. > make this an option and do it from the wiiji side
				_myReportBufferDescInternal[0] = button_vector[1] * ((target == WiiRemoteDownButton)*(127) - (target == WiiRemoteUpButton)*(127)); 	// make sure these values stay exclusive
			}
			else if (target == WiiRemoteRightButton || target == WiiRemoteLeftButton) {
				_myReportBufferDescInternal[1] = button_vector[1] * ((target == WiiRemoteLeftButton)*(127) - (target == WiiRemoteRightButton)*(127));
			}
			else {				
				if (target >= WiiRemoteUpButton)	// compensate for the unused dpad button inputs (we route it to x/y right now)
					target -= 4;
				
				int bitoffset = target % 8;
				int octet     = target / 8 + 4;
				UInt8 action  = 0x0001 << bitoffset;
			
				if (octet >= myReportDescSize)
					return kIOReturnError;
			
				if (button_vector[1]) {
					_myReportBufferDescInternal[octet] = _myReportBufferDescInternal[octet] | action;
				}
				else {
					_myReportBufferDescInternal[octet] = _myReportBufferDescInternal[octet] & ~action;
				}
			} 
			
			if (handleReport(_myReportBufferDesc) != kIOReturnSuccess) {
				IOLog("com_veltrop_taylor_driver_virtualhid: handleReport failed in setProperties");
				return kIOReturnError;
			}
			
			return kIOReturnSuccess;
		}
	}
	
	return kIOReturnError;
}

