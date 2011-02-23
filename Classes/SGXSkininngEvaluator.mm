//
//  SGXSkininngEvaluator.mm
//  MikuMikuPhone
//
//  Created by hakuroum on 1/21/11.
//  Copyright 2011 hakuroum@gmail.com. All rights reserved.
//

#import "SGXSkininngEvaluator.h"

const int32_t MAX_PALETTE_ENTRY = BATCH_DIVISION_THRESHOLD;
const int32_t NO_PALETTE_SPACE = 7;
#pragma mark Ctor
SGXSkinningEvaluator::SGXSkinningEvaluator()
{
	_arraySlot = [[NSMutableArray alloc] init];
	_arraySlotStatus = [[NSMutableArray alloc] init];

}

#pragma mark Dtor
SGXSkinningEvaluator::~SGXSkinningEvaluator()
{
	//NSLog( @"# Slots:%d", [_arraySlotStatus count] );
	[_arraySlot release];
	[_arraySlotStatus release];
}

int32_t SGXSkinningEvaluator::addItem( NSNumber* nKey, NSArray* arrayIndices, int32_t iSlot )
{
	if( [_arraySlot count] <= iSlot )
	{
		[_arraySlot addObject:[[[NSMutableArray alloc] init] autorelease]];
		[_arraySlotStatus addObject:[[[NSMutableDictionary alloc] init] autorelease]];
	}

	NSMutableDictionary* dic = [_arraySlotStatus objectAtIndex:iSlot];
	
	//Update key
	uint64_t uiKey = [nKey longLongValue];
	while( 1 )
	{
		uint32_t iIndex = uiKey & 0xff;
		if( iIndex == 0 )
			break;
		[dic setObject:nKey forKey:[NSNumber numberWithInt:iIndex]];
		uiKey >>= 8; 
	}

	[[_arraySlot objectAtIndex:iSlot] addObjectsFromArray:arrayIndices];
	
	if( [[_arraySlotStatus objectAtIndex:iSlot] count] > MAX_PALETTE_ENTRY )
	{
		NSLog( @"Matrix entry over flow %d",[[_arraySlotStatus objectAtIndex:iSlot] count] );
	}
//	NSLog( @"Matrix entries %@",[_arraySlotStatus description]);
	
	return 0;
}

int32_t SGXSkinningEvaluator::getScore( int64_t iKey, int32_t& iSlot )
{
	int32_t iLeastScore = INT_MAX;
	int32_t iLeastScoreSlot = INT_MAX;

	int32_t iCurrentSlot = 0;
	for( NSMutableDictionary* dic in _arraySlotStatus )
	{
		int64_t iKeyTmp = iKey;
		int32_t iRequiredNewEntry = 0;
		while( 1 )
		{
			int32_t iIndex = iKeyTmp & 0xff;
			if( iIndex == 0 )
				break;
			iKeyTmp >>= 8; 
			
			if( [dic objectForKey:[NSNumber numberWithInt:iIndex]] == nil )
			{
				iRequiredNewEntry++;
			}
		}
		if( iRequiredNewEntry + [dic count] > MAX_PALETTE_ENTRY )
		{
			iRequiredNewEntry = NO_PALETTE_SPACE;
		}
		
		if( iRequiredNewEntry < iLeastScore )
		{
			iLeastScore = iRequiredNewEntry;
			iLeastScoreSlot = iCurrentSlot;
		}
		
		//Fast pass
		if( iLeastScore == 0 )
			break;
		iCurrentSlot++;
	}
	
	if( iLeastScore == NO_PALETTE_SPACE )
	{
		//New slot
		iLeastScoreSlot = [_arraySlotStatus count];
	}
	iSlot = iLeastScoreSlot;
	return iLeastScore;
}

NSArray* SGXSkinningEvaluator::getResult()
{
	return _arraySlot;
}

void SGXSkinningEvaluator::clearResult()
{
	NSLog( @"# Slots:%d", [_arraySlotStatus count] );
	[_arraySlot removeAllObjects];
	[_arraySlotStatus removeAllObjects];
}
