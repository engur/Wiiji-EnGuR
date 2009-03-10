//
//  virtualhid.h
//  virtualhid
//
//  Created by Taylor Veltrop on 3/26/08.
//  Copyright 2008 Taylor Veltrop. All rights reserved.
//  Read COPYRIGHT.txt for legal info.
//  See comments in wiimote_manager.m in accompanying wiipad project for a synopsis.
//  See ChangeLog.txt as well.

#ifndef virtualhid_h
#define virtualhid_h

#include <IOKit/IOService.h>
#include <IOKit/hid/IOHIDDevice.h>
#include <IOKit/usb/IOUSBInterface.h>

class com_veltrop_taylor_driver_virtualhid : public IOHIDDevice	{
	OSDeclareDefaultStructors(com_veltrop_taylor_driver_virtualhid)

	UInt32			_deviceUsage;
	UInt32			_deviceUsagePage;
	UInt32			_maxOutReportSize;
	UInt32			_maxReportSize;
	
//	IOCommandGate *		_gate;

	IOBufferMemoryDescriptor * _myReportBufferDesc;				// the only live data we need to emulate this device
	UInt8*							_myReportBufferDescInternal;	// easy access to the data
	
public:
	// IO Driver methods
	virtual bool init(OSDictionary *dictionary = 0);
	virtual void free(void);
	
	virtual bool didTerminate( IOService * provider, IOOptionBits options, bool * defer );
	virtual bool willTerminate( IOService * provider, IOOptionBits options );
	 
	virtual bool start(IOService *provider);
	virtual void stop(IOService *provider);
	virtual IOService *probe(IOService *provider, SInt32 *score);
	
	// IOHIDDevice methods
	virtual IOReturn newReportDescriptor( IOMemoryDescriptor ** descriptor ) const;
	virtual OSString* newManufacturerString() const;
	virtual OSString* newProductString() const;
	virtual OSString* newTransportString() const;
	virtual OSNumber* newPrimaryUsageNumber() const;
	virtual OSNumber* newPrimaryUsagePageNumber() const;
	virtual OSNumber* newLocationIDNumber() const;
	// NOTE: there are many other "required" methods of IOHIDDevice, this seems to be enough to satisfy other programs.
	
	virtual IOReturn setProperties( OSObject * properties );

protected:
	virtual bool handleStart(IOService * provider);
	virtual void handleStop(IOService *  provider);
	
};

#endif
