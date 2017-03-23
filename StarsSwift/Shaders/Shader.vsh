//
//  Shader.vsh
//  StarsSwift
//
//  Created by Newcastle on 19.03.17.
//  Copyright © 2017 Newcastle. All rights reserved.
//
#version 100

uniform mat4 uClipFromEyeMatrix;
uniform mat4 uHeadFromStartMatrix;
uniform mat4 uEyeFromHeadMatrix;
uniform vec3 uOffsetPosition;
uniform vec3 uOffsetVelocity;
uniform float uWarpFactorVertex;
uniform float uBrightness;
attribute vec3 aVertex;
attribute vec3 aColor;
varying vec4 vColor;
void main(void) {
  vec3 pos_offset = aVertex + uOffsetPosition + vec3(100.);
  pos_offset = mod(pos_offset, 200.);
  pos_offset -= vec3(100.);
  vec4 pos = vec4(pos_offset, 1.0);
  if (uWarpFactorVertex > 0. && aColor[0] == 0.) {
    pos.xyz -= 10. * (uWarpFactorVertex - .5) * uOffsetVelocity;
  }
  vec3 color = aColor;
  color = min(color / (.7 + .3 * uWarpFactorVertex), vec3(1.));
  if (uWarpFactorVertex > 0.) {
    vec3 vel_dir = normalize(uOffsetVelocity);
    vec3 vel_component = dot(pos.xyz, vel_dir) * vel_dir;
    vec3 out_component = pos.xyz - vel_component;
    float dist = length(out_component);
    float dist_factor = 5. + dist;
    float warp_factor = pow(uWarpFactorVertex, 2.);
    dist_factor =
        ((1. - warp_factor) * dist + warp_factor * dist_factor) / dist;
    pos.xyz = vel_component + dist_factor * out_component;
    color *= 1. - .5 * warp_factor;
  }
  pos = uHeadFromStartMatrix * pos;
  pos = uClipFromEyeMatrix * uEyeFromHeadMatrix * pos;
  float distance_factor = 50. / pos.z;
  gl_PointSize = clamp(distance_factor, 1., 200.);
  gl_Position = pos;
    
  color *= uBrightness;
  vColor =
      vec4(min(distance_factor / 2., 5.) * color, distance_factor) * .1 * clamp(pos.z, 0., 10.);
}
