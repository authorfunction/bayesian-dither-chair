precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;
uniform sampler2D u_texture;
uniform float u_behaviour;
uniform vec3 u_baseColor;
uniform float u_useColorBlend;
uniform float u_applyPattern_r;
uniform float u_applyPattern_g;
uniform float u_applyPattern_b;
varying vec2 vUv;

// --- BAYER DITHERING MAP ---
const mat4 bayerMap = mat4(
        15.0, 195.0, 60.0, 240.0,
        135.0, 75.0, 180.0, 120.0,
        45.0, 225.0, 30.0, 210.0,
        165.0, 105.0, 150.0, 90.0
    );

// --- PATTERN GENERATOR ---
vec3 createColorPattern(vec2 st, float time) {
    float r = sin(st.x * 10.0 + time * 0.5) * 0.5 + 0.5;
    float g = sin(st.y * 10.0 + time * 0.3) * 0.5 + 0.5;
    float b = sin(st.x * 5.0 - st.y * 5.0 + time) * 0.5 + 0.5;
    return vec3(r, g, b);
}

// --- DITHER FUNCTION ---
float bayesianDither(vec3 originalColor) {
    float luminance = dot(originalColor, vec3(0.299, 0.587, 0.114));
    int x = int(mod(gl_FragCoord.x, 4.0));
    int y = int(mod(gl_FragCoord.y, 4.0));
    float threshold = bayerMap[x][y] / 255.0;
    return luminance > threshold ? 1.0 : 0.0;
}

void main() {
    vec2 st = vUv;

    // 1. CALCULATE ABERRATION OFFSET
    // We calculate how much the R and B channels should separate
    float amount = (1.0 + sin(u_time * 6.0)) * 0.5;
    amount *= 1.0 + sin(u_time * 16.0) * 0.5;
    amount *= 1.0 + sin(u_time * 19.0) * 0.5;
    amount *= 1.0 + sin(u_time * 27.0) * 0.5;
    amount = pow(amount, 3.0);
    amount *= 0.02; // Strength of the glitch

    // 2. GENERATE CHANNELS SEPARATELY (The "Split" Effect)

    // -- RED CHANNEL (Shifted +) --
    vec2 st_r = vec2(st.x + amount, st.y);
    //vec3 pattern_r = createColorPattern(st_r, u_time); // Generate pattern at shifted pos
    vec3 pattern_r = u_baseColor;
    if (u_applyPattern_r > 0.0) { // Checks if the value is "true"
        pattern_r = createColorPattern(st_r, u_time);
    }

    vec3 tex_r = texture2D(u_texture, st_r).rgb; // Sample texture at shifted pos
    float final_r = mix(pattern_r.r, tex_r.r, 0.1); // Mix them

    // -- GREEN CHANNEL (No Shift) --
    vec2 st_g = st;
    //vec3 pattern_g = createColorPattern(st_g, u_time);
    vec3 pattern_g = u_baseColor;
    if (u_applyPattern_g > 0.0) { // Checks if the value is "true"
        pattern_g = createColorPattern(st_r, u_time);
    }
    vec3 tex_g = texture2D(u_texture, st_g).rgb;
    float final_g = mix(pattern_g.g, tex_g.g, 0.1);

    // -- BLUE CHANNEL (Shifted -) --
    vec2 st_b = vec2(st.x - amount, st.y);
    //vec3 pattern_b = createColorPattern(st_b, u_time);
    vec3 pattern_b = u_baseColor;
    if (u_applyPattern_b > 0.0) { // Checks if the value is "true"
        pattern_b = createColorPattern(st_b, u_time);
    }
    vec3 tex_b = texture2D(u_texture, st_b).rgb;
    float final_b = mix(pattern_b.b, tex_b.b, 0.1);

    // 3. COMBINE CHANNELS
    vec3 combinedColor = vec3(final_r, final_g, final_b);

    // Darken slightly based on intensity (vignette effect from original code)
    //combinedColor *= (1.0 - amount * 0.5);

    // 4. APPLY DITHERING
    // We now dither the fully aberrated, combined image
    float ditheredValue = bayesianDither(combinedColor);

    // 5. FINAL OUTPUT
    // This applies the dither mask to the chromatic colors
    vec3 finalRender = combinedColor * ditheredValue;

    // Apply base color if enabled
    //if (u_useColor) {
    //    finalRender *= u_baseColor;
    //}

    switch (int(u_behaviour)) {
        case 0:
        // Show Colorized version (with aberration)
        gl_FragColor = vec4(finalRender, 1.0);
        break;
        case 1:
        // Show Monochrome version
        gl_FragColor = vec4(vec3(ditheredValue), 1.0);
        break;
        default:
        // Default behavior flip periodically
        if ((sin(u_time / 1.17)) < 0.0) {
            // Show Colorized version (with aberration)
            gl_FragColor = vec4(finalRender, 1.0);
        }
        else {
            // Show Monochrome version
            gl_FragColor = vec4(vec3(ditheredValue), 1.0);
            break;
        }
    }
}
