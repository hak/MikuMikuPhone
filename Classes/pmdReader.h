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
struct mmd_vertex
{
	float pos[3];
	float normal_vec[3];
	float uv[2];
	uint16_t bone_num[2];
	uint8_t bone_weight;
	uint8_t edge_flag;
	
	int16_t	getBoneIndex( const int32_t i )
	{
		switch( i )
		{
			case 0:
				return bone_num[ 0 ];
			case 1:
				if( bone_weight < 100 )
				{
					return bone_num[ 1 ];
				}
				else -1;
			default:
				return -1;
		}
	}
};

//Should be 70 bytes in size
struct mmd_material
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

struct mmd_bone
{
	char bone_name[20];
	uint16_t	parent_bone_index;		// 0xffff if none
	uint16_t	tail_pos_bone_index;	// tail bone
	uint8_t		bone_type;
	uint16_t	ik_parent_bone_index;
	float bone_head_pos[3];
};

struct mmd_ik
{
	uint16_t ik_bone_index;
	uint16_t ik_target_bone_index;
	uint8_t ik_chain_length;
	uint16_t iterations;
	float control_weight;
	uint16_t ik_child_bone_index[];
};

struct mmd_skin_vertex
{
	uint32_t	vert_index;
	float		pos[3];
};

struct mmd_skin
{
	char		skin_name[20];
	uint32_t	skin_vert_count;
	uint8_t		skin_type;	// 0:base, 1:eyebrow 2:eye 3:lip 4:etc
	mmd_skin_vertex skin_vert_data[];
};
#pragma pack()

class pmdReader
{
	int8_t* _pData;
	int32_t _iOffset;
	NSData* _data;
	
	int32_t _iNumVertices;
	mmd_vertex* _pVertices;

	int32_t _iNumIndices;
	uint16_t* _pIndices;

	int32_t _iNumMaterials;
	mmd_material* _pMaterials;
	
	int32_t _iNumBones;
	mmd_bone* _pBones;

	int32_t _iNumIKs;
	mmd_ik* _pIKs;
	
	int32_t _iNumSkins;
	mmd_skin* _pSkins;
	
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
	bool unload();
	
	int32_t getNumVertices() { return _iNumVertices; }
	mmd_vertex* getVertices() { return _pVertices; }
	
	int32_t getNumIndices() { return _iNumIndices; }
	uint16_t* getIndices() { return _pIndices; }

	int32_t getNumMaterials() { return _iNumMaterials; }
	mmd_material* getMaterials() { return _pMaterials; }

	int32_t getNumBones() { return _iNumBones; }
	mmd_bone* getBones() { return _pBones; }

	int32_t getNumIKs() { return _iNumIKs; }
	mmd_ik* getIKs() { return _pIKs; }
};