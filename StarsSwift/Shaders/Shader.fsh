#version 100

#ifdef GL_ES
precision mediump float;
#endif
uniform float uWarpFactorFragment;
varying vec4 vColor;

void main(void) {
  float blend_factor = clamp((vColor.a - 1.) / 2., 0., 1.);
  gl_FragColor = vec4(clamp(vColor, vec4(0.), vec4(1.)));
  float radius_factor = 1.;
  if (uWarpFactorFragment < .5) {
    radius_factor = (1. - 2. * abs(gl_PointCoord.x - .5)) *
                    (1. - 2. * abs(gl_PointCoord.y - .5));
  }
  vec3 star_color =
      mix(1., radius_factor, blend_factor) * vec3(vColor);
  gl_FragColor = vec4(clamp(star_color, vec3(0.), vec3(1.)), 0.);
}
