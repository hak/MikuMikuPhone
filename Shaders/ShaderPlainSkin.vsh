//
//  Shader.vsh
//  MikuMikuPhone
//
//  Created by hakuroum on 1/14/11.
//  Copyright 2011 hakuroum@gmail.com . All rights reserved.
//

#define USE_PHONG (1)

attribute highp vec3	myVertex;
attribute highp vec3	myNormal;
attribute mediump vec2	myUV;
attribute mediump vec4	myBone;

attribute highp vec3	mySkinAnimation;

varying mediump vec2	texCoord;
varying lowp	vec4	colorDiffuse;

#if USE_PHONG
varying mediump vec3 position;
varying mediump vec3 normal;
#else
varying lowp	vec4	colorSpecular;
#endif

//uniform highp mat4		uMVMatrix;
uniform highp mat4		uPMatrix;
uniform highp mat4		uMatrixPalette[116];

uniform highp vec3		vLight0;

uniform highp vec4		vMaterialDiffuse;
uniform highp vec3		vMaterialAmbient;
uniform highp vec4		vMaterialSpecular;

uniform highp float		fSkinWeight;


void main(void)
{
	highp vec4 p = vec4(myVertex,1);

	highp vec4 pSkin = vec4(mySkinAnimation,0);
	p = p + pSkin * myBone.z * fSkinWeight;
	
	highp mat4 m0 = uMatrixPalette[ int(myBone.x) ];
	highp mat4 m1 = uMatrixPalette[ int(myBone.y) ];
	vec4 b0 = m0 * p;
	vec4 b1 = m1 * p;
	vec4 v	= mix(b1, b0, myBone.w / 255.0);

	gl_Position = uPMatrix * v;
	gl_Position.z = -gl_Position.z;	

	texCoord = myUV;

	highp vec3 worldNormal = vec3(mat3(m0[0].xyz, m0[1].xyz, m0[2].xyz) * myNormal);
	highp vec3 ecPosition = v.xyz;

	colorDiffuse = dot( worldNormal, normalize(-vLight0+ecPosition) ) * vMaterialDiffuse  + vec4( vMaterialAmbient, 1 );
	
#if USE_PHONG
	normal = worldNormal;
	position = ecPosition;
#else	
	highp vec3 halfVector = normalize(ecPosition - vLight0);
	
	highp float NdotH = max(-dot(worldNormal, halfVector), 0.0);	
	float fPower = vMaterialSpecular.w;	
	highp float specular = min( pow(NdotH, fPower), 1.0);
	colorSpecular = vec4( vMaterialSpecular.xyz * specular, 1 );
#endif
}
