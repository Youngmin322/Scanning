//
//  ModelListView.swift
//  Scanning
//
//  Created by Youngmin Cho on 11/24/25.
//

import SwiftUI
import SwiftData

struct ModelListView: View {
    @Query(sort: \ScanModel.createdAt, order: .reverse) private var models: [ScanModel]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            if models.isEmpty {
                ContentUnavailableView(
                    "저장된 모델 없음",
                    systemImage: "cube.transparent",
                    description: Text("사물을 스캔하여 모델을 만들어보세요.")
                )
            } else {
                List {
                    ForEach(models) { model in
                        NavigationLink(destination: ModelDetailView(model: model)) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(model.fileName)
                                        .font(.headline)
                                    Text(model.createdAt.formatted(date: .abbreviated, time: .shortened))
                                    
                                    Spacer()
                                    
                                    Text("\(model.meshCount) Meshes")
                                        .font(.caption2)
                                        .padding(4)
                                        .background(.secondary.opacity(0.2))
                                        .cornerRadius(4)
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
}

import SwiftData

@MainActor
let previewContainer: ModelContainer = {
    // 임시(in-memory) 컨테이너: 프리뷰 전용
    let schema = Schema([ScanModel.self])
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    return try! ModelContainer(for: schema, configurations: [configuration])
}()

@MainActor
let previewContainerWithSamples: ModelContainer = {
    let schema = Schema([ScanModel.self])
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [configuration])

    let context = container.mainContext

    // 필요한 생성자 파라미터에 맞게 조정하세요.
    // 예시: ScanModel(fileName:filePath:meshCount:vertextCount:)
    let sample1 = ScanModel(
        fileName: "Scan_1",
        filePath: "/tmp/scan1.obj",
        meshCount: 12,
        vertextCount: 10234
    )
    let sample2 = ScanModel(
        fileName: "Scan_2",
        filePath: "/tmp/scan2.obj",
        meshCount: 8,
        vertextCount: 7321
    )

    context.insert(sample1)
    context.insert(sample2)
    try? context.save()
    return container
}()

#Preview("Empty") {
    ModelListView()
        .modelContainer(previewContainer)
}

#Preview("With Samples") {
    ModelListView()
        .modelContainer(previewContainerWithSamples)
}
