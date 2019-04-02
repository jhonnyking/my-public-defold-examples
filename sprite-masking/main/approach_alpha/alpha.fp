varying mediump vec2   var_texcoord0;
uniform lowp sampler2D texture_sampler;

void main()
{
    vec4 sample  = texture2D(texture_sampler, var_texcoord0.xy);
    gl_FragColor = vec4(sample.r);
}
