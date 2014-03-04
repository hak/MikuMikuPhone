//
//  vmdMotionProvider.mm
//  MikuMikuPhone
//
//  Created by hakuroum on 1/19/11.
//  Copyright 2011 hakuroum@gmail.com. All rights reserved.
//
#include <algorithm>
#import "vmdMotionProvider.h"

//#define DUMP_BONES (1)

#pragma mark Ctor
vmdMotionProvider::vmdMotionProvider(): _uiMaxFrame( 0 )
{
	_bLoopPlayback = true;
}

#pragma mark Dtor
vmdMotionProvider::~vmdMotionProvider()
{
	unbind();
}

//
//Derived from MikuMikuDroid
//http://en.sourceforge.jp/projects/mikumikudroid/
//
void vmdMotionProvider::interpolateLinear(float fFrame, motion_item *pM0, motion_item *pM1, motion_item *pOut)
{	
	if( pM1 == NULL )
	{
		*pOut = *pM0;
	}
	else
	{
		int32_t iDiff = pM1->iFrame - pM0->iFrame;
		float a0 = fFrame - pM0->iFrame;
		float fRatio = a0 / iDiff;
		
		double t = bazier(pM0->cInterpolation, 0, 4, fRatio);
		pOut->fPos[0] = (float) (pM0->fPos[0] + (pM1->fPos[0] - pM0->fPos[0]) * t);
		
		t = bazier(pM0->cInterpolation, 1, 4, fRatio);
		pOut->fPos[1] = (float) (pM0->fPos[1] + (pM1->fPos[1] - pM0->fPos[1]) * t);

		t = bazier(pM0->cInterpolation, 2, 4, fRatio);
		pOut->fPos[2] = (float) (pM0->fPos[2] + (pM1->fPos[2] - pM0->fPos[2]) * t);
		
		slerp(pOut->fRotation, pM0->fRotation, pM1->fRotation, bazier(pM0->cInterpolation, 3, 4, fRatio));
	}
}

void vmdMotionProvider::slerp(float p[], float q[], float r[], double t)
{
	double qr = q[0] * r[0] + q[1] * r[1] + q[2] * r[2] + q[3] * r[3];
	double ss = 1.0 - qr * qr;
	
	if (qr < 0) {
		qr = -qr;
		
		double sp = sqrt(ss);
		double ph = acos(qr);
		double pt = ph * t;
		double t1 = sin(pt) / sp;
		double t0 = sin(ph - pt) / sp;
		
		if (isnan(t0) || isnan(t1)) {
			p[0] = q[0];
			p[1] = q[1];
			p[2] = q[2];
			p[3] = q[3];
		} else {
			p[0] = (float) (q[0] * t0 - r[0] * t1);
			p[1] = (float) (q[1] * t0 - r[1] * t1);
			p[2] = (float) (q[2] * t0 - r[2] * t1);
			p[3] = (float) (q[3] * t0 - r[3] * t1);
		}
		
	} else {
		double sp = sqrt(ss);
		double ph = acos(qr);
		double pt = ph * t;
		double t1 = sin(pt) / sp;
		double t0 = sin(ph - pt) / sp;
		
		if (isnan(t0) || isnan(t1)) {
			p[0] = q[0];
			p[1] = q[1];
			p[2] = q[2];
			p[3] = q[3];
		} else {
			p[0] = (float) (q[0] * t0 + r[0] * t1);
			p[1] = (float) (q[1] * t0 + r[1] * t1);
			p[2] = (float) (q[2] * t0 + r[2] * t1);
			p[3] = (float) (q[3] * t0 + r[3] * t1);
		}
	}
}

double vmdMotionProvider::bazier(const uint8_t* ip, const int ofs, const int size, const float t)
{
	double xa = ip[ofs] / 256;
	double xb = ip[size * 2 + ofs] / 256;
	double ya = ip[size + ofs] / 256;
	double yb = ip[size * 3 + ofs] / 256;
	
	double min = 0;
	double max = 1;
	
	double ct = t;
	while (true)
	{
		double x11 = xa * ct;
		double x12 = xa + (xb - xa) * ct;
		double x13 = xb + (1 - xb) * ct;
		
		double x21 = x11 + (x12 - x11) * ct;
		double x22 = x12 + (x13 - x12) * ct;
		
		double x3 = x21 + (x22 - x21) * ct;
		
		if (fabs(x3 - t) < 0.0001) {
			double y11 = ya * ct;
			double y12 = ya + (yb - ya) * ct;
			double y13 = yb + (1 - yb) * ct;
			
			double y21 = y11 + (y12 - y11) * ct;
			double y22 = y12 + (y13 - y12) * ct;
			
			double y3 = y21 + (y22 - y21) * ct;
			
			return y3;
		} else if (x3 < t) {
			min = ct;
		} else {
			max = ct;
		}
		ct = min * 0.5 + max * 0.5;
	}
}

void vmdMotionProvider::quaternionMul(float* res, float* r, float* q)
{
	float  w = r[3], x = r[0], y = r[1], z = r[2];
	float qw = q[3], qx = q[0], qy = q[1], qz = q[2];
	res[0] = x * qw + y * qz - z * qy + w * qx;
	res[1] = -x * qz + y * qw + z * qx + w * qy;
	res[2] = x * qy - y * qx + z * qw + w * qz;
	res[3] = -x * qx - y * qy - z * qz + w * qw;
}

void vmdMotionProvider::quaternionToMatrix(float* mat, const float* quat)
{
	float x2 = quat[0] * quat[0] * 2.0f;
	float y2 = quat[1] * quat[1] * 2.0f;
	float z2 = quat[2] * quat[2] * 2.0f;
	float xy = quat[0] * quat[1] * 2.0f;
	float yz = quat[1] * quat[2] * 2.0f;
	float zx = quat[2] * quat[0] * 2.0f;
	float xw = quat[0] * quat[3] * 2.0f;
	float yw = quat[1] * quat[3] * 2.0f;
	float zw = quat[2] * quat[3] * 2.0f;
	
	mat[0] = 1.0f - y2 - z2;
	mat[1] = xy + zw;
	mat[2] = zx - yw;
	mat[4] = xy - zw;
	mat[5] = 1.0f - z2 - x2;
	mat[6] = yz + xw;
	mat[8] = zx + yw;
	mat[9] = yz - xw;
	mat[10] = 1.0f - x2 - y2;
	
	mat[3] = mat[7] = mat[11] = mat[12] = mat[13] = mat[14] = 0.0f;
	mat[15] = 1.0f;
}

void vmdMotionProvider::quaternionToMatrixPreserveTranslate(float* mat, const float* quat)
{
	float x2 = quat[0] * quat[0] * 2.0f;
	float y2 = quat[1] * quat[1] * 2.0f;
	float z2 = quat[2] * quat[2] * 2.0f;
	float xy = quat[0] * quat[1] * 2.0f;
	float yz = quat[1] * quat[2] * 2.0f;
	float zx = quat[2] * quat[0] * 2.0f;
	float xw = quat[0] * quat[3] * 2.0f;
	float yw = quat[1] * quat[3] * 2.0f;
	float zw = quat[2] * quat[3] * 2.0f;
	
	mat[0] = 1.0f - y2 - z2;
	mat[1] = xy + zw;
	mat[2] = zx - yw;
	mat[4] = xy - zw;
	mat[5] = 1.0f - z2 - x2;
	mat[6] = yz + xw;
	mat[8] = zx + yw;
	mat[9] = yz - xw;
	mat[10] = 1.0f - x2 - y2;
	
	mat[3] = mat[7] = mat[11] = 0.0f;
	mat[15] = 1.0f;
}


void vmdMotionProvider::updateBoneMatrix( const int32_t i )
{
	if( _vecMotionsWork[ i ].bUpdated == false )
	{
		if (_vecBones[ i ].parent_bone_index != 0xffff)
		{
			int32_t p = _vecBones[ i ].parent_bone_index;
			
			//Update parent
			updateBoneMatrix(p);
			
			_vecMotionsWork[ i ].mat = _vecMotionsWork[ p ].mat * _vecMotionsWork[ i ].matCurrent;
		}
		else
		{
			_vecMotionsWork[ i ].mat = _vecMotionsWork[ i ].matCurrent;
		}
		_vecMotionsWork[ i ].bUpdated = true;
	}
}

#pragma mark update
void dump (int32_t j, float* p )
{
	NSLog( @"%d", j );
	for( int32_t i = 0; i < 4; ++i )
		NSLog( @"%f %f %f %f", p[ i * 4 + 0 ], p[ i * 4 + 1 ], p[ i * 4 + 2 ], p[ i * 4 + 3 ] ); 
}


bool vmdMotionProvider::update( const double dTime )
{
	bool bReturn = true;

	if( _fCurrentFrame == -1.f )
	{
		//Reset
		_fCurrentFrame = 0.f;
		_dStartTime = dTime;
	}
	else
	{
		//Update frame
		double dDelta = dTime - _dStartTime;
		_fCurrentFrame = dDelta * FRAME_PERSEC;
		
		if( _bLoopPlayback
		   && _fCurrentFrame > _uiMaxFrame )
		{
			_fCurrentFrame = 0.f;
			_dStartTime = dTime;
			int32_t iSize = _vecBones.size();
			for( int32_t i = 0; i < iSize; ++i )
			{
				_vecMotionsWork[ i ].iCurrentIndex = 0;
			}
			_iCurrentSkinAnimationIndex = 0;
		}
	}

	int32_t iSize = _vecBones.size();
	for( int32_t i = 0; i < iSize; ++i )
	{
		//
		//1. get current motion
		//
		int32_t iMotionIndex = _vecMotionsWork[ i ].iCurrentIndex;
		std::vector<motion_item>& vec = *_vecMotions[ i ];
		motion_item* pCurrentItem = &vec[iMotionIndex];
		motion_item* pNextItem = &vec[iMotionIndex + 1];
		
		//Next index?
		while( pNextItem->iFrame <= _fCurrentFrame )
		{
			if( iMotionIndex < vec.size() -2 )
			{
				iMotionIndex++;
				pCurrentItem = pNextItem;
				pNextItem = &vec[iMotionIndex + 1];
			}
			else
			{
				//Runnning out of motion.
				pCurrentItem = pNextItem;
				pNextItem = NULL;
				break;
			}
		}
		_vecMotionsWork[ i ].iCurrentIndex = iMotionIndex;
		
		//
		//2. Interpolation
		//
		motion_item m;
		interpolateLinear(_fCurrentFrame, pCurrentItem, pNextItem, &m );

		//
		//3. Update
		//
		quaternionToMatrix(_vecMotionsWork[ i ].matCurrent.f, m.fRotation);
		
		if (_vecBones[ i ].parent_bone_index == 0xffff)
		{
			_vecMotionsWork[ i ].matCurrent.f[12] = m.fPos[0] + _vecBones[ i ].bone_head_pos[0];
			_vecMotionsWork[ i ].matCurrent.f[13] = m.fPos[1] + _vecBones[ i ].bone_head_pos[1];
			_vecMotionsWork[ i ].matCurrent.f[14] = m.fPos[2] + _vecBones[ i ].bone_head_pos[2];
		}
		else
		{
			mmd_bone* p = &_vecBones[ _vecBones[ i ].parent_bone_index ];
			_vecMotionsWork[ i ].matCurrent.f[12] = m.fPos[0] + _vecBones[ i ].bone_head_pos[0] - p->bone_head_pos[ 0 ];
			_vecMotionsWork[ i ].matCurrent.f[13] = m.fPos[1] + _vecBones[ i ].bone_head_pos[1] - p->bone_head_pos[ 1 ];
			_vecMotionsWork[ i ].matCurrent.f[14] = m.fPos[2] + _vecBones[ i ].bone_head_pos[2] - p->bone_head_pos[ 2 ];			
		}
		
		_vecMotionsWork[ i ].bUpdated = false;
		_vecMotionsWork[ i ].fQuaternion[ 0 ] = m.fRotation[ 0 ];
		_vecMotionsWork[ i ].fQuaternion[ 1 ] = m.fRotation[ 1 ];
		_vecMotionsWork[ i ].fQuaternion[ 2 ] = m.fRotation[ 2 ];
		_vecMotionsWork[ i ].fQuaternion[ 3 ] = m.fRotation[ 3 ];
	}

	//
	//4. Resolve IK
	//
	resolveIK();
	
	//
	//5. Update chain
	//
	for( int32_t i = 0; i < iSize; ++i )
	{
		updateBoneMatrix( i );
	}

	//
	//6. Back to position
	//
	for( int32_t i = 0; i < iSize; ++i )
	{
		PVRTMat4 mat;
		PVRTMatrixTranslationF( mat, 
							   -_vecBones[ i ].bone_head_pos[0],
							   -_vecBones[ i ].bone_head_pos[1],
							   -_vecBones[ i ].bone_head_pos[2] );

		_vecMotionsWork[ i ].mat = _vecMotionsWork[ i ].mat * mat;
	}
		
	//
	//Skin update
	//
	updateSkinAnimation();
	
	return bReturn;
}

#pragma mark bind
bool dataSortPredicate(const motion_item& d1, const motion_item& d2)
{
	return d1.iFrame < d2.iFrame;
}

bool vmdMotionProvider::bind( pmdReader* reader, vmdReader* motion )
{
	if( reader == NULL || motion == NULL )
		return false;

	//
	//Create bone dictionary
	//
	_dicBones = [[NSMutableDictionary alloc] init];
	int32_t iNumBones = reader->getNumBones();
	mmd_bone* pBone = reader->getBones(); 
	
	//Initialize motion array
	motion_item defaultMotion;
	defaultMotion.iFrame = 0;
	defaultMotion.fPos[ 0 ] = 0.f;
	defaultMotion.fPos[ 1 ] = 0.f;
	defaultMotion.fPos[ 2 ] = 0.f;
	defaultMotion.fRotation[ 0 ] = 0.f;
	defaultMotion.fRotation[ 1 ] = 0.f;
	defaultMotion.fRotation[ 2 ] = 0.f;
	defaultMotion.fRotation[ 3 ] = 1.f;
	for( int32_t i = 0; i < 16; ++i )
		defaultMotion.cInterpolation[ i ] = 0;
	
	bone_stats stats = { 0 };

	for( int32_t i = 0; i < iNumBones; ++i )
	{
		NSString* strBoneName = [NSString stringWithCString:pBone[ i ].bone_name encoding:NSShiftJISStringEncoding];
#ifdef DUMP_BONES
		NSLog( @"Bone %d: %@ parent:%d (%f, %f, %f)", i, strBoneName,
			  pBone[ i ].parent_bone_index,
			  pBone[ i ].bone_head_pos[0],
			  pBone[ i ].bone_head_pos[1],
			  pBone[ i ].bone_head_pos[2]
			  );
#endif
		if( strBoneName )
		{
			[_dicBones setObject:[NSNumber numberWithInteger:i] forKey:strBoneName];
			stats.iJointType = JOINT_TYPE_NORMAL;
			if( [strBoneName rangeOfString: STR_IK_KNEE].length > 0 )
				stats.iJointType = JOINT_TYPE_KNEE;
			else
				stats.iJointType = JOINT_TYPE_NORMAL;
		}
		
		std::vector<motion_item>* vec = new std::vector<motion_item>();
		vec->push_back( defaultMotion );
		_vecMotions.push_back( vec );
		
		_vecMotionsWork.push_back( stats );
	}

	int32_t iNumFrameData = motion->getNumMotions();
	vmd_motion* vmdMotion = motion->getMotions();
	
	for( int32_t i = 0; i < iNumFrameData; ++i )
	{
		NSString* strBoneName = [NSString stringWithCString:vmdMotion[ i ].BoneName encoding:NSShiftJISStringEncoding];
		if( strBoneName )
		{
			NSNumber* numIndex = [_dicBones objectForKey:strBoneName ];
			if( numIndex != nil )
			{
				//Found bone
				int32_t iIndex = [numIndex intValue]; 
				motion_item m;
				m.iFrame = vmdMotion[ i ].FlameNo;
				m.fPos[ 0 ] = vmdMotion[ i ].Location[ 0 ];
				m.fPos[ 1 ] = vmdMotion[ i ].Location[ 1 ];
				m.fPos[ 2 ] = vmdMotion[ i ].Location[ 2 ];
				m.fRotation[ 0 ] = vmdMotion[ i ].Rotatation[ 0 ];
				m.fRotation[ 1 ] = vmdMotion[ i ].Rotatation[ 1 ];
				m.fRotation[ 2 ] = vmdMotion[ i ].Rotatation[ 2 ];
				m.fRotation[ 3 ] = vmdMotion[ i ].Rotatation[ 3 ];
				for( int32_t j = 0; j < 16; ++j )
					m.cInterpolation[ j ] = vmdMotion[ i ].Interpolation[ j ];
				
				_vecMotions[ iIndex ]->push_back( m );
				_uiMaxFrame = std::max( _uiMaxFrame, vmdMotion[ i ].FlameNo );
			}
			else
			{
				NSLog( @"Bone not found %@", strBoneName );
			}
		}
	}

	//
	//Sort them all!!
	//
	for( int32_t i = 0; i < iNumBones; ++i )
	{
		if( _vecMotions[ i ]->size() == 1 )
		{
			//Need at least 2 entries
			_vecMotions[ i ]->push_back( defaultMotion );
		}
		
		std::sort(_vecMotions[ i ]->begin(), _vecMotions[ i ]->end(), dataSortPredicate);
	}
	
#if 0
	int32_t iBone = 91;
	for( int32_t i = 0; i < _vecMotions[ iBone ]->size(); ++i )
		NSLog( @"Motion %d, (%f,%f,%f), (%f,%f,%f,%f)", _vecMotions[ iBone ]->at( i ).iFrame,
			  _vecMotions[ iBone ]->at( i ).fPos[0],
			  _vecMotions[ iBone ]->at( i ).fPos[1],
			  _vecMotions[ iBone ]->at( i ).fPos[2],
			  _vecMotions[ iBone ]->at( i ).fRotation[ 0 ],
			  _vecMotions[ iBone ]->at( i ).fRotation[ 1 ],
			  _vecMotions[ iBone ]->at( i ).fRotation[ 2 ],
			  _vecMotions[ iBone ]->at( i ).fRotation[ 3 ]
			  );

#endif
#if 0
	//verify
	for( int32_t i = 0; i < iNumBones; ++i )
	{
		NSLog( @"Size: %d %d", i, _vecMotions[ i ]->size() );
	}
#endif

	NSLog( @"Max frame: %d", _uiMaxFrame );
	
	[_dicBones release];
	_dicBones = nil;

	//Keep reference
	_fCurrentFrame = -1.f;
	for( int32_t i = 0; i < reader->getNumBones(); ++i )
	{
		_vecBones.push_back( reader->getBones()[ i ] );
	}


	int32_t iNumIKs = reader->getNumIKs();
	mmd_ik* pIK = reader->getIKs();
	for( int32_t i = 0; i < iNumIKs; ++i )
	{
		ik_item ik = {0};
		ik.ik_bone_index = pIK->ik_bone_index;
		ik.ik_target_bone_index = pIK->ik_target_bone_index;
		ik.ik_chain_length = pIK->ik_chain_length;
		ik.iterations = pIK->iterations;
		ik.control_weight = pIK->control_weight;

		for( int32_t j = 0; j < pIK->ik_chain_length; ++j )
			ik._vec_ik_child_bone_index.push_back( pIK->ik_child_bone_index[ j ] );
		
		_vecIKs.push_back( ik );

		int32_t iChains = pIK->ik_chain_length;
		pIK = (mmd_ik*)((uint8_t*)pIK + sizeof( mmd_ik ) + iChains * sizeof( uint16_t ));		
	}

	//
	//bind skin
	//
	bindSkinAnimation(reader, motion);
	
	return true;
}

bool vmdMotionProvider::unbind()
{
	unbindSkinAnimation();
	_vecMotions.clear();
	_vecMotionsWork.clear();
	_vecBones.clear();
	_vecIKs.clear();
	_fCurrentFrame = -1.f;
	
	return true;
}


