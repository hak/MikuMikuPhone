//
//  SGXSkininngEvaluator.h
//  MikuMikuPhone
//
//  Created by hakuroum on 1/21/11.
//  Copyright 2011 hakuroum@gmail.com. All rights reserved.
//

#import <Foundation/Foundation.h>

const int32_t BATCH_DIVISION_THRESHOLD = 29;

class SkinningEvaluator {
public:
	virtual 	int32_t getNumBoneMatrixPalette() = 0;
	virtual 	int32_t addItem( NSNumber* nKey, NSArray* arrayIndices, int32_t iSlot ) = 0;
	virtual 	int32_t getScore( int64_t iKey, int32_t& iSlot ) = 0;
	virtual		NSArray* getResult() = 0;
	virtual		void clearResult() = 0;
};

class SGXSkinningEvaluator: public SkinningEvaluator {
	NSMutableArray* _arraySlot;
	NSMutableArray* _arraySlotStatus;
public:
	SGXSkinningEvaluator();
	virtual ~SGXSkinningEvaluator();
	
	virtual int32_t getNumBoneMatrixPalette()
	{
		return BATCH_DIVISION_THRESHOLD;
	}
	virtual 	int32_t addItem( NSNumber* nKey, NSArray* arrayIndices, int32_t iSlot );
	virtual 	int32_t getScore( int64_t iKey, int32_t& iSlot );
	virtual		NSArray* getResult();
	virtual		void clearResult();
};
