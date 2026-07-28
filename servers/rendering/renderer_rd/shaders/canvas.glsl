// ------------- VERTEX STAGE -------------

#[vertex]

#version 450

#VERSION_DEFINES

#ifdef USE_ATTRIBUTES
layout(location = 0) in vec2 vertex_attrib;
layout(location = 3) in vec4 color_attrib;
layout(location = 4) in vec2 uv_attrib;

#if defined(CUSTOM0_USED)
layout(location = 6) in vec4 custom0_attrib;
#endif

#if defined(CUSTOM1_USED)
layout(location = 7) in vec4 custom1_attrib;
#endif

layout(location = 10) in uvec4 bone_attrib;
layout(location = 11) in vec4 weight_attrib;

#endif

#include "canvas_uniforms_inc.glsl"

layout(location = 0) out vec4 uv_vertex_interp;
layout(location = 1) out vec4 color_interp;

#ifndef USE_ATTRIBUTES
// Varyings so the per-instance info can be used in the fragment shader
layout(location = 2) out flat vec4 varying_A;
layout(location = 3) out flat uvec4 varying_B;

#endif // !USE_ATTRIBUTES

#define read_draw_data_color_texture_pixel_size params.color_texture_pixel_size

#ifdef USE_ATTRIBUTES

#define read_draw_data_world_x params.world_x
#define read_draw_data_world_y params.world_y
#define read_draw_data_world_ofs params.world_ofs
#define read_draw_data_modulation params.modulation
#define read_draw_data_flags params.flags
#define read_draw_data_instance_offset params.instance_uniforms_ofs
#define read_draw_data_lights params.lights

#else // !USE_ATTRIBUTES

layout(location = 8) in vec4 attrib_A;
layout(location = 9) in vec4 attrib_B;
layout(location = 10) in vec4 attrib_C;
layout(location = 11) in vec4 attrib_D;
layout(location = 12) in vec4 attrib_E;
#ifdef USE_PRIMITIVE
layout(location = 13) in uvec4 attrib_F;
#else // !USE_PRIMITIVE
layout(location = 13) in vec4 attrib_F;
#endif // USE_PRIMITIVE
layout(location = 14) in uvec4 attrib_G;

#if !defined(USE_ATTRIBUTES) && !defined(USE_PRIMITIVE) && defined(USE_QUAD_REGION_TILE)
layout(location = 15) in vec4 attrib_H;
layout(location = 5) out vec4 uv_repeat;
#endif // !USE_ATTRIBUTES && !USE_PRIMITIVE && USE_QUAD_REGION_TILE

#define read_draw_data_world_x attrib_A.xy
#define read_draw_data_world_y attrib_A.zw
#define read_draw_data_world_ofs attrib_B.xy

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
#define read_draw_data_dst_rect attrib_E
#define read_draw_data_src_rect attrib_F

#endif // USE_PRIMITIVE

#define read_draw_data_flags attrib_G.z
#define read_draw_data_instance_offset attrib_G.w

#endif // USE_ATTRIBUTES

#ifdef MATERIAL_UNIFORMS_USED
/* clang-format off */
layout(set = 1, binding = 0, std140) uniform MaterialUniforms {
#MATERIAL_UNIFORMS
} material;
/* clang-format on */
#endif

#GLOBALS

#ifdef USE_ATTRIBUTES
vec3 srgb_to_linear(vec3 color) {
	return mix(pow((color.rgb + vec3(0.055)) * (1.0 / (1.0 + 0.055)), vec3(2.4)), color.rgb * (1.0 / 12.92), lessThan(color.rgb, vec3(0.04045)));
}
#endif

void main() {

#if !defined(USE_ATTRIBUTES) && !defined(USE_PRIMITIVE) && defined(USE_QUAD_REGION_TILE)
	uv_repeat.xy = read_draw_data_src_rect.xy;
	uv_repeat.zw = attrib_H.xy;
#endif // !USE_ATTRIBUTES && !USE_PRIMITIVE && USE_QUAD_REGION_TILE

#ifndef USE_ATTRIBUTES
	varying_A = vec4(read_draw_data_world_x, read_draw_data_world_y);
#ifdef USE_PRIMITIVE
	varying_B = uvec4(read_draw_data_flags, read_draw_data_instance_offset, 0.0, 0.0);
#else
	varying_B = uvec4(read_draw_data_flags, read_draw_data_instance_offset, packHalf2x16(read_draw_data_src_rect.xy), packHalf2x16(read_draw_data_src_rect.zw));
#endif
#endif // !USE_ATTRIBUTES

	vec4 instance_custom = vec4(0.0);
#if defined(CUSTOM0_USED)
	vec4 custom0 = vec4(0.0);
#endif
#if defined(CUSTOM1_USED)
	vec4 custom1 = vec4(0.0);
#endif

#ifdef USE_PRIMITIVE

	//weird bug,
	//this works
	vec2 vertex;
	vec2 uv;
	vec4 color;

	if (gl_VertexIndex == 0) {
		vertex = read_draw_data_point_a;
		uv = read_draw_data_uv_a;
		color = vec4(unpackHalf2x16(read_draw_data_color_a_rg), unpackHalf2x16(read_draw_data_color_a_ba));
	} else if (gl_VertexIndex == 1) {
		vertex = read_draw_data_point_b;
		uv = read_draw_data_uv_b;
		color = vec4(unpackHalf2x16(read_draw_data_color_b_rg), unpackHalf2x16(read_draw_data_color_b_ba));
	} else {
		vertex = read_draw_data_point_c;
		uv = read_draw_data_uv_c;
		color = vec4(unpackHalf2x16(read_draw_data_color_c_rg), unpackHalf2x16(read_draw_data_color_c_ba));
	}

	uvec4 bones = uvec4(0, 0, 0, 0);
	vec4 bone_weights = vec4(0.0);

#elif defined(USE_ATTRIBUTES)

	vec2 vertex = vertex_attrib;
	vec4 color = color_attrib;
	if (bool(canvas_data.flags & CANVAS_FLAGS_CONVERT_ATTRIBUTES_TO_LINEAR)) {
		color.rgb = srgb_to_linear(color.rgb);
	}
	color *= read_draw_data_modulation;
	vec2 uv = uv_attrib;

#if defined(CUSTOM0_USED)
	custom0 = custom0_attrib;
#endif

#if defined(CUSTOM1_USED)
	custom1 = custom1_attrib;
#endif

	uvec4 bones = bone_attrib;
	vec4 bone_weights = weight_attrib;
#else // !USE_ATTRIBUTES

	vec2 vertex_base = vec2(0.0);
	int vertex_id = gl_VertexIndex % 4;

	vertex_base.x = float(vertex_id == 3 || vertex_id == 2);
	vertex_base.y = float(vertex_id == 1 || vertex_id == 2);

#if !defined(USE_QUAD_REGION_TILE)
	vec2 uv = read_draw_data_src_rect.xy + abs(read_draw_data_src_rect.zw) * ((read_draw_data_flags & INSTANCE_FLAGS_TRANSPOSE_RECT) != 0 ? vertex_base.yx : vertex_base.xy);
#else // !USE_QUAD_REGION_TILE (USE_QUAD_REGION_TILE)
	vec2 uv = abs(read_draw_data_src_rect.zw)*vertex_base;
#endif // !USE_QUAD_REGION_TILE

	vec4 color = read_draw_data_modulation;
	vec2 vertex = read_draw_data_dst_rect.xy + read_draw_data_dst_rect.zw * vertex_base;
	uvec4 bones = uvec4(0, 0, 0, 0);

#endif // USE_ATTRIBUTES

	mat4 model_matrix = mat4(vec4(read_draw_data_world_x, 0.0, 0.0), vec4(read_draw_data_world_y, 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0), vec4(read_draw_data_world_ofs, 0.0, 1.0));

#ifdef USE_ATTRIBUTES

	uint instancing = params.batch_flags & BATCH_FLAGS_INSTANCING_MASK;

	if (instancing > 1) {
		// trails

		uint stride = 2 + 1 + 1; //particles always uses this format

		uint trail_size = instancing;

		uint offset = trail_size * stride * gl_InstanceIndex;

		vec4 pcolor;
		vec2 new_vertex;
		{
			uint boffset = offset + bone_attrib.x * stride;
			new_vertex = (vec4(vertex, 0.0, 1.0) * mat4(transforms.data[boffset + 0], transforms.data[boffset + 1], vec4(0.0, 0.0, 1.0, 0.0), vec4(0.0, 0.0, 0.0, 1.0))).xy * weight_attrib.x;
			pcolor = transforms.data[boffset + 2] * weight_attrib.x;
		}
		if (weight_attrib.y > 0.001) {
			uint boffset = offset + bone_attrib.y * stride;
			new_vertex += (vec4(vertex, 0.0, 1.0) * mat4(transforms.data[boffset + 0], transforms.data[boffset + 1], vec4(0.0, 0.0, 1.0, 0.0), vec4(0.0, 0.0, 0.0, 1.0))).xy * weight_attrib.y;
			pcolor += transforms.data[boffset + 2] * weight_attrib.y;
		}
		if (weight_attrib.z > 0.001) {
			uint boffset = offset + bone_attrib.z * stride;
			new_vertex += (vec4(vertex, 0.0, 1.0) * mat4(transforms.data[boffset + 0], transforms.data[boffset + 1], vec4(0.0, 0.0, 1.0, 0.0), vec4(0.0, 0.0, 0.0, 1.0))).xy * weight_attrib.z;
			pcolor += transforms.data[boffset + 2] * weight_attrib.z;
		}
		if (weight_attrib.w > 0.001) {
			uint boffset = offset + bone_attrib.w * stride;
			new_vertex += (vec4(vertex, 0.0, 1.0) * mat4(transforms.data[boffset + 0], transforms.data[boffset + 1], vec4(0.0, 0.0, 1.0, 0.0), vec4(0.0, 0.0, 0.0, 1.0))).xy * weight_attrib.w;
			pcolor += transforms.data[boffset + 2] * weight_attrib.w;
		}

		instance_custom = transforms.data[offset + 3];

		vertex = new_vertex;
		color *= pcolor;
	} else if (instancing == 1) {
		uint stride = 2 + bitfieldExtract(params.batch_flags, BATCH_FLAGS_INSTANCING_HAS_COLORS_SHIFT, 1) + bitfieldExtract(params.batch_flags, BATCH_FLAGS_INSTANCING_HAS_CUSTOM_DATA_SHIFT, 1);

		uint offset = stride * gl_InstanceIndex;

		mat4 matrix = mat4(transforms.data[offset + 0], transforms.data[offset + 1], vec4(0.0, 0.0, 1.0, 0.0), vec4(0.0, 0.0, 0.0, 1.0));
		offset += 2;

		if (bool(params.batch_flags & BATCH_FLAGS_INSTANCING_HAS_COLORS)) {
			color *= transforms.data[offset];
			offset += 1;
		}

		if (bool(params.batch_flags & BATCH_FLAGS_INSTANCING_HAS_CUSTOM_DATA)) {
			instance_custom = transforms.data[offset];
		}

		matrix = transpose(matrix);
		model_matrix = model_matrix * matrix;
	}
#endif // USE_ATTRIBUTES

	float point_size = 1.0;

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

	vertex = (canvas_data.canvas_transform * vec4(vertex, 0.0, 1.0)).xy;

	if (canvas_data.use_pixel_snap) {
		vertex = floor(vertex + 0.5);
		// precision issue on some hardware creates artifacts within texture
		// offset uv by a small amount to avoid
		uv += 1e-5;
	}

	uv_vertex_interp = vec4(uv, vertex);

	gl_Position = canvas_data.screen_transform * vec4(vertex, 0.0, 1.0);

#ifdef USE_POINT_SIZE
	gl_PointSize = point_size;
#endif
}

// ------------- FRAGMENT STAGE -------------

#[fragment]

#version 450

#VERSION_DEFINES

#include "canvas_uniforms_inc.glsl"

layout(location = 0) in vec4 uv_vertex_interp;
layout(location = 1) in vec4 color_interp;

#define read_draw_data_color_texture_pixel_size params.color_texture_pixel_size

#ifdef USE_ATTRIBUTES

#define read_draw_data_world_x params.world_x
#define read_draw_data_world_y params.world_y
#define read_draw_data_flags params.flags
#define read_draw_data_instance_offset params.instance_uniforms_ofs
#define read_draw_data_lights params.lights

#else // !USE_ATTRIBUTES

// Can all be flat as they are the same for the whole batched instance
layout(location = 2) in flat vec4 varying_A;

#define read_draw_data_world_x varying_A.xy
#define read_draw_data_world_y varying_A.zw

layout(location = 3) in flat uvec4 varying_B;
#define read_draw_data_flags varying_B.x
#define read_draw_data_instance_offset varying_B.y
#define read_draw_data_src_rect (varying_B.zw)
#endif // USE_ATTRIBUTES

#if !defined(USE_ATTRIBUTES) && !defined(USE_PRIMITIVE) && defined(USE_QUAD_REGION_TILE)
layout(location = 5) in vec4 uv_repeat;
#endif // !USE_ATTRIBUTES && !USE_PRIMITIVE && USE_QUAD_REGION_TILE


layout(location = 0) out vec4 frag_color;

#ifdef MATERIAL_UNIFORMS_USED
/* clang-format off */
layout(set = 1, binding = 0, std140) uniform MaterialUniforms {
#MATERIAL_UNIFORMS
} material;
/* clang-format on */
#endif

#GLOBALS

float msdf_median(float r, float g, float b) {
	return max(min(r, g), min(max(r, g), b));
}

void main() {
	vec4 color = color_interp;
	vec2 vertex = uv_vertex_interp.zw;

#if !defined(USE_ATTRIBUTES) && !defined(USE_PRIMITIVE) && defined(USE_QUAD_REGION_TILE)
	vec2 uv = uv_repeat.xy + fract(uv_vertex_interp.xy)*uv_repeat.zw;
#else // !USE_ATTRIBUTES && !USE_PRIMITIVE || !USE_QUAD_REGION_TILE
	vec2 uv = uv_vertex_interp.xy;
#endif // !USE_ATTRIBUTES && !USE_PRIMITIVE || !USE_QUAD_REGION_TILE

#if !defined(FRAGMENT_CODE_USED) && (defined(USE_ATTRIBUTES) || defined(USE_PRIMITIVE) || (!defined(USE_MSDF) && !defined(USE_LCD)))
	color *= texture(sampler2D(color_texture, texture_sampler), uv);
#endif

#if !defined(USE_ATTRIBUTES) && !defined(USE_PRIMITIVE)
	// only used by TYPE_RECT
	#if defined(USE_MSDF)
		float px_range = params.msdf.x;
		float outline_thickness = params.msdf.y;

		vec4 msdf_sample = texture(sampler2D(color_texture, texture_sampler), uv);
		vec2 msdf_size = vec2(textureSize(sampler2D(color_texture, texture_sampler), 0));
		vec2 dest_size = vec2(1.0) / fwidth(uv);
		float px_size = max(0.5 * dot((vec2(px_range) / msdf_size), dest_size), 1.0);
		float d = msdf_median(msdf_sample.r, msdf_sample.g, msdf_sample.b);

		if (outline_thickness > 0) {
			float cr = clamp(outline_thickness, 0.0, (px_range / 2.0) - 1.0) / px_range;
			d = min(d, msdf_sample.a);
			float a = clamp((d - 0.5 + cr) * px_size, 0.0, 1.0);
			color.a = a * color.a;
		} else {
			float a = clamp((d - 0.5) * px_size + 0.5, 0.0, 1.0);
			color.a = a * color.a;
		}
	#elif defined(USE_LCD)
		vec4 lcd_sample = texture(sampler2D(color_texture, texture_sampler), uv);
		if (lcd_sample.a == 1.0) {
			color.rgb = lcd_sample.rgb * color.a;
		} else {
			color = vec4(0.0, 0.0, 0.0, 0.0);
		}
	#endif
#endif


#if defined(SCREEN_UV_USED)
	vec2 screen_uv = gl_FragCoord.xy * canvas_data.screen_pixel_size;
#endif

#CODE : FRAGMENT

	frag_color = color;
}
