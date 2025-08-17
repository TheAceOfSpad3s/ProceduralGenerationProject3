shader_type spatial;

uniform vec4 top_color : source_color = vec4(0.5, 0.5, 0.5, 1.0);     // Flat tops
uniform vec4 middle_color : source_color = vec4(0.3, 0.2, 0.1, 1.0);  // Canyon walls
uniform vec4 bottom_color : source_color = vec4(0.2, 0.2, 0.2, 1.0);  // Ravine floor
uniform float slope_steepness : hint_range(0.0, 1.0) = 0.5;
uniform float slope_flatness : hint_range(0.0, 1.0) = 0.8;
uniform float height_transition_top : hint_range(0.0, 1.0) = 0.7;
uniform float height_transition_bottom : hint_range(0.0, 1.0) = 0.2;

uniform float ravine_depth : hint_range(1.0, 50.0) = 30.0;
uniform float side_height : hint_range(0.0, 50.0) = 10.0;

// Rock variation palette
uniform vec4 rock_color_1 : source_color = vec4(0.4, 0.3, 0.25, 1.0);
uniform vec4 rock_color_2 : source_color = vec4(0.55, 0.4, 0.3, 1.0);
uniform vec4 rock_color_3 : source_color = vec4(0.25, 0.2, 0.15, 1.0);
uniform float patch_scale : hint_range(1.0, 100.0) = 5.0;

// Pass data from vertex → fragment
varying vec3 v_vertex_pos;
varying vec3 v_normal;

// Simple hash for random per-face variation
float hash31(vec3 p) {
    vec3 p3 = fract(p * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

void vertex() {
    v_vertex_pos = VERTEX;
    v_normal = NORMAL; // normals are already “flat” if your mesh generator duplicates verts per face
}

void fragment() {
    vec3 world_pos = (MODEL_MATRIX * vec4(v_vertex_pos, 1.0)).xyz;

    // --- Height-based gradient ---
    float height_blend = (world_pos.y + ravine_depth) / (ravine_depth + side_height);
    height_blend = clamp(height_blend, 0.0, 1.0);

    vec3 height_color = mix(
        bottom_color.rgb,
        middle_color.rgb,
        smoothstep(height_transition_bottom, height_transition_top, height_blend)
    );

    // --- Slope-based blending ---
    float slope_blend = dot(normalize(v_normal), vec3(0.0, 1.0, 0.0));
    slope_blend = smoothstep(slope_steepness, slope_flatness, slope_blend);

    vec3 slope_color = mix(height_color, top_color.rgb, slope_blend);

    // --- Randomized per-face tint (low-poly jaggedness) ---
    vec2 face_id = floor(v_vertex_pos.xz / patch_scale);
    float rnd = hash31(vec3(face_id.x, 0.0, face_id.y));

    vec3 rock_tint;
    if (rnd < 0.33) {
        rock_tint = rock_color_1.rgb;
    } else if (rnd < 0.66) {
        rock_tint = rock_color_2.rgb;
    } else {
        rock_tint = rock_color_3.rgb;
    }

    vec3 final_color = mix(slope_color, rock_tint, 1.0 - slope_blend);

    // --- Stylized hard lighting for low-poly look ---
    vec3 light_dir = normalize(vec3(0.3, 0.8, 0.4));
    float light = max(dot(normalize(v_normal), light_dir), 0.0);
    light = step(0.5, light); // hard cutoff (lit or shadow)
    final_color *= mix(0.7, 1.0, light);

    ALBEDO = final_color;
}
