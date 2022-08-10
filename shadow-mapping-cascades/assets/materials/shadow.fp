uniform vec4 u_color;

vec4 float_to_rgba( float v )
{
	vec4 enc = vec4(1.0, 255.0, 65025.0, 16581375.0) * v;
	enc      = fract(enc);
	enc     -= enc.yzww * vec4(1.0/255.0,1.0/255.0,1.0/255.0,0.0);
	return enc;
}

void main()
{
	gl_FragColor = vec4(gl_FragCoord.z, gl_FragCoord.st / 1024.0, 1.0); // float_to_rgba(gl_FragCoord.z);
}
