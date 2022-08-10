varying mediump vec2 var_texcoord0;
varying mediump vec4 var_position_world;
varying mediump vec4 var_light;
uniform lowp sampler2D tex0;

float rgba_to_float(vec4 rgba)
{
    return dot(rgba, vec4(1.0, 1.0/255.0, 1.0/65025.0, 1.0/16581375.0));
}

void main()
{
    vec4 color       = texture2D(tex0, var_texcoord0.xy);
    float depth      = color.r; // vec3(rgba_to_float(color));
    gl_FragColor.a   = 1.0;
    gl_FragColor.rgb = vec3(1.0-depth);
}

