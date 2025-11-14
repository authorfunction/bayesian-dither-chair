     precision mediump float;
     // 'varying' means it passes data to the fragment shader
     varying vec2 vUv;
     uniform sampler2D u_texture; // <-- 1. Declare the new uniform
     uniform float u_time;

     void main() {
         // 'uv' is an attribute provided by PlaneGeometry
         vUv = uv;
         vec3 displacedPosition = position;
         // 2. Calculate displacement.
         // We use position.x and position.y to make the wave vary across
         // the plane, otherwise the whole plane would just move up and down.
         // Multiplying by 5.0 increases the frequency (more waves).
         // Multiplying by 0.2 decreases the amplitude (smaller waves).
         float displacement =
             sin(position.x * 5.0 + u_time) * 0.2 +
             sin(position.y * 5.0 + u_time) * 0.2;

         // 3. Apply the displacement to the z-axis
         //displacedPosition.z = displacement; // This displacement will be invisible in orthogrpahic straight down view
         // 3. Apply the displacement to the x-axis instead
         displacedPosition.x = position.x + displacement;

       gl_Position = projectionMatrix * modelViewMatrix * vec4(displacedPosition, 1.0);
     }
