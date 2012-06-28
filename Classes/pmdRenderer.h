//
//  pmdRenderer.h
//  MikuMikuPhone
//
//  Created by hakuroum on 1/14/11.
//  Copyright 2011 hakuroum@gmail.com. All rights reserved.
//
#import <vector>
#import <map>

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>

#import "pmdReader.h"
#import "vmdReader.h"
#import "vmdMotionProvider.h"
#import "SGXSkininngEvaluator.h"
#import "PVRTVector.h"
#import "Texture2D.h"

const int32_t MATRIX_UNDEFINED = -1;
const int32_t NUM_SHADERS = 4;

enum SHADER_INDEX {
	SHADER_NOTEXTURE = 0,
	SHADER_TEXTURE = 1,
	SHADER_SKIN = 2,
	SHADER_SKIN_TEXTURE = 3,
};

struct renderer_vertex
{
	float pos[3];
	float normal_vec[3];
	float uv[2];
	uint8_t bone[4];
};

struct skinanimation_vertex
{
	float pos[3];
};

struct DRAW_LIST
{
	bool	bSkinMesh;
	int32_t iMaterialIndex;
	int32_t iNumIndices;
	std::vector< int32_t > vecMatrixPalette;
};

struct SHADER_PARAMS
{
	GLuint _program;
	GLuint _uiLight0;
	GLuint _uiMaterialDiffuse;
	GLuint _uiMaterialAmbient;
	GLuint _uiMaterialSpecular;
	
	GLuint _uiMatrixPalette;
	GLuint _uiMatrixP;

	GLuint _uiSkinWeight;
};

class pmdRenderer
{
	vmdMotionProvider* _motionProvider;

	SHADER_PARAMS _shaders[ NUM_SHADERS ];

	PVRTMat4 _mProjection;
	PVRTMat4 _mView;

	GLuint _vboRender;
	GLuint _vboIndex;

	GLuint _vboSkinAnimation;
	int32_t _iNumSkinAnimations;
	int32_t _iCurrentSkinAnimationIndex;
	int32_t _iSizeSkinanimatinVertices;
	std::vector< skinanimation_vertex* > _vecSkinAnimation;

	std::vector< DRAW_LIST > _vecDrawList;
	std::vector< mmd_material > _vecMaterials;
	
	void createVbo( pmdReader * pReader );
	void createIndexBuffer( pmdReader* pReader );
	void loadMaterials( pmdReader* pReader );

	BOOL compileShader( GLuint *shader, const GLenum type, const NSString *file );
	BOOL linkProgram( const GLuint prog );
	BOOL validateProgram(const GLuint prog );
	BOOL loadShaders( SHADER_PARAMS* params, NSString* strVsh, NSString* strFsh );

	bool partitionMeshes( pmdReader* reader );
	bool partitioning( pmdReader* reader, SkinningEvaluator* eval, int32_t iStart, int32_t iNumIndices );
	static NSComparisonResult compare(NSNumber *first, NSNumber *second, NSDictionary *dic);
	bool createMatrixMapping( NSArray* sortedKeys, NSDictionary* dicMatrixRefArray );

	std::vector< renderer_vertex > _vecMappedVertex;
	std::map< int32_t, std::map< int32_t, int32_t> > _mapVertexMapping;
	
	int32_t getMappedVertices( mmd_vertex* pVertex, const int32_t iVertexIndex, const uint32_t iVertexKey, const bool bSkining );
	int16_t getMappedBone( std::vector< int32_t >* pVec, const int32_t iBone );

	bool _bPerformSkinmeshAnimation;
public:
	pmdRenderer();
	~pmdRenderer();
	bool init( pmdReader* reader, vmdReader* motion );
	bool unload();
	
	void update( const double dTime );
	void render();
};

