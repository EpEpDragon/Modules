#[compute]
# version 450

const float voxel_size = 0.05;
const uint chunk_size = 4;
const float border_dist = 0.2;

// Invocations in the (x, y, z) dimension
layout(local_size_x = chunk_size, local_size_y = chunk_size, local_size_z = chunk_size) in;

layout(set = 0, binding = 0) readonly buffer SFDSize{
    int sfd_size[3];
};

layout(set = 0, binding = 1) readonly buffer BakedPoints{
    vec4 baked_points[];
};

layout(set = 0, binding = 2, std430) writeonly buffer SDF {
    float sdf[];
};

void main() {
    uvec3 i_glob = gl_GlobalInvocationID;
    
    // Calculate closest distance to baked curve points
    vec3 coord_world = i_glob*voxel_size - vec3(2.5, 0, 2.5);
    float min_dist = 1000;
    for (int i = 0; i < baked_points.length(); i++) {
        float dist = length(coord_world - baked_points[i].xyz);
        if (dist < min_dist) {
            min_dist = dist;
        }
    }
    // Set SDF dist
    sdf[sfd_size[1]*sfd_size[0]*i_glob.z + sfd_size[0]*i_glob.y + i_glob.x] = min_dist - border_dist;
}