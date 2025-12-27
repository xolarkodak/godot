/**************************************************************************/
/*  texture_rect.cpp                                                      */
/**************************************************************************/
/*                         This file is part of:                          */
/*                             GODOT ENGINE                               */
/*                        https://godotengine.org                         */
/**************************************************************************/
/* Copyright (c) 2014-present Godot Engine contributors (see AUTHORS.md). */
/* Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.                  */
/*                                                                        */
/* Permission is hereby granted, free of charge, to any person obtaining  */
/* a copy of this software and associated documentation files (the        */
/* "Software"), to deal in the Software without restriction, including    */
/* without limitation the rights to use, copy, modify, merge, publish,    */
/* distribute, sublicense, and/or sell copies of the Software, and to     */
/* permit persons to whom the Software is furnished to do so, subject to  */
/* the following conditions:                                              */
/*                                                                        */
/* The above copyright notice and this permission notice shall be         */
/* included in all copies or substantial portions of the Software.        */
/*                                                                        */
/* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,        */
/* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF     */
/* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. */
/* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY   */
/* CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,   */
/* TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE      */
/* SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                 */
/**************************************************************************/

#include "texture_rect.h"

#include "servers/rendering_server.h"

void TextureRect::_notification(int p_what) {
	switch (p_what) {
		case NOTIFICATION_DRAW: {
			if (texture.is_null()) {
				return;
			}

			Vector2 texture_size = texture->get_size();
			Rect2 uv_rect, dst_rect;
			bool tile = false;

			switch (stretch_mode) {
				case STRETCH_SCALE: {
					dst_rect.size = get_size()*rect_scale;
					uv_rect.size = texture_size;
				} break;
				case STRETCH_TILE: {
					dst_rect.size = get_size();
					uv_rect.size = dst_rect.size;
					dst_rect.size *= rect_scale;
					tile = true;
				} break;
				case STRETCH_TILE_FIT: {
					dst_rect.size = get_size();
					uv_rect.size.x = dst_rect.size.x - Math::fmod(dst_rect.size.x, texture_size.x);
					uv_rect.size.y = dst_rect.size.y - Math::fmod(dst_rect.size.y, texture_size.y);
					dst_rect.size *= rect_scale;
					tile = true;
				} break;
				case STRETCH_KEEP: {
					dst_rect.size = texture_size*rect_scale;
					uv_rect.size = texture_size;
				} break;
				case STRETCH_KEEP_CENTERED: {
					dst_rect.size = texture_size*rect_scale;
					dst_rect.position = (get_size() - dst_rect.size) / 2.0f;
					uv_rect.size = texture_size;
				} break;
				case STRETCH_KEEP_ASPECT: {
					dst_rect.size = get_size();
					uv_rect.size = texture_size;
					int tex_x = texture_size.x * dst_rect.size.y / texture_size.y;
					int tex_y = dst_rect.size.y;

					if (tex_x > dst_rect.size.x) {
						tex_x = dst_rect.size.x;
						tex_y = texture_size.y * dst_rect.size.x / texture_size.x;
					}

					dst_rect.size.x = tex_x;
					dst_rect.size.y = tex_y;
				} break;
				case STRETCH_KEEP_ASPECT_CENTERED: {
					dst_rect.size = get_size()*rect_scale;
					uv_rect.size = texture_size;
					int tex_x = texture_size.x * dst_rect.size.y / texture_size.y;
					int tex_y = dst_rect.size.y;

					if (tex_x > dst_rect.size.x) {
						tex_x = dst_rect.size.x;
						tex_y = texture_size.y * dst_rect.size.x / texture_size.x;
					}

					dst_rect.position.x += (dst_rect.size.x - tex_x) / 2.0f;
					dst_rect.position.y += (dst_rect.size.y - tex_y) / 2.0f;

					dst_rect.size.x = tex_x;
					dst_rect.size.y = tex_y;
				} break;
				case STRETCH_KEEP_ASPECT_COVERED: {
					dst_rect.size = get_size()*rect_scale;

					Size2 scale_size(dst_rect.size.x / texture_size.width, dst_rect.size.y / texture_size.height);
					float scale = scale_size.width > scale_size.height ? scale_size.width : scale_size.height;
					Size2 scaled_tex_size = texture_size * scale;

					uv_rect.position = ((scaled_tex_size - dst_rect.size) / scale).abs() / 2.0f;
					uv_rect.size = dst_rect.size / scale;
				} break;
			}

			dst_rect.position += rect_offset;

			uv_rect.size.x *= hflip ? -1.0f : 1.0f;
			uv_rect.size.y *= vflip ? -1.0f : 1.0f;
			uv_rect.position += texture_offset;
			uv_rect.size *= texture_scale;

			draw_texture_rect_region(texture, dst_rect, uv_rect);

		} break;
		case NOTIFICATION_RESIZED: {
			update_minimum_size();
		} break;
	}
}

Size2 TextureRect::get_minimum_size() const {
	if (!texture.is_null()) {
		switch (expand_mode) {
			case EXPAND_KEEP_SIZE: {
				return texture->get_size();
			} break;
			case EXPAND_IGNORE_SIZE: {
				return Size2();
			} break;
			case EXPAND_FIT_WIDTH: {
				return Size2(get_size().y, 0);
			} break;
			case EXPAND_FIT_WIDTH_PROPORTIONAL: {
				real_t ratio = real_t(texture->get_width()) / texture->get_height();
				return Size2(get_size().y * ratio, 0);
			} break;
			case EXPAND_FIT_HEIGHT: {
				return Size2(0, get_size().x);
			} break;
			case EXPAND_FIT_HEIGHT_PROPORTIONAL: {
				real_t ratio = real_t(texture->get_height()) / texture->get_width();
				return Size2(0, get_size().x * ratio);
			} break;
		}
	}
	return Size2();
}

#ifndef DISABLE_DEPRECATED
bool TextureRect::_set(const StringName &p_name, const Variant &p_value) {
	if ((p_name == SNAME("expand") || p_name == SNAME("ignore_texture_size")) && p_value.operator bool()) {
		expand_mode = EXPAND_IGNORE_SIZE;
		return true;
	}
	return false;
}
#endif

void TextureRect::_texture_changed() {
	queue_redraw();
	update_minimum_size();
}

void TextureRect::set_texture(const Ref<Texture2D> &p_tex) {
	if (p_tex == texture) {
		return;
	}

	if (texture.is_valid()) {
		texture->disconnect_changed(callable_mp(this, &TextureRect::_texture_changed));
	}

	texture = p_tex;

	if (texture.is_valid()) {
		texture->connect_changed(callable_mp(this, &TextureRect::_texture_changed));
	}

	queue_redraw();
	update_minimum_size();
}

Ref<Texture2D> TextureRect::get_texture() const {
	return texture;
}

void TextureRect::set_texture_offset(const Vector2 &p_offset) {
	if (texture_offset == p_offset) {
		return;
	}

	texture_offset = p_offset;
	queue_redraw();
}

Vector2 TextureRect::get_texture_offset() const {
	return texture_offset;
}

void TextureRect::set_texture_scale(const Vector2 &p_scale) {
	if (texture_scale == p_scale) {
		return;
	}

	texture_scale = p_scale;
	queue_redraw();
}

Vector2 TextureRect::get_texture_scale() const {
	return texture_scale;
}

void TextureRect::set_rect_offset(const Vector2 &p_offset) {
	if (rect_offset == p_offset) {
		return;
	}

	rect_offset = p_offset;
	queue_redraw();
}

Vector2 TextureRect::get_rect_offset() const {
	return rect_offset;
}

void TextureRect::set_rect_scale(const Vector2 &p_scale) {
	if (rect_scale == p_scale) {
		return;
	}

	rect_scale = p_scale;
	queue_redraw();
}

Vector2 TextureRect::get_rect_scale() const {
	return rect_scale;
}

void TextureRect::set_expand_mode(ExpandMode p_mode) {
	if (expand_mode == p_mode) {
		return;
	}

	expand_mode = p_mode;
	queue_redraw();
	update_minimum_size();
}

TextureRect::ExpandMode TextureRect::get_expand_mode() const {
	return expand_mode;
}

void TextureRect::set_stretch_mode(StretchMode p_mode) {
	if (stretch_mode == p_mode) {
		return;
	}

	stretch_mode = p_mode;
	queue_redraw();
}

TextureRect::StretchMode TextureRect::get_stretch_mode() const {
	return stretch_mode;
}

void TextureRect::set_flip_h(bool p_flip) {
	if (hflip == p_flip) {
		return;
	}

	hflip = p_flip;
	queue_redraw();
}

bool TextureRect::is_flipped_h() const {
	return hflip;
}

void TextureRect::set_flip_v(bool p_flip) {
	if (vflip == p_flip) {
		return;
	}

	vflip = p_flip;
	queue_redraw();
}

bool TextureRect::is_flipped_v() const {
	return vflip;
}

void TextureRect::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_texture", "texture"), &TextureRect::set_texture);
	ClassDB::bind_method(D_METHOD("get_texture"), &TextureRect::get_texture);
	ClassDB::bind_method(D_METHOD("set_texture_offset", "offset"), &TextureRect::set_texture_offset);
	ClassDB::bind_method(D_METHOD("get_texture_offset"), &TextureRect::get_texture_offset);
	ClassDB::bind_method(D_METHOD("set_texture_scale", "scale"), &TextureRect::set_texture_scale);
	ClassDB::bind_method(D_METHOD("get_texture_scale"), &TextureRect::get_texture_scale);
	ClassDB::bind_method(D_METHOD("set_rect_offset", "offset"), &TextureRect::set_rect_offset);
	ClassDB::bind_method(D_METHOD("get_rect_offset"), &TextureRect::get_rect_offset);
	ClassDB::bind_method(D_METHOD("set_rect_scale", "scale"), &TextureRect::set_rect_scale);
	ClassDB::bind_method(D_METHOD("get_rect_scale"), &TextureRect::get_rect_scale);
	ClassDB::bind_method(D_METHOD("set_expand_mode", "expand_mode"), &TextureRect::set_expand_mode);
	ClassDB::bind_method(D_METHOD("get_expand_mode"), &TextureRect::get_expand_mode);
	ClassDB::bind_method(D_METHOD("set_flip_h", "enable"), &TextureRect::set_flip_h);
	ClassDB::bind_method(D_METHOD("is_flipped_h"), &TextureRect::is_flipped_h);
	ClassDB::bind_method(D_METHOD("set_flip_v", "enable"), &TextureRect::set_flip_v);
	ClassDB::bind_method(D_METHOD("is_flipped_v"), &TextureRect::is_flipped_v);
	ClassDB::bind_method(D_METHOD("set_stretch_mode", "stretch_mode"), &TextureRect::set_stretch_mode);
	ClassDB::bind_method(D_METHOD("get_stretch_mode"), &TextureRect::get_stretch_mode);

	ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "texture", PROPERTY_HINT_RESOURCE_TYPE, "Texture2D"), "set_texture", "get_texture");
	ADD_PROPERTY(PropertyInfo(Variant::INT, "expand_mode", PROPERTY_HINT_ENUM, "Keep Size,Ignore Size,Fit Width,Fit Width Proportional,Fit Height,Fit Height Proportional"), "set_expand_mode", "get_expand_mode");
	ADD_PROPERTY(PropertyInfo(Variant::INT, "stretch_mode", PROPERTY_HINT_ENUM, "Scale,Tile,Keep,Keep Centered,Keep Aspect,Keep Aspect Centered,Keep Aspect Covered,Tile Fit"), "set_stretch_mode", "get_stretch_mode");
	ADD_GROUP("Texture", "");
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR2, "texture_offset", PROPERTY_HINT_NONE, "suffix:px"), "set_texture_offset", "get_texture_offset");
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR2, "texture_scale", PROPERTY_HINT_LINK), "set_texture_scale", "get_texture_scale");
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "flip_h"), "set_flip_h", "is_flipped_h");
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "flip_v"), "set_flip_v", "is_flipped_v");
	ADD_GROUP("Rect", "");
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR2, "rect_offset", PROPERTY_HINT_NONE, "suffix:px"), "set_rect_offset", "get_rect_offset");
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR2, "rect_scale", PROPERTY_HINT_LINK), "set_rect_scale", "get_rect_scale");

	BIND_ENUM_CONSTANT(EXPAND_KEEP_SIZE);
	BIND_ENUM_CONSTANT(EXPAND_IGNORE_SIZE);
	BIND_ENUM_CONSTANT(EXPAND_FIT_WIDTH);
	BIND_ENUM_CONSTANT(EXPAND_FIT_WIDTH_PROPORTIONAL);
	BIND_ENUM_CONSTANT(EXPAND_FIT_HEIGHT);
	BIND_ENUM_CONSTANT(EXPAND_FIT_HEIGHT_PROPORTIONAL);

	BIND_ENUM_CONSTANT(STRETCH_SCALE);
	BIND_ENUM_CONSTANT(STRETCH_TILE);
	BIND_ENUM_CONSTANT(STRETCH_KEEP);
	BIND_ENUM_CONSTANT(STRETCH_KEEP_CENTERED);
	BIND_ENUM_CONSTANT(STRETCH_KEEP_ASPECT);
	BIND_ENUM_CONSTANT(STRETCH_KEEP_ASPECT_CENTERED);
	BIND_ENUM_CONSTANT(STRETCH_KEEP_ASPECT_COVERED);
	BIND_ENUM_CONSTANT(STRETCH_TILE_FIT);
}

TextureRect::TextureRect() {
	set_mouse_filter(MOUSE_FILTER_PASS);
}

TextureRect::~TextureRect() {
}
