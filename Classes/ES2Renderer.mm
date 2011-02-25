//
//  ES2Renderer.m
//  MikuMikuPhone
//
//  Created by hakuroum on 1/14/11.
//  Copyright 2011 hakuroum@gmail.com . All rights reserved.
//

#include <sys/time.h>
#import "ES2Renderer.h"

// uniform index
enum {
    UNIFORM_TRANSLATE,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// attribute index
enum {
    ATTRIB_VERTEX,
    ATTRIB_COLOR,
    NUM_ATTRIBUTES
};

inline double micro()
{
	struct timeval tv;
	double now;
	gettimeofday( &tv, NULL );
	now = tv.tv_usec;
	now /= 1000000;
	now += tv.tv_sec;
	
	return now;
}

@interface ES2Renderer (PrivateMethods)
- (BOOL)loadShaders;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;
@end

@implementation ES2Renderer

// Create an OpenGL ES 2.0 context
- (id)init
{
    self = [super init];
    if (self)
    {
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

        if (!context || ![EAGLContext setCurrentContext:context] || ![self loadShaders])
        {
            [self release];
            return nil;
        }

        // Create default framebuffer object. The backing will be allocated for the current layer in -resizeFromLayer
        glGenFramebuffers(1, &defaultFramebuffer);
        glGenRenderbuffers(1, &colorRenderbuffer);

        glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);

        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderbuffer);
		
		int32_t i;
		glGetIntegerv(GL_MAX_VERTEX_ATTRIBS, &i);
		NSLog( @"GL_MAX_VERTEX_ATTRIBS:%d", i );
		glGetIntegerv(GL_MAX_VERTEX_UNIFORM_VECTORS, &i);
		NSLog( @"GL_MAX_VERTEX_UNIFORM_VECTORS:%d", i );
		glGetIntegerv(GL_MAX_VARYING_VECTORS, &i);
		NSLog( @"GL_MAX_VARYING_VECTORS:%d", i );
		glGetIntegerv(GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS, &i);
		NSLog( @"GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS:%d", i );
		glGetIntegerv(GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS, &i);
		NSLog( @"GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS:%d", i );
		glGetIntegerv(GL_MAX_TEXTURE_IMAGE_UNITS, &i);
		NSLog( @"GL_MAX_TEXTURE_IMAGE_UNITS:%d", i );
		glGetIntegerv(GL_MAX_FRAGMENT_UNIFORM_VECTORS, &i);
		NSLog( @"GL_MAX_FRAGMENT_UNIFORM_VECTORS:%d", i );
		
    }

    return self;
}

- (bool)load:(NSString*)strModel motion:(NSString*)strMotion
{
	if( strModel == nil )
		return false;
	
	_pmdRenderer.unload();
	_reader.unload();
	_motionreader.unload();
	
	bool b = _reader.init( strModel );
	if( b == false )
		return b;
	
	if( strMotion == nil )
	{
		_pmdRenderer.init( &_reader, NULL );
	}
	else
	{
		_motionreader.init( strMotion );
		_pmdRenderer.init( &_reader, &_motionreader );
	}
	
	return true;
}

- (void)render
{
    // This application only creates a single context which is already set current at this point.
    // This call is redundant, but needed if dealing with multiple contexts.
    [EAGLContext setCurrentContext:context];

#ifdef USE_MSAA
	glBindFramebuffer(GL_FRAMEBUFFER, msaaFramebuffer);
	glBindRenderbuffer(GL_RENDERBUFFER, msaaRenderBuffer);
#endif

    glViewport(0, 0, backingWidth, backingHeight);

    glClearColor(0.5f, 0.5f, 0.5f, 1.0f);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    // Draw
	_pmdRenderer.update(micro());
	_pmdRenderer.render();

#ifdef USE_MSAA
	//Discard buffer
	GLenum attachments[] = {GL_DEPTH_ATTACHMENT};
	glDiscardFramebufferEXT(GL_READ_FRAMEBUFFER_APPLE, 1, attachments);   
    
	//Bind both MSAA and View FrameBuffers.
	glBindFramebuffer(GL_READ_FRAMEBUFFER_APPLE, msaaFramebuffer);
	glBindFramebuffer(GL_DRAW_FRAMEBUFFER_APPLE, defaultFramebuffer); 

	// Call a resolve to combine both buffers
	glResolveMultisampleFramebufferAPPLE();   
#else
	//Discard buffer
	GLenum attachments[] = {GL_DEPTH_ATTACHMENT};
	glDiscardFramebufferEXT(GL_READ_FRAMEBUFFER_APPLE, 1, attachments);   
    
    glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);
#endif	
    // This application only creates a single color renderbuffer which is already bound at this point.
    // This call is redundant, but needed if dealing with multiple renderbuffers.
    glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
    [context presentRenderbuffer:GL_RENDERBUFFER];
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
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

- (BOOL)linkProgram:(GLuint)prog
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

- (BOOL)validateProgram:(GLuint)prog
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

- (BOOL)loadShaders
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;

    // Create shader program
    program = glCreateProgram();

    // Create and compile vertex shader
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname])
    {
        NSLog(@"Failed to compile vertex shader");
        return FALSE;
    }

    // Create and compile fragment shader
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname])
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
    glBindAttribLocation(program, ATTRIB_VERTEX, "position");
    glBindAttribLocation(program, ATTRIB_COLOR, "color");

    // Link program
    if (![self linkProgram:program])
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
            program = 0;
        }
        
        return FALSE;
    }

    // Get uniform locations
    uniforms[UNIFORM_TRANSLATE] = glGetUniformLocation(program, "translate");

    // Release vertex and fragment shaders
    if (vertShader)
        glDeleteShader(vertShader);
    if (fragShader)
        glDeleteShader(fragShader);

    return TRUE;
}

- (BOOL)resizeFromLayer:(CAEAGLLayer *)layer
{
    // Allocate color buffer backing based on the current layer size
    glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
    
	[context renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer];

	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);

#ifdef USE_MSAA
	if( msaaFramebuffer == 0 )
	{
		//Generate our MSAA Frame and Render buffers
		glGenFramebuffers(1, &msaaFramebuffer);
		glGenRenderbuffers(1, &msaaRenderBuffer);
		
		//Bind our MSAA buffers
		glBindFramebuffer(GL_FRAMEBUFFER, msaaFramebuffer);
		glBindRenderbuffer(GL_RENDERBUFFER, msaaRenderBuffer);
		
		// Generate the msaaDepthBuffer.
		// 4 will be the number of pixels that the MSAA buffer will use in order to make one pixel on the render buffer.
		glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER, NUM_MSAASAMPLE, GL_RGB5_A1, backingWidth, backingHeight);
		glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, msaaRenderBuffer);
	}
#endif
	if( depthRenderbuffer == 0 )
	{
		glGenRenderbuffers(1, &depthRenderbuffer);
		glBindRenderbuffer(GL_RENDERBUFFER, depthRenderbuffer);
#ifdef USE_MSAA
		//Bind the msaa depth buffer.
		glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER, NUM_MSAASAMPLE, GL_DEPTH_COMPONENT16, backingWidth , backingHeight);
#else
		glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, backingWidth, backingHeight);
#endif
		glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthRenderbuffer);
	}
		
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
    {
        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
        return NO;
    }

    return YES;
}

- (void)dealloc
{
    // Tear down GL
    if (defaultFramebuffer)
    {
        glDeleteFramebuffers(1, &defaultFramebuffer);
        defaultFramebuffer = 0;
    }

    if (colorRenderbuffer)
    {
        glDeleteRenderbuffers(1, &colorRenderbuffer);
        colorRenderbuffer = 0;
    }
	
    if (depthRenderbuffer)
    {
        glDeleteRenderbuffers(1, &depthRenderbuffer);
        depthRenderbuffer = 0;
    }

    if (program)
    {
        glDeleteProgram(program);
        program = 0;
    }

    // Tear down context
    if ([EAGLContext currentContext] == context)
        [EAGLContext setCurrentContext:nil];

    [context release];
    context = nil;

    [super dealloc];
}

@end
