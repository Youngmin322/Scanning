//
//  Extensions.swift
//  Scanning
//
//  Created by Youngmin Cho on 11/19/25.
//

import ARKit

extension ARGeometrySource {
    func asSIMD3(ofType type: Float.Type) -> [SIMD3<Float>] {
        assert(componentsPerVector == 3, "Expected 3 components per vector")
        
        return (0..<count).map { index in
            let offset = index * stride
            let x = buffer.contents().load(fromByteOffset: offset, as: Float.self)
            let y = buffer.contents().load(fromByteOffset: offset + 4, as: Float.self)
            let z = buffer.contents().load(fromByteOffset: offset + 8, as: Float.self)
            return SIMD3<Float>(x, y, z)
        }
    }
}
