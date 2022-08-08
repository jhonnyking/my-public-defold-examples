varying highp vec4   var_position;
varying mediump vec3 var_normal;
varying mediump vec2 var_texcoord0;

uniform lowp sampler2D tex0;

void main()
{
    vec4 albedo    = texture2D(tex0, var_texcoord0.xy);
    gl_FragData[0] = vec4(var_position.xyz, 1.0);
    gl_FragData[1] = vec4(normalize(var_normal), 1.0);
    gl_FragData[2] = vec4(albedo.rgb, 1.0);
}

