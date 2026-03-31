//
//  AppStore.swift
//  xmaxx
//
//  Created by Codex on 3/30/26.
//

import Combine
import Foundation
import Security
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

@MainActor
final class AppStore: ObservableObject {
    @Published var profileName: String
    @Published var chatGPTAPIKey: String
    @Published var elevenLabsAPIKey: String
    @Published var audioResponsesEnabled: Bool
    @Published var missionText: String
    @Published var environmentText: String
    @Published var isRecordingMission: Bool
    @Published var voiceLoopEnabled: Bool
    @Published var recordingStatusMessage: String
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

    private let profileNameKey = "profileName"
    private let chatGPTAPIKeyKey = "chatGPTAPIKey"
    private let elevenLabsAPIKeyKey = "elevenLabsAPIKey"
    private let audioResponsesEnabledKey = "audioResponsesEnabled"
    private let missionTextKey = "missionText"
    private let environmentTextKey = "environmentText"
    private let operatorFeedbackKey = "operatorFeedback"
    private let maxIterationsKey = "maxIterations"
    private let voiceLoopEnabledKey = "voiceLoopEnabled"
    private var loopTask: Task<Void, Never>?
    private var listeningRestartTask: Task<Void, Never>?
    private let speechCoordinator = SpeechCoordinator()
    private let missionTranscriber = MissionTranscriber()

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        let storedProfileName = userDefaults.string(forKey: profileNameKey) ?? ""
        let storedMissionText = userDefaults.string(forKey: missionTextKey) ?? "Build a desktop computer-use copilot around the OODA loop."
        let storedEnvironmentText = userDefaults.string(forKey: environmentTextKey) ?? """
        Current app shell is a macOS dashboard. We have profile and API key settings, but no live screen capture, automation executor, or tool bridge yet.
        """
        let storedOperatorFeedback = userDefaults.string(forKey: operatorFeedbackKey) ?? ""
        let storedMaxIterations = max(1, userDefaults.integer(forKey: maxIterationsKey))
        let storedVoiceLoopEnabled = userDefaults.object(forKey: voiceLoopEnabledKey) as? Bool ?? false
        var storedAPIKey = keychain.read(account: chatGPTAPIKeyKey) ?? ""
        var storedElevenLabsAPIKey = keychain.read(account: elevenLabsAPIKeyKey) ?? ""
        let storedAudioResponsesEnabled = userDefaults.object(forKey: audioResponsesEnabledKey) as? Bool ?? false

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

        profileName = storedProfileName
        missionText = storedMissionText
        environmentText = storedEnvironmentText
        chatGPTAPIKey = storedAPIKey
        elevenLabsAPIKey = storedElevenLabsAPIKey
        audioResponsesEnabled = storedAudioResponsesEnabled
        operatorFeedback = storedOperatorFeedback
        isRecordingMission = false
        voiceLoopEnabled = storedVoiceLoopEnabled
        recordingStatusMessage = "Ready to capture the mission from audio."
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

    func updateSettings(profileName: String, chatGPTAPIKey: String) {
        updateSettings(
            profileName: profileName,
            chatGPTAPIKey: chatGPTAPIKey,
            elevenLabsAPIKey: elevenLabsAPIKey,
            audioResponsesEnabled: audioResponsesEnabled
        )
    }

    func updateSettings(
        profileName: String,
        chatGPTAPIKey: String,
        elevenLabsAPIKey: String,
        audioResponsesEnabled: Bool
    ) {
        self.profileName = profileName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.chatGPTAPIKey = chatGPTAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        self.elevenLabsAPIKey = elevenLabsAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        self.audioResponsesEnabled = audioResponsesEnabled

        userDefaults.set(self.profileName, forKey: profileNameKey)
        userDefaults.set(self.audioResponsesEnabled, forKey: audioResponsesEnabledKey)

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

    func runOODALoop(preserveVoiceLoop: Bool = false) {
        pauseMissionRecordingForProcessing()
        loopTask?.cancel()
        persistWorkspaceDraft()

        let trimmedMission = missionText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEnvironment = environmentText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedOperatorFeedback = operatorFeedback.trimmingCharacters(in: .whitespacesAndNewlines)

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

    func stopLoop() {
        loopTask?.cancel()
        loopTask = nil

        if status == .running {
            status = .stopped
            statusMessage = "Loop stopped by operator."
            speak("Loop stopped by operator.")
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
        guard voiceLoopEnabled, !isRecordingMission, status != .running else { return }
        listeningRestartTask?.cancel()

        Task {
            do {
                let store = self
                let currentMission = missionText
                try await missionTranscriber.start(
                    initialText: currentMission,
                    onUpdate: { transcript in
                        Task { @MainActor in
                            store.missionText = transcript
                        }
                    },
                    onFinal: { transcript in
                        Task { @MainActor in
                            store.isRecordingMission = false
                            let trimmedTranscript = transcript.trimmingCharacters(in: .whitespacesAndNewlines)

                            if !trimmedTranscript.isEmpty {
                                store.missionText = trimmedTranscript
                                store.recordingStatusMessage = "Mission captured. Running x-maxx."
                                store.runOODALoop(preserveVoiceLoop: true)
                            } else {
                                store.recordingStatusMessage = "No mission detected. Still listening."
                                store.scheduleMissionListeningRestartIfNeeded(delayNanoseconds: 300_000_000)
                            }
                        }
                    }
                )

                isRecordingMission = true
                recordingStatusMessage = "Listening for the mission. Stop speaking and I will calculate."
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
        let trimmedMission = missionText.trimmingCharacters(in: .whitespacesAndNewlines)
        recordingStatusMessage = trimmedMission.isEmpty ? "Ready to capture the mission from audio." : "Mission captured from audio."
    }

    private func pauseMissionRecordingForProcessing() {
        missionTranscriber.stop()
        isRecordingMission = false
        if voiceLoopEnabled {
            recordingStatusMessage = "Processing mission."
        }
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

            let result = try await client.generateOODALoop(
                apiKey: chatGPTAPIKey,
                profileName: profileName,
                mission: mission,
                environment: environment,
                operatorFeedback: operatorFeedback,
                iteration: iteration,
                maxIterations: limit,
                priorCycles: history
            )

            let cycle = OODACycle(
                iteration: iteration,
                createdAt: .now,
                mission: mission,
                environment: environment,
                summary: result.summary,
                model: result.model,
                progress: result.progress,
                objectiveMet: result.objectiveMet,
                isBlocked: result.isBlocked,
                blocker: result.blocker,
                sections: result.sections,
                actions: result.actions
            )

            history.append(cycle)
            sections = cycle.sections
            actionQueue = cycle.actions
            cycles.insert(cycle, at: 0)
            selectedCycleID = cycle.id
            objectiveProgress = cycle.progress
            speak(cycle.spokenSummary)

            if cycle.objectiveMet {
                status = .completed
                statusMessage = cycle.summary
                speak("Objective met. \(cycle.summary)")
                loopTask = nil
                scheduleMissionListeningRestartIfNeeded()
                return
            }

            if cycle.isBlocked {
                status = .blocked
                statusMessage = cycle.blocker ?? cycle.summary
                speak("Loop blocked. \(cycle.blocker ?? cycle.summary)")
                loopTask = nil
                scheduleMissionListeningRestartIfNeeded()
                return
            }

            if iteration == limit {
                status = .stopped
                statusMessage = "Reached iteration limit without meeting the objective."
                speak("Reached the iteration limit before the objective was met.")
                loopTask = nil
                scheduleMissionListeningRestartIfNeeded()
                return
            }
        }
    }

    private func scheduleMissionListeningRestartIfNeeded(delayNanoseconds: UInt64? = nil) {
        guard voiceLoopEnabled else { return }

        listeningRestartTask?.cancel()
        let delay = delayNanoseconds ?? (audioResponsesEnabled ? 4_000_000_000 : 800_000_000)

        listeningRestartTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: delay)
            guard !Task.isCancelled, self.voiceLoopEnabled, self.status != .running else { return }
            self.beginMissionListening()
        }
    }

    private func speak(_ text: String) {
        guard audioResponsesEnabled else { return }

        let elevenLabsAPIKey = self.elevenLabsAPIKey

        Task {
            await speechCoordinator.speak(
                text: text,
                elevenLabsAPIKey: elevenLabsAPIKey.isEmpty ? nil : elevenLabsAPIKey
            )
        }
    }
}

private extension OODACycle {
    var spokenSummary: String {
        let actionTitles = actions.prefix(2).map(\.title).joined(separator: ". ")

        if actionTitles.isEmpty {
            return "Iteration \(iteration). \(summary)"
        }

        return "Iteration \(iteration). \(summary) Next actions: \(actionTitles)."
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
            { "title": "string", "tool": "string", "target": "string", "rationale": "string", "status": "queued|ready|blocked|done" }
          ]
        }

        Keep bullets concise. Prefer 2 to 4 bullets per section and 3 to 6 actions total.
        Set "objective_met" true only when the objective is actually achieved within the known context.
        Set "blocked" true only when the next step cannot proceed without missing tooling, permissions, or new human input.
        "progress" must be a number from 0.0 to 1.0 showing estimated distance closed toward the mission.
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

        Produce the next OODA loop for this app. This is a macOS desktop copilot dashboard. It can plan through ChatGPT, but it does not yet have live screen capture or a real automation executor. Make the output useful, specific, and honest about gaps. Push the loop forward instead of repeating generic advice.
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
                    status: $0.status
                )
            }
        )
    }
}

private final class MissionTranscriber {
    private let audioEngine = AVAudioEngine()
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var lastTranscript = ""

    func start(
        initialText: String,
        onUpdate: @escaping @Sendable (String) -> Void,
        onFinal: @escaping @Sendable (String) -> Void
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
        lastTranscript = initialText.trimmingCharacters(in: .whitespacesAndNewlines)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = false
        }

        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            if let result {
                let transcript = result.bestTranscription.formattedString.trimmingCharacters(in: .whitespacesAndNewlines)
                self?.lastTranscript = transcript
                if transcript.isEmpty {
                    onUpdate(initialText)
                } else {
                    onUpdate(transcript)
                }
            }

            if error != nil || (result?.isFinal ?? false) {
                onFinal(self?.lastTranscript ?? initialText)
                self?.stop()
            }
        }
    }

    func stop() {
        recognitionTask?.cancel()
        recognitionTask = nil

        recognitionRequest?.endAudio()
        recognitionRequest = nil

        if audioEngine.isRunning {
            audioEngine.stop()
        }

        audioEngine.inputNode.removeTap(onBus: 0)
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

@MainActor
private final class SpeechCoordinator {
    private let fallbackSynthesizer = AVSpeechSynthesizer()
    private let elevenLabsClient = ElevenLabsClient()
    private var audioPlayer: AVAudioPlayer?

    func speak(text: String, elevenLabsAPIKey: String?) async {
        let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedText.isEmpty else { return }

        if fallbackSynthesizer.isSpeaking {
            fallbackSynthesizer.stopSpeaking(at: .immediate)
        }
        audioPlayer?.stop()

        if let elevenLabsAPIKey, !elevenLabsAPIKey.isEmpty {
            do {
                let audioData = try await elevenLabsClient.synthesize(text: cleanedText, apiKey: elevenLabsAPIKey)
                audioPlayer = try AVAudioPlayer(data: audioData)
                audioPlayer?.prepareToPlay()
                audioPlayer?.play()
                return
            } catch {
                // Fall through to the macOS system voice when ElevenLabs is unavailable.
            }
        }

        let utterance = AVSpeechUtterance(string: cleanedText)
        utterance.rate = 0.48
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        fallbackSynthesizer.speak(utterance)
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
