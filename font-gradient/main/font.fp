varying mediump vec2 var_texcoord0;
varying lowp vec4 var_face_color;
varying lowp vec4 var_outline_color;
varying lowp vec4 var_shadow_color;

uniform mediump vec4   texture_size_recip;
uniform lowp sampler2D texture;
uniform lowp vec4      time;

vec3 crazy_mode()
{
    lowp float gradient_value_y = fract(var_texcoord0.y / texture_size_recip.w + time.x);
    lowp float gradient_value_x = (sin( gl_FragCoord.x / 256.0 + time.x) + 1.0)*0.5;
    lowp vec3  color_a          = vec3(1.0,0.0,gradient_value_x);
    lowp vec3  color_b          = vec3(0.0,1.0,gradient_value_x);
    lowp vec3  color_gradient   = mix(color_a,color_b,smoothstep(0.0,0.5,gradient_value_y));
    return mix(color_gradient,color_a,smoothstep(0.5,1.0,gradient_value_y));
}

vec3 gradient_mode()
{
    lowp float gradient_value_y = fract(var_texcoord0.y / texture_size_recip.w);
    lowp vec3  color_a          = vec3(1.0,0.0,1.0);
    lowp vec3  color_b          = vec3(0.0,1.0,1.0);
    
    return mix(color_a,color_b,gradient_value_y);
}

void main()
{
    lowp vec4  cache_sample  = texture2D(texture, var_texcoord0.xy);
    lowp vec3 gradient_crazy = crazy_mode();
    lowp vec3 gradient_norml = gradient_mode();
    
    gl_FragColor = vec4(mix(gradient_crazy,gradient_norml,time.y),1.0) * cache_sample.x;
}
