shader_type spatial;

#define LIT unshaded
#define CULL cull_back
#define DEPTH depth_draw_opaque
#define BLEND blend_mix
#define ALPHA_SCISSOR

#include "psx_base.gdshaderinc"
