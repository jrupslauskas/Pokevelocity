
const VERTEX_SHADER_SOURCE = `#version 300 es
out highp vec2 vUv;

void main() {
  vec2 vertices[6];
  vertices[0] = vec2(0.0, 0.0);
  vertices[1] = vec2(1.0, 0.0);
  vertices[2] = vec2(1.0, 1.0);
  vertices[3] = vec2(1.0, 1.0);
  vertices[4] = vec2(0.0, 1.0);
  vertices[5] = vec2(0.0, 0.0);
  vec2 uv = vertices[gl_VertexID];

  gl_Position = vec4(uv * 2.0 - vec2(1.0), 0.0, 1.0);
  vUv = uv;
}
`;

const FRAGMENT_SHADER_SOURCE = `#version 300 es
uniform highp float uTime;
uniform sampler2D uSampler;
in highp vec2 vUv;
out highp vec4 fragColor;

void main() {
  highp vec4 color = texture(uSampler, vUv);
  fragColor = vec4(vec3(0.0), color.r > uTime ? 0.0 : 1.0);
}
`;

const ANIMATION_LENGTH = 2000.0;
const BLACKOUT_LENGTH = 500.0;

document.addEventListener('turbo:load', function () {

  const poke = {
    gl: null,
  };

  function initGl() {
    const canvas = document.getElementById('animation-overlay');
    poke.gl = canvas.getContext('webgl2');
    let gl = poke.gl;

    poke.vs = gl.createShader(gl.VERTEX_SHADER);
    gl.shaderSource(poke.vs, VERTEX_SHADER_SOURCE);
    gl.compileShader(poke.vs);

    poke.fs = gl.createShader(gl.FRAGMENT_SHADER);
    gl.shaderSource(poke.fs, FRAGMENT_SHADER_SOURCE);
    gl.compileShader(poke.fs);

    if (!gl.getShaderParameter(poke.vs, gl.COMPILE_STATUS)) {
      console.error(`${gl.getShaderInfoLog(poke.vs)}`);
    }

    if (!gl.getShaderParameter(poke.fs, gl.COMPILE_STATUS)) {
      console.error(`${gl.getShaderInfoLog(poke.fs)}`);
    }

    poke.program = gl.createProgram();
    gl.attachShader(poke.program, poke.vs);
    gl.attachShader(poke.program, poke.fs);
    gl.linkProgram(poke.program);

    if (!gl.getProgramParameter(poke.program, gl.LINK_STATUS)) {
      console.error(`${gl.getProgramInfoLog(poke.program)}`);
    }
  }

  initGl();
  poke.texture = loadImage(window.assetPaths.horizontalStripes);

  function loadImage(imageUrl) {
    const gl = poke.gl;
    const texture = gl.createTexture();

    gl.bindTexture(gl.TEXTURE_2D, texture);
    // placeholder data while image is loading
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, 1, 1, 0, gl.RGBA, gl.UNSIGNED_BYTE, new Uint8Array([0, 0, 0, 255]));


    const image = new Image();
    image.onload = function () {
      gl.bindTexture(gl.TEXTURE_2D, texture);
      gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, image);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
      gl.generateMipmap(gl.TEXTURE_2D);
    };
    image.src = imageUrl;

    return texture;
  }

  function startAnimation(timestamp) {
    if (poke.animationStartTime === undefined) {
      poke.animationStartTime = timestamp;
    }

    let gl = poke.gl;
    gl.clearColor(1.0, 1.0, 1.0, 1.0);
    gl.clear(gl.COLOR_BUFFER_BIT);

    gl.useProgram(poke.program);

    gl.enable(gl.BLEND);
    gl.blendFunc(gl.ONE, gl.ZERO);

    let dt = (timestamp - poke.animationStartTime) / ANIMATION_LENGTH;
    gl.uniform1f(gl.getUniformLocation(poke.program, 'uTime'), dt);

    gl.activeTexture(gl.TEXTURE0);
    gl.bindTexture(gl.TEXTURE_2D, poke.texture);
    gl.uniform1i(gl.getUniformLocation(poke.program, 'uSampler'), 0);

    gl.drawArrays(gl.TRIANGLES, 0, 6);

    if (dt < ANIMATION_LENGTH) {
      // Stop redrawing animation when finished
      requestAnimationFrame(startAnimation);
    }
  }

  // Trigger animation when clicking "Adventure" button on route selection
  document.querySelectorAll('form.adventure-form').forEach(function (form) {
    let isAnimating = false;

    form.addEventListener('submit', function(event) {
      // If already animating or submitted, allow the form to submit normally
      if (isAnimating) {
        return;
      }

      // Check if user has enabled encounter animation
      if (!window.showEncounterAnimation) {
        // Animation disabled, allow form to submit normally
        return;
      }

      // Prevent default form submission
      event.preventDefault();
      isAnimating = true;

      document.getElementById("animation-overlay").classList.remove('hidden');
      poke.animationStartTime = undefined; // Reset animation start time
      requestAnimationFrame(startAnimation);

      // Play encounter audio if animation is enabled
      const encounterAudio = document.getElementById('encounter-audio');
      if (encounterAudio) {
        encounterAudio.currentTime = 0; // Reset to start
        encounterAudio.play()
          .then(() => {
            console.log('✓ Encounter audio playing');
          })
          .catch(err => {
            console.error('✗ Encounter audio playback failed:', err);
          });
      }

      setTimeout(function () {
        document.getElementById("animation-overlay").classList.add('hidden');
        // Submit the form after animation completes (this will bypass the event listener)
        form.submit();
      }, ANIMATION_LENGTH + BLACKOUT_LENGTH);
    });
  });
});
