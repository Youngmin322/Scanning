//
//  MeshExporter.swift
//  Scanning
//
//  Created by Youngmin Cho on 11/19/25.
//

import Foundation
import ARKit

private extension SIMD4 where Scalar == Float {
    var xyz: SIMD3<Float> { SIMD3(x, y, z) }
}

class MeshExporter {
    // ARMeshAnchor 배열을 obj 파일로 저장
    static func exportToOBJ(meshAnchors: [ARMeshAnchor]) -> (url: URL, vertextCount: Int)? {
        guard !meshAnchors.isEmpty else {
            print("저장할 메쉬 없음")
            
            return nil
        }
        
        print("OBJ 파일 생성 시작: \(meshAnchors.count)")
        
        var objContent = "# Exported from Scanning App \n"
        objContent += "# Total meshes: \(meshAnchors.count)\n\n"
        
        var totalVertexCount = 0
        
        // 각 메쉬를 OBJ 포맷으로 변환
        for (index, meshAnchor) in meshAnchors.enumerated() {
            objContent += "# Mesh \(index + 1)\n"
            objContent += "o Mesh_\(index + 1)\n"
            
            let geometry = meshAnchor.geometry
            let transform = meshAnchor.transform
            
            // 정점(Vertices) 추가
            let vertexSource = geometry.vertices
            let vertexCount = vertexSource.count
            let vertexStride = vertexSource.stride
            let vertexOffset = vertexSource.offset
            let vertexBuffer = vertexSource.buffer
            let vertexPointer = vertexBuffer.contents().advanced(by: vertexOffset)

            for vertexIndex in 0..<vertexCount {
                let byteOffset = vertexIndex * vertexStride
                let basePtr = vertexPointer.advanced(by: byteOffset)
                // Each vertex is a SIMD3<Float> (Float x 3)
                let x = basePtr.load(as: Float.self)
                let y = basePtr.advanced(by: MemoryLayout<Float>.size).load(as: Float.self)
                let z = basePtr.advanced(by: MemoryLayout<Float>.size * 2).load(as: Float.self)

                let worldPosition = (transform * SIMD4<Float>(x, y, z, 1.0)).xyz
                objContent += "v \(worldPosition.x) \(worldPosition.y) \(worldPosition.z)\n"
            }
            
            // 면(Faces) 추가
            let faces = geometry.faces
            for faceIndex in 0..<faces.count {
                let face = faces[faceIndex]
                
                // OBJ는 1-based 인덱스 사용
                let v1 = Int(face[0]) + 1 + totalVertexCount
                let v2 = Int(face[1]) + 1 + totalVertexCount
                let v3 = Int(face[2]) + 1 + totalVertexCount
                
                // OBJ 포맷: f v1 v2 v3
                objContent += "f \(v1) \(v2) \(v3)\n"
            }
            
            totalVertexCount += geometry.vertices.count
            objContent += "\n"
        }
        
        // 파일 저장 로직
        let fileName = "scan_\(Date().timeIntervalSince1970).obj"
        let documentsPath = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            try objContent.write(to: fileURL, atomically: true, encoding: .utf8)
            print("OBJ 파일 저장 완료")
            print("경로: \(fileURL.path)")
            print("통계:")
            print("   - 메쉬 개수: \(meshAnchors.count)")
            print("   - 총 정점: \(totalVertexCount)")
            return (fileURL, totalVertexCount)
        } catch {
            print("파일 저장 실패: \(error)")
            return nil
        }
    }
}

// ARGeometryElement Extension (Face 접근용)
extension ARGeometryElement {
    subscript(index: Int) -> [Int32] {
        let buffer = self.buffer.contents()
        let stride = self.bytesPerIndex
        let offset = index * self.indexCountPerPrimitive * stride
        
        var indices: [Int32] = []
        for i in 0..<self.indexCountPerPrimitive {
            let indexOffset = offset + (i * stride)
            if stride == 2 {
                let value = buffer.load(fromByteOffset: indexOffset, as: UInt16.self)
                indices.append(Int32(value))
            } else {
                let value = buffer.load(fromByteOffset: indexOffset, as: Int32.self)
                indices.append(value)
            }
        }
        return indices
    }
}
