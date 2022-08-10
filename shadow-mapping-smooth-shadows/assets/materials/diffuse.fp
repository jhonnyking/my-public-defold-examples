varying mediump vec4 var_position;
varying mediump vec4 var_position_world;
varying mediump vec3 var_normal;
varying mediump vec2 var_texcoord0;
varying mediump vec4 var_texcoord0_shadow;
varying mediump vec4 var_light;

uniform lowp sampler2D tex0;
uniform lowp sampler2D tex_depth;

uniform mediump vec4 mtx_light_mvp0;
uniform mediump vec4 mtx_light_mvp1;
uniform mediump vec4 mtx_light_mvp2;
uniform mediump vec4 mtx_light_mvp3;

float rgba_to_float(vec4 rgba)
{
    return dot(rgba, vec4(1.0, 1.0/255.0, 1.0/65025.0, 1.0/16581375.0));
}

float shadow_calculation(vec4 depth_data)
{
    const float depth_bias = 0.002;
    // const float depth_bias = 0.00002; // for perspective camera
    
    float shadow = 0.0;
    vec2 texel_size = 1.0 / textureSize(tex_depth, 0);
    for (int x = -1; x <= 1; ++x)
    {
        for (int y = -1; y <= 1; ++y)
        {
            float depth = rgba_to_float(texture2D(tex_depth, depth_data.st + vec2(x,y) * texel_size));
            shadow += depth_data.z - depth_bias > depth ? 0.8 : 0.0;
        }
    }
    shadow /= 9.0;

    return shadow;
}


void main()
{
    vec4 color = texture2D(tex0, var_texcoord0.xy);

    // Diffuse light calculations.
    vec3 ambient_light = vec3(0.2);
    vec3 diff_light    = vec3(normalize(var_light.xyz - var_position.xyz));
    diff_light         = max(dot(var_normal,1.0 - diff_light), 0.0) + ambient_light;
    diff_light         = clamp(diff_light, 0.0, 1.0);

    vec4 depth_proj = var_texcoord0_shadow / var_texcoord0_shadow.w;    
    //gl_FragColor    = vec4(color.rgb*diff_light * get_visibility(depth_proj.xyzw),1.0);
    gl_FragColor    = vec4(color.rgb * (1.0 - shadow_calculation(depth_proj.xyzw)),1.0);
}

