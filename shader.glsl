#version 410 core

uniform float fGlobalTime;// in seconds
uniform vec2 v2Resolution;// viewport resolution (in pixels)
uniform float fFrameTime;// duration of the last frame, in seconds

uniform sampler1D texFFT;// towards 0.0 is bass / lower freq, towards 1.0 is higher / treble freq
uniform sampler1D texFFTSmoothed;// this one has longer falloff and less harsh transients
uniform sampler1D texFFTIntegrated;// this is continually increasing
uniform sampler2D texPreviousFrame;// screenshot of the previous frame
uniform sampler2D texChecker;
uniform sampler2D texNoise;
uniform sampler2D texTex1;
uniform sampler2D texTex2;
uniform sampler2D texTex3;
uniform sampler2D texTex4;

layout(location=0)out vec4 out_color;

float pi=acos(-1);
float t=mod(fGlobalTime,10*pi);

float sphere(vec3 p, float r){
  return length(p) - r;
  }
  
  float box(vec3 p, vec3 s){
    vec3 b = abs(p) - s;
    return max(max(b.x, b.y), b.z);
  }
  
  float rec (vec3 p, float s){
  return step(s, p.x);
}

float scene(vec3 p){
  p= mod(p, 5)-2.5;
  //float s = sphere(p, 1.*cos(cos(t)/(3.14/2))) ;
  float s = sphere(p, .71) ;
  float b = box(p, vec3(.7));
  float r= rec(p, 0.3*cos(t));
  return min(b,s-b);
}



vec3 camera(vec2 uv, vec3 origin, vec3 target, float zoom){
  vec3 forward = normalize(target - origin); // direction de la camera
  vec3 side = normalize(cross(vec3(0.,1.,0.), forward)); 
  vec3 up = cross(forward, side);  // les 2 vecteurs étant normalize up sera normalisé
  return normalize(forward * zoom + uv.x * side + uv.y * up);
}

vec3 normal (vec3 p) {
  vec2 e = vec2(0.001, 0.);
  return normalize(scene(p) - vec3(scene(p-e.xyy), scene(p-e.yxy), scene(p - e.yyx)));
}

void main(void)
{
	vec2 uv=vec2(gl_FragCoord.x/v2Resolution.x,gl_FragCoord.y/v2Resolution.y);
	uv-=.5;
	uv/=vec2(v2Resolution.y/v2Resolution.x,1.);
  
  //vec3 origin = vec3(.5*sin(t)+ 0.,.7*sin(t)*cos(t)+0.,-2.);
  vec3 origin = vec3(0.,0.,-2.);
  vec3 target = vec3(0.);
  vec3 dir = camera(uv, origin, target, 0.8);
  
  vec3 col = vec3(0.);
  
  vec3 dirlight = normalize(vec3(1.,1.,-1.+sin(t)));
  
  float dist = 0.;
  for (int i=0; i<100; i++) {
    float mindist = scene(origin + dir * dist);
    if(mindist < 0.001 ) {
      vec3 touch = origin + dir * dist;
      vec3 normale = normal(touch);
      float diffuse = max(0., dot (normale, dirlight)); // supprime les valeur négative
      float frenel = pow( max(0., 1.- dot(normale, -dir)) , 3);
      float specular = pow(max(0., dot(dir, reflect(dirlight, normale))), 100.);
      col +=  frenel + diffuse + specular;
      break;
    }
    if (dist >100.) break;
    dist += mindist;
  }
  
	
	
	
	out_color.rgb = col;
}