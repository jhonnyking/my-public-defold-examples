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

const int NUM_CASCADES = 3;

float rgba_to_float(vec4 rgba)
{
    return dot(rgba, vec4(1.0, 1.0/255.0, 1.0/65025.0, 1.0/16581375.0));
}

vec4 get_visibility(int cascade, vec4 light_space_pos)
{
    vec3 debug_color = vec3(0.0);
    vec3 proj_coord = light_space_pos.xyz / light_space_pos.w;
    vec2 uv_coord;

    /*
    uv_coord.x = 0.5 * proj_coord.x + 0.5; 
    uv_coord.y = 0.5 * proj_coord.y + 0.5; 
    float z = 0.5 * proj_coord.z + 0.5; 
    */
    
    vec4 csm_sample = vec4(0.0);
    if (cascade == 0)
    {
        csm_sample = texture2D(tex_csm_0, proj_coord.st);
        debug_color = vec3(1.0,0.0,0.0);
    }
    else if (cascade == 1)
    {
        csm_sample = texture2D(tex_csm_1, proj_coord.st);
        debug_color = vec3(0.0,1.0,0.0);
    }
    else if (cascade == 2)
    {
        csm_sample = texture2D(tex_csm_2, proj_coord.st);
        debug_color = vec3(0.0,0.0,1.0);
    }

    float depth_sample = csm_sample.r; // rgba_to_float(csm_sample);
    float depth_bias = 0.01; // 0.00001
    
    if (depth_sample < proj_coord.z - depth_bias)
        return vec4(debug_color, 0.0);
    else 
        return vec4(debug_color, 1.0);
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

    for (int i=0; i < NUM_CASCADES; i++)
    {
        if (var_position_clip.z <= u_cascade_limits[i])
        {
            visibility = get_visibility(i, var_texcoord0_shadow[i]);
            break;
        }
    }
    
    // gl_FragColor.rgb = mix(color.rgb, visibility.rgb, visibility.a);
    gl_FragColor.rgb = mix(visibility.rgb * 0.5,visibility.rgb,visibility.a) + color.rgb * 0.0001;

    //gl_FragColor.rgb = visibility.rgb + color.rgb * 0.0001;
    gl_FragColor.a   = 1.0;
}

