//
//  vmdReader.h
//  MikuMikuPhone
//
//  Created by hakuroum on 1/14/11.
//  Copyright 2011 hakuroum@gmail.com . All rights reserved.
//

#import <Foundation/Foundation.h>

//#define DUMP_SKIN_MOTION (1)

#pragma pack(1)
//Should be 111 bytes in size
struct vmd_motion
{
	char		BoneName[15];
	uint32_t	FlameNo;
	float		Location[3];
	float		Rotatation[4]; // Quaternion
	uint8_t		Interpolation[64]; // [4][4][4]
};

//Should be 23 bytes in size
struct vmd_skin
{
	char		SkinName[15];
	uint32_t	FlameNo;
	float		Weight;
};

//Should be 61 bytes in size
struct vmd_camera
{
	uint32_t	FlameNo;
	float		Length;	// -(distance)
	float		Location[3];
	float		Rotation[3];	// Euler, flipped x axis
	uint8_t		Interpolation[24];
	uint32_t	ViewingAngle;
	uint8_t		Perspective; // 0:on 1:off
};

//Should be 23 bytes in size
struct vmd_light
{
	uint32_t	FlameNo;
	float		RGB[3];	// RGB value/256
	float		Location[3];
};

//Should be 9 bytes in size
struct vmd_self_shadow
{
	uint32_t	FlameNo;
	uint8_t		Mode;		// 00-02
	float		Distance;	// 0.1 - (dist * 0.00001)
};

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

	int32_t _iNumMotions;
	vmd_motion* _pMotions;

	int32_t _iNumSkins;
	vmd_skin*	_pSkins;

	int32_t _iNumCameras;
	vmd_camera* _pCameras;
	
	int32_t _iNumLights;
	vmd_light*	_pLights;
	
	int32_t _iNumShadows;
	vmd_self_shadow* _pShadows;

	bool parseMotions();
	bool parseSkins();
	bool parseCameras();
	bool parseLights();
	bool parseShadows();
public:
	vmdReader();
	~vmdReader();
	bool init( NSString* strFileName );
	bool unload();
	
	int32_t getNumMotions() { return _iNumMotions; }
	vmd_motion* getMotions() { return _pMotions; }
	
	int32_t getNumSkins() { return _iNumSkins; }
	vmd_skin* getSkins() { return _pSkins; }

	int32_t getNumCameras() { return _iNumCameras; }
	vmd_camera* getCameras() { return _pCameras; }

	int32_t getNumLights() { return _iNumLights; }
	vmd_light* getLights() { return _pLights; }

	int32_t getNumShadows() { return _iNumShadows; }
	vmd_self_shadow* getShadows() { return _pShadows; }
	
};