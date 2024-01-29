R"(
#version 420

#ifdef VULKAN
layout(set=0, binding=1) uniform sampler2D fs0;
layout(set=0, binding=2) uniform sampler2D fs1;
#else
layout(binding=31) uniform sampler2D fs0;
layout(binding=30) uniform sampler2D fs1;
#endif

layout(location=0) in vec2 tc0;
layout(location=0) out vec4 ocol;

#define STEREO_MODE_DISABLED 0
#define STEREO_MODE_SIDE_BY_SIDE 1
#define STEREO_MODE_OVER_UNDER 2
#define STEREO_MODE_ANAGLYPH_RED_GREEN 3
#define STEREO_MODE_ANAGLYPH_RED_BLUE 4
#define STEREO_MODE_ANAGLYPH_RED_CYAN 5
#define STEREO_MODE_ANAGLYPH_MAGENTA_CYAN 6
#define STEREO_MODE_ANAGLYPH_TRIOSCOPIC 7

vec2 sbs_single_matrix = vec2(2.0,0.4898f);
vec2 sbs_multi_matrix =  vec2(2.0,1.0);
vec2 ou_single_matrix =  vec2(1.0,0.9796f);
vec2 ou_multi_matrix =   vec2(1.0,2.0);

#ifdef VULKAN
layout(push_constant) uniform static_data
{
	float gamma;
	int limit_range;
	int stereo_display_mode;
	int stereo_image_count;
};
#else
uniform float gamma;
uniform int limit_range;
uniform int stereo_display_mode;
uniform int stereo_image_count;
#endif

vec4 read_source()
{
	if (stereo_display_mode == STEREO_MODE_DISABLED) return texture(fs0, tc0);

	vec4 left, right;
	if (stereo_image_count == 1)
	{
		switch (stereo_display_mode)
		{
			case STEREO_MODE_ANAGLYPH_RED_GREEN:
				left = texture(fs0, tc0 * vec2(1.f, 0.4898f));
				right = texture(fs0, (tc0 * vec2(1.f, 0.4898f)) + vec2(0.f, 0.510204f));
				return vec4(left.r, right.g, 0.f, 1.f);
			case STEREO_MODE_ANAGLYPH_RED_BLUE:
				left = texture(fs0, tc0 * vec2(1.f, 0.4898f));
				right = texture(fs0, (tc0 * vec2(1.f, 0.4898f)) + vec2(0.f, 0.510204f));
				return vec4(left.r, 0.f, right.b, 1.f);
			case STEREO_MODE_ANAGLYPH_RED_CYAN:
				left = texture(fs0, tc0 * vec2(1.f, 0.4898f));
				right = texture(fs0, (tc0 * vec2(1.f, 0.4898f)) + vec2(0.f, 0.510204f));
				return vec4(left.r, right.g, right.b, 1.f);
			case STEREO_MODE_ANAGLYPH_MAGENTA_CYAN:
				left = texture(fs0, tc0 * vec2(1.f, 0.4898f));
				right = texture(fs0, (tc0 * vec2(1.f, 0.4898f)) + vec2(0.f, 0.510204f));
				return vec4(left.r, right.g, (left.b + right.b) / 2.f, 1.f);
			case STEREO_MODE_ANAGLYPH_TRIOSCOPIC:
				left = texture(fs0, tc0 * vec2(1.f, 0.4898f));
				right = texture(fs0, (tc0 * vec2(1.f, 0.4898f)) + vec2(0.f, 0.510204f));
				return vec4(right.r, left.g, right.b, 1.f);
			case STEREO_MODE_SIDE_BY_SIDE:
				if (tc0.x < 0.5) return texture(fs0, tc0* sbs_single_matrix);
				else             return texture(fs0, (tc0* sbs_single_matrix) + vec2(-1.f, 0.510204f));
			case STEREO_MODE_OVER_UNDER:
				if (tc0.y < 0.5) return texture(fs0, tc0* ou_single_matrix);
				else             return texture(fs0, (tc0* ou_single_matrix) + vec2(0.f, 0.020408f) );
			default: // undefined behavior
				return texture(fs0,tc0);
		}
	}
	else if (stereo_image_count == 2)
	{
		switch (stereo_display_mode)
		{
			case STEREO_MODE_ANAGLYPH_RED_GREEN:
				left = texture(fs0, tc0);
				right = texture(fs1, tc0);
				return vec4(left.r, right.g, 0.f, 1.f);
			case STEREO_MODE_ANAGLYPH_RED_BLUE:
				left = texture(fs0, tc0);
				right = texture(fs1, tc0);
				return vec4(left.r, 0.f, right.b, 1.f);
			case STEREO_MODE_ANAGLYPH_RED_CYAN:
				left = texture(fs0, tc0);
				right = texture(fs1, tc0);
				return vec4(left.r, right.g, right.b, 1.f);
			case STEREO_MODE_ANAGLYPH_MAGENTA_CYAN:
				left = texture(fs0, tc0);
				right = texture(fs1, tc0);
				return vec4(left.r, right.g, (left.b + right.b) / 2.f, 1.f);
			case STEREO_MODE_ANAGLYPH_TRIOSCOPIC:
				left = texture(fs0, tc0);
				right = texture(fs1, tc0);
				return vec4(right.r, left.g, right.b, 1.f);
			case STEREO_MODE_SIDE_BY_SIDE:
				if (tc0.x < 0.5) return texture(fs0,(tc0 * sbs_multi_matrix));
				else             return texture(fs1,(tc0 * sbs_multi_matrix) + vec2(-1.f,0.f));
			case STEREO_MODE_OVER_UNDER:
				if (tc0.y < 0.5) return texture(fs0,(tc0 * ou_multi_matrix));
				else             return texture(fs1,(tc0 * ou_multi_matrix) + vec2(0.f,-1.f));
			default: // undefined behavior
				return texture(fs0,tc0);
		}
	}
	else
	{
		vec2 coord_left = tc0 * vec2(1.f, 0.4898f);
		vec2 coord_right = coord_left + vec2(0.f, 0.510204f);
		left = texture(fs0, coord_left);
		right = texture(fs0, coord_right);
		return vec4(left.r, right.g, right.b, 1.);
	}
}

void main()
{
	vec4 color = read_source();
	color.rgb = pow(color.rgb, vec3(gamma));
	if (limit_range > 0)
		ocol = ((color * 220.) + 16.) / 255.;
	else
		ocol = color;
}
)"
