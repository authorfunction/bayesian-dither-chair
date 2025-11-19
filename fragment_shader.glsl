// Set default precision for floating point numbers
precision mediump float;

// Uniforms are variables passed from our JavaScript
uniform vec2 u_resolution; // The resolution of the canvas
uniform float u_time; // The elapsed time for animation
uniform sampler2D u_texture; // <-- 1. Declare the new uniform
uniform vec3 u_baseColor;
uniform float u_useColorBlend;
uniform float u_applyPattern;
uniform float u_behaviour;

// 'vUv' is the data received from the vertex shader (0.0 to 1.0)
varying vec2 vUv;

// --- BAYER DITHERING MAP ---
// We define the 4x4 Bayer threshold map as a matrix.
// GLSL matrices are "column-major", so we list the columns.
const mat4 bayerMap = mat4(
        15.0, 195.0, 60.0, 240.0, // Column 0
        135.0, 75.0, 180.0, 120.0, // Column 1
        45.0, 225.0, 30.0, 210.0, // Column 2
        165.0, 105.0, 150.0, 90.0 // Column 3
    );

const mat4 bayerMap_glitch = mat4(
        225.0, 0.0, 0.0, 64.0, // Random values...
        0.0, 128.0, 0.0, 128.0, // ...
        128.0, 0.0, 128.0, 64.0, // ...
        225.0, 225.0, 225.0, 225.0 // ...
    );

// This will create vertical stripes
const mat4 bayerMap_striped = mat4(
        0.0, 0.0, 0.0, 0.0, // Col 0
        250.0, 250.0, 250.0, 250.0, // Col 1
        0.0, 0.0, 0.0, 0.0, // Col 2
        250.0, 250.0, 250.0, 250.0 // Col 3
    );

vec3 createColorPattern(vec2 st, float time) {
    float r = sin(st.x * 10.0 + time * 0.5) * 0.5 + 0.5;
    float g = sin(st.y * 10.0 + time * 0.3) * 0.5 + 0.5;
    float b = sin(st.x * 5.0 - st.y * 5.0 + time) * 0.5 + 0.5;
    return vec3(r, g, b);
}

float bayesianDither(vec3 originalColor) {
    // 2. CALCULATE LUMINANCE (0.0 to 1.0)
    // Convert the color to grayscale brightness
    //originalColor = color;
    float luminance = dot(originalColor, vec3(0.299, 0.587, 0.114));

    // 3. GET DITHER THRESHOLD
    // gl_FragCoord.xy gives us the screen pixel coordinate (e.g., 800, 600)
    // We use mod() to find which cell in the 4x4 map this pixel corresponds to.
    int x = int(mod(gl_FragCoord.x, 4.0));
    int y = int(mod(gl_FragCoord.y, 4.0));

    // Look up the threshold value from the map (col, row)
    // The value is 0-255, so we divide by 255.0 to normalize it to 0.0-1.0
    float threshold = bayerMap[x][y] / 255.0;

    // 4. COMPARE AND SET FINAL COLOR
    // If the luminance is brighter than the threshold, use 1.0 (bright).
    // Otherwise, use 0.0 (dark).
    float ditheredValue = luminance > threshold ? 1.0 : 0.0;

    return ditheredValue;
    //return 1.0;
}

void main() {
    // 'vUv' gives us the normalized coordinate (0.0 to 1.0)
    vec2 st = vUv;
    vec3 originalColor;

    // 1. CALCULATE ORIGINAL COLOR
    if (u_applyPattern > 0.0) {
        originalColor = createColorPattern(st, u_time);
    } else {
        vec3 originalColor = u_baseColor;
    }
    vec3 textureColor = texture2D(u_texture, st).rgb;

    vec3 blendedColor = mix(originalColor, textureColor, 0.5);
    // 2. Apply Bayesian dither
    float ditheredValue = bayesianDither(blendedColor);
    //float ditheredTextureValue = bayesianDither(textureColor);

    // Blend the original color with the dithered value.
    // This preserves the color, but applies the dither pattern
    // (multiplying by 1.0 keeps the color, multiplying by 0.0 makes it black).
    // with texture:
    //vec3 finalColor = blendedColor * ditheredValue;

    float ditheredValue2 = bayesianDither(originalColor);
    vec3 finalRender = originalColor * ditheredValue2;

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
    if (u_useColorBlend > 0.0) {
        //gl_FragColor = vec4(finalColor * u_baseColor, finalColor.a);
        // FIX 2: A vec3 (finalColor) has no .a component. Use 1.0 for alpha.
        //gl_FragColor = vec4(finalRender * u_baseColor, 1.0);
        gl_FragColor = vec4(mix(finalRender, u_baseColor, 0.5), 1.0);
    }
}
