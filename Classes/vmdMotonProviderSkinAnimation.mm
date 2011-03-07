//
//  vmdMotionProvider.mm
//  MikuMikuPhone
//
//  Created by hakuroum on 1/19/11.
//  Copyright 2011 hakuroum@gmail.com. All rights reserved.
//
#include <algorithm>
#import "vmdMotionProvider.h"

int32_t vmdMotionProvider::getSkinAnimationParameters( float& fWeight )
{
	fWeight = _fSkinAnimationWeight;
	return _iCurrentSkinAnimationDataIndex;
}

void vmdMotionProvider::updateSkinAnimation()
{
	//
	//1. get current motion
	//
	skin_item* pCurrentItem = &_vecSkinAnimations[_iCurrentSkinAnimationIndex];
	skin_item* pNextItem = &_vecSkinAnimations[_iCurrentSkinAnimationIndex + 1];
	
	//Next index?
	while( pNextItem->iFrame <= _fCurrentFrame )
	{
		if( _iCurrentSkinAnimationIndex < _vecSkinAnimations.size() -2 )
		{
			_iCurrentSkinAnimationIndex++;
			pCurrentItem = pNextItem;
			pNextItem = &_vecSkinAnimations[_iCurrentSkinAnimationIndex + 1];
		}
		else
		{
			//Runnning out of motion.
			pCurrentItem = pNextItem;
			pNextItem = NULL;
			
			_fSkinAnimationWeight = 1.f;
			_iCurrentSkinAnimationDataIndex = pCurrentItem->iIndex;
			return;
		}
	}
	
	int32_t iDiff = pNextItem->iFrame - pCurrentItem->iFrame;
	float a0 = _fCurrentFrame - pCurrentItem->iFrame;
	_fSkinAnimationWeight = a0 / iDiff;
	_iCurrentSkinAnimationDataIndex = pCurrentItem->iIndex;
}	

void vmdMotionProvider::bindSkinAnimation( pmdReader* reader, vmdReader* motion )
{
	int32_t iNumSkins = reader->getNumSkinAnimations();
	mmd_skin* pSkin = reader->getSkinAnimations();
	NSMutableDictionary* dicSkinName = [[NSMutableDictionary alloc] init];
		
	for( int32_t i = 0; i < iNumSkins; ++i )
	{
		NSString* strSkinName = [NSString stringWithCString:pSkin->skin_name encoding:NSShiftJISStringEncoding];
		
		if( strSkinName )
		{
			[dicSkinName setObject:[NSNumber numberWithInteger:i] forKey:strSkinName];
			NSLog( @"Skin: %@", strSkinName );
		}
		pSkin = (mmd_skin*)(((uint8_t*)pSkin) + sizeof( mmd_skin ) + pSkin->skin_vert_count * sizeof( mmd_skin_vertex ));
	}

	int32_t iNumAnimations = motion->getNumSkins();
	vmd_skin* pAnimation = motion->getSkins();

	_vecSkinAnimations.clear();
	for( int32_t i = 0; i < iNumAnimations; ++i )
	{
		NSString* strSkinName = [NSString stringWithCString:pAnimation[ i ].SkinName encoding:NSShiftJISStringEncoding];
		
		NSNumber* num = [dicSkinName objectForKey:strSkinName];
		if( num != nil )
		{
			skin_item item;
			item.iIndex = [num intValue];
			item.Weight = pAnimation[ i ].Weight;
			item.iFrame = pAnimation[ i ].FlameNo;
			
			_vecSkinAnimations.push_back( item );
		}
	}
	
	_iCurrentSkinAnimationIndex = 0;
	[dicSkinName release];
}

void vmdMotionProvider::unbindSkinAnimation()
{
	_vecSkinAnimations.clear();
}