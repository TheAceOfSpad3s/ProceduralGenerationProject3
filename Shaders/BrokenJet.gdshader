// Define this as a 3D spatial shader
shader_type spatial;

// ----------------------------------------------------
// VERTEX FUNCTION (GEOMETRY WARP)
// ----------------------------------------------------

// Uniform controlled by GDScript (0.0 = off, 1.0 = full warp)
uniform float crumple_amount = 1.0;

void vertex() {
    // 1. Get the current position of the vertex in world space.
    vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

    // 2. Generate a pseudo-random, chaotic 3D vector (noise)
    // This creates the direction for the jiggle.
    vec3 noise_offset = vec3(
        sin(world_pos.x * 5.0) * cos(world_pos.z * 5.0),
        cos(world_pos.y * 3.0),
        sin(world_pos.z * 5.0) * cos(world_pos.x * 5.0)
    );

    // 3. Apply the warp effect, scaled by the crumple_amount.
    // This is the only part that modifies the mesh's geometry.
    VERTEX += normalize(noise_offset) * crumple_amount * 0.5;
}

// ----------------------------------------------------
// FRAGMENT FUNCTION (COLOR/TEXTURE PASS-THROUGH)
// This part reads the original color/texture passed by the script.
// ----------------------------------------------------

// These are placeholders for the original material's properties
uniform sampler2D original_albedo_texture;
uniform vec4 original_albedo_color : source_color = vec4(1.0);


void fragment() {
    // We are simply sampling the original texture and color and applying it.
    // This preserves the look of the old material under the new geometry.
    vec4 albedo_tex = texture(original_albedo_texture, UV);
    
    // Apply the original color and texture, allowing Godot's lighting to work.
    ALBEDO = original_albedo_color.rgb * albedo_tex.rgb;
}
