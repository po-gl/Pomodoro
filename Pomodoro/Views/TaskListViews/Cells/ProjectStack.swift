//
//  ProjectStack.swift
//  Pomodoro
//
//  Created by Porter Glines on 10/19/23.
//

import SwiftUI
import OSLog

struct ProjectStack: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.managedObjectContext) private var viewContext

    @Environment(\.isReordering) private var isReordering
    @Environment(\.selectedReorderingIndex) private var selectedReorderingIndex
    @Environment(\.selectedReorderingRect) private var selectedReorderingRect

    @FetchRequest(fetchRequest: ProjectsData.currentProjectsRequest)
    private var currentProjects: FetchedResults<Project>

    @ObservedObject var isCollapsed: ObservableValue<Bool>

    var collapsedRowHeight: Double { !dynamicTypeSize.isAccessibilitySize ? 85 : 135 }
    var spacing = 8.0

    @ObservedObject var metrics: ObservableValue<[CGRect]> = ObservableValue([])
    var emptyMetricBinding = Binding(get: { CGRect.zero }, set: { _ in })
    @State var reorderCompensatingOffsets: [CGFloat] = []

    var body: some View {
        HStack(alignment: .top) {
            VStack(spacing: spacing) {
                if currentProjects.count > 0 {
                    ForEach(Array(zip(currentProjects.indices, currentProjects)), id: \.1) { i, project in
                        let iDouble = Double(i)
                        let reorderOffset = offsetForReorder(index: i)
                        ProjectCell(project: project,
                                    isCollapsed: isCollapsed,
                                    cellHeight: collapsedRowHeight,
                                    index: i,
                                    rect: (!isCollapsed.value && i < metrics.value.count) ? $metrics.value[i] : emptyMetricBinding)
                        .opacity(isCollapsed.value ? 1 - (0.3 * iDouble) : 1.0)
                        .scaleEffect(isCollapsed.value ? 1 - (0.08 * iDouble) : 1.0)
                        .offset(y: isCollapsed.value ? -iDouble * collapsedRowHeight + (iDouble * 3) : 0.0)

                        .offset(y: reorderOffset)
                        .animation(.bouncy, value: reorderOffset)
                        .offset(y: i < reorderCompensatingOffsets.count ? reorderCompensatingOffsets[i] : 0.0)

                        .compositingGroup()
                        .animation(.easeInOut(duration: isCollapsed.value ? 0.2 : 0.4), value: isCollapsed.value)
                    }
                } else {
                    EmptyProjectsView(cellHeight: collapsedRowHeight)
                }
            }
            .frame(maxHeight: isCollapsed.value ? collapsedRowHeight*1.25 : .infinity, alignment: .top)
        }
        .compositingGroup()

        .onAppear {
            metrics.value = Array(repeating: CGRect.zero, count: currentProjects.count)
            reorderCompensatingOffsets = Array(repeating: CGFloat.zero, count: currentProjects.count)
        }
        .onChange(of: currentProjects.count) { count in
            metrics.value = Array(repeating: CGRect.zero, count: count)
            reorderCompensatingOffsets = Array(repeating: CGFloat.zero, count: count)
        }

        .onChange(of: isReordering.value) { isReordering in
            if !isReordering {
                do {
                    if selectedReorderingIndex.value >= 0 {
                        metrics.value[selectedReorderingIndex.value] = selectedReorderingRect.value
                    }
                    try reorder()
                } catch {
                    Logger().error("Error reordering projects: \(error.localizedDescription)")
                }
            }
        }
    }

    private func offsetForReorder(index: Int) -> Double {
        guard isReordering.value else { return 0.0 }
        guard index < metrics.value.count else { return 0.0 }
        guard selectedReorderingIndex.value < metrics.value.count else { return 0.0 }
        let rect = metrics.value[index]
        let selectedRect = metrics.value[selectedReorderingIndex.value]

        if  index > selectedReorderingIndex.value && rect.midY < selectedRect.midY {
            return -(selectedRect.height + spacing/2)
        } else if index < selectedReorderingIndex.value && rect.midY > selectedRect.midY {
            return selectedRect.height + spacing/2
        }
        return 0.0
    }

    private func reorder() throws {
        guard currentProjects.count == metrics.value.count &&
                metrics.value.count == reorderCompensatingOffsets.count else { throw ReorderError.unevenArrays }

        let metricsWithIndices = Array(zip(metrics.value.indices, metrics.value))
        let indicesByPositionOrder = metricsWithIndices
            .sorted(by: { $0.1.midY < $1.1.midY })
            .map { $0.0 }

        addReorderCompensatingOffsets(indicesByPositionOrder)
        Task { @MainActor in
            // Animation matches draggable offset animation to cancel it
            withAnimation(.bouncy) {
                setReorderCompensatingOffetsToZero()
            }
        }

        for (newOrder, oldOrder) in indicesByPositionOrder.enumerated() {
            ProjectsData.setOrderWithoutSaving(newOrder, for: currentProjects[oldOrder], context: viewContext)
        }
        ProjectsData.saveContextSync(viewContext, errorMessage: "CoreData error reordering projects.")
    }

    private func addReorderCompensatingOffsets(_ sortedIndices: [Int]) {
        for (newOrder, oldOrder) in sortedIndices.enumerated() {
            let diff = oldOrder - newOrder
            if diff == 0 { continue }

            var compensatingOffset = selectedReorderingRect.value.height + spacing/2
            if diff > 0 {  // moved up
                compensatingOffset *= 1.0
            } else if diff < 0 {  // moved down
                compensatingOffset *= -1.0
            }

            if oldOrder == selectedReorderingIndex.value {
                compensatingOffset *= abs(Double(diff)) - 1.0
            }

            reorderCompensatingOffsets[newOrder] = compensatingOffset
        }
    }

    private func setReorderCompensatingOffetsToZero() {
        for i in reorderCompensatingOffsets.indices {
            reorderCompensatingOffsets[i] = 0.0
        }
    }
}

enum ReorderError: Error {
    case unevenArrays
}

#Preview {
    ScrollView {
        ProjectStack(isCollapsed: ObservableValue(false))
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .padding(.horizontal)
    }
}
