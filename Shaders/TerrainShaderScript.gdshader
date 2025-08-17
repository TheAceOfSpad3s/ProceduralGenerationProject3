shader_type spatial;

uniform vec4 high_color : source_color = vec4(0.8, 0.8, 0.8, 1.0); // Snow
uniform vec4 rock_color : source_color = vec4(0.5, 0.45, 0.4, 1.0); // Rocks

uniform float min_height : hint_range(-100.0, 0.0) = -5.0;
uniform float max_height : hint_range(0.0, 100.0) = 20.0;
uniform float slope_threshold : hint_range(0.0, 1.0) = 0.6; // Steepness where rocks start appearing
uniform float slope_transition_width : hint_range(0.0, 1.0) = 0.1; // How wide the transition band is
uniform float rock_min_height : hint_range(-100.0, 100.0) = 5.0; // The minimum height for rocks to appear
uniform float rock_blend_height_start : hint_range(-100.0, 100.0) = 5.0;
uniform float rock_blend_height_end : hint_range(-100.0, 100.0) = 15.0;

// Three uniform colors for our three shades of green
uniform vec4 green_color_1 : source_color = vec4(0.0, 0.6, 0.0, 1.0); // Standard green
uniform vec4 green_color_2 : source_color = vec4(0.2, 0.8, 0.4, 1.0); // Lighter green
uniform vec4 green_color_3 : source_color = vec4(0.1, 0.45, 0.2, 1.0); // Darker green
uniform float grass_patch_scale : hint_range(1.0, 100.0) = 5.0; // The size of the color patches

// Pass the vertex position, height, and slope to the fragment shader
varying vec3 v_vertex_pos;
varying float v_height;
varying float v_slope;

// A simple hash function to get a pseudo-random value from a vec3
float hash31(vec3 p) {
    vec3 p3 = fract(p * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

void vertex() {
	v_height = VERTEX.y; // Save the world-space height
	v_slope = NORMAL.y; // Save the slope value (1 = flat, 0 = vertical)
	v_vertex_pos = VERTEX; // Pass the local vertex position
}

void fragment() {
    // --- Choose a random low color per face ---
    // The key is using floor() on the interpolated vertex position
    // to get a constant value for each face.
    vec2 pos = floor(v_vertex_pos.xz / grass_patch_scale);
    float random_val = hash31(vec3(pos.x, 0.0, pos.y));

    vec4 selected_grass_color;
    if (random_val < 0.45) {
        selected_grass_color = green_color_1;
    } else if (random_val < 0.90) {
        selected_grass_color = green_color_2;
    } else {
        selected_grass_color = green_color_3;
    }

	// --- Height-based blend (Grass to Snow) ---
	// This creates our base color, which is a mix of grass and snow depending on height.
	float height_t = clamp((v_height - min_height) / (max_height - min_height), 0.0, 1.0);
	vec4 height_based_color = mix(selected_grass_color, high_color, height_t);

	// The rest of your code remains the same...
	float slope_blend_factor = smoothstep(slope_threshold - slope_transition_width, slope_threshold + slope_transition_width, v_slope);
	float height_rock_factor = smoothstep(rock_min_height - 5.0, rock_min_height + 5.0, v_height);
	float rock_fade_factor = smoothstep(rock_blend_height_start, rock_blend_height_end, v_height);
	float combined_rock_factor = (1.0 - slope_blend_factor) * height_rock_factor * rock_fade_factor;
	vec4 final_color = mix(height_based_color, rock_color, combined_rock_factor);

	ALBEDO = final_color.rgb;
}
