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

float get_visibility(vec3 depth_data)
{
    float depth            = rgba_to_float(texture2D(tex_depth, depth_data.st));
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

void main()
{
    vec4 color = texture2D(tex0, var_texcoord0.xy);

    // Diffuse light calculations.
    vec3 ambient_light = vec3(0.2);
    vec3 diff_light    = vec3(normalize(var_light.xyz - var_position.xyz));
    diff_light         = max(dot(var_normal,1.0 - diff_light), 0.0) + ambient_light;
    diff_light         = clamp(diff_light, 0.0, 1.0);

    // Note: We need to divide the projected coordinate by the w component to move it from
    // clip space into a UV coordinate that we can use to sample the depth map from.
    // When we set the gl_Position in the vertex shader, this is done automatically for
    // us by the hardware but since we are just passing the multiplied value along as 
    // a varying we have to do it ourselves. Just google perspective division by w or 
    // something similar and you'll find better resources that explains the reasoning.
    // Also note that this is only really needed for perspective projections.
    vec4 depth_proj = var_texcoord0_shadow / var_texcoord0_shadow.w;    
    gl_FragColor    = vec4(color.rgb*diff_light * get_visibility(depth_proj.xyz),1.0);
}

