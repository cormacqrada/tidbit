import Foundation
import SwiftData

// MARK: - Tidbit

@Model
final class Tidbit {
    var id: UUID
    
    // Content
    var concept: String           // "Line 3, Stanza 1" or concept name
    var body: String              // The actual content/definition
    var sourceExcerpt: String?    // Original passage
    
    // Sequence info (for poems/structured content)
    var sequenceIndex: Int        // Position in sequence
    var stanzaIndex: Int?         // Stanza number for poems
    
    // Source metadata
    var sourceTitle: String       // "Because I Could Not Stop for Death"
    var sourceAuthor: String?     // "Emily Dickinson"
    var sourceUrl: String?
    
    // Learning metadata
    var topicTags: [String]
    var difficulty: Int           // 1-5
    var dependencyIds: [UUID]     // IDs of prerequisite tidbits
    var meaningNotes: String?     // AI-generated context note
    
    // Audit
    var createdAt: Date
    var createdBy: CreationSource
    
    // Relationship
    var lesson: Lesson?
    
    init(
        id: UUID = UUID(),
        concept: String,
        body: String,
        sourceExcerpt: String? = nil,
        sequenceIndex: Int = 0,
        stanzaIndex: Int? = nil,
        sourceTitle: String,
        sourceAuthor: String? = nil,
        sourceUrl: String? = nil,
        topicTags: [String] = [],
        difficulty: Int = 2,
        dependencyIds: [UUID] = [],
        meaningNotes: String? = nil,
        createdAt: Date = Date(),
        createdBy: CreationSource = .ai,
        lesson: Lesson? = nil
    ) {
        self.id = id
        self.concept = concept
        self.body = body
        self.sourceExcerpt = sourceExcerpt
        self.sequenceIndex = sequenceIndex
        self.stanzaIndex = stanzaIndex
        self.sourceTitle = sourceTitle
        self.sourceAuthor = sourceAuthor
        self.sourceUrl = sourceUrl
        self.topicTags = topicTags
        self.difficulty = difficulty
        self.dependencyIds = dependencyIds
        self.meaningNotes = meaningNotes
        self.createdAt = createdAt
        self.createdBy = createdBy
        self.lesson = lesson
    }
}

enum CreationSource: String, Codable {
    case ai
    case manual
}

// MARK: - Lesson (Collection)

@Model
final class Lesson {
    var id: UUID
    var name: String
    
    // Content type
    var contentType: ContentType
    var detectedLanguage: String?
    var estimatedLineCount: Int?
    
    // Configuration
    var learningGoal: LearningGoal
    var sessionLength: Int        // minutes: 3, 5, 10, 15
    var difficultyRamp: Double    // 0.0 = gradual, 1.0 = steep
    var hintPolicy: HintPolicy
    var modality: Modality
    
    // Exercise mix (stored as JSON)
    var exerciseMixData: Data?
    
    // Source info
    var sourceText: String?       // Original raw text
    var sourceUrl: String?
    
    // Audit
    var createdAt: Date
    
    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \Tidbit.lesson)
    var tidbits: [Tidbit] = []
    
    init(
        id: UUID = UUID(),
        name: String,
        contentType: ContentType = .prose,
        detectedLanguage: String? = nil,
        estimatedLineCount: Int? = nil,
        learningGoal: LearningGoal = .memorizeVerbatim,
        sessionLength: Int = 5,
        difficultyRamp: Double = 0.25,
        hintPolicy: HintPolicy = .always,
        modality: Modality = .mixed,
        exerciseMix: [ExerciseWeight] = [],
        sourceText: String? = nil,
        sourceUrl: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.contentType = contentType
        self.detectedLanguage = detectedLanguage
        self.estimatedLineCount = estimatedLineCount
        self.learningGoal = learningGoal
        self.sessionLength = sessionLength
        self.difficultyRamp = difficultyRamp
        self.hintPolicy = hintPolicy
        self.modality = modality
        self.exerciseMixData = try? JSONEncoder().encode(exerciseMix)
        self.sourceText = sourceText
        self.sourceUrl = sourceUrl
        self.createdAt = createdAt
    }
    
    var exerciseMix: [ExerciseWeight] {
        get {
            guard let data = exerciseMixData else { return [] }
            return (try? JSONDecoder().decode([ExerciseWeight].self, from: data)) ?? []
        }
        set {
            exerciseMixData = try? JSONEncoder().encode(newValue)
        }
    }
}

// MARK: - Learner State

@Model
final class LearnerState {
    var id: UUID
    var tidbitId: UUID
    var learnerId: UUID           // User ID (for multi-user support later)
    
    // Progress tracking
    var attempts: Int
    var successRate: Double       // 0.0 - 1.0
    var lastSeen: Date?
    var nextDue: Date
    var intervalDays: Int
    
    // Phase
    var phase: Phase
    
    // Signal history (stored as JSON array of raw values)
    var signalHistoryData: Data?
    
    init(
        id: UUID = UUID(),
        tidbitId: UUID,
        learnerId: UUID = UUID(),  // Default single user
        attempts: Int = 0,
        successRate: Double = 0.0,
        lastSeen: Date? = nil,
        nextDue: Date = Date(),
        intervalDays: Int = 1,
        phase: Phase = .learning,
        signalHistory: [AdaptiveSignal] = []
    ) {
        self.id = id
        self.tidbitId = tidbitId
        self.learnerId = learnerId
        self.attempts = attempts
        self.successRate = successRate
        self.lastSeen = lastSeen
        self.nextDue = nextDue
        self.intervalDays = intervalDays
        self.phase = phase
        self.signalHistoryData = try? JSONEncoder().encode(signalHistory.map { $0.rawValue })
    }
    
    var signalHistory: [AdaptiveSignal] {
        get {
            guard let data = signalHistoryData else { return [] }
            let rawValues = (try? JSONDecoder().decode([String].self, from: data)) ?? []
            return rawValues.compactMap { AdaptiveSignal(rawValue: $0) }
        }
        set {
            signalHistoryData = try? JSONEncoder().encode(newValue.map { $0.rawValue })
        }
    }
}

// MARK: - Telemetry Event

struct TelemetryEvent: Codable, Identifiable {
    let id: UUID
    let sessionId: UUID
    let tidbitId: UUID
    let templateId: String
    let learnerId: UUID
    let timestamp: Date
    let responseRaw: String
    let score: Double
    let responseTimeMs: Int
    let hintUsed: Bool
    let adaptiveSignal: AdaptiveSignal
    let exerciseConfig: [String: String]
    
    init(
        id: UUID = UUID(),
        sessionId: UUID,
        tidbitId: UUID,
        templateId: String,
        learnerId: UUID,
        timestamp: Date = Date(),
        responseRaw: String,
        score: Double,
        responseTimeMs: Int,
        hintUsed: Bool,
        adaptiveSignal: AdaptiveSignal,
        exerciseConfig: [String: String] = [:]
    ) {
        self.id = id
        self.sessionId = sessionId
        self.tidbitId = tidbitId
        self.templateId = templateId
        self.learnerId = learnerId
        self.timestamp = timestamp
        self.responseRaw = responseRaw
        self.score = score
        self.responseTimeMs = responseTimeMs
        self.hintUsed = hintUsed
        self.adaptiveSignal = adaptiveSignal
        self.exerciseConfig = exerciseConfig
    }
}
