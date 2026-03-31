//
//  AppStore.swift
//  xmaxx
//
//  Created by Codex on 3/30/26.
//

import Combine
import Foundation
import Security
import AppKit
import ApplicationServices
import CoreServices
import AVFoundation
import Speech

enum OODAPhase: String, CaseIterable, Hashable, Codable, Identifiable {
    case observe
    case orient
    case decide
    case act

    var id: String { rawValue }
}

enum ActionStatus: String, Codable, Hashable {
    case queued
    case ready
    case blocked
    case done
}

enum LoopStatus: Hashable {
    case idle
    case awaitingAPIKey
    case running
    case ready
    case completed
    case blocked
    case stopped
    case failed

    var title: String {
        switch self {
        case .idle:
            return "Standby"
        case .awaitingAPIKey:
            return "API Key Needed"
        case .running:
            return "Running Loop"
        case .ready:
            return "Plan Ready"
        case .completed:
            return "Objective Met"
        case .blocked:
            return "Loop Blocked"
        case .stopped:
            return "Loop Stopped"
        case .failed:
            return "Run Failed"
        }
    }
}

enum AudioDialogueMode: String, CaseIterable, Hashable, Identifiable {
    case external
    case internalOnly = "internal"
    case both

    var id: String { rawValue }

    var title: String {
        switch self {
        case .external:
            return "External"
        case .internalOnly:
            return "Internal"
        case .both:
            return "Both"
        }
    }
}

struct OODASection: Identifiable, Hashable {
    let phase: OODAPhase
    var headline: String
    var narrative: String
    var bullets: [String]
    var confidence: Double

    var id: OODAPhase { phase }
}

struct ActionItem: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var tool: String
    var target: String
    var rationale: String
    var status: ActionStatus
    var x: Double?
    var y: Double?
    var output: String?
}

struct OODACycle: Identifiable, Hashable {
    let id = UUID()
    let iteration: Int
    let createdAt: Date
    let mission: String
    let environment: String
    let summary: String
    let model: String
    let progress: Double
    let objectiveMet: Bool
    let isBlocked: Bool
    let blocker: String?
    let sections: [OODASection]
    let actions: [ActionItem]
}

struct ActionGraphNode: Identifiable, Hashable {
    enum Kind: Hashable {
        case loop
        case phase(OODAPhase)
        case action
    }

    let id: String
    let title: String
    let subtitle: String
    let kind: Kind
    let emphasis: Double
}

struct ActionGraphEdge: Identifiable, Hashable {
    let id: String
    let fromID: String
    let toID: String
    let weight: Double
}

struct ActionGraphSnapshot: Hashable {
    let nodes: [ActionGraphNode]
    let edges: [ActionGraphEdge]
}

@MainActor
final class AppStore: ObservableObject {
    @Published var profileName: String
    @Published var chatGPTAPIKey: String
    @Published var elevenLabsAPIKey: String
    @Published var pyannoteAPIKey: String
    @Published var audioResponsesEnabled: Bool
    @Published var audioDialogueMode: AudioDialogueMode
    @Published var missionText: String
    @Published var environmentText: String
    @Published var isRecordingMission: Bool
    @Published var voiceLoopEnabled: Bool
    @Published var isAgentSpeaking: Bool
    @Published var recordingStatusMessage: String
    @Published var voiceAnalysisSummary: String
    @Published var externalDialogText: String
    @Published var internalDialogText: String
    @Published private(set) var isAccessibilityGranted: Bool
    @Published private(set) var isScreenRecordingGranted: Bool
    @Published var status: LoopStatus = .idle
    @Published var statusMessage: String
    @Published var currentIteration: Int
    @Published var maxIterations: Int
    @Published var objectiveProgress: Double
    @Published var operatorFeedback: String
    @Published var sections: [OODASection]
    @Published var actionQueue: [ActionItem]
    @Published private(set) var cycles: [OODACycle]
    @Published var selectedCycleID: OODACycle.ID?

    private let userDefaults: UserDefaults
    private let keychain = KeychainStore()
    private let client = OpenAIClient()
    private let mouseExecutor = PythonMouseExecutor()
    private let pyannoteClient = PyannoteClient()

    private let profileNameKey = "profileName"
    private let chatGPTAPIKeyKey = "chatGPTAPIKey"
    private let elevenLabsAPIKeyKey = "elevenLabsAPIKey"
    private let pyannoteAPIKeyKey = "pyannoteAPIKey"
    private let audioResponsesEnabledKey = "audioResponsesEnabled"
    private let audioDialogueModeKey = "audioDialogueMode"
    private let missionTextKey = "missionText"
    private let environmentTextKey = "environmentText"
    private let operatorFeedbackKey = "operatorFeedback"
    private let maxIterationsKey = "maxIterations"
    private let voiceLoopEnabledKey = "voiceLoopEnabled"
    private var loopTask: Task<Void, Never>?
    private var listeningRestartTask: Task<Void, Never>?
    private var speakingTask: Task<Void, Never>?
    private var didTriggerPermissionProbes = false
    private var didAutoStart = false
    private var liveVoiceLoopContext = ""
    private var missionDraftBaseText: String?
    private var operatorFeedbackDraftBaseText: String?
    private let speechCoordinator = SpeechCoordinator()
    private let missionTranscriber = MissionTranscriber()

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        let legacyDefaultEnvironmentText = """
        Current app shell is a macOS dashboard. We have profile and API key settings, but no live screen capture, automation executor, or tool bridge yet.
        """
        let currentDefaultEnvironmentText = """
        Current app shell is a macOS dashboard. ChatGPT planning is active, and a limited automation executor is available for coordinate-based mouse_move, mouse_click, and mouse_right_click when Accessibility permission is granted. Live screen capture is still unavailable, so actions need grounded coordinates from the environment.
        """
        let storedProfileName = userDefaults.string(forKey: profileNameKey) ?? ""
        let storedMissionText = userDefaults.string(forKey: missionTextKey) ?? "Build a desktop computer-use copilot around the OODA loop."
        let persistedEnvironmentText = userDefaults.string(forKey: environmentTextKey)
        let storedEnvironmentText: String
        if let persistedEnvironmentText {
            storedEnvironmentText = persistedEnvironmentText.trimmingCharacters(in: .whitespacesAndNewlines) == legacyDefaultEnvironmentText
                ? currentDefaultEnvironmentText
                : persistedEnvironmentText
        } else {
            storedEnvironmentText = currentDefaultEnvironmentText
        }
        let storedOperatorFeedback = userDefaults.string(forKey: operatorFeedbackKey) ?? ""
        let storedMaxIterations = max(1, userDefaults.integer(forKey: maxIterationsKey))
        let storedVoiceLoopEnabled = userDefaults.object(forKey: voiceLoopEnabledKey) as? Bool ?? false
        var storedAPIKey = keychain.read(account: chatGPTAPIKeyKey) ?? ""
        var storedElevenLabsAPIKey = keychain.read(account: elevenLabsAPIKeyKey) ?? ""
        var storedPyannoteAPIKey = keychain.read(account: pyannoteAPIKeyKey) ?? ""
        let storedAudioResponsesEnabled = userDefaults.object(forKey: audioResponsesEnabledKey) as? Bool ?? false
        let storedAudioDialogueMode = AudioDialogueMode(rawValue: userDefaults.string(forKey: audioDialogueModeKey) ?? "") ?? .external

        if storedAPIKey.isEmpty, let legacyAPIKey = userDefaults.string(forKey: chatGPTAPIKeyKey) {
            storedAPIKey = legacyAPIKey
            keychain.save(legacyAPIKey, account: chatGPTAPIKeyKey)
            userDefaults.removeObject(forKey: chatGPTAPIKeyKey)
        }

        if storedElevenLabsAPIKey.isEmpty, let legacyElevenLabsKey = userDefaults.string(forKey: elevenLabsAPIKeyKey) {
            storedElevenLabsAPIKey = legacyElevenLabsKey
            keychain.save(legacyElevenLabsKey, account: elevenLabsAPIKeyKey)
            userDefaults.removeObject(forKey: elevenLabsAPIKeyKey)
        }

        if storedPyannoteAPIKey.isEmpty, let legacyPyannoteKey = userDefaults.string(forKey: pyannoteAPIKeyKey) {
            storedPyannoteAPIKey = legacyPyannoteKey
            keychain.save(legacyPyannoteKey, account: pyannoteAPIKeyKey)
            userDefaults.removeObject(forKey: pyannoteAPIKeyKey)
        }

        profileName = storedProfileName
        missionText = storedMissionText
        environmentText = storedEnvironmentText
        chatGPTAPIKey = storedAPIKey
        elevenLabsAPIKey = storedElevenLabsAPIKey
        pyannoteAPIKey = storedPyannoteAPIKey
        audioResponsesEnabled = storedAudioResponsesEnabled
        audioDialogueMode = storedAudioDialogueMode
        operatorFeedback = storedOperatorFeedback
        isRecordingMission = false
        voiceLoopEnabled = storedVoiceLoopEnabled
        isAgentSpeaking = false
        recordingStatusMessage = "Ready to capture the mission from audio."
        voiceAnalysisSummary = ""
        externalDialogText = "Ready to speak to the operator."
        internalDialogText = "Internal loop narration will appear here."
        isAccessibilityGranted = SystemPermissionPrompter.isAccessibilityGranted()
        isScreenRecordingGranted = SystemPermissionPrompter.isScreenRecordingGranted()
        maxIterations = storedMaxIterations == 0 ? 5 : min(storedMaxIterations, 12)
        currentIteration = 0
        objectiveProgress = 0.18

        let starterSections = Self.placeholderSections
        let starterActions = Self.placeholderActions

        sections = starterSections
        actionQueue = starterActions
        cycles = [
            OODACycle(
                iteration: 0,
                createdAt: .now,
                mission: storedMissionText,
                environment: storedEnvironmentText,
                summary: "Initial shell configured. Ready to generate the first loop with ChatGPT.",
                model: "Planning Shell",
                progress: 0.18,
                objectiveMet: false,
                isBlocked: false,
                blocker: nil,
                sections: starterSections,
                actions: starterActions
            )
        ]
        statusMessage = "Wire observation inputs, generate plans, and keep the loop tight."
        selectedCycleID = cycles.first?.id
    }

    var selectedCycle: OODACycle? {
        cycles.first(where: { $0.id == selectedCycleID })
    }

    var canRunLoop: Bool {
        !missionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && status != .running
    }

    var actionGraphSnapshot: ActionGraphSnapshot {
        let loopNode = ActionGraphNode(
            id: "loop-\(currentIteration)",
            title: currentIteration == 0 ? "Loop Standby" : "Loop \(currentIteration)",
            subtitle: status.title,
            kind: .loop,
            emphasis: max(objectiveProgress, 0.25)
        )

        let phaseNodes = sections.map { section in
            ActionGraphNode(
                id: "phase-\(section.phase.rawValue)",
                title: section.phase.rawValue.capitalized,
                subtitle: section.headline,
                kind: .phase(section.phase),
                emphasis: max(section.confidence, 0.2)
            )
        }

        let actionNodes = actionQueue.enumerated().map { index, action in
            ActionGraphNode(
                id: "action-\(index)-\(action.id.uuidString)",
                title: action.title,
                subtitle: action.output ?? action.tool,
                kind: .action,
                emphasis: graphEmphasis(for: action.status)
            )
        }

        var edges = phaseNodes.map { node in
            ActionGraphEdge(
                id: "\(loopNode.id)-\(node.id)",
                fromID: loopNode.id,
                toID: node.id,
                weight: node.emphasis
            )
        }

        if let decideNode = phaseNodes.first(where: { $0.id == "phase-decide" }),
           let actNode = phaseNodes.first(where: { $0.id == "phase-act" }) {
            edges.append(
                ActionGraphEdge(
                    id: "\(decideNode.id)-\(actNode.id)",
                    fromID: decideNode.id,
                    toID: actNode.id,
                    weight: 0.9
                )
            )
        }

        if let actNode = phaseNodes.first(where: { $0.id == "phase-act" }) {
            edges.append(contentsOf: actionNodes.map { node in
                ActionGraphEdge(
                    id: "\(actNode.id)-\(node.id)",
                    fromID: actNode.id,
                    toID: node.id,
                    weight: node.emphasis
                )
            })
        }

        if let observeNode = phaseNodes.first(where: { $0.id == "phase-observe" }),
           let orientNode = phaseNodes.first(where: { $0.id == "phase-orient" }),
           let decideNode = phaseNodes.first(where: { $0.id == "phase-decide" }) {
            edges.append(
                ActionGraphEdge(
                    id: "\(observeNode.id)-\(orientNode.id)",
                    fromID: observeNode.id,
                    toID: orientNode.id,
                    weight: 0.8
                )
            )
            edges.append(
                ActionGraphEdge(
                    id: "\(orientNode.id)-\(decideNode.id)",
                    fromID: orientNode.id,
                    toID: decideNode.id,
                    weight: 0.8
                )
            )
        }

        return ActionGraphSnapshot(
            nodes: [loopNode] + phaseNodes + actionNodes,
            edges: edges
        )
    }

    func triggerPermissionProbesIfNeeded() {
        guard !didTriggerPermissionProbes else { return }
        didTriggerPermissionProbes = true
        refreshPermissionStatuses()

        Task { @MainActor in
            SystemPermissionPrompter.triggerAccessibilityPromptIfNeeded()
        }

        Task.detached(priority: .utility) {
            _ = SystemPermissionPrompter.requestScreenRecordingAccessIfNeeded()
            SystemPermissionPrompter.triggerAutomationPrompt(forBundleIdentifier: "com.apple.finder")
            SystemPermissionPrompter.triggerAutomationPrompt()

            await MainActor.run {
                self.refreshPermissionStatuses()
            }
        }
    }

    func refreshPermissionStatuses() {
        isAccessibilityGranted = SystemPermissionPrompter.isAccessibilityGranted()
        isScreenRecordingGranted = SystemPermissionPrompter.isScreenRecordingGranted()
    }

    func requestScreenRecordingPermission() {
        refreshPermissionStatuses()

        Task.detached(priority: .userInitiated) {
            let granted = SystemPermissionPrompter.requestScreenRecordingAccessIfNeeded()

            await MainActor.run {
                self.refreshPermissionStatuses()
                self.statusMessage = granted
                    ? "Screen Recording access is granted."
                    : "Screen Recording permission is still missing. Approve xmaxx in System Settings > Privacy & Security > Screen Recording."
            }
        }
    }

    func openScreenRecordingSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") else {
            return
        }

        NSWorkspace.shared.open(url)
    }

    func autoStartIfPossible() {
        guard !didAutoStart else { return }
        didAutoStart = true

        guard !chatGPTAPIKey.isEmpty else {
            status = .awaitingAPIKey
            statusMessage = "Add your ChatGPT API key in settings to start the voice loop."
            return
        }

        voiceLoopEnabled = true
        persistWorkspaceDraft()
        beginMissionListening()
    }

    func updateSettings(profileName: String, chatGPTAPIKey: String) {
        updateSettings(
            profileName: profileName,
            chatGPTAPIKey: chatGPTAPIKey,
            elevenLabsAPIKey: elevenLabsAPIKey,
            pyannoteAPIKey: pyannoteAPIKey,
            audioResponsesEnabled: audioResponsesEnabled,
            audioDialogueMode: audioDialogueMode
        )
    }

    func updateSettings(
        profileName: String,
        chatGPTAPIKey: String,
        elevenLabsAPIKey: String,
        pyannoteAPIKey: String,
        audioResponsesEnabled: Bool,
        audioDialogueMode: AudioDialogueMode
    ) {
        self.profileName = profileName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.chatGPTAPIKey = chatGPTAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        self.elevenLabsAPIKey = elevenLabsAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        self.pyannoteAPIKey = pyannoteAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        self.audioResponsesEnabled = audioResponsesEnabled
        self.audioDialogueMode = audioDialogueMode

        userDefaults.set(self.profileName, forKey: profileNameKey)
        userDefaults.set(self.audioResponsesEnabled, forKey: audioResponsesEnabledKey)
        userDefaults.set(self.audioDialogueMode.rawValue, forKey: audioDialogueModeKey)

        if self.chatGPTAPIKey.isEmpty {
            keychain.delete(account: chatGPTAPIKeyKey)
        } else {
            keychain.save(self.chatGPTAPIKey, account: chatGPTAPIKeyKey)
        }

        if self.elevenLabsAPIKey.isEmpty {
            keychain.delete(account: elevenLabsAPIKeyKey)
        } else {
            keychain.save(self.elevenLabsAPIKey, account: elevenLabsAPIKeyKey)
        }

        if self.pyannoteAPIKey.isEmpty {
            keychain.delete(account: pyannoteAPIKeyKey)
            voiceAnalysisSummary = ""
        } else {
            keychain.save(self.pyannoteAPIKey, account: pyannoteAPIKeyKey)
        }
    }

    func persistWorkspaceDraft() {
        userDefaults.set(missionText, forKey: missionTextKey)
        userDefaults.set(environmentText, forKey: environmentTextKey)
        userDefaults.set(operatorFeedback, forKey: operatorFeedbackKey)
        userDefaults.set(maxIterations, forKey: maxIterationsKey)
        userDefaults.set(voiceLoopEnabled, forKey: voiceLoopEnabledKey)
    }

    func selectCycle(_ cycle: OODACycle) {
        selectedCycleID = cycle.id
        sections = cycle.sections
        actionQueue = cycle.actions
        objectiveProgress = cycle.progress
        currentIteration = cycle.iteration
        status = cycle.objectiveMet ? .completed : (cycle.isBlocked ? .blocked : .ready)
        statusMessage = cycle.summary
    }

    func runOODALoop(
        preserveVoiceLoop: Bool = false,
        supplementalEnvironment: String = ""
    ) {
        pauseMissionRecordingForProcessing()
        loopTask?.cancel()
        persistWorkspaceDraft()

        let trimmedMission = missionText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEnvironment = environmentText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedOperatorFeedback = operatorFeedback.trimmingCharacters(in: .whitespacesAndNewlines)
        liveVoiceLoopContext = supplementalEnvironment.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedMission.isEmpty else {
            status = .failed
            statusMessage = "Add a mission before running the loop."
            scheduleMissionListeningRestartIfNeeded()
            return
        }

        guard !chatGPTAPIKey.isEmpty else {
            status = .awaitingAPIKey
            statusMessage = "Add your ChatGPT API key in settings to generate a loop."
            scheduleMissionListeningRestartIfNeeded()
            return
        }

        status = .running
        statusMessage = "Starting x-maxx loop."
        currentIteration = 0
        objectiveProgress = 0.18

        loopTask = Task {
            do {
                try await runLoopSession(
                    mission: trimmedMission,
                    environment: trimmedEnvironment,
                    operatorFeedback: trimmedOperatorFeedback
                )
            } catch {
                guard !Task.isCancelled else { return }
                status = .failed
                statusMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                scheduleMissionListeningRestartIfNeeded()
            }
        }
    }

    private func composeEnvironment(base: String, supplemental: String) -> String {
        let parts = [base, supplemental]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return parts.joined(separator: "\n\n")
    }

    private func runtimeCapabilitySummary() -> String {
        refreshPermissionStatuses()
        let accessibilityStatus = isAccessibilityGranted ? "granted" : "missing"
        let screenRecordingStatus = isScreenRecordingGranted ? "granted" : "missing"
        let pyannoteStatus = pyannoteAPIKey.isEmpty ? "disabled" : "enabled"

        return """
        Runtime capability status:
        - Real automation executor available for coordinate-based mouse_move, mouse_click, and mouse_right_click.
        - Mouse automation depends on Accessibility permission. Current Accessibility status: \(accessibilityStatus).
        - Apple Events Automation approval may exist for Finder/System Events prompts, but the current action executor uses HID mouse events rather than AppleScript.
        - Screen Recording permission status: \(screenRecordingStatus).
        - Live screen capture is still unavailable in the app, so Screen Recording approval alone does not provide screenshots yet. Action coordinates still need grounded context.
        - Live operator steering by voice is available while the loop is running.
        - pyannote speaker analysis is \(pyannoteStatus).
        """
    }

    func stopLoop() {
        loopTask?.cancel()
        loopTask = nil

        if status == .running {
            status = .stopped
            statusMessage = "Loop stopped by operator."
            deliverDialogue(
                external: "Stopping now.",
                internal: "Loop stopped by operator."
            )
            scheduleMissionListeningRestartIfNeeded()
        }
    }

    func toggleMissionRecording() {
        if voiceLoopEnabled {
            stopMissionRecording()
        } else {
            startMissionRecording()
        }
    }

    func startMissionRecording() {
        voiceLoopEnabled = true
        persistWorkspaceDraft()
        beginMissionListening()
    }

    private func beginMissionListening() {
        guard voiceLoopEnabled else { return }
        listeningRestartTask?.cancel()

        if isRecordingMission {
            guard !isAgentSpeaking else { return }
            missionTranscriber.resumeSegmentDelivery()
            recordingStatusMessage = status == .running
                ? "Loop running. Mic is active for steering. Pause to inject guidance."
                : "Listening continuously. Pause to start x-maxx."
            return
        }

        Task {
            do {
                let store = self
                let currentMission = missionText
                try await missionTranscriber.start(
                    captureAudioForAnalysis: !pyannoteAPIKey.isEmpty,
                    initialText: currentMission,
                    onUpdate: { transcript in
                        Task { @MainActor in
                            if store.status == .running || store.loopTask != nil {
                                store.updateOperatorFeedbackDraft(with: transcript)
                            } else {
                                store.updateMissionDraft(with: transcript)
                            }
                        }
                    },
                    onFinal: { capture in
                        Task { @MainActor in
                            await store.handleCapturedSpeech(capture)
                        }
                    }
                )

                isRecordingMission = true
                if status == .running {
                    missionTranscriber.resumeSegmentDelivery()
                    recordingStatusMessage = "Loop running. Mic is active for steering. Pause to inject guidance."
                } else if isAgentSpeaking {
                    missionTranscriber.suspendSegmentDelivery()
                    recordingStatusMessage = "Speaking response. Mic stays live while self-voice is ignored."
                } else {
                    missionTranscriber.resumeSegmentDelivery()
                    recordingStatusMessage = "Listening continuously. Pause to start x-maxx."
                }
            } catch {
                isRecordingMission = false
                recordingStatusMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
        }
    }

    func stopMissionRecording() {
        voiceLoopEnabled = false
        listeningRestartTask?.cancel()
        missionTranscriber.stop()
        isRecordingMission = false
        liveVoiceLoopContext = ""
        clearMissionDraftPreview()
        clearOperatorFeedbackDraftPreview()
        let trimmedMission = missionText.trimmingCharacters(in: .whitespacesAndNewlines)
        recordingStatusMessage = trimmedMission.isEmpty ? "Ready to capture the mission from audio." : "Mission captured from audio."
    }

    private func pauseMissionRecordingForProcessing() {
        if voiceLoopEnabled {
            recordingStatusMessage = status == .running
                ? "Loop running. Mic is active for steering. Pause to inject guidance."
                : "Processing mission. Mic is active."
        }
    }

    private func handleCapturedSpeech(_ capture: MissionCapture) async {
        if status == .running || loopTask != nil {
            await processOperatorSteering(capture)
        } else {
            await processCapturedMission(capture)
        }
    }

    private func processCapturedMission(_ capture: MissionCapture) async {
        let trimmedTranscript = capture.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTranscript.isEmpty else {
            clearMissionDraftPreview()
            capture.deleteTemporaryAudioFileIfNeeded()
            return
        }

        let baseMissionText = missionDraftBaseText ?? missionText
        clearMissionDraftPreview()
        pauseMissionRecordingForProcessing()
        missionText = appendMissionEntry(trimmedTranscript, to: baseMissionText)
        recordingStatusMessage = "Mission captured. Running x-maxx while voice analysis continues."
        runOODALoop(
            preserveVoiceLoop: true,
            supplementalEnvironment: ""
        )

        startBackgroundVoiceAnalysis(capture, analysisPurpose: "mission")
    }

    private func processOperatorSteering(_ capture: MissionCapture) async {
        let trimmedTranscript = capture.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTranscript.isEmpty else {
            clearOperatorFeedbackDraftPreview()
            capture.deleteTemporaryAudioFileIfNeeded()
            return
        }

        let baseOperatorFeedback = operatorFeedbackDraftBaseText ?? operatorFeedback
        clearOperatorFeedbackDraftPreview()
        let normalized = trimmedTranscript.lowercased()

        if normalized.contains("stop loop") || normalized.contains("cancel loop") || normalized.contains("halt loop") {
            recordingStatusMessage = "Voice command received. Stopping the loop."
            capture.deleteTemporaryAudioFileIfNeeded()
            stopLoop()
            return
        }

        operatorFeedback = appendOperatorFeedbackEntry(trimmedTranscript, to: baseOperatorFeedback)
        persistWorkspaceDraft()
        recordingStatusMessage = "Steering captured immediately. The loop will use it while voice analysis continues."
        startBackgroundVoiceAnalysis(capture, analysisPurpose: "steering")
    }

    private func startBackgroundVoiceAnalysis(
        _ capture: MissionCapture,
        analysisPurpose: String
    ) {
        guard !pyannoteAPIKey.isEmpty, let audioFileURL = capture.audioFileURL else {
            voiceAnalysisSummary = pyannoteAPIKey.isEmpty ? "" : "Local speech transcript captured."
            capture.deleteTemporaryAudioFileIfNeeded()
            return
        }

        let apiKey = pyannoteAPIKey
        let fallbackTranscript = capture.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        voiceAnalysisSummary = analysisPurpose == "mission"
            ? "Mission appended. Speaker analysis is running in the background."
            : "Steering appended. Speaker analysis is running in the background."

        Task { @MainActor [weak self] in
            guard let self else {
                capture.deleteTemporaryAudioFileIfNeeded()
                return
            }

            defer {
                capture.deleteTemporaryAudioFileIfNeeded()
            }

            do {
                let analysis = try await self.pyannoteClient.analyzeUtterance(
                    audioFileURL: audioFileURL,
                    apiKey: apiKey
                )

                self.voiceAnalysisSummary = analysis.summary
                if !analysis.loopContext.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    self.liveVoiceLoopContext = analysis.loopContext
                }
            } catch {
                self.voiceAnalysisSummary = fallbackTranscript.isEmpty
                    ? "pyannote analysis unavailable."
                    : "pyannote analysis unavailable. Using the appended local speech transcript."
            }
        }
    }

    private func updateMissionDraft(with transcript: String) {
        let trimmedTranscript = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTranscript.isEmpty else { return }

        if missionDraftBaseText == nil {
            missionDraftBaseText = missionText
        }

        missionText = appendMissionEntry(trimmedTranscript, to: missionDraftBaseText ?? "")
    }

    private func updateOperatorFeedbackDraft(with transcript: String) {
        let trimmedTranscript = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTranscript.isEmpty else { return }

        if operatorFeedbackDraftBaseText == nil {
            operatorFeedbackDraftBaseText = operatorFeedback
        }

        operatorFeedback = appendOperatorFeedbackEntry(trimmedTranscript, to: operatorFeedbackDraftBaseText ?? "")
    }

    private func clearMissionDraftPreview() {
        missionDraftBaseText = nil
    }

    private func clearOperatorFeedbackDraftPreview() {
        operatorFeedbackDraftBaseText = nil
    }

    private func appendMissionEntry(_ entry: String, to existingText: String) -> String {
        appendDistinctEntry(entry, prefix: nil, existingText: existingText, limit: nil)
    }

    private func appendOperatorFeedbackEntry(_ entry: String, to existingText: String) -> String {
        let trimmedEntry = entry.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEntry.isEmpty else { return existingText }

        return appendDistinctEntry(trimmedEntry, prefix: "Voice steer", existingText: existingText, limit: 12)
    }

    private func appendDistinctEntry(
        _ entry: String,
        prefix: String?,
        existingText: String,
        limit: Int?
    ) -> String {
        let trimmedEntry = entry.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEntry.isEmpty else { return existingText }

        let formattedEntry: String
        if let prefix {
            formattedEntry = "\(prefix): \(trimmedEntry)"
        } else {
            formattedEntry = trimmedEntry
        }

        let existingEntries = existingText
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if existingEntries.last == formattedEntry {
            return existingText
        }

        let updatedEntries = existingEntries + [formattedEntry]
        let cappedEntries = if let limit {
            Array(updatedEntries.suffix(limit))
        } else {
            updatedEntries
        }

        return cappedEntries.joined(separator: "\n\n")
    }

    private func runLoopSession(
        mission: String,
        environment: String,
        operatorFeedback: String
    ) async throws {
        var history: [OODACycle] = []
        let limit = min(max(maxIterations, 1), 12)

        for iteration in 1...limit {
            try Task.checkCancellation()

            currentIteration = iteration
            status = .running
            statusMessage = "Iteration \(iteration) of \(limit): observing and planning."
            let liveEnvironment = composeEnvironment(
                base: environment,
                supplemental: composeEnvironment(
                    base: liveVoiceLoopContext,
                    supplemental: runtimeCapabilitySummary()
                )
            )
            let liveOperatorFeedback = self.operatorFeedback
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let result = try await client.generateOODALoop(
                apiKey: chatGPTAPIKey,
                profileName: profileName,
                mission: mission,
                environment: liveEnvironment,
                operatorFeedback: liveOperatorFeedback.isEmpty ? operatorFeedback : liveOperatorFeedback,
                iteration: iteration,
                maxIterations: limit,
                priorCycles: history
            )

            let cycle = OODACycle(
                iteration: iteration,
                createdAt: .now,
                mission: mission,
                environment: liveEnvironment,
                summary: result.summary,
                model: result.model,
                progress: result.progress,
                objectiveMet: result.objectiveMet,
                isBlocked: result.isBlocked,
                blocker: result.blocker,
                sections: result.sections,
                actions: await executeActions(result.actions)
            )

            history.append(cycle)
            sections = cycle.sections
            actionQueue = cycle.actions
            cycles.insert(cycle, at: 0)
            selectedCycleID = cycle.id
            objectiveProgress = cycle.progress
            deliverDialogue(
                external: cycle.externalDialogue,
                internal: cycle.internalDialogue
            )

            if cycle.objectiveMet {
                status = .completed
                statusMessage = cycle.summary
                deliverDialogue(
                    external: "Objective met. \(cycle.summary)",
                    internal: "Iteration \(cycle.iteration) completed the mission with progress at \(Int(cycle.progress * 100)) percent."
                )
                loopTask = nil
                scheduleMissionListeningRestartIfNeeded()
                return
            }

            if cycle.isBlocked {
                status = .blocked
                statusMessage = cycle.blocker ?? cycle.summary
                deliverDialogue(
                    external: "I am blocked. \(cycle.blocker ?? cycle.summary)",
                    internal: "Loop blocked on iteration \(cycle.iteration). Reason: \(cycle.blocker ?? cycle.summary)"
                )
                loopTask = nil
                scheduleMissionListeningRestartIfNeeded()
                return
            }

            if iteration == limit {
                status = .stopped
                statusMessage = "Reached iteration limit without meeting the objective."
                deliverDialogue(
                    external: "I ran out of iterations before finishing the objective.",
                    internal: "Iteration budget exhausted at \(limit) cycles with progress at \(Int(cycle.progress * 100)) percent."
                )
                loopTask = nil
                scheduleMissionListeningRestartIfNeeded()
                return
            }
        }
    }

    private func scheduleMissionListeningRestartIfNeeded(delayNanoseconds: UInt64? = nil) {
        guard voiceLoopEnabled else { return }

        listeningRestartTask?.cancel()
        let delay = delayNanoseconds ?? 400_000_000

        listeningRestartTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: delay)
            guard !Task.isCancelled, self.voiceLoopEnabled, !self.isAgentSpeaking, self.status != .running else { return }

            if self.isRecordingMission {
                self.missionTranscriber.resumeSegmentDelivery()
                self.recordingStatusMessage = "Listening continuously. Pause to start x-maxx."
            } else {
                self.beginMissionListening()
            }
        }
    }

    private func deliverDialogue(external: String, internal internalText: String) {
        externalDialogText = external.trimmingCharacters(in: .whitespacesAndNewlines)
        internalDialogText = internalText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard audioResponsesEnabled else { return }

        let spokenText: String
        switch audioDialogueMode {
        case .external:
            spokenText = externalDialogText
        case .internalOnly:
            spokenText = internalDialogText
        case .both:
            spokenText = [externalDialogText, internalDialogText]
                .filter { !$0.isEmpty }
                .joined(separator: " Internal note. ")
        }

        let elevenLabsAPIKey = self.elevenLabsAPIKey

        guard !spokenText.isEmpty else { return }

        listeningRestartTask?.cancel()
        pauseMissionRecordingForProcessing()
        missionTranscriber.suspendSegmentDelivery()
        isAgentSpeaking = true

        speakingTask?.cancel()
        speakingTask = Task { @MainActor [weak self] in
            guard let self else { return }

            if self.voiceLoopEnabled {
                self.recordingStatusMessage = "Speaking response. Mic stays live while self-voice is ignored."
            }

            await speechCoordinator.speakAndWait(
                text: spokenText,
                elevenLabsAPIKey: elevenLabsAPIKey.isEmpty ? nil : elevenLabsAPIKey
            )

            guard !Task.isCancelled else { return }

            self.isAgentSpeaking = false

            guard self.voiceLoopEnabled else { return }

            self.missionTranscriber.resumeSegmentDelivery(
                afterNanoseconds: 250_000_000,
                suppressingPlaybackEchoFrom: spokenText
            )

            if self.status == .running {
                self.recordingStatusMessage = "Loop running. Mic is active for steering. Pause to inject guidance."
            } else {
                self.recordingStatusMessage = "Listening continuously. Pause to start x-maxx."
            }
        }
    }

    private func executeActions(_ actions: [ActionItem]) async -> [ActionItem] {
        var updatedActions = actions

        for index in updatedActions.indices {
            let normalizedTool = updatedActions[index].tool
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()

            guard updatedActions[index].status == .ready else { continue }

            switch normalizedTool {
            case "mouse_move", "mouse_click", "mouse_right_click":
                guard let x = updatedActions[index].x, let y = updatedActions[index].y else {
                    updatedActions[index].status = .blocked
                    updatedActions[index].output = "Missing screen coordinates for \(updatedActions[index].tool)."
                    continue
                }

                guard SystemPermissionPrompter.isAccessibilityGranted() else {
                    updatedActions[index].status = .blocked
                    updatedActions[index].output = "Mouse automation requires Accessibility permission in System Settings > Privacy & Security > Accessibility."
                    continue
                }

                do {
                    let result = try await mouseExecutor.execute(tool: normalizedTool, x: x, y: y)
                    updatedActions[index].status = .done
                    updatedActions[index].output = result
                } catch {
                    updatedActions[index].status = .blocked
                    updatedActions[index].output = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                }

            default:
                continue
            }
        }

        return updatedActions
    }

    private func graphEmphasis(for status: ActionStatus) -> Double {
        switch status {
        case .queued:
            return 0.35
        case .ready:
            return 0.65
        case .blocked:
            return 0.45
        case .done:
            return 0.95
        }
    }
}

private extension OODACycle {
    var externalDialogue: String {
        let actionTitles = actions.prefix(2).map(\.title).joined(separator: ", ")

        guard !actionTitles.isEmpty else {
            return "Iteration \(iteration). \(summary)"
        }

        return "Iteration \(iteration). \(summary) Next I will handle \(actionTitles)."
    }

    var internalDialogue: String {
        let observeHeadline = sections.first(where: { $0.phase == .observe })?.headline ?? "Observation unavailable"
        let decideHeadline = sections.first(where: { $0.phase == .decide })?.headline ?? "Decision unavailable"
        let actionTools = actions.prefix(3).map { "\($0.tool) on \($0.target)" }.joined(separator: "; ")

        if actionTools.isEmpty {
            return "Iteration \(iteration). Observe: \(observeHeadline). Decide: \(decideHeadline). No executable actions were attached."
        }

        return "Iteration \(iteration). Observe: \(observeHeadline). Decide: \(decideHeadline). Planned actions: \(actionTools). Progress is \(Int(progress * 100)) percent."
    }
}

extension AppStore {
    static let placeholderSections: [OODASection] = [
        OODASection(
            phase: .observe,
            headline: "Observe the machine state",
            narrative: "Capture the current screen, focused app, recent events, and direct user intent before making moves.",
            bullets: [
                "Collect screen and window context.",
                "Track user command and recent history.",
                "Prefer facts over guesses."
            ],
            confidence: 0.35
        ),
        OODASection(
            phase: .orient,
            headline: "Build the operating picture",
            narrative: "Transform raw signals into a grounded model of what the user is doing, what matters next, and what tools are available.",
            bullets: [
                "Summarize goals, blockers, and constraints.",
                "Note missing information explicitly.",
                "Update the mental model every cycle."
            ],
            confidence: 0.40
        ),
        OODASection(
            phase: .decide,
            headline: "Choose the next move",
            narrative: "Select the smallest action sequence that reduces uncertainty or advances the mission without creating avoidable risk.",
            bullets: [
                "Prioritize reversible moves.",
                "Keep the plan short and inspectable.",
                "Escalate when stakes are high."
            ],
            confidence: 0.42
        ),
        OODASection(
            phase: .act,
            headline: "Execute and loop fast",
            narrative: "Run the chosen step, inspect the result immediately, and fold the outcome back into the next observation cycle.",
            bullets: [
                "Execute the next action clearly.",
                "Log results and anomalies.",
                "Re-enter observation immediately."
            ],
            confidence: 0.38
        )
    ]

    static let placeholderActions: [ActionItem] = [
        ActionItem(
            title: "Add screen observation bridge",
            tool: "Frontend",
            target: "Observation panel",
            rationale: "Computer use starts with reliable state capture.",
            status: .ready
        ),
        ActionItem(
            title: "Connect ChatGPT planning call",
            tool: "Responses API",
            target: "OODA cycle generation",
            rationale: "Turn mission and environment text into an explicit plan.",
            status: .done
        ),
        ActionItem(
            title: "Add safe action executor",
            tool: "Automation bridge",
            target: "Act phase",
            rationale: "Planned actions need a controlled execution layer next.",
            status: .queued
        )
    ]
}

private struct GeneratedLoop {
    let model: String
    let summary: String
    let progress: Double
    let objectiveMet: Bool
    let isBlocked: Bool
    let blocker: String?
    let sections: [OODASection]
    let actions: [ActionItem]
}

private struct OpenAIClient {
    private let session = URLSession.shared
    private let model = "gpt-4.1-mini"

    func generateOODALoop(
        apiKey: String,
        profileName: String,
        mission: String,
        environment: String,
        operatorFeedback: String,
        iteration: Int,
        maxIterations: Int,
        priorCycles: [OODACycle]
    ) async throws -> GeneratedLoop {
        guard let url = URL(string: "https://api.openai.com/v1/responses") else {
            throw OpenAIClientError.invalidRequest
        }

        let systemPrompt = """
        You are driving an autonomous x-maxx OODA loop for a desktop computer-use copilot.
        Return JSON only.
        Use grounded reasoning. If information is missing, say that directly instead of inventing facts.
        Goal: maximize progress toward objective x, where x is the user's mission.
        The loop should continue until the objective is met, the agent is blocked, or the iteration budget is exhausted.
        Treat operator feedback as live steering from the human. If it changes priorities, constraints, or desired direction, adapt immediately in the next iteration instead of continuing the old plan.
        Keep the loop steerable: prefer small, reversible next moves over long speculative plans when live steering is present.
        If the mission or latest steering is ambiguous, say exactly what clarification is needed.

        Required JSON shape:
        {
          "summary": "string",
          "progress": 0.0,
          "objective_met": false,
          "blocked": false,
          "blocker": "string or null",
          "observe": { "headline": "string", "narrative": "string", "bullets": ["string"], "confidence": 0.0 },
          "orient": { "headline": "string", "narrative": "string", "bullets": ["string"], "confidence": 0.0 },
          "decide": { "headline": "string", "narrative": "string", "bullets": ["string"], "confidence": 0.0 },
          "act": { "headline": "string", "narrative": "string", "bullets": ["string"], "confidence": 0.0 },
          "actions": [
            { "title": "string", "tool": "string", "target": "string", "rationale": "string", "status": "queued|ready|blocked|done", "x": 0.0, "y": 0.0 }
          ]
        }

        Keep bullets concise. Prefer 2 to 4 bullets per section and 3 to 6 actions total.
        Set "objective_met" true only when the objective is actually achieved within the known context.
        Set "blocked" true only when the next step cannot proceed without missing tooling, permissions, or new human input.
        "progress" must be a number from 0.0 to 1.0 showing estimated distance closed toward the mission.
        Available executable tools right now are mouse_move, mouse_click, and mouse_right_click. When you choose one of those tools, include absolute screen coordinates in x and y. Do not invent coordinates unless the environment explicitly gives enough information to ground them.
        A real automation executor exists for those mouse tools. Do not claim automation is unavailable when coordinates and Accessibility permission are available.
        Only mark the loop blocked for automation when coordinates are missing, Accessibility permission is missing, or a real tool execution error occurs.
        """

        let operatorName = profileName.isEmpty ? "Operator" : profileName
        let historySummary = priorCycles.isEmpty ? "No prior cycles yet." : priorCycles.prefix(6).map { cycle in
            let blockerText = cycle.blocker ?? "none"
            let actionTitles = cycle.actions.map(\.title).joined(separator: ", ")
            return """
            Iteration \(cycle.iteration)
            Summary: \(cycle.summary)
            Progress: \(Int(cycle.progress * 100))%
            Objective Met: \(cycle.objectiveMet)
            Blocked: \(cycle.isBlocked)
            Blocker: \(blockerText)
            Actions: \(actionTitles)
            """
        }.joined(separator: "\n\n")
        let userPrompt = """
        Profile: \(operatorName)
        Iteration: \(iteration) of \(maxIterations)
        Mission:
        \(mission)

        Environment:
        \(environment)

        Operator feedback:
        \(operatorFeedback.isEmpty ? "None." : operatorFeedback)

        Prior cycles:
        \(historySummary)

        Produce the next OODA loop for this app. This is a macOS desktop copilot dashboard. It can plan through ChatGPT, it has a limited real automation executor for coordinate-based mouse actions, and it does not yet have live screen capture. Make the output useful, specific, and honest about gaps. Push the loop forward instead of repeating generic advice. Assume operator feedback may have arrived while the loop was already running, and give it priority over stale earlier plans.
        """

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let body = ResponsesRequest(
            model: model,
            input: [
                ResponsesRequest.Message(
                    role: "system",
                    content: [.init(type: "input_text", text: systemPrompt)]
                ),
                ResponsesRequest.Message(
                    role: "user",
                    content: [.init(type: "input_text", text: userPrompt)]
                )
            ],
            text: .init(format: .init(type: "json_object"))
        )

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            throw OpenAIClientError.network(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIClientError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let apiError = try? JSONDecoder().decode(OpenAIErrorEnvelope.self, from: data)
            throw OpenAIClientError.apiError(apiError?.error.message ?? "OpenAI request failed with status \(httpResponse.statusCode).")
        }

        let envelope = try JSONDecoder().decode(ResponsesEnvelope.self, from: data)
        let payloadText = envelope.outputText ?? envelope.output.compactMap { item in
            item.content?.compactMap(\.text).joined(separator: "\n")
        }.joined(separator: "\n")

        guard !payloadText.isEmpty, let jsonData = payloadText.data(using: .utf8) else {
            throw OpenAIClientError.emptyOutput
        }

        let loopResponse = try JSONDecoder().decode(LoopResponse.self, from: jsonData)

        return GeneratedLoop(
            model: envelope.model ?? model,
            summary: loopResponse.summary,
            progress: min(max(loopResponse.progress, 0), 1),
            objectiveMet: loopResponse.objectiveMet,
            isBlocked: loopResponse.blocked,
            blocker: loopResponse.blocker,
            sections: [
                loopResponse.observe.makeSection(for: .observe),
                loopResponse.orient.makeSection(for: .orient),
                loopResponse.decide.makeSection(for: .decide),
                loopResponse.act.makeSection(for: .act)
            ],
            actions: loopResponse.actions.map {
                ActionItem(
                    title: $0.title,
                    tool: $0.tool,
                    target: $0.target,
                    rationale: $0.rationale,
                    status: $0.status,
                    x: $0.x,
                    y: $0.y,
                    output: nil
                )
            }
        )
    }
}

private actor PythonMouseExecutor {
    func execute(tool: String, x: Double, y: Double) async throws -> String {
        let buttonName: String
        let eventKind: String

        switch tool {
        case "mouse_move":
            buttonName = "left"
            eventKind = "move"
        case "mouse_right_click":
            buttonName = "right"
            eventKind = "click"
        default:
            buttonName = "left"
            eventKind = "click"
        }

        let script = """
import Quartz
import time

x = float(\(x))
y = float(\(y))
point = (x, y)

move = Quartz.CGEventCreateMouseEvent(None, Quartz.kCGEventMouseMoved, point, Quartz.kCGMouseButtonLeft)
Quartz.CGEventPost(Quartz.kCGHIDEventTap, move)
time.sleep(0.05)

if "\(eventKind)" == "click":
    button = Quartz.kCGMouseButtonRight if "\(buttonName)" == "right" else Quartz.kCGMouseButtonLeft
    down_type = Quartz.kCGEventRightMouseDown if button == Quartz.kCGMouseButtonRight else Quartz.kCGEventLeftMouseDown
    up_type = Quartz.kCGEventRightMouseUp if button == Quartz.kCGMouseButtonRight else Quartz.kCGEventLeftMouseUp
    down = Quartz.CGEventCreateMouseEvent(None, down_type, point, button)
    up = Quartz.CGEventCreateMouseEvent(None, up_type, point, button)
    Quartz.CGEventPost(Quartz.kCGHIDEventTap, down)
    Quartz.CGEventPost(Quartz.kCGHIDEventTap, up)

print(f"\(tool) executed at ({x:.1f}, {y:.1f})")
"""

        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
            process.arguments = ["-c", script]

            let outputPipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = errorPipe

            process.terminationHandler = { process in
                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let errorText = String(data: errorData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

                if process.terminationStatus == 0 {
                    continuation.resume(returning: output.isEmpty ? "\(tool) executed." : output)
                } else {
                    continuation.resume(throwing: MouseExecutionError.executionFailed(errorText.isEmpty ? "Python mouse command failed." : errorText))
                }
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: MouseExecutionError.executionFailed(error.localizedDescription))
            }
        }
    }
}

private struct MissionCapture {
    let transcript: String
    let audioFileURL: URL?

    func deleteTemporaryAudioFileIfNeeded() {
        guard let audioFileURL else { return }
        try? FileManager.default.removeItem(at: audioFileURL)
    }
}

private final class MissionTranscriber {
    private let silenceCommitDelayNanoseconds: UInt64 = 500_000_000
    private let playbackEchoFilterDuration: TimeInterval = 1.2
    private let audioEngine = AVAudioEngine()
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioCaptureQueue = DispatchQueue(label: "AthenaLive.xmaxx.audioCapture")
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var lastTranscript = ""
    private var lastRecognitionEmission = ""
    private var didCaptureSpeech = false
    private var silenceCommitTask: Task<Void, Never>?
    private var resumeDeliveryTask: Task<Void, Never>?
    private var updateHandler: (@Sendable (String) -> Void)?
    private var finalHandler: (@Sendable (MissionCapture) -> Void)?
    private var isRunning = false
    private var isSegmentDeliveryEnabled = true
    private var deliveryModeVersion: UInt64 = 0
    private var recognitionSessionVersion: UInt64 = 0
    private var playbackEchoReference = ""
    private var playbackEchoDeadline = Date.distantPast
    private var captureAudioForAnalysis = false
    private var currentUtterancePCM = Data()
    private var currentUtteranceSampleRate: Double = 16_000
    private var currentUtteranceChannelCount: UInt16 = 1

    func start(
        captureAudioForAnalysis: Bool,
        initialText: String,
        onUpdate: @escaping @Sendable (String) -> Void,
        onFinal: @escaping @Sendable (MissionCapture) -> Void
    ) async throws {
        guard let recognizer else {
            throw MissionTranscriberError.unavailable
        }

        guard recognizer.isAvailable else {
            throw MissionTranscriberError.unavailable
        }

        let speechStatus = await requestSpeechAuthorization()
        guard speechStatus == .authorized else {
            throw MissionTranscriberError.speechPermissionDenied
        }

        let microphoneGranted = await requestMicrophonePermission()
        guard microphoneGranted else {
            throw MissionTranscriberError.microphonePermissionDenied
        }

        stop()
        lastTranscript = ""
        lastRecognitionEmission = ""
        didCaptureSpeech = false
        self.captureAudioForAnalysis = captureAudioForAnalysis
        updateHandler = onUpdate
        finalHandler = onFinal

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        currentUtteranceSampleRate = format.sampleRate
        currentUtteranceChannelCount = 1
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
            self?.captureAudioBufferIfNeeded(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        isRunning = true
        isSegmentDeliveryEnabled = true
        playbackEchoReference = ""
        playbackEchoDeadline = .distantPast
        _ = initialText
        startRecognitionSession()
    }

    func stop() {
        silenceCommitTask?.cancel()
        silenceCommitTask = nil
        resumeDeliveryTask?.cancel()
        resumeDeliveryTask = nil
        recognitionSessionVersion &+= 1
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest?.endAudio()
        recognitionRequest = nil

        if audioEngine.isRunning {
            audioEngine.stop()
        }

        audioEngine.reset()
        audioEngine.inputNode.removeTap(onBus: 0)
        lastTranscript = ""
        lastRecognitionEmission = ""
        didCaptureSpeech = false
        updateHandler = nil
        finalHandler = nil
        isRunning = false
        isSegmentDeliveryEnabled = true
        deliveryModeVersion &+= 1
        playbackEchoReference = ""
        playbackEchoDeadline = .distantPast
        captureAudioForAnalysis = false
        audioCaptureQueue.sync {
            currentUtterancePCM.removeAll(keepingCapacity: false)
        }
    }

    func suspendSegmentDelivery() {
        deliveryModeVersion &+= 1
        resumeDeliveryTask?.cancel()
        resumeDeliveryTask = nil
        isSegmentDeliveryEnabled = false
        playbackEchoReference = ""
        playbackEchoDeadline = .distantPast
        resetCurrentUtterance()
    }

    func resumeSegmentDelivery(
        afterNanoseconds delayNanoseconds: UInt64 = 0,
        suppressingPlaybackEchoFrom referenceText: String? = nil
    ) {
        deliveryModeVersion &+= 1
        let deliveryVersion = deliveryModeVersion
        let normalizedReference = normalize(referenceText ?? "")

        resumeDeliveryTask?.cancel()
        resumeDeliveryTask = nil
        resetCurrentUtterance()

        if delayNanoseconds == 0 {
            guard isRunning else { return }
            isSegmentDeliveryEnabled = true
            configurePlaybackEchoFilter(using: normalizedReference)
            return
        }

        isSegmentDeliveryEnabled = false
        resumeDeliveryTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: delayNanoseconds)
            guard let self, !Task.isCancelled, self.isRunning, self.deliveryModeVersion == deliveryVersion else { return }
            self.isSegmentDeliveryEnabled = true
            self.configurePlaybackEchoFilter(using: normalizedReference)
        }
    }

    private func scheduleSilenceCommit(using transcript: String) {
        silenceCommitTask?.cancel()

        silenceCommitTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: self.silenceCommitDelayNanoseconds)
            guard !Task.isCancelled, self.isRunning else { return }
            self.finishCurrentUtterance(withFallback: transcript)
            self.restartRecognitionSession()
        }
    }

    private func startRecognitionSession() {
        guard let recognizer, isRunning else { return }

        recognitionSessionVersion &+= 1
        let sessionVersion = recognitionSessionVersion

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = false
        }

        recognitionRequest = request
        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self, self.recognitionSessionVersion == sessionVersion else { return }
            self.handleRecognition(result: result, error: error)
        }
    }

    private func restartRecognitionSession() {
        guard isRunning else { return }
        recognitionSessionVersion &+= 1
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        startRecognitionSession()
    }

    private func handleRecognition(result: SFSpeechRecognitionResult?, error: Error?) {
        if let error {
            _ = error
            finishCurrentUtterance(withFallback: lastTranscript)
            restartRecognitionSession()
            return
        }

        guard let result else { return }

        let transcript = result.bestTranscription.formattedString.trimmingCharacters(in: .whitespacesAndNewlines)
        if shouldIgnoreTranscript(transcript) {
            if result.isFinal {
                finishCurrentUtterance(withFallback: transcript)
                restartRecognitionSession()
            }
            return
        }

        let shouldRescheduleSilenceCommit = transcript != lastRecognitionEmission
        lastRecognitionEmission = transcript

        if !transcript.isEmpty {
            didCaptureSpeech = true
            lastTranscript = transcript
            updateHandler?(transcript)
            if shouldRescheduleSilenceCommit {
                scheduleSilenceCommit(using: transcript)
            }
        }

        if result.isFinal {
            finishCurrentUtterance(withFallback: transcript)
            restartRecognitionSession()
        }
    }

    private func finishCurrentUtterance(withFallback fallback: String) {
        silenceCommitTask?.cancel()
        silenceCommitTask = nil

        let finalTranscript = lastTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedTranscript = didCaptureSpeech ? (finalTranscript.isEmpty ? fallback.trimmingCharacters(in: .whitespacesAndNewlines) : finalTranscript) : ""
        let audioFileURL = didCaptureSpeech ? makeAudioCaptureFileIfAvailable() : nil
        resetCurrentUtterance()

        guard isSegmentDeliveryEnabled, !resolvedTranscript.isEmpty else { return }
        finalHandler?(MissionCapture(
            transcript: resolvedTranscript,
            audioFileURL: audioFileURL
        ))
    }

    private func resetCurrentUtterance() {
        silenceCommitTask?.cancel()
        silenceCommitTask = nil
        lastTranscript = ""
        lastRecognitionEmission = ""
        didCaptureSpeech = false
        audioCaptureQueue.sync {
            currentUtterancePCM.removeAll(keepingCapacity: false)
        }
    }

    private func captureAudioBufferIfNeeded(_ buffer: AVAudioPCMBuffer) {
        guard captureAudioForAnalysis, isSegmentDeliveryEnabled, buffer.frameLength > 0 else { return }

        let frameCount = Int(buffer.frameLength)
        var pcmChunk = Data(count: frameCount * MemoryLayout<Int16>.size)

        pcmChunk.withUnsafeMutableBytes { rawBuffer in
            let pcmSamples = rawBuffer.bindMemory(to: Int16.self)

            if let floatChannelData = buffer.floatChannelData {
                let source = floatChannelData[0]
                for index in 0..<frameCount {
                    let clampedSample = max(-1.0, min(1.0, source[index]))
                    pcmSamples[index] = Int16(clampedSample * Float(Int16.max)).littleEndian
                }
            } else if let int16ChannelData = buffer.int16ChannelData {
                let source = int16ChannelData[0]
                for index in 0..<frameCount {
                    pcmSamples[index] = source[index].littleEndian
                }
            } else if let int32ChannelData = buffer.int32ChannelData {
                let source = int32ChannelData[0]
                for index in 0..<frameCount {
                    let shiftedSample = source[index] >> 16
                    let clampedSample = max(Int32(Int16.min), min(Int32(Int16.max), shiftedSample))
                    pcmSamples[index] = Int16(clampedSample).littleEndian
                }
            }
        }

        audioCaptureQueue.async { [weak self] in
            self?.currentUtterancePCM.append(pcmChunk)
        }
    }

    private func makeAudioCaptureFileIfAvailable() -> URL? {
        guard captureAudioForAnalysis else { return nil }

        let pcmData = audioCaptureQueue.sync { currentUtterancePCM }
        guard !pcmData.isEmpty else { return nil }

        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("xmaxx-utterance-\(UUID().uuidString)")
            .appendingPathExtension("wav")

        do {
            let wavData = try makeWAVData(
                pcmData: pcmData,
                sampleRate: currentUtteranceSampleRate,
                channelCount: currentUtteranceChannelCount
            )
            try wavData.write(to: fileURL, options: .atomic)
            return fileURL
        } catch {
            return nil
        }
    }

    private func makeWAVData(
        pcmData: Data,
        sampleRate: Double,
        channelCount: UInt16
    ) throws -> Data {
        let bitsPerSample: UInt16 = 16
        let byteRate = UInt32(sampleRate) * UInt32(channelCount) * UInt32(bitsPerSample / 8)
        let blockAlign = channelCount * (bitsPerSample / 8)
        let dataChunkSize = UInt32(pcmData.count)
        let riffChunkSize = 36 + dataChunkSize

        var wavData = Data()
        wavData.append("RIFF".data(using: .ascii) ?? Data())
        wavData.append(littleEndianData(riffChunkSize))
        wavData.append("WAVE".data(using: .ascii) ?? Data())
        wavData.append("fmt ".data(using: .ascii) ?? Data())
        wavData.append(littleEndianData(UInt32(16)))
        wavData.append(littleEndianData(UInt16(1)))
        wavData.append(littleEndianData(channelCount))
        wavData.append(littleEndianData(UInt32(sampleRate.rounded())))
        wavData.append(littleEndianData(byteRate))
        wavData.append(littleEndianData(blockAlign))
        wavData.append(littleEndianData(bitsPerSample))
        wavData.append("data".data(using: .ascii) ?? Data())
        wavData.append(littleEndianData(dataChunkSize))
        wavData.append(pcmData)
        return wavData
    }

    private func littleEndianData<T: FixedWidthInteger>(_ value: T) -> Data {
        var littleEndianValue = value.littleEndian
        return Data(bytes: &littleEndianValue, count: MemoryLayout<T>.size)
    }

    private func configurePlaybackEchoFilter(using reference: String) {
        playbackEchoReference = reference
        playbackEchoDeadline = reference.isEmpty ? .distantPast : Date().addingTimeInterval(playbackEchoFilterDuration)
    }

    private func shouldIgnoreTranscript(_ transcript: String) -> Bool {
        guard isSegmentDeliveryEnabled else { return true }

        let normalizedTranscript = normalize(transcript)
        guard !normalizedTranscript.isEmpty else { return false }
        guard Date() < playbackEchoDeadline, !playbackEchoReference.isEmpty else { return false }

        if normalizedTranscript.count >= 12 &&
            (playbackEchoReference.contains(normalizedTranscript) || normalizedTranscript.contains(playbackEchoReference)) {
            return true
        }

        let transcriptWords = Set(normalizedTranscript.split(separator: " ").map(String.init))
        let referenceWords = Set(playbackEchoReference.split(separator: " ").map(String.init))
        let overlap = transcriptWords.intersection(referenceWords).count
        let minimumSharedWords = min(transcriptWords.count, referenceWords.count)

        guard overlap >= 3, minimumSharedWords > 0 else { return false }
        return Double(overlap) / Double(minimumSharedWords) >= 0.7
    }

    private func normalize(_ text: String) -> String {
        let lowercase = text.lowercased()
        let scalars = lowercase.unicodeScalars.map { scalar -> Character in
            if CharacterSet.alphanumerics.contains(scalar) {
                return Character(scalar)
            }

            return " "
        }

        return String(scalars)
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    private func requestSpeechAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }

    private func requestMicrophonePermission() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .audio)
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }

}

private enum MissionTranscriberError: LocalizedError {
    case unavailable
    case speechPermissionDenied
    case microphonePermissionDenied

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "Speech recognition is currently unavailable on this Mac."
        case .speechPermissionDenied:
            return "Speech recognition permission was denied."
        case .microphonePermissionDenied:
            return "Microphone permission was denied."
        }
    }
}

private struct PyannoteUtteranceAnalysis {
    let missionTranscript: String
    let loopContext: String
    let summary: String
}

private actor PyannoteClient {
    private struct MediaUploadRequest: Encodable {
        let url: String
    }

    private struct MediaUploadResponse: Decodable {
        let url: String
    }

    private struct DiarizeRequest: Encodable {
        let url: String
        let model: String
        let exclusive: Bool
        let transcription: Bool
    }

    private struct JobCreateResponse: Decodable {
        let jobId: String
        let status: String
        let warning: String?
    }

    private struct JobResponse: Decodable {
        let jobId: String
        let status: String
        let warning: String?
        let output: JobOutput?
    }

    private struct JobOutput: Decodable {
        let diarization: [SpeakerSegment]?
        let exclusiveDiarization: [SpeakerSegment]?
        let turnLevelTranscription: [SpeechTurn]?
        let error: String?
        let warning: String?
    }

    private struct SpeakerSegment: Decodable {
        let speaker: String
        let start: Double
        let end: Double
    }

    private struct SpeechTurn: Decodable {
        let start: Double
        let end: Double
        let text: String
        let speaker: String
    }

    private let session = URLSession.shared
    private let baseURL = URL(string: "https://api.pyannote.ai/v1")!

    func analyzeUtterance(audioFileURL: URL, apiKey: String) async throws -> PyannoteUtteranceAnalysis {
        let objectKey = "xmaxx/\(UUID().uuidString).wav"
        let mediaURL = "media://\(objectKey)"

        let uploadURL = try await createUploadURL(mediaURL: mediaURL, apiKey: apiKey)
        try await uploadAudioFile(audioFileURL, uploadURL: uploadURL)

        let jobID = try await submitDiarizationJob(mediaURL: mediaURL, apiKey: apiKey)
        let job = try await pollJobUntilFinished(jobID: jobID, apiKey: apiKey)
        return try makeAnalysis(from: job)
    }

    private func createUploadURL(mediaURL: String, apiKey: String) async throws -> URL {
        let endpoint = baseURL.appending(path: "media/input")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(MediaUploadRequest(url: mediaURL))

        let response: MediaUploadResponse = try await performJSONRequest(request, acceptedStatusCodes: 200...299)

        guard let uploadURL = URL(string: response.url) else {
            throw PyannoteError.invalidResponse
        }

        return uploadURL
    }

    private func uploadAudioFile(_ audioFileURL: URL, uploadURL: URL) async throws {
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "PUT"
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")

        do {
            let (_, response) = try await session.upload(for: request, fromFile: audioFileURL)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw PyannoteError.invalidResponse
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw PyannoteError.apiError("pyannote media upload failed with status \(httpResponse.statusCode).")
            }
        } catch let error as URLError {
            throw PyannoteError.network(error)
        }
    }

    private func submitDiarizationJob(mediaURL: String, apiKey: String) async throws -> String {
        let endpoint = baseURL.appending(path: "diarize")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(
            DiarizeRequest(
                url: mediaURL,
                model: "precision-2",
                exclusive: true,
                transcription: true
            )
        )

        let response: JobCreateResponse = try await performJSONRequest(request, acceptedStatusCodes: 200...299)
        return response.jobId
    }

    private func pollJobUntilFinished(jobID: String, apiKey: String) async throws -> JobResponse {
        let deadline = Date().addingTimeInterval(25)

        while Date() < deadline {
            let job = try await fetchJob(jobID: jobID, apiKey: apiKey)

            switch job.status {
            case "succeeded":
                return job
            case "failed":
                throw PyannoteError.jobFailed(job.output?.error ?? job.warning ?? "pyannote diarization job failed.")
            case "canceled":
                throw PyannoteError.jobFailed("pyannote diarization job was canceled.")
            default:
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }

        throw PyannoteError.timedOut
    }

    private func fetchJob(jobID: String, apiKey: String) async throws -> JobResponse {
        let endpoint = baseURL.appending(path: "jobs/\(jobID)")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        return try await performJSONRequest(request, acceptedStatusCodes: 200...299)
    }

    private func performJSONRequest<Response: Decodable>(
        _ request: URLRequest,
        acceptedStatusCodes: ClosedRange<Int>
    ) async throws -> Response {
        let (data, response): (Data, URLResponse)

        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            throw PyannoteError.network(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw PyannoteError.invalidResponse
        }

        guard acceptedStatusCodes.contains(httpResponse.statusCode) else {
            let apiMessage = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            throw PyannoteError.apiError(apiMessage?.isEmpty == false ? apiMessage! : "pyannote request failed with status \(httpResponse.statusCode).")
        }

        do {
            return try JSONDecoder().decode(Response.self, from: data)
        } catch {
            throw PyannoteError.invalidResponse
        }
    }

    private func makeAnalysis(from job: JobResponse) throws -> PyannoteUtteranceAnalysis {
        guard let output = job.output else {
            throw PyannoteError.missingResult
        }

        let turns = (output.turnLevelTranscription ?? [])
            .map {
                SpeechTurn(
                    start: $0.start,
                    end: $0.end,
                    text: $0.text.trimmingCharacters(in: .whitespacesAndNewlines),
                    speaker: $0.speaker
                )
            }
            .filter { !$0.text.isEmpty }

        let timingSegments = output.exclusiveDiarization ?? output.diarization ?? []
        let speakerDurations = timingSegments.reduce(into: [String: Double]()) { partialResult, segment in
            partialResult[segment.speaker, default: 0] += max(0, segment.end - segment.start)
        }

        let sortedSpeakers = speakerDurations
            .sorted { lhs, rhs in
                if lhs.value == rhs.value {
                    return lhs.key < rhs.key
                }
                return lhs.value > rhs.value
            }
            .map(\.key)

        let dominantSpeaker = sortedSpeakers.first
        let speakerCount = max(sortedSpeakers.count, Set(turns.map(\.speaker)).count)

        let missionTranscript: String
        if turns.isEmpty {
            missionTranscript = ""
        } else if Set(turns.map(\.speaker)).count <= 1 {
            missionTranscript = turns.map(\.text).joined(separator: " ")
        } else {
            missionTranscript = turns
                .map { turn in
                    "\(turn.speaker) (\(formatTimestamp(turn.start))-\(formatTimestamp(turn.end))): \(turn.text)"
                }
                .joined(separator: "\n")
        }

        let loopContext = """
        Recent voice analysis from pyannoteAI:
        Speakers detected: \(max(1, speakerCount))
        Dominant speaker: \(dominantSpeaker ?? "unknown")
        Speaker order by activity: \(sortedSpeakers.isEmpty ? "unknown" : sortedSpeakers.joined(separator: ", "))
        Speaker-attributed transcript:
        \(missionTranscript.isEmpty ? "Unavailable" : missionTranscript)
        """

        let summary = speakerCount > 1
            ? "pyannote detected \(speakerCount) speakers and attached speaker turns."
            : "pyannote detected one active speaker."

        return PyannoteUtteranceAnalysis(
            missionTranscript: missionTranscript,
            loopContext: loopContext,
            summary: summary
        )
    }

    private func formatTimestamp(_ seconds: Double) -> String {
        let totalSeconds = max(Int(seconds.rounded(.down)), 0)
        let minutes = totalSeconds / 60
        let remainder = totalSeconds % 60
        return "\(minutes):" + String(format: "%02d", remainder)
    }
}

private enum PyannoteError: LocalizedError {
    case invalidResponse
    case network(URLError)
    case apiError(String)
    case jobFailed(String)
    case missingResult
    case timedOut

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "pyannote returned an invalid response."
        case let .network(error):
            return error.xmaxxDescription(for: "pyannote")
        case let .apiError(message):
            return message
        case let .jobFailed(message):
            return message
        case .missingResult:
            return "pyannote finished without a usable diarization result."
        case .timedOut:
            return "pyannote diarization timed out before finishing."
        }
    }
}

@MainActor
private final class SpeechCoordinator: NSObject {
    private let fallbackSynthesizer = AVSpeechSynthesizer()
    private let elevenLabsClient = ElevenLabsClient()
    private var audioPlayer: AVAudioPlayer?
    private var completionContinuation: CheckedContinuation<Void, Never>?

    override init() {
        super.init()
        fallbackSynthesizer.delegate = self
    }

    func speakAndWait(text: String, elevenLabsAPIKey: String?) async {
        let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedText.isEmpty else { return }

        stopCurrentPlayback()

        if let elevenLabsAPIKey, !elevenLabsAPIKey.isEmpty {
            do {
                let audioData = try await elevenLabsClient.synthesize(text: cleanedText, apiKey: elevenLabsAPIKey)
                audioPlayer = try AVAudioPlayer(data: audioData)
                audioPlayer?.delegate = self
                audioPlayer?.prepareToPlay()
                audioPlayer?.play()
                await waitForPlaybackToFinish()
                return
            } catch {
                // Fall through to the macOS system voice when ElevenLabs is unavailable.
            }
        }

        let utterance = AVSpeechUtterance(string: cleanedText)
        utterance.rate = 0.48
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        fallbackSynthesizer.speak(utterance)
        await waitForPlaybackToFinish()
    }

    private func stopCurrentPlayback() {
        completionContinuation?.resume()
        completionContinuation = nil

        if fallbackSynthesizer.isSpeaking {
            fallbackSynthesizer.stopSpeaking(at: .immediate)
        }

        audioPlayer?.stop()
        audioPlayer = nil
    }

    private func waitForPlaybackToFinish() async {
        await withCheckedContinuation { continuation in
            completionContinuation = continuation
        }
    }

    private func finishPlayback() {
        completionContinuation?.resume()
        completionContinuation = nil
        audioPlayer = nil
    }

}

extension SpeechCoordinator: AVSpeechSynthesizerDelegate, AVAudioPlayerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.finishPlayback()
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.finishPlayback()
        }
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.finishPlayback()
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in
            self.finishPlayback()
        }
    }
}

private enum SystemPermissionPrompter {
    nonisolated static func isAccessibilityGranted() -> Bool {
        AXIsProcessTrusted()
    }

    nonisolated static func isScreenRecordingGranted() -> Bool {
        CGPreflightScreenCaptureAccess()
    }

    nonisolated static func triggerAccessibilityPromptIfNeeded() {
        let options = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
        ] as CFDictionary

        _ = AXIsProcessTrustedWithOptions(options)
    }

    nonisolated static func requestScreenRecordingAccessIfNeeded() -> Bool {
        guard !CGPreflightScreenCaptureAccess() else { return true }
        return CGRequestScreenCaptureAccess()
    }

    nonisolated static func triggerAutomationPrompt(forBundleIdentifier bundleIdentifier: String) {
        let descriptor = NSAppleEventDescriptor(bundleIdentifier: bundleIdentifier)
        _ = AEDeterminePermissionToAutomateTarget(
            descriptor.aeDesc,
            AEEventClass(typeWildCard),
            AEEventID(typeWildCard),
            true
        )
    }

    nonisolated static func triggerAutomationPrompt() {
        let source = """
        tell application "System Events"
            return name of first process whose frontmost is true
        end tell
        """

        guard let script = NSAppleScript(source: source) else { return }
        var error: NSDictionary?
        _ = script.executeAndReturnError(&error)
    }
}

private struct ElevenLabsClient {
    private let session = URLSession.shared
    private let voiceID = "JBFqnCBsd6RMkjVDRZzb"

    func synthesize(text: String, apiKey: String) async throws -> Data {
        guard let url = URL(string: "https://api.elevenlabs.io/v1/text-to-speech/\(voiceID)?output_format=mp3_44100_128") else {
            throw ElevenLabsError.invalidRequest
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")

        let body = ElevenLabsRequest(
            text: text,
            modelID: "eleven_multilingual_v2"
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            throw ElevenLabsError.network(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ElevenLabsError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let apiError = try? JSONDecoder().decode(ElevenLabsErrorEnvelope.self, from: data)
            throw ElevenLabsError.apiError(apiError?.detail.message ?? "ElevenLabs request failed with status \(httpResponse.statusCode).")
        }

        return data
    }
}

private enum ElevenLabsError: LocalizedError {
    case invalidRequest
    case invalidResponse
    case network(URLError)
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .invalidRequest:
            return "Could not create the ElevenLabs request."
        case .invalidResponse:
            return "The ElevenLabs response was not a valid HTTP response."
        case let .network(error):
            return error.xmaxxDescription(for: "ElevenLabs")
        case let .apiError(message):
            return message
        }
    }
}

private enum MouseExecutionError: LocalizedError {
    case executionFailed(String)

    var errorDescription: String? {
        switch self {
        case let .executionFailed(message):
            return message
        }
    }
}

private struct ElevenLabsRequest: Encodable {
    let text: String
    let modelID: String

    enum CodingKeys: String, CodingKey {
        case text
        case modelID = "model_id"
    }
}

private struct ElevenLabsErrorEnvelope: Decodable {
    let detail: ElevenLabsErrorDetail

    struct ElevenLabsErrorDetail: Decodable {
        let message: String
    }
}

private enum OpenAIClientError: LocalizedError {
    case invalidRequest
    case invalidResponse
    case emptyOutput
    case network(URLError)
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .invalidRequest:
            return "Could not create the ChatGPT request."
        case .invalidResponse:
            return "The ChatGPT response was not a valid HTTP response."
        case .emptyOutput:
            return "ChatGPT returned no usable OODA plan."
        case let .network(error):
            return error.xmaxxDescription(for: "OpenAI")
        case let .apiError(message):
            return message
        }
    }
}

private extension URLError {
    func xmaxxDescription(for service: String) -> String {
        switch code {
        case .cannotFindHost, .dnsLookupFailed:
            return "\(service) could not be reached because the hostname lookup failed. Check internet access, DNS, VPN, or firewall settings."
        case .notConnectedToInternet:
            return "No internet connection is available for \(service)."
        case .timedOut:
            return "\(service) timed out before responding."
        case .cannotConnectToHost:
            return "A connection to \(service) could not be established."
        default:
            return localizedDescription
        }
    }
}

private struct ResponsesRequest: Encodable {
    let model: String
    let input: [Message]
    let text: TextConfiguration

    struct Message: Encodable {
        let role: String
        let content: [Content]
    }

    struct Content: Encodable {
        let type: String
        let text: String
    }

    struct TextConfiguration: Encodable {
        let format: TextFormat
    }

    struct TextFormat: Encodable {
        let type: String
    }
}

private struct ResponsesEnvelope: Decodable {
    let model: String?
    let outputText: String?
    let output: [OutputItem]

    enum CodingKeys: String, CodingKey {
        case model
        case output
        case outputText = "output_text"
    }

    struct OutputItem: Decodable {
        let content: [OutputContent]?
    }

    struct OutputContent: Decodable {
        let text: String?
    }
}

private struct LoopResponse: Decodable {
    let summary: String
    let progress: Double
    let objectiveMet: Bool
    let blocked: Bool
    let blocker: String?
    let observe: LoopSectionResponse
    let orient: LoopSectionResponse
    let decide: LoopSectionResponse
    let act: LoopSectionResponse
    let actions: [LoopActionResponse]

    enum CodingKeys: String, CodingKey {
        case summary
        case progress
        case objectiveMet = "objective_met"
        case blocked
        case blocker
        case observe
        case orient
        case decide
        case act
        case actions
    }
}

private struct LoopSectionResponse: Decodable {
    let headline: String
    let narrative: String
    let bullets: [String]
    let confidence: Double

    func makeSection(for phase: OODAPhase) -> OODASection {
        OODASection(
            phase: phase,
            headline: headline,
            narrative: narrative,
            bullets: bullets,
            confidence: min(max(confidence, 0), 1)
        )
    }
}

private struct LoopActionResponse: Decodable {
    let title: String
    let tool: String
    let target: String
    let rationale: String
    let status: ActionStatus
    let x: Double?
    let y: Double?
}

private struct OpenAIErrorEnvelope: Decodable {
    let error: OpenAIError

    struct OpenAIError: Decodable {
        let message: String
    }
}

private struct KeychainStore {
    private let service = Bundle.main.bundleIdentifier ?? "xmaxx"

    func save(_ value: String, account: String) {
        guard let data = value.data(using: .utf8) else { return }

        let query = baseQuery(account: account)
        SecItemDelete(query as CFDictionary)

        var attributes = query
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

        SecItemAdd(attributes as CFDictionary, nil)
    }

    func read(account: String) -> String? {
        var query = baseQuery(account: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess,
              let data = item as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }

        return value
    }

    func delete(account: String) {
        SecItemDelete(baseQuery(account: account) as CFDictionary)
    }

    private func baseQuery(account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}
