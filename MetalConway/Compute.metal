//
//  Shader.metal
//  MetalConway
//
//  Created by Sky Zhang on 2018/08/05.
//  Copyright © 2018 Sky Zhang. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;


bool check_alive(float4 color) {
    return color.x >= 0.5;
}

kernel void conway_func(texture2d<float, access::read> input [[texture(0)]],
                        texture2d<float, access::write> output [[texture(1)]],
                        uint2 gid [[thread_position_in_grid]]) {
    int width = output.get_width(), height = output.get_height();
    bool is_alive = check_alive(input.read(gid));
    int neighbours = 0;
    for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
            if (!(i == 0 && j == 0)) {
                int _x = i + gid.x, _y = j + gid.y;
                if (_x >= 0 && _x < width && _y >= 0 && _y < height) {
                    if (check_alive(input.read(uint2(_x, _y)))) {
                        ++neighbours;
                    }
                }
            }
        }
    }
    
    if (is_alive) {
        if (neighbours < 2 || neighbours > 3)
            output.write(float4(0.0, 1.0, 1.0, 1.0), gid);
        else
            output.write(float4(1.0, 1.0, 1.0, 1.0), gid);
    } else {
        if (neighbours == 3)
            output.write(float4(1.0, 0.0, 0.0, 1.0), gid);
        else
            output.write(float4(0.0, 0.0, 0.0, 1.0), gid);
    }
}
