#[compute]
# version 450

#include "triangle_table.glsl"

const float voxel_size = 0.05;
const uint chunk_size = 4;
// const float border_dist = 0.2;

// uvec3 num_wg = gl_NumWorkGroups;

// CompactVec3, use to fit in 12 bytes, vec3 is padded to 16 bytes
struct CVec3 {
    float x,y,z;
};

// Invocations in the (x, y, z) dimension
layout(local_size_x = chunk_size, local_size_y = chunk_size, local_size_z = chunk_size) in;
uvec3 wg_size = gl_WorkGroupSize;

layout(set = 0, binding = 0) readonly buffer SFDSize{
    int sfd_size[3];
};

layout(set = 0, binding = 2, std430) readonly buffer SDF {
    float sdf[];
};

layout(set = 0, binding = 3, std430) restrict buffer VertexBuffer {
    CVec3 vertices[]; 
    // vec4 vertices[];
};

layout(set = 0, binding = 4, std430) writeonly buffer NormalBuffer {
    CVec3 normals[];
    // vec4 normals[];
};

 layout(set = 0, binding = 5, std430) restrict buffer NumberOfVertices{
    uint number_of_vertices;
 };

void main() {
    uvec3 i_glob = gl_GlobalInvocationID;
    // Make sure this is not a border cell (otherwise neighbor lookup in the next step would fail):
    if( i_glob.x >= sfd_size[0]-1 ||
		  i_glob.y >= sfd_size[1]-1 ||
		  i_glob.z >= sfd_size[2]-1 )
		  return;

    // Calculate connection index
    uint y_up = sfd_size[0];
    uint z_up = y_up*sfd_size[1];
    uint sdf_i = (z_up*i_glob.z + y_up*i_glob.y + i_glob.x);

    int conn_index = 0;
    if (sdf[sdf_i]  < 0) conn_index |= 1;
    if (sdf[sdf_i + 1]  < 0) conn_index |= 2;
    if (sdf[sdf_i + z_up + 1]  < 0) conn_index |= 4;
    if (sdf[sdf_i + z_up]  < 0) conn_index |= 8;
    if (sdf[sdf_i + y_up]  < 0) conn_index |= 16;
    if (sdf[sdf_i + y_up + 1]  < 0) conn_index |= 32;
    if (sdf[sdf_i + y_up + z_up + 1]  < 0) conn_index |= 64;
    if (sdf[sdf_i + y_up + z_up]  < 0) conn_index |= 128;

    int tri_vert_indices[15] = tConnectionTable[conn_index];
    uint vertex_i = 0;
    for (int i=14; i>-1; i -= 3) {
        if (tri_vert_indices[i] != -1) {
            // Atomic counter for tight buffer
            vertex_i = atomicAdd(number_of_vertices, 3);
            // Add next 3 verts in series
            for (int tri_i = 0; tri_i < 3; tri_i++){
                int conn[6] = eConnectionTable[tri_vert_indices[i - tri_i]];
                uvec3 indA = uvec3(conn[0], conn[1], conn[2]);
                uvec3 indB = uvec3(conn[3], conn[4], conn[5]);
                float weightA = sdf[sdf_i + indA.x + indA.y*y_up + indA.z*z_up];
                float weightB = sdf[sdf_i + indB.x + indB.y*y_up + indB.z*z_up];
                vec3 point = (i_glob + mix(indA, indB, abs(weightA/(weightA-weightB))))*voxel_size;
                vertices[vertex_i + tri_i].x = point.x - 2.5;
                vertices[vertex_i + tri_i].y = point.y;
                vertices[vertex_i + tri_i].z = point.z - 2.5;
                // vertices[vertex_i].xyz = point - vec3(2.5,0,2.5);
            }
            // Add normals every 3 verts
                vec3 face_normal = normalize( cross( (vec3(vertices[vertex_i+2].x,vertices[vertex_i+2].y,vertices[vertex_i+2].z)-vec3(vertices[vertex_i+1].x,vertices[vertex_i+1].y,vertices[vertex_i+1].z)), 
                                                    (vec3(vertices[vertex_i+2].x,vertices[vertex_i+2].y,vertices[vertex_i+2].z)-vec3(vertices[vertex_i].x,vertices[vertex_i].y,vertices[vertex_i].z)) ) );
                normals[vertex_i].x = face_normal.x;
                normals[vertex_i].y = face_normal.y;
                normals[vertex_i].z = face_normal.z;
                normals[vertex_i+1].x = face_normal.x;
                normals[vertex_i+1].y = face_normal.y;
                normals[vertex_i+1].z = face_normal.z;
                normals[vertex_i+2].x = face_normal.x;
                normals[vertex_i+2].y = face_normal.y;
                normals[vertex_i+2].z = face_normal.z;
                // normals[vertex_i].xyz = face_normal;
                // normals[vertex_i-1].xyz = face_normal;
                // normals[vertex_i-2].xyz = face_normal;
            // }
        }
    }
}