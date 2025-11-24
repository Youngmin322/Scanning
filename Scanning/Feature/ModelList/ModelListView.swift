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
