#define M_PI 3.14159265359

#define SDF_MAX_LENGTH 16384.0

#define INSTANCE_FLAGS_LIGHT_COUNT_SHIFT 0 // 4 bits.

#define INSTANCE_FLAGS_TRANSPOSE_RECT uint(1 << 5)

#define INSTANCE_FLAGS_NINEPATCH_DRAW_CENTER uint(1 << 8)
#define INSTANCE_FLAGS_NINEPATCH_H_MODE_SHIFT 9
#define INSTANCE_FLAGS_NINEPATCH_V_MODE_SHIFT 11

// 1 means enabled, 2+ means trails in use
#define BATCH_FLAGS_INSTANCING_MASK uint(0x7F)
#define BATCH_FLAGS_INSTANCING_HAS_COLORS_SHIFT 7
#define BATCH_FLAGS_INSTANCING_HAS_COLORS uint(1 << BATCH_FLAGS_INSTANCING_HAS_COLORS_SHIFT)
#define BATCH_FLAGS_INSTANCING_HAS_CUSTOM_DATA_SHIFT 8
#define BATCH_FLAGS_INSTANCING_HAS_CUSTOM_DATA uint(1 << BATCH_FLAGS_INSTANCING_HAS_CUSTOM_DATA_SHIFT)

layout(std140) uniform GlobalShaderUniformData { //ubo:1
	vec4 global_shader_uniforms[MAX_GLOBAL_SHADER_UNIFORMS];
};

layout(std140) uniform CanvasData { //ubo:0
	mat4 canvas_transform;
	mat4 screen_transform;
	mat4 canvas_normal_transform;
	vec4 canvas_modulation;
	vec2 screen_pixel_size;
	float time;
	bool use_pixel_snap;

	vec4 sdf_to_tex;
	vec2 screen_to_sdf;
	vec2 sdf_to_screen;

	uint directional_light_count;
	float tex_to_sdf;
	uint pad1;
	uint pad2;
};