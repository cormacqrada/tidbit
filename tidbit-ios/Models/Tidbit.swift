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
    var meaningNotes: String?     // AI-generated context note (Explanation facet)
    
    // Knowledge structure — owned by the tidbit (orthogonal to ContentType/LearningGoal)
    var knowledgeDomain: KnowledgeDomain
    
    // Concept-domain facets (the Goodhart/Campbell shape)
    var simpleMeaning: String?    // Plain-language restatement (Simple meaning facet)
    var examples: [String]        // Real-world instances (Examples facet)
    
    // Free-form user notes (editable; "saw the movie, add notes to themes")
    var userNotes: String?
    
    // Encoding artifacts (generated on demand, stored as JSON)
    var encodingArtifactsData: Data?
    
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
        knowledgeDomain: KnowledgeDomain = .concept,
        simpleMeaning: String? = nil,
        examples: [String] = [],
        userNotes: String? = nil,
        encodingArtifacts: EncodingArtifacts = EncodingArtifacts(),
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
        self.knowledgeDomain = knowledgeDomain
        self.simpleMeaning = simpleMeaning
        self.examples = examples
        self.userNotes = userNotes
        self.encodingArtifactsData = try? JSONEncoder().encode(encodingArtifacts)
        self.createdAt = createdAt
        self.createdBy = createdBy
        self.lesson = lesson
    }
    
    var encodingArtifacts: EncodingArtifacts {
        get {
            guard let data = encodingArtifactsData else { return EncodingArtifacts() }
            return (try? JSONDecoder().decode(EncodingArtifacts.self, from: data)) ?? EncodingArtifacts()
        }
        set {
            encodingArtifactsData = try? JSONEncoder().encode(newValue)
        }
    }
}

enum CreationSource: String, Codable {
    case ai
    case manual
}

// MARK: - Encoding Artifacts

/// Memory-trace aids generated for a tidbit (at ingest or on demand). All fields
/// optional — only the techniques the user selected are populated. Rendered by
/// encoding exercises (mode = .encoding) and surfaced as in-session hint aids.
struct EncodingArtifacts: Codable {
    var mnemonic: String?          // acronym / acrostic
    var story: String?             // narrative of the content
    var palace: String?            // loci (memory palace) journey
    var analogy: String?           // familiar-domain mapping
    var imageDescription: String?  // bizarre image anchor
    var chunks: [Chunk] = []
    var personalCase: String?      // user-supplied real example (find_your_case)
    var priorLink: String?         // user-supplied connection to prior knowledge
    
    struct Chunk: Codable, Identifiable {
        var id: UUID = UUID()
        var label: String
        var memberConcepts: [String]
    }
    
    var isEmpty: Bool {
        mnemonic == nil && story == nil && palace == nil && analogy == nil
            && imageDescription == nil && chunks.isEmpty
            && personalCase == nil && priorLink == nil
    }
    
    init(mnemonic: String? = nil, story: String? = nil, palace: String? = nil,
         analogy: String? = nil, imageDescription: String? = nil, chunks: [Chunk] = [],
         personalCase: String? = nil, priorLink: String? = nil) {
        self.mnemonic = mnemonic
        self.story = story
        self.palace = palace
        self.analogy = analogy
        self.imageDescription = imageDescription
        self.chunks = chunks
        self.personalCase = personalCase
        self.priorLink = priorLink
    }
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
    var primaryKnowledgeDomain: KnowledgeDomain  // derived hint for ingest defaults / display
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
        primaryKnowledgeDomain: KnowledgeDomain = .concept,
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
        self.primaryKnowledgeDomain = primaryKnowledgeDomain
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
    
    // Encoding exposure state (separate from scored recall scheduling)
    var encodedTechniques: [String]
    var encodingExposures: Int
    
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
        encodedTechniques: [String] = [],
        encodingExposures: Int = 0,
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
        self.encodedTechniques = encodedTechniques
        self.encodingExposures = encodingExposures
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
    let mode: ExerciseMode
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
        mode: ExerciseMode = .recall,
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
        self.mode = mode
        self.exerciseConfig = exerciseConfig
    }
}
