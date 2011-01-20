//
//  pmdRenderer.mm
//  MikuMikuPhone
//
//  Created by hakuroum on 1/14/11.
//  Copyright 2011 hakuroum@gmail.com. All rights reserved.
//

#import "pmdRenderer.h"


#define BUFFER_OFFSET(i) ((char *)NULL + (i))

enum {
	ATTRIB_VERTEX,
	ATTRIB_NORMAL,
	ATTRIB_UV,
	ATTRIB_BONEINDEX,
	ATTRIB_BONEWEIGHT,
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
	if (_program)
		glDeleteProgram(_program);
	if (_programTex)
		glDeleteProgram(_programTex);
}

#pragma mark Render
void pmdRenderer::render()
{
    // Bind the VBO
    glBindBuffer(GL_ARRAY_BUFFER, _vboRender);
	
    int32_t iStride = sizeof(vertex);
    // Pass the vertex data
    glVertexAttribPointer(ATTRIB_VERTEX, 3, GL_FLOAT, GL_FALSE, iStride, BUFFER_OFFSET( 0 ));
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    
    glVertexAttribPointer(ATTRIB_NORMAL, 3, GL_FLOAT, GL_FALSE, iStride, BUFFER_OFFSET( 3 * sizeof(GLfloat) ));
    glEnableVertexAttribArray(ATTRIB_NORMAL);
    
	// Bind the IB
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _vboIndex);
	    
    // Set matrix		
	static float fAngle = 0.f;
	fAngle += 0.05f;
    PVRTMat4 mModel = PVRTMat4::RotationY( fAngle );
	mModel.postTranslate( 0.f, -10.f, 0.f );

	//State
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_CULL_FACE);
	glCullFace(GL_CCW);
    
    // Feed Projection and Model View matrices to the shaders
    PVRTMat4 mModelView = _mView * mModel;
    PVRTMat4 mMVP = _mProjection * mModelView;
	
	int32_t iMaterials = _reader->getNumMaterials();
	material* pMaterial = _reader->getMaterials();
	int32_t iOffset = 0;
	
	for( int32_t i = 0; i < iMaterials; ++i )
	{
		int32_t iNumIndices = pMaterial[ i ].face_vert_count;

		//Set materials
		if( pMaterial[ i ].alpha < 1.0f )
			glEnable(GL_BLEND);
		else
			glDisable(GL_BLEND);
		
		if( pMaterial[ i ]._tex )
		{
			glUseProgram(_programTex);		
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
		}
		else
		{
			glUseProgram(_program);		
			glDisable(GL_TEXTURE_2D);
			glDisableVertexAttribArray(ATTRIB_UV);
		}
		glUniform4f( _uiMaterialDiffuse, pMaterial[ i ].diffuse_color[ 0 ],
					pMaterial[ i ].diffuse_color[ 1 ],
					pMaterial[ i ].diffuse_color[ 2 ],
					pMaterial[ i ].alpha );
		glUniform4f( _uiMaterialSpecular, pMaterial[ i ].specular_color[ 0 ],
					pMaterial[ i ].specular_color[ 1 ],
					pMaterial[ i ].specular_color[ 2 ],
					pMaterial[ i ].intensity );
		
		glUniform3fv( _uiMaterialAmbient, 1, pMaterial[ i ].ambient_color );
		
		glUniformMatrix4fv( _uiMatrixLocation, 1, GL_FALSE,  mMVP.ptr());
		glUniformMatrix4fv( _uiMatrixWorld, 1, GL_FALSE,  mModel.ptr());
		glUniformMatrix4fv( _uiMatrixWorldView, 1, GL_FALSE,  mModelView.ptr());
		glUniform3f( _uiLight0, 1.f, 0.f, 0.f );
		
		glDrawElements(GL_TRIANGLES, iNumIndices,
					   GL_UNSIGNED_SHORT, BUFFER_OFFSET(iOffset * sizeof(uint16_t) ));
		iOffset += iNumIndices;
	}
	
	//	glDrawArrays(GL_TRIANGLES, 0, iNumIndices);    
}

#pragma mark Init
bool pmdRenderer::init( pmdReader* reader )
{
	if( reader == NULL )
		return false;
	_reader = reader;
	
	loadShaders(&_program, @"ShaderPlain", @"ShaderPlain" );
	loadShaders(&_programTex, @"ShaderPlainTex", @"ShaderPlainTex" );

#if defined(DEBUG)
    if (!validateProgram(_program))
    {
        NSLog(@"Failed to validate program: %d", _program);
        return false;
    }
#endif
	
	createVbo();
	createIndexBuffer();

	//Init matrices
	float fAspect = 320.f/480.f;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		fAspect = 0.75;

    const float CAM_FOV  = M_PI_2/4;
    const float CAM_NEAR = 0.5f;
	const float CAM_Z = 64.f;
	
    bool bRotate = false;
    _mProjection = PVRTMat4::PerspectiveFovFloatDepthRH(CAM_FOV, fAspect, CAM_NEAR, PVRTMat4::OGL, bRotate);
    _mView = PVRTMat4::LookAtRH(PVRTVec3(0.f, 0.f, CAM_Z), PVRTVec3(0.f), PVRTVec3(0.f, 1.f, 0.f));
	
	return true;	
}

void pmdRenderer::createVbo()
{
    int32_t iStride = sizeof( vertex );
	glGenBuffers(1, &_vboRender);
	
	// Bind the VBO
	glBindBuffer(GL_ARRAY_BUFFER, _vboRender);
	
	// Set the buffer's data
	glBufferData(GL_ARRAY_BUFFER, iStride * _reader->getNumVertices(), _reader->getVertices(), GL_STATIC_DRAW);

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
    
	return;
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

BOOL pmdRenderer::loadShaders( GLuint*pProgram, NSString* strVsh, NSString* strFsh )
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
            *pProgram = 0;
        }
        
        return FALSE;
    }
	
    // Get uniform locations
	_uiMatrixLocation = glGetUniformLocation(program, "myMVPMatrix");
	_uiMatrixWorld = glGetUniformLocation(program, "myWorldMatrix");
	_uiMatrixWorldView = glGetUniformLocation(program, "myWorldViewMatrix");
	_uiLight0 = glGetUniformLocation(program, "vLight0");
	_uiMaterialDiffuse = glGetUniformLocation(program, "vMaterialDiffuse");
	_uiMaterialAmbient = glGetUniformLocation(program, "vMaterialAmbient");
	_uiMaterialSpecular = glGetUniformLocation(program, "vMaterialSpecular");

	// Set the sampler2D uniforms to corresponding texture units
	glUniform1i(glGetUniformLocation(program, "sTexture"), 0);
  
	// Release vertex and fragment shaders
    if (vertShader)
        glDeleteShader(vertShader);
	if (fragShader)
		glDeleteShader(fragShader);

	*pProgram = program;
	return TRUE;
}


