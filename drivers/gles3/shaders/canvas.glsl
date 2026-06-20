/* clang-format off */
#[modes]

mode_quad = #define MODE_QUAD
mode_primitive = #define USE_PRIMITIVE
mode_attributes = #define USE_ATTRIBUTES
mode_instanced = #define USE_ATTRIBUTES \n#define USE_INSTANCING

#[specializations]

PIXEL_SNAP = false
USE_MSDF = false
USE_LCD = false
USE_REGION_TILE = false

#[vertex]

#if defined(USE_ATTRIBUTES)
layout(location = 0) in vec2 vertex_attrib;
layout(location = 3) in vec4 color_attrib;
layout(location = 4) in vec2 uv_attrib;
#endif // USE_INSTANCING

#if defined(USE_ATTRIBUTES) && defined(USE_INSTANCING)
layout(location = 1) in highp vec4 instance_xform0;
layout(location = 2) in highp vec4 instance_xform1;
layout(location = 5) in highp uvec4 instance_color_custom_data; // Color packed into xy, custom_data packed into zw for compatibility with 3D
#endif // USE_ATTRIBUTES && USE_INSTANCING

#include "stdlib_inc.glsl"

#if defined(CUSTOM0_USED)
layout(location = 6) in highp vec4 custom0_attrib;
#endif // CUSTOM0_USED

#if defined(CUSTOM1_USED)
layout(location = 7) in highp vec4 custom1_attrib;
#endif // CUSTOM1_USED

layout(location = 8) in highp vec4 attrib_A;
layout(location = 9) in highp vec4 attrib_B;
layout(location = 10) in highp vec4 attrib_C;
layout(location = 11) in highp vec4 attrib_D;
layout(location = 12) in highp vec4 attrib_E;

#if defined(USE_PRIMITIVE)
layout(location = 13) in highp uvec4 attrib_F;
#else // !USE_PRIMITIVE
layout(location = 13) in highp vec4 attrib_F;
#endif // USE_PRIMITIVE

layout(location = 14) in highp uvec4 attrib_G;
//layout(location = 15) in highp uvec4 attrib_H;

#define read_draw_data_world_x attrib_A.xy
#define read_draw_data_world_y attrib_A.zw
#define read_draw_data_world_ofs attrib_B.xy
#define texpixel_size attrib_B.zw

#ifdef USE_PRIMITIVE

#define read_draw_data_point_a attrib_C.xy
#define read_draw_data_point_b attrib_C.zw
#define read_draw_data_point_c attrib_D.xy
#define read_draw_data_uv_a attrib_D.zw
#define read_draw_data_uv_b attrib_E.xy
#define read_draw_data_uv_c attrib_E.zw

#define read_draw_data_color_a_rg attrib_F.x
#define read_draw_data_color_a_ba attrib_F.y
#define read_draw_data_color_b_rg attrib_F.z
#define read_draw_data_color_b_ba attrib_F.w
#define read_draw_data_color_c_rg attrib_G.x
#define read_draw_data_color_c_ba attrib_G.y

#else // !USE_PRIMITIVE

#define read_draw_data_modulation attrib_C
#define read_draw_data_msdf attrib_D
#define dst_rect attrib_E
#define uv_rect attrib_F

#endif // USE_PRIMITIVE

#define read_draw_data_flags attrib_G.z
#define read_draw_data_specular_shininess attrib_G.w

// This needs to be outside clang-format so the ubo comment is in the right place
#if defined(MATERIAL_UNIFORMS_USED)
layout(std140) uniform MaterialUniforms{ //ubo:4

#MATERIAL_UNIFORMS

};
#endif // MATERIAL_UNIFORMS_USED
/* clang-format on */
#include "canvas_uniforms_inc.glsl"

// Out for Region Tile
#if !defined(USE_PRIMITIVE) && defined(USE_REGION_TILE)
layout(location = 15) in highp vec4 attrib_H;
flat out vec4 uv_repeat;
#endif // !USE_PRIMITIVE && USE_REGION_TILE
// Out for MSDF
#if !defined(USE_PRIMITIVE) && defined(USE_MSDF)
flat out vec4 varying_C;
#endif // !USE_PRIMITIVE && USE_MSDF

out vec2 uv_interp;
out vec2 vertex_interp;
out vec4 color_interp;

#GLOBALS

void main() {
	vec4 instance_custom = vec4(0.0);

#if !defined(USE_PRIMITIVE) && defined(USE_REGION_TILE)
	uv_repeat.xy = uv_rect.xy;
	uv_repeat.zw = attrib_H.xy;
#endif // !USE_PRIMITIVE && USE_REGION_TILE

#if !defined(USE_PRIMITIVE) && defined(USE_MSDF)
	varying_C = read_draw_data_msdf;
#endif // !USE_PRIMITIVE && USE_MSDF

#if defined(CUSTOM0_USED)
	vec4 custom0 = vec4(0.0);
#endif // CUSTOM0_USED

#if defined(CUSTOM1_USED)
	vec4 custom1 = vec4(0.0);
#endif // CUSTOM1_USED

#if defined(USE_PRIMITIVE)
	vec2 vertex = vec2(0.0);
	vec2 uv = vec2(0.0);
	vec4 color = vec4(0.0);

	if (gl_VertexID % 3 == 0) {
		vertex = read_draw_data_point_a;
		uv = read_draw_data_uv_a;
		color.xy = unpackHalf2x16(read_draw_data_color_a_rg);
		color.zw = unpackHalf2x16(read_draw_data_color_a_ba);
	} else if (gl_VertexID % 3 == 1) {
		vertex = read_draw_data_point_b;
		uv = read_draw_data_uv_b;
		color.xy = unpackHalf2x16(read_draw_data_color_b_rg);
		color.zw = unpackHalf2x16(read_draw_data_color_b_ba);
	} else {
		vertex = read_draw_data_point_c;
		uv = read_draw_data_uv_c;
		color.xy = unpackHalf2x16(read_draw_data_color_c_rg);
		color.zw = unpackHalf2x16(read_draw_data_color_c_ba);
	}

#elif defined(USE_ATTRIBUTES) // !USE_PRIMITIVE
	vec2 vertex = vertex_attrib;
	vec4 color = color_attrib * read_draw_data_modulation;
	vec2 uv = uv_attrib;

#if defined(USE_INSTANCING)
	if (bool(read_draw_data_flags & FLAGS_INSTANCING_HAS_COLORS)) {
		vec4 instance_color;
		instance_color.xy = unpackHalf2x16(uint(instance_color_custom_data.x));
		instance_color.zw = unpackHalf2x16(uint(instance_color_custom_data.y));
		color *= instance_color;
	}
	if (bool(read_draw_data_flags & FLAGS_INSTANCING_HAS_CUSTOM_DATA)) {
		instance_custom.xy = unpackHalf2x16(instance_color_custom_data.z);
		instance_custom.zw = unpackHalf2x16(instance_color_custom_data.w);
	}
#endif // USE_INSTANCING

#else // USE_PRIMITIVE  (!USE_PRIMITIVE and !USE_ATTRIBUTES)

	vec2 vertex_base = vec2(0.0);
	int vertex_id = gl_VertexID % 4;
	vertex_base.x = float(vertex_id == 3 || vertex_id == 2);
	vertex_base.y = float(vertex_id == 1 || vertex_id == 2);

#if !defined(USE_REGION_TILE)
	vec2 uv = uv_rect.xy + abs(uv_rect.zw) * ((read_draw_data_flags & FLAGS_TRANSPOSE_RECT) != uint(0) ? vertex_base.yx : vertex_base.xy);
	//vec2 uv = uv_rect.xy + uv_rect.zw*vertex_base;
#else // !USE_REGION_TILE (USE_REGION_TILE)
	vec2 uv = abs(uv_rect.zw)*vertex_base;
#endif // USE_REGION_TILE

	vec4 color = read_draw_data_modulation;
	vec2 vertex = dst_rect.xy + dst_rect.zw * vertex_base;
	//vec2 vertex = dst_rect.xy + dst_rect.zw*vertex_base;


#endif // USE_PRIMITIVE

	mat4 model_matrix = mat4(vec4(read_draw_data_world_x, 0.0, 0.0), vec4(read_draw_data_world_y, 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0), vec4(read_draw_data_world_ofs, 0.0, 1.0));

#if defined(USE_INSTANCING)
	model_matrix = model_matrix * transpose(mat4(instance_xform0, instance_xform1, vec4(0.0, 0.0, 1.0, 0.0), vec4(0.0, 0.0, 0.0, 1.0)));
#endif // USE_INSTANCING

	vec2 color_texture_pixel_size = texpixel_size;

#if defined(USE_POINT_SIZE)
	float point_size = 1.0;
#endif // USE_POINT_SIZE

#if defined(USE_WORLD_VERTEX_COORDS)
	vertex = (model_matrix * vec4(vertex, 0.0, 1.0)).xy;
#endif // USE_WORLD_VERTEX_COORDS

	{
#CODE : VERTEX
	}


#if !defined(SKIP_TRANSFORM_USED) && !defined(USE_WORLD_VERTEX_COORDS)
	vertex = (model_matrix * vec4(vertex, 0.0, 1.0)).xy;
#endif // !SKIP_TRANSFORM_USED && !USE_WORLD_VERTEX_COORDS

	color_interp = color;

#if defined(PIXEL_SNAP)
	vertex = floor(vertex + 0.5);
	// precision issue on some hardware creates artifacts within texture
	// offset uv by a small amount to avoid
	uv += 1e-5;
#endif // PIXEL_SNAP

	vertex = (canvas_transform * vec4(vertex, 0.0, 1.0)).xy;

	vertex_interp = vertex;
	uv_interp = uv;

	gl_Position = screen_transform * vec4(vertex, 0.0, 1.0);

#if defined(USE_POINT_SIZE)
	gl_PointSize = point_size;
#endif // USE_POINT_SIZE
}

#[fragment]

#include "canvas_uniforms_inc.glsl"
#include "stdlib_inc.glsl"

in vec2 uv_interp;
in vec2 vertex_interp;
in vec4 color_interp;

#if !defined(USE_PRIMITIVE) && defined(USE_REGION_TILE)
flat in vec4 uv_repeat;
#endif // !USE_PRIMITIVE && USE_REGION_TILE

#if !defined(USE_PRIMITIVE) && defined(USE_MSDF)
flat in vec4 varying_C;
#define read_draw_data_msdf varying_C
#endif // USE_PRIMITIVE && USE_MSDF

uniform sampler2D main_texture; //texunit:0

#if defined(SCREEN_TEXTURE_USE)
uniform sampler2D backbuffer_texture; //texunit:-4
#endif // SCREEN_TEXTURE_USE

layout(location = 0) out vec4 frag_color;

/* clang-format off */
// This needs to be outside clang-format so the ubo comment is in the right place
#if defined(MATERIAL_UNIFORMS_USED)
layout(std140) uniform MaterialUniforms{ //ubo:4

#MATERIAL_UNIFORMS

};
#endif // MATERIAL_UNIFORMS_USED
/* clang-format on */

#GLOBALS

float msdf_median(float r, float g, float b, float a) {
	return min(max(min(r, g), min(max(r, g), b)), a);
}

void main() {
	vec4 color = color_interp;

#if !defined(USE_PRIMITIVE) && defined(USE_REGION_TILE)
	vec2 uv = uv_repeat.xy + fract(uv_interp)*uv_repeat.zw;
#else // USE_PRIMITIVE || !USE_REGION_TILE
	vec2 uv = uv_interp;
#endif // !USE_PRIMITIVE && USE_REGION_TILE

	vec2 vertex = vertex_interp;

#if !defined(FRAGMENT_CODE_USED) && (defined(USE_PRIMITIVE) || (!defined(USE_MSDF) && !defined(USE_LCD)))
	color *= texture(main_texture, uv);
#endif // !FRAGMENT_CODE_USED && (!USE_PRIMITIVE || (!USE_MSDF && !USE_LCD))

#if !defined(USE_PRIMITIVE)

#if defined(USE_MSDF)
	float px_range = read_draw_data_msdf.x;
	float outline_thickness = read_draw_data_msdf.y;

	vec4 msdf_sample = texture(main_texture, uv);
	vec2 msdf_size = vec2(textureSize(main_texture, 0));
	vec2 dest_size = vec2(1.0) / fwidth(uv);
	float px_size = max(0.5 * dot((vec2(px_range) / msdf_size), dest_size), 1.0);
	float d = msdf_median(msdf_sample.r, msdf_sample.g, msdf_sample.b, msdf_sample.a) - 0.5;

	if (outline_thickness > 0.0) {
		float cr = clamp(outline_thickness, 0.0, px_range / 2.0) / px_range;
		float a = clamp((d + cr) * px_size, 0.0, 1.0);
		color.a = a * color.a;
	} else {
		float a = clamp(d * px_size + 0.5, 0.0, 1.0);
		color.a = a * color.a;
	}
#elif defined(USE_LCD) // USE_MSDF (!USE_MSDF)
	vec4 lcd_sample = texture(main_texture, uv);
	if (lcd_sample.a == 1.0) {
		color.rgb = lcd_sample.rgb * color.a;
	} else {
		color = vec4(0.0, 0.0, 0.0, 0.0);
	}
#endif // USE_MSDF
#endif // !USE_PRIMITIVE


#if defined(SCREEN_UV_USED)
	vec2 screen_uv = gl_FragCoord.xy * screen_pixel_size;
#endif // SCREEN_UV_USED


	{

#CODE : FRAGMENT

	}
	
	frag_color = color;
}
