varying highp vec4   var_position;
varying mediump vec3 var_normal;
varying mediump vec2 var_texcoord0;

uniform mediump mat4   mtx_view;
uniform lowp sampler2D tex_positions;
uniform lowp sampler2D tex_normals;
uniform lowp sampler2D tex_albedo;

uniform mediump vec4 u_window_size;
uniform mediump vec4 u_light_position;
uniform mediump vec4 u_light_color;
uniform mediump vec4 u_light_properties;

vec3 lighting_diffuse(vec3 pos, vec3 nor, vec3 albedo, vec3 light_pos)
{
    float linear      = u_light_properties.x;
    float quadratic   = u_light_properties.y;
    float radius      = u_light_properties.z;
    vec3 light_vec    = light_pos - pos;
    vec3 light_dir    = normalize(light_vec);
    float distance    = length(light_vec);
    vec3 diffuse      = max(dot(nor, light_dir), 0.0) * albedo * u_light_color.rgb;
    float attenuation = 1.0 / (1.0 + linear * distance + quadratic * distance * distance);

    return diffuse * attenuation;
}

void main()
{
    vec2 uv              = gl_FragCoord.st / u_window_size.st;
    vec4 sample_position = texture2D(tex_positions, uv);
    vec4 sample_normal   = texture2D(tex_normals, uv);
    vec4 sample_albedo   = texture2D(tex_albedo, uv);
    vec4 light_pos_view  = mtx_view * vec4(u_light_position.xyz, 1.0);
    vec3 diffuse_color   = lighting_diffuse(sample_position.rgb, sample_normal.rgb, sample_albedo.rgb, light_pos_view.xyz);
    gl_FragColor         = vec4(diffuse_color, 1.0);
}

