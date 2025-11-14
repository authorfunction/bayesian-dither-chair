uniform sampler2D tDiffuse;
uniform float u_time;
varying vec2 vUv;

void main() {
    vec2 st = vUv;

    // 1. CALCULATE ABERRATION AMOUNT (The Jitter)
    float amount = (1.0 + sin(u_time * 6.0)) * 0.5;
    amount *= 1.0 + sin(u_time * 16.0) * 0.5;
    amount *= 1.0 + sin(u_time * 19.0) * 0.5;
    amount *= 1.0 + sin(u_time * 27.0) * 0.5;
    amount = pow(amount, 3.0);
    amount *= 0.008; //0.05; // Adjust this value to change the maximum shift distance

    // 2. SPLIT CHANNELS
    // Sample the scene texture (tDiffuse) at slightly different coordinates

    // Red: Shifted positive
    float r = texture2D(tDiffuse, vec2(st.x + amount, st.y)).r;

    // Green: No shift (keeps the image stable)
    float g = texture2D(tDiffuse, st).g;

    // Blue: Shifted negative
    float b = texture2D(tDiffuse, vec2(st.x - amount, st.y)).b;

    vec3 finalColor = vec3(r, g, b);

    // 3. VIGNETTE / DARKENING
    // Darken the image slightly when the glitch is strong
    finalColor *= (1.0 - amount * 0.5);

    gl_FragColor = vec4(finalColor, 1.0);
}
