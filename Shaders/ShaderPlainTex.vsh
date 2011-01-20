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
varying mediump vec2	texCoord;
varying lowp	vec4	colorDiffuse;

#if USE_PHONG
varying mediump vec3 position;
varying mediump vec3 normal;
#else
varying lowp	vec4	colorSpecular;
#endif

uniform highp mat4		myMVPMatrix;
uniform highp mat4		myWorldMatrix;
uniform highp mat4		myWorldViewMatrix;
uniform highp vec3		vLight0;

uniform highp vec4		vMaterialDiffuse;
uniform highp vec3		vMaterialAmbient;
uniform highp vec4		vMaterialSpecular;

void main(void)
{
	gl_Position = myMVPMatrix * vec4(myVertex,1);
	texCoord = myUV;

	highp vec3 worldNormal = vec3(vec4(myNormal,0) * myWorldMatrix);
	colorDiffuse = dot( worldNormal, -vLight0 ) * vMaterialDiffuse;
	//colorDiffuse = vec4(0,0,0,1);
	
	highp vec3 ecPosition = vec3(myWorldMatrix*vec4(myVertex,1) );
	
#if USE_PHONG
	normal = worldNormal;
	position = ecPosition;
#else	
	highp vec3 halfVector = -normalize(vLight0 + ecPosition);
	
	highp float NdotH = max(dot(worldNormal, halfVector), 0.0);	
	float fPower = vMaterialSpecular.w;	
	highp float specular = pow(NdotH, fPower);
	colorSpecular = vec4( vMaterialSpecular.xyz * specular, 1 ) + vec4( vMaterialAmbient, 1 );
//	colorSpecular = vec4( 0,0,0, 1 );
#endif
}
