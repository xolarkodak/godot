/* clang-format off */
#[modes]

mode_default =

#[specializations]

USE_PRIMITIVE = false   // spec: 1  << 0
USE_ATTRIBUTES = false  // spec: 2  << 1
USE_INSTANCING = false  // spec: 4  << 2
USE_REGION_TILE = false // spec: 8  << 3
PIXEL_SNAP = false      // spec: 16  << 4
USE_MSDF = false        // spec: 32  << 5
USE_LCD = false         // spec: 64  << 6

// ------------- VERTEX STAGE -------------

#[vertex]

#ifdef USE_ATTRIBUTES
layout(location = 0) in vec2 vertex_attrib;
layout(location = 3) in vec4 color_attrib;
layout(location = 4) in vec2 uv_attrib;
#endif // USE_ATTRIBUTES

#if defined(USE_ATTRIBUTES) && defined(USE_INSTANCING)
layout(location = 1) in highp vec4 instance_xform0;
layout(location = 2) in highp vec4 instance_xform1;
layout(location = 5) in highp uvec4 instance_color_custom_data; // Color packed into xy, custom_data packed into zw for compatibility with 3D
#endif // USE_ATTRIBUTES && USE_INSTANCING

#include "stdlib_inc.glsl"

#if defined(CUSTOM0_USED)
layout(location = 6) in highp vec4 custom0_attrib;
#endif

#if defined(CUSTOM1_USED)
layout(location = 7) in highp vec4 custom1_attrib;
#endif

layout(location = 8) in highp vec4 attrib_A;
layout(location = 9) in highp vec4 attrib_B;
layout(location = 10) in highp vec4 attrib_C;
layout(location = 11) in highp vec4 attrib_D;
layout(location = 12) in highp vec4 attrib_E;

#ifdef USE_PRIMITIVE
layout(location = 13) in highp uvec4 attrib_F;
#else
layout(location = 13) in highp vec4 attrib_F;
#endif

layout(location = 14) in highp uvec4 attrib_G;

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

#else // USE_PRIMITIVE

#define read_draw_data_modulation attrib_C
#define read_draw_data_msdf attrib_D
#define dst_rect attrib_E
#define uv_rect attrib_F

#endif // USE_PRIMITIVE

#define read_draw_data_flags attrib_G.z
#define read_draw_data_instance_offset attrib_G.w

// Varyings so the per-instance info can be used in the fragment shader
flat out vec2 varying_B;
#ifndef USE_PRIMITIVE
flat out vec4 varying_C;
#endif
flat out uvec2 varying_F;

// IN-OUT for Region Tile
#if !defined(USE_ATTRIBUTES) && !defined(USE_PRIMITIVE) && defined(USE_REGION_TILE)
layout(location = 15) in highp vec4 attrib_H;
flat out vec4 uv_repeat;
#endif // !USE_ATTRIBUTES && !USE_PRIMITIVE && USE_REGION_TILE

// This needs to be outside clang-format so the ubo comment is in the right place
#ifdef MATERIAL_UNIFORMS_USED
layout(std140) uniform MaterialUniforms{ //ubo:4

#MATERIAL_UNIFORMS

};
#endif

/* clang-format on */
#include "canvas_uniforms_inc.glsl"

uniform mediump uint batch_flags;

out vec2 uv_interp;
out vec2 vertex_interp;
out vec4 color_interp;

#GLOBALS

void main() {
	vec4 instance_custom = vec4(0.0);

	varying_B = texpixel_size;
	varying_F = uvec2(read_draw_data_flags, read_draw_data_instance_offset);

#if !defined(USE_ATTRIBUTES) && !defined(USE_PRIMITIVE) && defined(USE_REGION_TILE)
	uv_repeat.xy = uv_rect.xy;
	uv_repeat.zw = attrib_H.xy;
#endif // !USE_ATTRIBUTES && !USE_PRIMITIVE && USE_REGION_TILE

#if !defined(USE_ATTRIBUTES) && !defined(USE_PRIMITIVE) && defined(USE_MSDF)
	varying_C = read_draw_data_msdf;
#endif // !USE_ATTRIBUTES && !USE_PRIMITIVE && USE_MSDF

#if defined(CUSTOM0_USED)
	vec4 custom0 = vec4(0.0);
#endif

#if defined(CUSTOM1_USED)
	vec4 custom1 = vec4(0.0);
#endif

#ifdef USE_PRIMITIVE
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

#elif defined(USE_ATTRIBUTES)
	vec2 vertex = vertex_attrib;
	vec4 color = color_attrib * read_draw_data_modulation;
	vec2 uv = uv_attrib;

#ifdef USE_INSTANCING
	if (bool(batch_flags & BATCH_FLAGS_INSTANCING_HAS_COLORS)) {
		vec4 instance_color;
		instance_color.xy = unpackHalf2x16(uint(instance_color_custom_data.x));
		instance_color.zw = unpackHalf2x16(uint(instance_color_custom_data.y));
		color *= instance_color;
	}
	if (bool(batch_flags & BATCH_FLAGS_INSTANCING_HAS_CUSTOM_DATA)) {
		instance_custom.xy = unpackHalf2x16(instance_color_custom_data.z);
		instance_custom.zw = unpackHalf2x16(instance_color_custom_data.w);
	}
#endif // USE_INSTANCING

#else // USE_ATTRIBUTES (!USE_PRIMITIVE and !USE_ATTRIBUTES)

	vec2 vertex_base = vec2(0.0);
	int vertex_id = gl_VertexID % 4;

	vertex_base.x = float(vertex_id == 3 || vertex_id == 2);
	vertex_base.y = float(vertex_id == 1 || vertex_id == 2);

#if !defined(USE_REGION_TILE)
	vec2 uv = uv_rect.xy + abs(uv_rect.zw) * ((read_draw_data_flags & INSTANCE_FLAGS_TRANSPOSE_RECT) != uint(0) ? vertex_base.yx : vertex_base.xy);
	//vec2 uv = uv_rect.xy + uv_rect.zw*vertex_base;
#else // !USE_REGION_TILE (USE_REGION_TILE)
	vec2 uv = abs(uv_rect.zw)*vertex_base;
#endif // !USE_REGION_TILE

	vec4 color = read_draw_data_modulation;
	vec2 vertex = dst_rect.xy + dst_rect.zw * vertex_base;
	//vec2 vertex = read_draw_data_dst_rect.xy + abs(read_draw_data_dst_rect.zw) * mix(vertex_base, vec2(1.0, 1.0) - vertex_base, lessThan(uv_rect.zw, vec2(0.0, 0.0)));

#endif // USE_ATTRIBUTES

#if defined(CUSTOM0_USED)
	custom0 = custom0_attrib;
#endif

#if defined(CUSTOM1_USED)
	custom1 = custom1_attrib;
#endif

	mat4 model_matrix = mat4(vec4(read_draw_data_world_x, 0.0, 0.0), vec4(read_draw_data_world_y, 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0), vec4(read_draw_data_world_ofs, 0.0, 1.0));

#ifdef USE_INSTANCING
	model_matrix = model_matrix * transpose(mat4(instance_xform0, instance_xform1, vec4(0.0, 0.0, 1.0, 0.0), vec4(0.0, 0.0, 0.0, 1.0)));
#endif // USE_INSTANCING

	vec2 color_texture_pixel_size = texpixel_size;

#ifdef USE_POINT_SIZE
	float point_size = 1.0;
#endif

#ifdef USE_WORLD_VERTEX_COORDS
	vertex = (model_matrix * vec4(vertex, 0.0, 1.0)).xy;
#endif

	{
#CODE : VERTEX
	}

#if !defined(SKIP_TRANSFORM_USED) && !defined(USE_WORLD_VERTEX_COORDS)
	vertex = (model_matrix * vec4(vertex, 0.0, 1.0)).xy;
#endif

	color_interp = color;

	vertex = (canvas_transform * vec4(vertex, 0.0, 1.0)).xy;

	#if defined(PIXEL_SNAP)
	vertex = floor(vertex + 0.5);
	// precision issue on some hardware creates artifacts within texture
	// offset uv by a small amount to avoid
	uv += 1e-5;
	#endif // PIXEL_SNAP

	vertex_interp = vertex;
	uv_interp = uv;

	gl_Position = screen_transform * vec4(vertex, 0.0, 1.0);

#ifdef USE_POINT_SIZE
	gl_PointSize = point_size;
#endif
}

// ------------- FRAGMENT STAGE -------------

#[fragment]

#include "canvas_uniforms_inc.glsl"
#include "stdlib_inc.glsl"

in vec2 uv_interp;
in vec2 vertex_interp;
in vec4 color_interp;

// Can all be flat as they are the same for the whole batched instance
flat in vec2 varying_B;
#define texpixel_size varying_B

// INPUT Region TILE data
#if !defined(USE_ATTRIBUTES) && !defined(USE_PRIMITIVE) && defined(USE_REGION_TILE)
flat in vec4 uv_repeat;
#endif // !USE_ATTRIBUTES && !USE_PRIMITIVE && USE_REGION_TILE

// INPUT MSDF data
#if !defined(USE_ATTRIBUTES) && !defined(USE_PRIMITIVE) && defined(USE_MSDF)
flat in vec4 varying_C;
#define read_draw_data_msdf varying_C
#endif // !USE_ATTRIBUTES && !USE_PRIMITIVE && USE_REGION_TILE

flat in uvec2 varying_F;
#define read_draw_data_flags varying_F.x
#define read_draw_data_instance_offset varying_F.y

uniform sampler2D main_texture; //texunit:0

#if defined(SCREEN_TEXTURE_USE)
uniform sampler2D backbuffer_texture; //texunit:-4
#endif // SCREEN_TEXTURE_USE

layout(location = 0) out vec4 frag_color;

/* clang-format off */
// This needs to be outside clang-format so the ubo comment is in the right place
#ifdef MATERIAL_UNIFORMS_USED
layout(std140) uniform MaterialUniforms{ //ubo:4

#MATERIAL_UNIFORMS

};
#endif
/* clang-format on */

#GLOBALS

float msdf_median(float r, float g, float b) {
	return max(min(r, g), min(max(r, g), b));
}

void main() {
	vec4 color = color_interp;
	vec2 vertex = vertex_interp;

#if !defined(USE_ATTRIBUTES) && !defined(USE_PRIMITIVE) && defined(USE_REGION_TILE)
	vec2 uv = uv_repeat.xy + fract(uv_interp)*uv_repeat.zw;
#else // !USE_ATTRIBUTES && !USE_PRIMITIVE || !USE_REGION_TILE
	vec2 uv = uv_interp;
#endif // !USE_ATTRIBUTES && !USE_PRIMITIVE || !USE_REGION_TILE

#if !defined(FRAGMENT_CODE_USED) && (defined(USE_ATTRIBUTES) || defined(USE_PRIMITIVE) || (!defined(USE_MSDF) && !defined(USE_LCD)))
	color *= texture(main_texture, uv);
#endif

#if !defined(USE_ATTRIBUTES) && !defined(USE_PRIMITIVE)
	// only used by TYPE_RECT
	#if defined(USE_MSDF)
		float px_range = read_draw_data_msdf.x;
		float outline_thickness = read_draw_data_msdf.y;

		vec4 msdf_sample = texture(main_texture, uv);
		vec2 msdf_size = vec2(textureSize(main_texture, 0));
		vec2 dest_size = vec2(1.0) / fwidth(uv);
		float px_size = max(0.5 * dot((vec2(px_range) / msdf_size), dest_size), 1.0);
		float d = msdf_median(msdf_sample.r, msdf_sample.g, msdf_sample.b);

		if (outline_thickness > 0.0) {
			float cr = clamp(outline_thickness, 0.0, (px_range / 2.0) - 1.0) / px_range;
			d = min(d, msdf_sample.a);
			float a = clamp((d - 0.5 + cr) * px_size, 0.0, 1.0);
			color.a = a * color.a;
		} else {
			float a = clamp((d - 0.5) * px_size + 0.5, 0.0, 1.0);
			color.a = a * color.a;
		}
	#elif defined(USE_LCD)
		vec4 lcd_sample = texture(main_texture, uv);
		if (lcd_sample.a == 1.0) {
			color.rgb = lcd_sample.rgb * color.a;
		} else {
			color = vec4(0.0, 0.0, 0.0, 0.0);
		}
	#endif
#endif // !USE_ATTRIBUTES && !USE_PRIMITIVE

#if defined(SCREEN_UV_USED)
	vec2 screen_uv = gl_FragCoord.xy * screen_pixel_size;
#endif

	//vec2 color_texture_pixel_size = texpixel_size.xy;

#CODE : FRAGMENT

	frag_color = color;
}
