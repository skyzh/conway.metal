//
//  ViewController.swift
//  MetalConway
//
//  Created by Sky Zhang on 2018/08/05.
//  Copyright © 2018 Sky Zhang. All rights reserved.
//

import MetalKit

class ViewController: MTKView {
    var commandQ: MTLCommandQueue?
    var cps: MTLComputePipelineState?
    var inTexture: MTLTexture?
    var outTexture: MTLTexture?
    
    var threadGroups: MTLSize?
    var threadGroupCount: MTLSize?
    
    var data: [Float]
    
    let WIDTH = 1920
    let HEIGHT = 1080
    
    var initFlag = false
    
    required init(coder: NSCoder) {
        data = [Float]()
        for _ in 0..<WIDTH {
            for _ in 0..<HEIGHT {
                let is_alive = arc4random_uniform(2) == 0 ? true : false
                if (is_alive) {
                    data.append(1.0)
                    data.append(1.0)
                    data.append(1.0)
                    data.append(1.0)
                } else {
                    data.append(0.0)
                    data.append(0.0)
                    data.append(0.0)
                    data.append(1.0)
                }
            }
        }
        super.init(coder: coder)
        device = MTLCreateSystemDefaultDevice()
        commandQ = device!.makeCommandQueue()
        let library = device!.makeDefaultLibrary()!
        cps = try! device!.makeComputePipelineState(function: library.makeFunction(name: "conway_func")!)
        
        if let drawable = currentDrawable {
            var td = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: WIDTH, height: HEIGHT, mipmapped: false)
            td.usage = .shaderRead
            inTexture = device!.makeTexture(descriptor: td)
            td.usage = .shaderWrite
            outTexture = device!.makeTexture(descriptor: td)
            
            threadGroupCount = MTLSizeMake(16, 8, 1)
            threadGroups = MTLSizeMake(WIDTH / threadGroupCount!.width, HEIGHT / threadGroupCount!.height, 1
            )
        }
        self.framebufferOnly = false
    }
    
    override func draw() {
        super.draw()
        if let drawable = currentDrawable {
            let commandBuffer = commandQ!.makeCommandBuffer()!
            let computeEncoder = commandBuffer.makeComputeCommandEncoder()!
            computeEncoder.setComputePipelineState(cps!)
            computeEncoder.setTexture(inTexture, index: 0)
            computeEncoder.setTexture(outTexture, index: 1)
            computeEncoder.dispatchThreadgroups(threadGroups!, threadsPerThreadgroup: threadGroupCount!)
            computeEncoder.endEncoding()
            let blitEncoder = commandBuffer.makeBlitCommandEncoder()!
            blitEncoder.synchronize(resource: outTexture!)
            if !initFlag {
                let floatSize = MemoryLayout<Float>.size
                let buffer = device!.makeBuffer(bytes: data, length: floatSize * data.count)!
                blitEncoder.copy(from: buffer, sourceOffset: 0, sourceBytesPerRow: WIDTH * floatSize * 4,
                                 sourceBytesPerImage: WIDTH * HEIGHT * floatSize * 4,
                                 sourceSize: MTLSizeMake(WIDTH, HEIGHT, 1),
                                 to: outTexture!,
                                 destinationSlice: 0, destinationLevel: 0, destinationOrigin: MTLOriginMake(0, 0, 0))
                initFlag = true
            }
            blitEncoder.copy(from: outTexture!, sourceSlice: 0, sourceLevel: 0,
                             sourceOrigin: MTLOriginMake(0, 0, 0), sourceSize: MTLSizeMake(WIDTH, HEIGHT, 1),
                             to: drawable.texture, destinationSlice: 0, destinationLevel: 0, destinationOrigin: MTLOriginMake(0, 0, 0))
            blitEncoder.copy(from: outTexture!, sourceSlice: 0, sourceLevel: 0, sourceOrigin: MTLOriginMake(0, 0, 0), sourceSize: MTLSizeMake(outTexture!.width, outTexture!.height, 1), to: inTexture!, destinationSlice: 0, destinationLevel: 0, destinationOrigin: MTLOriginMake(0, 0, 0))
            blitEncoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}
