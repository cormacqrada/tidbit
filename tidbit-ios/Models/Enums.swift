import Foundation

// MARK: - Content Type

enum ContentType: String, Codable, CaseIterable {
    case poem
    case prose
    case factual
    case technical
    case list
    case dialogue
    
    var displayName: String {
        switch self {
        case .poem: "Poem"
        case .prose: "Prose"
        case .factual: "Factual"
        case .technical: "Technical"
        case .list: "List"
        case .dialogue: "Dialogue"
        }
    }
}

// MARK: - Knowledge Domain

/// The cognitive structure of a tidbit — what *kind* of knowledge it is.
/// Owned by the Tidbit (the atomic unit owns its own structure). Orthogonal to
/// ContentType (source format) and LearningGoal (intensity/weighting).
enum KnowledgeDomain: String, Codable, CaseIterable {
    case word
    case plot
    case thesis
    case concept
    case system
    case procedure
    case strategic
    case spatial
    
    var displayName: String {
        switch self {
        case .word: "Word-level"
        case .plot: "Plot / events"
        case .thesis: "Thesis / argument"
        case .concept: "Concept"
        case .system: "System dynamics"
        case .procedure: "Procedure"
        case .strategic: "Strategic"
        case .spatial: "Spatial"
        }
    }
    
    var iconName: String {
        switch self {
        case .word: "text.quote"
        case .plot: "books.vertical"
        case .thesis: "text.alignleft"
        case .concept: "brain"
        case .system: "gearshape.2"
        case .procedure: "list.ordered"
        case .strategic: "target"
        case .spatial: "map"
        }
    }
}

// MARK: - Exercise Mode

/// Two layers of exercises. Recall exercises are scored and feed the scheduler.
/// Encoding exercises build the memory trace before repetition — no score,
/// only exposure telemetry; they never call updateLearnerState.
enum ExerciseMode: String, Codable {
    case encoding
    case recall
}

// MARK: - Learning Goal

enum LearningGoal: String, Codable, CaseIterable {
    case memorizeVerbatim = "memorize_verbatim"
    case understandDeeply = "understand_deeply"
    case recallKeyIdeas = "recall_key_ideas"
    case examPrep = "exam_prep"
    
    var displayName: String {
        switch self {
        case .memorizeVerbatim: "Memorize verbatim"
        case .understandDeeply: "Understand deeply"
        case .recallKeyIdeas: "Key ideas"
        case .examPrep: "Exam prep"
        }
    }
}

// MARK: - Hint Policy

enum HintPolicy: String, Codable, CaseIterable {
    case always
    case once
    case never
    
    var displayName: String {
        switch self {
        case .always: "Always"
        case .once: "Once"
        case .never: "Never"
        }
    }
}

// MARK: - Modality

enum Modality: String, Codable, CaseIterable {
    case tapOnly = "tap_only"
    case mixed
    case typeOnly = "type_only"
    
    var displayName: String {
        switch self {
        case .tapOnly: "Tap only"
        case .mixed: "Mixed"
        case .typeOnly: "Type only"
        }
    }
}

// MARK: - Learning Phase

enum Phase: String, Codable {
    case learning
    case review
    case maintenance
}

// MARK: - Adaptive Signal

enum AdaptiveSignal: String, Codable {
    case gotIt = "got_it"
    case struggled
    case skipped
    case hintUsed = "hint_used"
    case exposed = "exposed"
}

// MARK: - Exercise Type

enum ExerciseType: String, Codable, CaseIterable {
    // MARK: - Recall (scored, feed the scheduler)
    case textRecall = "text_recall"
    case vocabMatch = "vocab_match"
    case fillBlank = "fill_blank"
    case explainBack = "explain_back"
    case conceptConnect = "concept_connect"
    case quickfire
    case linePrompt = "line_prompt"          // generalized: next line / next step / next event
    case wordFill = "word_fill"
    case stanzaReconstruct = "stanza_reconstruct"  // generalized: reorder lines / steps / beats
    case coldOpen = "cold_open"
    case meaningProbe = "meaning_probe"
    // Recall — concept/thesis transfer
    case applyToCase = "apply_to_case"
    case argumentMap = "argument_map"
    case evidenceFor = "evidence_for"
    // MARK: - Encoding (no score, exposure telemetry only)
    case mnemonicLearn = "mnemonic_learn"
    case mnemonicDecode = "mnemonic_decode"
    case imageAnchorRead = "image_anchor_read"
    case imageToConcept = "image_to_concept"
    case analogyRead = "analogy_read"
    case chunkedRead = "chunked_read"
    case connectToPrior = "connect_to_prior"
    case findYourCase = "find_your_case"
    
    var mode: ExerciseMode {
        switch self {
        case .mnemonicLearn, .mnemonicDecode, .imageAnchorRead, .imageToConcept,
             .analogyRead, .chunkedRead, .connectToPrior, .findYourCase:
            return .encoding
        default:
            return .recall
        }
    }
    
    var displayName: String {
        switch self {
        case .textRecall: "Recall"
        case .vocabMatch: "Vocab match"
        case .fillBlank: "Fill in the blank"
        case .explainBack: "Explain back"
        case .conceptConnect: "Connect"
        case .quickfire: "Quickfire"
        case .linePrompt: "Next in sequence"
        case .wordFill: "Word fill"
        case .stanzaReconstruct: "Reconstruct"
        case .coldOpen: "Cold open"
        case .meaningProbe: "Meaning probe"
        case .applyToCase: "Apply to case"
        case .argumentMap: "Argument map"
        case .evidenceFor: "Evidence for"
        case .mnemonicLearn: "Learn mnemonic"
        case .mnemonicDecode: "Decode mnemonic"
        case .imageAnchorRead: "Image anchor"
        case .imageToConcept: "Image → concept"
        case .analogyRead: "Analogy"
        case .chunkedRead: "Chunked overview"
        case .connectToPrior: "Connect to prior"
        case .findYourCase: "Find your case"
        }
    }
    
    /// Domain-aware display name for context-rich UI (e.g. "Line prompt" for poems,
    /// "Next step" for procedures). Falls back to the neutral `displayName`.
    func displayName(for domain: KnowledgeDomain) -> String {
        switch (self, domain) {
        case (.linePrompt, .word): return "Line prompt"
        case (.linePrompt, .procedure): return "Next step"
        case (.linePrompt, .plot): return "Next event"
        case (.stanzaReconstruct, .word): return "Stanza reconstruct"
        case (.stanzaReconstruct, .procedure): return "Reorder steps"
        case (.stanzaReconstruct, .plot): return "Reorder events"
        default: return displayName
        }
    }
    
    var subtitle: String {
        switch self {
        case .textRecall: "Show concept, type definition"
        case .vocabMatch: "Pick concept from choices"
        case .fillBlank: "Tap missing word in line"
        case .explainBack: "Explain in your own words"
        case .conceptConnect: "Link related tidbits"
        case .quickfire: "Timed recall across 5"
        case .linePrompt: "Given the previous part, type the next"
        case .wordFill: "Fill one or more blanks"
        case .stanzaReconstruct: "Reorder shuffled parts"
        case .coldOpen: "Title only → full text"
        case .meaningProbe: "Interpret a line or image"
        case .applyToCase: "Apply the concept to a new scenario"
        case .argumentMap: "Rebuild the thesis → supports → evidence"
        case .evidenceFor: "Name the evidence for a claim"
        case .mnemonicLearn: "Study the memory hook"
        case .mnemonicDecode: "What does each letter stand for?"
        case .imageAnchorRead: "Read the vivid image anchor"
        case .imageToConcept: "Name the concept the image encodes"
        case .analogyRead: "Read the familiar-domain analogy"
        case .chunkedRead: "Learn the chunk labels first"
        case .connectToPrior: "What does this remind you of?"
        case .findYourCase: "Supply your own real example"
        }
    }
    
    var requiresAI: Bool {
        // All exercises have local/self-report fallbacks.
        // (AI is used to *generate* encoding artifacts at ingest, not to run them.)
        return false
    }
    
    // MARK: - Domain × Mode Eligibility Matrix
    
    /// Scored recall exercises eligible for a domain. Drives session composition.
    static func recallExercises(for domain: KnowledgeDomain) -> [ExerciseType] {
        switch domain {
        case .word:
            return [.linePrompt, .wordFill, .stanzaReconstruct, .coldOpen, .meaningProbe]
        case .concept:
            return [.textRecall, .vocabMatch, .fillBlank, .explainBack, .applyToCase, .conceptConnect]
        case .thesis:
            return [.explainBack, .argumentMap, .evidenceFor, .conceptConnect, .meaningProbe]
        case .plot:
            return [.stanzaReconstruct, .explainBack, .quickfire, .meaningProbe]
        case .system:
            return [.explainBack, .meaningProbe]
        case .procedure:
            return [.stanzaReconstruct, .linePrompt, .explainBack, .meaningProbe]
        case .strategic:
            return [.applyToCase, .meaningProbe]
        case .spatial:
            return []
        }
    }
    
    /// Non-scored encoding exercises eligible for a domain. Build the memory trace.
    static func encodingExercises(for domain: KnowledgeDomain) -> [ExerciseType] {
        switch domain {
        case .word:
            return [.chunkedRead, .mnemonicLearn, .mnemonicDecode, .imageAnchorRead, .imageToConcept, .connectToPrior]
        case .concept:
            return [.imageAnchorRead, .imageToConcept, .analogyRead, .chunkedRead, .connectToPrior, .findYourCase, .mnemonicLearn, .mnemonicDecode]
        case .thesis:
            return [.chunkedRead, .analogyRead, .connectToPrior]
        case .plot:
            return [.chunkedRead, .imageAnchorRead, .connectToPrior, .findYourCase]
        case .system:
            return [.analogyRead, .chunkedRead, .imageAnchorRead, .connectToPrior]
        case .procedure:
            return [.chunkedRead, .mnemonicLearn, .mnemonicDecode]
        case .strategic:
            return [.analogyRead, .connectToPrior, .findYourCase]
        case .spatial:
            return [.imageAnchorRead]
        }
    }
    
    /// All eligible exercises (encoding first, then recall) for a domain.
    static func allExercises(for domain: KnowledgeDomain) -> [ExerciseType] {
        encodingExercises(for: domain) + recallExercises(for: domain)
    }
}

// MARK: - Exercise Weight

struct ExerciseWeight: Codable, Identifiable {
    var id: String { type.rawValue }
    let type: ExerciseType
    var weight: Int // 0-5 for frequency dots (0 = disabled)
    var isEnabled: Bool { weight > 0 }
}
