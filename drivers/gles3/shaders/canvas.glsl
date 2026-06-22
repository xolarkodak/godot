/* clang-format off */
#[modes]

mode_default =

#[specializations]

USE_PRIMITIVE = false   // spec: 1  << 0
USE_ATTRIBUTES = false  // spec: 2  << 1
USE_INSTANCING = false  // spec: 4  << 2
USE_NINEPATCH = false   // spec: 8  << 3
PIXEL_SNAP = false      // spec: 16  << 4
USE_MSDF = false        // spec: 32  << 5
USE_LCD = false         // spec: 64  << 6
// USE_REGION_TILE = false // spec: 128  << 7

// ------------- VERTEX STAGE -------------

#[vertex]

#ifdef USE_ATTRIBUTES
layout(location = 0) in vec2 vertex_attrib;
layout(location = 3) in vec4 color_attrib;
layout(location = 4) in vec2 uv_attrib;

#ifdef USE_INSTANCING

layout(location = 1) in highp vec4 instance_xform0;
layout(location = 2) in highp vec4 instance_xform1;
layout(location = 5) in highp uvec4 instance_color_custom_data; // Color packed into xy, custom_data packed into zw for compatibility with 3D

#endif // USE_INSTANCING

#endif // USE_ATTRIBUTES

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
layout(location = 15) in highp uvec4 attrib_H;

#define read_draw_data_world_x attrib_A.xy
#define read_draw_data_world_y attrib_A.zw
#define read_draw_data_world_ofs attrib_B.xy
#define read_draw_data_color_texture_pixel_size attrib_B.zw

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

#else

#define read_draw_data_modulation attrib_C
#define read_draw_data_ninepatch_margins attrib_D
#define read_draw_data_dst_rect attrib_E
#define read_draw_data_src_rect attrib_F

#endif

#define read_draw_data_flags attrib_G.z
#define read_draw_data_instance_offset attrib_G.w
#define read_draw_data_lights attrib_H

// Varyings so the per-instance info can be used in the fragment shader
flat out vec4 varying_A;
flat out vec2 varying_B;
#ifndef USE_PRIMITIVE
flat out vec4 varying_C;
#ifndef USE_ATTRIBUTES
#ifdef USE_NINEPATCH

flat out vec2 varying_D;
#endif
flat out vec4 varying_E;
#endif
#endif
flat out uvec2 varying_F;
flat out uvec4 varying_G;

// This needs to be outside clang-format so the ubo comment is in the right place
#ifdef MATERIAL_UNIFORMS_USED
layout(std140) uniform MaterialUniforms{ //ubo:4

#MATERIAL_UNIFORMS

};
#endif

uniform mediump uint batch_flags;

/* clang-format on */
#include "canvas_uniforms_inc.glsl"

out vec2 uv_interp;
out vec4 color_interp;
out vec2 vertex_interp;

#ifdef USE_NINEPATCH

out vec2 pixel_size_interp;

#endif

#GLOBALS

void main() {
	varying_A = vec4(read_draw_data_world_x, read_draw_data_world_y);
	varying_B = read_draw_data_color_texture_pixel_size;
#ifndef USE_PRIMITIVE
	varying_C = read_draw_data_ninepatch_margins;

#ifndef USE_ATTRIBUTES
#ifdef USE_NINEPATCH
	varying_D = vec2(read_draw_data_dst_rect.z, read_draw_data_dst_rect.w);
#endif // USE_NINEPATCH
	varying_E = read_draw_data_src_rect;
#endif // !USE_ATTRIBUTES
#endif // USE_PRIMITIVE

	varying_F = uvec2(read_draw_data_flags, read_draw_data_instance_offset);
	varying_G = read_draw_data_lights;

	vec4 instance_custom = vec4(0.0);

#if defined(CUSTOM0_USED)
	vec4 custom0 = vec4(0.0);
#endif
#if defined(CUSTOM1_USED)
	vec4 custom1 = vec4(0.0);
#endif

#ifdef USE_PRIMITIVE
	vec2 vertex;
	vec2 uv;
	vec4 color;

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
#endif // !USE_INSTANCING

#else // !USE_ATTRIBUTES

	// crash on Adreno 320/330
	//vec2 vertex_base_arr[6] = vec2[](vec2(0.0, 0.0), vec2(0.0, 1.0), vec2(1.0, 1.0), vec2(1.0, 0.0), vec2(0.0, 0.0), vec2(1.0, 1.0));
	//vec2 vertex_base = vertex_base_arr[gl_VertexID % 6];
	//-----------------------------------------
	// ID |  0  |  1  |  2  |  3  |  4  |  5  |
	//-----------------------------------------
	// X  | 0.0 | 0.0 | 1.0 | 1.0 | 0.0 | 1.0 |
	// Y  | 0.0 | 1.0 | 1.0 | 0.0 | 0.0 | 1.0 |
	//-----------------------------------------
	// no crash or freeze on all Adreno 3xx	with 'if / else if' and slightly faster!
	int vertex_id = gl_VertexID % 6;
	vec2 vertex_base;
	if (vertex_id == 0) {
		vertex_base = vec2(0.0, 0.0);
	} else if (vertex_id == 1) {
		vertex_base = vec2(0.0, 1.0);
	} else if (vertex_id == 2) {
		vertex_base = vec2(1.0, 1.0);
	} else if (vertex_id == 3) {
		vertex_base = vec2(1.0, 0.0);
	} else if (vertex_id == 4) {
		vertex_base = vec2(0.0, 0.0);
	} else if (vertex_id == 5) {
		vertex_base = vec2(1.0, 1.0);
	}

	vec2 uv = read_draw_data_src_rect.xy + abs(read_draw_data_src_rect.zw) * ((read_draw_data_flags & INSTANCE_FLAGS_TRANSPOSE_RECT) != uint(0) ? vertex_base.yx : vertex_base.xy);
	vec4 color = read_draw_data_modulation;
	vec2 vertex = read_draw_data_dst_rect.xy + abs(read_draw_data_dst_rect.zw) * mix(vertex_base, vec2(1.0, 1.0) - vertex_base, lessThan(read_draw_data_src_rect.zw, vec2(0.0, 0.0)));

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

	vec2 color_texture_pixel_size = read_draw_data_color_texture_pixel_size;

#ifdef USE_POINT_SIZE
	float point_size = 1.0;
#endif

#ifdef USE_WORLD_VERTEX_COORDS
	vertex = (model_matrix * vec4(vertex, 0.0, 1.0)).xy;
#endif
	{
#CODE : VERTEX
	}

#ifdef USE_NINEPATCH
	pixel_size_interp = abs(read_draw_data_dst_rect.zw) * vertex_base;
#endif

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

#ifdef USE_NINEPATCH

in vec2 pixel_size_interp;

#endif

// Can all be flat as they are the same for the whole batched instance
flat in vec4 varying_A;
flat in vec2 varying_B;
#define read_draw_data_world_x varying_A.xy
#define read_draw_data_world_y varying_A.zw
#define read_draw_data_color_texture_pixel_size varying_B

#ifndef USE_PRIMITIVE
flat in vec4 varying_C;
#define read_draw_data_ninepatch_margins varying_C

#ifndef USE_ATTRIBUTES
#ifdef USE_NINEPATCH

flat in vec2 varying_D;
#define read_draw_data_dst_rect_z varying_D.x
#define read_draw_data_dst_rect_w varying_D.y
#endif

flat in vec4 varying_E;
#define read_draw_data_src_rect varying_E
#endif // USE_ATTRIBUTES
#endif // USE_PRIMITIVE

flat in uvec2 varying_F;
flat in uvec4 varying_G;
#define read_draw_data_flags varying_F.x
#define read_draw_data_instance_offset varying_F.y
#define read_draw_data_lights varying_G

uniform sampler2D color_buffer; //texunit:-4
uniform sampler2D main_texture; //texunit:0

uniform mediump uint batch_flags;
uniform highp uint specular_shininess_in;

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

#ifdef USE_NINEPATCH

float map_ninepatch_axis(float pixel, float draw_size, float tex_pixel_size, float margin_begin, float margin_end, int np_repeat, inout int draw_center) {
	float tex_size = 1.0 / tex_pixel_size;

	if (pixel < margin_begin) {
		return pixel * tex_pixel_size;
	} else if (pixel >= draw_size - margin_end) {
		return (tex_size - (draw_size - pixel)) * tex_pixel_size;
	} else {
		if (!bool(read_draw_data_flags & INSTANCE_FLAGS_NINEPATCH_DRAW_CENTER)) {
			draw_center--;
		}

		// np_repeat is passed as uniform using NinePatchRect::AxisStretchMode enum.
		if (np_repeat == 0) { // Stretch.
			// Convert to ratio.
			float ratio = (pixel - margin_begin) / (draw_size - margin_begin - margin_end);
			// Scale to source texture.
			return (margin_begin + ratio * (tex_size - margin_begin - margin_end)) * tex_pixel_size;
		} else if (np_repeat == 1) { // Tile.
			// Convert to offset.
			float ofs = mod((pixel - margin_begin), tex_size - margin_begin - margin_end);
			// Scale to source texture.
			return (margin_begin + ofs) * tex_pixel_size;
		} else if (np_repeat == 2) { // Tile Fit.
			// Calculate scale.
			float src_area = draw_size - margin_begin - margin_end;
			float dst_area = tex_size - margin_begin - margin_end;
			float scale = max(1.0, floor(src_area / max(dst_area, 0.0000001) + 0.5));
			// Convert to ratio.
			float ratio = (pixel - margin_begin) / src_area;
			ratio = mod(ratio * scale, 1.0);
			// Scale to source texture.
			return (margin_begin + ratio * dst_area) * tex_pixel_size;
		} else { // Shouldn't happen, but silences compiler warning.
			return 0.0;
		}
	}
}

#endif

float msdf_median(float r, float g, float b) {
	return max(min(r, g), min(max(r, g), b));
}

void main() {
	vec4 color = color_interp;
	vec2 uv = uv_interp;
	vec2 vertex = vertex_interp;

#if !defined(USE_ATTRIBUTES) && !defined(USE_PRIMITIVE) && defined(USE_NINEPATCH)
	int draw_center = 2;
	uv = vec2(
			map_ninepatch_axis(pixel_size_interp.x, abs(read_draw_data_dst_rect_z), read_draw_data_color_texture_pixel_size.x, read_draw_data_ninepatch_margins.x, read_draw_data_ninepatch_margins.z, int(read_draw_data_flags >> INSTANCE_FLAGS_NINEPATCH_H_MODE_SHIFT) & 0x3, draw_center),
			map_ninepatch_axis(pixel_size_interp.y, abs(read_draw_data_dst_rect_w), read_draw_data_color_texture_pixel_size.y, read_draw_data_ninepatch_margins.y, read_draw_data_ninepatch_margins.w, int(read_draw_data_flags >> INSTANCE_FLAGS_NINEPATCH_V_MODE_SHIFT) & 0x3, draw_center));

	if (draw_center == 0) {
		color.a = 0.0;
	}

	uv = uv * read_draw_data_src_rect.zw + read_draw_data_src_rect.xy; //apply region if needed
#endif

#if !defined(FRAGMENT_CODE_USED) && (defined(USE_ATTRIBUTES) || defined(USE_PRIMITIVE) || (!defined(USE_MSDF) && !defined(USE_LCD)))
	color *= texture(main_texture, uv);
#endif


#if !defined(USE_ATTRIBUTES) && !defined(USE_PRIMITIVE)
	// only used by TYPE_RECT
	#if defined(USE_MSDF)
		float px_range = read_draw_data_ninepatch_margins.x;
		float outline_thickness = read_draw_data_ninepatch_margins.y;

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

#CODE : FRAGMENT

	frag_color = color;
}
