shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
#define iResolution 1.0/SCREEN_PIXEL_SIZE
#define iTime TIME
#define fragCoord FRAGCOORD
#define fragColor COLOR
uniform sampler2D iChannel0;
uniform bool curvature =  true;
uniform bool mask =  true;
uniform bool scan_line = true;
uniform bool transparency = false;
uniform bool mode2 = false;
uniform vec4 trim_color = vec4(1.0);

vec2 CRTCurveUV( vec2 uv )
{
    uv = uv * 2.0 - 1.0;
    vec2 offset = abs( uv.yx ) / vec2( 3.0, 2.0 );
    uv = uv + uv * offset * offset;
    uv = uv * 0.5 + 0.5;
    return uv;
}

void DrawVignette( inout vec3 color, vec2 uv )
{    
    float vignette = uv.x * uv.y * ( 1.0 - uv.x ) * ( 1.0 - uv.y );
    vignette = clamp( pow( 16.0 * vignette, 0.3 ), 0.0, 1.0 );
    color *= vignette;
}

void DrawScanline( inout vec3 color, vec2 uv )
{
    float scanline 	= clamp( 0.95 + 0.05 * cos( 3.14 * ( uv.y + 0.008 * iTime ) * 240.0 * 1.0 ), 0.0, 1.0 );
    float grille 	= 0.85 + 0.15 * clamp( 1.5 * cos( 3.14 * uv.x * 640.0 * 1.0 ), 0.0, 1.0 );    
    color *= scanline * grille * 1.2;
}

void fragment()
{
    // we want to see at least 224x192 (overscan) and we want multiples of pixel size
    float resMultX  = floor( iResolution.x / 224.0 );
    float resMultY  = floor( iResolution.y / 192.0 );
    float resRcp	= 1.0 / max( min( resMultX, resMultY ), 1.0 );
    
    float time			= iTime;
    float screenWidth	= floor( iResolution.x * resRcp );
    float screenHeight	= floor( iResolution.y * resRcp );
    float pixelX 		= floor( fragCoord.x * resRcp );
    float pixelY 		= 220. - floor( fragCoord.y * resRcp );

    vec3 color = textureLod(screen_texture, SCREEN_UV, 0.0).xyz;
 	
    
    
    // CRT effects (curvature, vignette, scanlines and CRT grille)
    vec2 uv  = UV ;
    vec2 crtUV = CRTCurveUV( uv );
	if (curvature == true){
		if ( crtUV.x < 0.0 || crtUV.x > 1.0 || crtUV.y < 0.0 || crtUV.y > 1.0 )
    {
        color = vec3( 0.0, 0.0, 0.0 );
    }
	}
	if (mask == true){
		DrawVignette( color, uv );
	}
    if (scan_line == true)
    {
		DrawScanline( color, uv );
	}
	
	fragColor.xyz 	= color;
    fragColor.w		= 1.0;
	if (transparency == true){
		fragColor.w		= color.r;
	}
	vec4 col1 = texture(iChannel0, UV);
	vec4 col2;
	vec4 col3 = vec4(fragColor.rgb, fragColor.r);
	if (mode2 == true){
		if (curvature == true){
			col1.rgb = texture(iChannel0, crtUV).rgb;
		}
		col2.rgb = smoothstep(0.0, 0.2, fragColor.rgb);
		fragColor = mix(vec4((col1.rgb  * col2.rgb), 1.0), vec4(col3.rgb, 1.0), 0.9);
		if (transparency == true){
			fragColor.a = fragColor.r;
		}
		}
	fragColor = vec4(fragColor.r * trim_color.r, fragColor.g * trim_color.g,fragColor.b * trim_color.b,fragColor.a * trim_color.a);
}
