//
//  pmdRenderer.mm
//  MikuMikuPhone
//
//  Created by hakuroum on 1/14/11.
//  Copyright 2011 hakuroum@gmail.com. All rights reserved.
//

#import "pmdRenderer.h"


#define BUFFER_OFFSET(i) ((char *)NULL + (i))

//#define DUMP_PARTITIONS (1)

enum {
	ATTRIB_VERTEX,
	ATTRIB_NORMAL,
	ATTRIB_UV,
	ATTRIB_BONE,
};

#pragma mark Ctor
pmdRenderer::pmdRenderer()
{
}
#pragma mark Dtor
pmdRenderer::~pmdRenderer()
{
	if (_vboRender)
		glDeleteBuffers(1, &_vboRender);
	if (_vboIndex)
		glDeleteBuffers(1, &_vboIndex);
	
	for( int32_t i = 0; i < sizeof( _shaders ) / sizeof( _shaders[ 0 ] ); ++i)
	{
		if (_shaders[ i ]._program)
			glDeleteProgram(_shaders[ i ]._program);
	}
	
	delete _motionProvider;
	_vecDrawList.clear();
}

#pragma mark Update
void pmdRenderer::update( const double dTime )
{
	if( _motionProvider )
	{
		_motionProvider->update( dTime );
	}
}

#pragma mark Render
void pmdRenderer::render()
{
    // Bind the VBO
    glBindBuffer(GL_ARRAY_BUFFER, _vboRender);
	
    int32_t iStride = sizeof(renderer_vertex);
    // Pass the vertex data
    glVertexAttribPointer(ATTRIB_VERTEX, 3, GL_FLOAT, GL_FALSE, iStride, BUFFER_OFFSET( 0 ));
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    
    glVertexAttribPointer(ATTRIB_NORMAL, 3, GL_FLOAT, GL_FALSE, iStride, BUFFER_OFFSET( 3 * sizeof(GLfloat) ));
    glEnableVertexAttribArray(ATTRIB_NORMAL);
    
    glVertexAttribPointer(ATTRIB_BONE, 4, GL_UNSIGNED_BYTE, GL_FALSE, iStride, BUFFER_OFFSET( 8 * sizeof(GLfloat) ));
    glEnableVertexAttribArray(ATTRIB_BONE);

	// Bind the IB
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _vboIndex);
	    
	//State
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_CULL_FACE);
	glCullFace(GL_CCW);
    
    // Feed Projection and Model View matrices to the shaders
    PVRTMat4 mVP = _mProjection * _mView;
	
	//int32_t iMaterials = _reader->getNumMaterials();
	mmd_material* pMaterial = _reader->getMaterials();
	int32_t iOffset = 0;
	
	GLuint lastProgram = -1;
	GLuint currentProgram = -1;
	
	std::vector<bone_stats>* matrixPalette = NULL;
	if( _motionProvider )
	{
		matrixPalette = _motionProvider->getMatrixPalette();
	}
	
	std::vector< DRAW_LIST >::iterator itBegin = _vecDrawList.begin();
	std::vector< DRAW_LIST >::iterator itEnd = _vecDrawList.end();
	for( ;itBegin != itEnd; ++itBegin )		
	{
		int32_t iNumIndices = itBegin->iNumIndices;
		int32_t i = itBegin->iMaterialIndex;
		
		//Set materials
		if( pMaterial[ i ].alpha < 1.0f )
			glEnable(GL_BLEND);
		else
			glDisable(GL_BLEND);
		
		int32_t iShaderIndex = 0;
		
		if( pMaterial[ i ]._tex )
		{
			iShaderIndex = 1;
			glUseProgram(_shaders[iShaderIndex]._program);		
			glEnable(GL_TEXTURE_2D);
			glActiveTexture(GL_TEXTURE0);
			glBindTexture(GL_TEXTURE_2D, pMaterial[ i ]._tex);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
			glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
			glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
			// Pass the texture coordinates data
			glVertexAttribPointer(ATTRIB_UV, 2, GL_FLOAT, GL_FALSE, iStride, BUFFER_OFFSET( (3 * sizeof(GLfloat)) + (3 * sizeof(GLfloat)) ) );
			glEnableVertexAttribArray(ATTRIB_UV);
			currentProgram = _shaders[iShaderIndex]._program;
		}
		else
		{
			iShaderIndex = 0;
			glUseProgram(_shaders[iShaderIndex]._program);		
			glDisable(GL_TEXTURE_2D);
			glDisableVertexAttribArray(ATTRIB_UV);
			currentProgram = _shaders[iShaderIndex]._program;
		}
		
		glUniform4f( _shaders[iShaderIndex]._uiMaterialDiffuse, pMaterial[ i ].diffuse_color[ 0 ],
					pMaterial[ i ].diffuse_color[ 1 ],
					pMaterial[ i ].diffuse_color[ 2 ],
					pMaterial[ i ].alpha );
		glUniform4f( _shaders[iShaderIndex]._uiMaterialSpecular, pMaterial[ i ].specular_color[ 0 ],
					pMaterial[ i ].specular_color[ 1 ],
					pMaterial[ i ].specular_color[ 2 ],
					pMaterial[ i ].intensity );
		
		glUniform3fv( _shaders[iShaderIndex]._uiMaterialAmbient, 1, pMaterial[ i ].ambient_color );
		
		//
		//Set up matrix palette
		//
		if( _motionProvider )
		{
			std::vector< int32_t >& vec = itBegin->vecMatrixPalette;
			for( int32_t iPaletteIndex = 0; iPaletteIndex < BATCH_DIVISION_THRESHOLD; ++iPaletteIndex )
			{
				if( vec[ iPaletteIndex ] != -1 )
				{
					glUniformMatrix4fv( _shaders[iShaderIndex]._uiMatrixPalette + iPaletteIndex * 4, 1, GL_FALSE,
									   (*matrixPalette)[ vec[ iPaletteIndex ] ].mat.ptr());
				}
 
			}
		}
			
		if( currentProgram != lastProgram )
		{
			glUniformMatrix4fv( _shaders[iShaderIndex]._uiMatrixP, 1, GL_FALSE,  mVP.ptr());
			
			glUniform3f( _shaders[iShaderIndex]._uiLight0, 0.f, 10.f, 1.f );
		}
		lastProgram = currentProgram;
		
		glDrawElements(GL_TRIANGLES, iNumIndices,
					   GL_UNSIGNED_SHORT, BUFFER_OFFSET(iOffset * sizeof(uint16_t) ));
		iOffset += iNumIndices;
	}
	
}

#pragma mark Init
bool pmdRenderer::init( pmdReader* reader, vmdReader* motion )
{
	if( reader == NULL )
		return false;
	_reader = reader;
	
	if( motion != NULL )
	{
		_motionProvider = new vmdMotionProvider();
		_motionProvider->bind( reader, motion );
		partitionMeshes( reader );
	}
	else
	{
		createVbo();
		createIndexBuffer();
	}
	
	loadShaders(&_shaders[ 0 ], @"ShaderPlain", @"ShaderPlain" );
#if defined(DEBUG)
    if (!validateProgram(_shaders[ 0 ]._program))
    {
        NSLog(@"Failed to validate program: %d", _shaders[ 0 ]._program);
        return false;
    }
#endif
	
	loadShaders(&_shaders[ 1 ], @"ShaderPlainTex", @"ShaderPlainTex" );
#if defined(DEBUG)
    if (!validateProgram(_shaders[ 1 ]._program))
    {
        NSLog(@"Failed to validate program: %d", _shaders[ 1 ]._program);
        return false;
    }
#endif
	
	//Init matrices
	float fAspect = 320.f/480.f;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		fAspect = 0.75;

    const float CAM_FOV  = M_PI_2/4;
    const float CAM_NEAR = 0.5f;
	const float CAM_Z = 64.f;
	
    bool bRotate = false;
    _mProjection = PVRTMat4::PerspectiveFovFloatDepthRH(CAM_FOV, fAspect, CAM_NEAR, PVRTMat4::OGL, bRotate);
    _mView = PVRTMat4::LookAtRH(PVRTVec3(0.f, 10.f, -CAM_Z), PVRTVec3(0.f,10.f,0.f), PVRTVec3(0.f, 1.f, 0.f));
	
	return true;	
}

void pmdRenderer::createVbo()
{
    int32_t iStride = sizeof( renderer_vertex );
	glGenBuffers(1, &_vboRender);
	
	// Bind the VBO
	glBindBuffer(GL_ARRAY_BUFFER, _vboRender);
	
	int32_t iNum = _reader->getNumVertices();
	mmd_vertex* pVertices = _reader->getVertices();
	std::vector< renderer_vertex > vec;
	renderer_vertex vertex;
	for( int32_t iVertexIndex = 0; iVertexIndex < iNum; ++iVertexIndex )
	{
		vertex.pos[ 0 ] = pVertices[ iVertexIndex ].pos[ 0 ];
		vertex.pos[ 1 ] = pVertices[ iVertexIndex ].pos[ 1 ];
		vertex.pos[ 2 ] = pVertices[ iVertexIndex ].pos[ 2 ];
		vertex.normal_vec[ 0 ] = pVertices[ iVertexIndex ].normal_vec[ 0 ];
		vertex.normal_vec[ 1 ] = pVertices[ iVertexIndex ].normal_vec[ 1 ];
		vertex.normal_vec[ 2 ] = pVertices[ iVertexIndex ].normal_vec[ 2 ];
		vertex.uv[ 0 ] = pVertices[ iVertexIndex ].uv[ 0 ];
		vertex.uv[ 1 ] = pVertices[ iVertexIndex ].uv[ 1 ];
		vertex.bone[ 0 ] = 0;
		vertex.bone[ 1 ] = 0;
		vertex.bone[ 2 ] = 0;
		vertex.bone[ 3 ] = pVertices[ iVertexIndex ].bone_weight;
		vec.push_back( vertex );
	}
	
	// Set the buffer's data
	glBufferData(GL_ARRAY_BUFFER, iStride * vec.size(), &vec[ 0 ], GL_STATIC_DRAW);

	// Unbind the VBO
	glBindBuffer(GL_ARRAY_BUFFER, 0);
    
	return;
}

void pmdRenderer::createIndexBuffer()
{
    int32_t iStride = sizeof( uint16_t );
	glGenBuffers(1, &_vboIndex);
	
	// Bind the VBO
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _vboIndex);
	
	// Set the buffer's data
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, iStride * _reader->getNumIndices(), _reader->getIndices(), GL_STATIC_DRAW);
	
	// Unbind the VBO
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    
	int32_t iMaterials = _reader->getNumMaterials();
	mmd_material* pMaterial = _reader->getMaterials();

	for( int32_t i = 0; i < iMaterials; ++i )
	{
		DRAW_LIST list;
		list.iMaterialIndex = i;
		list.iNumIndices = pMaterial[ i ].face_vert_count;
		_vecDrawList.push_back( list );
	}
	return;
}

#pragma mark partitioning
bool pmdRenderer::partitioning( pmdReader* reader, SkinningEvaluator* eval, int32_t iStart, int32_t iNumIndices )
{
	if( iNumIndices % 3 )
		return false;

	if( reader == NULL || eval == NULL )
	{
		return false;
	}

	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	mmd_vertex* pVertices = reader->getVertices();
	uint16_t* pIndices = reader->getIndices() + iStart;
	
	NSMutableDictionary* meshStats = [[[NSMutableDictionary alloc] init] autorelease];
	for( int32_t i = 0; i < iNumIndices/3; ++i )
	{
		//Triangle stats array
		NSMutableDictionary* triangleStats = [[[NSMutableDictionary alloc] init] autorelease];
		for( int32_t j = 0; j < 3; ++j )
		{
			int32_t iMatrix0 = pVertices[ pIndices[i * 3 + j] ].getBoneIndex( 0 );
			NSNumber* n0 = [NSNumber numberWithInt:iMatrix0];
			[triangleStats setObject:n0 forKey:n0];

			int32_t iMatrix1 = pVertices[ pIndices[i * 3 + j] ].getBoneIndex( 1 );
			if( iMatrix1 != -1 )
			{
				NSNumber* n1 = [NSNumber numberWithInt:iMatrix1];
				[triangleStats setObject:n1 forKey:n1];
			}
		}

		//Sort matrix used in the mesh
		NSArray *keys = [triangleStats allKeys];
		NSArray *sortedKeys = [keys sortedArrayUsingSelector:@selector(compare:)];
		
		int64_t iKey = 0;
		for( NSNumber* n in sortedKeys )
		{
			iKey <<= 8;
			iKey |= [n intValue];
			if( [n intValue] > 255 )
			{
				NSLog( @"Invalid bone #, assuming # bones less than 255" );
			}
		}
		
		NSNumber* numKey = [NSNumber numberWithLongLong:iKey];
		if( [meshStats objectForKey:numKey] == nil )
		{
			[meshStats setObject:[[[NSMutableArray alloc] init] autorelease]
						  forKey:numKey];
		}
		[[meshStats objectForKey:numKey] addObject:[NSNumber numberWithInt:pIndices[i * 3]]];
		[[meshStats objectForKey:numKey] addObject:[NSNumber numberWithInt:pIndices[i * 3 + 1]]];
		[[meshStats objectForKey:numKey] addObject:[NSNumber numberWithInt:pIndices[i * 3 + 2]]];
	}
	
	//
	//meshStats[key][triangle index]
	NSArray *keys = [meshStats allKeys];
	NSMutableArray *sortedMeshStats = [NSMutableArray arrayWithArray:[keys sortedArrayUsingSelector:@selector(compare:)]];
	NSLog( @"Num keys:%d", [sortedMeshStats count] );
//	NSLog( @"keys:%@", [sortedMeshStats description] );
	
	//Start.
	//Add 1st item
	eval->addItem([sortedMeshStats objectAtIndex:0],
				  [meshStats objectForKey:[sortedMeshStats objectAtIndex:0]],
				   0);
	[sortedMeshStats removeObjectAtIndex:0];
	
	while( [sortedMeshStats count] )
	{
		int32_t iLeastScore = INT_MAX;
		int32_t iLeastIndex = INT_MAX;
		int32_t iLeastScoreSlot;
		int32_t iSlot;
		
		int32_t iCount = [sortedMeshStats count];
		for( int32_t iIndex = 0; iIndex < iCount; ++iIndex )
		{
			//Get least score
			int32_t iScore = eval->getScore( [[sortedMeshStats objectAtIndex:iIndex] longLongValue], iSlot);
			if( iScore < iLeastScore )
			{
				iLeastScore = iScore;
				iLeastIndex = iIndex;
				iLeastScoreSlot = iSlot;
			}
		}
		eval->addItem( [sortedMeshStats objectAtIndex:iLeastIndex], [meshStats objectForKey:[sortedMeshStats objectAtIndex:iLeastIndex]], iLeastScoreSlot);
		[sortedMeshStats removeObjectAtIndex:iLeastIndex];
	}
	
	//Done partitioning
	
	[pool drain];
	return true;
}

NSComparisonResult pmdRenderer::compare(NSNumber *first, NSNumber *second, NSDictionary *dic)
{
	int32_t iValueFirst = [[dic objectForKey:first] intValue];
	int32_t iValueSecond = [[dic objectForKey:second] intValue];
	if ( iValueFirst < iValueSecond)
		return NSOrderedDescending;
	else 	if ( iValueFirst > iValueSecond)
		return NSOrderedAscending;
	else 
		return NSOrderedSame;
}

bool pmdRenderer::createMatrixMapping( NSArray* sortedKeys, NSDictionary* dicMatrixRefArray )
{
	for( int32_t i = 0; i < _vecDrawList.size(); ++i )
	{
		_vecDrawList[ i ].vecMatrixPalette.clear();
		_vecDrawList[ i ].vecMatrixPalette.reserve( BATCH_DIVISION_THRESHOLD );
		for( int32_t iIndex = 0; iIndex < BATCH_DIVISION_THRESHOLD; ++iIndex )
			_vecDrawList[ i ].vecMatrixPalette.push_back( MATRIX_UNDEFINED );
	}
	
//	NSLog( @"sortedKeys:%@", [sortedKeys description] );

	//Sorted decending order
	for( NSNumber* num in sortedKeys )
	{
		//Create matrix map
		NSArray* batches = [dicMatrixRefArray objectForKey:num];
				
		int32_t iLeastScore = BATCH_DIVISION_THRESHOLD + 1;
		int32_t iLeastIndex = BATCH_DIVISION_THRESHOLD + 1;
		for( int32_t iBottom = 0; iBottom < BATCH_DIVISION_THRESHOLD; ++iBottom )
		{
			int32_t iScore = 0;
			for( NSNumber* numBatch in batches )
			{
				if( _vecDrawList[ [numBatch intValue] ].vecMatrixPalette[ iBottom ] != MATRIX_UNDEFINED )
				{
					//Slot is used
					iScore++;
				}
			}
			//Pick least score			
			if( iLeastScore > iScore )
			{
				iLeastScore = iScore;
				iLeastIndex = iBottom;
			}
		}
		
		//Map it!!
		for( NSNumber* numBatch in batches )
		{
			int32_t iIndex = 0;
			for( iIndex = 0; iIndex < BATCH_DIVISION_THRESHOLD; ++iIndex )
			{
				if( _vecDrawList[ [numBatch intValue] ].vecMatrixPalette[ (iIndex + iLeastIndex ) % BATCH_DIVISION_THRESHOLD ] == MATRIX_UNDEFINED )
				{
					_vecDrawList[ [numBatch intValue] ].vecMatrixPalette[ (iIndex + iLeastIndex ) % BATCH_DIVISION_THRESHOLD ] = [num intValue];
					break;
				}
			}
			
			if( iIndex == BATCH_DIVISION_THRESHOLD )
			{
				NSLog( @"No slot available" );
			}
		}
	}
	
#ifdef DUMP_PARTITIONS
	//Dump out..
	for( int32_t i = 0; i < _vecDrawList.size(); ++i )
	{
		NSLog( @"----%d----\n", i );
		for( int32_t iIndex = 0; iIndex < BATCH_DIVISION_THRESHOLD; ++iIndex )
			NSLog( @"%2x", _vecDrawList[ i ].vecMatrixPalette[ iIndex ] );
		NSLog( @"\n" );
	}
#endif
	
	return true;
}

int32_t pmdRenderer::getMappedVertices( mmd_vertex* pVertices, const int32_t iVertexIndex, const uint32_t iVertexKey )
{
	
	std::map< int32_t, int32_t >::iterator it = _mapVertexMapping[ iVertexIndex ].find( iVertexKey );
	if( it != _mapVertexMapping[ iVertexIndex ].end() )
	{
		return it->second;
	}
	
	int32_t iNewIndex = _vecMappedVertex.size();
	_mapVertexMapping[ iVertexIndex ][ iVertexKey ] = iNewIndex;
	
	renderer_vertex vertex;
	vertex.pos[ 0 ] = pVertices[ iVertexIndex ].pos[ 0 ];
	vertex.pos[ 1 ] = pVertices[ iVertexIndex ].pos[ 1 ];
	vertex.pos[ 2 ] = pVertices[ iVertexIndex ].pos[ 2 ];
	vertex.normal_vec[ 0 ] = pVertices[ iVertexIndex ].normal_vec[ 0 ];
	vertex.normal_vec[ 1 ] = pVertices[ iVertexIndex ].normal_vec[ 1 ];
	vertex.normal_vec[ 2 ] = pVertices[ iVertexIndex ].normal_vec[ 2 ];
	vertex.uv[ 0 ] = pVertices[ iVertexIndex ].uv[ 0 ];
	vertex.uv[ 1 ] = pVertices[ iVertexIndex ].uv[ 1 ];
	vertex.bone[ 0 ] = uint8_t(iVertexKey >> 16);
	vertex.bone[ 1 ] = uint8_t(iVertexKey & 0xffff);
	vertex.bone[ 2 ] = 0;
	vertex.bone[ 3 ] = uint8_t( float(pVertices[ iVertexIndex ].bone_weight) / 100.f * 255.f);
	_vecMappedVertex.push_back( vertex );
	
	//NSLog( @"vertex %d, weight %d bone0 %d, bone1 %d", iNewIndex, vertex.bone[ 3 ], vertex.bone[ 0 ], vertex.bone[ 1 ] );
	return iNewIndex;
}

int16_t pmdRenderer::getMappedBone( std::vector< int32_t >*pVec, const int32_t iBone )
{
	int32_t iCount = pVec->size();
	int32_t iIndex = -1;
	for( int32_t i = 0; i < iCount; ++i )
	{
		if( pVec->at( i ) == iBone )
		{
			iIndex = i;
			break;
		}
	}

	if( iIndex == -1 )
		NSLog( @"Bone Index not found! %d" );

	return iIndex;
}

//
//Check bones used in each material
//
bool pmdRenderer::partitionMeshes( pmdReader* reader )
{
	SGXSkinningEvaluator* eval = new SGXSkinningEvaluator();
	int32_t iMaterials = reader->getNumMaterials();
	mmd_material* pMaterial = reader->getMaterials();
	int32_t iOffset = 0;
	
	mmd_vertex* pVertices = reader->getVertices();
	uint16_t* pIndices = reader->getIndices();
	
	int32_t iNumMatrix = eval->getNumBoneMatrixPalette();
	int32_t MAX_BONES = 255;
	if( iNumMatrix > MAX_BONES )
	{
		return false;
	}
	
	NSMutableDictionary* dicMatrixRefCount = [[NSMutableDictionary alloc] init];
	NSMutableDictionary* dicMatrixRefArray = [[NSMutableDictionary alloc] init];

	std::vector< int16_t > vecIndices;
	int32_t iBatchIndex = 0;
	
	for( int32_t i = 0; i < iMaterials; ++i )
	{
		NSMutableDictionary* dic = [[NSMutableDictionary alloc] init];
		int32_t iNumIndices = pMaterial[ i ].face_vert_count;
		
		bool bPartitioned = false;

		for( int32_t j = 0; j < iNumIndices; ++j )
		{
			int32_t iIndex = pIndices[ iOffset + j ];
			int32_t iBone0 = pVertices[ iIndex ].getBoneIndex( 0 );
			NSNumber* num0 = [NSNumber numberWithInt:iBone0];
			[dic setObject:num0 forKey:num0];
			
			int32_t iBone1 = pVertices[ iIndex ].getBoneIndex( 1 );
			if( iBone1 != -1 )
			{
				NSNumber* num1 = [NSNumber numberWithInt:iBone1];
				[dic setObject:num1 forKey:num1];
			}
			
			if( [dic count] > iNumMatrix )
			{
				bPartitioned = true;
				//Need to partition mesh
				NSLog( @"Partitioning..." );
				partitioning( reader, eval, iOffset, iNumIndices );
				break;
			}
			
		}
		
		//Create index list 
		if( bPartitioned )
		{
//			NSLog( @"Partitioning..." );
//			partitioning( reader, eval, iOffset, iNumIndices );

			NSArray* arrayPartitions = eval->getResult();

			for( NSArray* indices in arrayPartitions )
			{
				NSNumber* numBatch = [NSNumber numberWithInt:iBatchIndex];
				
				for( NSNumber* index in indices )
				{
					int16_t iIndex = [index shortValue];
					vecIndices.push_back( iIndex );
					
					//Count matrix usage for matrix palette index mapping
					for( int32_t iBoneIndex = 0; iBoneIndex < 2; ++iBoneIndex )
					{
						int32_t iBone = pVertices[ iIndex ].getBoneIndex( iBoneIndex );
						NSNumber* num = [NSNumber numberWithInt:iBone];
						
						NSNumber* numCount = [dicMatrixRefCount objectForKey:num];
						if( numCount == nil )
							[dicMatrixRefCount setObject:[NSNumber numberWithInt:1]  forKey:num];
						else
							[dicMatrixRefCount setObject:[NSNumber numberWithInt:[numCount intValue] + 1]  forKey:num];
						
						NSMutableDictionary* dicMatrix = [dicMatrixRefArray objectForKey:num];
						if( dicMatrix == nil )
							dicMatrix = [[[NSMutableDictionary alloc] init] autorelease];
						
						[dicMatrix setObject:numBatch forKey:numBatch]; 
						[dicMatrixRefArray setObject:dicMatrix forKey:num];

						if( pVertices[ iIndex ].getBoneIndex( iBoneIndex + 1 ) == -1 )
							break;
					}

				}

				DRAW_LIST list;
				list.iMaterialIndex = i;
				list.iNumIndices = [indices count];
				_vecDrawList.push_back( list );
				
				iBatchIndex++;
			}
			
			eval->clearResult();
		}
		else
		{
			NSNumber* numBatch = [NSNumber numberWithInt:iBatchIndex];

			//Push indices to index list
			for( int32_t j = 0; j < iNumIndices; ++j )
			{
				int32_t iIndex = pIndices[ iOffset + j ];
				vecIndices.push_back( iIndex );

				//Count matrix usage for matrix palette index mapping
				for( int32_t iBoneIndex = 0; iBoneIndex < 2; ++iBoneIndex )
				{
					int32_t iBone = pVertices[ iIndex ].getBoneIndex( iBoneIndex );
					NSNumber* num = [NSNumber numberWithInt:iBone];
					
					NSNumber* numCount = [dicMatrixRefCount objectForKey:num];
					if( numCount == nil )
						[dicMatrixRefCount setObject:[NSNumber numberWithInt:1]  forKey:num];
					else
						[dicMatrixRefCount setObject:[NSNumber numberWithInt:[numCount intValue] + 1]  forKey:num];
					
					NSMutableDictionary* dicMatrix = [dicMatrixRefArray objectForKey:num];
					if( dicMatrix == nil )
						dicMatrix = [[[NSMutableDictionary alloc] init] autorelease];
					
					[dicMatrix setObject:numBatch forKey:numBatch]; 
					[dicMatrixRefArray setObject:dicMatrix forKey:num];
					
					if( pVertices[ iIndex ].getBoneIndex( iBoneIndex + 1 ) == -1 )
						break;
				}
			}
			
			DRAW_LIST list;
			list.iMaterialIndex = i;
			list.iNumIndices = iNumIndices;
			_vecDrawList.push_back( list );

			iBatchIndex++;
		}
		
#ifdef DUMP_PARTITIONS
		NSLog( @"Bones in material %d: %d, %@", i, [dic count], [dic description]);
#endif
		[dic release];
		
		iOffset += iNumIndices;
	}
	
	//NSLog( @"matrix dic:%@", [dicMatrixRefArray description] );
	
	//
	//Now we have index list
	//
	
	//dicMatrixRefCount
	//bone0 - nsnumber: # reference count
	//bone1 - nsnumber: # reference count.
	
	//dicMatrixRefArray
	//bone0 - dic { batch using the bone }
	//bone1 - dic { batch using the bone }
	
	//Sort bones by ref count
	NSArray *keys = [dicMatrixRefCount allKeys];
	NSArray *sortedKeys = [keys sortedArrayUsingFunction:(NSInteger (*)(id, id, void *))compare context:dicMatrixRefCount];
	//NSLog( @"%@", [sortedKeys description] );
	//NSLog( @"%@", [dicMatrixRefCount description] );
	
	createMatrixMapping( sortedKeys, dicMatrixRefArray );
	
	//Go through index buffer & duplicate vertex if necessary
	int32_t iIndex = 0;

	_vecMappedVertex.clear();
	_mapVertexMapping.clear();
	
	std::vector< DRAW_LIST >::iterator itBegin = _vecDrawList.begin();
	std::vector< DRAW_LIST >::iterator itEnd = _vecDrawList.end();
	std::vector< uint16_t > vecMappedIndices;
	for( ;itBegin != itEnd; ++itBegin )		
	{
		int32_t iNumIndices = itBegin->iNumIndices;
		NSLog( @"Batch material:%d # indices:%d", itBegin->iMaterialIndex, iNumIndices );
		std::vector< int32_t >* pVec = &itBegin->vecMatrixPalette;
		for( int32_t i = 0; i < iNumIndices; ++i )
		{
			int32_t iCurrentIndex = vecIndices[ iIndex ];
			int16_t iBone0 = pVertices[ iCurrentIndex ].getBoneIndex( 0 );
			int16_t iMappedBone0 = getMappedBone( pVec, iBone0 ); 
			
			int16_t iBone1 = pVertices[ iCurrentIndex ].getBoneIndex( 1 );
			int16_t iMappedBone1 = -1;
			if( iBone1 != -1 )
			{
				iMappedBone1 = getMappedBone( pVec, iBone1 ); 
				uint32_t iKey = iMappedBone0 << 16 | iMappedBone1;
				int32_t iMappedIndex = getMappedVertices( pVertices, iCurrentIndex, iKey );
				vecMappedIndices.push_back( iMappedIndex );
			}
			else
			{
				uint32_t iKey = iMappedBone0 << 16;
				int32_t iMappedIndex = getMappedVertices( pVertices, iCurrentIndex, iKey );
				vecMappedIndices.push_back( iMappedIndex );
			}
			
			iIndex++;
			
		}
	}
		
	
	//Create Index buffer
	glGenBuffers(1, &_vboIndex);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _vboIndex);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, vecMappedIndices.size() * sizeof( uint16_t ), &vecMappedIndices[ 0 ], GL_STATIC_DRAW);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
	
	//Create VBO
    int32_t iStride = sizeof( renderer_vertex );
	glGenBuffers(1, &_vboRender);
	glBindBuffer(GL_ARRAY_BUFFER, _vboRender);
	glBufferData(GL_ARRAY_BUFFER, iStride * _vecMappedVertex.size(), &_vecMappedVertex[ 0 ], GL_STATIC_DRAW);
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	
	NSLog( @"Duplicated vertices:%d", _vecMappedVertex.size() - reader->getNumVertices() );
    	
	_vecMappedVertex.clear();
	_mapVertexMapping.clear();
	[dicMatrixRefCount release];
	[dicMatrixRefArray release];
	delete eval;
	return true;
}

#pragma mark ShaderHelper

BOOL pmdRenderer::compileShader( GLuint *shader, const GLenum type, const NSString *file )
{
    GLint status;
    const GLchar *source;
	
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source)
    {
        NSLog(@"Failed to load vertex shader");
        return FALSE;
    }
	
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
	
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
	
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0)
    {
        glDeleteShader(*shader);
        return FALSE;
    }
	
    return TRUE;
}

BOOL pmdRenderer::linkProgram( const GLuint prog )
{
    GLint status;
	
    glLinkProgram(prog);
	
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
	
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0)
        return FALSE;
	
    return TRUE;
}

BOOL pmdRenderer::validateProgram(const GLuint prog )
{
    GLint logLength, status;
	
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
	
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0)
        return FALSE;
	
    return TRUE;
}

BOOL pmdRenderer::loadShaders( SHADER_PARAMS* params, NSString* strVsh, NSString* strFsh )
{
	GLuint program;
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
	
    // Create shader program
    program = glCreateProgram();
	
    // Create and compile vertex shader
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:strVsh ofType:@"vsh"];
    if (!compileShader( &vertShader, GL_VERTEX_SHADER, vertShaderPathname ))
    {
        NSLog(@"Failed to compile vertex shader");
        return FALSE;
    }
	
    // Create and compile fragment shader
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:strFsh ofType:@"fsh"];
    if (!compileShader( &fragShader, GL_FRAGMENT_SHADER, fragShaderPathname ))
    {
        NSLog(@"Failed to compile fragment shader");
        return FALSE;
    }
	
    // Attach vertex shader to program
    glAttachShader(program, vertShader);

    // Attach fragment shader to program
    glAttachShader(program, fragShader);
	
    // Bind attribute locations
    // this needs to be done prior to linking
    glBindAttribLocation(program, ATTRIB_VERTEX, "myVertex");
    glBindAttribLocation(program, ATTRIB_NORMAL, "myNormal");
    glBindAttribLocation(program, ATTRIB_UV, "myUV");
    glBindAttribLocation(program, ATTRIB_BONE, "myBone");

	    // Link program
    if( !linkProgram(program) )
    {
        NSLog(@"Failed to link program: %d", program);
		
        if (vertShader)
        {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader)
        {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (program)
        {
            glDeleteProgram(program);
            params->_program = 0;
        }
        
        return FALSE;
    }
	
    // Get uniform locations
	params->_uiMatrixPalette = glGetUniformLocation(program, "uMatrixPalette");
	params->_uiMatrixP = glGetUniformLocation(program, "uPMatrix");
	
	params->_uiLight0 = glGetUniformLocation(program, "vLight0");
	params->_uiMaterialDiffuse = glGetUniformLocation(program, "vMaterialDiffuse");
	params->_uiMaterialAmbient = glGetUniformLocation(program, "vMaterialAmbient");
	params->_uiMaterialSpecular = glGetUniformLocation(program, "vMaterialSpecular");

	// Set the sampler2D uniforms to corresponding texture units
	glUniform1i(glGetUniformLocation(program, "sTexture"), 0);
  
	// Release vertex and fragment shaders
    if (vertShader)
        glDeleteShader(vertShader);
	if (fragShader)
		glDeleteShader(fragShader);

	params->_program = program;
	return TRUE;
}


