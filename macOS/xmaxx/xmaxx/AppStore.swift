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

private enum OperatorPromptDecision {
    case proceed
    case revise
}

enum OperatorPromptKind: String, Hashable {
    case startupAssessment
    case actionApproval
    case checkpoint
    case question

    var blocksLoop: Bool {
        switch self {
        case .startupAssessment:
            return false
        case .actionApproval, .checkpoint, .question:
            return true
        }
    }
}

struct OperatorPrompt: Identifiable, Hashable {
    let id: UUID
    let kind: OperatorPromptKind
    let title: String
    let question: String
    let detail: String
    let proceedLabel: String
    let reviseLabel: String
    let responsePlaceholder: String
    let requiresResponse: Bool

    init(
        id: UUID = UUID(),
        kind: OperatorPromptKind,
        title: String,
        question: String,
        detail: String,
        proceedLabel: String,
        reviseLabel: String,
        responsePlaceholder: String = "",
        requiresResponse: Bool = false
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.question = question
        self.detail = detail
        self.proceedLabel = proceedLabel
        self.reviseLabel = reviseLabel
        self.responsePlaceholder = responsePlaceholder
        self.requiresResponse = requiresResponse
    }

    var acceptsResponse: Bool {
        requiresResponse || !responsePlaceholder.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

private struct OperatorPromptResult {
    let decision: OperatorPromptDecision
    let response: String
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

enum VoiceFlowState: String, Hashable {
    case idle
    case listening
    case captured
    case processing
    case speaking
    case error

    var title: String {
        switch self {
        case .idle:
            return "Idle"
        case .listening:
            return "Listening"
        case .captured:
            return "Captured"
        case .processing:
            return "Incorporating"
        case .speaking:
            return "Speaking"
        case .error:
            return "Error"
        }
    }
}

enum ConversationSpeaker: String, Hashable {
    case user
    case computer
    case system

    var title: String {
        switch self {
        case .user:
            return "You"
        case .computer:
            return "xmaxx"
        case .system:
            return "Session"
        }
    }
}

enum ConversationMessageState: String, Hashable {
    case live
    case captured
    case processing
    case delivered
    case noted

    var title: String {
        switch self {
        case .live:
            return "Listening"
        case .captured:
            return "Captured"
        case .processing:
            return "In Loop"
        case .delivered:
            return "Sent"
        case .noted:
            return "Session"
        }
    }
}

struct ConversationMessage: Identifiable, Hashable {
    let id: UUID
    let speaker: ConversationSpeaker
    let createdAt: Date
    var text: String
    var detail: String?
    var state: ConversationMessageState

    init(
        id: UUID = UUID(),
        speaker: ConversationSpeaker,
        createdAt: Date = .now,
        text: String,
        detail: String? = nil,
        state: ConversationMessageState
    ) {
        self.id = id
        self.speaker = speaker
        self.createdAt = createdAt
        self.text = text
        self.detail = detail
        self.state = state
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
    let operatorMessage: String?
    let internalMessage: String?
    let decisionNote: String?
    let sections: [NavigationSection]
    let actions: [ActionItem]

    init(
        iteration: Int,
        createdAt: Date,
        mission: String,
        environment: String,
        summary: String,
        model: String,
        progress: Double,
        objectiveMet: Bool,
        isBlocked: Bool,
        blocker: String?,
        operatorMessage: String? = nil,
        internalMessage: String? = nil,
        decisionNote: String? = nil,
        sections: [NavigationSection],
        actions: [ActionItem]
    ) {
        self.iteration = iteration
        self.createdAt = createdAt
        self.mission = mission
        self.environment = environment
        self.summary = summary
        self.model = model
        self.progress = progress
        self.objectiveMet = objectiveMet
        self.isBlocked = isBlocked
        self.blocker = blocker
        self.operatorMessage = operatorMessage
        self.internalMessage = internalMessage
        self.decisionNote = decisionNote
        self.sections = sections
        self.actions = actions
    }
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

private struct RecoverySnapshot: Codable {
    let mission: String
    let operatorFeedback: String
    let cycleCount: Int
    let lastCycleSummary: String
    let lastCycleProgress: Double
    let lastCycleTimestamp: Date
    let lastStatusTitle: String
    let voiceLoopEnabled: Bool

    var hasRecoverableState: Bool {
        cycleCount > 1 ||
        (
            voiceLoopEnabled &&
            (
                !mission.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                !operatorFeedback.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            )
        )
    }
}

struct LoadedSkill: Identifiable, Hashable {
    let fileURL: URL
    let title: String
    let summary: String
    let content: String

    var id: String { fileURL.path }
    var fileName: String { fileURL.lastPathComponent }
}

private struct SkillsDirectoryConfiguration {
    let directoryURL: URL
    let isDefault: Bool
    let statusMessage: String?
}

@MainActor
final class AppStore: ObservableObject {
    @Published var profileName: String
    @Published var chatGPTAPIKey: String
    @Published var elevenLabsAPIKey: String
    @Published var pyannoteAPIKey: String
    @Published var audioResponsesEnabled: Bool
    @Published var audioDialogueMode: AudioDialogueMode
    @Published private(set) var skillsDirectoryPath: String
    @Published private(set) var isUsingDefaultSkillsDirectory: Bool
    @Published private(set) var loadedSkills: [LoadedSkill]
    @Published private(set) var skillsStatusMessage: String
    @Published var selectedDecisionModels: [DecisionModel]
    @Published var missionText: String
    @Published var environmentText: String
    @Published var isRecordingMission: Bool
    @Published var voiceLoopEnabled: Bool
    @Published var isAgentSpeaking: Bool
    @Published var recordingStatusMessage: String
    @Published var voiceFlowState: VoiceFlowState
    @Published var voiceFlowTitle: String
    @Published var voiceFlowDetail: String
    @Published var voiceFlowTranscript: String
    @Published var voiceAnalysisSummary: String
    @Published var externalDialogText: String
    @Published var internalDialogText: String
    @Published var typedInstructionDraft: String
    @Published private(set) var pendingOperatorPrompt: OperatorPrompt?
    @Published var pendingOperatorResponseDraft: String
    @Published private(set) var awaitingOperatorInput: Bool
    @Published private(set) var sessionStartedAt: Date
    @Published private(set) var sessionNumber: Int
    @Published private(set) var conversationEntries: [ConversationMessage]
    @Published private(set) var awaitingActionConfirmation: Bool
    @Published private(set) var isAccessibilityGranted: Bool
    @Published private(set) var isScreenRecordingGranted: Bool
    @Published private(set) var isSpeechRecognitionGranted: Bool
    @Published private(set) var isMicrophoneGranted: Bool
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
    private let skillsDirectoryBookmarkKey = "skillsDirectoryBookmark"
    private let selectedDecisionModelsKey = "selectedDecisionModels"
    private let missionTextKey = "missionText"
    private let environmentTextKey = "environmentText"
    private let operatorFeedbackKey = "operatorFeedback"
    private let maxIterationsKey = "maxIterations"
    private let voiceLoopEnabledKey = "voiceLoopEnabled"
    private let recoverySnapshotKey = "recoverySnapshot"
    private let applicationSessionActiveKey = "applicationSessionActive"
    private var loopTask: Task<Void, Never>?
    private var listeningRestartTask: Task<Void, Never>?
    private var speakingTask: Task<Void, Never>?
    private var didTriggerPermissionProbes = false
    private var didAutoStart = false
    private var previousLaunchEndedUncleanly = false
    private var liveVoiceLoopContext = ""
    private var missionDraftBaseText: String?
    private var operatorFeedbackDraftBaseText: String?
    private var activeVoiceDraftMessageID: ConversationMessage.ID?
    private var startupRecoverySnapshot: RecoverySnapshot?
    private var operatorPromptContinuation: CheckedContinuation<OperatorPromptResult, Never>?
    private let speechCoordinator = SpeechCoordinator()
    private let missionTranscriber = MissionTranscriber()

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        let legacyDefaultMissionText = "Build a desktop computer-use copilot around a guided loop."
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
        let persistedMissionText = userDefaults.string(forKey: missionTextKey) ?? ""
        let storedMissionText = persistedMissionText.trimmingCharacters(in: .whitespacesAndNewlines) == legacyDefaultMissionText
            ? ""
            : persistedMissionText
        let storedApplicationSessionActive = userDefaults.object(forKey: applicationSessionActiveKey) as? Bool ?? false
        let storedRecoverySnapshot = Self.loadRecoverySnapshot(
            from: userDefaults,
            key: recoverySnapshotKey
        )
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
        let skillsDirectoryConfiguration = Self.resolveSkillsDirectoryConfiguration(
            from: userDefaults,
            bookmarkKey: skillsDirectoryBookmarkKey
        )
        var storedAPIKey = keychain.read(account: chatGPTAPIKeyKey) ?? ""
        var storedElevenLabsAPIKey = keychain.read(account: elevenLabsAPIKeyKey) ?? ""
        var storedPyannoteAPIKey = keychain.read(account: pyannoteAPIKeyKey) ?? ""
        let storedAudioResponsesEnabled = userDefaults.object(forKey: audioResponsesEnabledKey) as? Bool ?? false
        let storedAudioDialogueMode = AudioDialogueMode(rawValue: userDefaults.string(forKey: audioDialogueModeKey) ?? "") ?? .external
        let resolvedLoadedSkills = Self.loadSkills(from: skillsDirectoryConfiguration.directoryURL)
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
        skillsDirectoryPath = skillsDirectoryConfiguration.directoryURL.path
        isUsingDefaultSkillsDirectory = skillsDirectoryConfiguration.isDefault
        loadedSkills = resolvedLoadedSkills
        skillsStatusMessage = skillsDirectoryConfiguration.statusMessage ?? Self.makeSkillsStatusMessage(
            count: resolvedLoadedSkills.count,
            directoryURL: skillsDirectoryConfiguration.directoryURL,
            isDefault: skillsDirectoryConfiguration.isDefault
        )
        selectedDecisionModels = resolvedDecisionModels
        operatorFeedback = storedOperatorFeedback
        isRecordingMission = false
        voiceLoopEnabled = storedVoiceLoopEnabled
        isAgentSpeaking = false
        recordingStatusMessage = "Ready to capture the mission from audio."
        voiceFlowState = .idle
        voiceFlowTitle = "Voice loop idle"
        voiceFlowDetail = "Start the voice loop, speak naturally, and pause once to commit your text into the loop."
        voiceFlowTranscript = ""
        voiceAnalysisSummary = ""
        externalDialogText = "Ready to speak to the operator."
        internalDialogText = "Internal guided-loop narration will appear here."
        typedInstructionDraft = ""
        pendingOperatorPrompt = nil
        pendingOperatorResponseDraft = ""
        awaitingOperatorInput = false
        sessionStartedAt = .now
        sessionNumber = 1
        conversationEntries = []
        awaitingActionConfirmation = false
        isAccessibilityGranted = SystemPermissionPrompter.isAccessibilityGranted()
        isScreenRecordingGranted = SystemPermissionPrompter.isScreenRecordingGranted()
        isSpeechRecognitionGranted = SystemPermissionPrompter.isSpeechRecognitionGranted()
        isMicrophoneGranted = SystemPermissionPrompter.isMicrophoneGranted()
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
        conversationEntries = Self.bootstrapConversationEntries(
            mission: storedMissionText,
            operatorFeedback: storedOperatorFeedback
        )
        previousLaunchEndedUncleanly = storedApplicationSessionActive
        startupRecoverySnapshot = storedRecoverySnapshot
        refreshAutomationStatusMessage()
    }

    var selectedCycle: NavigationCycle? {
        cycles.first(where: { $0.id == selectedCycleID })
    }

    var sessionHeadline: String {
        if awaitingActionConfirmation {
            return "Awaiting approval"
        }

        if isGuidedLoopRunning {
            return "Session live"
        }

        if missionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            operatorFeedback.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            cycles.count <= 1 {
            return "New session ready"
        }

        return "Draft loaded"
    }

    var sessionDetail: String {
        if awaitingActionConfirmation {
            return "The latest plan is waiting for confirmation. Keep talking to revise it or approve the queued actions."
        }

        if isGuidedLoopRunning {
            return "The loop is running live. New pauses from your voice are folded back into the current plan."
        }

        if missionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Speak or type a fresh mission, or press New Session any time to clear the current workspace."
        }

        return "Startup restored the current mission draft. You can continue it immediately or clear into a new session."
    }

    var dialogueCount: Int {
        conversationEntries.filter { $0.speaker != .system }.count
    }

    var hasPendingOperatorPrompt: Bool {
        pendingOperatorPrompt != nil
    }

    var canRunLoop: Bool {
        !missionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        status != .running &&
        loopTask == nil &&
        !hasBlockingOperatorPrompt
    }

    var activeDecisionProfile: DecisionProfile {
        DecisionProfile.make(from: selectedDecisionModels)
    }

    var isGuidedLoopRunning: Bool {
        status == .running || loopTask != nil || hasBlockingOperatorPrompt
    }

    var isVoiceLoopActive: Bool {
        voiceLoopEnabled || isGuidedLoopRunning
    }

    private var hasBlockingOperatorPrompt: Bool {
        pendingOperatorPrompt?.kind.blocksLoop == true
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

    func startNewSession() {
        resolvePendingOperatorPrompt(
            decision: .revise,
            response: pendingOperatorResponseDraft,
            handledInternally: true
        )
        loopTask?.cancel()
        loopTask = nil
        listeningRestartTask?.cancel()
        listeningRestartTask = nil
        speakingTask?.cancel()
        speakingTask = nil

        missionTranscriber.stop()
        voiceLoopEnabled = false
        isRecordingMission = false
        isAgentSpeaking = false
        liveVoiceLoopContext = ""
        clearMissionDraftPreview()
        clearOperatorFeedbackDraftPreview()
        discardLiveVoiceDraftIfNeeded()

        missionText = ""
        operatorFeedback = ""
        typedInstructionDraft = ""
        voiceAnalysisSummary = ""
        externalDialogText = "Ready for a new session."
        internalDialogText = "Session reset. Awaiting a fresh mission."
        awaitingActionConfirmation = false
        currentIteration = 0
        objectiveProgress = 0.18
        sessionStartedAt = .now
        sessionNumber += 1

        let profile = activeDecisionProfile
        let starterSections = Self.placeholderSections(for: profile)
        let starterActions = Self.placeholderActions(for: profile)
        sections = starterSections
        actionQueue = starterActions

        let starterCycle = NavigationCycle(
            iteration: 0,
            createdAt: .now,
            mission: "",
            environment: environmentText,
            summary: "New session ready. Speak or type a mission to start the next loop.",
            model: "Planning Shell",
            progress: objectiveProgress,
            objectiveMet: false,
            isBlocked: false,
            blocker: nil,
            sections: starterSections,
            actions: starterActions
        )

        cycles = [starterCycle]
        selectedCycleID = starterCycle.id
        conversationEntries = Self.bootstrapConversationEntries(mission: "", operatorFeedback: "")
        persistWorkspaceDraft()
        startupRecoverySnapshot = nil

        if chatGPTAPIKey.isEmpty {
            status = .awaitingAPIKey
            statusMessage = "Add your ChatGPT API key in settings before starting the next session."
        } else {
            status = .idle
            statusMessage = "New session ready. Speak or type the mission when you want to begin."
        }

        recordingStatusMessage = "New session ready. Start the voice loop or type a new mission."
        updateVoiceFlow(
            state: .idle,
            title: "New session",
            detail: "The previous dialog and cycle history were cleared. The next spoken pause will start a fresh session.",
            transcript: nil,
            clearTranscript: true
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
            _ = await SystemPermissionPrompter.requestSpeechRecognitionAccessIfNeeded()
            _ = await SystemPermissionPrompter.requestMicrophoneAccessIfNeeded()

            await MainActor.run {
                self.refreshPermissionStatuses()
            }
        }
    }

    func refreshPermissionStatuses() {
        isAccessibilityGranted = SystemPermissionPrompter.isAccessibilityGranted()
        isScreenRecordingGranted = SystemPermissionPrompter.isScreenRecordingGranted()
        isSpeechRecognitionGranted = SystemPermissionPrompter.isSpeechRecognitionGranted()
        isMicrophoneGranted = SystemPermissionPrompter.isMicrophoneGranted()
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

    func requestSpeechRecognitionPermission() {
        refreshPermissionStatuses()

        Task {
            let granted = await SystemPermissionPrompter.requestSpeechRecognitionAccessIfNeeded()
            refreshPermissionStatuses()
            statusMessage = granted
                ? "Speech Recognition access is granted."
                : "Speech Recognition permission is still missing. Approve xmaxx in System Settings > Privacy & Security > Speech Recognition."
        }
    }

    func openSpeechRecognitionSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_SpeechRecognition") else {
            return
        }

        NSWorkspace.shared.open(url)
    }

    func requestMicrophonePermission() {
        refreshPermissionStatuses()

        Task {
            let granted = await SystemPermissionPrompter.requestMicrophoneAccessIfNeeded()
            refreshPermissionStatuses()
            statusMessage = granted
                ? "Microphone access is granted."
                : "Microphone permission is still missing. Approve xmaxx in System Settings > Privacy & Security > Microphone."
        }
    }

    func openMicrophoneSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") else {
            return
        }

        NSWorkspace.shared.open(url)
    }

    func requestAllPermissions() {
        triggerPermissionProbesIfNeeded()
        requestAccessibilityPermission()
        requestScreenRecordingPermission()
        requestSpeechRecognitionPermission()
        requestMicrophonePermission()
    }

    func autoStartIfPossible() {
        guard !didAutoStart else { return }
        didAutoStart = true
        markApplicationLaunchActive()

        if chatGPTAPIKey.isEmpty {
            status = .awaitingAPIKey
            statusMessage = "Add your ChatGPT API key in settings to start the guided loop."
        } else {
            status = .idle
            statusMessage = "Ready. Start the \(activeDecisionProfile.title) voice loop when you want to begin."
        }
        recordingStatusMessage = missionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Ready. Start the voice loop to capture the mission."
            : "Mission ready. Start the guided voice loop to run it with live steering."
        updateVoiceFlow(
            state: .idle,
            title: "Voice loop ready",
            detail: missionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? "Your first paused utterance will be captured as mission text."
                : "The mission is loaded. Speaking now will either update the mission or steer the live loop.",
            transcript: nil,
            clearTranscript: missionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        )
        persistRecoverySnapshot()
        presentStartupAssessmentIfNeeded()

        if !isRecordingMission && !isAgentSpeaking {
            startMissionRecording()
        }
    }

    private func presentStartupAssessmentIfNeeded() {
        guard pendingOperatorPrompt == nil else { return }
        guard previousLaunchEndedUncleanly else { return }

        let snapshot = startupRecoverySnapshot ?? currentRecoverySnapshot()
        guard snapshot.hasRecoverableState else {
            previousLaunchEndedUncleanly = false
            startupRecoverySnapshot = nil
            return
        }

        let cycleWord = snapshot.cycleCount == 1 ? "cycle" : "cycles"
        let progressPercent = Int(snapshot.lastCycleProgress * 100)
        let summaryLine = snapshot.lastCycleSummary.trimmingCharacters(in: .whitespacesAndNewlines)
        let missionLine = snapshot.mission.trimmingCharacters(in: .whitespacesAndNewlines)
        let savedAtLine = "Saved at: \(snapshot.lastCycleTimestamp.formatted(date: .abbreviated, time: .shortened))"
        let prompt = OperatorPrompt(
            kind: .startupAssessment,
            title: "Startup Assessment",
            question: "I found a previous session with \(snapshot.cycleCount) \(cycleWord). Continue forward from that saved state?",
            detail: [
                missionLine.isEmpty ? nil : "Mission: \(missionLine)",
                "Last status: \(snapshot.lastStatusTitle)",
                "Saved progress: \(progressPercent)%",
                savedAtLine,
                summaryLine.isEmpty ? nil : "Last cycle: \(summaryLine)"
            ]
            .compactMap { $0 }
            .joined(separator: "\n"),
            proceedLabel: "Continue Forward",
            reviseLabel: "New Session",
            responsePlaceholder: "Optional note before continuing"
        )

        statusMessage = "Startup assessment ready. Continue from the saved state or reset into a new session."
        recordingStatusMessage = "Recovery check ready. Confirm whether to continue the saved session."
        updateVoiceFlow(
            state: .idle,
            title: "Startup assessment",
            detail: "A previous session was found after launch. Confirm whether xmaxx should continue from that state or start fresh.",
            transcript: nil
        )
        presentOperatorPrompt(prompt)
        deliverDialogue(
            external: prompt.question,
            internal: "Startup recovery check after launch.",
            note: prompt.detail
        )
        startupRecoverySnapshot = nil
        previousLaunchEndedUncleanly = false
    }

    func markApplicationClosedGracefully() {
        persistWorkspaceDraft()
        userDefaults.set(false, forKey: applicationSessionActiveKey)
        previousLaunchEndedUncleanly = false
    }

    private func markApplicationLaunchActive() {
        userDefaults.set(true, forKey: applicationSessionActiveKey)
    }

    private func currentRecoverySnapshot() -> RecoverySnapshot {
        let latestCycle = cycles.first ?? NavigationCycle(
            iteration: 0,
            createdAt: .now,
            mission: missionText,
            environment: environmentText,
            summary: statusMessage,
            model: "Planning Shell",
            progress: objectiveProgress,
            objectiveMet: false,
            isBlocked: false,
            blocker: nil,
            sections: sections,
            actions: actionQueue
        )

        return RecoverySnapshot(
            mission: missionText,
            operatorFeedback: operatorFeedback,
            cycleCount: cycles.count,
            lastCycleSummary: latestCycle.summary,
            lastCycleProgress: latestCycle.progress,
            lastCycleTimestamp: latestCycle.createdAt,
            lastStatusTitle: status.title,
            voiceLoopEnabled: voiceLoopEnabled
        )
    }

    private func persistRecoverySnapshot() {
        let snapshot = currentRecoverySnapshot()
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        userDefaults.set(data, forKey: recoverySnapshotKey)
    }

    private static func loadRecoverySnapshot(
        from userDefaults: UserDefaults,
        key: String
    ) -> RecoverySnapshot? {
        guard let data = userDefaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(RecoverySnapshot.self, from: data)
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

    func chooseSkillsDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: skillsDirectoryPath, isDirectory: true)

        guard panel.runModal() == .OK, let selectedURL = panel.url else { return }

        do {
            let bookmarkData = try selectedURL.bookmarkData(
                options: [.withSecurityScope],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            userDefaults.set(bookmarkData, forKey: skillsDirectoryBookmarkKey)
            applySkillsDirectory(selectedURL, isDefault: false, statusOverride: nil)
        } catch {
            skillsStatusMessage = "Could not save access to the selected skills folder."
        }
    }

    func resetSkillsDirectoryToDefault() {
        userDefaults.removeObject(forKey: skillsDirectoryBookmarkKey)
        applySkillsDirectory(Self.ensureDefaultSkillsDirectory(), isDefault: true, statusOverride: nil)
    }

    func reloadSkillsDirectory() {
        applySkillsDirectory(
            URL(fileURLWithPath: skillsDirectoryPath, isDirectory: true),
            isDefault: isUsingDefaultSkillsDirectory,
            statusOverride: nil
        )
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
        persistRecoverySnapshot()
    }

    func selectCycle(_ cycle: NavigationCycle) {
        selectedCycleID = cycle.id
        sections = cycle.sections
        actionQueue = cycle.actions
        objectiveProgress = cycle.progress
        currentIteration = cycle.iteration
        status = cycle.objectiveMet ? .completed : (cycle.isBlocked ? .blocked : .ready)
        statusMessage = cycle.summary
        persistRecoverySnapshot()
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
        print("Running navigation loop at \(Date())")
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
        let speechStatus = isSpeechRecognitionGranted ? "Speech Recognition is granted." : "Speech Recognition is missing."
        let microphoneStatus = isMicrophoneGranted ? "Microphone is granted." : "Microphone is missing."

        automationStatusMessage = """
        \(accessibilityStatus) \(screenStatus) \(speechStatus) \(microphoneStatus) Mouse automation only works after Accessibility approval. Screen-based coordinate finding only works after Screen Recording approval. Live voice capture only works after Speech Recognition and Microphone approval.
        """
    }

    private func noteAutomationStatus(_ message: String) {
        automationStatusMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func runtimeCapabilitySummary() -> String {
        refreshPermissionStatuses()
        let accessibilityStatus = isAccessibilityGranted ? "granted" : "missing"
        let screenRecordingStatus = isScreenRecordingGranted ? "granted" : "missing"
        let speechRecognitionStatus = isSpeechRecognitionGranted ? "granted" : "missing"
        let microphoneStatus = isMicrophoneGranted ? "granted" : "missing"
        let pyannoteStatus = pyannoteAPIKey.isEmpty ? "disabled" : "enabled"
        let loadedSkillCount = loadedSkills.count

        return """
        Runtime capability status:
        - Real automation executor available for coordinate-based mouse_move, mouse_click, and mouse_right_click.
        - Screen coordinate resolver available through find_screen_text. It captures a fresh screenshot, runs OCR, and maps visible text to screen coordinates.
        - Mouse automation uses native HID mouse events from this app and depends on Accessibility permission. Current Accessibility status: \(accessibilityStatus).
        - Screen Recording permission status: \(screenRecordingStatus).
        - Speech Recognition permission status: \(speechRecognitionStatus).
        - Microphone permission status: \(microphoneStatus).
        - Screenshot-based coordinate finding depends on Screen Recording approval. Without it, the resolver cannot inspect the desktop.
        - Live operator steering by voice depends on Speech Recognition and Microphone approval.
        - pyannote speaker analysis is \(pyannoteStatus).
        - CLI skill markdown files loaded: \(loadedSkillCount). Skills directory: \(skillsDirectoryPath).
        """
    }

    private func ensureVoiceCapturePermissions() async -> Bool {
        refreshPermissionStatuses()

        let speechGranted = await SystemPermissionPrompter.requestSpeechRecognitionAccessIfNeeded()
        let microphoneGranted = await SystemPermissionPrompter.requestMicrophoneAccessIfNeeded()
        refreshPermissionStatuses()

        guard speechGranted, microphoneGranted else {
            voiceLoopEnabled = false
            isRecordingMission = false
            let missing = missingVoicePermissionSummary()
            statusMessage = missing
            recordingStatusMessage = missing
            updateVoiceFlow(
                state: .error,
                title: "Voice permissions missing",
                detail: missing,
                transcript: nil
            )
            return false
        }

        return true
    }

    private func missingVoicePermissionSummary() -> String {
        var missing: [String] = []

        if !isSpeechRecognitionGranted {
            missing.append("Speech Recognition")
        }

        if !isMicrophoneGranted {
            missing.append("Microphone")
        }

        if missing.isEmpty {
            return "Voice capture permission is missing."
        }

        return "Voice capture cannot start until \(missing.joined(separator: " and ")) access is approved in System Settings > Privacy & Security."
    }

    private func applySkillsDirectory(_ directoryURL: URL, isDefault: Bool, statusOverride: String?) {
        let normalizedURL = directoryURL.standardizedFileURL
        skillsDirectoryPath = normalizedURL.path
        isUsingDefaultSkillsDirectory = isDefault
        loadedSkills = Self.loadSkills(from: normalizedURL)
        skillsStatusMessage = statusOverride ?? Self.makeSkillsStatusMessage(
            count: loadedSkills.count,
            directoryURL: normalizedURL,
            isDefault: isDefault
        )
    }

    private static func resolveSkillsDirectoryConfiguration(
        from userDefaults: UserDefaults,
        bookmarkKey: String
    ) -> SkillsDirectoryConfiguration {
        let defaultDirectoryURL = ensureDefaultSkillsDirectory()

        guard let bookmarkData = userDefaults.data(forKey: bookmarkKey) else {
            return SkillsDirectoryConfiguration(
                directoryURL: defaultDirectoryURL,
                isDefault: true,
                statusMessage: nil
            )
        }

        var isStale = false

        do {
            let directoryURL = try URL(
                resolvingBookmarkData: bookmarkData,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

            if isStale {
                userDefaults.removeObject(forKey: bookmarkKey)
                return SkillsDirectoryConfiguration(
                    directoryURL: defaultDirectoryURL,
                    isDefault: true,
                    statusMessage: "Saved skills folder access expired. Reverted to the default skills folder."
                )
            }

            return SkillsDirectoryConfiguration(
                directoryURL: directoryURL,
                isDefault: false,
                statusMessage: nil
            )
        } catch {
            userDefaults.removeObject(forKey: bookmarkKey)
            return SkillsDirectoryConfiguration(
                directoryURL: defaultDirectoryURL,
                isDefault: true,
                statusMessage: "Saved skills folder could not be reopened. Reverted to the default skills folder."
            )
        }
    }

    private static func ensureDefaultSkillsDirectory() -> URL {
        let applicationSupportURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.homeDirectoryForCurrentUser

        let directoryURL = applicationSupportURL
            .appendingPathComponent("xmaxx", isDirectory: true)
            .appendingPathComponent("skills", isDirectory: true)

        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        return directoryURL
    }

    private static func loadSkills(from directoryURL: URL) -> [LoadedSkill] {
        let accessedResource = directoryURL.startAccessingSecurityScopedResource()
        defer {
            if accessedResource {
                directoryURL.stopAccessingSecurityScopedResource()
            }
        }

        let resourceKeys: Set<URLResourceKey> = [.isRegularFileKey]
        let enumerator = FileManager.default.enumerator(
            at: directoryURL,
            includingPropertiesForKeys: Array(resourceKeys),
            options: [.skipsHiddenFiles]
        )

        var loadedSkills: [LoadedSkill] = []

        while let fileURL = enumerator?.nextObject() as? URL {
            guard fileURL.pathExtension.lowercased() == "md" else { continue }
            guard
                let resourceValues = try? fileURL.resourceValues(forKeys: resourceKeys),
                resourceValues.isRegularFile == true
            else {
                continue
            }

            guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else { continue }
            let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedContent.isEmpty else { continue }

            let metadata = parseSkillMetadata(from: trimmedContent, fallbackName: fileURL.deletingPathExtension().lastPathComponent)
            loadedSkills.append(
                LoadedSkill(
                    fileURL: fileURL,
                    title: metadata.title,
                    summary: metadata.summary,
                    content: trimmedContent
                )
            )
        }

        return loadedSkills.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    private static func parseSkillMetadata(from content: String, fallbackName: String) -> (title: String, summary: String) {
        let lines = content
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        let title = lines.first(where: { $0.hasPrefix("# ") })
            .map { String($0.dropFirst(2)).trimmingCharacters(in: .whitespacesAndNewlines) }
            ?? fallbackName

        let summary = lines.first(where: { line in
            !line.isEmpty && !line.hasPrefix("#") && !line.hasPrefix("-") && !line.hasPrefix("*")
        }) ?? "CLI skill documentation available."

        return (title, summary)
    }

    private static func makeSkillsStatusMessage(count: Int, directoryURL: URL, isDefault: Bool) -> String {
        let folderLabel = isDefault ? "default skills folder" : "custom skills folder"
        let skillWord = count == 1 ? "skill" : "skills"

        if count == 0 {
            return "No `.md` skills found in the \(folderLabel) at \(directoryURL.path)."
        }

        return "Loaded \(count) \(skillWord) from the \(folderLabel) at \(directoryURL.path)."
    }

    func stopLoop() {
        let wasAwaitingActionConfirmation = awaitingActionConfirmation
        resolvePendingOperatorPrompt(
            decision: .revise,
            response: pendingOperatorResponseDraft
        )
        loopTask?.cancel()
        loopTask = nil

        if status == .running || wasAwaitingActionConfirmation {
            status = .stopped
            statusMessage = "Loop stopped by operator."
            deliverDialogue(
                external: "Stopping now.",
                internal: "Loop stopped by operator."
            )
            persistRecoverySnapshot()
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
        if pendingOperatorPrompt?.kind == .startupAssessment {
            status = .ready
            statusMessage = "Answer the startup assessment before continuing the saved session."
            return
        }

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
        recordingStatusMessage = "Checking voice permissions before arming the mic."
        updateVoiceFlow(
            state: .processing,
            title: "Checking permissions",
            detail: "xmaxx is requesting the permissions needed for live voice capture before opening the transcript.",
            transcript: nil
        )

        Task {
            let permissionsReady = await ensureVoiceCapturePermissions()
            guard permissionsReady else { return }

            updateVoiceFlow(
                state: .listening,
                title: "Mic armed",
                detail: "Live transcript is open. Pause once and the current speech will be committed into the loop.",
                transcript: nil
            )
            beginMissionListening()
        }
    }

    func confirmPendingActions() {
        guard pendingOperatorPrompt?.kind == .actionApproval else { return }
        submitPendingOperatorPromptProceed(responseOverride: "confirm action")
        status = .running
        statusMessage = "Action confirmation received. Executing approved actions."
        recordingStatusMessage = "Action confirmation received. Executing approved actions."
        updateVoiceFlow(
            state: .processing,
            title: "Confirmation captured",
            detail: "Your approval was heard and the queued actions are now moving through execution.",
            transcript: "confirm action"
        )
    }

    func submitTypedInstruction() {
        let trimmedInstruction = typedInstructionDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInstruction.isEmpty else { return }

        typedInstructionDraft = ""
        let normalizedInstruction = trimmedInstruction.lowercased()

        if let prompt = pendingOperatorPrompt {
            pendingOperatorResponseDraft = trimmedInstruction
            recordingStatusMessage = "Typed response received."

            if prompt.kind == .actionApproval && isActionConfirmationCommand(normalizedInstruction) {
                status = .running
                statusMessage = "Typed approval received. Executing approved actions."
                updateVoiceFlow(
                    state: .processing,
                    title: "Typed approval captured",
                    detail: "The typed approval was accepted for the waiting plan and execution is starting now.",
                    transcript: trimmedInstruction
                )
                submitPendingOperatorPromptProceed(responseOverride: trimmedInstruction)
                return
            }

            if isPromptRevisionCommand(normalizedInstruction) {
                updateVoiceFlow(
                    state: .captured,
                    title: "Typed revision captured",
                    detail: "The typed reply requested a revision before continuing.",
                    transcript: trimmedInstruction
                )
                submitPendingOperatorPromptRevise(responseOverride: trimmedInstruction)
                return
            }

            updateVoiceFlow(
                state: .captured,
                title: "Typed reply captured",
                detail: "The typed reply was submitted to the open prompt.",
                transcript: trimmedInstruction
            )
            submitPendingOperatorPromptProceed(responseOverride: trimmedInstruction)
            return
        }

        if status == .running || loopTask != nil {
            applyTypedOperatorSteering(trimmedInstruction, normalizedInstruction: normalizedInstruction)
            return
        }

        applyTypedMissionInstruction(trimmedInstruction)
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
            updateVoiceFlow(
                state: .listening,
                title: status == .running ? "Listening for steering" : "Listening for mission",
                detail: status == .running
                    ? "Keep talking. When you pause, the latest steering will be committed into the active loop."
                    : "Keep talking. When you pause, the latest mission text will be committed and the loop will start.",
                transcript: nil
            )
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
                    updateVoiceFlow(
                        state: .listening,
                        title: "Listening for steering",
                        detail: "Your next paused utterance will be captured and folded into the running loop.",
                        transcript: nil
                    )
                } else if isAgentSpeaking {
                    missionTranscriber.suspendSegmentDelivery()
                    recordingStatusMessage = "Speaking response. Mic stays live while self-voice is ignored."
                    updateVoiceFlow(
                        state: .speaking,
                        title: "Agent speaking",
                        detail: "Your last captured text is already in the loop. The mic will resume as soon as playback clears.",
                        transcript: nil
                    )
                } else {
                    missionTranscriber.resumeSegmentDelivery()
                    recordingStatusMessage = "Listening continuously. Pause to start x-maxx."
                    updateVoiceFlow(
                        state: .listening,
                        title: "Listening for mission",
                        detail: "The app is actively hearing you. Pause once to commit the current transcript into the mission flow.",
                        transcript: nil
                    )
                }
            } catch {
                isRecordingMission = false
                recordingStatusMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                updateVoiceFlow(
                    state: .error,
                    title: "Voice capture failed",
                    detail: (error as? LocalizedError)?.errorDescription ?? error.localizedDescription,
                    transcript: nil
                )
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
        discardLiveVoiceDraftIfNeeded()
        let trimmedMission = missionText.trimmingCharacters(in: .whitespacesAndNewlines)
        recordingStatusMessage = trimmedMission.isEmpty
            ? "Ready. Start the voice loop to capture the mission."
            : "Voice loop stopped. The current mission stays loaded."
        updateVoiceFlow(
            state: .idle,
            title: "Voice loop stopped",
            detail: trimmedMission.isEmpty
                ? "Nothing is currently queued from voice."
                : "The current mission stays loaded and can be resumed at any time.",
            transcript: nil,
            clearTranscript: trimmedMission.isEmpty
        )
    }

    private func pauseMissionRecordingForProcessing() {
        if voiceLoopEnabled {
            recordingStatusMessage = status == .running
                ? "Guided loop running. Mic is active for steering. Pause to inject guidance."
                : "Processing mission. Mic is active."
        }
    }

    private func handleCapturedSpeech(_ capture: MissionCapture) async {
        print("Handling captured speech at \(Date())")
        if pendingOperatorPrompt != nil {
            await handlePendingOperatorPromptCapture(capture)
            return
        }

        if status == .running || loopTask != nil {
            await processOperatorSteering(capture)
        } else {
            await processCapturedMission(capture)
        }
    }

    private func handlePendingOperatorPromptCapture(_ capture: MissionCapture) async {
        let trimmedTranscript = capture.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let prompt = pendingOperatorPrompt else {
            capture.deleteTemporaryAudioFileIfNeeded()
            return
        }

        guard !trimmedTranscript.isEmpty else {
            discardLiveVoiceDraftIfNeeded()
            capture.deleteTemporaryAudioFileIfNeeded()
            return
        }

        let normalized = trimmedTranscript.lowercased()
        let detail: String
        if prompt.kind == .actionApproval && isActionConfirmationCommand(normalized) {
            detail = "Captured as approval for the current plan."
            finalizeVoiceDraft(
                transcript: trimmedTranscript,
                detail: detail,
                state: .captured
            )
            submitPendingOperatorPromptProceed(
                responseOverride: trimmedTranscript,
                handledInternally: true
            )
        } else if isPromptRevisionCommand(normalized) {
            detail = prompt.kind == .startupAssessment
                ? "Captured as request to start a new session."
                : "Captured as request to revise before proceeding."
            finalizeVoiceDraft(
                transcript: trimmedTranscript,
                detail: detail,
                state: .captured
            )
            submitPendingOperatorPromptRevise(
                responseOverride: trimmedTranscript,
                handledInternally: true
            )
        } else {
            detail = "Captured as the answer to the open question."
            finalizeVoiceDraft(
                transcript: trimmedTranscript,
                detail: detail,
                state: .processing
            )
            submitPendingOperatorPromptProceed(
                responseOverride: trimmedTranscript,
                handledInternally: true
            )
        }

        capture.deleteTemporaryAudioFileIfNeeded()
    }

    private func processCapturedMission(_ capture: MissionCapture) async {
        print("Processing captured mission at \(Date())")
        let trimmedTranscript = capture.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTranscript.isEmpty else {
            clearMissionDraftPreview()
            discardLiveVoiceDraftIfNeeded()
            capture.deleteTemporaryAudioFileIfNeeded()
            return
        }

        let baseMissionText = missionDraftBaseText ?? missionText
        clearMissionDraftPreview()
        pauseMissionRecordingForProcessing()
        missionText = appendMissionEntry(trimmedTranscript, to: baseMissionText)
        finalizeVoiceDraft(
            transcript: trimmedTranscript,
            detail: "Captured as mission input and now being incorporated into the loop.",
            state: .processing
        )
        recordingStatusMessage = "Mission captured. Running x-maxx while voice analysis continues."
        updateVoiceFlow(
            state: .processing,
            title: "Mission captured",
            detail: "Your paused speech was committed into the mission and is now being incorporated into the next loop run.",
            transcript: trimmedTranscript
        )
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
            discardLiveVoiceDraftIfNeeded()
            capture.deleteTemporaryAudioFileIfNeeded()
            return
        }

        let baseOperatorFeedback = operatorFeedbackDraftBaseText ?? operatorFeedback
        clearOperatorFeedbackDraftPreview()
        let normalized = trimmedTranscript.lowercased()

        if normalized.contains("stop loop") || normalized.contains("cancel loop") || normalized.contains("halt loop") {
            recordingStatusMessage = "Voice command received. Stopping the loop."
            finalizeVoiceDraft(
                transcript: trimmedTranscript,
                detail: "Captured as a stop command.",
                state: .captured
            )
            updateVoiceFlow(
                state: .captured,
                title: "Stop command captured",
                detail: "The voice command was heard and the active loop is stopping now.",
                transcript: trimmedTranscript
            )
            capture.deleteTemporaryAudioFileIfNeeded()
            stopLoop()
            return
        }

        if awaitingActionConfirmation && isActionConfirmationCommand(normalized) {
            recordingStatusMessage = "Voice confirmation received. Executing approved actions."
            finalizeVoiceDraft(
                transcript: trimmedTranscript,
                detail: "Captured as action approval. Execution is starting now.",
                state: .processing
            )
            updateVoiceFlow(
                state: .captured,
                title: "Confirmation captured",
                detail: "Your approval was captured and is being applied to the waiting plan.",
                transcript: trimmedTranscript
            )
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
            finalizeVoiceDraft(
                transcript: trimmedTranscript,
                detail: "Captured as steering. The waiting plan is being revised before anything executes.",
                state: .processing
            )
            updateVoiceFlow(
                state: .processing,
                title: "Steering captured",
                detail: "Your speech was appended to the operator feedback and the plan is being revised before any action runs.",
                transcript: trimmedTranscript
            )
            submitPendingOperatorPromptRevise(responseOverride: trimmedTranscript, handledInternally: true)
            return
        }

        if loopTask != nil {
            finalizeVoiceDraft(
                transcript: trimmedTranscript,
                detail: "Captured as steering and now being folded into the live loop.",
                state: .processing
            )
            updateVoiceFlow(
                state: .processing,
                title: "Steering captured",
                detail: "Your speech was appended to the live loop context and planning is restarting with that new input now.",
                transcript: trimmedTranscript
            )
            restartLoopPlanningWithLatestContext()
        } else {
            finalizeVoiceDraft(
                transcript: trimmedTranscript,
                detail: "Captured as steering and queued for the next cycle.",
                state: .captured
            )
            updateVoiceFlow(
                state: .captured,
                title: "Steering captured",
                detail: "Your speech was appended to operator feedback and is ready for the next loop cycle.",
                transcript: trimmedTranscript
            )
        }
    }

    private func applyTypedMissionInstruction(_ instruction: String) {
        missionText = appendMissionEntry(instruction, to: missionText)
        persistWorkspaceDraft()
        recordingStatusMessage = "Typed mission captured. Running x-maxx now."
        appendConversationEntry(
            ConversationMessage(
                speaker: .user,
                text: instruction,
                detail: "Typed mission input submitted.",
                state: .captured
            )
        )
        updateVoiceFlow(
            state: .processing,
            title: "Typed mission captured",
            detail: "The typed instruction was added to the mission and the loop is starting now.",
            transcript: instruction
        )
        runNavigationLoop(preserveVoiceLoop: voiceLoopEnabled)
    }

    private func applyTypedOperatorSteering(_ instruction: String, normalizedInstruction: String) {
        if normalizedInstruction.contains("stop loop") || normalizedInstruction.contains("cancel loop") || normalizedInstruction.contains("halt loop") {
            recordingStatusMessage = "Typed stop command received. Stopping the loop."
            appendConversationEntry(
                ConversationMessage(
                    speaker: .user,
                    text: instruction,
                    detail: "Typed stop command submitted.",
                    state: .captured
                )
            )
            updateVoiceFlow(
                state: .captured,
                title: "Typed stop command",
                detail: "The typed stop command was accepted and the active loop is stopping now.",
                transcript: instruction
            )
            stopLoop()
            return
        }

        operatorFeedback = appendTypedOperatorFeedbackEntry(instruction, to: operatorFeedback)
        persistWorkspaceDraft()
        recordingStatusMessage = "Typed steering captured and appended to the active context."
        appendConversationEntry(
            ConversationMessage(
                speaker: .user,
                text: instruction,
                detail: "Typed steering submitted.",
                state: .captured
            )
        )

        if awaitingActionConfirmation {
            statusMessage = "Typed steering received. Replanning before any action executes."
            updateVoiceFlow(
                state: .processing,
                title: "Typed steering captured",
                detail: "The typed steering was appended and the waiting plan is being revised before anything executes.",
                transcript: instruction
            )
            submitPendingOperatorPromptRevise(responseOverride: instruction)
            return
        }

        if loopTask != nil {
            updateVoiceFlow(
                state: .processing,
                title: "Typed steering captured",
                detail: "The typed steering was appended to the live loop context and planning is restarting now.",
                transcript: instruction
            )
            restartLoopPlanningWithLatestContext()
        } else {
            updateVoiceFlow(
                state: .captured,
                title: "Typed steering captured",
                detail: "The typed steering was appended and is ready for the next loop cycle.",
                transcript: instruction
            )
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
        updateLiveVoiceDraft(
            transcript: trimmedTranscript,
            detail: "Listening now. If you pause here, this will become mission input."
        )
        updateVoiceFlow(
            state: .listening,
            title: "Hearing mission text",
            detail: "The live transcript is updating. When you pause, this text will be committed into the mission and used by the loop.",
            transcript: trimmedTranscript
        )
    }

    private func updateOperatorFeedbackDraft(with transcript: String) {
        let trimmedTranscript = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTranscript.isEmpty else { return }

        if operatorFeedbackDraftBaseText == nil {
            operatorFeedbackDraftBaseText = operatorFeedback
        }

        operatorFeedback = appendOperatorFeedbackEntry(trimmedTranscript, to: operatorFeedbackDraftBaseText ?? "")
        updateLiveVoiceDraft(
            transcript: trimmedTranscript,
            detail: "Listening now. If you pause here, this will be appended as fresh steering."
        )
        updateVoiceFlow(
            state: .listening,
            title: "Hearing steering",
            detail: "The live transcript is updating. When you pause, this text will be appended to the loop as fresh steering.",
            transcript: trimmedTranscript
        )
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

    private func appendTypedOperatorFeedbackEntry(_ entry: String, to existingText: String) -> String {
        let trimmedEntry = entry.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEntry.isEmpty else { return existingText }

        return appendDistinctEntry(trimmedEntry, prefix: "Typed steer", existingText: existingText, limit: 12)
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
            action.status == .ready && requiresOperatorApproval(for: action.tool)
        }
    }

    private func requiresLongRunningCheckpoint(for actions: [ActionItem]) -> Bool {
        let actionableCount = actions.filter { $0.status == .queued || $0.status == .ready }.count
        let includesShellPlan = actions.contains {
            $0.tool.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "shell_command"
        }

        return actionableCount >= 4 || (includesShellPlan && actionableCount >= 2)
    }

    private func isExecutableActionTool(_ tool: String) -> Bool {
        let normalizedTool = tool.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return normalizedTool == "mouse_move" || normalizedTool == "mouse_click" || normalizedTool == "mouse_right_click"
    }

    private func requiresOperatorApproval(for tool: String) -> Bool {
        let normalizedTool = tool.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return normalizedTool == "mouse_click" || normalizedTool == "mouse_right_click"
    }

    private func detectNavigationLoop(
        currentActions: [ActionItem],
        currentProgress: Double,
        history: [NavigationCycle]
    ) -> (question: String, detail: String, internalNote: String)? {
        let recentCycles = Array(history.suffix(2))
        guard recentCycles.count == 2 else { return nil }

        let priorProgress = recentCycles.map(\.progress)
        let progressStalled = priorProgress.allSatisfy { currentProgress <= $0 + 0.02 }

        let currentReadySignature = readyActionSignature(from: currentActions)
        let repeatedReadyAction =
            !currentReadySignature.isEmpty &&
            recentCycles.allSatisfy { readyActionSignature(from: $0.actions) == currentReadySignature }

        if progressStalled && repeatedReadyAction {
            let actionLabel = describeActionSignature(currentReadySignature)
            return (
                question: "I am repeating \(actionLabel) without meaningful progress. Should I stop, keep probing, or try a different target?",
                detail: "The last few cycles converged on the same ready navigation step while progress stayed flat.",
                internalNote: "Repeated ready navigation action detected with stalled progress. Pause for operator direction instead of looping."
            )
        }

        let currentBlockedSignature = blockedActionSignature(from: currentActions)
        let repeatedBlockedAction =
            !currentBlockedSignature.isEmpty &&
            recentCycles.contains { blockedActionSignature(from: $0.actions) == currentBlockedSignature }

        if repeatedBlockedAction {
            let actionLabel = describeActionSignature(currentBlockedSignature)
            return (
                question: "I am stuck repeating \(actionLabel). Should I stop, wait, or redirect to a different target?",
                detail: "A blocked navigation step is recurring, so continuing automatically is unlikely to help.",
                internalNote: "Repeated blocked navigation action detected. Ask for direction rather than retrying the same failed step."
            )
        }

        return nil
    }

    private func readyActionSignature(from actions: [ActionItem]) -> String {
        actionSignature(
            from: actions.first(where: { $0.status == .ready && isExecutableActionTool($0.tool) })
        )
    }

    private func blockedActionSignature(from actions: [ActionItem]) -> String {
        actionSignature(
            from: actions.first(where: { $0.status == .blocked && isExecutableActionTool($0.tool) })
        )
    }

    private func actionSignature(from action: ActionItem?) -> String {
        guard let action else { return "" }

        let tool = action.tool.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let target = action.target.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let coordinates: String
        if let x = action.x, let y = action.y {
            coordinates = "@\(Int(x.rounded()))x\(Int(y.rounded()))"
        } else {
            coordinates = "@unresolved"
        }

        return "\(tool)|\(target)|\(coordinates)"
    }

    private func describeActionSignature(_ signature: String) -> String {
        guard !signature.isEmpty else { return "the same navigation step" }

        let parts = signature.split(separator: "|", maxSplits: 2).map(String.init)
        let tool = parts.indices.contains(0) ? parts[0] : "action"
        let target = parts.indices.contains(1) ? parts[1] : ""

        if target.isEmpty {
            return tool.replacingOccurrences(of: "_", with: " ")
        }

        return "\(tool.replacingOccurrences(of: "_", with: " ")) on \"\(target)\""
    }

    private func presentOperatorPrompt(_ prompt: OperatorPrompt, initialResponse: String = "") {
        pendingOperatorPrompt = prompt
        pendingOperatorResponseDraft = initialResponse
        awaitingOperatorInput = true
        awaitingActionConfirmation = prompt.kind == .actionApproval

        if prompt.kind.blocksLoop {
            status = .ready
            recordingStatusMessage = prompt.question
            updateVoiceFlow(
                state: .captured,
                title: prompt.title,
                detail: prompt.question,
                transcript: nil
            )
        }
    }

    private func waitForOperatorPrompt(
        _ prompt: OperatorPrompt,
        initialResponse: String = ""
    ) async -> OperatorPromptResult {
        await withCheckedContinuation { continuation in
            self.operatorPromptContinuation = continuation
            self.presentOperatorPrompt(prompt, initialResponse: initialResponse)
        }
    }

    private func resolvePendingOperatorPrompt(
        decision: OperatorPromptDecision,
        response: String? = nil,
        handledInternally: Bool = false
    ) {
        let trimmedResponse = (response ?? pendingOperatorResponseDraft)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let prompt = pendingOperatorPrompt
        let continuation = operatorPromptContinuation

        pendingOperatorPrompt = nil
        pendingOperatorResponseDraft = ""
        awaitingOperatorInput = false
        awaitingActionConfirmation = false
        operatorPromptContinuation = nil

        guard let prompt else { return }

        let result = OperatorPromptResult(
            decision: decision,
            response: trimmedResponse
        )

        if !handledInternally {
            recordOperatorPromptDecision(prompt: prompt, result: result)
        }

        if let continuation {
            continuation.resume(returning: result)
            return
        }

        handleStandaloneOperatorPrompt(prompt: prompt, result: result)
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

    private func isPromptRevisionCommand(_ normalizedTranscript: String) -> Bool {
        let phrases = [
            "new session",
            "start new session",
            "start fresh",
            "start over",
            "reset session",
            "revise",
            "change it",
            "not yet",
            "hold on",
            "wait",
            "stop here"
        ]

        return phrases.contains { normalizedTranscript.contains($0) }
    }

    func proceedPendingOperatorPrompt() {
        submitPendingOperatorPromptProceed()
    }

    private func submitPendingOperatorPromptProceed(
        responseOverride: String? = nil,
        handledInternally: Bool = false
    ) {
        guard let prompt = pendingOperatorPrompt else { return }
        let response = (responseOverride ?? pendingOperatorResponseDraft)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.requiresResponse || !response.isEmpty else { return }
        resolvePendingOperatorPrompt(
            decision: .proceed,
            response: response,
            handledInternally: handledInternally
        )
    }

    func revisePendingOperatorPrompt() {
        resolvePendingOperatorPrompt(decision: .revise)
    }

    private func submitPendingOperatorPromptRevise(
        responseOverride: String? = nil,
        handledInternally: Bool = false
    ) {
        resolvePendingOperatorPrompt(
            decision: .revise,
            response: responseOverride,
            handledInternally: handledInternally
        )
    }

    private func recordOperatorPromptDecision(
        prompt: OperatorPrompt,
        result: OperatorPromptResult
    ) {
        let defaultText = result.decision == .proceed ? prompt.proceedLabel : prompt.reviseLabel
        let detail: String
        switch prompt.kind {
        case .startupAssessment:
            detail = result.decision == .proceed
                ? "Startup assessment accepted."
                : "Startup assessment rejected. Resetting into a new session."
        case .actionApproval:
            detail = result.decision == .proceed
                ? "Approved the current executable plan."
                : "Requested revisions before execution."
        case .checkpoint:
            detail = result.decision == .proceed
                ? "Checkpoint approved."
                : "Checkpoint paused for more feedback."
        case .question:
            detail = result.decision == .proceed
                ? "Answered the planner's question."
                : "Paused before answering the planner's question."
        }

        appendConversationEntry(
            ConversationMessage(
                speaker: .user,
                text: result.response.isEmpty ? defaultText : result.response,
                detail: detail,
                state: .captured
            )
        )
    }

    private func handleStandaloneOperatorPrompt(
        prompt: OperatorPrompt,
        result: OperatorPromptResult
    ) {
        switch prompt.kind {
        case .startupAssessment:
            if result.decision == .revise {
                startNewSession()
                return
            }

            if !result.response.isEmpty {
                operatorFeedback = appendOperatorFeedbackEntry(result.response, to: operatorFeedback)
                persistWorkspaceDraft()
            }

            statusMessage = "Recovered startup state. Continue forward when ready."
            recordingStatusMessage = "Recovery accepted. Resume the saved mission whenever you are ready."
            updateVoiceFlow(
                state: .idle,
                title: "Recovery accepted",
                detail: "The saved session remains loaded. Start the loop again or add more feedback before continuing.",
                transcript: nil
            )
            persistRecoverySnapshot()

        case .actionApproval, .checkpoint, .question:
            break
        }
    }

    private func shouldReplanAfterOperatorPrompt(_ result: OperatorPromptResult) -> Bool {
        let trimmedResponse = result.response.trimmingCharacters(in: .whitespacesAndNewlines)

        if !trimmedResponse.isEmpty {
            operatorFeedback = appendOperatorFeedbackEntry(trimmedResponse, to: operatorFeedback)
            persistWorkspaceDraft()
        }

        switch result.decision {
        case .proceed:
            return !trimmedResponse.isEmpty
        case .revise:
            return true
        }
    }

    private func restartLoopPlanningWithLatestContext() {
        guard loopTask != nil else { return }

        let preservedVoiceContext = liveVoiceLoopContext
        loopTask?.cancel()
        loopTask = nil
        status = .running
        statusMessage = "Restarting planning with updated operator guidance."
        updateVoiceFlow(
            state: .processing,
            title: "Replanning with captured steering",
            detail: "The latest paused speech is now part of the active context and the loop is being recomputed around it.",
            transcript: voiceFlowTranscript.isEmpty ? nil : voiceFlowTranscript
        )
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
        print("Running loop session at \(Date())")
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

            print("Starting API call for cycle \(iteration) at \(Date())")
            let result = try await client.generateNavigationLoop(
                apiKey: chatGPTAPIKey,
                profileName: profileName,
                mission: mission,
                environment: liveEnvironment,
                operatorFeedback: liveOperatorFeedback.isEmpty ? operatorFeedback : liveOperatorFeedback,
                iteration: iteration,
                maxIterations: limit,
                priorCycles: history,
                decisionProfile: decisionProfile,
                loadedSkills: loadedSkills
            )
            print("API call completed for cycle \(iteration) at \(Date())")

            sections = result.sections
            actionQueue = result.actions
            objectiveProgress = result.progress

            let operatorQuestion = result.operatorQuestion?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            if !result.objectiveMet && result.needsOperatorInput && !operatorQuestion.isEmpty {
                let prompt = OperatorPrompt(
                    kind: .question,
                    title: "Need Operator Input",
                    question: operatorQuestion,
                    detail: result.decisionTrace.note,
                    proceedLabel: "Submit Answer",
                    reviseLabel: "Pause Loop",
                    responsePlaceholder: "Answer the question or add a new constraint",
                    requiresResponse: true
                )
                status = .ready
                statusMessage = prompt.question
                deliverDialogue(
                    external: prompt.question,
                    internal: result.internalMessage,
                    note: prompt.detail
                )

                let answerResult = await waitForOperatorPrompt(prompt)
                try Task.checkCancellation()

                if answerResult.decision == .revise {
                    status = .ready
                    statusMessage = "Loop paused while waiting for operator input."
                    loopTask = nil
                    scheduleMissionListeningRestartIfNeeded()
                    return
                }

                if shouldReplanAfterOperatorPrompt(answerResult) {
                    status = .running
                    statusMessage = "Operator input received. Replanning with the latest answer."
                    continue
                }
            }

            if !result.objectiveMet, let loopSignal = detectNavigationLoop(
                currentActions: result.actions,
                currentProgress: result.progress,
                history: history
            ) {
                let prompt = OperatorPrompt(
                    kind: .question,
                    title: "Navigation Loop Check",
                    question: loopSignal.question,
                    detail: loopSignal.detail,
                    proceedLabel: "Send Direction",
                    reviseLabel: "Stop Loop",
                    responsePlaceholder: "Tell xmaxx to stop, choose a different target, or add a constraint",
                    requiresResponse: true
                )
                status = .ready
                statusMessage = prompt.question
                deliverDialogue(
                    external: prompt.question,
                    internal: loopSignal.internalNote,
                    note: prompt.detail
                )

                let loopResult = await waitForOperatorPrompt(prompt)
                try Task.checkCancellation()

                if loopResult.decision == .revise {
                    status = .ready
                    statusMessage = "Loop paused after repeated navigation behavior."
                    loopTask = nil
                    scheduleMissionListeningRestartIfNeeded()
                    return
                }

                if shouldReplanAfterOperatorPrompt(loopResult) {
                    status = .running
                    statusMessage = "Direction received. Replanning with the latest operator guidance."
                    continue
                }
            }

            if !result.objectiveMet && !result.isBlocked && requiresActionConfirmation(for: result.actions) {
                let prompt = OperatorPrompt(
                    kind: .actionApproval,
                    title: "Action Approval",
                    question: "Plan ready. Say confirm action to execute, or keep talking to revise.",
                    detail: "Cycle \(iteration) is waiting for approval before any executable action runs.",
                    proceedLabel: "Approve Actions",
                    reviseLabel: "Revise Plan"
                )
                status = .ready
                statusMessage = prompt.question
                deliverDialogue(
                    external: prompt.question,
                    internal: "Waiting for action confirmation on cycle \(iteration). Fresh operator speech will revise the plan before any action executes.",
                    note: prompt.detail
                )

                let approvalResult = await waitForOperatorPrompt(prompt)
                try Task.checkCancellation()

                if shouldReplanAfterOperatorPrompt(approvalResult) {
                    status = .running
                    statusMessage = "Replanning with updated operator guidance."
                    continue
                }

                status = .running
                statusMessage = "Action confirmation received. Executing approved actions."
            } else if !result.objectiveMet && !result.isBlocked && requiresLongRunningCheckpoint(for: result.actions) {
                let prompt = OperatorPrompt(
                    kind: .checkpoint,
                    title: "Long-Run Checkpoint",
                    question: "This cycle spans multiple steps. Proceed forward, or add feedback before xmaxx continues?",
                    detail: result.summary,
                    proceedLabel: "Proceed Forward",
                    reviseLabel: "Add Feedback",
                    responsePlaceholder: "Optional checkpoint note or constraint"
                )
                status = .ready
                statusMessage = prompt.question
                deliverDialogue(
                    external: prompt.question,
                    internal: "Checkpoint requested on cycle \(iteration) because the current plan is a longer multi-step act.",
                    note: prompt.detail
                )

                let checkpointResult = await waitForOperatorPrompt(prompt)
                try Task.checkCancellation()

                if shouldReplanAfterOperatorPrompt(checkpointResult) {
                    status = .running
                    statusMessage = "Checkpoint feedback received. Replanning with the latest operator input."
                    continue
                }

                status = .running
                statusMessage = "Checkpoint cleared. Continuing the current plan."
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
                operatorMessage: result.operatorMessage,
                internalMessage: result.internalMessage,
                decisionNote: result.decisionTrace.note,
                sections: result.sections,
                actions: executedActions
            )

            history.append(cycle)
            sections = cycle.sections
            actionQueue = cycle.actions
            cycles.insert(cycle, at: 0)
            selectedCycleID = cycle.id
            objectiveProgress = cycle.progress
            persistRecoverySnapshot()
            deliverDialogue(
                external: cycle.externalDialogue,
                internal: cycle.internalDialogue,
                note: cycle.dialogueNote
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
        let delay = delayNanoseconds ?? 180_000_000

        listeningRestartTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: delay)
            guard !Task.isCancelled, self.voiceLoopEnabled, !self.isAgentSpeaking, self.status != .running else { return }

            if self.isRecordingMission {
                self.missionTranscriber.resumeSegmentDelivery()
                self.recordingStatusMessage = "Listening continuously. Pause to start x-maxx."
                self.updateVoiceFlow(
                    state: .listening,
                    title: self.status == .running ? "Listening for steering" : "Listening for mission",
                    detail: self.status == .running
                        ? "The loop is live again. Your next pause will commit fresh steering."
                        : "The mic is live again. Your next pause will commit the mission text.",
                    transcript: nil
                )
            } else {
                self.beginMissionListening()
            }
        }
    }

    private func deliverDialogue(
        external: String,
        internal internalText: String,
        note: String? = nil
    ) {
        print("Delivering dialogue at \(Date())")
        recordComputerDialogue(external: external, internal: internalText, note: note)

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
        updateVoiceFlow(
            state: .speaking,
            title: "Agent speaking",
            detail: "Your last captured speech is already in the loop. Playback is happening now and the mic resumes right after.",
            transcript: nil
        )

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
                afterNanoseconds: 120_000_000,
                suppressingPlaybackEchoFrom: spokenText
            )

            if self.status == .running {
                self.recordingStatusMessage = "Guided loop running. Mic is active for steering. Pause to inject guidance."
                self.updateVoiceFlow(
                    state: .listening,
                    title: "Listening for steering",
                    detail: "Playback finished. Your next pause will commit fresh steering into the running loop.",
                    transcript: nil
                )
            } else {
                self.recordingStatusMessage = "Listening continuously. Pause to start x-maxx."
                self.updateVoiceFlow(
                    state: .listening,
                    title: "Listening for mission",
                    detail: "Playback finished. Your next pause will commit the current mission text into the loop.",
                    transcript: nil
                )
            }
        }
    }

    private func updateVoiceFlow(
        state: VoiceFlowState,
        title: String,
        detail: String,
        transcript: String?,
        clearTranscript: Bool = false
    ) {
        voiceFlowState = state
        voiceFlowTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        voiceFlowDetail = detail.trimmingCharacters(in: .whitespacesAndNewlines)

        if clearTranscript {
            voiceFlowTranscript = ""
        } else if let transcript {
            voiceFlowTranscript = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    private func updateLiveVoiceDraft(transcript: String, detail: String) {
        let trimmedTranscript = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDetail = detail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTranscript.isEmpty else { return }

        if
            let activeVoiceDraftMessageID,
            let index = conversationEntries.firstIndex(where: { $0.id == activeVoiceDraftMessageID })
        {
            conversationEntries[index].text = trimmedTranscript
            conversationEntries[index].detail = trimmedDetail
            conversationEntries[index].state = .live
            return
        }

        let message = ConversationMessage(
            speaker: .user,
            text: trimmedTranscript,
            detail: trimmedDetail,
            state: .live
        )
        appendConversationEntry(message)
        activeVoiceDraftMessageID = message.id
    }

    private func finalizeVoiceDraft(
        transcript: String,
        detail: String,
        state: ConversationMessageState
    ) {
        let trimmedTranscript = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDetail = detail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTranscript.isEmpty else {
            discardLiveVoiceDraftIfNeeded()
            return
        }

        if
            let activeVoiceDraftMessageID,
            let index = conversationEntries.firstIndex(where: { $0.id == activeVoiceDraftMessageID })
        {
            conversationEntries[index].text = trimmedTranscript
            conversationEntries[index].detail = trimmedDetail
            conversationEntries[index].state = state
            self.activeVoiceDraftMessageID = nil
            return
        }

        appendConversationEntry(
            ConversationMessage(
                speaker: .user,
                text: trimmedTranscript,
                detail: trimmedDetail,
                state: state
            )
        )
        activeVoiceDraftMessageID = nil
    }

    private func discardLiveVoiceDraftIfNeeded() {
        guard let activeVoiceDraftMessageID else { return }
        defer { self.activeVoiceDraftMessageID = nil }

        guard let index = conversationEntries.firstIndex(where: { $0.id == activeVoiceDraftMessageID }) else {
            return
        }

        if conversationEntries[index].state == .live {
            conversationEntries.remove(at: index)
        }
    }

    private func recordComputerDialogue(
        external: String,
        internal internalText: String,
        note: String? = nil
    ) {
        externalDialogText = external.trimmingCharacters(in: .whitespacesAndNewlines)
        internalDialogText = internalText.trimmingCharacters(in: .whitespacesAndNewlines)

        let visibleText = externalDialogText.isEmpty ? internalDialogText : externalDialogText
        guard !visibleText.isEmpty else { return }

        let resolvedDetail: String?
        if let note {
            let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
            resolvedDetail = trimmedNote.isEmpty ? nil : trimmedNote
        } else if !internalDialogText.isEmpty, internalDialogText != visibleText {
            resolvedDetail = internalDialogText
        } else {
            resolvedDetail = nil
        }

        appendConversationEntry(
            ConversationMessage(
                speaker: .computer,
                text: visibleText,
                detail: resolvedDetail,
                state: .delivered
            )
        )
    }

    private func appendConversationEntry(_ message: ConversationMessage) {
        conversationEntries.append(message)
        if conversationEntries.count > 48 {
            conversationEntries = Array(conversationEntries.suffix(48))
        }
    }

    private func executeActions(_ actions: [ActionItem]) async -> [ActionItem] {
        print("Executing actions at \(Date())")
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
        if let operatorMessage, !operatorMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return operatorMessage
        }

        let actionTitles = actions.prefix(2).map(\.title).joined(separator: ", ")

        guard !actionTitles.isEmpty else {
            return "Cycle \(iteration). \(summary)"
        }

        return "Cycle \(iteration). \(summary) Next I will handle \(actionTitles)."
    }

    var internalDialogue: String {
        if let internalMessage, !internalMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return internalMessage
        }

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

    var dialogueNote: String? {
        let trimmedNote = decisionNote?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmedNote.isEmpty ? nil : trimmedNote
    }
}

extension AppStore {
    static func bootstrapConversationEntries(
        mission: String,
        operatorFeedback: String
    ) -> [ConversationMessage] {
        let hasDraft = !mission.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            !operatorFeedback.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        let text = hasDraft
            ? "Draft restored at startup. Continue it immediately, or press New Session to clear it."
            : "New session ready. Speak or type the mission to begin."
        let detail = hasDraft
            ? "The app recognized an existing mission or steering draft when it launched."
            : "No prior dialog is active yet."

        return [
            ConversationMessage(
                speaker: .system,
                text: text,
                detail: detail,
                state: .noted
            )
        ]
    }

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
    let operatorMessage: String
    let internalMessage: String
    let needsOperatorInput: Bool
    let operatorQuestion: String?
    let decisionTrace: DecisionTraceResponse
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
        decisionProfile: DecisionProfile,
        loadedSkills: [LoadedSkill]
    ) async throws -> GeneratedLoop {
        guard let url = URL(string: "https://api.openai.com/v1/responses") else {
            throw OpenAIClientError.invalidRequest
        }

        let stagePrompt = decisionProfile.stages.map { stage in
            "- \(stage.phase.rawValue) => \(stage.title): \(stage.shortLabel) \(stage.instruction)"
        }.joined(separator: "\n")
        let skillPrompt = makeSkillPrompt(from: loadedSkills)

        let systemPrompt = """
        You are the planning core for xmaxx, a live macOS desktop copilot.
        Return JSON only and match the requested schema exactly.
        Use grounded reasoning. If information is missing, say that directly instead of inventing facts.
        Goal: maximize progress toward objective x, where x is the user's mission.
        Produce one decisive guided cycle, not generic strategy commentary.
        Treat operator feedback as live steering from the human. If it changes priorities, constraints, or desired direction, adapt immediately in the next iteration instead of continuing the old plan.
        Keep the loop steerable: prefer small, reversible next moves over long speculative plans when live steering is present.
        Detect navigation loops explicitly. If the same action or blocker is repeating without meaningful progress, ask for operator direction or recommend stopping instead of continuing the same pattern.
        Every narrative field must reference the actual mission, environment, operator feedback, or prior runtime outputs.
        If the mission or latest steering is ambiguous, set needs_operator_input true, put the exact question in operator_question, and explain in decision_trace why that answer is needed now.
        operator_message is what xmaxx should say out loud to the human right now.
        internal_message is xmaxx's terse private reasoning note for the app log.
        Active decision model surface: \(decisionProfile.title).
        Selected model lenses: \(decisionProfile.selectedModelLine).
        \(decisionProfile.promptContext)
        Structure the reasoning around these five internal JSON keys for this run:
        \(stagePrompt)

        Required JSON shape:
        {
          "summary": "string",
          "operator_message": "string",
          "internal_message": "string",
          "progress": 0.0,
          "objective_met": false,
          "blocked": false,
          "blocker": "string or null",
          "needs_operator_input": false,
          "operator_question": "string or null",
          "decision_trace": {
            "situation": "string",
            "intent": "string",
            "why_now": "string",
            "risk": "string",
            "success_signal": "string"
          },
          "observe": { "headline": "string", "narrative": "string", "bullets": ["string"], "confidence": 0.0 },
          "orient": { "headline": "string", "narrative": "string", "bullets": ["string"], "confidence": 0.0 },
          "decide": { "headline": "string", "narrative": "string", "bullets": ["string"], "confidence": 0.0 },
          "act": { "headline": "string", "narrative": "string", "bullets": ["string"], "confidence": 0.0 },
          "guide": { "headline": "string", "narrative": "string", "bullets": ["string"], "confidence": 0.0 },
          "actions": [
            { "title": "string", "tool": "string", "target": "string", "rationale": "string", "status": "queued|ready|blocked|done", "x": 0.0, "y": 0.0 }
          ]
        }

        Keep bullets concise. Prefer 2 to 4 bullets per section and 1 to 5 actions total.
        Set "objective_met" true only when the objective is actually achieved within the known context.
        Set "blocked" true only when the next step cannot proceed without missing tooling, permissions, or new human input.
        If "blocked" is false, set "blocker" to null.
        If "needs_operator_input" is false, set "operator_question" to null.
        If "needs_operator_input" is true, ask one concrete question, keep it short, and avoid pretending the answer is already known.
        "progress" must be a number from 0.0 to 1.0 showing estimated distance closed toward the mission.
        Available executable tools right now are mouse_move, mouse_click, mouse_right_click, and find_screen_text.
        You may also return shell_command as a planning-only action. When you use shell_command, put the exact CLI command string in target and prefer queued status because the current macOS build does not auto-execute shell commands yet.
        find_screen_text captures a fresh screenshot, OCRs visible text, and returns the center coordinates of matching visible text.
        When you choose mouse_move, mouse_click, or mouse_right_click, include absolute screen coordinates in x and y when they are known.
        If exact coordinates are not known but the click target is visible text on screen, you may omit x and y and set target to the exact text so the runtime can resolve coordinates from a fresh screenshot.
        A real automation executor exists for those mouse tools. Do not claim automation is unavailable when coordinates or searchable visible text and Accessibility permission are available.
        Only mark the loop blocked for automation when coordinates are missing, Accessibility permission is missing, or a real tool execution error occurs.
        Treat prior action outputs as ground truth. Do not repeat the same blocked action with the same target unless the new cycle explains what changed.
        Actions must be in execution order. Mark only the immediate next executable step as ready. Keep downstream or contingent steps queued.
        Mouse movement for navigation/probing is low risk. Reserve approval-worthy steps for meaningful clicks, destructive changes, or cases where human direction is genuinely needed.
        \(skillPrompt)
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

        Produce the next guided cycle for this app. This is a macOS desktop copilot dashboard. It can plan through ChatGPT, it has a limited real automation executor for coordinate-based mouse actions, and it can resolve coordinates from screenshots when the target is visible text and Screen Recording permission is granted.
        Make the output useful, specific, and honest about gaps. Push the loop forward instead of repeating generic advice. Assume operator feedback may have arrived while the cycle was already running, and give it priority over stale earlier plans.
        Choose the best immediate move, explain why it is the best immediate move, and give xmaxx a speakable operator_message.
        """

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30.0
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
            text: .init(format: .init(
                type: "json_schema",
                name: "xmaxx_guided_cycle",
                strict: true,
                schema: LoopResponse.jsonSchema
            ))
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
            operatorMessage: loopResponse.operatorMessage,
            internalMessage: loopResponse.internalMessage,
            needsOperatorInput: loopResponse.needsOperatorInput,
            operatorQuestion: loopResponse.operatorQuestion,
            decisionTrace: loopResponse.decisionTrace,
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

    private func makeSkillPrompt(from loadedSkills: [LoadedSkill]) -> String {
        guard !loadedSkills.isEmpty else {
            return """
            No external markdown CLI skills are currently loaded.
            """
        }

        var remainingBudget = 12_000
        var skillBlocks: [String] = []

        for skill in loadedSkills {
            guard remainingBudget > 0 else { break }

            let sanitizedContent = skill.content
                .replacingOccurrences(of: "\r\n", with: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let truncatedContent = String(sanitizedContent.prefix(min(remainingBudget, 2_400)))
            let block = """
            Skill: \(skill.title)
            File: \(skill.fileName)
            Summary: \(skill.summary)
            Markdown guidance:
            \(truncatedContent)
            """
            skillBlocks.append(block)
            remainingBudget -= block.count
        }

        let skillCount = loadedSkills.count
        let skillWord = skillCount == 1 ? "skill" : "skills"

        return """
        Loaded CLI skills:
        - \(skillCount) markdown \(skillWord) are available below.
        - These skills are documentation, not executables. They describe how external CLI programs can be called.
        - When a skill is relevant, follow its documented invocation pattern and emit the exact CLI in a shell_command action target.
        - Do not invent undocumented flags, subcommands, or skill behavior.

        \(skillBlocks.joined(separator: "\n\n"))
        """
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
    private let silenceCommitDelayNanoseconds: UInt64 = 320_000_000
    private let playbackEchoFilterDuration: TimeInterval = 0.7
    private let voiceActivityFloor: Float = 0.003
    private let voiceActivityPeakFloor: Float = 0.015
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
    private var lastSpeechActivityNanoseconds: UInt64 = 0
    private var currentUtterancePCM = Data()
    private var currentUtteranceSampleRate: Double = 16_000
    private var currentUtteranceChannelCount: UInt16 = 1

    func start(
        captureAudioForAnalysis: Bool,
        initialText: String,
        onUpdate: @escaping @Sendable (String) -> Void,
        onFinal: @escaping @Sendable (MissionCapture) -> Void
    ) async throws {
        let startTime = Date()
        print("Speech recognition start initiated at \(startTime)")

        guard let recognizer else {
            throw MissionTranscriberError.unavailable
        }

        guard recognizer.isAvailable else {
            throw MissionTranscriberError.unavailable
        }

        print("Recognizer available, requesting speech auth at \(Date().timeIntervalSince(startTime))s")
        let speechStatus = await requestSpeechAuthorization()
        print("Speech auth completed at \(Date().timeIntervalSince(startTime))s, status: \(speechStatus)")
        guard speechStatus == .authorized else {
            throw MissionTranscriberError.speechPermissionDenied
        }

        print("Requesting mic permission at \(Date().timeIntervalSince(startTime))s")
        let microphoneGranted = await requestMicrophonePermission()
        print("Mic permission completed at \(Date().timeIntervalSince(startTime))s, granted: \(microphoneGranted)")
        guard microphoneGranted else {
            throw MissionTranscriberError.microphonePermissionDenied
        }

        print("Stopping previous session at \(Date().timeIntervalSince(startTime))s")
        stop()
        lastTranscript = ""
        lastRecognitionEmission = ""
        didCaptureSpeech = false
        self.captureAudioForAnalysis = captureAudioForAnalysis
        updateHandler = onUpdate
        finalHandler = onFinal
        lastSpeechActivityNanoseconds = 0

        print("Setting up audio engine at \(Date().timeIntervalSince(startTime))s")
        let inputNode = audioEngine.inputNode
        let format = inputNode.inputFormat(forBus: 0)
        print(
            """
            Input tap format resolved at \(Date().timeIntervalSince(startTime))s: \
            \(Int(format.channelCount)) ch, \(format.sampleRate) Hz, \(format.commonFormat.rawValue)
            """
        )
        currentUtteranceSampleRate = format.sampleRate
        currentUtteranceChannelCount = UInt16(max(1, min(format.channelCount, UInt32(UInt16.max))))
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
            self?.captureAudioBufferIfNeeded(buffer)
        }

        print("Preparing audio engine at \(Date().timeIntervalSince(startTime))s")
        audioEngine.prepare()
        print("Starting audio engine at \(Date().timeIntervalSince(startTime))s")
        try audioEngine.start()
        print("Audio engine started at \(Date().timeIntervalSince(startTime))s")

        isRunning = true
        isSegmentDeliveryEnabled = true
        playbackEchoReference = ""
        playbackEchoDeadline = .distantPast
        _ = initialText
        print("Starting recognition session at \(Date().timeIntervalSince(startTime))s")
        startRecognitionSession()
        print("Speech recognition fully started at \(Date().timeIntervalSince(startTime))s")
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
        lastSpeechActivityNanoseconds = 0
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
        lastSpeechActivityNanoseconds = 0
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
        lastSpeechActivityNanoseconds = 0

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

    private func scheduleSilenceCommit() {
        silenceCommitTask?.cancel()

        silenceCommitTask = Task { [weak self] in
            guard let self else { return }

            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: self.silenceCommitDelayNanoseconds)
                guard !Task.isCancelled, self.isRunning else { return }

                let now = DispatchTime.now().uptimeNanoseconds
                let lastSpeechActivity = self.lastSpeechActivityNanoseconds
                let silenceDuration = now > lastSpeechActivity ? now - lastSpeechActivity : self.silenceCommitDelayNanoseconds

                guard silenceDuration >= self.silenceCommitDelayNanoseconds else { continue }

                let fallback = self.lastTranscript.isEmpty ? self.lastRecognitionEmission : self.lastTranscript
                self.finishCurrentUtterance(withFallback: fallback)
                self.restartRecognitionSession()
                return
            }
        }
    }

    private func startRecognitionSession() {
        guard let recognizer, isRunning else { return }

        recognitionSessionVersion &+= 1
        let sessionVersion = recognitionSessionVersion

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
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
            print("Speech recognition error: \(error.localizedDescription)")
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
            noteSpeechActivity()
            updateHandler?(transcript)
            if shouldRescheduleSilenceCommit || silenceCommitTask == nil {
                scheduleSilenceCommit()
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
        lastSpeechActivityNanoseconds = 0
        audioCaptureQueue.sync {
            currentUtterancePCM.removeAll(keepingCapacity: false)
        }
    }

    private func captureAudioBufferIfNeeded(_ buffer: AVAudioPCMBuffer) {
        if containsSpeechEnergy(in: buffer) {
            noteSpeechActivity()
        }

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

    private func noteSpeechActivity() {
        lastSpeechActivityNanoseconds = DispatchTime.now().uptimeNanoseconds
    }

    private func containsSpeechEnergy(in buffer: AVAudioPCMBuffer) -> Bool {
        guard isSegmentDeliveryEnabled, buffer.frameLength > 0 else { return false }

        let frameCount = Int(buffer.frameLength)

        if let floatChannelData = buffer.floatChannelData {
            let source = floatChannelData[0]
            var totalMagnitude: Float = 0
            var peak: Float = 0

            for index in 0..<frameCount {
                let sample = abs(source[index])
                totalMagnitude += sample
                peak = max(peak, sample)
            }

            let averageMagnitude = totalMagnitude / Float(frameCount)
            return averageMagnitude >= voiceActivityFloor || peak >= voiceActivityPeakFloor
        }

        if let int16ChannelData = buffer.int16ChannelData {
            let source = int16ChannelData[0]
            var totalMagnitude: Float = 0
            var peak: Float = 0

            for index in 0..<frameCount {
                let sample = Float(source[index].magnitude) / Float(Int16.max)
                totalMagnitude += sample
                peak = max(peak, sample)
            }

            let averageMagnitude = totalMagnitude / Float(frameCount)
            return averageMagnitude >= voiceActivityFloor || peak >= voiceActivityPeakFloor
        }

        if let int32ChannelData = buffer.int32ChannelData {
            let source = int32ChannelData[0]
            var totalMagnitude: Float = 0
            var peak: Float = 0

            for index in 0..<frameCount {
                let sample = Float(source[index].magnitude) / Float(Int32.max)
                totalMagnitude += sample
                peak = max(peak, sample)
            }

            let averageMagnitude = totalMagnitude / Float(frameCount)
            return averageMagnitude >= voiceActivityFloor || peak >= voiceActivityPeakFloor
        }

        return false
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
            return "Speech recognition permission was denied. Enable xmaxx in System Settings > Privacy & Security > Speech Recognition."
        case .microphonePermissionDenied:
            return "Microphone permission was denied. Enable xmaxx in System Settings > Privacy & Security > Microphone."
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
        print("Starting speech synthesis at \(Date())")
        let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedText.isEmpty else { return }

        stopCurrentPlayback()

        if let elevenLabsAPIKey, !elevenLabsAPIKey.isEmpty {
            do {
                let audioData = try await elevenLabsClient.synthesize(text: cleanedText, apiKey: elevenLabsAPIKey)
                audioPlayer = try AVAudioPlayer(data: audioData)
                audioPlayer?.delegate = self
                guard let audioPlayer else {
                    throw ElevenLabsError.invalidAudioData
                }

                audioPlayer.prepareToPlay()
                guard audioPlayer.play() else {
                    self.audioPlayer = nil
                    throw ElevenLabsError.playbackFailed
                }

                await waitForPlaybackToFinish()
                print("Speech synthesis completed at \(Date())")
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
        print("Speech synthesis completed at \(Date())")
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

    nonisolated static func isSpeechRecognitionGranted() -> Bool {
        SFSpeechRecognizer.authorizationStatus() == .authorized
    }

    nonisolated static func isMicrophoneGranted() -> Bool {
        AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
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

    nonisolated static func requestSpeechRecognitionAccessIfNeeded() async -> Bool {
        if isSpeechRecognitionGranted() {
            return true
        }

        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    nonisolated static func requestMicrophoneAccessIfNeeded() async -> Bool {
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

        let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type")?.lowercased() ?? ""
        let isExpectedAudioType = contentType.isEmpty
            || contentType.contains("audio/")
            || contentType.contains("application/octet-stream")
        guard isExpectedAudioType else {
            throw ElevenLabsError.invalidAudioData
        }

        guard !data.isEmpty else {
            throw ElevenLabsError.invalidAudioData
        }

        return data
    }
}

private enum ElevenLabsError: LocalizedError {
    case invalidRequest
    case invalidResponse
    case network(URLError)
    case apiError(String)
    case invalidAudioData
    case playbackFailed

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
        case .invalidAudioData:
            return "ElevenLabs returned audio data that macOS could not play."
        case .playbackFailed:
            return "macOS could not start playback for the ElevenLabs response."
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
        let name: String?
        let strict: Bool?
        let schema: JSONValue?
    }
}

private enum JSONValue: Encodable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case array([JSONValue])
    case object([String: JSONValue])
    case null

    func encode(to encoder: Encoder) throws {
        switch self {
        case let .string(value):
            var container = encoder.singleValueContainer()
            try container.encode(value)
        case let .number(value):
            var container = encoder.singleValueContainer()
            try container.encode(value)
        case let .bool(value):
            var container = encoder.singleValueContainer()
            try container.encode(value)
        case let .array(values):
            var container = encoder.unkeyedContainer()
            for value in values {
                try container.encode(value)
            }
        case let .object(dictionary):
            var container = encoder.container(keyedBy: DynamicCodingKey.self)
            for key in dictionary.keys.sorted() {
                guard let codingKey = DynamicCodingKey(stringValue: key) else { continue }
                try container.encode(dictionary[key], forKey: codingKey)
            }
        case .null:
            var container = encoder.singleValueContainer()
            try container.encodeNil()
        }
    }
}

private struct DynamicCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
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
    let operatorMessage: String
    let internalMessage: String
    let progress: Double
    let objectiveMet: Bool
    let blocked: Bool
    let blocker: String?
    let needsOperatorInput: Bool
    let operatorQuestion: String?
    let decisionTrace: DecisionTraceResponse
    let observe: LoopSectionResponse
    let orient: LoopSectionResponse
    let decide: LoopSectionResponse
    let act: LoopSectionResponse
    let guide: LoopSectionResponse
    let actions: [LoopActionResponse]

    enum CodingKeys: String, CodingKey {
        case summary
        case operatorMessage = "operator_message"
        case internalMessage = "internal_message"
        case progress
        case objectiveMet = "objective_met"
        case blocked
        case blocker
        case needsOperatorInput = "needs_operator_input"
        case operatorQuestion = "operator_question"
        case decisionTrace = "decision_trace"
        case observe
        case orient
        case decide
        case act
        case guide
        case actions
    }

    static let jsonSchema: JSONValue = {
        let sectionSchema: JSONValue = .object([
            "type": .string("object"),
            "additionalProperties": .bool(false),
            "properties": .object([
                "headline": .object(["type": .string("string"), "minLength": .number(1)]),
                "narrative": .object(["type": .string("string"), "minLength": .number(1)]),
                "bullets": .object([
                    "type": .string("array"),
                    "items": .object(["type": .string("string")]),
                    "minItems": .number(1),
                    "maxItems": .number(4)
                ]),
                "confidence": .object([
                    "type": .string("number"),
                    "minimum": .number(0),
                    "maximum": .number(1)
                ])
            ]),
            "required": .array([
                .string("headline"),
                .string("narrative"),
                .string("bullets"),
                .string("confidence")
            ])
        ])

        let actionSchema: JSONValue = .object([
            "type": .string("object"),
            "additionalProperties": .bool(false),
            "properties": .object([
                "title": .object(["type": .string("string"), "minLength": .number(1)]),
                "tool": .object(["type": .string("string"), "minLength": .number(1)]),
                "target": .object(["type": .string("string")]),
                "rationale": .object(["type": .string("string"), "minLength": .number(1)]),
                "status": .object([
                    "type": .string("string"),
                    "enum": .array([.string("queued"), .string("ready"), .string("blocked"), .string("done")])
                ]),
                "x": .object(["type": .array([.string("number"), .string("null")])]),
                "y": .object(["type": .array([.string("number"), .string("null")])])
            ]),
            "required": .array([
                .string("title"),
                .string("tool"),
                .string("target"),
                .string("rationale"),
                .string("status"),
                .string("x"),
                .string("y")
            ])
        ])

        return .object([
            "type": .string("object"),
            "additionalProperties": .bool(false),
            "properties": .object([
                "summary": .object(["type": .string("string"), "minLength": .number(1)]),
                "operator_message": .object(["type": .string("string"), "minLength": .number(1)]),
                "internal_message": .object(["type": .string("string"), "minLength": .number(1)]),
                "progress": .object([
                    "type": .string("number"),
                    "minimum": .number(0),
                    "maximum": .number(1)
                ]),
                "objective_met": .object(["type": .string("boolean")]),
                "blocked": .object(["type": .string("boolean")]),
                "blocker": .object(["type": .array([.string("string"), .string("null")])]),
                "needs_operator_input": .object(["type": .string("boolean")]),
                "operator_question": .object(["type": .array([.string("string"), .string("null")])]),
                "decision_trace": .object([
                    "type": .string("object"),
                    "additionalProperties": .bool(false),
                    "properties": .object([
                        "situation": .object(["type": .string("string"), "minLength": .number(1)]),
                        "intent": .object(["type": .string("string"), "minLength": .number(1)]),
                        "why_now": .object(["type": .string("string"), "minLength": .number(1)]),
                        "risk": .object(["type": .string("string"), "minLength": .number(1)]),
                        "success_signal": .object(["type": .string("string"), "minLength": .number(1)])
                    ]),
                    "required": .array([
                        .string("situation"),
                        .string("intent"),
                        .string("why_now"),
                        .string("risk"),
                        .string("success_signal")
                    ])
                ]),
                "observe": sectionSchema,
                "orient": sectionSchema,
                "decide": sectionSchema,
                "act": sectionSchema,
                "guide": sectionSchema,
                "actions": .object([
                    "type": .string("array"),
                    "items": actionSchema,
                    "minItems": .number(1),
                    "maxItems": .number(5)
                ])
            ]),
            "required": .array([
                .string("summary"),
                .string("operator_message"),
                .string("internal_message"),
                .string("progress"),
                .string("objective_met"),
                .string("blocked"),
                .string("blocker"),
                .string("needs_operator_input"),
                .string("operator_question"),
                .string("decision_trace"),
                .string("observe"),
                .string("orient"),
                .string("decide"),
                .string("act"),
                .string("guide"),
                .string("actions")
            ])
        ])
    }()
}

private struct DecisionTraceResponse: Decodable {
    let situation: String
    let intent: String
    let whyNow: String
    let risk: String
    let successSignal: String

    enum CodingKeys: String, CodingKey {
        case situation
        case intent
        case whyNow = "why_now"
        case risk
        case successSignal = "success_signal"
    }

    var note: String {
        [
            "Situation: \(situation)",
            "Intent: \(intent)",
            "Why now: \(whyNow)",
            "Risk: \(risk)",
            "Success signal: \(successSignal)"
        ].joined(separator: "\n")
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
