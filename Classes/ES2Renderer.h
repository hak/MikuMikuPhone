//
//  ES2Renderer.h
//  MikuMikuPhone
//
//  Created by hakuroum on 1/14/11.
//  Copyright 2011 hakuroum@gmail.com . All rights reserved.
//

#import "ESRenderer.h"

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#import "pmdRenderer.h"

#define USE_MSAA (1)
#define NUM_MSAASAMPLE (2)

@interface ES2Renderer : NSObject <ESRenderer>
{
@private
    EAGLContext *context;

    // The pixel dimensions of the CAEAGLLayer
    GLint backingWidth;
    GLint backingHeight;

    // The OpenGL ES names for the framebuffer and renderbuffer used to render to this view
    GLuint defaultFramebuffer, colorRenderbuffer, depthRenderbuffer;
	
#ifdef USE_MSAA
	//Buffer definitions for the MSAA
	GLuint msaaFramebuffer, msaaRenderBuffer, msaaDepthBuffer;
#endif
	
    GLuint program;
	
	pmdReader _reader;
	vmdReader _motionreader;
	pmdRenderer _pmdRenderer;
	
}

- (void)render;
- (BOOL)resizeFromLayer:(CAEAGLLayer *)layer;

@end

