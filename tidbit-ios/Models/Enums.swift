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
}

// MARK: - Exercise Type

enum ExerciseType: String, Codable, CaseIterable {
    case textRecall = "text_recall"
    case vocabMatch = "vocab_match"
    case fillBlank = "fill_blank"
    case explainBack = "explain_back"
    case conceptConnect = "concept_connect"
    case quickfire
    case linePrompt = "line_prompt"
    case wordFill = "word_fill"
    case stanzaReconstruct = "stanza_reconstruct"
    case coldOpen = "cold_open"
    case meaningProbe = "meaning_probe"
    
    var displayName: String {
        switch self {
        case .textRecall: "Recall"
        case .vocabMatch: "Vocab match"
        case .fillBlank: "Fill in the blank"
        case .explainBack: "Explain back"
        case .conceptConnect: "Concept connect"
        case .quickfire: "Quickfire"
        case .linePrompt: "Line prompt"
        case .wordFill: "Word fill"
        case .stanzaReconstruct: "Stanza reconstruct"
        case .coldOpen: "Cold open"
        case .meaningProbe: "Meaning probe"
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
        case .linePrompt: "Given prev. line, type next"
        case .wordFill: "Fill one or more blanks"
        case .stanzaReconstruct: "Reorder shuffled lines"
        case .coldOpen: "Title only → full stanza"
        case .meaningProbe: "Interpret a line or image"
        }
    }
    
    var requiresAI: Bool {
        // All exercises now have local fallbacks
        // meaningProbe, explainBack, vocabMatch use self-reported confidence
        return false
    }
}

// MARK: - Exercise Weight

struct ExerciseWeight: Codable, Identifiable {
    var id: String { type.rawValue }
    let type: ExerciseType
    var weight: Int // 0-5 for frequency dots (0 = disabled)
    var isEnabled: Bool { weight > 0 }
}
