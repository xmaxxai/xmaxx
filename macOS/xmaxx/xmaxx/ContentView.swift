//
//  ContentView.swift
//  xmaxx
//
//  Created by Armen Merikyan on 3/30/26.
//

import SwiftUI
import SceneKit

struct ContentView: View {
    @StateObject private var store = AppStore()
    @State private var isSettingsPresented = false
    @State private var didAppear = false

    var body: some View {
        GeometryReader { proxy in
            let layout = DashboardLayout(width: proxy.size.width)

            ZStack {
                backgroundView

                ScrollView(.vertical) {
                    VStack(spacing: 18) {
                        HeaderBar(store: store, isCompact: layout.isHeaderCompact) {
                            isSettingsPresented = true
                        } onNewSession: {
                            store.startNewSession()
                        }

                        if layout.prefersSingleColumn {
                            VStack(spacing: 18) {
                                ControlDeckPanel(store: store) {
                                    isSettingsPresented = true
                                }

                                MissionBoard(store: store, availableWidth: layout.contentWidth)

                                ActivityRail(store: store)
                            }
                        } else if layout.prefersTwoColumns {
                            VStack(spacing: 18) {
                                ControlDeckPanel(store: store) {
                                    isSettingsPresented = true
                                }

                                HStack(alignment: .top, spacing: 18) {
                                    MissionBoard(store: store, availableWidth: layout.secondaryColumnWidth)
                                        .frame(maxWidth: .infinity, alignment: .top)

                                    ActivityRail(store: store)
                                        .frame(width: layout.railWidth)
                                }
                            }
                        } else {
                            HStack(alignment: .top, spacing: 18) {
                                ControlDeckPanel(store: store) {
                                    isSettingsPresented = true
                                }
                                .frame(width: layout.controlWidth)

                                MissionBoard(store: store, availableWidth: layout.centerWidth)
                                    .frame(maxWidth: .infinity, alignment: .top)

                                ActivityRail(store: store)
                                    .frame(width: layout.railWidth)
                            }
                        }
                    }
                    .padding(20)
                    .frame(width: max(proxy.size.width - 1, layout.minimumCanvasWidth), alignment: .topLeading)
                    .frame(minHeight: max(proxy.size.height - 1, 720), alignment: .topLeading)
                }
                .scrollIndicators(.visible)
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $isSettingsPresented) {
            SettingsSheet(store: store)
        }
        .onAppear {
            guard !didAppear else { return }
            didAppear = true
            store.triggerPermissionProbesIfNeeded()
            store.autoStartIfPossible()
        }
        .onDisappear {
            store.markApplicationClosedGracefully()
        }
    }

    private var backgroundView: some View {
        LinearGradient(
            colors: [
                Color(red: 0.05, green: 0.07, blue: 0.10),
                Color(red: 0.07, green: 0.10, blue: 0.16),
                Color(red: 0.03, green: 0.05, blue: 0.09)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(alignment: .topLeading) {
            Circle()
                .fill(Color(red: 0.33, green: 0.78, blue: 0.70).opacity(0.18))
                .frame(width: 420, height: 420)
                .blur(radius: 110)
                .offset(x: -90, y: -120)
        }
        .overlay(alignment: .bottomTrailing) {
            Circle()
                .fill(Color(red: 0.98, green: 0.58, blue: 0.24).opacity(0.14))
                .frame(width: 480, height: 480)
                .blur(radius: 140)
                .offset(x: 120, y: 120)
        }
        .ignoresSafeArea()
    }
}

private struct HeaderBar: View {
    @ObservedObject var store: AppStore
    let isCompact: Bool
    let onOpenSettings: () -> Void
    let onNewSession: () -> Void

    var body: some View {
        Group {
            if isCompact {
                VStack(alignment: .leading, spacing: 16) {
                    titleBlock

                    HStack(spacing: 12) {
                        StatusPill(title: store.status.title, subtitle: store.statusMessage)
                        newSessionButton
                        settingsButton
                    }
                }
            } else {
                HStack(spacing: 18) {
                    titleBlock

                    Spacer()

                    HStack(spacing: 12) {
                        StatusPill(title: store.status.title, subtitle: store.statusMessage)
                        newSessionButton
                        settingsButton
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("xmaxx Computer")
                .font(.system(size: 38, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text("\(store.activeDecisionProfile.title): \(store.activeDecisionProfile.subtitle)")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.62))
        }
    }

    private var newSessionButton: some View {
        Button(action: onNewSession) {
            Text("New Session")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }

    private var settingsButton: some View {
        Menu {
            Button("Profile & API Key") {
                onOpenSettings()
            }
        } label: {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                }
        }
        .menuStyle(.borderlessButton)
    }
}

private struct DashboardLayout {
    let width: CGFloat

    var prefersSingleColumn: Bool { width < 980 }
    var prefersTwoColumns: Bool { width >= 980 && width < 1320 }
    var isHeaderCompact: Bool { width < 880 }

    var controlWidth: CGFloat {
        min(max(width * 0.24, 300), 360)
    }

    var railWidth: CGFloat {
        min(max(width * 0.25, 300), 360)
    }

    var centerWidth: CGFloat {
        max(width - controlWidth - railWidth - 76, 520)
    }

    var secondaryColumnWidth: CGFloat {
        max(width - railWidth - 58, 560)
    }

    var contentWidth: CGFloat {
        max(width - 40, 320)
    }

    var minimumCanvasWidth: CGFloat {
        if prefersSingleColumn {
            return max(width - 1, 0)
        }

        if prefersTwoColumns {
            return 980
        }

        return 1220
    }
}

private struct ControlDeckPanel: View {
    @ObservedObject var store: AppStore
    let onOpenSettings: () -> Void

    var body: some View {
        PanelSurface {
            VStack(alignment: .leading, spacing: 18) {
                sectionLabel("Mission Control")

                Text("Shape the guided loop")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Feed the model the real mission, current machine state, and fresh steering. The tighter the inputs, the better the next move.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.62))
                    .fixedSize(horizontal: false, vertical: true)

                SessionSummaryCard(store: store)

                fieldBlock(title: "Mission") {
                    VStack(alignment: .leading, spacing: 10) {
                        VoiceLoopControl(store: store)

                        if !store.voiceAnalysisSummary.isEmpty {
                            Text(store.voiceAnalysisSummary)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(Color(red: 0.56, green: 0.82, blue: 0.77))
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Text("One control now handles both listening and loop execution. If the mission text is already filled in, starting here runs it immediately and keeps the mic live for steering. If not, it listens first and starts after your first spoken pause.")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.42))
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        TextEditor(text: $store.missionText)
                            .scrollContentBackground(.hidden)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(12)
                            .frame(minHeight: 132)
                            .background(panelInputBackground)
                    }
                }

                fieldBlock(title: "Planning Surface") {
                    VStack(alignment: .leading, spacing: 14) {
                        DecisionModelSelector(store: store)

                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Iteration Budget")
                                    .font(.system(size: 12, weight: .black, design: .rounded))
                                    .foregroundStyle(Color.white.opacity(0.48))

                                Text("Cap the loop at \(store.maxIterations) guided \(store.maxIterations == 1 ? "cycle" : "cycles").")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundStyle(Color.white.opacity(0.62))
                            }

                            Spacer()

                            Stepper(value: $store.maxIterations, in: 1...12) {
                                EmptyView()
                            }
                            .labelsHidden()
                        }
                        .padding(14)
                        .background(panelInputBackground)
                    }
                }

                fieldBlock(title: "Loop Context") {
                    VStack(alignment: .leading, spacing: 12) {
                        ContextEditor(title: "Environment", text: $store.environmentText, minHeight: 150)
                        ContextEditor(title: "Operator Feedback", text: $store.operatorFeedback, minHeight: 96)
                    }
                }

                fieldBlock(title: "Automation") {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            PermissionCapsule(title: "Accessibility", isGranted: store.isAccessibilityGranted)
                            PermissionCapsule(title: "Screen", isGranted: store.isScreenRecordingGranted)
                        }

                        Text(store.automationStatusMessage)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.70))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(14)
                    .background(panelInputBackground)
                }

                VStack(alignment: .leading, spacing: 10) {
                    if let prompt = store.pendingOperatorPrompt {
                        OperatorPromptCard(store: store, prompt: prompt)
                    }

                    if store.chatGPTAPIKey.isEmpty {
                        Button("Add ChatGPT API Key") {
                            onOpenSettings()
                        }
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.74))
                        .buttonStyle(.plain)
                    }
                }

                Spacer()
            }
        }
    }

    private var panelInputBackground: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color.black.opacity(0.18))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            }
    }
}

private struct MissionBoard: View {
    @ObservedObject var store: AppStore
    let availableWidth: CGFloat

    var body: some View {
        VStack(spacing: 18) {
            PanelSurface {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            sectionLabel("Decision Model")
                            Text(store.activeDecisionProfile.stageHeadline)
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 8) {
                            Text(store.activeDecisionProfile.title)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.white.opacity(0.65))

                            Text("Iteration \(store.currentIteration) / \(store.maxIterations)")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.white.opacity(0.48))
                        }
                    }

                    ProgressView(value: store.objectiveProgress) {
                        Text("Objective Progress")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.46))
                    } currentValueLabel: {
                        Text("\(Int(store.objectiveProgress * 100))%")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .tint(Color(red: 0.57, green: 0.89, blue: 0.74))

                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(store.sections) { section in
                            NavigationCard(section: section)
                        }
                    }
                }
            }

            PanelSurface {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            sectionLabel("Action Queue")
                            Text("Operator-facing action plan")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }

                        Spacer()
                    }

                    if store.actionQueue.isEmpty {
                        Text("No actions yet. Run the guided loop to generate the next plan.")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.55))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(store.actionQueue) { action in
                                    ActionRow(action: action)
                                }
                            }
                        }
                        .scrollIndicators(.visible)
                    }
                }
            }

            PanelSurface {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            sectionLabel("3D Loop Graph")
                            Text("Live guided topology")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }

                        Spacer()

                        Text("\(store.actionGraphSnapshot.nodes.count) nodes")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.62))
                    }

                    ActionGraphScene(snapshot: store.actionGraphSnapshot)
                        .frame(minHeight: 320)

                    Text("The graph updates as the loop changes, linking \(store.activeDecisionProfile.stageHeadline) to the actions and CLI suggestions that are queued, running, blocked, or done.")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.48))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

private extension MissionBoard {
    var columns: [GridItem] {
        let columnCount = availableWidth < 760 ? 1 : 2
        return Array(
            repeating: GridItem(.flexible(), spacing: 16, alignment: .top),
            count: columnCount
        )
    }
}

private struct ActionGraphScene: View {
    let snapshot: ActionGraphSnapshot

    var body: some View {
        SceneView(
            scene: makeScene(from: snapshot),
            pointOfView: nil,
            options: [.allowsCameraControl, .autoenablesDefaultLighting]
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        }
    }

    private func makeScene(from snapshot: ActionGraphSnapshot) -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = NSColor(calibratedRed: 0.05, green: 0.07, blue: 0.11, alpha: 1)

        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0, 18)
        scene.rootNode.addChildNode(cameraNode)

        let keyLight = SCNNode()
        keyLight.light = SCNLight()
        keyLight.light?.type = .omni
        keyLight.position = SCNVector3(8, 10, 14)
        scene.rootNode.addChildNode(keyLight)

        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.color = NSColor.white.withAlphaComponent(0.35)
        scene.rootNode.addChildNode(ambient)

        let positions = layoutPositions(for: snapshot.nodes)
        let positionMap = Dictionary(uniqueKeysWithValues: zip(snapshot.nodes.map(\.id), positions))

        for edge in snapshot.edges {
            guard let from = positionMap[edge.fromID], let to = positionMap[edge.toID] else { continue }
            scene.rootNode.addChildNode(edgeNode(from: from, to: to, weight: edge.weight))
        }

        for (index, node) in snapshot.nodes.enumerated() {
            let visual = makeNodeVisual(for: node)
            visual.position = positions[index]
            scene.rootNode.addChildNode(visual)
        }

        return scene
    }

    private func layoutPositions(for nodes: [ActionGraphNode]) -> [SCNVector3] {
        nodes.enumerated().map { index, node in
            switch node.kind {
            case .loop:
                return SCNVector3(0, 4.8, 0)
            case let .phase(phase):
                switch phase {
                case .observe:
                    return SCNVector3(-6.0, 1.9, 0)
                case .orient:
                    return SCNVector3(-3.0, 1.1, 1.6)
                case .decide:
                    return SCNVector3(0, 0.8, -1.7)
                case .act:
                    return SCNVector3(3.0, 1.1, 1.6)
                case .guide:
                    return SCNVector3(6.0, 1.9, 0)
                }
            case .action:
                let actionIndex = max(index - 6, 0)
                let row = actionIndex % 3
                let column = actionIndex / 3
                return SCNVector3(
                    Float(-4 + (row * 4)),
                    Float(-2.5 - Double(column * 2)),
                    Float((row - 1) * 2)
                )
            }
        }
    }

    private func makeNodeVisual(for node: ActionGraphNode) -> SCNNode {
        let geometry: SCNGeometry
        switch node.kind {
        case .loop:
            geometry = SCNSphere(radius: 0.82)
        case .phase:
            geometry = SCNBox(width: 1.3, height: 1.3, length: 1.3, chamferRadius: 0.28)
        case .action:
            geometry = SCNCapsule(capRadius: 0.46, height: 1.8)
        }

        let accent = color(for: node.kind)
        geometry.firstMaterial?.diffuse.contents = accent.withAlphaComponent(0.92)
        geometry.firstMaterial?.emission.contents = accent.withAlphaComponent(0.28 * node.emphasis)

        let container = SCNNode()
        let bodyNode = SCNNode(geometry: geometry)
        container.addChildNode(bodyNode)

        let text = SCNText(string: node.title, extrusionDepth: 0.18)
        text.font = .systemFont(ofSize: 0.48, weight: .bold)
        text.flatness = 0.2
        text.firstMaterial?.diffuse.contents = NSColor.white.withAlphaComponent(0.92)

        let textNode = SCNNode(geometry: text)
        let (minBounds, maxBounds) = text.boundingBox
        textNode.position = SCNVector3(
            -((maxBounds.x - minBounds.x) / 2),
            -1.55,
            0
        )
        textNode.scale = SCNVector3(0.34, 0.34, 0.34)
        container.addChildNode(textNode)

        let rotationDuration = max(4.0, 14.0 - (node.emphasis * 6.0))
        let spin = SCNAction.repeatForever(
            SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: rotationDuration)
        )
        bodyNode.runAction(spin)

        return container
    }

    private func edgeNode(from: SCNVector3, to: SCNVector3, weight: Double) -> SCNNode {
        let source = SCNGeometrySource(vertices: [from, to])
        let element = SCNGeometryElement(indices: [Int32(0), Int32(1)], primitiveType: .line)
        let geometry = SCNGeometry(sources: [source], elements: [element])
        geometry.firstMaterial?.diffuse.contents = NSColor.white.withAlphaComponent(0.18 + weight * 0.35)
        return SCNNode(geometry: geometry)
    }

    private func color(for kind: ActionGraphNode.Kind) -> NSColor {
        switch kind {
        case .loop:
            return NSColor(calibratedRed: 0.91, green: 0.95, blue: 0.98, alpha: 1)
        case let .phase(phase):
            switch phase {
            case .observe:
                return NSColor(calibratedRed: 0.35, green: 0.73, blue: 0.96, alpha: 1)
            case .orient:
                return NSColor(calibratedRed: 0.55, green: 0.84, blue: 0.65, alpha: 1)
            case .decide:
                return NSColor(calibratedRed: 0.98, green: 0.74, blue: 0.28, alpha: 1)
            case .act:
                return NSColor(calibratedRed: 0.99, green: 0.48, blue: 0.36, alpha: 1)
            case .guide:
                return NSColor(calibratedRed: 0.80, green: 0.88, blue: 0.43, alpha: 1)
            }
        case .action:
            return NSColor(calibratedRed: 0.83, green: 0.87, blue: 0.94, alpha: 1)
        }
    }
}

private struct ActivityRail: View {
    @ObservedObject var store: AppStore

    var body: some View {
        VStack(spacing: 18) {
            PanelSurface {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            sectionLabel("Conversation")
                            Text("Operator dialog")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }

                        Spacer()

                        Text(store.audioDialogueMode.title)
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.88))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(Color.white.opacity(0.08))
                            )
                    }

                    HStack(spacing: 8) {
                        railBadge(title: "Session \(store.sessionNumber)", accent: Color.white.opacity(0.34))
                        railBadge(title: store.voiceFlowState.title, accent: voiceFlowAccent)
                        if store.awaitingActionConfirmation {
                            railBadge(title: "Approval", accent: Color(red: 0.98, green: 0.74, blue: 0.28))
                        } else if store.hasPendingOperatorPrompt {
                            railBadge(title: "Question", accent: Color(red: 0.55, green: 0.84, blue: 0.65))
                        }
                    }

                    Text(store.voiceFlowTitle)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(store.voiceFlowDetail)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.70))
                        .fixedSize(horizontal: false, vertical: true)

                    if !store.voiceAnalysisSummary.isEmpty {
                        Text(store.voiceAnalysisSummary)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(Color(red: 0.56, green: 0.82, blue: 0.77))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(store.conversationEntries) { message in
                                ConversationBubble(message: message, profileName: store.profileName)
                            }
                        }
                    }
                    .frame(minHeight: 300, maxHeight: 420)
                    .scrollIndicators(.visible)
                }
            }

            PanelSurface {
                VStack(alignment: .leading, spacing: 16) {
                    sectionLabel("Recent Cycles")
                    Text("Cycle History")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(store.cycles) { cycle in
                                CycleCard(
                                    cycle: cycle,
                                    isSelected: cycle.id == store.selectedCycleID
                                ) {
                                    store.selectCycle(cycle)
                                }
                            }
                        }
                    }
                    .scrollIndicators(.visible)
                }
            }

            PanelSurface {
                VStack(alignment: .leading, spacing: 16) {
                    sectionLabel("Inspector")
                    Text("Cycle Detail")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    if let cycle = store.selectedCycle {
                        VStack(alignment: .leading, spacing: 14) {
                            Text(cycle.summary)
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                                .fixedSize(horizontal: false, vertical: true)

                            infoLine("Iteration", value: "\(cycle.iteration)")
                            infoLine("Progress", value: "\(Int(cycle.progress * 100))%")
                            infoLine("Mission", value: cycle.mission)
                            infoLine("Model", value: cycle.model)
                            infoLine("Environment", value: cycle.environment)

                            if let blocker = cycle.blocker, cycle.isBlocked {
                                infoLine("Blocker", value: blocker)
                            }
                        }
                    } else {
                        Text("Select a cycle to inspect the generated plan.")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.55))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
    }

    @ViewBuilder
    private func infoLine(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.48))

            Text(value)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.84))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func railBadge(title: String, accent: Color) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                Capsule(style: .continuous)
                    .fill(accent.opacity(0.18))
            )
            .overlay {
                Capsule(style: .continuous)
                    .stroke(accent.opacity(0.34), lineWidth: 1)
            }
    }

    private var voiceFlowAccent: Color {
        switch store.voiceFlowState {
        case .idle:
            return Color(red: 0.69, green: 0.72, blue: 0.82)
        case .listening:
            return Color(red: 0.35, green: 0.73, blue: 0.96)
        case .captured:
            return Color(red: 0.98, green: 0.74, blue: 0.28)
        case .processing:
            return Color(red: 0.57, green: 0.89, blue: 0.74)
        case .speaking:
            return Color(red: 0.92, green: 0.60, blue: 0.26)
        case .error:
            return Color(red: 0.99, green: 0.54, blue: 0.44)
        }
    }
}

private struct NavigationCard: View {
    let section: NavigationSection

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 7) {
                    Text(section.stageTitle.uppercased())
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(accent.opacity(0.9))

                    Text(section.stagePrompt)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.58))

                    Text(section.headline)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }

                Spacer()

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(accent)
                    .padding(10)
                    .background(
                        Circle()
                            .fill(accent.opacity(0.12))
                    )
            }

            Text(section.narrative)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(section.bullets, id: \.self) { bullet in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(accent)
                            .frame(width: 7, height: 7)
                            .padding(.top, 5)

                        Text(bullet)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.84))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            HStack {
                Text("Confidence")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.48))

                Spacer()

                Text("\(Int(section.confidence * 100))%")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(accent)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.08))

                    Capsule()
                        .fill(accent)
                        .frame(width: max(26, geometry.size.width * section.confidence))
                }
            }
            .frame(height: 10)
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 265, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(accent.opacity(0.10))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(accent.opacity(0.22), lineWidth: 1)
        }
    }

    private var accent: Color {
        switch section.phase {
        case .observe:
            return Color(red: 0.35, green: 0.73, blue: 0.96)
        case .orient:
            return Color(red: 0.55, green: 0.84, blue: 0.65)
        case .decide:
            return Color(red: 0.98, green: 0.74, blue: 0.28)
        case .act:
            return Color(red: 0.99, green: 0.48, blue: 0.36)
        case .guide:
            return Color(red: 0.80, green: 0.88, blue: 0.43)
        }
    }

    private var icon: String {
        switch section.phase {
        case .observe:
            return "eye.fill"
        case .orient:
            return "brain.head.profile"
        case .decide:
            return "point.topleft.down.curvedto.point.bottomright.up.fill"
        case .act:
            return "bolt.fill"
        case .guide:
            return "location.viewfinder"
        }
    }
}

private struct ActionRow: View {
    let action: ActionItem

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(statusColor.opacity(0.16))
                .frame(width: 12)
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(statusColor)
                        .frame(width: 4)
                }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(action.title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer()

                    Text(action.status.rawValue.capitalized)
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(statusColor)
                        .fixedSize(horizontal: true, vertical: false)
                }

                if action.tool == "shell_command" {
                    Text(action.target)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.78))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.black.opacity(0.22))
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        }
                } else {
                    Text("\(action.tool) -> \(action.target)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.50))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let x = action.x, let y = action.y {
                    Text(String(format: "Coordinates: %.1f, %.1f", x, y))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.50))
                }

                Text(action.rationale)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)

                if let output = action.output, !output.isEmpty {
                    Text(output)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(statusColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        }
    }

    private var statusColor: Color {
        switch action.status {
        case .queued:
            return Color(red: 0.69, green: 0.72, blue: 0.82)
        case .ready:
            return Color(red: 0.57, green: 0.89, blue: 0.74)
        case .blocked:
            return Color(red: 0.99, green: 0.54, blue: 0.44)
        case .done:
            return Color(red: 0.42, green: 0.77, blue: 0.96)
        }
    }
}

private struct CycleCard: View {
    let cycle: NavigationCycle
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(cycle.createdAt, style: .time)
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.50))

                    Spacer()

                    Text(cycle.model)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.42))
                }

                HStack {
                    Text("Cycle \(cycle.iteration)")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.62))

                    Spacer()

                    Text("\(Int(cycle.progress * 100))%")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.62))
                }

                Text(cycle.mission)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Text(cycle.summary)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.62))
                    .lineLimit(3)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.white.opacity(isSelected ? 0.10 : 0.05))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(isSelected ? 0.18 : 0.08), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct SessionSummaryCard: View {
    @ObservedObject var store: AppStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(store.sessionHeadline)
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(store.sessionDetail)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.68))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                summaryStat(title: "Cycles", value: "\(store.cycles.count)")
                summaryStat(title: "Dialog", value: "\(store.dialogueCount)")
                summaryStat(title: "Started", value: sessionStartedLabel)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        }
    }

    private var sessionStartedLabel: String {
        store.sessionStartedAt.formatted(date: .omitted, time: .shortened)
    }

    private func summaryStat(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.44))

            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.16))
        )
    }
}

private struct ContextEditor: View {
    let title: String
    @Binding var text: String
    let minHeight: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.48))

            TextEditor(text: $text)
                .scrollContentBackground(.hidden)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.88))
                .padding(12)
                .frame(minHeight: minHeight)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.black.opacity(0.18))
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                }
        }
    }
}

private struct OperatorPromptCard: View {
    @ObservedObject var store: AppStore
    let prompt: OperatorPrompt

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: prompt.kind == .startupAssessment ? "clock.arrow.trianglehead.counterclockwise.rotate.90" : "questionmark.bubble.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(accent)

                Text(prompt.title)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Spacer()

                Text(prompt.kind == .startupAssessment ? "Recovery" : "Waiting")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(
                        Capsule(style: .continuous)
                            .fill(accent.opacity(0.22))
                    )
            }

            Text(prompt.question)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            Text(prompt.detail)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.66))
                .fixedSize(horizontal: false, vertical: true)

            if prompt.acceptsResponse {
                TextField(prompt.responsePlaceholder, text: $store.pendingOperatorResponseDraft, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.black.opacity(0.18))
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    }
            }

            HStack(spacing: 10) {
                Button(prompt.proceedLabel) {
                    if prompt.kind == .actionApproval {
                        store.confirmPendingActions()
                    } else {
                        store.proceedPendingOperatorPrompt()
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(proceedEnabled ? Color.black.opacity(0.82) : Color.white.opacity(0.46))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(proceedEnabled ? accent : Color.white.opacity(0.10))
                )
                .disabled(!proceedEnabled)

                Button(prompt.reviseLabel) {
                    store.revisePendingOperatorPrompt()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white.opacity(0.86))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(accent.opacity(0.12))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(accent.opacity(0.24), lineWidth: 1)
        }
    }

    private var accent: Color {
        switch prompt.kind {
        case .startupAssessment:
            return Color(red: 0.42, green: 0.77, blue: 0.96)
        case .actionApproval:
            return Color(red: 0.98, green: 0.74, blue: 0.28)
        case .checkpoint:
            return Color(red: 0.55, green: 0.84, blue: 0.65)
        case .question:
            return Color(red: 0.95, green: 0.50, blue: 0.32)
        }
    }

    private var proceedEnabled: Bool {
        !prompt.requiresResponse || !store.pendingOperatorResponseDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

private struct ConversationBubble: View {
    let message: ConversationMessage
    let profileName: String

    var body: some View {
        Group {
            switch message.speaker {
            case .system:
                systemBubble
            case .computer:
                HStack(alignment: .top) {
                    bubble(alignment: .leading)
                    Spacer(minLength: 36)
                }
            case .user:
                HStack(alignment: .top) {
                    Spacer(minLength: 36)
                    bubble(alignment: .trailing)
                }
            }
        }
    }

    private var systemBubble: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles.rectangle.stack")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.72))

                Text(message.speaker.title)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.56))

                Spacer()

                stateBadge
            }

            Text(message.text)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            if let detail = message.detail, !detail.isEmpty {
                Text(detail)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.62))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        }
    }

    private func bubble(alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 8) {
            HStack(spacing: 8) {
                if message.speaker == .computer {
                    Text(displayName)
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.58))

                    stateBadge
                } else {
                    stateBadge

                    Text(displayName)
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.58))
                }
            }

            Text(message.text)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(message.speaker == .user ? .trailing : .leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: message.speaker == .user ? .trailing : .leading)

            if let detail = message.detail, !detail.isEmpty {
                Text(detail)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.66))
                    .multilineTextAlignment(message.speaker == .user ? .trailing : .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: message.speaker == .user ? .trailing : .leading)
            }
        }
        .padding(14)
        .frame(maxWidth: 280, alignment: message.speaker == .user ? .trailing : .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(bubbleAccent.opacity(0.18))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(bubbleAccent.opacity(0.36), lineWidth: 1)
        }
    }

    private var displayName: String {
        switch message.speaker {
        case .user:
            return profileName.isEmpty ? "You" : profileName
        case .computer:
            return "xmaxx"
        case .system:
            return "Session"
        }
    }

    private var bubbleAccent: Color {
        switch message.speaker {
        case .user:
            switch message.state {
            case .live:
                return Color(red: 0.35, green: 0.73, blue: 0.96)
            case .captured:
                return Color(red: 0.98, green: 0.74, blue: 0.28)
            case .processing:
                return Color(red: 0.57, green: 0.89, blue: 0.74)
            case .delivered, .noted:
                return Color(red: 0.35, green: 0.73, blue: 0.96)
            }
        case .computer:
            return Color(red: 0.99, green: 0.48, blue: 0.36)
        case .system:
            return Color.white.opacity(0.28)
        }
    }

    private var stateBadge: some View {
        Text(message.state.title)
            .font(.system(size: 10, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                Capsule(style: .continuous)
                    .fill(bubbleAccent.opacity(0.24))
            )
    }
}

private struct MetricStrip: View {
    @ObservedObject var store: AppStore

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                metricCards
            }

            VStack(spacing: 10) {
                metricCards
            }
        }
    }

    private var metricCards: some View {
        Group {
            metricCard(title: "Cycles", value: "\(store.cycles.count)")
            metricCard(title: "Progress", value: "\(Int(store.objectiveProgress * 100))%")
            metricCard(title: "Model", value: store.activeDecisionProfile.title)
            metricCard(title: "Profile", value: store.profileName.isEmpty ? "Guest" : store.profileName)
        }
    }

    private func metricCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.46))

            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        }
    }
}

private struct DecisionModelSelector: View {
    @ObservedObject var store: AppStore

    private let columns = [
        GridItem(.flexible(), spacing: 10, alignment: .top),
        GridItem(.flexible(), spacing: 10, alignment: .top)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(DecisionModel.allCases) { model in
                    Button {
                        store.toggleDecisionModel(model)
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top) {
                                Text(model.capsuleTitle)
                                    .font(.system(size: 11, weight: .black, design: .rounded))
                                    .foregroundStyle(isSelected(model) ? Color.black.opacity(0.82) : accent(for: model))

                                Spacer(minLength: 6)

                                Image(systemName: isSelected(model) ? "checkmark.circle.fill" : "plus.circle")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(isSelected(model) ? Color.black.opacity(0.82) : Color.white.opacity(0.44))
                            }

                            Text(model.title)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .fixedSize(horizontal: false, vertical: true)

                            Text(model.summary)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.white.opacity(0.62))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, minHeight: 116, alignment: .topLeading)
                        .background(background(for: model))
                        .overlay {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(borderColor(for: model), lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 8) {
                Text(store.activeDecisionProfile.title)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text(store.activeDecisionProfile.subtitle)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.54))
                    .lineLimit(2)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.04))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            }
        }
    }

    private func isSelected(_ model: DecisionModel) -> Bool {
        store.selectedDecisionModels.contains(model)
    }

    private func accent(for model: DecisionModel) -> Color {
        switch model {
        case .ooda:
            return Color(red: 0.35, green: 0.73, blue: 0.96)
        case .recognitionPrimed:
            return Color(red: 0.99, green: 0.48, blue: 0.36)
        case .system1System2:
            return Color(red: 0.98, green: 0.74, blue: 0.28)
        case .bayesian:
            return Color(red: 0.80, green: 0.88, blue: 0.43)
        case .reinforcementLearning:
            return Color(red: 0.53, green: 0.92, blue: 0.82)
        case .predictiveProcessing:
            return Color(red: 0.58, green: 0.70, blue: 0.98)
        case .cynefin:
            return Color(red: 0.92, green: 0.60, blue: 0.26)
        }
    }

    private func background(for model: DecisionModel) -> some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(
                LinearGradient(
                    colors: isSelected(model)
                        ? [
                            Color.white.opacity(0.88),
                            accent(for: model).opacity(0.78)
                        ]
                        : [
                            Color.white.opacity(0.05),
                            accent(for: model).opacity(0.14)
                        ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    private func borderColor(for model: DecisionModel) -> Color {
        isSelected(model) ? accent(for: model).opacity(0.82) : Color.white.opacity(0.10)
    }
}

private struct VoiceLoopControl: View {
    @ObservedObject var store: AppStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                store.toggleGuidedVoiceLoop()
            } label: {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(iconGradient)
                            .frame(width: 62, height: 62)

                        Image(systemName: buttonIcon)
                            .font(.system(size: 22, weight: .black))
                            .foregroundStyle(buttonIconForeground)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(buttonTitle)
                            .font(.system(size: 17, weight: .black, design: .rounded))
                            .foregroundStyle(.white)

                        Text(buttonSubtitle)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.64))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: isActive ? "stop.circle.fill" : "arrow.right.circle.fill")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.92))
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(controlBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(buttonAccent.opacity(0.42), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)

            HStack(spacing: 8) {
                controlBadge(
                    title: "Mic",
                    value: micStatusLabel,
                    accent: isActive ? buttonAccent : Color.white.opacity(0.32)
                )

                controlBadge(
                    title: "Loop",
                    value: loopStatusLabel,
                    accent: loopAccent
                )
            }

            Text(store.recordingStatusMessage)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.52))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            if shouldShowLiveTranscript {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(transcriptAccent)
                            .frame(width: 8, height: 8)

                        Text(transcriptTitle)
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundStyle(transcriptAccent)
                    }

                    Text(liveTranscriptBody)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(transcriptAccent.opacity(0.12))
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(transcriptAccent.opacity(0.24), lineWidth: 1)
                }
            }
        }
    }

    private var hasMission: Bool {
        !store.missionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var isRunning: Bool {
        store.isGuidedLoopRunning
    }

    private var isActive: Bool {
        store.isVoiceLoopActive
    }

    private var buttonTitle: String {
        if isActive {
            return "Stop Voice Loop"
        }

        return hasMission ? "Start Guided Voice Loop" : "Start Voice Loop"
    }

    private var buttonSubtitle: String {
        if isRunning {
            return "The loop is live and the mic stays available for steering."
        }

        if isActive {
            return "The mic is armed and waiting for your next spoken pause."
        }

        if hasMission {
            return "Run the current mission now and keep listening for voice steering."
        }

        return "Start listening first, speak the mission, then pause to kick off the loop."
    }

    private var buttonIcon: String {
        if isActive {
            return "stop.fill"
        }

        return hasMission ? "waveform.and.mic" : "mic.fill"
    }

    private var buttonAccent: Color {
        if isActive {
            return Color(red: 0.99, green: 0.48, blue: 0.36)
        }

        return hasMission
            ? Color(red: 0.53, green: 0.92, blue: 0.82)
            : Color(red: 0.35, green: 0.73, blue: 0.96)
    }

    private var buttonIconForeground: Color {
        isActive ? .white : Color.black.opacity(0.82)
    }

    private var iconGradient: LinearGradient {
        LinearGradient(
            colors: isActive
                ? [
                    buttonAccent.opacity(0.95),
                    Color(red: 0.80, green: 0.24, blue: 0.20)
                ]
                : [
                    Color.white.opacity(0.92),
                    buttonAccent.opacity(0.95)
                ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var controlBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.08),
                        buttonAccent.opacity(0.18)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    private var micStatusLabel: String {
        if store.isRecordingMission {
            return "Live"
        }

        if isActive {
            return "Arming"
        }

        return "Off"
    }

    private var loopStatusLabel: String {
        if store.awaitingActionConfirmation {
            return "Approval"
        }

        if isRunning {
            return "Running"
        }

        return hasMission ? "Ready" : "Waiting"
    }

    private var loopAccent: Color {
        if store.awaitingActionConfirmation {
            return Color(red: 0.98, green: 0.74, blue: 0.28)
        }

        if isRunning {
            return Color(red: 0.53, green: 0.92, blue: 0.82)
        }

        return hasMission
            ? Color(red: 0.35, green: 0.73, blue: 0.96)
            : Color.white.opacity(0.28)
    }

    private var shouldShowLiveTranscript: Bool {
        isActive || !store.voiceFlowTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var transcriptTitle: String {
        let transcript = store.voiceFlowTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        return transcript.isEmpty ? "Listening Now" : "Live Transcript"
    }

    private var liveTranscriptBody: String {
        let transcript = store.voiceFlowTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        if !transcript.isEmpty {
            return transcript
        }

        if store.isRecordingMission {
            return "Mic is live. Start speaking and your words should appear here before the pause commits them."
        }

        if isActive {
            return "Voice loop is arming. If nothing appears here after a few seconds, check microphone and speech-recognition permissions."
        }

        return "Start the voice loop to see live transcription here."
    }

    private var transcriptAccent: Color {
        switch store.voiceFlowState {
        case .idle:
            return Color.white.opacity(0.34)
        case .listening:
            return Color(red: 0.35, green: 0.73, blue: 0.96)
        case .captured:
            return Color(red: 0.98, green: 0.74, blue: 0.28)
        case .processing:
            return Color(red: 0.57, green: 0.89, blue: 0.74)
        case .speaking:
            return Color(red: 0.92, green: 0.60, blue: 0.26)
        case .error:
            return Color(red: 0.99, green: 0.54, blue: 0.44)
        }
    }

    private func controlBadge(title: String, value: String, accent: Color) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.48))

            Text(value)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(accent.opacity(0.16))
        )
        .overlay {
            Capsule(style: .continuous)
                .stroke(accent.opacity(0.34), lineWidth: 1)
        }
    }
}

private struct StatusPill: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.52))

            Text(subtitle)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: 360, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.07))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        }
    }
}

private struct PermissionCapsule: View {
    let title: String
    let isGranted: Bool

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isGranted ? Color.green : Color.orange)
                .frame(width: 8, height: 8)

            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.86))

            Text(isGranted ? "Granted" : "Missing")
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(isGranted ? Color.green.opacity(0.95) : Color.orange.opacity(0.95))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.07))
        )
        .overlay {
            Capsule(style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        }
    }
}

private struct VoiceChannelCard: View {
    let title: String
    let systemImage: String
    let bodyText: String
    let accent: Color
    var accessory: AnyView?

    init(
        title: String,
        systemImage: String,
        bodyText: String,
        accent: Color,
        @ViewBuilder accessory: () -> some View = { EmptyView() }
    ) {
        self.title = title
        self.systemImage = systemImage
        self.bodyText = bodyText
        self.accent = accent
        self.accessory = AnyView(accessory())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(accent)

                Text(title)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }

            Text(bodyText)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.80))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            accessory
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(accent.opacity(0.12))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(accent.opacity(0.20), lineWidth: 1)
        }
    }
}

private struct SettingsSheet: View {
    @ObservedObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var profileName: String
    @State private var chatGPTAPIKey: String
    @State private var elevenLabsAPIKey: String
    @State private var pyannoteAPIKey: String
    @State private var audioResponsesEnabled: Bool
    @State private var audioDialogueMode: AudioDialogueMode

    init(store: AppStore) {
        self.store = store
        _profileName = State(initialValue: store.profileName)
        _chatGPTAPIKey = State(initialValue: store.chatGPTAPIKey)
        _elevenLabsAPIKey = State(initialValue: store.elevenLabsAPIKey)
        _pyannoteAPIKey = State(initialValue: store.pyannoteAPIKey)
        _audioResponsesEnabled = State(initialValue: store.audioResponsesEnabled)
        _audioDialogueMode = State(initialValue: store.audioDialogueMode)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Profile")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.58))

                        TextField("Enter your name", text: $profileName)
                            .textFieldStyle(.plain)
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(sheetFieldBackground)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("ChatGPT API Key")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.58))

                        SecureField("sk-...", text: $chatGPTAPIKey)
                            .textFieldStyle(.plain)
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(sheetFieldBackground)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("ElevenLabs API Key")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.58))

                        SecureField("Enter ElevenLabs key", text: $elevenLabsAPIKey)
                            .textFieldStyle(.plain)
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(sheetFieldBackground)

                        Text("If ElevenLabs is unavailable, the app falls back to the macOS system voice.")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.45))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("pyannoteAI API Key")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.58))

                        SecureField("Enter pyannoteAI key", text: $pyannoteAPIKey)
                            .textFieldStyle(.plain)
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(sheetFieldBackground)

                        Text("Adds speaker diarization after each pause so the mission can include who spoke when. pyannote's public streaming page still says real-time diarization is coming soon, so this app uses the documented file-based API per utterance.")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.45))
                    }

                    Toggle(isOn: $audioResponsesEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Enable Audio Responses")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)

                            Text("Speak guided-loop results out loud after each iteration.")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.white.opacity(0.45))
                        }
                    }
                    .toggleStyle(.switch)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Hear")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.58))

                        Picker("Hear", selection: $audioDialogueMode) {
                            ForEach(AudioDialogueMode.allCases) { mode in
                                Text(mode.title).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)

                        Text("Choose whether spoken audio uses the user-facing reply, the agent's internal narration, or both.")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.45))
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Permissions")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.58))

                        permissionRow(
                            title: "Accessibility",
                            detail: "Required for HID mouse automation. If this is missing, mouse_move and mouse_click will not fire at all.",
                            isGranted: store.isAccessibilityGranted
                        )

                        permissionRow(
                            title: "Screen Recording",
                            detail: "Required for screenshot-based coordinate finding. The guided loop uses this to resolve visible text into screen coordinates.",
                            isGranted: store.isScreenRecordingGranted
                        )

                        HStack(spacing: 10) {
                            Button("Request Accessibility") {
                                store.requestAccessibilityPermission()
                            }
                            .buttonStyle(.borderedProminent)

                            Button("Open Accessibility Settings") {
                                store.openAccessibilitySettings()
                            }
                            .buttonStyle(.bordered)
                        }

                        HStack(spacing: 10) {
                            Button("Request Screen Recording") {
                                store.requestScreenRecordingPermission()
                            }
                            .buttonStyle(.borderedProminent)

                            Button("Open Screen Recording Settings") {
                                store.openScreenRecordingSettings()
                            }
                            .buttonStyle(.bordered)

                            Button("Refresh") {
                                store.refreshPermissionStatuses()
                            }
                            .buttonStyle(.bordered)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Automation Status")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)

                            Text(store.automationStatusMessage)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.white.opacity(0.60))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(14)
                        .background(sheetFieldBackground)

                        Text("If macOS already cached a denial, the system may not show the prompt again. In that case enable xmaxx manually in System Settings > Privacy & Security > Accessibility and Screen Recording.")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.45))
                    }

                    Text("API keys are stored securely in the macOS Keychain for this app.")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.45))
                }
                .padding(24)
            }
            .frame(width: 560, height: 720)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.10, blue: 0.15),
                        Color(red: 0.05, green: 0.07, blue: 0.11)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.updateSettings(
                            profileName: profileName,
                            chatGPTAPIKey: chatGPTAPIKey,
                            elevenLabsAPIKey: elevenLabsAPIKey,
                            pyannoteAPIKey: pyannoteAPIKey,
                            audioResponsesEnabled: audioResponsesEnabled,
                            audioDialogueMode: audioDialogueMode
                        )
                        dismiss()
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                store.refreshPermissionStatuses()
            }
        }
        .preferredColorScheme(.dark)
    }

    private var sheetFieldBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.white.opacity(0.06))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            }
    }

    private func permissionRow(title: String, detail: String, isGranted: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Circle()
                    .fill(isGranted ? Color.green : Color.orange)
                    .frame(width: 10, height: 10)

                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(isGranted ? "Granted" : "Missing")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(isGranted ? Color.green.opacity(0.95) : Color.orange.opacity(0.95))
            }

            Text(detail)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.60))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(sheetFieldBackground)
    }
}

private struct PanelSurface<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(22)
            .background(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(Color.white.opacity(0.055))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            }
    }
}

@ViewBuilder
private func sectionLabel(_ title: String) -> some View {
    Text(title)
        .font(.system(size: 12, weight: .black, design: .rounded))
        .foregroundStyle(Color.white.opacity(0.45))
}

@ViewBuilder
private func fieldBlock<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
    VStack(alignment: .leading, spacing: 8) {
        Text(title)
            .font(.system(size: 13, weight: .black, design: .rounded))
            .foregroundStyle(Color.white.opacity(0.56))

        content()
    }
}

#Preview {
    ContentView()
}
