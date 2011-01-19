//
//  pmdRenderer.h
//  MikuMikuPhone
//
//  Created by hakuroum on 1/14/11.
//  Copyright 2011 hakuroum@gmail.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>

#import "pmdReader.h"
#import "PVRTVector.h"
#import "Texture2D.h"

class pmdRenderer
{
	pmdReader* _reader;

	GLuint _program;
	GLuint _uiMatrixLocation;
	GLuint _uiMatrixWorld;
	GLuint _uiMatrixWorldView;
	GLuint _uiLight0;
	GLuint _uiMaterialDiffuse;
	GLuint _uiMaterialAmbient;
	GLuint _uiMaterialSpecular;

	PVRTMat4 _mProjection;
	PVRTMat4 _mView;
		
	GLuint _vboRender;
	GLuint _vboIndex;
	
	void createVbo();
	void createIndexBuffer();

	BOOL compileShader( GLuint *shader, const GLenum type, const NSString *file );
	BOOL linkProgram( const GLuint prog );
	BOOL validateProgram(const GLuint prog );
	BOOL loadShaders();

public:
	pmdRenderer();
	~pmdRenderer();
	bool init( pmdReader* reader );
	void render();
};

