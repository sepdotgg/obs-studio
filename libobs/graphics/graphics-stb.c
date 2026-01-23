/******************************************************************************
    Copyright (C) 2023 by Lain Bailey <lain@obsproject.com>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
******************************************************************************/

/*
 * stb_image-based image loading implementation.
 *
 * Supported formats: PNG, JPEG, BMP, TGA, PSD, GIF (static), HDR, PIC, PNM
 */

#include "graphics.h"
#include "srgb.h"

#include <util/base.h>
#include <util/platform.h>

#define STB_IMAGE_IMPLEMENTATION
#define STBI_NO_STDIO
#define STBI_MALLOC(sz)        bmalloc(sz)
#define STBI_REALLOC(p, newsz) brealloc(p, newsz)
#define STBI_FREE(p)           bfree(p)
#include "stb_image.h"

void gs_init_image_deps(void)
{
}

void gs_free_image_deps(void)
{
}

/*
 * Load file into memory buffer.
 * Returns NULL on failure, sets *out_size to file size on success.
 */
static uint8_t *load_file_to_buffer(const char *file, size_t *out_size)
{
	FILE *f = os_fopen(file, "rb");
	if (!f) {
		blog(LOG_WARNING, "stb_image: Failed to open file '%s'", file);
		return NULL;
	}

	fseek(f, 0, SEEK_END);
	long file_size = ftell(f);
	fseek(f, 0, SEEK_SET);

	if (file_size <= 0) {
		blog(LOG_WARNING, "stb_image: Invalid file size for '%s'", file);
		fclose(f);
		return NULL;
	}

	uint8_t *buffer = bmalloc((size_t)file_size);
	if (!buffer) {
		blog(LOG_WARNING, "stb_image: Failed to allocate buffer for '%s'", file);
		fclose(f);
		return NULL;
	}

	size_t bytes_read = fread(buffer, 1, (size_t)file_size, f);
	fclose(f);

	if (bytes_read != (size_t)file_size) {
		blog(LOG_WARNING, "stb_image: Failed to read file '%s' (read %zu of %ld bytes)",
		     file, bytes_read, file_size);
		bfree(buffer);
		return NULL;
	}

	*out_size = (size_t)file_size;
	return buffer;
}

/*
 * Apply alpha premultiplication to RGBA data.
 * stb_image always outputs RGBA when we request 4 channels.
 */
static void apply_alpha_premultiply(uint8_t *data, uint32_t cx, uint32_t cy,
				    enum gs_image_alpha_mode alpha_mode)
{
	if (alpha_mode == GS_IMAGE_ALPHA_STRAIGHT)
		return;

	size_t texel_count = (size_t)cx * cy;

	if (alpha_mode == GS_IMAGE_ALPHA_PREMULTIPLY_SRGB) {
		gs_premultiply_xyza_srgb_loop(data, texel_count);
	} else if (alpha_mode == GS_IMAGE_ALPHA_PREMULTIPLY) {
		gs_premultiply_xyza_loop(data, texel_count);
	}
}

/*
 * Convert RGBA (stb) to BGRA (OBS)
 */
static void rgba_to_bgra(uint8_t *data, uint32_t cx, uint32_t cy)
{
	size_t texel_count = (size_t)cx * cy;
	uint8_t *p = data;

	for (size_t i = 0; i < texel_count; i++) {
		uint8_t r = p[0];
		uint8_t b = p[2];
		p[0] = b;
		p[2] = r;
		p += 4;
	}
}

/*
 * Internal implementation that loads image data using stb_image.
 * Returns pixel data allocated with bmalloc, caller must free with bfree.
 */
static uint8_t *stb_image_load_internal(const char *file,
					enum gs_image_alpha_mode alpha_mode,
					enum gs_color_format *format,
					uint32_t *cx_out, uint32_t *cy_out,
					enum gs_color_space *space)
{
	if (!file || !*file)
		return NULL;

	/* Load file into memory */
	size_t file_size = 0;
	uint8_t *file_buffer = load_file_to_buffer(file, &file_size);
	if (!file_buffer)
		return NULL;

	/* Decode image with stb_image */
	int width = 0, height = 0, channels = 0;
	
	/* Always request 4 channels (RGBA) for consistency */
	uint8_t *stb_data = stbi_load_from_memory(file_buffer, (int)file_size,
						  &width, &height, &channels, 4);
	
	/* Free file buffer - no longer needed */
	bfree(file_buffer);

	if (!stb_data) {
		blog(LOG_WARNING, "stb_image: Failed to decode '%s': %s",
		     file, stbi_failure_reason());
		return NULL;
	}

	/* Validate dimensions */
	if (width <= 0 || height <= 0 || width > 32768 || height > 32768) {
		blog(LOG_WARNING, "stb_image: Invalid dimensions %dx%d for '%s'",
		     width, height, file);
		stbi_image_free(stb_data);
		return NULL;
	}

	/* stb_image allocated with our bmalloc via STBI_MALLOC, so we can use it directly */
	uint8_t *data = stb_data;
	uint32_t cx = (uint32_t)width;
	uint32_t cy = (uint32_t)height;

	/* Apply alpha premultiplication if requested (do this before RGBA->BGRA conversion) */
	apply_alpha_premultiply(data, cx, cy, alpha_mode);

	/* Convert RGBA to BGRA for OBS */
	rgba_to_bgra(data, cx, cy);

	/* Set output parameters */
	*format = GS_BGRA;
	*cx_out = cx;
	*cy_out = cy;
	*space = GS_CS_SRGB;

	return data;
}

/*
 * Stub graphics-ffmpeg.c
 */

uint8_t *gs_create_texture_file_data(const char *file, enum gs_color_format *format,
				     uint32_t *cx_out, uint32_t *cy_out)
{
	enum gs_color_space unused;
	return stb_image_load_internal(file, GS_IMAGE_ALPHA_STRAIGHT,
				       format, cx_out, cy_out, &unused);
}

uint8_t *gs_create_texture_file_data2(const char *file,
				      enum gs_image_alpha_mode alpha_mode,
				      enum gs_color_format *format,
				      uint32_t *cx_out, uint32_t *cy_out)
{
	enum gs_color_space unused;
	return stb_image_load_internal(file, alpha_mode, format, cx_out, cy_out, &unused);
}

uint8_t *gs_create_texture_file_data3(const char *file,
				      enum gs_image_alpha_mode alpha_mode,
				      enum gs_color_format *format,
				      uint32_t *cx_out, uint32_t *cy_out,
				      enum gs_color_space *space)
{
	return stb_image_load_internal(file, alpha_mode, format, cx_out, cy_out, space);
}
