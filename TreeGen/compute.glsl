#[compute]
# version 450

#include "triangle_table.glsl"

const float voxel_size = 0.05;
const uint chunk_size = 1;


uvec3 num_wg = gl_NumWorkGroups;

// CompactVec3, use to fit in 12 bytes, vec3 is padded to 16 bytes
// struct CVec3 {
//     float x,y,z;
// };

// Invocations in the (x, y, z) dimension
layout(local_size_x = chunk_size, local_size_y = chunk_size, local_size_z = chunk_size) in;
uvec3 wg_size = gl_WorkGroupSize;

layout(set = 0, binding = 0) readonly buffer InputCloud{
    int cloud[];
};

layout(set = 0, binding = 1, std430) restrict buffer VertexBuffer {
    // CVec3 vertices[];
    vec3 vertices[];
};

layout(set = 0, binding = 2, std430) writeonly buffer NormalBuffer {
    // CVec3 normals[];
    vec3 normals[];
};


void main() {
    uvec3 i_glob = gl_GlobalInvocationID;
    // Make sure this is not a border cell (otherwise neighbor lookup in the next step would fail):
    if( i_glob.x >= num_wg.x*chunk_size-1 ||
		  i_glob.y >= num_wg.y*chunk_size-1 ||
		  i_glob.z >= num_wg.z*chunk_size-1 )
		  return;

    // Calculate connection index
    uint y_up = num_wg.x*wg_size.x;
    uint z_up = y_up*num_wg.y*wg_size.y;
    uint cloud_i = (z_up*i_glob.z + y_up*i_glob.y + i_glob.x);
    uint vertex_i = cloud_i*15;
    int conn_index = int((cloud[cloud_i]) +
                         (cloud[cloud_i + 1] << 1) +
                         (cloud[cloud_i + z_up + 1] << 2) +
                         (cloud[cloud_i + z_up] << 3) +
                         (cloud[cloud_i + y_up] << 4) +
                         (cloud[cloud_i + y_up + 1] << 5 ) +
                         (cloud[cloud_i + y_up + z_up + 1] << 6) + 
                         (cloud[cloud_i + y_up + z_up] << 7));

    int tri_vert_indices[15] = tConnectionTable[conn_index];
    
    for (int i=14; i>-1; i--) {
        if (tri_vert_indices[i] > -1) {
            int conn[6] = eConnectionTable[tri_vert_indices[i]];
            uvec3 indA = uvec3(conn[0], conn[1], conn[2]);
            uvec3 indB = uvec3(conn[3], conn[4], conn[5]);
            vec3 point = (2*i_glob + indA + indB)*voxel_size/2;
            // vertices[vertex_i].x = point.x;
            // vertices[vertex_i].y = point.y;
            // vertices[vertex_i].z = point.z;
            vertices[vertex_i] = point - vec3(2.5,0,2.5);
            // Add normals every 3 verts
            if (i % 3 == 0){
                vec3 face_normal = normalize( cross( (vertices[vertex_i]-vertices[vertex_i-1]), (vertices[vertex_i]-vertices[vertex_i-2]) ) );
                // normals[vertex_i].x = face_normal.x;
                // normals[vertex_i].y = face_normal.y;
                // normals[vertex_i].z = face_normal.z;
                // normals[vertex_i-1].x = face_normal.x;
                // normals[vertex_i-1].y = face_normal.y;
                // normals[vertex_i-1].z = face_normal.z;
                // normals[vertex_i-2].x = face_normal.x;
                // normals[vertex_i-2].y = face_normal.y;
                // normals[vertex_i-2].z = face_normal.z;
                normals[vertex_i] = face_normal;
                normals[vertex_i-1] = face_normal;
                normals[vertex_i-2] = face_normal;
            }
        } 
        vertex_i += 1;
    }
}