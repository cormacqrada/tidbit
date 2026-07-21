import Foundation
import SwiftUI
import SwiftData

// MARK: - Create Lesson Flow State

enum CreateLessonStep: Int, CaseIterable {
    case source = 1
    case configure = 2
    case exerciseMix = 3
    case processing = 4
}

// MARK: - Source Tab

enum SourceTab: String, CaseIterable {
    case text
    case url
    case file
    case voice
    
    var displayName: String {
        switch self {
        case .text: "Text"
        case .url: "URL"
        case .file: "File"
        case .voice: "Voice"
        }
    }
}

// MARK: - Source Structure

/// How the source text is organized — determines the extraction path.
enum SourceStructure: String, Codable {
    case poem           // line/stanza based (verbatim)
    case prose          // paragraph based (paraphrase acceptable)
    case faceted        // structured with labeled sections (Definition, Examples, etc.)
}

// MARK: - Ingestion Result

struct IngestionResult {
    let text: String
    let contentType: ContentType
    let sourceStructure: SourceStructure
    let primaryKnowledgeDomain: KnowledgeDomain
    let detectedLanguage: String
    let estimatedLineCount: Int
    let suggestedTitle: String?
    let detectedAuthor: String?
    
    // Backwards-compatible convenience init (defaults to prose/concept)
    init(text: String, contentType: ContentType, sourceStructure: SourceStructure = .prose,
         primaryKnowledgeDomain: KnowledgeDomain = .concept,
         detectedLanguage: String, estimatedLineCount: Int,
         suggestedTitle: String?, detectedAuthor: String?) {
        self.text = text
        self.contentType = contentType
        self.sourceStructure = sourceStructure
        self.primaryKnowledgeDomain = primaryKnowledgeDomain
        self.detectedLanguage = detectedLanguage
        self.estimatedLineCount = estimatedLineCount
        self.suggestedTitle = suggestedTitle
        self.detectedAuthor = detectedAuthor
    }
}

// MARK: - Processing Step

enum ProcessingStepStatus {
    case done
    case active
    case todo
}

struct ProcessingStep: Identifiable {
    let id = UUID()
    let label: String
    var detail: String?
    var status: ProcessingStepStatus = .todo
}

// MARK: - Create Lesson View Model

@MainActor
@Observable
class CreateLessonViewModel {
    
    // MARK: - Navigation State
    
    var currentStep: CreateLessonStep = .source
    var isProcessing: Bool = false
    
    // MARK: - Source Input
    
    var sourceTab: SourceTab = .text
    var pastedText: String = ""
    var urlInput: String = ""
    var collectionName: String = ""
    
    // MARK: - Ingestion Result
    
    var ingestionResult: IngestionResult?
    
    // MARK: - Configuration
    
    var learningGoal: LearningGoal = .memorizeVerbatim
    var sessionLength: Int = 5
    var difficultyRamp: Double = 0.25
    var hintPolicy: HintPolicy = .always
    var modality: Modality = .mixed
    
    // MARK: - Exercise Mix
    
    var exerciseMix: [ExerciseWeight] = []
    var meaningProbeEnabled: Bool = false
    
    // MARK: - Processing State
    
    var processingSteps: [ProcessingStep] = [
        ProcessingStep(label: "Text extracted", detail: nil),
        ProcessingStep(label: "Structure parsed", detail: nil),
        ProcessingStep(label: "Generating tidbits", detail: nil),
        ProcessingStep(label: "Building exercise queue", detail: nil),
        ProcessingStep(label: "Scheduling first session", detail: nil)
    ]
    
    // MARK: - Created Lesson
    
    var createdLesson: Lesson?
    
    // MARK: - Computed Properties
    
    var contentType: ContentType {
        ingestionResult?.contentType ?? .prose
    }
    
    var detectedContentTypeLabel: String {
        guard let result = ingestionResult else { return "" }
        let typeLabel = result.contentType.displayName
        let linesLabel = result.estimatedLineCount == 1 ? "1 line" : "\(result.estimatedLineCount) lines"
        return "\(typeLabel) detected · \(linesLabel) · \(result.detectedLanguage)"
    }
    
    var canProceedFromSource: Bool {
        switch sourceTab {
        case .text:
            return !pastedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .url:
            return urlInput.contains(".") && ingestionResult != nil
        case .file, .voice:
            return false // MVP: not implemented
        }
    }
    
    // MARK: - Actions
    
    func ingestText() {
        let text = pastedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        // Detect content type
        let result = ContentDetector.detect(text: text)
        self.ingestionResult = result
        
        // Auto-fill collection name if empty
        if collectionName.isEmpty, let title = result.suggestedTitle {
            collectionName = title
        }
    }
    
    func fetchUrl() async {
        // MVP: Not implemented - would use Readability
        // For now, just mock a result
        guard !urlInput.isEmpty else { return }
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Mock result
        self.ingestionResult = IngestionResult(
            text: "Mock fetched content",
            contentType: .poem,
            detectedLanguage: "English",
            estimatedLineCount: 24,
            suggestedTitle: "Fetched Poem",
            detectedAuthor: nil
        )
        
        if collectionName.isEmpty {
            collectionName = "Fetched Poem"
        }
    }
    
    func generateExerciseMix() {
        // Generate based on knowledge domain and learning goal (domain-aware)
        let domain = ingestionResult?.primaryKnowledgeDomain ?? .concept
        exerciseMix = ExerciseMixGenerator.generate(
            domain: domain,
            learningGoal: learningGoal
        )
    }
    
    func startProcessing() async {
        currentStep = .processing
        isProcessing = true
        
        // Step 1: Text extracted (instant for text input)
        processingSteps[0].status = .active
        try? await Task.sleep(nanoseconds: 100_000_000)
        processingSteps[0].detail = "\(ingestionResult?.estimatedLineCount ?? 0) lines · 1 stanza detected"
        processingSteps[0].status = .done
        
        // Step 2: Structure parsed
        processingSteps[1].status = .active
        try? await Task.sleep(nanoseconds: 200_000_000)
        processingSteps[1].detail = "Line breaks, stanza boundaries"
        processingSteps[1].status = .done
        
        // Step 3: Generating tidbits (the slow one)
        processingSteps[2].status = .active
        for i in 1...4 {
            try? await Task.sleep(nanoseconds: 400_000_000)
            processingSteps[2].detail = "\(i) of \(ingestionResult?.estimatedLineCount ?? 0) complete…"
        }
        processingSteps[2].status = .done
        
        // Step 4: Building exercise queue
        processingSteps[3].status = .active
        try? await Task.sleep(nanoseconds: 200_000_000)
        processingSteps[3].status = .done
        
        // Step 5: Scheduling first session
        processingSteps[4].status = .active
        try? await Task.sleep(nanoseconds: 100_000_000)
        processingSteps[4].status = .done
        
        isProcessing = false
    }
    
    func createLesson(modelContext: ModelContext) -> Lesson {
        let primaryDomain = ingestionResult?.primaryKnowledgeDomain ?? .concept
        let lesson = Lesson(
            name: collectionName,
            contentType: contentType,
            detectedLanguage: ingestionResult?.detectedLanguage,
            estimatedLineCount: ingestionResult?.estimatedLineCount,
            learningGoal: learningGoal,
            primaryKnowledgeDomain: primaryDomain,
            sessionLength: sessionLength,
            difficultyRamp: difficultyRamp,
            hintPolicy: hintPolicy,
            modality: modality,
            exerciseMix: exerciseMix,
            sourceText: ingestionResult?.text ?? pastedText,
            sourceUrl: sourceTab == .url ? urlInput : nil
        )
        
        // Generate tidbits from the source text. For URL sources the content lives
        // in ingestionResult.text (pastedText is empty), so prefer the fetched text.
        let sourceText = ingestionResult?.text ?? pastedText
        let structure = ingestionResult?.sourceStructure ?? .prose
        let tidbits = TidbitGenerator.generate(
            from: sourceText,
            contentType: contentType,
            sourceStructure: structure,
            primaryDomain: primaryDomain,
            sourceTitle: collectionName
        )
        
        // Set relationship and insert tidbits
        for tidbit in tidbits {
            tidbit.lesson = lesson
            modelContext.insert(tidbit)
        }
        
        // Insert lesson
        modelContext.insert(lesson)
        
        // Persist to the store
        try? modelContext.save()
        
        self.createdLesson = lesson
        return lesson
    }
    
    func reset() {
        currentStep = .source
        isProcessing = false
        sourceTab = .text
        pastedText = ""
        urlInput = ""
        collectionName = ""
        ingestionResult = nil
        learningGoal = .memorizeVerbatim
        sessionLength = 5
        difficultyRamp = 0.25
        hintPolicy = .always
        modality = .mixed
        exerciseMix = []
        meaningProbeEnabled = false
        createdLesson = nil
        
        // Reset processing steps
        for i in processingSteps.indices {
            processingSteps[i].status = .todo
            processingSteps[i].detail = nil
        }
    }
}

// MARK: - Content Detector

enum ContentDetector {
    static func detect(text: String) -> IngestionResult {
        let lines = text.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        let avgLineLength = lines.isEmpty ? 0 : lines.map { $0.count }.reduce(0, +) / lines.count
        
        // Count blank lines (stanza breaks)
        var blankLineCount = 0
        var previousWasBlank = false
        for line in text.components(separatedBy: .newlines) {
            let isBlank = line.trimmingCharacters(in: .whitespaces).isEmpty
            if isBlank && !previousWasBlank {
                blankLineCount += 1
            }
            previousWasBlank = isBlank
        }
        
        // Heuristics for poem detection
        let blankLineRatio = Double(blankLineCount) / Double(max(lines.count, 1))
        let isPoem = avgLineLength < 60 && (blankLineRatio > 0.05 || lines.allSatisfy { $0.count < 80 })
        
        let contentType: ContentType = isPoem ? .poem : .prose
        
        // Detect faceted structure (Definition / Examples / Thesis / Step N headings)
        let facetResult = FacetDetector.detect(text: text, lines: lines)
        let sourceStructure: SourceStructure = facetResult?.structure ?? (isPoem ? .poem : .prose)
        let primaryDomain: KnowledgeDomain = facetResult?.domain ?? (isPoem ? .word : .concept)
        
        // Try to extract title from first line if it looks like a title
        let suggestedTitle: String? = lines.first.map { firstLine in
            firstLine.count < 50 ? firstLine : nil
        } ?? nil
        
        return IngestionResult(
            text: text,
            contentType: contentType,
            sourceStructure: sourceStructure,
            primaryKnowledgeDomain: primaryDomain,
            detectedLanguage: "English", // MVP: assume English
            estimatedLineCount: lines.count,
            suggestedTitle: suggestedTitle,
            detectedAuthor: nil
        )
    }
}

// MARK: - Facet Detector

/// Detects labeled-section structure in pasted text (the Goodhart/Campbell shape).
/// Recognizes facet signatures for concept (Definition/Examples), thesis
/// (Thesis/Argument/Evidence), and procedure (Step N) domains.
enum FacetDetector {
    
    struct Result {
        let structure: SourceStructure
        let domain: KnowledgeDomain
        let facets: [(label: String, body: String)]  // ordered facet sections
        let itemTitles: [String]  // ### headings or detected concept names
    }
    
    static func detect(text: String, lines: [String]) -> Result? {
        // Check for markdown heading structure first
        let hasMarkdownHeadings = lines.contains { $0.hasPrefix("#") || $0.hasPrefix("##") || $0.hasPrefix("###") }
        
        // Collect recognized facet labels present in the text
        let conceptFacets: Set<String> = ["definition", "simple meaning", "simple meaning:", "explanation", "examples", "example"]
        let thesisFacets: Set<String> = ["thesis", "argument", "arguments", "evidence", "claim", "support", "key points"]
        let procedureFacets: Set<String> = ["step 1", "step 2", "step 3", "steps"]
        
        let normalizedLines = lines.map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
        
        let foundConcept = normalizedLines.filter { conceptFacets.contains($0) }.count
        let foundThesis = normalizedLines.filter { thesisFacets.contains($0) }.count
        let foundProcedure = normalizedLines.filter { procedureFacets.contains($0) }.count
        
        // Need at least 2 facet labels to classify as faceted
        let maxFacets = max(foundConcept, foundThesis, foundProcedure)
        guard maxFacets >= 2 else { return nil }
        
        let domain: KnowledgeDomain
        let facetSet: Set<String>
        if foundConcept >= foundThesis && foundConcept >= foundProcedure {
            domain = .concept
            facetSet = conceptFacets
        } else if foundThesis >= foundProcedure {
            domain = .thesis
            facetSet = thesisFacets
        } else {
            domain = .procedure
            facetSet = procedureFacets
        }
        
        // Parse facets — split text into (label, body) sections
        let facets = parseFacets(text: text, facetSet: facetSet)
        
        // Detect item titles (### headings or short lines before facets)
        let itemTitles = detectItemTitles(lines: lines, hasMarkdownHeadings: hasMarkdownHeadings)
        
        return Result(structure: .faceted, domain: domain, facets: facets, itemTitles: itemTitles)
    }
    
    /// Parse text into ordered (label, body) sections by scanning for facet labels.
    private static func parseFacets(text: String, facetSet: Set<String>) -> [(label: String, body: String)] {
        let lines = text.components(separatedBy: .newlines)
        var facets: [(String, String)] = []
        var currentLabel: String?
        var currentBody: String = ""
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let normalized = trimmed.lowercased()
            
            if facetSet.contains(normalized) || facetSet.contains(normalized.replacingOccurrences(of: ":", with: "")) {
                if let label = currentLabel {
                    facets.append((label, currentBody.trimmingCharacters(in: .whitespacesAndNewlines)))
                }
                currentLabel = trimmed.replacingOccurrences(of: ":", with: "")
                currentBody = ""
            } else if currentLabel != nil {
                if !trimmed.isEmpty {
                    currentBody += trimmed + "\n"
                }
            }
        }
        if let label = currentLabel {
            facets.append((label, currentBody.trimmingCharacters(in: .whitespacesAndNewlines)))
        }
        
        return facets
    }
    
    /// Detect item titles — either markdown ### headings or short standalone lines
    /// that precede facet blocks (e.g. "Goodhart's Law" before "Definition").
    private static func detectItemTitles(lines: [String], hasMarkdownHeadings: Bool) -> [String] {
        if hasMarkdownHeadings {
            return lines.compactMap { line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("###") || trimmed.hasPrefix("##") {
                    return trimmed.replacingOccurrences(of: "^#+\\s*", with: "", options: .regularExpression)
                }
                return nil
            }
        }
        
        // Non-markdown: short lines (1-5 words, < 60 chars) that sit between blank lines
        // and are followed by a facet label. Heuristic: standalone short lines not containing
        // facet labels themselves.
        let facetLabels: Set<String> = ["definition", "simple meaning", "explanation", "examples", "thesis", "argument", "evidence"]
        var titles: [String] = []
        for (i, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let wordCount = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }.count
            let isShort = trimmed.count < 60 && wordCount <= 5
            let isNotFacet = !facetLabels.contains(trimmed.lowercased())
            let isNotBlank = !trimmed.isEmpty
            // Look ahead: is the next non-blank line a facet label?
            var nextNonBlankIsFacet = false
            for j in (i+1)..<min(i+4, lines.count) {
                let next = lines[j].trimmingCharacters(in: .whitespaces)
                if !next.isEmpty {
                    nextNonBlankIsFacet = facetLabels.contains(next.lowercased())
                    break
                }
            }
            if isShort && isNotFacet && isNotBlank && nextNonBlankIsFacet {
                titles.append(trimmed)
            }
        }
        return titles
    }
}

// MARK: - Exercise Mix Generator

enum ExerciseMixGenerator {
    /// Domain-aware exercise mix generation. Uses the knowledge domain × learning goal
    /// to select exercises from the eligibility matrix with appropriate weights.
    static func generate(domain: KnowledgeDomain, learningGoal: LearningGoal) -> [ExerciseWeight] {
        let recallTypes = ExerciseType.recallExercises(for: domain)
        
        // Weight each recall exercise based on the learning goal
        return recallTypes.map { type in
            ExerciseWeight(type: type, weight: weightFor(type: type, domain: domain, goal: learningGoal))
        }
    }
    
    /// Legacy contentType-based generation (kept for EditLessonSheet reset compatibility).
    static func generate(contentType: ContentType, learningGoal: LearningGoal) -> [ExerciseWeight] {
        // Map contentType to a default domain and delegate
        let domain: KnowledgeDomain = contentType == .poem ? .word : .concept
        return generate(domain: domain, learningGoal: learningGoal)
    }
    
    private static func weightFor(type: ExerciseType, domain: KnowledgeDomain, goal: LearningGoal) -> Int {
        // Higher weights for exercises that match the learning goal's cognitive demand
        switch goal {
        case .memorizeVerbatim:
            // Favor verbatim reproduction exercises
            switch type {
            case .linePrompt, .wordFill, .stanzaReconstruct, .coldOpen: return 5
            case .fillBlank: return 4
            case .quickfire: return 3
            default: return 2
            }
        case .understandDeeply:
            // Favor comprehension and transfer exercises
            switch type {
            case .meaningProbe, .explainBack, .applyToCase, .argumentMap: return 5
            case .evidenceFor, .conceptConnect: return 3
            default: return 2
            }
        case .recallKeyIdeas:
            // Balanced recall
            switch type {
            case .textRecall, .explainBack, .conceptConnect: return 4
            case .fillBlank, .evidenceFor, .applyToCase: return 3
            default: return 2
            }
        case .examPrep:
            // Heavy on all recall types
            switch type {
            case .textRecall, .fillBlank, .coldOpen, .quickfire: return 4
            case .stanzaReconstruct, .linePrompt, .wordFill: return 4
            default: return 3
            }
        }
    }
}

// MARK: - Tidbit Generator

enum TidbitGenerator {
    static func generate(from text: String, contentType: ContentType,
                         sourceStructure: SourceStructure = .prose,
                         primaryDomain: KnowledgeDomain = .concept,
                         sourceTitle: String) -> [Tidbit] {
        switch sourceStructure {
        case .faceted:
            return generateFacetedTidbits(from: text, primaryDomain: primaryDomain, sourceTitle: sourceTitle)
        case .poem:
            return generatePoemTidbits(from: text, sourceTitle: sourceTitle)
        case .prose:
            return generateProseTidbits(from: text, sourceTitle: sourceTitle)
        }
    }
    
    private static func generatePoemTidbits(from text: String, sourceTitle: String) -> [Tidbit] {
        var tidbits: [Tidbit] = []
        var dependencyIds: [UUID] = []
        
        // Split into stanzas
        let stanzas = text.components(separatedBy: "\n\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        var globalIndex = 0
        for (stanzaIndex, stanza) in stanzas.enumerated() {
            let lines = stanza.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            
            for (_, line) in lines.enumerated() {
                let trimmedLine = line.trimmingCharacters(in: .whitespaces)
                guard !trimmedLine.isEmpty else { continue }
                
                let tidbitId = UUID()
                
                let tidbit = Tidbit(
                    id: tidbitId,
                    concept: "Line \(globalIndex + 1), Stanza \(stanzaIndex + 1)",
                    body: trimmedLine,
                    sequenceIndex: globalIndex,
                    stanzaIndex: stanzaIndex,
                    sourceTitle: sourceTitle,
                    difficulty: 2,
                    dependencyIds: dependencyIds.suffix(1).map { $0 }, // Depend on previous line
                    knowledgeDomain: .word
                )
                
                tidbits.append(tidbit)
                dependencyIds.append(tidbitId)
                globalIndex += 1
            }
        }
        
        return tidbits
    }
    
    private static func generateProseTidbits(from text: String, sourceTitle: String) -> [Tidbit] {
        // Split into sentences or paragraphs for prose
        let paragraphs = text.components(separatedBy: "\n\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        var tidbits: [Tidbit] = []
        
        for (index, paragraph) in paragraphs.enumerated() {
            let trimmed = paragraph.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            
            // Derive a meaningful concept name. For a single-block paste (the common
            // concept/definition case), use a "Title: rest" split or the first sentence
            // rather than the generic "Paragraph 1".
            let conceptName: String
            if paragraphs.count == 1 {
                conceptName = deriveConceptName(for: trimmed)
            } else {
                conceptName = "Paragraph \(index + 1)"
            }
            
            let tidbit = Tidbit(
                concept: conceptName,
                body: trimmed,
                sequenceIndex: index,
                sourceTitle: sourceTitle,
                difficulty: 2,
                knowledgeDomain: .concept
            )
            
            tidbits.append(tidbit)
        }
        
        return tidbits
    }
    
    /// Derive a concept name from a single block of text: prefer the text before
    /// the first colon ("Goodhart's Law: ..."), else the first sentence, else a prefix.
    private static func deriveConceptName(for text: String) -> String {
        if let colonRange = text.range(of: ":") {
            let before = text[..<colonRange.lowerBound].trimmingCharacters(in: .whitespaces)
            if !before.isEmpty && before.count <= 60 {
                return String(before)
            }
        }
        // First sentence
        let firstSentence = text.components(separatedBy: CharacterSet(charactersIn: ".!?")).first ?? text
        let trimmed = firstSentence.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty && trimmed.count <= 80 {
            return trimmed
        }
        // Fallback: first 8 words
        let words = text.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        return words.prefix(8).joined(separator: " ")
    }
    
    // MARK: - Faceted Tidbit Generator
    
    /// Extract tidbits from structured/faceted text. Each item (detected by title
    /// or ### heading) becomes one tidbit with its facets mapped to the appropriate
    /// fields: Definition → body, Simple meaning → simpleMeaning, Explanation →
    /// meaningNotes, Examples → examples. For thesis domains: Thesis → body,
    /// Argument → meaningNotes, Evidence → examples.
    private static func generateFacetedTidbits(from text: String, primaryDomain: KnowledgeDomain,
                                               sourceTitle: String) -> [Tidbit] {
        let lines = text.components(separatedBy: .newlines)
        let nonBlankLines = lines.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        guard let facetResult = FacetDetector.detect(text: text, lines: nonBlankLines) else {
            return generateProseTidbits(from: text, sourceTitle: sourceTitle)
        }
        
        let facets = facetResult.facets
        let itemTitles = facetResult.itemTitles
        let domain = facetResult.domain
        
        var facetMap: [String: String] = [:]
        for (label, body) in facets {
            facetMap[label.lowercased()] = body
        }
        
        if itemTitles.count > 1 {
            return generateMultiItemFacetedTidbits(from: text, itemTitles: itemTitles, domain: domain, sourceTitle: sourceTitle)
        }
        
        let title = itemTitles.first ?? sourceTitle
        let tidbit = buildTidbitFromFacets(title: title, facetMap: facetMap, domain: domain,
                                           sequenceIndex: 0, sourceTitle: sourceTitle)
        return [tidbit]
    }
    
    private static func generateMultiItemFacetedTidbits(from text: String, itemTitles: [String],
                                                         domain: KnowledgeDomain, sourceTitle: String) -> [Tidbit] {
        let lines = text.components(separatedBy: .newlines)
        var blocks: [(title: String, lines: [String])] = []
        var currentTitle: String?
        var currentLines: [String] = []
        
        let titleSet = Set(itemTitles.map { $0.lowercased() })
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if titleSet.contains(trimmed.lowercased()) {
                if let title = currentTitle {
                    blocks.append((title, currentLines))
                }
                currentTitle = trimmed
                currentLines = []
            } else if currentTitle != nil {
                currentLines.append(line)
            }
        }
        if let title = currentTitle {
            blocks.append((title, currentLines))
        }
        
        var tidbits: [Tidbit] = []
        for (index, block) in blocks.enumerated() {
            let blockText = block.lines.joined(separator: "\n")
            let nonBlank = block.lines.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            guard let blockFacets = FacetDetector.detect(text: blockText, lines: nonBlank) else { continue }
            
            var facetMap: [String: String] = [:]
            for (label, body) in blockFacets.facets {
                facetMap[label.lowercased()] = body
            }
            
            let tidbit = buildTidbitFromFacets(title: block.title, facetMap: facetMap, domain: domain,
                                               sequenceIndex: index, sourceTitle: sourceTitle)
            tidbits.append(tidbit)
        }
        
        return tidbits
    }
    
    private static func buildTidbitFromFacets(title: String, facetMap: [String: String],
                                              domain: KnowledgeDomain, sequenceIndex: Int,
                                              sourceTitle: String) -> Tidbit {
        var body = ""
        var simpleMeaning: String? = nil
        var meaningNotes: String? = nil
        var examples: [String] = []
        
        switch domain {
        case .concept:
            body = facetMap["definition"] ?? facetMap["simple meaning"] ?? title
            simpleMeaning = facetMap["simple meaning"]
            meaningNotes = facetMap["explanation"]
            if let ex = facetMap["examples"] {
                examples = ex.components(separatedBy: .newlines)
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
                    .map { $0.replacingOccurrences(of: "^[\\-•*]\\s*", with: "", options: .regularExpression) }
            }
        case .thesis:
            body = facetMap["thesis"] ?? facetMap["claim"] ?? title
            simpleMeaning = facetMap["key points"]
            meaningNotes = facetMap["argument"] ?? facetMap["arguments"] ?? facetMap["support"]
            if let ex = facetMap["evidence"] {
                examples = ex.components(separatedBy: .newlines)
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
            }
        case .procedure:
            body = facetMap["steps"] ?? title
            meaningNotes = facetMap["step 1"]
        default:
            body = facetMap["definition"] ?? title
        }
        
        return Tidbit(
            concept: title,
            body: body,
            sequenceIndex: sequenceIndex,
            sourceTitle: sourceTitle,
            difficulty: 2,
            meaningNotes: meaningNotes,
            knowledgeDomain: domain,
            simpleMeaning: simpleMeaning,
            examples: examples
        )
    }
}
