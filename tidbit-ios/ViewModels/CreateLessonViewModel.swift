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

// MARK: - Ingestion Result

struct IngestionResult {
    let text: String
    let contentType: ContentType
    let detectedLanguage: String
    let estimatedLineCount: Int
    let suggestedTitle: String?
    let detectedAuthor: String?
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
        // Generate based on content type and learning goal
        exerciseMix = ExerciseMixGenerator.generate(
            contentType: contentType,
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
        let lesson = Lesson(
            name: collectionName,
            contentType: contentType,
            detectedLanguage: ingestionResult?.detectedLanguage,
            estimatedLineCount: ingestionResult?.estimatedLineCount,
            learningGoal: learningGoal,
            sessionLength: sessionLength,
            difficultyRamp: difficultyRamp,
            hintPolicy: hintPolicy,
            modality: modality,
            exerciseMix: exerciseMix,
            sourceText: pastedText,
            sourceUrl: sourceTab == .url ? urlInput : nil
        )
        
        // Generate tidbits from source text
        let tidbits = TidbitGenerator.generate(
            from: pastedText,
            contentType: contentType,
            sourceTitle: collectionName
        )
        
        // Set relationship and insert tidbits
        for tidbit in tidbits {
            tidbit.lesson = lesson
            modelContext.insert(tidbit)
        }
        
        // Insert lesson
        modelContext.insert(lesson)
        
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
        
        // Try to extract title from first line if it looks like a title
        let suggestedTitle: String? = lines.first.map { firstLine in
            firstLine.count < 50 ? firstLine : nil
        } ?? nil
        
        return IngestionResult(
            text: text,
            contentType: contentType,
            detectedLanguage: "English", // MVP: assume English
            estimatedLineCount: lines.count,
            suggestedTitle: suggestedTitle,
            detectedAuthor: nil
        )
    }
}

// MARK: - Exercise Mix Generator

enum ExerciseMixGenerator {
    static func generate(contentType: ContentType, learningGoal: LearningGoal) -> [ExerciseWeight] {
        // Matrix from specs: content_type × learning_goal
        // Returns weights 1-5 for each exercise type
        
        switch (contentType, learningGoal) {
        case (.poem, .memorizeVerbatim):
            return [
                ExerciseWeight(type: .linePrompt, weight: 5),
                ExerciseWeight(type: .fillBlank, weight: 4),
                ExerciseWeight(type: .stanzaReconstruct, weight: 3),
                ExerciseWeight(type: .coldOpen, weight: 2),
                ExerciseWeight(type: .quickfire, weight: 2)
            ]
            
        case (.poem, .understandDeeply):
            return [
                ExerciseWeight(type: .linePrompt, weight: 3),
                ExerciseWeight(type: .meaningProbe, weight: 4),
                ExerciseWeight(type: .stanzaReconstruct, weight: 3),
                ExerciseWeight(type: .coldOpen, weight: 1)
            ]
            
        case (.prose, .recallKeyIdeas):
            return [
                ExerciseWeight(type: .textRecall, weight: 3),
                ExerciseWeight(type: .conceptConnect, weight: 4),
                ExerciseWeight(type: .fillBlank, weight: 2)
            ]
            
        case (.prose, .understandDeeply):
            return [
                ExerciseWeight(type: .meaningProbe, weight: 5),
                ExerciseWeight(type: .conceptConnect, weight: 3),
                ExerciseWeight(type: .explainBack, weight: 3)
            ]
            
        default:
            return [
                ExerciseWeight(type: .textRecall, weight: 3),
                ExerciseWeight(type: .fillBlank, weight: 2)
            ]
        }
    }
}

// MARK: - Tidbit Generator

enum TidbitGenerator {
    static func generate(from text: String, contentType: ContentType, sourceTitle: String) -> [Tidbit] {
        switch contentType {
        case .poem:
            return generatePoemTidbits(from: text, sourceTitle: sourceTitle)
        default:
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
                    dependencyIds: dependencyIds.suffix(1).map { $0 } // Depend on previous line
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
            
            let tidbit = Tidbit(
                concept: "Paragraph \(index + 1)",
                body: trimmed,
                sequenceIndex: index,
                sourceTitle: sourceTitle,
                difficulty: 2
            )
            
            tidbits.append(tidbit)
        }
        
        return tidbits
    }
}
