//
//  ScanModel.swift
//  Scanning
//
//  Created by Youngmin Cho on 11/19/25.
//

import Foundation
import SwiftData

@Model
final class ScanModel {
    var id: UUID
    var fileName: String
    var filePath: String
    var createdAt: Date
    var meshCount: Int
    var vertextCount: Int
    
    init(fileName: String, filePath: String, meshCount: Int, vertextCount: Int) {
        self.id = UUID()
        self.fileName = fileName
        self.filePath = filePath
        self.createdAt = Date()
        self.meshCount = meshCount
        self.vertextCount = vertextCount
    }
}
