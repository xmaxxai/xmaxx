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

                ScrollView([.horizontal, .vertical]) {
                    VStack(spacing: 18) {
                        HeaderBar(store: store, isCompact: layout.isHeaderCompact) {
                            isSettingsPresented = true
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
                    .frame(
                        minWidth: layout.minimumCanvasWidth,
                        minHeight: max(proxy.size.height - 1, 720),
                        alignment: .topLeading
                    )
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
            store.persistWorkspaceDraft()
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

    var body: some View {
        Group {
            if isCompact {
                VStack(alignment: .leading, spacing: 16) {
                    titleBlock

                    HStack(spacing: 12) {
                        StatusPill(title: store.status.title, subtitle: store.statusMessage)
                        settingsButton
                    }
                }
            } else {
                HStack(spacing: 18) {
                    titleBlock

                    Spacer()

                    HStack(spacing: 12) {
                        StatusPill(title: store.status.title, subtitle: store.statusMessage)
                        settingsButton
                    }
                }
            }
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("xmaxx Computer")
                .font(.system(size: 38, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text("Observe. Orient. Decide. Act. Then loop again.")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.62))
        }
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

                Text("Shape the loop")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Feed the model the real mission and current machine state. The tighter the inputs, the better the next move.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.62))
                    .fixedSize(horizontal: false, vertical: true)

                MetricStrip(store: store)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Iteration Budget")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.56))

                        Spacer()

                        Text("\(store.maxIterations)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }

                    Stepper(value: $store.maxIterations, in: 1...12) {
                        EmptyView()
                    }
                    .labelsHidden()
                }

                fieldBlock(title: "Mission") {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 10) {
                            Button {
                                store.toggleMissionRecording()
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: "mic.fill")
                                        .font(.system(size: 28, weight: .bold))
                                    Text(store.voiceLoopEnabled ? "Stop" : "Start")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                }
                                .foregroundStyle(store.isRecordingMission ? Color(red: 0.99, green: 0.48, blue: 0.36) : Color.white)
                                .frame(width: 94, height: 94)
                                .background(
                                    Circle()
                                        .fill(Color.white.opacity(0.07))
                                )
                                .overlay {
                                    Circle()
                                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                                }
                            }
                            .buttonStyle(.plain)

                            Text(store.recordingStatusMessage)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.white.opacity(0.52))
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Text("Turn on the microphone and keep talking naturally. The mic stays live, a short pause commits the mission, and the app ignores its own voice while it speaks.")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.42))
                            .fixedSize(horizontal: false, vertical: true)

                        TextEditor(text: $store.missionText)
                            .scrollContentBackground(.hidden)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(12)
                            .frame(minHeight: 150)
                            .background(panelInputBackground)
                    }
                }

                fieldBlock(title: "Environment") {
                    TextEditor(text: $store.environmentText)
                        .scrollContentBackground(.hidden)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.88))
                        .padding(12)
                        .frame(minHeight: 220)
                        .background(panelInputBackground)
                }

                fieldBlock(title: "Operator Feedback") {
                    TextEditor(text: $store.operatorFeedback)
                        .scrollContentBackground(.hidden)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.88))
                        .padding(12)
                        .frame(minHeight: 110)
                        .background(panelInputBackground)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Button {
                        store.runOODALoop()
                    } label: {
                        HStack {
                            Image(systemName: store.status == .running ? "bolt.horizontal.circle.fill" : "play.circle.fill")
                            Text(store.status == .running ? "Running OODA Loop" : "Run OODA Loop")
                        }
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.black.opacity(0.86))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.88, green: 0.94, blue: 0.96),
                                            Color(red: 0.53, green: 0.92, blue: 0.82)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!store.canRunLoop)
                    .opacity(store.canRunLoop ? 1 : 0.55)

                    if store.status == .running {
                        Button("Stop Loop") {
                            store.stopLoop()
                        }
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.84))
                        .buttonStyle(.plain)
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
                            sectionLabel("OODA Board")
                            Text("Computer-use loop")
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 8) {
                            Text("Live planning via ChatGPT")
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
                            OODACard(section: section)
                        }
                    }
                }
            }

            PanelSurface {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            sectionLabel("Act Queue")
                            Text("Operator-facing action plan")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }

                        Spacer()
                    }

                    if store.actionQueue.isEmpty {
                        Text("No actions yet. Run the loop to generate the next plan.")
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
                            sectionLabel("3D Action Graph")
                            Text("Live action topology")
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

                    Text("The graph updates as the loop changes, linking OODA phases to the actions that are queued, running, blocked, or done.")
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
                    return SCNVector3(-5.2, 1.8, 0)
                case .orient:
                    return SCNVector3(-1.7, 1.2, 1.6)
                case .decide:
                    return SCNVector3(1.7, 1.2, -1.6)
                case .act:
                    return SCNVector3(5.2, 1.8, 0)
                }
            case .action:
                let actionIndex = max(index - 5, 0)
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
                            sectionLabel("Voice Channels")
                            Text("Internal vs external")
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

                    VoiceChannelCard(
                        title: "Out Loud",
                        systemImage: "speaker.wave.2.fill",
                        bodyText: store.externalDialogText,
                        accent: Color(red: 0.55, green: 0.84, blue: 0.65)
                    )

                    VoiceChannelCard(
                        title: "Internal",
                        systemImage: "brain.head.profile",
                        bodyText: store.internalDialogText,
                        accent: Color(red: 0.98, green: 0.74, blue: 0.28)
                    )
                }
            }

            PanelSurface {
                VStack(alignment: .leading, spacing: 16) {
                    sectionLabel("Recent Loops")
                    Text("History")
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
                    Text("Selected loop")
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
}

private struct OODACard: View {
    let section: OODASection

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 7) {
                    Text(section.phase.rawValue.uppercased())
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(accent.opacity(0.9))

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

                    Spacer()

                    Text(action.status.rawValue.capitalized)
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(statusColor)
                }

                Text("\(action.tool) -> \(action.target)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.50))

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
    let cycle: OODACycle
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
                    Text("Loop \(cycle.iteration)")
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
            metricCard(title: "Loops", value: "\(store.cycles.count)")
            metricCard(title: "Progress", value: "\(Int(store.objectiveProgress * 100))%")
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

private struct VoiceChannelCard: View {
    let title: String
    let systemImage: String
    let bodyText: String
    let accent: Color

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
    @State private var audioResponsesEnabled: Bool
    @State private var audioDialogueMode: AudioDialogueMode

    init(store: AppStore) {
        self.store = store
        _profileName = State(initialValue: store.profileName)
        _chatGPTAPIKey = State(initialValue: store.chatGPTAPIKey)
        _elevenLabsAPIKey = State(initialValue: store.elevenLabsAPIKey)
        _audioResponsesEnabled = State(initialValue: store.audioResponsesEnabled)
        _audioDialogueMode = State(initialValue: store.audioDialogueMode)
    }

    var body: some View {
        NavigationStack {
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

                Toggle(isOn: $audioResponsesEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Enable Audio Responses")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Speak loop results out loud after each iteration.")
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

                Text("API keys are stored securely in the macOS Keychain for this app.")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.45))

                Spacer()
            }
            .padding(24)
            .frame(width: 480, height: 420)
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
                            audioResponsesEnabled: audioResponsesEnabled,
                            audioDialogueMode: audioDialogueMode
                        )
                        dismiss()
                    }
                }
            }
            .navigationTitle("Settings")
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
}

private struct PanelSurface<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
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
