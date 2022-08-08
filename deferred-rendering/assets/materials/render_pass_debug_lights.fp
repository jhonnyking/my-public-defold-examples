varying mediump vec2 var_texcoord0;

uniform mediump vec4 u_light_color;

void main()
{
    gl_FragColor = vec4(u_light_color.rgb, 0.2);
}

