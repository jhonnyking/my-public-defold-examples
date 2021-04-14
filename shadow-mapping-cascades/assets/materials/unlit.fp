varying mediump vec2 var_texcoord0;
uniform lowp sampler2D tex0;
uniform lowp vec4 tint;

void main()
{
    vec4 color = texture2D(tex0, var_texcoord0.xy) * tint;
    gl_FragColor = vec4(color.rgb,1.0);
}

