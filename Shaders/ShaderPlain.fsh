//
//  Shader.fsh
//  MikuMikuPhone
//
//  Created by hakuroum on 1/14/11.
//  Copyright 2011 hakuroum@gmail.com . All rights reserved.
//

#define USE_PHONG (1)

uniform sampler2D sTexture;
uniform highp vec3		vMaterialAmbient;
uniform highp vec4		vMaterialSpecular;

varying lowp vec4 colorDiffuse;
varying highp vec2	texCoord;

#if USE_PHONG
uniform highp vec3		vLight0;
varying mediump vec3 position;
varying mediump vec3 normal;
#else
varying lowp vec4 colorSpecular;
#endif

void main()
{
#if USE_PHONG
	mediump vec3 halfVector = normalize(vLight0 + position);
	mediump float NdotH = max(dot(normal, halfVector), 0.0);	
	mediump float fPower = vMaterialSpecular.w;	
	mediump float specular = pow(NdotH, fPower);
	
	lowp vec4 colorSpecular = vec4( vMaterialSpecular.xyz * specular, 1 ) + vec4( vMaterialAmbient, 1 );
    gl_FragColor = texture2D(sTexture, texCoord)* colorDiffuse + colorSpecular;
#else	
    gl_FragColor = texture2D(sTexture, texCoord)* colorDiffuse + colorSpecular;
#endif
}
