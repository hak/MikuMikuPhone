//
//  vmdMotionProvider.h
//  MikuMikuPhone
//
//  Created by hakuroum on 1/19/11.
//  Copyright 2011 hakuroum@gmail.com. All rights reserved.
//
#import <vector>

#import <Foundation/Foundation.h>
#import "vmdReader.h"
#import "pmdReader.h"
#import "PVRTVector.h"
#import "PVRTQuaternion.h"

const double FRAME_PERSEC = 60.0;
NSString* const STR_IK_KNEE = @"ひざ";

enum JOINT_TYPE {
	JOINT_TYPE_NORMAL,
	JOINT_TYPE_KNEE,
};

struct motion_item {
	uint32_t iFrame;
	float fPos[ 3 ];
	float fRotation[ 4 ];
	uint8_t	cInterpolation[ 16 ];
};

struct bone_stats {
	bool bUpdated;
	JOINT_TYPE	iJointType;
	int32_t	iCurrentIndex;
	PVRTMat4 matCurrent;
	PVRTMat4 mat;
	float fQuaternion[ 4 ];
};

class vmdMotionProvider {
	NSMutableDictionary* _dicBones;

	float _fCurrentFrame;
	double _dStartTime;

	uint32_t _uiMaxFrame;
	std::vector<std::vector<motion_item>*> _vecBones;
	std::vector<bone_stats> _vecBonesWork;
	pmdReader* _reader;
	
	int32_t _iNumBones;
	mmd_bone* _pBones;
	
	bool checkBones( pmdReader* reader, vmdReader* motion );
	void interpolateLinear(float fFrame, motion_item *M0, motion_item *pM1, motion_item *pOut);
	void slerp(float p[], float q[], float r[], double t);
	double bazier(const uint8_t* ip, const int ofs, const int size, const float t);
	void quaternionToMatrix(float* mat, const float* quat);
	void quaternionToMatrixPreserveTranslate(float* mat, const float* quat);

	void quaternionMul(float* res, float* r, float* q);
	void updateBoneMatrix( const int32_t i );

	void resolveIK();
	void ccdIK( mmd_ik* pIk);
	void getCurrentPosition( PVRTVec3& vec, int32_t iIndex);
	void clearUpdateFlags( int32_t iCurrentBone, int32_t iTargetBone );
	void makeQuaternion(float* quat, float angle, PVRTVec3 axis );
	
public:
	vmdMotionProvider();
	~vmdMotionProvider();
	
	bool bind( pmdReader* reader, vmdReader* motion );
	bool unbind();
	
	bool update( const double dTime );
	std::vector<bone_stats>* getMatrixPalette() { return &_vecBonesWork; }
	
};