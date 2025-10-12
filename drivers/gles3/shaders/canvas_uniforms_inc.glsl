#define M_PI 3.14159265359

#define SDF_MAX_LENGTH 16384.0

//1 means enabled, 2+ means trails in use
#define FLAGS_INSTANCING_HAS_COLORS uint(1 << 7)
#define FLAGS_INSTANCING_HAS_CUSTOM_DATA uint(1 << 8)

#define FLAGS_TRANSPOSE_RECT uint(1 << 10)

#define FLAGS_USE_MSDF uint(1 << 28)
#define FLAGS_USE_LCD uint(1 << 29)

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