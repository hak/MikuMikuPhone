//
//  vmdReader.mm
//  MikuMikuPhone
//
//  Created by hakuroum on 1/14/11.
//  Copyright 2011 hakuroum@gmail.com . All rights reserved.
//

#import "vmdReader.h"

#pragma mark Ctor
vmdReader::vmdReader()
{
}

#pragma mark Dtor
vmdReader::~vmdReader()
{
	unload();
}

#pragma mark Init
bool vmdReader::init( NSString* strFileName )
{
	_data = [[NSData dataWithContentsOfFile:strFileName options:NSDataReadingUncached error:nil] retain];
	if( !_data )
    {
        NSLog(@"Failed to load data");
        return FALSE;
    }
	
    _pData = (int8_t*)[_data bytes];
    if (!_pData)
    {
        NSLog(@"Failed to load data");
        return FALSE;
    }
	_iOffset = 0;
	
	if( verifyHeader() == false )
		return false;
	if( !parseMotions() )
		return false;
	if( !parseSkins() )
		return false;
	if( !parseCameras() )
		return false;
	if( !parseShadows() )
		return false;
	
	//Just ignore other stuff...
	return true;	
}

bool vmdReader::unload()
{
	if( _data )
	{
		[_data release];
		_data = nil;
	}
	return 0;
}

#pragma mark Parser
int16_t vmdReader::getShort()
{
	int16_t i =  *(int16_t*)&_pData[ _iOffset ];
	_iOffset += sizeof( int16_t );
	return i;
}

int32_t vmdReader::getInteger()
{
	int32_t i =  *(int32_t*)&_pData[ _iOffset ];
	_iOffset += sizeof( int32_t );
	return i;
}

float vmdReader::getFloat()
{
	float f =  *(float*)&_pData[ _iOffset ];
	_iOffset += sizeof( float );
	return f;
}

bool vmdReader::parseMotions()
{
	int32_t i = getInteger();
	NSLog( @"Num Motions: %d", i );
	_iNumMotions = i;
	_pMotions = (vmd_motion*)&_pData[ _iOffset ];
	_iOffset += i * sizeof( vmd_motion );
	
	if( _iOffset > [_data length] )
		return false;
	
	return true;
}

bool vmdReader::parseSkins()
{
	int32_t i = getInteger();
	NSLog( @"Num Skins: %d", i );
	_iNumSkins = i;
	_pSkins = (vmd_skin*)&_pData[ _iOffset ];
	_iOffset += i * sizeof( vmd_skin );
	
	if( _iOffset > [_data length] )
		return false;
	
	return true;
}

bool vmdReader::parseCameras()
{
	int32_t i = getInteger();
	NSLog( @"Num Cameras: %d", i );
	_iNumCameras = i;
	_pCameras = (vmd_camera*)&_pData[ _iOffset ];
	_iOffset += i * sizeof( vmd_camera );
	
	if( _iOffset > [_data length] )
		return false;
	
	return true;
}

bool vmdReader::parseLights()
{
	int32_t i = getInteger();
	NSLog( @"Num Lights: %d", i );
	_iNumLights = i;
	_pLights = (vmd_light*)&_pData[ _iOffset ];
	_iOffset += i * sizeof( vmd_light );
	
	if( _iOffset > [_data length] )
		return false;
	
	return true;
}

bool vmdReader::parseShadows()
{
	int32_t i = getInteger();
	NSLog( @"Num Shadows: %d", i );
	_iNumLights = i;
	_pShadows = (vmd_self_shadow*)&_pData[ _iOffset ];
	_iOffset += i * sizeof( vmd_self_shadow );
	
	if( _iOffset > [_data length] )
		return false;
	
	return true;
}

bool vmdReader::verifyHeader()
{
	const char* VMD_MAGIC = "Vocaloid Motion Data 0002";
	const int32_t VMD_MAGIC_SIZE = 30;
	const int32_t VMD_MODELNAME_SIZE = 20;
	
	if( !_pData )
		return false;

	if( 0 != strcmp( (const char*)&_pData[ _iOffset ], VMD_MAGIC ) )
		return false;
		
	_iOffset += VMD_MAGIC_SIZE;
	_iOffset += VMD_MODELNAME_SIZE;
	
	return true;	
}

