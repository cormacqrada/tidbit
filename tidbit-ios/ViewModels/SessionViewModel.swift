import Foundation
import SwiftData

// MARK: - Part of Speech

enum PartOfSpeech {
    case noun, verb, adjective, adverb, other
    
    /// Get part of speech for a word using NSLinguisticTagger
    static func classify(_ word: String) -> PartOfSpeech {
        let tagger = NSLinguisticTagger(tagSchemes: [.lexicalClass], options: 0)
        tagger.string = word
        
        guard let tag = tagger.tag(at: 0, scheme: .lexicalClass, tokenRange: nil, sentenceRange: nil),
              let tagValue = tag.rawValue as? String else {
            return .other
        }
        
        switch tagValue {
        case "noun": return .noun
        case "verb": return .verb
        case "adjective": return .adjective
        case "adverb": return .adverb
        default: return .other
        }
    }
}

// MARK: - Session State

/// Represents an active learning session
struct SessionState: Identifiable {
    let id: UUID
    let lessonId: UUID
    let lessonName: String
    var startTime: Date
    var exerciseQueue: [ExerciseInstance]
    var currentIndex: Int
    var completedExercises: [CompletedExercise]
    var hintUsed: Bool
    
    init(lesson: Lesson, exercises: [ExerciseInstance]) {
        self.id = UUID()
        self.lessonId = lesson.id
        self.lessonName = lesson.name
        self.startTime = Date()
        self.exerciseQueue = exercises
        self.currentIndex = 0
        self.completedExercises = []
        self.hintUsed = false
    }
    
    var currentExercise: ExerciseInstance? {
        guard currentIndex < exerciseQueue.count else { return nil }
        return exerciseQueue[currentIndex]
    }
    
    var progress: Double {
        guard !exerciseQueue.isEmpty else { return 0 }
        return Double(currentIndex) / Double(exerciseQueue.count)
    }
    
    var totalExercises: Int {
        exerciseQueue.count
    }
    
    var completedCount: Int {
        completedExercises.count
    }
    
    var isComplete: Bool {
        currentIndex >= exerciseQueue.count
    }
    
    var score: Double {
        guard !completedExercises.isEmpty else { return 0 }
        return completedExercises.map(\.score).reduce(0, +) / Double(completedExercises.count)
    }
}

// MARK: - Exercise Instance

/// A specific instance of an exercise for a tidbit
struct ExerciseInstance: Identifiable {
    let id: UUID
    let tidbit: Tidbit
    let exerciseType: ExerciseType
    var config: ExerciseConfig
    
    init(tidbit: Tidbit, exerciseType: ExerciseType, config: ExerciseConfig = ExerciseConfig()) {
        self.id = UUID()
        self.tidbit = tidbit
        self.exerciseType = exerciseType
        self.config = config
    }
}

// MARK: - Exercise Config

struct ExerciseConfig {
    var fuzzyThreshold: Double = 0.8
    var hintPolicy: HintPolicy = .always
    var showHint: Bool = false
    var correctAnswer: String? = nil  // For fillBlank exercises, store the specific blanked word
    var blankedIndex: Int = 0        // Index of blanked word in the line
    var distractors: [String] = []  // Static list of distractor words (correct answer + 3 wrong)
    
    static func from(lesson: Lesson) -> ExerciseConfig {
        ExerciseConfig(
            fuzzyThreshold: 0.8,
            hintPolicy: lesson.hintPolicy,
            showHint: false,
            correctAnswer: nil
        )
    }
}

// MARK: - Completed Exercise

struct CompletedExercise: Identifiable {
    let id: UUID
    let exerciseId: UUID
    let tidbitId: UUID
    let exerciseType: ExerciseType
    let score: Double
    let responseTimeMs: Int
    let hintUsed: Bool
    let adaptiveSignal: AdaptiveSignal
    let timestamp: Date
    let userResponse: String
    
    init(
        exercise: ExerciseInstance,
        score: Double,
        responseTimeMs: Int,
        hintUsed: Bool,
        userResponse: String
    ) {
        self.id = UUID()
        self.exerciseId = exercise.id
        self.tidbitId = exercise.tidbit.id
        self.exerciseType = exercise.exerciseType
        self.score = score
        self.responseTimeMs = responseTimeMs
        self.hintUsed = hintUsed
        self.adaptiveSignal = AdaptiveSignal.from(score: score, hintUsed: hintUsed)
        self.timestamp = Date()
        self.userResponse = userResponse
    }
    
    /// Memberwise init for updating with self-reported confidence
    init(
        exerciseId: UUID,
        tidbitId: UUID,
        exerciseType: ExerciseType,
        score: Double,
        responseTimeMs: Int,
        hintUsed: Bool,
        adaptiveSignal: AdaptiveSignal,
        timestamp: Date,
        userResponse: String
    ) {
        self.id = UUID()
        self.exerciseId = exerciseId
        self.tidbitId = tidbitId
        self.exerciseType = exerciseType
        self.score = score
        self.responseTimeMs = responseTimeMs
        self.hintUsed = hintUsed
        self.adaptiveSignal = adaptiveSignal
        self.timestamp = timestamp
        self.userResponse = userResponse
    }
}

// MARK: - Session View Model

@MainActor
@Observable
class SessionViewModel {
    
    // MARK: - State
    
    var session: SessionState?
    var userInput: String = ""
    var showHint: Bool = false
    var isSubmitting: Bool = false
    var lastResult: ValidationResult?
    var showFeedback: Bool = false
    var startTime: Date?
    var sessionStartTime: Date?  // Overall session timer
    var pausedDuration: TimeInterval = 0  // Accumulated paused time
    var pauseStartTime: Date?  // When timer was paused
    var autoAdvanceTask: Task<Void, Never>?  // For auto-advance after correct answer
    
    // Stored for encoding exposure telemetry + scheduler-bypass inserts
    private var modelContext: ModelContext?
    private var currentLesson: Lesson?
    
    // MARK: - Computed
    
    /// Elapsed time since session start (excluding paused time)
    var elapsedTime: TimeInterval {
        guard let sessionStart = sessionStartTime else { return 0 }
        var elapsed = Date().timeIntervalSince(sessionStart) - pausedDuration
        // If currently paused, subtract current pause duration
        if let pauseStart = pauseStartTime {
            elapsed -= Date().timeIntervalSince(pauseStart)
        }
        return max(0, elapsed)
    }
    
    /// Formatted elapsed time string (MM:SS)
    var elapsedTimeString: String {
        let interval = elapsedTime
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Initialization
    
    func startSession(lesson: Lesson, modelContext: ModelContext) {
        // Store for encoding exposure + on-demand insertions
        self.modelContext = modelContext
        self.currentLesson = lesson
        
        // Get tidbits for this lesson
        let tidbits = lesson.tidbits.sorted { $0.sequenceIndex < $1.sequenceIndex }
        
        // Generate exercises based on lesson config
        let exercises = generateExercises(
            tidbits: tidbits,
            exerciseMix: lesson.exerciseMix,
            config: ExerciseConfig.from(lesson: lesson)
        )
        
        session = SessionState(lesson: lesson, exercises: exercises)
        startTime = Date()
        sessionStartTime = Date()
        userInput = ""
        showHint = false
        showFeedback = false
        lastResult = nil
        
        // Prepare fillBlank data for first exercise
        prepareFillBlankData()
    }
    
    // MARK: - Exercise Generation
    
    private func generateExercises(
        tidbits: [Tidbit],
        exerciseMix: [ExerciseWeight],
        config: ExerciseConfig
    ) -> [ExerciseInstance] {
        var exercises: [ExerciseInstance] = []
        
        // For each tidbit, create exercises based on weights
        for tidbit in tidbits {
            for weight in exerciseMix {
                // Skip AI-requiring exercises for free tier
                if weight.type.requiresAI { continue }
                
                // Skip disabled exercises (weight 0)
                if weight.weight == 0 { continue }
                
                // Add exercise with probability based on weight
                // Weight 5 = always include, weight 1 = 20% chance
                let probability = Double(weight.weight) / 5.0
                if Double.random(in: 0...1) < probability {
                    exercises.append(ExerciseInstance(
                        tidbit: tidbit,
                        exerciseType: weight.type,
                        config: config
                    ))
                }
            }
        }
        
        // Sort by cognitive demand (easier first)
        exercises.sort { exerciseTypeOrder($0.exerciseType) < exerciseTypeOrder($1.exerciseType) }
        
        return exercises
    }
    
    private func exerciseTypeOrder(_ type: ExerciseType) -> Int {
        switch type {
        // Encoding first (build the trace before testing it)
        case .chunkedRead: return 0
        case .mnemonicLearn, .imageAnchorRead, .analogyRead: return 1
        case .mnemonicDecode, .imageToConcept, .connectToPrior, .findYourCase: return 2
        // Recall — lower cognitive demand first
        case .fillBlank, .wordFill: return 3
        case .linePrompt: return 4
        case .stanzaReconstruct, .conceptConnect: return 5
        case .evidenceFor: return 5
        case .argumentMap, .applyToCase: return 6
        case .coldOpen: return 7
        case .quickfire: return 8
        case .meaningProbe, .explainBack: return 9
        default: return 5
        }
    }
    
    // MARK: - Actions
    
    func submitAnswer(correctAnswer: String? = nil) {
        guard let exercise = session?.currentExercise else { return }
        
        let responseTimeMs = Int(Date().timeIntervalSince(startTime ?? Date()) * 1000)
        
        // Get the correct answer - use override if provided (for fillBlank)
        let answer = correctAnswer ?? getCorrectAnswer(for: exercise)
        
        // Validate
        let result = ValidationResult(
            input: userInput,
            target: answer,
            threshold: exercise.config.fuzzyThreshold
        )
        
        self.lastResult = result
        self.showFeedback = true
        
        // Record completion
        let completed = CompletedExercise(
            exercise: exercise,
            score: result.score,
            responseTimeMs: responseTimeMs,
            hintUsed: showHint,
            userResponse: userInput
        )
        
        session?.completedExercises.append(completed)
        
        // Auto-advance after correct answer
        if result.passed {
            autoAdvanceTask = Task {
                try? await Task.sleep(for: .seconds(1.0))
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self.nextExercise()
                }
            }
        }
    }
    
    func nextExercise() {
        // Cancel any pending auto-advance
        autoAdvanceTask?.cancel()
        autoAdvanceTask = nil
        
        session?.currentIndex += 1
        session?.hintUsed = false
        userInput = ""
        showHint = false
        showFeedback = false
        lastResult = nil
        startTime = Date()
        
        // Prepare fillBlank data for next exercise
        prepareFillBlankData()
    }
    
    func retryCurrentExercise() {
        // Cancel any pending auto-advance
        autoAdvanceTask?.cancel()
        autoAdvanceTask = nil
        
        // Remove the last completed exercise (the wrong one)
        if session != nil && !session!.completedExercises.isEmpty {
            session!.completedExercises.removeLast()
        }
        
        // Reset state for retry
        session?.hintUsed = false
        userInput = ""
        showHint = false
        showFeedback = false
        lastResult = nil
        startTime = Date()
    }
    
    func reportConfidence(_ level: ConfidenceLevel) {
        // Update the last completed exercise with the self-reported confidence
        guard session != nil, !session!.completedExercises.isEmpty else { return }
        
        // Replace the last exercise with correct adaptive signal
        let lastCompleted = session!.completedExercises.removeLast()
        let signal: AdaptiveSignal
        switch level {
        case .gotIt: signal = .gotIt
        case .struggled: signal = .struggled
        case .skipped: signal = .skipped
        }
        
        let updated = CompletedExercise(
            exerciseId: lastCompleted.exerciseId,
            tidbitId: lastCompleted.tidbitId,
            exerciseType: lastCompleted.exerciseType,
            score: level == .gotIt ? 1.0 : level == .struggled ? 0.7 : 0.3,
            responseTimeMs: lastCompleted.responseTimeMs,
            hintUsed: lastCompleted.hintUsed,
            adaptiveSignal: signal,
            timestamp: lastCompleted.timestamp,
            userResponse: lastCompleted.userResponse
        )
        
        session!.completedExercises.append(updated)
    }
    
    func useHint() {
        showHint = true
        session?.hintUsed = true
    }
    
    // MARK: - Encoding Exposure
    
    /// Record an encoding-mode exposure. Emits telemetry with mode = .encoding and
    /// signal = .exposed. NEVER calls updateLearnerState — encoding does not affect
    /// successRate, nextDue, or phase. Optionally updates LearnerState encoding counters.
    func recordEncodingExposure(for exercise: ExerciseInstance) {
        let event = TelemetryEvent(
            sessionId: session?.id ?? UUID(),
            tidbitId: exercise.tidbit.id,
            templateId: exercise.exerciseType.rawValue,
            learnerId: UUID(),
            responseRaw: "",
            score: 0,
            responseTimeMs: 0,
            hintUsed: false,
            adaptiveSignal: .exposed,
            mode: .encoding
        )
        TelemetryService.log(event: event)
        
        // Update encoding exposure counters on learner state (separate from recall scheduling)
        if let modelContext = self.modelContext {
            updateEncodingCounters(tidbitId: exercise.tidbit.id, technique: exercise.exerciseType.rawValue, modelContext: modelContext)
        }
    }
    
    private func updateEncodingCounters(tidbitId: UUID, technique: String, modelContext: ModelContext) {
        let descriptor = FetchDescriptor<LearnerState>(
            predicate: #Predicate { $0.tidbitId == tidbitId }
        )
        if let state = try? modelContext.fetch(descriptor).first {
            state.encodingExposures += 1
            if !state.encodedTechniques.contains(technique) {
                state.encodedTechniques.append(technique)
            }
        }
    }
    
    // MARK: - Practice This Now (scheduler bypass)
    
    /// Insert a tidbit as the next card in the current session, bypassing the
    /// scheduler. Called from TidbitDetailView's “Practice this now” action.
    func insertTidbitAsNext(_ tidbit: Tidbit, exerciseType: ExerciseType? = nil) {
        guard var session = self.session else { return }
        let type = exerciseType ?? defaultRecallType(for: tidbit.knowledgeDomain)
        let hintPolicy = currentLesson?.hintPolicy ?? .always
        let config = ExerciseConfig(fuzzyThreshold: 0.8, hintPolicy: hintPolicy, showHint: false, correctAnswer: nil)
        let instance = ExerciseInstance(tidbit: tidbit, exerciseType: type, config: config)
        session.exerciseQueue.insert(instance, at: session.currentIndex + 1)
        self.session = session
    }
    
    /// Pick a sensible default recall exercise for a domain when inserting on demand.
    private func defaultRecallType(for domain: KnowledgeDomain) -> ExerciseType {
        ExerciseType.recallExercises(for: domain).first ?? .textRecall
    }
    
    func skip() {
        guard let exercise = session?.currentExercise else { return }
        
        let completed = CompletedExercise(
            exercise: exercise,
            score: 0,
            responseTimeMs: 0,
            hintUsed: false,
            userResponse: ""
        )
        
        session?.completedExercises.append(completed)
        nextExercise()
    }
    
    /// Jump to a specific exercise by index (allows back-and-forth navigation)
    func skipTo(index: Int) {
        guard let session = session, index >= 0, index < session.exerciseQueue.count else { return }
        
        // Cancel any pending auto-advance
        autoAdvanceTask?.cancel()
        autoAdvanceTask = nil
        
        // Jump to target
        self.session?.currentIndex = index
        userInput = ""
        showHint = false
        showFeedback = false
        lastResult = nil
        startTime = Date()
        
        // Prepare fillBlank data for new exercise
        prepareFillBlankData()
    }
    
    /// Skip to the next exercise of a specific type (searches entire array)
    func skipToExerciseType(_ type: ExerciseType) {
        guard let session = session else { return }
        
        // Search from current position forward first
        for i in session.currentIndex..<session.exerciseQueue.count {
            if session.exerciseQueue[i].exerciseType == type {
                skipTo(index: i)
                return
            }
        }
        
        // If not found forward, search from beginning
        for i in 0..<session.currentIndex {
            if session.exerciseQueue[i].exerciseType == type {
                skipTo(index: i)
                return
            }
        }
    }
    
    /// Get unique exercise types in the remaining queue
    var remainingExerciseTypes: [ExerciseType] {
        guard let session = session else { return [] }
        let remaining = session.exerciseQueue[session.currentIndex...]
        return Array(Set(remaining.map { $0.exerciseType })).sorted { $0.displayName < $1.displayName }
    }
    
    // MARK: - Timer Control
    
    func pauseTimer() {
        pauseStartTime = Date()
    }
    
    func resumeTimer() {
        if let pauseStart = pauseStartTime {
            pausedDuration += Date().timeIntervalSince(pauseStart)
        }
        pauseStartTime = nil
    }
    
    func completeSession() {
        // Finalize any pending state
        autoAdvanceTask?.cancel()
        autoAdvanceTask = nil
        
        // Mark session as complete by moving index past the end
        session?.currentIndex = session?.exerciseQueue.count ?? 0
        
        // TODO: Log session completion with duration to storage
        // Session duration available via elapsedTime
    }
    
    // MARK: - Helpers
    
    func getCorrectAnswer(for exercise: ExerciseInstance) -> String {
        // For fillBlank, use the stored correct answer if available
        if exercise.exerciseType == .fillBlank || exercise.exerciseType == .wordFill {
            if let storedAnswer = exercise.config.correctAnswer {
                return storedAnswer
            }
        }
        return exercise.tidbit.body
    }
    
    func getHint(for exercise: ExerciseInstance) -> String {
        let body = exercise.tidbit.body
        switch exercise.config.hintPolicy {
        case .always, .once:
            // Show first letter of each word
            let words = body.components(separatedBy: " ")
            return words.map { $0.first.map(String.init) ?? "" }.joined(separator: " ")
        case .never:
            return "Hints disabled"
        }
    }
    
    // MARK: - Line Prompt Specific
    
    /// Get the cue line (previous line) for line_prompt exercise
    func getCueLine(for exercise: ExerciseInstance) -> String? {
        // For line_prompt, show the previous line as a cue
        guard exercise.exerciseType == .linePrompt else { return nil }
        
        let sequenceIndex = exercise.tidbit.sequenceIndex
        guard sequenceIndex > 0 else { return nil }
        
        // Find previous tidbit - would need access to all tidbits
        // For now, return nil
        return nil
    }
    
    // MARK: - FillBlank Setup
    
    /// Prepare fillBlank exercise data - called when exercise changes
    func prepareFillBlankData() {
        guard let exercise = session?.currentExercise else { return }
        guard exercise.exerciseType == .fillBlank || exercise.exerciseType == .wordFill else { return }
        
        let line = exercise.tidbit.body
        let words = line.components(separatedBy: " ")
        
        // Find a good word to blank (prefer non-trivial words)
        let candidates = words.enumerated().filter { index, word in
            word.count >= 4 && !commonWords.contains(word.lowercased())
        }
        
        let blankedIndex: Int
        let blankedWord: String
        
        if let (index, word) = candidates.randomElement() ?? words.enumerated().first(where: { $0.element.count >= 3 }) {
            blankedIndex = index
            blankedWord = word.trimmingCharacters(in: .punctuationCharacters)
        } else {
            blankedIndex = 0
            blankedWord = words.first ?? ""
        }
        
        // Generate distractors matching part of speech
        var distractors = [blankedWord]
        let targetPOS = PartOfSpeech.classify(blankedWord)
        
        // Get words from all tidbits, grouped by part of speech
        var wordsByPOS: [PartOfSpeech: [String]] = [:]
        
        if let currentSession = session {
            let allTidbitWords = currentSession.exerciseQueue.flatMap { ex in
                ex.tidbit.body.components(separatedBy: " ")
                    .map { $0.trimmingCharacters(in: .punctuationCharacters) }
                    .filter { $0.count >= 3 && !commonWords.contains($0.lowercased()) }
            }
            
            for word in Set(allTidbitWords) {
                let pos = PartOfSpeech.classify(word)
                if pos != .other {
                    wordsByPOS[pos, default: []].append(word)
                }
            }
        }
        
        // Get distractors matching the target word's part of speech
        if let sameTypeWords = wordsByPOS[targetPOS] {
            let matchingDistractors = sameTypeWords
                .filter { $0.lowercased() != blankedWord.lowercased() }
                .shuffled()
                .prefix(3)
            distractors.append(contentsOf: matchingDistractors)
        }
        
        // If not enough matching words, fall back to similar parts of speech
        if distractors.count < 4 {
            let fallbackPOS: [PartOfSpeech] = targetPOS == .noun ? [.noun] :
                                              targetPOS == .verb ? [.verb] :
                                              targetPOS == .adjective ? [.adjective, .adverb] :
                                              targetPOS == .adverb ? [.adverb, .adjective] : []
            
            for pos in fallbackPOS {
                if distractors.count >= 4 { break }
                if let words = wordsByPOS[pos] {
                    let fallbacks = words
                        .filter { $0.lowercased() != blankedWord.lowercased() && !distractors.contains($0) }
                        .shuffled()
                    for word in fallbacks {
                        if distractors.count >= 4 { break }
                        distractors.append(word)
                    }
                }
            }
        }
        
        // Last resort: generic fallback words categorized by type
        if distractors.count < 4 {
            let nounFallbacks = ["Death", "Life", "Time", "Love", "Hope", "Soul", "Heart", "Mind", "Dream", "Night"]
            let verbFallbacks = ["see", "hear", "feel", "know", "think", "come", "go", "stand", "fall", "rise"]
            let adjFallbacks = ["dark", "light", "cold", "warm", "sweet", "bright", "soft", "hard", "deep", "high"]
            
            let fallbackWords = targetPOS == .noun ? nounFallbacks :
                                targetPOS == .verb ? verbFallbacks :
                                targetPOS == .adjective || targetPOS == .adverb ? adjFallbacks :
                                (nounFallbacks + verbFallbacks + adjFallbacks)
            
            let fallbacks = fallbackWords
                .filter { $0.lowercased() != blankedWord.lowercased() && !distractors.contains($0) }
                .shuffled()
            for word in fallbacks {
                if distractors.count >= 4 { break }
                distractors.append(word)
            }
        }
        
        // Shuffle so correct answer appears in random position
        distractors.shuffle()
        
        // Store in exercise config via the exercise queue
        guard var session = self.session else { return }
        let index = session.currentIndex
        session.exerciseQueue[index].config.correctAnswer = blankedWord
        session.exerciseQueue[index].config.blankedIndex = blankedIndex
        session.exerciseQueue[index].config.distractors = distractors
        self.session = session
    }
    
    private let commonWords = ["the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for", "of", "is", "was", "are", "were"]
}
