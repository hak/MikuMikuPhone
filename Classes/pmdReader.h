//
//  pmdReader.h
//  MikuMikuPhone
//
//  Created by hakuroum on 1/14/11.
//  Copyright 2011 hakuroum@gmail.com . All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Texture2D.h"

#pragma pack(1)

//Should be 38 bytes in size
struct vertex
{
	float pos[3];
	float normal_vec[3];
	float uv[2];
	uint16_t bone_num[2];
	uint8_t bone_weight;
	uint8_t edge_flag;
};

//Should be 70 bytes in size
struct material
{
	float diffuse_color[3];
	float alpha;
	float intensity;
	float specular_color[3];
	float ambient_color[3]; // ambient
	uint8_t toon_index; // toonNN.bmp // 0.bmp:0xFF, 1(01).bmp:0x00 ・・・ 10.bmp:0x09
	uint8_t	edge_flag;
	uint32_t face_vert_count;
	union {
		char texture_file_name[20];
		struct {
			uint32_t _tex;
			Texture2D* _tex2D;
		};
	};
};

struct bone
{
	char bone_name[20];
	uint16_t	parent_bone_index;		// 0xffff if none
	uint16_t	tail_pos_bone_index;	// tail bone
	uint8_t		bone_type;
	uint16_t	ik_parent_bone_index;
	float bone_head_pos[3];
};

struct ik
{
	uint16_t ik_bone_index;
	uint16_t ik_target_bone_index;
	uint8_t ik_chain_length;
	uint16_t iterations;
	float control_weight;
	uint16_t ik_child_bone_index[];
};

struct skin_vertex
{
	uint32_t	vert_index;
	float		pos[3];
};

struct skin
{
	char		skin_name[20];
	uint32_t	skin_vert_count;
	uint8_t		skin_type;	// 0:base, 1:eyebrow 2:eye 3:lip 4:etc
	skin_vertex skin_vert_data[];
};
#pragma pack()

class pmdReader
{
	int8_t* _pData;
	int32_t _iOffset;
	NSData* _data;
	
	int32_t _iNumVertices;
	vertex* _pVertices;

	int32_t _iNumIndices;
	uint16_t* _pIndices;

	int32_t _iNumMaterials;
	material* _pMaterials;
	
	int32_t _iNumBones;
	bone* _pBones;

	int32_t _iNumIKs;
	ik* _pIKs;
	
	int32_t _iNumSkins;
	skin* _pSkins;
	
	int32_t getInteger();
	int16_t getShort();
	float getFloat();

	bool verifyHeader();
	bool parseVertices();
	bool parseIndices();
	bool parseMaterials();
	bool parseBones();
	bool parseIKs();
	bool parseSkins();
public:
	pmdReader();
	~pmdReader();
	bool init( NSString* strFileName );
	
	int32_t getNumVertices() { return _iNumVertices; }
	vertex* getVertices() { return _pVertices; }
	
	int32_t getNumIndices() { return _iNumIndices; }
	uint16_t* getIndices() { return _pIndices; }

	int32_t getNumMaterials() { return _iNumMaterials; }
	material* getMaterials() { return _pMaterials; }
};