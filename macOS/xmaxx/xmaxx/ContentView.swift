//
//  ContentView.swift
//  xmaxx
//
//  Created by Armen Merikyan on 3/30/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var store = AppStore()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.07, blue: 0.11),
                    Color(red: 0.08, green: 0.10, blue: 0.16)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay(alignment: .topTrailing) {
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 340, height: 340)
                    .blur(radius: 90)
                    .offset(x: 90, y: -120)
            }
            .ignoresSafeArea()

            HStack(spacing: 18) {
                MicPanel(store: store)
                    .frame(width: 220)

                TaskListPanel(store: store)
                    .frame(maxWidth: .infinity)

                TaskInspectorPanel(task: store.selectedTask)
                    .frame(width: 300)
            }
            .padding(20)
        }
        .frame(minWidth: 1120, minHeight: 720)
        .preferredColorScheme(.dark)
    }
}

private struct MicPanel: View {
    @ObservedObject var store: AppStore

    var body: some View {
        PanelSurface {
            VStack(spacing: 22) {
                Spacer()

                Button(action: store.triggerMic) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        store.micState.accent.opacity(0.95),
                                        store.micState.accent.opacity(0.60)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Circle()
                            .stroke(Color.white.opacity(0.16), lineWidth: 1.5)

                        Circle()
                            .stroke(store.micState.accent.opacity(0.25), lineWidth: 14)
                            .scaleEffect(store.micState == .idle ? 1.0 : 1.10)

                        Image(systemName: "mic.fill")
                            .font(.system(size: 40, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 138, height: 138)
                    .shadow(color: store.micState.accent.opacity(0.35), radius: 24, y: 12)
                    .scaleEffect(store.micState == .idle ? 1.0 : 1.04)
                    .animation(.easeInOut(duration: 0.25), value: store.micState)
                }
                .buttonStyle(.plain)
                .disabled(store.micState != .idle)

                VStack(spacing: 8) {
                    Text(store.micState.label)
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Click to simulate a command")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.58))
                        .multilineTextAlignment(.center)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct TaskListPanel: View {
    @ObservedObject var store: AppStore

    var body: some View {
        PanelSurface {
            VStack(alignment: .leading, spacing: 18) {
                panelTitle("Tasks", subtitle: "Commands update here over time.")

                if store.tasks.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("No simulated tasks yet")
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Use the mic button to add a command and watch each step complete.")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.6))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(store.tasks) { task in
                                TaskCard(
                                    task: task,
                                    isSelected: task.id == store.selectedTaskID
                                ) {
                                    store.selectTask(task)
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

private struct TaskInspectorPanel: View {
    let task: SimulatedTask?

    var body: some View {
        PanelSurface {
            if let task {
                VStack(alignment: .leading, spacing: 18) {
                    panelTitle("Inspector", subtitle: "Selected task details.")

                    VStack(alignment: .leading, spacing: 12) {
                        Text(task.command)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        StatusBadge(status: task.status)
                    }

                    Divider()
                        .overlay(Color.white.opacity(0.08))

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Steps")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.7))

                        ForEach(Array(task.steps.enumerated()), id: \.element.id) { index, step in
                            HStack(alignment: .center, spacing: 12) {
                                Image(systemName: step.isComplete ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundStyle(step.isComplete ? TaskStatus.completed.tint : Color.white.opacity(0.35))

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(step.title)
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.white)

                                    Text(step.isComplete ? "Completed" : "Pending")
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundStyle(step.isComplete ? TaskStatus.completed.tint : Color.white.opacity(0.45))
                                }

                                Spacer(minLength: 12)

                                Text("\(index + 1)")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color.white.opacity(0.35))
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.white.opacity(0.04))
                            )
                        }
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                VStack(spacing: 10) {
                    Text("No task selected")
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Click a task card to inspect the full command and step progress.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.58))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

private struct TaskCard: View {
    let task: SimulatedTask
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    Text(task.command)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    StatusBadge(status: task.status)
                }

                VStack(alignment: .leading, spacing: 9) {
                    ForEach(task.steps) { step in
                        HStack(spacing: 10) {
                            Image(systemName: step.isComplete ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(step.isComplete ? TaskStatus.completed.tint : Color.white.opacity(0.28))

                            Text(step.title)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(step.isComplete ? Color.white.opacity(0.85) : Color.white.opacity(0.55))

                            Spacer(minLength: 0)
                        }
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(isSelected ? 0.10 : 0.05))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        isSelected ? Color.white.opacity(0.20) : Color.white.opacity(0.08),
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(.plain)
    }
}

private struct StatusBadge: View {
    let status: TaskStatus

    var body: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(status.tint)
                .frame(width: 8, height: 8)

            Text(status.label)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(status.tint)
        }
    }
}

private struct PanelSurface<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.white.opacity(0.06))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            }
    }
}

@ViewBuilder
private func panelTitle(_ title: String, subtitle: String) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        Text(title)
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(Color.white.opacity(0.55))

        Text(subtitle)
            .font(.system(size: 24, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview {
    ContentView()
}
