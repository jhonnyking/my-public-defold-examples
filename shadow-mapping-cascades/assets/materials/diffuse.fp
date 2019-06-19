varying mediump vec4 var_position;
varying mediump vec4 var_position_clip;
varying mediump vec3 var_normal;
varying mediump vec2 var_texcoord0;
varying mediump vec4 var_texcoord0_shadow[3];
varying mediump vec4 var_light;

uniform lowp sampler2D tex0;
uniform lowp sampler2D tex_csm_0;
uniform lowp sampler2D tex_csm_1;
uniform lowp sampler2D tex_csm_2;

uniform mediump vec4 u_cascade_limits;

float rgba_to_float(vec4 rgba)
{
    return dot(rgba, vec4(1.0, 1.0/255.0, 1.0/65025.0, 1.0/16581375.0));
}

/*
float get_visibility(int cascade, vec3 depth_data)
{
    vec4 depth_sample = vec4(0.0);

    if (cascade == 0)
        depth_sample = texture2D(tex_csm_0, depth_data.st);
    else if (cascade == 1)
        depth_sample = texture2D(tex_csm_1, depth_data.st);
    else if (cascade == 2)
        depth_sample = texture2D(tex_csm_2, depth_data.st);
    
    float depth            = rgba_to_float(depth_sample);
    const float depth_bias = 0.002;
    // const float depth_bias = 0.00002; // for perspective camera

    // The 'depth_bias' value is per-scene dependant and must be tweaked accordingly.
    // It is needed to avoid shadow acne, which is basically a precision issue.
    if (depth < depth_data.z - depth_bias)
    {
        return 0.5;
    }

    return 1.0;
}
*/

vec4 get_visibility(int cascade, vec4 light_space_pos)
{
    vec3 proj_coord = light_space_pos.xyz / light_space_pos.w;
    vec2 uv_coord;

    uv_coord.x = 0.5 * proj_coord.x + 0.5; 
    uv_coord.y = 0.5 * proj_coord.y + 0.5; 
    float z = 0.5 * proj_coord.z + 0.5; 
    
    vec4 depth_sample = vec4(0.0);
    if (cascade == 0)
        depth_sample = texture2D(tex_csm_0, uv_coord.st);
    else if (cascade == 1)
        depth_sample = texture2D(tex_csm_1, uv_coord.st);
    else if (cascade == 2)
        depth_sample = texture2D(tex_csm_2, uv_coord.st);

    return depth_sample;
    /*
    if (Depth < z + 0.00001) 
        return 0.5;
    else 
    return 1.0; 
    */
}

void main()
{
    vec4 color = texture2D(tex0, var_texcoord0.xy);

    /*
    // Diffuse light calculations.
    vec3 ambient_light = vec3(0.2);
    vec3 diff_light    = vec3(normalize(var_light.xyz - var_position.xyz));
    diff_light         = max(dot(var_normal,1.0 - diff_light), 0.0) + ambient_light;
    diff_light         = clamp(diff_light, 0.0, 1.0);
    vec4 depth_proj    = var_texcoord0_shadow / var_texcoord0_shadow.w;
    */

    vec4 visibility = vec4(0.0);

    for (int i=0; i < 3; i++)
    {
        if (var_position_clip.z <= u_cascade_limits[i])
        {
            visibility = get_visibility(i, var_texcoord0_shadow[i]);
            break;
        }
    }
    
    gl_FragColor = vec4(mix(color.rgb,visibility.rgb,0.5),1.0);
}

