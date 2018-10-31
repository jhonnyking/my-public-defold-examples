varying mediump vec2 var_texcoord0;
varying lowp vec4 var_face_color;
varying lowp vec4 var_outline_color;
varying lowp vec4 var_shadow_color;

uniform mediump vec4   texture_size_recip;
uniform lowp sampler2D texture;

void main()
{
    lowp vec4  cache_sample   = texture2D(texture, var_texcoord0.xy);
    lowp float gradient_value = fract(var_texcoord0.y / texture_size_recip.w);
    lowp vec3  color_a        = vec3(1.0,0.0,0.0);
    lowp vec3  color_b        = vec3(0.0,1.0,0.0);
    lowp vec3  color_gradient = mix(color_a,color_b,gradient_value);
    gl_FragColor              = vec4(color_gradient,1.0) * cache_sample.x;
}
