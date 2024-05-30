shader_type canvas_item;
// Star Nest by Pablo Roman Andrioli
// License: MIT

#define iterations 10
#define formuparam 0.93

#define volsteps 10
#define stepsize 0.1

#define tile   0.850
#define speed  0.010 

#define brightness 0.0005
#define darkmatter 0.300
#define distfading 0.730
#define saturation 0.850

uniform vec2 position;
uniform float aspectRatio;
uniform float zoom;

void fragment() {
    vec2 uv=SCREEN_UV-.5;
    uv.y *= aspectRatio;
    vec3 dir=vec3(uv*zoom,1.);
    float time=1.0;

    //mouse rotation
    float a1=.5+0.0;
    float a2=.8+0.0;
    vec3 from=vec3(1.,.5,0.5);
    from+=vec3(position,-2.);

    //volumetric rendering
    float s=0.1,fade=1.;
    vec3 v=vec3(0.);
    for (int r=0; r<volsteps; r++) {
        vec3 p=from+s*dir*.5;
        p = abs(vec3(tile)-mod(p,vec3(tile*2.))); // tiling fold
        float pa,a=pa=0.;
        for (int i=0; i<iterations; i++) { 
            p=abs(p)/dot(p,p)-formuparam; // the magic formula
            a+=abs(length(p)-pa); // absolute sum of average change
            pa=length(p);
        }
        float dm=max(0.,darkmatter-a*a*.001); //dark matter
        a*=a*a; // add contrast
        if (r>6) fade*=1.-dm; // dark matter, don't render near
                      //v+=vec3(dm,dm*.5,0.);
        v+=fade;
        v+=vec3(s,s*s,s*s*s*s)*a*brightness*fade; // coloring based on distance
        fade*=distfading; // distance fading
        s+=stepsize;
    }
    v=mix(vec3(length(v)),v,saturation); //color adjust
    COLOR = vec4(v*.01,1.);
}
