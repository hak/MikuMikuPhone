//
//  pmdReader.mm
//  MikuMikuPhone
//
//  Created by hakuroum on 1/14/11.
//  Copyright 2011 hakuroum@gmail.com . All rights reserved.
//

#import "pmdReader.h"

#pragma mark Ctor
pmdReader::pmdReader()
{
}

#pragma mark Dtor
pmdReader::~pmdReader()
{
	unload();
}

#pragma mark Init
bool pmdReader::init( NSString* strFileName )
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
	
	if( !parseVertices() )
		return false;
	if( !parseIndices() )
		return false;
	if( !parseMaterials() )
		return false;
	if( !parseBones() )
		return false;
	if( !parseIKs() )
		return false;
	if( !parseSkins() )
		return false;
	
	//Just ignore other stuff...
	
	return true;	
}

bool pmdReader::unload()
{
	for( int32_t i = 0; i < _iNumMaterials; ++i )
	{
		if( _pMaterials[ i ]._tex2D )
		{
			[_pMaterials[ i ]._tex2D release];
			_pMaterials[ i ]._tex2D = nil;
		}
	}
	
	if( _data )
	{
		[_data release];
		_data = nil;
	}
	return true;
}

#pragma mark Parser
int16_t pmdReader::getShort()
{
	int16_t i =  *(int16_t*)&_pData[ _iOffset ];
	_iOffset += sizeof( int16_t );
	return i;
}

int32_t pmdReader::getInteger()
{
	int32_t i =  *(int32_t*)&_pData[ _iOffset ];
	_iOffset += sizeof( int32_t );
	return i;
}

float pmdReader::getFloat()
{
	float f =  *(float*)&_pData[ _iOffset ];
	_iOffset += sizeof( float );
	return f;
}

bool pmdReader::parseVertices()
{
	int32_t iVertices = getInteger();
	NSLog( @"Num vertices: %d", iVertices );
	_iNumVertices = iVertices;
	_pVertices = (mmd_vertex*)&_pData[ _iOffset ];
	_iOffset += iVertices * sizeof( mmd_vertex );
	
	//Reverse Z
	for( int32_t i = 0; i < iVertices; ++i )
	{
		//_pVertices[ i ].pos[ 2 ] = -_pVertices[ i ].pos[ 2 ];
		
		if (_pVertices[ i ].bone_weight < 50)
		{
			uint16_t tmp = _pVertices[ i ].bone_num[0];
			_pVertices[ i ].bone_num[0] = _pVertices[ i ].bone_num[1];
			_pVertices[ i ].bone_num[1] = tmp;
			_pVertices[ i ].bone_weight = (uint8_t) (100 - _pVertices[ i ].bone_weight);
		}
		
	}
	
	if( _iOffset > [_data length] )
		return false;
		
	return true;
}

bool pmdReader::parseIndices()
{
	int32_t iIndices = getInteger();
	NSLog( @"Num Indices: %d", iIndices );
	_iNumIndices = iIndices;	//Num triangles /=3
	_pIndices = (uint16_t*)&_pData[ _iOffset ];
	_iOffset += iIndices * sizeof( uint16_t );
	
	if( _iOffset > [_data length] )
		return false;
	
	return true;
}

bool pmdReader::parseMaterials()
{
	int32_t i = getInteger();
	NSLog( @"Num Materials: %d", i );
	_iNumMaterials = i;
	_pMaterials = (mmd_material*)&_pData[ _iOffset ];
	_iOffset += i * sizeof( mmd_material );
	
	if( _iOffset > [_data length] )
		return false;
	
	for( int32_t i = 0; i < _iNumMaterials; ++i )
	{
		if( _pMaterials[ i ].texture_file_name[ 0 ] != 0 )
		{
			NSString* strFile = [NSString stringWithUTF8String: _pMaterials[ i ].texture_file_name];
			NSLog( @"Texture:%s", _pMaterials[ i ].texture_file_name );
			_pMaterials[ i ]._tex2D = [[Texture2D alloc] initWithImage: [UIImage imageNamed:strFile]];
			_pMaterials[ i ]._tex = _pMaterials[ i ]._tex2D.name;
			
		}
		else
		{
			_pMaterials[ i ]._tex2D = nil;
			_pMaterials[ i ]._tex = 0;
		}
	}

	return true;
}

bool pmdReader::parseBones()
{
	int32_t i = getShort();
	NSLog( @"Num Bones: %d", i );
	_iNumBones = i;
	_pBones = (mmd_bone*)&_pData[ _iOffset ];
	_iOffset += i * sizeof( mmd_bone );
	
	if( _iOffset > [_data length] )
		return false;
	
	return true;
}

bool pmdReader::parseIKs()
{
	int32_t iNumIK = getShort();
	NSLog( @"Num IKs: %d", iNumIK );
	_iNumIKs = iNumIK;
	_pIKs = (mmd_ik*)&_pData[ _iOffset ];
	
	for( int32_t i = 0; i < iNumIK; ++i )
	{
		mmd_ik* currentIK = (mmd_ik*)&_pData[ _iOffset ];
		int32_t iChains = currentIK->ik_chain_length;
		NSLog( @"Chains %d, %d", i, iChains );
		_iOffset += sizeof( mmd_ik ) + iChains * sizeof( uint16_t );
	}

	if( _iOffset > [_data length] )
		return false;
	
	return true;
}

bool pmdReader::parseSkins()
{
	int32_t iNumSkins = getShort();
	NSLog( @"Num Skins: %d", iNumSkins );
	_iNumSkins = iNumSkins;
	_pSkins = (mmd_skin*)&_pData[ _iOffset ];
	
	for( int32_t i = 0; i < iNumSkins; ++i )
	{
		mmd_skin* currentSkin = (mmd_skin*)&_pData[ _iOffset ];
		int32_t iVertices = currentSkin->skin_vert_count;
		NSLog( @"Skin %d, %d", i, iVertices );
		_iOffset += sizeof( mmd_skin ) + iVertices * sizeof( mmd_skin_vertex );
	}
	
	if( _iOffset > [_data length] )
		return false;
	
	return true;
}

bool pmdReader::verifyHeader()
{
	const int32_t PMD_MAGIC = 'd' << 16 | 'm' << 8 | 'P';
	const float PMD_VERSION = 1.f;
	const int32_t PMD_MODELNAME_SIZE = 20;
	const int32_t PMD_COMMENT_SIZE = 256;
	
	if( !_pData )
		return false;

	if( getInteger() != PMD_MAGIC )
		return false;
	
	_iOffset -= 1;	//Magicword == 3bytes

	float fVersion = getFloat();
	if( fVersion != PMD_VERSION )
		return false;
	
	NSData* strModelName = [NSString stringWithCString:(const char*)&_pData[ _iOffset ] encoding:NSShiftJISStringEncoding];
	NSLog( @"ModelName:%@", strModelName );
	_iOffset += PMD_MODELNAME_SIZE;

	NSData* strComment = [NSString stringWithCString:(const char*)&_pData[ _iOffset] encoding:NSShiftJISStringEncoding];
	NSLog( @"Comment:%@", strComment );
	_iOffset += PMD_COMMENT_SIZE;
	
	return true;	
}

