//
//  AppStore.swift
//  xmaxx
//
//  Created by Codex on 3/30/26.
//

import Combine
import SwiftUI

enum MicState: String {
    case idle
    case listening
    case processing

    var label: String {
        switch self {
        case .idle:
            return "Idle"
        case .listening:
            return "Listening..."
        case .processing:
            return "Processing..."
        }
    }

    var accent: Color {
        switch self {
        case .idle:
            return Color(red: 0.34, green: 0.59, blue: 0.96)
        case .listening:
            return Color(red: 0.97, green: 0.51, blue: 0.24)
        case .processing:
            return Color(red: 0.38, green: 0.79, blue: 0.60)
        }
    }
}

enum TaskStatus: String {
    case queued
    case running
    case completed

    var label: String {
        rawValue.capitalized
    }

    var tint: Color {
        switch self {
        case .queued:
            return Color(red: 0.64, green: 0.67, blue: 0.75)
        case .running:
            return Color(red: 0.97, green: 0.66, blue: 0.18)
        case .completed:
            return Color(red: 0.36, green: 0.80, blue: 0.60)
        }
    }
}

struct TaskStep: Identifiable, Hashable {
    let id = UUID()
    let title: String
    var isComplete = false
}

struct SimulatedTask: Identifiable, Hashable {
    let id = UUID()
    let command: String
    var status: TaskStatus
    var steps: [TaskStep]
}

@MainActor
final class AppStore: ObservableObject {
    @Published var micState: MicState = .idle
    @Published private(set) var tasks: [SimulatedTask] = []
    @Published var selectedTaskID: SimulatedTask.ID?

    private let recipes: [(command: String, steps: [String])] = [
        (
            "Open Safari",
            [
                "Launch app",
                "Bring to front",
                "Done"
            ]
        ),
        (
            "Organize Desktop",
            [
                "Scan files",
                "Group related items",
                "Done"
            ]
        ),
        (
            "Search Google",
            [
                "Open browser",
                "Load search page",
                "Done"
            ]
        )
    ]

    private var nextRecipeIndex = 0

    var selectedTask: SimulatedTask? {
        tasks.first(where: { $0.id == selectedTaskID })
    }

    func triggerMic() {
        guard micState == .idle else { return }

        Task {
            await runMicSequence()
        }
    }

    func selectTask(_ task: SimulatedTask) {
        selectedTaskID = task.id
    }

    private func runMicSequence() async {
        micState = .listening
        try? await Task.sleep(nanoseconds: 2_000_000_000)

        guard !Task.isCancelled else {
            micState = .idle
            return
        }

        micState = .processing
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        guard !Task.isCancelled else {
            micState = .idle
            return
        }

        let task = makeTask()
        tasks.insert(task, at: 0)
        selectedTaskID = task.id
        micState = .idle

        Task {
            await simulateExecution(for: task.id)
        }
    }

    private func makeTask() -> SimulatedTask {
        let recipe = recipes[nextRecipeIndex % recipes.count]
        nextRecipeIndex += 1

        return SimulatedTask(
            command: recipe.command,
            status: .running,
            steps: recipe.steps.map { TaskStep(title: $0) }
        )
    }

    private func simulateExecution(for taskID: UUID) async {
        guard let stepCount = tasks.first(where: { $0.id == taskID })?.steps.count else {
            return
        }

        for stepIndex in 0..<stepCount {
            try? await Task.sleep(nanoseconds: UInt64.random(in: 500_000_000...1_000_000_000))

            guard !Task.isCancelled else { return }
            guard let taskIndex = tasks.firstIndex(where: { $0.id == taskID }) else { return }

            tasks[taskIndex].steps[stepIndex].isComplete = true
        }

        guard let taskIndex = tasks.firstIndex(where: { $0.id == taskID }) else { return }
        tasks[taskIndex].status = .completed
    }
}
