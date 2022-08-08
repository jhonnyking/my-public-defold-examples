varying mediump vec2 var_texcoord0;
uniform lowp sampler2D tex0;

void main()
{
    float ambient = 0.1;
    vec4 albedo_sample = texture2D(tex0, var_texcoord0);
    gl_FragColor = vec4(albedo_sample.rgb * ambient, 1.0);
}

