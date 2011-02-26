//
//  vmdMotionProvider.mm
//  MikuMikuPhone
//
//  Created by hakuroum on 1/19/11.
//  Copyright 2011 hakuroum@gmail.com. All rights reserved.
//
#include <algorithm>
#import "vmdMotionProvider.h"

//
//Derived from MikuMikuDroid
//http://en.sourceforge.jp/projects/mikumikudroid/
//
void vmdMotionProvider::resolveIK()
{
	int32_t iNumIKs = _vecIKs.size();
	
	for( int32_t i = 0; i < iNumIKs; ++i )
	{
		ccdIK( &_vecIKs[ i ] );

		int32_t iSize = _vecBones.size();
		for( int32_t i = 0; i < iSize; ++i )
			_vecMotionsWork[ i ].bUpdated = false;
	}
	
}

void vmdMotionProvider::makeQuaternion(float* quat, float angle, PVRTVec3 axis )
{
	float s = sinf(angle / 2);
	
	quat[0] = s * axis.x;
	quat[1] = s * axis.y;
	quat[2] = s * axis.z;
	quat[3] = cosf( angle / 2 );
}

void vmdMotionProvider::getCurrentPosition( PVRTVec3& vec, int32_t iIndex)
{
	updateBoneMatrix(iIndex);
	mmd_bone& b = _vecBones[ iIndex ];

	PVRTMat4 mat;
	PVRTMatrixTranslationF( mat,
						   -b.bone_head_pos[ 0 ],
						   -b.bone_head_pos[ 1 ],
						   -b.bone_head_pos[ 2 ] );
	
	mat = _vecMotionsWork[ iIndex ].mat * mat;

	vec = mat * PVRTVec4( b.bone_head_pos[ 0 ],
						 b.bone_head_pos[ 1 ],
						 b.bone_head_pos[ 2 ],
						 1.0f );
}

void vmdMotionProvider::clearUpdateFlags( int32_t iCurrentBone, int32_t iTargetBone )
{
	while( iCurrentBone != iTargetBone )
	{
		_vecMotionsWork[ iTargetBone ].bUpdated = false;
		if( _vecBones[ iTargetBone ].parent_bone_index != 0xffff )
		{
			iTargetBone = _vecBones[ iTargetBone ].parent_bone_index;
		}
		else
		{
			return;
		}
	}
	_vecMotionsWork[ iCurrentBone ].bUpdated = false;
}

void vmdMotionProvider::ccdIK( ik_item* pIK)
{
	int32_t iBoneTarget = pIK->ik_target_bone_index;
	
	PVRTVec3 vecEffector;
	getCurrentPosition( vecEffector, pIK->ik_bone_index );

	for( int32_t i = 0; i < pIK->iterations; ++i )
	{
		for( int32_t j = 0; j < pIK->ik_chain_length; ++j )
		{
			int32_t iCurrentBone = pIK->_vec_ik_child_bone_index[ j ];
			
			clearUpdateFlags( iCurrentBone, iBoneTarget );

			PVRTVec3 vecTarget;
			getCurrentPosition( vecTarget, iBoneTarget );
			
			switch( _vecMotionsWork[ iCurrentBone ].iJointType )
			{
				case JOINT_TYPE_KNEE:
					if( i == 0 )
					{
						PVRTVec3 vecTargetInvs;
						PVRTVec3 vecEffectorInvs;
						getCurrentPosition( vecTargetInvs, iCurrentBone );
						getCurrentPosition( vecEffectorInvs, pIK->_vec_ik_child_bone_index[ pIK->ik_chain_length - 1 ] );
						
						float eff_len = ( vecEffector - vecEffectorInvs ).length();
						float b_len = ( vecTargetInvs - vecEffectorInvs ).length();
						float t_len = ( vecTarget - vecTargetInvs ).length();
						
						float angle = acosf((eff_len * eff_len - b_len * b_len - t_len * t_len) / (2 * b_len * t_len));
						if ( !isnan( angle ) )
						{
							float fQuat[ 4 ];
							PVRTVec3 vecAxis( -1, 0, 0 );
							
							makeQuaternion( fQuat, angle, vecAxis );
							quaternionMul( _vecMotionsWork[ iCurrentBone ].fQuaternion,
										  _vecMotionsWork[ iCurrentBone ].fQuaternion, 
										  fQuat );
							quaternionToMatrixPreserveTranslate( _vecMotionsWork[ iCurrentBone ].matCurrent.f,
																_vecMotionsWork[ iCurrentBone ].fQuaternion );
						}
					}
					break;
				default:
					if( ( vecEffector - vecTarget ).length() < 0.001f )
						return;
					
					updateBoneMatrix( iCurrentBone );
					PVRTMat4 matCurrent = _vecMotionsWork[ iCurrentBone ].mat;
					PVRTMatrixInverse( matCurrent, matCurrent );
					
					PVRTVec3 vecInvEffector = matCurrent * PVRTVec4( vecEffector, 1.f );
					PVRTVec3 vecInvTarget = matCurrent * PVRTVec4( vecTarget, 1.f );
					
					vecInvEffector.normalize();
					vecInvTarget.normalize();
					
					float fAngle = acosf( vecInvEffector.dot( vecInvTarget ) );
					fAngle *= pIK->control_weight;
					
					if( !isnan( fAngle ) )
					{
						PVRTVec3 vecAxis = vecInvTarget.cross( vecInvEffector );
						vecAxis.normalize();
						
						if( !isnan( vecAxis.x )
						   && !isnan( vecAxis.y )
						   && !isnan( vecAxis.z ) )
						{
							float fQuat[ 4 ];
							
							makeQuaternion( fQuat, fAngle, vecAxis );
							quaternionMul( _vecMotionsWork[ iCurrentBone ].fQuaternion,
										  _vecMotionsWork[ iCurrentBone ].fQuaternion,
										  fQuat );
							quaternionToMatrixPreserveTranslate( _vecMotionsWork[ iCurrentBone ].matCurrent.f,
																_vecMotionsWork[ iCurrentBone ].fQuaternion );
						}
					}
			}
		}
	}
}

