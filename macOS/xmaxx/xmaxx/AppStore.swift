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
import ScreenCaptureKit
import Vision

enum NavigationPhase: String, CaseIterable, Hashable, Codable, Identifiable {
    case observe
    case orient
    case decide
    case act
    case guide

    var id: String { rawValue }

    var title: String {
        switch self {
        case .observe:
            return "Observe"
        case .orient:
            return "Orient"
        case .decide:
            return "Decide"
        case .act:
            return "Act"
        case .guide:
            return "Guide"
        }
    }

    var shortLabel: String {
        switch self {
        case .observe:
            return "What is happening?"
        case .orient:
            return "What does it mean?"
        case .decide:
            return "What should I do?"
        case .act:
            return "Do it"
        case .guide:
            return "Did this reduce distance?"
        }
    }
}

enum DecisionModel: String, CaseIterable, Codable, Hashable, Identifiable {
    case ooda
    case recognitionPrimed = "recognition_primed"
    case system1System2 = "system_1_system_2"
    case bayesian
    case reinforcementLearning = "reinforcement_learning"
    case predictiveProcessing = "predictive_processing"
    case cynefin

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ooda:
            return "OODA"
        case .recognitionPrimed:
            return "Recognition-Primed"
        case .system1System2:
            return "System 1 / System 2"
        case .bayesian:
            return "Bayesian Updating"
        case .reinforcementLearning:
            return "Reinforcement Learning"
        case .predictiveProcessing:
            return "Predictive Processing"
        case .cynefin:
            return "Cynefin"
        }
    }

    var capsuleTitle: String {
        switch self {
        case .ooda:
            return "OODA"
        case .recognitionPrimed:
            return "RPD"
        case .system1System2:
            return "Sys1+2"
        case .bayesian:
            return "Bayes"
        case .reinforcementLearning:
            return "RL"
        case .predictiveProcessing:
            return "Predictive"
        case .cynefin:
            return "Cynefin"
        }
    }

    var summary: String {
        switch self {
        case .ooda:
            return "Continuous observe, orient, decide, act, and guide loop."
        case .recognitionPrimed:
            return "Pattern-match quickly and commit to the first workable move."
        case .system1System2:
            return "Balance fast intuition against slow deliberate reasoning."
        case .bayesian:
            return "Update beliefs explicitly as new evidence arrives."
        case .reinforcementLearning:
            return "Optimize behavior through action, reward, and policy updates."
        case .predictiveProcessing:
            return "Predict first, then use error signals to recalibrate."
        case .cynefin:
            return "Choose the decision style that fits the reality domain."
        }
    }

    var promptDescription: String {
        switch self {
        case .ooda:
            return "Use an OODA-style control loop: observe the environment, orient to meaning, decide the next move, act, and guide the next cycle based on what changed."
        case .recognitionPrimed:
            return "Use a recognition-primed style: match the situation to known patterns, mentally simulate the first workable response, and commit quickly instead of comparing many options."
        case .system1System2:
            return "Use a System 1 / System 2 split: surface the fast intuitive read, then explicitly state whether slower deliberate reasoning should confirm or override it."
        case .bayesian:
            return "Use Bayesian updating: name the prior belief, state the new evidence, update the posterior confidence, and act based on the updated odds."
        case .reinforcementLearning:
            return "Use a reinforcement learning lens: identify the current state, choose the action with the best expected reward, and explain what feedback signal should update the policy."
        case .predictiveProcessing:
            return "Use predictive processing: state the current prediction, identify prediction errors, update the internal model, and act to reduce uncertainty or mismatch."
        case .cynefin:
            return "Use the Cynefin framework: determine whether the situation is clear, complicated, complex, or chaotic, then pick the response mode that matches that domain."
        }
    }

    var stages: [DecisionStageDescriptor] {
        switch self {
        case .ooda:
            return [
                DecisionStageDescriptor(phase: .observe, title: "Observe", shortLabel: "What is happening?", instruction: "Capture concrete signals, state, and operator intent before inferring anything."),
                DecisionStageDescriptor(phase: .orient, title: "Orient", shortLabel: "What does it mean?", instruction: "Interpret the signals, constraints, and implications of the current situation."),
                DecisionStageDescriptor(phase: .decide, title: "Decide", shortLabel: "What should I do?", instruction: "Pick the next move that best reduces distance to the mission."),
                DecisionStageDescriptor(phase: .act, title: "Act", shortLabel: "What command executes it?", instruction: "Translate the chosen move into specific executable or operator-facing actions."),
                DecisionStageDescriptor(phase: .guide, title: "Guide", shortLabel: "Did it reduce distance?", instruction: "Measure whether the move improved the situation and steer the next cycle.")
            ]
        case .recognitionPrimed:
            return [
                DecisionStageDescriptor(phase: .observe, title: "Cue Scan", shortLabel: "What cues match known patterns?", instruction: "Surface the cues, environmental markers, and operator intent that matter most for recognition."),
                DecisionStageDescriptor(phase: .orient, title: "Pattern Match", shortLabel: "What known situation does this resemble?", instruction: "Name the most plausible situation pattern and why it fits the observed cues."),
                DecisionStageDescriptor(phase: .decide, title: "Mental Sim", shortLabel: "Does the first move survive quick simulation?", instruction: "Mentally simulate the first workable response and reject it only if it obviously fails."),
                DecisionStageDescriptor(phase: .act, title: "Commit", shortLabel: "What is the concrete move now?", instruction: "Commit to the best recognized action and express it concretely as an executable or operator-facing command."),
                DecisionStageDescriptor(phase: .guide, title: "Expert Update", shortLabel: "Did recognition hold up?", instruction: "State whether the recognized pattern still fits after action and what needs reframing.")
            ]
        case .system1System2:
            return [
                DecisionStageDescriptor(phase: .observe, title: "Stimulus", shortLabel: "What is the immediate signal?", instruction: "Capture the fresh signal, operator input, and surrounding context without filtering it away."),
                DecisionStageDescriptor(phase: .orient, title: "Fast Read", shortLabel: "What does intuition say first?", instruction: "State the fast automatic interpretation, including any emotional or heuristic pull."),
                DecisionStageDescriptor(phase: .decide, title: "Deliberate Check", shortLabel: "Should slower reasoning override it?", instruction: "Run the slower explicit check and state whether it confirms or overrides the fast read."),
                DecisionStageDescriptor(phase: .act, title: "Act", shortLabel: "What command follows from that?", instruction: "Produce the concrete next action or CLI command that follows from the chosen reasoning mode."),
                DecisionStageDescriptor(phase: .guide, title: "Audit", shortLabel: "What bias or drift showed up?", instruction: "Evaluate whether the outcome exposed bias, overreaction, or drift in either reasoning mode.")
            ]
        case .bayesian:
            return [
                DecisionStageDescriptor(phase: .observe, title: "Prior", shortLabel: "What do we currently believe?", instruction: "State the current working belief, hypothesis, or prior confidence before new evidence is processed."),
                DecisionStageDescriptor(phase: .orient, title: "Evidence", shortLabel: "What evidence just arrived?", instruction: "Identify the new evidence and explain how reliable it is."),
                DecisionStageDescriptor(phase: .decide, title: "Posterior", shortLabel: "What belief is strong enough to act on now?", instruction: "Update the belief state and make the posterior explicit enough to justify action."),
                DecisionStageDescriptor(phase: .act, title: "Bet", shortLabel: "What action fits the updated odds?", instruction: "Choose the action or CLI command implied by the updated belief distribution."),
                DecisionStageDescriptor(phase: .guide, title: "Recalibrate", shortLabel: "What should the next prior become?", instruction: "Use the result to inform the next prior and say what would change your belief again.")
            ]
        case .reinforcementLearning:
            return [
                DecisionStageDescriptor(phase: .observe, title: "State", shortLabel: "What state are we in?", instruction: "Describe the current state, local constraints, and what reward-relevant facts are visible."),
                DecisionStageDescriptor(phase: .orient, title: "Policy", shortLabel: "What behavior looks promising here?", instruction: "State the current policy intuition or action pattern that seems likely to improve reward."),
                DecisionStageDescriptor(phase: .decide, title: "Action Choice", shortLabel: "Which move maximizes expected reward now?", instruction: "Pick the best next action under the present policy and explain the reward logic."),
                DecisionStageDescriptor(phase: .act, title: "Execute", shortLabel: "What command do we run?", instruction: "Translate the chosen action into an executable or operator-facing command."),
                DecisionStageDescriptor(phase: .guide, title: "Reward Update", shortLabel: "What feedback should change the policy?", instruction: "Use the result as reward feedback and say how the policy should adapt next.")
            ]
        case .predictiveProcessing:
            return [
                DecisionStageDescriptor(phase: .observe, title: "Prediction", shortLabel: "What did we expect to see?", instruction: "State the current prediction or model expectation before reacting to the new evidence."),
                DecisionStageDescriptor(phase: .orient, title: "Error Signal", shortLabel: "What mismatched the prediction?", instruction: "Highlight the prediction errors, anomalies, or surprises that matter."),
                DecisionStageDescriptor(phase: .decide, title: "Inference", shortLabel: "What internal model best explains it?", instruction: "Update the internal model and state the inference that best explains the mismatch."),
                DecisionStageDescriptor(phase: .act, title: "Active Inference", shortLabel: "What command reduces uncertainty or error?", instruction: "Choose the action that best reduces prediction error, uncertainty, or ambiguity."),
                DecisionStageDescriptor(phase: .guide, title: "Calibration", shortLabel: "Did the model improve?", instruction: "State whether the action calibrated the model and what prediction changes next.")
            ]
        case .cynefin:
            return [
                DecisionStageDescriptor(phase: .observe, title: "Context", shortLabel: "What signals define the situation?", instruction: "Capture the current facts, volatility, and ambiguity that shape the problem space."),
                DecisionStageDescriptor(phase: .orient, title: "Domain", shortLabel: "Is this clear, complicated, complex, or chaotic?", instruction: "Classify the situation into the Cynefin domain that best fits the evidence."),
                DecisionStageDescriptor(phase: .decide, title: "Response Mode", shortLabel: "What decision style fits this domain?", instruction: "Choose the response mode that fits the domain instead of forcing one fixed style."),
                DecisionStageDescriptor(phase: .act, title: "Intervene", shortLabel: "What command fits this domain?", instruction: "Produce the action or CLI command appropriate to the chosen domain response mode."),
                DecisionStageDescriptor(phase: .guide, title: "Sensemaking", shortLabel: "What did the intervention reveal?", instruction: "Use the result to confirm or revise the domain classification for the next cycle.")
            ]
        }
    }
}

struct DecisionStageDescriptor: Hashable, Codable, Identifiable {
    let phase: NavigationPhase
    let title: String
    let shortLabel: String
    let instruction: String

    var id: NavigationPhase { phase }
}

struct DecisionProfile: Hashable {
    let selectedModels: [DecisionModel]
    let title: String
    let subtitle: String
    let summary: String
    let stages: [DecisionStageDescriptor]
    let promptContext: String

    var stageHeadline: String {
        stages.map(\.title).joined(separator: " / ")
    }

    var selectedModelLine: String {
        selectedModels.map(\.title).joined(separator: " + ")
    }

    func stage(for phase: NavigationPhase) -> DecisionStageDescriptor {
        stages.first(where: { $0.phase == phase })
            ?? DecisionStageDescriptor(
                phase: phase,
                title: phase.title,
                shortLabel: phase.shortLabel,
                instruction: "Explain this stage clearly and concretely."
            )
    }

    static func make(from selectedModels: [DecisionModel]) -> DecisionProfile {
        let resolvedModels = DecisionModel.allCases.filter { selectedModels.contains($0) }
        let models = resolvedModels.isEmpty ? [.ooda] : resolvedModels

        if models.count == 1, let model = models.first {
            return DecisionProfile(
                selectedModels: models,
                title: model.title,
                subtitle: model.summary,
                summary: "Active model: \(model.title).",
                stages: model.stages,
                promptContext: model.promptDescription
            )
        }

        let combinedDescriptions = models.map { "- \($0.title): \($0.promptDescription)" }.joined(separator: "\n")
        return DecisionProfile(
            selectedModels: models,
            title: "Synthesis",
            subtitle: models.map(\.capsuleTitle).joined(separator: " + "),
            summary: "Blend the selected models into one steerable action surface.",
            stages: [
                DecisionStageDescriptor(phase: .observe, title: "Signal Intake", shortLabel: "What signals, cues, and priors matter?", instruction: "Combine observation, cues, priors, and expectation signals before overcommitting to a frame."),
                DecisionStageDescriptor(phase: .orient, title: "Frame", shortLabel: "What pattern, domain, or error frame fits best?", instruction: "Blend pattern recognition, domain selection, evidence evaluation, and prediction-error framing into one coherent interpretation."),
                DecisionStageDescriptor(phase: .decide, title: "Commit", shortLabel: "What move survives both intuition and scrutiny?", instruction: "Pick the move that still holds after combining fast intuition, deliberate checks, and updated belief state."),
                DecisionStageDescriptor(phase: .act, title: "Command", shortLabel: "What exact action or CLI command should run now?", instruction: "Translate the chosen move into a concrete actionable command, tool call, or operator instruction."),
                DecisionStageDescriptor(phase: .guide, title: "Update", shortLabel: "How should the model change after the result?", instruction: "Use the outcome to update priors, reward expectations, domain classification, and the next frame.")
            ],
            promptContext: """
            Blend these decision models in one run:
            \(combinedDescriptions)
            Use the five semantic stages below as the synthesis surface. Keep the output concrete and action-oriented even when the models pull in different directions.
            """
        )
    }
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

private enum ActionApprovalDecision {
    case confirm
    case revise
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

struct NavigationSection: Identifiable, Hashable {
    let phase: NavigationPhase
    var stageTitle: String
    var stagePrompt: String
    var headline: String
    var narrative: String
    var bullets: [String]
    var confidence: Double

    var id: NavigationPhase { phase }
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

struct NavigationCycle: Identifiable, Hashable {
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
    let sections: [NavigationSection]
    let actions: [ActionItem]
}

struct ActionGraphNode: Identifiable, Hashable {
    enum Kind: Hashable {
        case loop
        case phase(NavigationPhase)
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
    @Published var selectedDecisionModels: [DecisionModel]
    @Published var missionText: String
    @Published var environmentText: String
    @Published var isRecordingMission: Bool
    @Published var voiceLoopEnabled: Bool
    @Published var isAgentSpeaking: Bool
    @Published var recordingStatusMessage: String
    @Published var voiceAnalysisSummary: String
    @Published var externalDialogText: String
    @Published var internalDialogText: String
    @Published private(set) var awaitingActionConfirmation: Bool
    @Published private(set) var isAccessibilityGranted: Bool
    @Published private(set) var isScreenRecordingGranted: Bool
    @Published var automationStatusMessage: String
    @Published var status: LoopStatus = .idle
    @Published var statusMessage: String
    @Published var currentIteration: Int
    @Published var maxIterations: Int
    @Published var objectiveProgress: Double
    @Published var operatorFeedback: String
    @Published var sections: [NavigationSection]
    @Published var actionQueue: [ActionItem]
    @Published private(set) var cycles: [NavigationCycle]
    @Published var selectedCycleID: NavigationCycle.ID?

    private let userDefaults: UserDefaults
    private let keychain = KeychainStore()
    private let client = OpenAIClient()
    private let mouseExecutor = NativeMouseExecutor()
    private let screenCoordinateResolver = ScreenCoordinateResolver()
    private let pyannoteClient = PyannoteClient()

    private let profileNameKey = "profileName"
    private let chatGPTAPIKeyKey = "chatGPTAPIKey"
    private let elevenLabsAPIKeyKey = "elevenLabsAPIKey"
    private let pyannoteAPIKeyKey = "pyannoteAPIKey"
    private let audioResponsesEnabledKey = "audioResponsesEnabled"
    private let audioDialogueModeKey = "audioDialogueMode"
    private let selectedDecisionModelsKey = "selectedDecisionModels"
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
    private var actionApprovalContinuation: CheckedContinuation<ActionApprovalDecision, Never>?
    private let speechCoordinator = SpeechCoordinator()
    private let missionTranscriber = MissionTranscriber()

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        let legacyDefaultEnvironmentText = """
        Current app shell is a macOS dashboard. We have profile and API key settings, but no live screen capture, automation executor, or tool bridge yet.
        """
        let previousCurrentDefaultEnvironmentText = """
        Current app shell is a macOS dashboard. ChatGPT planning is active, and a limited automation executor is available for coordinate-based mouse_move, mouse_click, and mouse_right_click when Accessibility permission is granted. Live screen capture is still unavailable, so actions need grounded coordinates from the environment.
        """
        let currentDefaultEnvironmentText = """
        Current app shell is a macOS dashboard. ChatGPT planning is active, a limited automation executor is available for coordinate-based mouse_move, mouse_click, and mouse_right_click when Accessibility permission is granted, and screenshot-based coordinate lookup is available through find_screen_text when Screen Recording permission is granted.
        """
        let storedProfileName = userDefaults.string(forKey: profileNameKey) ?? ""
        let storedMissionText = userDefaults.string(forKey: missionTextKey) ?? "Build a desktop computer-use copilot around a guided loop."
        let persistedEnvironmentText = userDefaults.string(forKey: environmentTextKey)
        let storedEnvironmentText: String
        if let persistedEnvironmentText {
            let trimmedPersistedEnvironmentText = persistedEnvironmentText.trimmingCharacters(in: .whitespacesAndNewlines)
            storedEnvironmentText = (trimmedPersistedEnvironmentText == legacyDefaultEnvironmentText || trimmedPersistedEnvironmentText == previousCurrentDefaultEnvironmentText)
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
        let storedDecisionModels = (userDefaults.stringArray(forKey: selectedDecisionModelsKey) ?? [])
            .compactMap(DecisionModel.init(rawValue:))
        let resolvedDecisionModels = storedDecisionModels.isEmpty ? [DecisionModel.ooda] : DecisionModel.allCases.filter { storedDecisionModels.contains($0) }

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
        selectedDecisionModels = resolvedDecisionModels
        operatorFeedback = storedOperatorFeedback
        isRecordingMission = false
        voiceLoopEnabled = storedVoiceLoopEnabled
        isAgentSpeaking = false
        recordingStatusMessage = "Ready to capture the mission from audio."
        voiceAnalysisSummary = ""
        externalDialogText = "Ready to speak to the operator."
        internalDialogText = "Internal guided-loop narration will appear here."
        awaitingActionConfirmation = false
        isAccessibilityGranted = SystemPermissionPrompter.isAccessibilityGranted()
        isScreenRecordingGranted = SystemPermissionPrompter.isScreenRecordingGranted()
        automationStatusMessage = "Checking automation capabilities."
        maxIterations = storedMaxIterations == 0 ? 5 : min(storedMaxIterations, 12)
        currentIteration = 0
        objectiveProgress = 0.18

        let starterDecisionProfile = DecisionProfile.make(from: resolvedDecisionModels)
        let starterSections = Self.placeholderSections(for: starterDecisionProfile)
        let starterActions = Self.placeholderActions(for: starterDecisionProfile)

        sections = starterSections
        actionQueue = starterActions
        cycles = [
            NavigationCycle(
                iteration: 0,
                createdAt: .now,
                mission: storedMissionText,
                environment: storedEnvironmentText,
                summary: "Initial shell configured. Ready to generate the first \(starterDecisionProfile.title) cycle with ChatGPT.",
                model: "Planning Shell",
                progress: 0.18,
                objectiveMet: false,
                isBlocked: false,
                blocker: nil,
                sections: starterSections,
                actions: starterActions
            )
        ]
        statusMessage = "Ready to plan with \(starterDecisionProfile.selectedModelLine)."
        selectedCycleID = cycles.first?.id
        refreshAutomationStatusMessage()
    }

    var selectedCycle: NavigationCycle? {
        cycles.first(where: { $0.id == selectedCycleID })
    }

    var canRunLoop: Bool {
        !missionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && status != .running && loopTask == nil && !awaitingActionConfirmation
    }

    var activeDecisionProfile: DecisionProfile {
        DecisionProfile.make(from: selectedDecisionModels)
    }

    var isGuidedLoopRunning: Bool {
        status == .running || loopTask != nil || awaitingActionConfirmation
    }

    var isVoiceLoopActive: Bool {
        voiceLoopEnabled || isGuidedLoopRunning
    }

    var actionGraphSnapshot: ActionGraphSnapshot {
        let loopNode = ActionGraphNode(
            id: "loop-\(currentIteration)",
            title: currentIteration == 0 ? "Navigator Standby" : "Cycle \(currentIteration)",
            subtitle: status.title,
            kind: .loop,
            emphasis: max(objectiveProgress, 0.25)
        )

        let phaseNodes = sections.map { section in
            ActionGraphNode(
                id: "phase-\(section.phase.rawValue)",
                title: section.stageTitle,
                subtitle: section.headline.isEmpty ? section.stagePrompt : section.headline,
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

        if let actNode = phaseNodes.first(where: { $0.id == "phase-\(NavigationPhase.act.rawValue)" }) {
            edges.append(contentsOf: actionNodes.map { node in
                ActionGraphEdge(
                    id: "\(actNode.id)-\(node.id)",
                    fromID: actNode.id,
                    toID: node.id,
                    weight: node.emphasis
                )
            })
        }

        for pair in zip(phaseNodes, phaseNodes.dropFirst()) {
            edges.append(
                ActionGraphEdge(
                    id: "\(pair.0.id)-\(pair.1.id)",
                    fromID: pair.0.id,
                    toID: pair.1.id,
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

            await MainActor.run {
                self.refreshPermissionStatuses()
            }
        }
    }

    func refreshPermissionStatuses() {
        isAccessibilityGranted = SystemPermissionPrompter.isAccessibilityGranted()
        isScreenRecordingGranted = SystemPermissionPrompter.isScreenRecordingGranted()
        refreshAutomationStatusMessage()
    }

    func requestAccessibilityPermission() {
        refreshPermissionStatuses()
        SystemPermissionPrompter.triggerAccessibilityPromptIfNeeded()
        statusMessage = "Accessibility prompt requested. Approve xmaxx in System Settings if macOS does not show a dialog."

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 400_000_000)
            self.refreshPermissionStatuses()
        }
    }

    func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }

        NSWorkspace.shared.open(url)
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
            statusMessage = "Add your ChatGPT API key in settings to start the guided loop."
            return
        }

        status = .idle
        statusMessage = "Ready. Start the \(activeDecisionProfile.title) voice loop when you want to begin."
        recordingStatusMessage = missionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Ready. Start the voice loop to capture the mission."
            : "Mission ready. Start the guided voice loop to run it with live steering."
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

    func toggleDecisionModel(_ model: DecisionModel) {
        var updatedModels = selectedDecisionModels

        if updatedModels.contains(model) {
            guard updatedModels.count > 1 else { return }
            updatedModels.removeAll { $0 == model }
        } else {
            updatedModels.append(model)
        }

        selectedDecisionModels = DecisionModel.allCases.filter { updatedModels.contains($0) }
        persistWorkspaceDraft()
        refreshDecisionModelScaffoldIfNeeded()
    }

    func persistWorkspaceDraft() {
        userDefaults.set(missionText, forKey: missionTextKey)
        userDefaults.set(environmentText, forKey: environmentTextKey)
        userDefaults.set(operatorFeedback, forKey: operatorFeedbackKey)
        userDefaults.set(maxIterations, forKey: maxIterationsKey)
        userDefaults.set(voiceLoopEnabled, forKey: voiceLoopEnabledKey)
        userDefaults.set(selectedDecisionModels.map(\.rawValue), forKey: selectedDecisionModelsKey)
    }

    func selectCycle(_ cycle: NavigationCycle) {
        selectedCycleID = cycle.id
        sections = cycle.sections
        actionQueue = cycle.actions
        objectiveProgress = cycle.progress
        currentIteration = cycle.iteration
        status = cycle.objectiveMet ? .completed : (cycle.isBlocked ? .blocked : .ready)
        statusMessage = cycle.summary
    }

    private func refreshDecisionModelScaffoldIfNeeded() {
        let profile = activeDecisionProfile

        if status == .running || loopTask != nil {
            statusMessage = "Decision model updated. The next cycle will use \(profile.selectedModelLine)."
            return
        }

        statusMessage = "Decision model set to \(profile.selectedModelLine)."

        guard currentIteration == 0 else { return }

        let placeholderSections = Self.placeholderSections(for: profile)
        let placeholderActions = Self.placeholderActions(for: profile)

        sections = placeholderSections
        actionQueue = placeholderActions

        if let firstCycle = cycles.first, firstCycle.iteration == 0 {
            cycles[0] = NavigationCycle(
                iteration: 0,
                createdAt: firstCycle.createdAt,
                mission: missionText,
                environment: environmentText,
                summary: "Planning shell updated for \(profile.selectedModelLine).",
                model: firstCycle.model,
                progress: objectiveProgress,
                objectiveMet: false,
                isBlocked: false,
                blocker: nil,
                sections: placeholderSections,
                actions: placeholderActions
            )
            selectedCycleID = cycles[0].id
        }
    }

    func runNavigationLoop(
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
            statusMessage = "Add a mission before running the guided loop."
            scheduleMissionListeningRestartIfNeeded()
            return
        }

        guard !chatGPTAPIKey.isEmpty else {
            status = .awaitingAPIKey
            statusMessage = "Add your ChatGPT API key in settings to generate a guided cycle."
            scheduleMissionListeningRestartIfNeeded()
            return
        }

        status = .running
        statusMessage = "Starting \(activeDecisionProfile.title) navigator."
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

    private func refreshAutomationStatusMessage() {
        let accessibilityStatus = isAccessibilityGranted ? "Accessibility is granted." : "Accessibility is missing."
        let screenStatus = isScreenRecordingGranted ? "Screen Recording is granted." : "Screen Recording is missing."

        automationStatusMessage = """
        \(accessibilityStatus) \(screenStatus) Mouse automation only works after Accessibility approval. Screen-based coordinate finding only works after Screen Recording approval.
        """
    }

    private func noteAutomationStatus(_ message: String) {
        automationStatusMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func runtimeCapabilitySummary() -> String {
        refreshPermissionStatuses()
        let accessibilityStatus = isAccessibilityGranted ? "granted" : "missing"
        let screenRecordingStatus = isScreenRecordingGranted ? "granted" : "missing"
        let pyannoteStatus = pyannoteAPIKey.isEmpty ? "disabled" : "enabled"

        return """
        Runtime capability status:
        - Real automation executor available for coordinate-based mouse_move, mouse_click, and mouse_right_click.
        - Screen coordinate resolver available through find_screen_text. It captures a fresh screenshot, runs OCR, and maps visible text to screen coordinates.
        - Mouse automation uses native HID mouse events from this app and depends on Accessibility permission. Current Accessibility status: \(accessibilityStatus).
        - Screen Recording permission status: \(screenRecordingStatus).
        - Screenshot-based coordinate finding depends on Screen Recording approval. Without it, the resolver cannot inspect the desktop.
        - Live operator steering by voice is available while the loop is running.
        - pyannote speaker analysis is \(pyannoteStatus).
        """
    }

    func stopLoop() {
        let wasAwaitingActionConfirmation = awaitingActionConfirmation
        resolvePendingActionApproval(with: .revise)
        loopTask?.cancel()
        loopTask = nil

        if status == .running || wasAwaitingActionConfirmation {
            status = .stopped
            statusMessage = "Loop stopped by operator."
            deliverDialogue(
                external: "Stopping now.",
                internal: "Loop stopped by operator."
            )
            scheduleMissionListeningRestartIfNeeded()
        }
    }

    func toggleGuidedVoiceLoop() {
        if isVoiceLoopActive {
            stopGuidedVoiceLoop()
        } else {
            startGuidedVoiceLoop()
        }
    }

    func startGuidedVoiceLoop() {
        startMissionRecording()

        guard !chatGPTAPIKey.isEmpty else {
            status = .awaitingAPIKey
            statusMessage = "Add your ChatGPT API key in settings to start the guided loop."
            return
        }

        guard !missionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            status = .idle
            statusMessage = "Listening for the first mission. Pause after speaking to start x-maxx."
            return
        }

        guard !isGuidedLoopRunning else { return }
        runNavigationLoop(preserveVoiceLoop: true)
    }

    func stopGuidedVoiceLoop() {
        if isGuidedLoopRunning {
            stopLoop()
        }

        stopMissionRecording()
    }

    func toggleMissionRecording() {
        toggleGuidedVoiceLoop()
    }

    func startMissionRecording() {
        voiceLoopEnabled = true
        persistWorkspaceDraft()
        beginMissionListening()
    }

    func confirmPendingActions() {
        guard awaitingActionConfirmation else { return }
        resolvePendingActionApproval(with: .confirm)
        status = .running
        statusMessage = "Action confirmation received. Executing approved actions."
        recordingStatusMessage = "Action confirmation received. Executing approved actions."
    }

    private func beginMissionListening() {
        guard voiceLoopEnabled else { return }
        listeningRestartTask?.cancel()

        if isRecordingMission {
            guard !isAgentSpeaking else { return }
            missionTranscriber.resumeSegmentDelivery()
            recordingStatusMessage = status == .running
                ? "Guided loop running. Mic is active for steering. Pause to inject guidance."
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
                    recordingStatusMessage = "Guided loop running. Mic is active for steering. Pause to inject guidance."
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
        recordingStatusMessage = trimmedMission.isEmpty
            ? "Ready. Start the voice loop to capture the mission."
            : "Voice loop stopped. The current mission stays loaded."
    }

    private func pauseMissionRecordingForProcessing() {
        if voiceLoopEnabled {
            recordingStatusMessage = status == .running
                ? "Guided loop running. Mic is active for steering. Pause to inject guidance."
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
        runNavigationLoop(
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

        if awaitingActionConfirmation && isActionConfirmationCommand(normalized) {
            recordingStatusMessage = "Voice confirmation received. Executing approved actions."
            capture.deleteTemporaryAudioFileIfNeeded()
            confirmPendingActions()
            return
        }

        operatorFeedback = appendOperatorFeedbackEntry(trimmedTranscript, to: baseOperatorFeedback)
        persistWorkspaceDraft()
        recordingStatusMessage = "Steering captured immediately and appended to the active context."
        startBackgroundVoiceAnalysis(capture, analysisPurpose: "steering")

        if awaitingActionConfirmation {
            statusMessage = "New steering received. Replanning before any action executes."
            resolvePendingActionApproval(with: .revise)
            return
        }

        if loopTask != nil {
            restartLoopPlanningWithLatestContext()
        }
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

    private func requiresActionConfirmation(for actions: [ActionItem]) -> Bool {
        actions.contains { action in
            action.status == .ready && isExecutableActionTool(action.tool)
        }
    }

    private func isExecutableActionTool(_ tool: String) -> Bool {
        let normalizedTool = tool.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return normalizedTool == "mouse_move" || normalizedTool == "mouse_click" || normalizedTool == "mouse_right_click"
    }

    private func waitForPendingActionApproval() async -> ActionApprovalDecision {
        await withCheckedContinuation { continuation in
            actionApprovalContinuation = continuation
        }
    }

    private func resolvePendingActionApproval(with decision: ActionApprovalDecision) {
        awaitingActionConfirmation = false
        let continuation = actionApprovalContinuation
        actionApprovalContinuation = nil
        continuation?.resume(returning: decision)
    }

    private func isActionConfirmationCommand(_ normalizedTranscript: String) -> Bool {
        let phrases = [
            "confirm action",
            "confirm actions",
            "approve action",
            "approve actions",
            "go ahead",
            "proceed",
            "continue",
            "yes do it",
            "yes proceed",
            "run the action",
            "execute the action",
            "execute actions"
        ]

        return phrases.contains { normalizedTranscript.contains($0) }
    }

    private func restartLoopPlanningWithLatestContext() {
        guard loopTask != nil else { return }

        let preservedVoiceContext = liveVoiceLoopContext
        loopTask?.cancel()
        loopTask = nil
        status = .running
        statusMessage = "Restarting planning with updated operator guidance."
        runNavigationLoop(
            preserveVoiceLoop: true,
            supplementalEnvironment: preservedVoiceContext
        )
    }

    private func runLoopSession(
        mission: String,
        environment: String,
        operatorFeedback: String
    ) async throws {
        var history: [NavigationCycle] = []
        let limit = min(max(maxIterations, 1), 12)
        var iteration = 1

        while iteration <= limit {
            try Task.checkCancellation()

            currentIteration = iteration
            status = .running
            statusMessage = "Cycle \(iteration) of \(limit): observing, acting, and guiding."
            let liveEnvironment = composeEnvironment(
                base: environment,
                supplemental: composeEnvironment(
                    base: liveVoiceLoopContext,
                    supplemental: runtimeCapabilitySummary()
                )
            )
            let liveOperatorFeedback = self.operatorFeedback
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let decisionProfile = self.activeDecisionProfile

            let result = try await client.generateNavigationLoop(
                apiKey: chatGPTAPIKey,
                profileName: profileName,
                mission: mission,
                environment: liveEnvironment,
                operatorFeedback: liveOperatorFeedback.isEmpty ? operatorFeedback : liveOperatorFeedback,
                iteration: iteration,
                maxIterations: limit,
                priorCycles: history,
                decisionProfile: decisionProfile
            )

            sections = result.sections
            actionQueue = result.actions
            objectiveProgress = result.progress

            if !result.objectiveMet && !result.isBlocked && requiresActionConfirmation(for: result.actions) {
                awaitingActionConfirmation = true
                status = .ready
                statusMessage = "Plan ready. Say 'confirm action' to execute or keep talking to revise."
                externalDialogText = "Plan ready. Say confirm action to execute, or keep talking to revise."
                internalDialogText = "Waiting for action confirmation on cycle \(iteration). Fresh operator speech will revise the plan before any action executes."

                switch await waitForPendingActionApproval() {
                case .revise:
                    try Task.checkCancellation()
                    status = .running
                    statusMessage = "Replanning with updated operator guidance."
                    continue
                case .confirm:
                    try Task.checkCancellation()
                    status = .running
                    statusMessage = "Action confirmation received. Executing approved actions."
                }
            }

            let executedActions = await executeActions(result.actions)
            let runtimeBlocker = executedActions
                .first(where: { $0.status == .blocked })?
                .output?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let cycleSummary: String
            if let runtimeBlocker, !runtimeBlocker.isEmpty {
                cycleSummary = "\(result.summary) Runtime result: \(runtimeBlocker)"
            } else {
                cycleSummary = result.summary
            }
            let cycle = NavigationCycle(
                iteration: iteration,
                createdAt: .now,
                mission: mission,
                environment: liveEnvironment,
                summary: cycleSummary,
                model: result.model,
                progress: result.progress,
                objectiveMet: result.objectiveMet,
                isBlocked: result.isBlocked || !(runtimeBlocker ?? "").isEmpty,
                blocker: runtimeBlocker ?? result.blocker,
                sections: result.sections,
                actions: executedActions
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
                    internal: "Cycle \(cycle.iteration) completed the mission with progress at \(Int(cycle.progress * 100)) percent."
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
                    internal: "Guided loop blocked on cycle \(cycle.iteration). Reason: \(cycle.blocker ?? cycle.summary)"
                )
                loopTask = nil
                scheduleMissionListeningRestartIfNeeded()
                return
            }

            if iteration == limit {
                status = .stopped
                statusMessage = "Reached iteration limit without meeting the objective."
                deliverDialogue(
                    external: "I ran out of guided cycles before reaching the objective.",
                    internal: "Guided-loop budget exhausted at \(limit) cycles with progress at \(Int(cycle.progress * 100)) percent."
                )
                loopTask = nil
                scheduleMissionListeningRestartIfNeeded()
                return
            }

            iteration += 1
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
                self.recordingStatusMessage = "Guided loop running. Mic is active for steering. Pause to inject guidance."
            } else {
                self.recordingStatusMessage = "Listening continuously. Pause to start x-maxx."
            }
        }
    }

    private func executeActions(_ actions: [ActionItem]) async -> [ActionItem] {
        var updatedActions = actions
        var resolvedTargets: [String: CGPoint] = [:]

        for index in updatedActions.indices {
            let normalizedTool = updatedActions[index].tool
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()

            guard updatedActions[index].status == .ready else { continue }

            switch normalizedTool {
            case "find_screen_text":
                do {
                    let match = try await screenCoordinateResolver.findCoordinates(for: updatedActions[index].target)
                    updatedActions[index].x = match.x
                    updatedActions[index].y = match.y
                    updatedActions[index].status = .done
                    updatedActions[index].output = "Found \"\(match.matchedText)\" at (\(String(format: "%.1f", match.x)), \(String(format: "%.1f", match.y))) with \(Int(match.confidence * 100))% confidence."
                    resolvedTargets[coordinateCacheKey(for: updatedActions[index].target)] = CGPoint(x: match.x, y: match.y)
                    noteAutomationStatus("Screen resolver found \"\(match.matchedText)\" at (\(String(format: "%.1f", match.x)), \(String(format: "%.1f", match.y))).")
                } catch {
                    updatedActions[index].status = .blocked
                    updatedActions[index].output = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                    noteAutomationStatus(updatedActions[index].output ?? "Screen coordinate resolution failed.")
                }

            case "mouse_move", "mouse_click", "mouse_right_click":
                guard SystemPermissionPrompter.isAccessibilityGranted() else {
                    updatedActions[index].status = .blocked
                    updatedActions[index].output = "Mouse automation requires Accessibility permission in System Settings > Privacy & Security > Accessibility."
                    noteAutomationStatus(updatedActions[index].output ?? "Accessibility permission is missing.")
                    continue
                }

                let resolvedPoint: CGPoint
                if let x = updatedActions[index].x, let y = updatedActions[index].y {
                    resolvedPoint = CGPoint(x: x, y: y)
                } else if let cachedPoint = resolvedTargets[coordinateCacheKey(for: updatedActions[index].target)] {
                    resolvedPoint = cachedPoint
                    updatedActions[index].x = cachedPoint.x
                    updatedActions[index].y = cachedPoint.y
                } else {
                    let trimmedTarget = updatedActions[index].target.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmedTarget.isEmpty else {
                        updatedActions[index].status = .blocked
                        updatedActions[index].output = "Missing screen coordinates for \(updatedActions[index].tool), and no visible-text target was provided for screenshot lookup."
                        noteAutomationStatus(updatedActions[index].output ?? "Missing screen coordinates.")
                        continue
                    }

                    do {
                        let match = try await screenCoordinateResolver.findCoordinates(for: trimmedTarget)
                        resolvedPoint = CGPoint(x: match.x, y: match.y)
                        updatedActions[index].x = match.x
                        updatedActions[index].y = match.y
                        resolvedTargets[coordinateCacheKey(for: trimmedTarget)] = resolvedPoint
                        noteAutomationStatus("Resolved \"\(match.matchedText)\" to (\(String(format: "%.1f", match.x)), \(String(format: "%.1f", match.y))) before \(updatedActions[index].tool).")
                    } catch {
                        updatedActions[index].status = .blocked
                        updatedActions[index].output = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                        noteAutomationStatus(updatedActions[index].output ?? "Screen coordinate resolution failed.")
                        continue
                    }
                }

                do {
                    let result = try await mouseExecutor.execute(tool: normalizedTool, x: resolvedPoint.x, y: resolvedPoint.y)
                    updatedActions[index].status = .done
                    updatedActions[index].output = result
                    noteAutomationStatus(result)
                } catch {
                    updatedActions[index].status = .blocked
                    updatedActions[index].output = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                    noteAutomationStatus(updatedActions[index].output ?? "Mouse automation failed.")
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

    private func coordinateCacheKey(for target: String) -> String {
        target
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }
}

private extension NavigationCycle {
    var externalDialogue: String {
        let actionTitles = actions.prefix(2).map(\.title).joined(separator: ", ")

        guard !actionTitles.isEmpty else {
            return "Cycle \(iteration). \(summary)"
        }

        return "Cycle \(iteration). \(summary) Next I will handle \(actionTitles)."
    }

    var internalDialogue: String {
        let openingStage = sections.first(where: { $0.phase == .observe })
        let closingStage = sections.first(where: { $0.phase == .guide })
        let openingTitle = openingStage?.stageTitle ?? "Opening"
        let openingHeadline = openingStage?.headline ?? "Unavailable"
        let closingTitle = closingStage?.stageTitle ?? "Closing"
        let closingHeadline = closingStage?.headline ?? "Unavailable"
        let actionTools = actions.prefix(3).map { "\($0.tool) on \($0.target)" }.joined(separator: "; ")

        if actionTools.isEmpty {
            return "Cycle \(iteration). \(openingTitle): \(openingHeadline). \(closingTitle): \(closingHeadline). No executable actions were attached."
        }

        return "Cycle \(iteration). \(openingTitle): \(openingHeadline). \(closingTitle): \(closingHeadline). Planned actions: \(actionTools). Progress is \(Int(progress * 100)) percent."
    }
}

extension AppStore {
    static func placeholderSections(for profile: DecisionProfile) -> [NavigationSection] {
        profile.stages.map { stage in
            let content: (headline: String, narrative: String, bullets: [String], confidence: Double)

            switch stage.phase {
            case .observe:
                content = (
                    headline: "Capture the current machine state",
                    narrative: "Pull in the latest screen context, operator intent, and system signals before overcommitting to a frame.",
                    bullets: [
                        "Read the current app, visible state, and recent changes.",
                        "Treat operator steering as the freshest source of intent.",
                        "Collect signal before story."
                    ],
                    confidence: 0.35
                )
            case .orient:
                content = (
                    headline: "Build a grounded frame",
                    narrative: "Interpret the raw signals into a working picture of constraints, likely causes, and the decision style that fits.",
                    bullets: [
                        "Explain what matters and why.",
                        "State uncertainty instead of hiding it.",
                        "Choose the right mental frame for this cycle."
                    ],
                    confidence: 0.40
                )
            case .decide:
                content = (
                    headline: "Select the next move",
                    narrative: "Choose the smallest move that best advances the mission under the active decision model.",
                    bullets: [
                        "Prefer inspectable moves over vague plans.",
                        "Say why this move beats the nearby alternatives.",
                        "Keep the decision steerable."
                    ],
                    confidence: 0.38
                )
            case .act:
                content = (
                    headline: "Translate intent into commands",
                    narrative: "Convert the decision into executable actions, operator-facing CLI commands, or concrete automation steps.",
                    bullets: [
                        "Produce specific tool calls or shell commands.",
                        "Make the next action runnable, not abstract.",
                        "Log the actual result, not the intended one."
                    ],
                    confidence: 0.36
                )
            case .guide:
                content = (
                    headline: "Update the next cycle",
                    narrative: "Measure whether the last move helped, then revise the next frame, belief, or control strategy accordingly.",
                    bullets: [
                        "State what changed after the action.",
                        "Measure progress, error, or reward clearly.",
                        "Feed the update into the next cycle."
                    ],
                    confidence: 0.34
                )
            }

            return NavigationSection(
                phase: stage.phase,
                stageTitle: stage.title,
                stagePrompt: stage.shortLabel,
                headline: content.headline,
                narrative: content.narrative,
                bullets: content.bullets,
                confidence: content.confidence
            )
        }
    }

    static func placeholderActions(for profile: DecisionProfile) -> [ActionItem] {
        [
            ActionItem(
                title: "Synthesize \(profile.title) loop output",
                tool: "Responses API",
                target: profile.selectedModelLine,
                rationale: "Turn mission and environment text into a decision-model-specific JSON cycle.",
                status: .done
            ),
            ActionItem(
                title: "Return operator-ready CLI suggestions",
                tool: "shell_command",
                target: "echo \"replace with the next concrete command\"",
                rationale: "The act stage should be able to emit exact CLI commands even when the app is not executing them directly yet.",
                status: .queued
            ),
            ActionItem(
                title: "Measure update quality",
                tool: "Automation bridge",
                target: profile.stages.last?.title ?? "Update stage",
                rationale: "The final stage should score whether the chosen model actually reduced distance to the goal.",
                status: .queued
            )
        ]
    }
}

private struct GeneratedLoop {
    let model: String
    let summary: String
    let progress: Double
    let objectiveMet: Bool
    let isBlocked: Bool
    let blocker: String?
    let sections: [NavigationSection]
    let actions: [ActionItem]
}

private struct OpenAIClient {
    private let session = URLSession.shared
    private let model = "gpt-4.1-mini"

    func generateNavigationLoop(
        apiKey: String,
        profileName: String,
        mission: String,
        environment: String,
        operatorFeedback: String,
        iteration: Int,
        maxIterations: Int,
        priorCycles: [NavigationCycle],
        decisionProfile: DecisionProfile
    ) async throws -> GeneratedLoop {
        guard let url = URL(string: "https://api.openai.com/v1/responses") else {
            throw OpenAIClientError.invalidRequest
        }

        let stagePrompt = decisionProfile.stages.map { stage in
            "- \(stage.phase.rawValue) => \(stage.title): \(stage.shortLabel) \(stage.instruction)"
        }.joined(separator: "\n")

        let systemPrompt = """
        You are driving an autonomous x-maxx guided loop for a desktop computer-use copilot.
        Return JSON only.
        Use grounded reasoning. If information is missing, say that directly instead of inventing facts.
        Goal: maximize progress toward objective x, where x is the user's mission.
        The guided cycle should continue until the objective is met, the agent is blocked, or the iteration budget is exhausted.
        Treat operator feedback as live steering from the human. If it changes priorities, constraints, or desired direction, adapt immediately in the next iteration instead of continuing the old plan.
        Keep the loop steerable: prefer small, reversible next moves over long speculative plans when live steering is present.
        If the mission or latest steering is ambiguous, say exactly what clarification is needed.
        Active decision model surface: \(decisionProfile.title).
        Selected model lenses: \(decisionProfile.selectedModelLine).
        \(decisionProfile.promptContext)
        Structure the reasoning around these five internal JSON keys for this run:
        \(stagePrompt)

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
          "guide": { "headline": "string", "narrative": "string", "bullets": ["string"], "confidence": 0.0 },
          "actions": [
            { "title": "string", "tool": "string", "target": "string", "rationale": "string", "status": "queued|ready|blocked|done", "x": 0.0, "y": 0.0 }
          ]
        }

        Keep bullets concise. Prefer 2 to 4 bullets per section and 3 to 6 actions total.
        Set "objective_met" true only when the objective is actually achieved within the known context.
        Set "blocked" true only when the next step cannot proceed without missing tooling, permissions, or new human input.
        "progress" must be a number from 0.0 to 1.0 showing estimated distance closed toward the mission.
        Available executable tools right now are mouse_move, mouse_click, mouse_right_click, and find_screen_text.
        You may also return shell_command as a planning-only action. When you use shell_command, put the exact CLI command string in target and prefer queued status because the current macOS build does not auto-execute shell commands yet.
        find_screen_text captures a fresh screenshot, OCRs visible text, and returns the center coordinates of matching visible text.
        When you choose mouse_move, mouse_click, or mouse_right_click, include absolute screen coordinates in x and y when they are known.
        If exact coordinates are not known but the click target is visible text on screen, you may omit x and y and set target to the exact text so the runtime can resolve coordinates from a fresh screenshot.
        A real automation executor exists for those mouse tools. Do not claim automation is unavailable when coordinates or searchable visible text and Accessibility permission are available.
        Only mark the loop blocked for automation when coordinates are missing, Accessibility permission is missing, or a real tool execution error occurs.
        Treat prior action outputs as ground truth. Do not repeat the same blocked action with the same target unless the new cycle explains what changed.
        """

        let operatorName = profileName.isEmpty ? "Operator" : profileName
        let historySummary = priorCycles.isEmpty ? "No prior cycles yet." : priorCycles.suffix(6).map { cycle in
            let blockerText = cycle.blocker ?? "none"
            let actionSummaries = cycle.actions.map { action in
                let output = action.output?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "no runtime output"
                let coordinates = if let x = action.x, let y = action.y {
                    "@ (\(String(format: "%.1f", x)), \(String(format: "%.1f", y)))"
                } else {
                    "@ unresolved"
                }

                return "\(action.title) [\(action.tool) \(coordinates)] status=\(action.status.rawValue); target=\(action.target); output=\(output)"
            }.joined(separator: "\n")
            return """
            Cycle \(cycle.iteration)
            Summary: \(cycle.summary)
            Progress: \(Int(cycle.progress * 100))%
            Objective Met: \(cycle.objectiveMet)
            Blocked: \(cycle.isBlocked)
            Blocker: \(blockerText)
            Actions:
            \(actionSummaries)
            """
        }.joined(separator: "\n\n")
        let userPrompt = """
        Profile: \(operatorName)
        Cycle: \(iteration) of \(maxIterations)
        Mission:
        \(mission)

        Environment:
        \(environment)

        Operator feedback:
        \(operatorFeedback.isEmpty ? "None." : operatorFeedback)

        Prior cycles:
        \(historySummary)

        Produce the next guided cycle for this app. This is a macOS desktop copilot dashboard. It can plan through ChatGPT, it has a limited real automation executor for coordinate-based mouse actions, and it can resolve coordinates from screenshots when the target is visible text and Screen Recording permission is granted. Make the output useful, specific, and honest about gaps. Push the loop forward instead of repeating generic advice. Assume operator feedback may have arrived while the cycle was already running, and give it priority over stale earlier plans.
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
                loopResponse.observe.makeSection(using: decisionProfile.stage(for: .observe)),
                loopResponse.orient.makeSection(using: decisionProfile.stage(for: .orient)),
                loopResponse.decide.makeSection(using: decisionProfile.stage(for: .decide)),
                loopResponse.act.makeSection(using: decisionProfile.stage(for: .act)),
                loopResponse.guide.makeSection(using: decisionProfile.stage(for: .guide))
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

private struct ScreenCoordinateMatch {
    let query: String
    let matchedText: String
    let x: Double
    let y: Double
    let confidence: Double
}

private enum ScreenCoordinateResolutionError: LocalizedError {
    case missingTarget
    case screenRecordingPermissionMissing
    case screenshotUnavailable
    case noTextRecognized
    case targetNotFound(String)
    case visionFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingTarget:
            return "Screen coordinate lookup needs a visible-text target."
        case .screenRecordingPermissionMissing:
            return "Screen coordinate lookup requires Screen Recording permission in System Settings > Privacy & Security > Screen Recording."
        case .screenshotUnavailable:
            return "The app could not capture the current screen."
        case .noTextRecognized:
            return "The screenshot was captured, but OCR did not find readable text."
        case let .targetNotFound(target):
            return "Could not find visible text matching \"\(target)\" on the current screen."
        case let .visionFailed(message):
            return message
        }
    }
}

private actor ScreenCoordinateResolver {
    private struct RecognizedTextCandidate {
        let text: String
        let normalizedText: String
        let bounds: CGRect
        let confidence: Double
    }

    private struct ScoredMatch {
        let match: ScreenCoordinateMatch
        let score: Double
    }

    func findCoordinates(for target: String) async throws -> ScreenCoordinateMatch {
        let trimmedTarget = target.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTarget.isEmpty else {
            throw ScreenCoordinateResolutionError.missingTarget
        }

        guard SystemPermissionPrompter.isScreenRecordingGranted() else {
            throw ScreenCoordinateResolutionError.screenRecordingPermissionMissing
        }

        let captures = try await captureDisplayImages()
        var sawRecognizedText = false
        var bestResolvedMatch: ScoredMatch?

        for (screenshot, captureRect) in captures {
            let candidates = try recognizeVisibleText(in: screenshot)
            guard !candidates.isEmpty else { continue }
            sawRecognizedText = true

            guard let candidateMatch = bestMatch(for: trimmedTarget, in: candidates, captureRect: captureRect) else {
                continue
            }

            if let existingBestMatch = bestResolvedMatch {
                if candidateMatch.score > existingBestMatch.score {
                    bestResolvedMatch = candidateMatch
                }
            } else {
                bestResolvedMatch = candidateMatch
            }
        }

        guard sawRecognizedText else {
            throw ScreenCoordinateResolutionError.noTextRecognized
        }

        guard let bestResolvedMatch else {
            throw ScreenCoordinateResolutionError.targetNotFound(trimmedTarget)
        }

        return bestResolvedMatch.match
    }

    private func recognizeVisibleText(in screenshot: CGImage) throws -> [RecognizedTextCandidate] {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.minimumTextHeight = 0.012

        let handler = VNImageRequestHandler(cgImage: screenshot, options: [:])

        do {
            try handler.perform([request])
        } catch {
            throw ScreenCoordinateResolutionError.visionFailed(error.localizedDescription)
        }

        let observations = request.results ?? []
        return observations.compactMap { observation in
            guard let candidate = observation.topCandidates(1).first else {
                return nil
            }

            let text = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else {
                return nil
            }

            let normalizedText = normalize(text)
            guard !normalizedText.isEmpty else {
                return nil
            }

            return RecognizedTextCandidate(
                text: text,
                normalizedText: normalizedText,
                bounds: observation.boundingBox,
                confidence: Double(candidate.confidence)
            )
        }
    }

    private func bestMatch(
        for target: String,
        in candidates: [RecognizedTextCandidate],
        captureRect: CGRect
    ) -> ScoredMatch? {
        let normalizedTarget = normalize(target)
        let targetTokens = Set(normalizedTarget.split(separator: " ").map(String.init))
        guard !normalizedTarget.isEmpty else { return nil }

        let bestCandidate = candidates
            .map { candidate -> (RecognizedTextCandidate, Double) in
                let score = scoreMatch(
                    target: normalizedTarget,
                    targetTokens: targetTokens,
                    candidate: candidate.normalizedText,
                    rawConfidence: candidate.confidence
                )
                return (candidate, score)
            }
            .max { lhs, rhs in lhs.1 < rhs.1 }

        guard let (candidate, score) = bestCandidate, score >= 0.45 else {
            return nil
        }

        let midX = captureRect.minX + (candidate.bounds.midX * captureRect.width)
        let midY = captureRect.minY + ((1 - candidate.bounds.midY) * captureRect.height)

        return ScoredMatch(
            match: ScreenCoordinateMatch(
                query: target,
                matchedText: candidate.text,
                x: midX,
                y: midY,
                confidence: min(max(score, 0), 1)
            ),
            score: score
        )
    }

    private func scoreMatch(
        target: String,
        targetTokens: Set<String>,
        candidate: String,
        rawConfidence: Double
    ) -> Double {
        if candidate == target {
            return 1.0
        }

        if candidate.contains(target) || target.contains(candidate) {
            return min(0.96, 0.78 + (rawConfidence * 0.18))
        }

        let candidateTokens = Set(candidate.split(separator: " ").map(String.init))
        let overlap = targetTokens.intersection(candidateTokens).count
        let tokenScore = targetTokens.isEmpty ? 0 : Double(overlap) / Double(targetTokens.count)
        let prefixBonus = candidate.hasPrefix(target) || target.hasPrefix(candidate) ? 0.12 : 0
        let confidenceBonus = rawConfidence * 0.12

        return min(0.95, tokenScore * 0.82 + prefixBonus + confidenceBonus)
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

    private func captureDisplayImages() async throws -> [(CGImage, CGRect)] {
        let shareableContent = try await currentShareableContent()
        let displays = shareableContent.displays.sorted { lhs, rhs in
            if lhs.displayID == CGMainDisplayID() {
                return true
            }

            if rhs.displayID == CGMainDisplayID() {
                return false
            }

            return lhs.frame.minX < rhs.frame.minX
        }

        guard !displays.isEmpty else {
            throw ScreenCoordinateResolutionError.screenshotUnavailable
        }

        var captures: [(CGImage, CGRect)] = []
        for display in displays {
            let rect = display.frame

            do {
                let image = try await captureImage(in: rect)
                captures.append((image, rect))
            } catch {
                continue
            }
        }

        guard !captures.isEmpty else {
            throw ScreenCoordinateResolutionError.screenshotUnavailable
        }

        return captures
    }

    private func currentShareableContent() async throws -> SCShareableContent {
        do {
            return try await SCShareableContent.current
        } catch {
            throw ScreenCoordinateResolutionError.visionFailed(error.localizedDescription)
        }
    }

    private func captureImage(in rect: CGRect) async throws -> CGImage {
        do {
            return try await SCScreenshotManager.captureImage(in: rect)
        } catch {
            throw ScreenCoordinateResolutionError.visionFailed(error.localizedDescription)
        }
    }
}

private actor NativeMouseExecutor {
    func execute(tool: String, x: Double, y: Double) async throws -> String {
        let location = CGPoint(x: x, y: y)

        switch tool {
        case "mouse_move":
            try postMouseEvent(type: .mouseMoved, position: location, button: .left)
        case "mouse_right_click":
            try postMouseEvent(type: .mouseMoved, position: location, button: .left)
            try await Task.sleep(nanoseconds: 50_000_000)
            try postMouseEvent(type: .rightMouseDown, position: location, button: .right)
            try postMouseEvent(type: .rightMouseUp, position: location, button: .right)
        default:
            try postMouseEvent(type: .mouseMoved, position: location, button: .left)
            try await Task.sleep(nanoseconds: 50_000_000)
            try postMouseEvent(type: .leftMouseDown, position: location, button: .left)
            try postMouseEvent(type: .leftMouseUp, position: location, button: .left)
        }

        return "\(tool) executed at (\(String(format: "%.1f", x)), \(String(format: "%.1f", y)))"
    }

    private func postMouseEvent(type: CGEventType, position: CGPoint, button: CGMouseButton) throws {
        guard let event = CGEvent(mouseEventSource: nil, mouseType: type, mouseCursorPosition: position, mouseButton: button) else {
            throw MouseExecutionError.eventCreationFailed
        }

        event.post(tap: .cghidEventTap)
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
    case eventCreationFailed
    case executionFailed(String)

    var errorDescription: String? {
        switch self {
        case .eventCreationFailed:
            return "The app could not create a native mouse event."
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
            return "ChatGPT returned no usable guided cycle."
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
    let guide: LoopSectionResponse
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
        case guide
        case actions
    }
}

private struct LoopSectionResponse: Decodable {
    let headline: String
    let narrative: String
    let bullets: [String]
    let confidence: Double

    func makeSection(using descriptor: DecisionStageDescriptor) -> NavigationSection {
        NavigationSection(
            phase: descriptor.phase,
            stageTitle: descriptor.title,
            stagePrompt: descriptor.shortLabel,
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
