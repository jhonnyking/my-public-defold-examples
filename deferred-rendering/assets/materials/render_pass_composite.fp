varying mediump vec2 var_texcoord0;
uniform lowp sampler2D tex_albedo;
uniform lowp sampler2D tex_position;

void main()
{
    float ambient = 0.1;
    vec4 albedo_sample   = texture2D(tex_albedo, var_texcoord0);
    vec4 position_sample = texture2D(tex_position, var_texcoord0);
    gl_FragColor         = vec4(albedo_sample.rgb * ambient, 1.0);
    gl_FragDepth         = position_sample.z;

    //gl_FragColor = vec4(vec3(-position_sample.z), 1.0);
    //gl_FragColor.b = 1.0;
}

