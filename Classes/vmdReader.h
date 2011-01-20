//
//  vmdReader.h
//  MikuMikuPhone
//
//  Created by hakuroum on 1/14/11.
//  Copyright 2011 hakuroum@gmail.com . All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma pack(1)
//Should be 38 bytes in size
#pragma pack()

class vmdReader
{
	int8_t* _pData;
	int32_t _iOffset;
	NSData* _data;
	
	int32_t getInteger();
	int16_t getShort();
	float getFloat();

	bool verifyHeader();
public:
	vmdReader();
	~vmdReader();
	bool init( NSString* strFileName );
	
};