import SwiftUI
import SwiftData

// MARK: - Progress Arc (Auto-advance countdown)

struct ProgressArc: View {
    let totalDuration: Double
    
    @State private var progress: Double = 1.0
    @State private var isPaused: Bool = false
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(DesignSystem.ink4, lineWidth: 2)
                .frame(width: 24, height: 24)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    DesignSystem.green,
                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                )
                .frame(width: 24, height: 24)
                .rotationEffect(.degrees(-90))
        }
        .onTapGesture {
            isPaused.toggle()
        }
        .task {
            while progress > 0 && !isPaused {
                let step = totalDuration / 60.0
                try? await Task.sleep(for: .milliseconds(Int(step * 1000)))
                if !isPaused {
                    progress = max(0, progress - (1.0 / 60.0))
                }
            }
        }
    }
}

// MARK: - Exercise Input Footer

struct ExerciseInputFooter: View {
    let exercise: ExerciseInstance
    @Bindable var viewModel: SessionViewModel
    
    @State private var showEncodingAid = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Word chips for fillBlank (with result coloring after evaluation)
            if exercise.exerciseType == .fillBlank || exercise.exerciseType == .wordFill {
                wordChipsWithResult
            }
            
            // Input field
            inputField
            
            // Buttons row
            buttonRow
        }
        .padding(20)
        .background(DesignSystem.parchment)
        .sheet(isPresented: $showEncodingAid) {
            EncodingAidSheet(tidbit: exercise.tidbit)
                .presentationDetents([.medium])
        }
    }
    
    // MARK: - Word Chips with Result Coloring
    @ViewBuilder
    private var wordChipsWithResult: some View {
        // Use static distractors from config (prepared by viewModel)
        let words = exercise.config.distractors
        
        HStack(spacing: 8) {
            ForEach(words, id: \.self) { word in
                let chipStyle = chipStyle(for: word)
                
                Button {
                    viewModel.userInput = word
                } label: {
                    Text(word)
                        .font(DesignSystem.serif(size: 15))
                        .italic()
                        .foregroundColor(chipStyle.textColor)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(chipStyle.backgroundColor)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(chipStyle.borderColor, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .disabled(viewModel.showFeedback)
            }
        }
    }
    
    private func chipStyle(for word: String) -> ChipStyle {
        // During evaluation
        if viewModel.showFeedback, let result = viewModel.lastResult {
            let correctAnswer = exercise.config.correctAnswer ?? result.correctAnswer
            if word == correctAnswer {
                return ChipStyle(
                    textColor: DesignSystem.green,
                    backgroundColor: DesignSystem.greenLight,
                    borderColor: DesignSystem.greenMid
                )
            } else if word == result.userAnswer && !result.passed {
                return ChipStyle(
                    textColor: DesignSystem.red,
                    backgroundColor: DesignSystem.redLight,
                    borderColor: DesignSystem.redMid
                )
            } else {
                return ChipStyle(
                    textColor: DesignSystem.ink3,
                    backgroundColor: DesignSystem.card,
                    borderColor: DesignSystem.parchment3
                )
            }
        }
        
        // Before submission - show selection
        if viewModel.userInput == word {
            return ChipStyle(
                textColor: .white,
                backgroundColor: DesignSystem.accent,
                borderColor: DesignSystem.accentMid
            )
        }
        
        return ChipStyle(
            textColor: DesignSystem.ink2,
            backgroundColor: DesignSystem.card,
            borderColor: DesignSystem.parchment3
        )
    }
    
    struct ChipStyle {
        let textColor: Color
        let backgroundColor: Color
        let borderColor: Color
    }
    
    // MARK: - Input Field
    @ViewBuilder
    private var inputField: some View {
        switch exercise.exerciseType {
        case .fillBlank, .wordFill:
            TextField("Type the word...", text: $viewModel.userInput)
                .font(DesignSystem.serif(size: 17))
                .italic()
                .foregroundColor(DesignSystem.ink)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(14)
                .background(DesignSystem.card)
                .cornerRadius(DesignSystem.radiusSm)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.radiusSm)
                        .stroke(DesignSystem.parchment3, lineWidth: 1)
                )
                .disabled(viewModel.showFeedback)
        
        case .coldOpen:
            TextEditor(text: $viewModel.userInput)
                .font(DesignSystem.serif(size: 18))
                .italic()
                .foregroundColor(DesignSystem.ink2)
                .frame(height: 80)
                .padding(12)
                .background(DesignSystem.card)
                .cornerRadius(DesignSystem.radius)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.radius)
                        .stroke(DesignSystem.parchment3, lineWidth: 1)
                )
                .overlay(alignment: .topLeading) {
                    if viewModel.userInput.isEmpty {
                        Text("Type from memory...")
                            .font(DesignSystem.serif(size: 18))
                            .italic()
                            .foregroundColor(DesignSystem.ink4)
                            .padding(12)
                    }
                }
                .disabled(viewModel.showFeedback)
        
        default:
            TextEditor(text: $viewModel.userInput)
                .font(DesignSystem.serif(size: 18))
                .italic()
                .foregroundColor(DesignSystem.ink)
                .frame(height: 80)
                .padding(14)
                .background(DesignSystem.card)
                .cornerRadius(DesignSystem.radius)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.radius)
                        .stroke(DesignSystem.parchment3, lineWidth: 1)
                )
                .overlay(alignment: .topLeading) {
                    if viewModel.userInput.isEmpty {
                        Text("Type your answer...")
                            .font(DesignSystem.serif(size: 18))
                            .italic()
                            .foregroundColor(DesignSystem.ink4)
                            .padding(14)
                    }
                }
                .disabled(viewModel.showFeedback)
        }
    }
    
    // MARK: - Button Row
    @ViewBuilder
    private var buttonRow: some View {
        HStack(spacing: 12) {
            // Hint menu (if applicable and not in feedback mode)
            if !viewModel.showFeedback, exercise.config.hintPolicy != .never, exercise.exerciseType != .coldOpen {
                Menu {
                    Button {
                        viewModel.useHint()
                    } label: {
                        Label("Show first letters", systemImage: "textformat")
                    }
                    .disabled(viewModel.showHint && exercise.config.hintPolicy == .once)
                    
                    Button {
                        showEncodingAid = true
                    } label: {
                        Label("Give me a way to remember", systemImage: "brain.head.profile")
                    }
                } label: {
                    Image(systemName: viewModel.showHint ? "lightbulb.fill" : "lightbulb")
                        .font(.system(size: 16))
                        .foregroundColor(viewModel.showHint ? DesignSystem.ink2 : DesignSystem.accent)
                        .frame(width: 48, height: 48)
                        .background(viewModel.showHint ? DesignSystem.parchment2 : DesignSystem.accentLight)
                        .cornerRadius(DesignSystem.radius)
                }
            }
            
            // Submit or Reveal button
            if !viewModel.showFeedback {
                Button {
                    submitAction()
                } label: {
                    Text(submitButtonTitle)
                        .font(.custom("DM Sans", size: 16).weight(.medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(submitButtonColor)
                        .cornerRadius(DesignSystem.radius)
                }
                .disabled(!canSubmit)
            }
        }
    }
    
    // MARK: - Helpers
    
    private var submitButtonTitle: String {
        if exercise.exerciseType == .coldOpen {
            return "Reveal correct version"
        }
        return "Submit"
    }
    
    private var submitButtonColor: Color {
        let hasInput = !viewModel.userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return hasInput ? DesignSystem.accent : DesignSystem.ink4
    }
    
    private var canSubmit: Bool {
        if exercise.exerciseType == .coldOpen {
            return true
        }
        return !viewModel.userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func submitAction() {
        if exercise.exerciseType == .fillBlank || exercise.exerciseType == .wordFill {
            viewModel.submitAnswer(correctAnswer: exercise.config.correctAnswer)
        } else {
            viewModel.submitAnswer()
        }
    }
}

struct SessionView: View {
    let lesson: Lesson
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var viewModel = SessionViewModel()
    
    // Track result state for styling
    private var resultState: ResultState {
        if viewModel.showFeedback, let result = viewModel.lastResult {
            return result.passed ? .correct : .wrong
        }
        return .neutral
    }
    
    @State private var showTableOfContents = false
    @State private var timerUpdateTrigger = false
    @State private var showTimerMenu = false
    @State private var isTimerPaused = false
    @AppStorage("showTimer") private var showTimer: Bool = true
    
    var body: some View {
        ZStack {
            // Background with tint based on result
            backgroundColor
                .ignoresSafeArea()
            
            if let session = viewModel.session {
                if session.isComplete {
                    SessionCompleteView(
                        sessionName: session.lessonName,
                        score: session.score,
                        totalExercises: session.totalExercises,
                        completedExercises: session.completedCount
                    ) {
                        dismiss()
                    }
                } else if let exercise = session.currentExercise {
                    VStack(spacing: 0) {
                        // ===== FIXED HEADER =====
                        SessionHeaderBar(
                            current: session.currentIndex + 1,
                            total: session.totalExercises,
                            elapsedTime: viewModel.elapsedTimeString,
                            resultState: resultState,
                            isTimerPaused: isTimerPaused,
                            showTimer: showTimer,
                            onExit: { dismiss() },
                            onTableOfContents: { showTableOfContents = true },
                            onTimerTap: { showTimerMenu = true }
                        )
                        
                        // Progress pip row
                        ProgressPipRow(
                            completedExercises: session.completedExercises,
                            currentIndex: session.currentIndex,
                            total: session.totalExercises
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                        
                        // ===== SCROLLABLE MIDDLE =====
                        ScrollView {
                            VStack(spacing: 0) {
                                // Exercise type header with context
                                ExerciseTypeHeader(
                                    type: exercise.exerciseType,
                                    contextInfo: contextInfo(for: exercise)
                                )
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                
                                // Exercise content (no internal scrolling)
                                ExerciseContentView(
                                    exercise: exercise,
                                    viewModel: viewModel,
                                    showDrawer: false
                                )
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                        }
                        .scrollDismissesKeyboard(.interactively)
                        .onTapGesture {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                        
                        // ===== FIXED FOOTER =====
                        if exercise.exerciseType.mode == .encoding {
                            // Encoding exercises render their own acknowledge button;
                            // no scored input footer or evaluation drawer.
                            Color.clear.frame(height: 12)
                        } else if viewModel.showFeedback, let result = viewModel.lastResult {
                            // Evaluation drawer after submission
                            EvaluationDrawer(
                                result: result,
                                tidbit: exercise.tidbit,
                                distractors: exercise.config.distractors,
                                onContinue: {
                                    viewModel.nextExercise()
                                },
                                onRetry: result.passed ? nil : {
                                    viewModel.retryCurrentExercise()
                                }
                            )
                        } else {
                            // Input area for answering
                            ExerciseInputFooter(
                                exercise: exercise,
                                viewModel: viewModel
                            )
                        }
                    }
                    .sheet(isPresented: $showTableOfContents) {
                        TableOfContentsSheet(
                            exercises: session.exerciseQueue,
                            currentIndex: session.currentIndex,
                            onSelect: { index in
                                showTableOfContents = false
                                viewModel.skipTo(index: index)
                            },
                            onSelectType: { type in
                                showTableOfContents = false
                                viewModel.skipToExerciseType(type)
                            }
                        )
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                    }
                    .confirmationDialog("Timer Options", isPresented: $showTimerMenu) {
                        Button(isTimerPaused ? "Resume Timer" : "Pause Timer") {
                            isTimerPaused.toggle()
                            if isTimerPaused {
                                viewModel.pauseTimer()
                            } else {
                                viewModel.resumeTimer()
                            }
                        }
                        
                        Button("Complete Lesson") {
                            viewModel.completeSession()
                            dismiss()
                        }
                        
                        Button(showTimer ? "Hide Time" : "Show Time") {
                            showTimer.toggle()
                        }
                        
                        Button("Cancel", role: .cancel) { }
                    } message: {
                        Text("Session duration: \(viewModel.elapsedTimeString)")
                    }
                }
            } else {
                // Loading state
                ProgressView("Starting session...")
                    .foregroundStyle(DesignSystem.ink3)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.startSession(lesson: lesson, modelContext: modelContext)
        }
        // Timer update trigger
        .onChange(of: timerUpdateTrigger) { _, _ in }
        .task {
            while true {
                try? await Task.sleep(for: .seconds(1))
                timerUpdateTrigger.toggle()
            }
        }
    }
    
    private var backgroundColor: Color {
        switch resultState {
        case .correct:
            return DesignSystem.greenTint
        case .wrong:
            return DesignSystem.redTint
        case .neutral:
            return DesignSystem.parchment
        }
    }
    
}

enum ResultState {
    case correct, wrong, neutral
}

// MARK: - Progress Pip Row

struct ProgressPipRow: View {
    let completedExercises: [CompletedExercise]
    let currentIndex: Int
    let total: Int
    
    // Track which exercise IDs have been completed (not just count)
    // This handles navigation back-and-forth properly
    private var completedExerciseIds: Set<UUID> {
        Set(completedExercises.map { $0.exerciseId })
    }
    
    // Get the score for a specific exercise if completed
    private func scoreForExercise(at index: Int) -> Double? {
        guard index < completedExercises.count else { return nil }
        return completedExercises[index].score
    }
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<total, id: \.self) { index in
                pip(for: index)
            }
        }
    }
    
    @ViewBuilder
    private func pip(for index: Int) -> some View {
        let state = pipState(for: index)
        RoundedRectangle(cornerRadius: 1.5)
            .fill(pipColor(for: state))
            .frame(height: 3)
    }
    
    private func pipState(for index: Int) -> PipState {
        // Check if this exercise has been completed (based on position in array)
        if index < completedExercises.count {
            let score = completedExercises[index].score
            // score 0 means skipped/not answered
            if score == 0 {
                return .todo  // Show as neutral, not wrong
            }
            return score >= 0.8 ? .doneCorrect : .doneWrong
        } else if index == currentIndex {
            return .current
        } else {
            return .todo
        }
    }
    
    private func pipColor(for state: PipState) -> Color {
        switch state {
        case .doneCorrect: return DesignSystem.green
        case .doneWrong: return DesignSystem.red
        case .current: return DesignSystem.accentMid
        case .todo: return DesignSystem.parchment3
        }
    }
}

enum PipState {
    case doneCorrect, doneWrong, current, todo
}

// MARK: - Context Info Helper

extension SessionView {
    /// Build context info string from tidbit metadata
    /// e.g., "Emily Dickinson · Stanza 1" or "Spaced Repetition"
    func contextInfo(for exercise: ExerciseInstance) -> String {
        let tidbit = exercise.tidbit
        
        // Build author/source info
        var parts: [String] = []
        
        if let author = tidbit.sourceAuthor {
            parts.append(author)
        } else if !tidbit.sourceTitle.isEmpty {
            parts.append(tidbit.sourceTitle)
        }
        
        // Add stanza/line info if available
        if let stanza = tidbit.stanzaIndex {
            parts.append("Stanza \(stanza + 1)")
        } else if !tidbit.concept.isEmpty, tidbit.concept != tidbit.sourceTitle {
            parts.append(tidbit.concept)
        }
        
        return parts.isEmpty ? tidbit.sourceTitle : parts.joined(separator: " · ")
    }
}

// MARK: - Exercise Content View

struct ExerciseContentView: View {
    let exercise: ExerciseInstance
    @Bindable var viewModel: SessionViewModel
    var showDrawer: Bool = true
    
    var body: some View {
        VStack(spacing: 24) {
            // Render appropriate exercise based on type
            switch exercise.exerciseType {
            case .linePrompt:
                LinePromptExerciseView(exercise: exercise, viewModel: viewModel, showDrawer: showDrawer)
            case .fillBlank:
                FillBlankExerciseView(exercise: exercise, viewModel: viewModel, showDrawer: showDrawer)
            case .wordFill:
                WordFillExerciseView(exercise: exercise, viewModel: viewModel, showDrawer: showDrawer)
            case .textRecall:
                TextRecallExerciseView(exercise: exercise, viewModel: viewModel, showDrawer: showDrawer)
            case .coldOpen:
                ColdOpenExerciseView(exercise: exercise, viewModel: viewModel, showDrawer: showDrawer)
            case .stanzaReconstruct:
                StanzaReconstructExerciseView(exercise: exercise, viewModel: viewModel)
            case .quickfire:
                QuickfireExerciseView(exercise: exercise, viewModel: viewModel, showDrawer: showDrawer)
            case .conceptConnect:
                ConceptConnectExerciseView(exercise: exercise, viewModel: viewModel, showDrawer: showDrawer)
            case .meaningProbe:
                MeaningProbeExerciseView(exercise: exercise, viewModel: viewModel, showDrawer: showDrawer)
            case .explainBack:
                ExplainBackExerciseView(exercise: exercise, viewModel: viewModel, showDrawer: showDrawer)
            case .vocabMatch:
                VocabMatchExerciseView(exercise: exercise, viewModel: viewModel, showDrawer: showDrawer)
            case .applyToCase:
                ApplyToCaseExerciseView(exercise: exercise, viewModel: viewModel, showDrawer: showDrawer)
            case .argumentMap:
                ArgumentMapExerciseView(exercise: exercise, viewModel: viewModel, showDrawer: showDrawer)
            case .evidenceFor:
                EvidenceForExerciseView(exercise: exercise, viewModel: viewModel, showDrawer: showDrawer)
            case .mnemonicLearn, .mnemonicDecode, .imageAnchorRead, .imageToConcept,
                 .analogyRead, .chunkedRead, .connectToPrior, .findYourCase:
                EncodingExerciseView(exercise: exercise, viewModel: viewModel, showDrawer: showDrawer)
            }
        }
    }
}

// MARK: - Exercise Type Header (with dynamic context)

struct ExerciseTypeHeader: View {
    let type: ExerciseType
    var contextInfo: String? = nil  // e.g., "Dickinson · Stanza 1"
    
    var body: some View {
        HStack(spacing: 12) {
            ExerciseIcon(type: type)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(type.displayName)
                    .font(.custom("DM Sans", size: 18).weight(.semibold))
                    .foregroundColor(DesignSystem.ink)
                
                Text(contextInfo ?? type.subtitle)
                    .font(.custom("DM Sans", size: 13))
                    .foregroundColor(DesignSystem.ink3)
            }
            
            Spacer()
        }
    }
}

// MARK: - Session Complete View

struct SessionCompleteView: View {
    let sessionName: String
    let score: Double
    let totalExercises: Int
    let completedExercises: Int
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon
            Text("🎉")
                .font(.system(size: 64))
            
            // Title
            Text("Session Complete!")
                .font(DesignSystem.serif(size: 28))
                .foregroundColor(DesignSystem.ink)
            
            // Subtitle
            Text(sessionName)
                .font(.custom("DM Sans", size: 16))
                .foregroundColor(DesignSystem.ink3)
            
            // Score card
            VStack(spacing: 12) {
                Text("\(Int(score * 100))%")
                    .font(DesignSystem.serif(size: 48))
                    .foregroundColor(score >= 0.8 ? DesignSystem.green : score >= 0.5 ? DesignSystem.amber : DesignSystem.red)
                
                Text("\(completedExercises) of \(totalExercises) completed")
                    .font(.custom("DM Sans", size: 14))
                    .foregroundColor(DesignSystem.ink3)
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(DesignSystem.card)
            .cornerRadius(DesignSystem.radius)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.radius)
                    .stroke(DesignSystem.parchment3, lineWidth: 1)
            )
            .padding(.horizontal, 40)
            
            // Done button
            Button("Done") {
                onDismiss()
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}

// MARK: - Evaluation Drawer (Full-width, bottom-pinned)

struct EvaluationDrawer: View {
    let result: ValidationResult
    let tidbit: Tidbit
    var distractors: [String] = []
    let onContinue: () -> Void
    let onRetry: (() -> Void)?
    
    private var isCorrect: Bool { result.passed }
    
    var body: some View {
        VStack(spacing: 0) {
            // Word chips above the divider (if we have distractors)
            if !distractors.isEmpty {
                HStack(spacing: 8) {
                    ForEach(distractors, id: \.self) { word in
                        let isCorrectAnswer = word == result.correctAnswer
                        
                        Text(word)
                            .font(DesignSystem.serif(size: 15))
                            .italic()
                            .foregroundColor(isCorrectAnswer ? DesignSystem.green : DesignSystem.ink4)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(isCorrectAnswer ? DesignSystem.greenLight : DesignSystem.card)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(isCorrectAnswer ? DesignSystem.greenMid : DesignSystem.parchment3, lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(isCorrect ? DesignSystem.greenLight : DesignSystem.redLight)
            }
            
            // Top border - full width, no padding
            Rectangle()
                .fill(isCorrect ? DesignSystem.greenMid : DesignSystem.redMid)
                .frame(height: 1)
            
            // Content with padding
            VStack(spacing: 14) {
                // Header with verdict and progress arc for correct
                HStack(spacing: 12) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(isCorrect ? DesignSystem.green : DesignSystem.red)
                            .frame(width: 32, height: 32)
                        
                        Text(isCorrect ? "✓" : "✕")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    // Verdict
                    Text(isCorrect ? "That's it" : "Not quite")
                        .font(.custom("DM Sans", size: 18).weight(.medium))
                        .foregroundColor(isCorrect ? DesignSystem.green : DesignSystem.red)
                    
                    Spacer()
                    
                    // Progress arc for correct answers (auto-advance countdown)
                    if isCorrect {
                        ProgressArc(totalDuration: 1.0)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Correction line - show full line with correct word highlighted
                Text(displayCorrectionLine)
                    .font(DesignSystem.serif(size: 16))
                    .italic()
                    .foregroundColor(isCorrect ? Color(hex: "#1a5c3a") : DesignSystem.ink2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(isCorrect ? Color(hex: "#d4ede2") : Color(hex: "#f5d4d2"))
                    .cornerRadius(DesignSystem.radiusSm)
                
                // Meaning note
                if let notes = tidbit.meaningNotes {
                    Text(notes)
                        .font(.custom("DM Sans", size: 14))
                        .foregroundColor(isCorrect ? Color(hex: "#4a8a6a") : Color(hex: "#8a4a45"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Buttons - full width at bottom
                VStack(spacing: 10) {
                    if !isCorrect, let onRetry = onRetry {
                        Button {
                            onRetry()
                        } label: {
                            Text("Retry")
                                .font(.custom("DM Sans", size: 16).weight(.medium))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(DesignSystem.red)
                                .cornerRadius(DesignSystem.radius)
                        }
                    }
                    
                    Button {
                        onContinue()
                    } label: {
                        Text(isCorrect ? "Continue" : "Got it")
                            .font(.custom("DM Sans", size: 16).weight(.medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(isCorrect ? DesignSystem.green : DesignSystem.red)
                            .cornerRadius(DesignSystem.radius)
                    }
                }
            }
            .padding(20)
        }
        .background(isCorrect ? DesignSystem.greenLight : DesignSystem.redLight)
    }
    
    // Attributed string for correction line
    private var displayCorrectionLine: AttributedString {
        var result = AttributedString()
        
        if isCorrect {
            // Show line with highlighted correct word
            let line = "\"\(tidbit.body)\""
            var attrLine = AttributedString(line)
            attrLine.font = DesignSystem.serif(size: 16)
            attrLine.foregroundColor = Color(hex: "#1a5c3a")
            attrLine.inlinePresentationIntent = .emphasized
            result = attrLine
        } else {
            // Show "The word is [correct] — not [wrong]"
            var text = AttributedString("The word is ")
            text.font = DesignSystem.serif(size: 16)
            text.foregroundColor = DesignSystem.ink2
            result.append(text)
            
            var correct = AttributedString("\"\(self.result.correctAnswer)\"")
            correct.font = DesignSystem.serif(size: 16).bold()
            correct.foregroundColor = DesignSystem.green
            correct.inlinePresentationIntent = [.emphasized]
            result.append(correct)
            
            var not = AttributedString(" — not ")
            not.font = DesignSystem.serif(size: 16)
            not.foregroundColor = DesignSystem.ink2
            result.append(not)
            
            var wrong = AttributedString("\"\(self.result.userAnswer)\"")
            wrong.font = DesignSystem.serif(size: 16)
            wrong.foregroundColor = DesignSystem.red
            wrong.inlinePresentationIntent = [.emphasized]
            wrong.strikethroughStyle = .single
            result.append(wrong)
        }
        
        return result
    }
}

// MARK: - Session Header Bar

struct SessionHeaderBar: View {
    let current: Int
    let total: Int
    let elapsedTime: String
    var resultState: ResultState = .neutral
    var isTimerPaused: Bool = false
    var showTimer: Bool = true
    let onExit: () -> Void
    let onTableOfContents: () -> Void
    let onTimerTap: () -> Void
    
    // Colors based on result state
    private var backgroundColor: Color {
        switch resultState {
        case .correct: return Color(hex: "#e8f5ef")
        case .wrong: return Color(hex: "#fdecea")
        case .neutral: return DesignSystem.parchment
        }
    }
    
    private var tintColor: Color {
        switch resultState {
        case .correct: return DesignSystem.green
        case .wrong: return DesignSystem.red
        case .neutral: return DesignSystem.ink3
        }
    }
    
    private var buttonBgColor: Color {
        switch resultState {
        case .correct: return Color(hex: "#d4ede2")
        case .wrong: return Color(hex: "#f5d4d2")
        case .neutral: return DesignSystem.parchment2
        }
    }
    
    var body: some View {
        HStack {
            // Exit button
            Button {
                onExit()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(tintColor)
                    .frame(width: 32, height: 32)
                    .background(buttonBgColor)
                    .cornerRadius(8)
            }
            
            Spacer()
            
            // Question number
            Text("\(current) of \(total)")
                .font(.custom("DM Sans", size: 15).weight(.medium))
                .foregroundColor(DesignSystem.ink)
            
            Spacer()
            
            // TOC button + Timer
            HStack(spacing: 8) {
                Button {
                    onTableOfContents()
                } label: {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(tintColor)
                        .frame(width: 32, height: 32)
                        .background(buttonBgColor)
                        .cornerRadius(8)
                }
                
                // Timer (tap to open menu)
                Button {
                    onTimerTap()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isTimerPaused ? "pause.circle.fill" : "clock")
                            .font(.system(size: 12))
                        Text(showTimer ? elapsedTime : "--:--")
                            .font(.custom("DM Sans", size: 13).weight(.medium))
                    }
                    .foregroundColor(tintColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(buttonBgColor)
                    .cornerRadius(8)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(backgroundColor)
    }
}

// MARK: - Table of Contents Sheet

struct TableOfContentsSheet: View {
    let exercises: [ExerciseInstance]
    let currentIndex: Int
    let onSelect: (Int) -> Void
    let onSelectType: (ExerciseType) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    // Group exercises by type
    private var exercisesByType: [ExerciseType: [ExerciseInstance]] {
        Dictionary(grouping: exercises, by: { $0.exerciseType })
    }
    
    // Get unique types in order of appearance
    private var uniqueTypes: [ExerciseType] {
        var seen = Set<ExerciseType>()
        return exercises.compactMap { exercise -> ExerciseType? in
            if seen.insert(exercise.exerciseType).inserted {
                return exercise.exerciseType
            }
            return nil
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Skip to section
                Section("Jump to") {
                    ForEach(uniqueTypes, id: \.self) { type in
                        Button {
                            onSelectType(type)
                        } label: {
                            HStack {
                                ExerciseIcon(type: type)
                                    .frame(width: 24, height: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(type.displayName)
                                        .font(.custom("DM Sans", size: 15).weight(.medium))
                                        .foregroundColor(DesignSystem.ink)
                                    
                                    Text("\(exercisesByType[type]?.count ?? 0) exercises")
                                        .font(.custom("DM Sans", size: 12))
                                        .foregroundColor(DesignSystem.ink3)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(DesignSystem.ink4)
                            }
                        }
                        .listRowBackground(DesignSystem.card)
                }
                }
                
                // All questions
                Section("All Questions") {
                    ForEach(Array(exercises.enumerated()), id: \.element.id) { index, exercise in
                        Button {
                            onSelect(index)
                        } label: {
                            HStack {
                                // Number or status
                                ZStack {
                                    if index < currentIndex {
                                        // Completed
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(DesignSystem.greenLight)
                                            .frame(width: 28, height: 28)
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(DesignSystem.green)
                                    } else if index == currentIndex {
                                        // Current
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(DesignSystem.accentLight)
                                            .frame(width: 28, height: 28)
                                        Text("\(index + 1)")
                                            .font(.custom("DM Sans", size: 12).weight(.bold))
                                            .foregroundColor(DesignSystem.accent)
                                    } else {
                                        // Future
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(DesignSystem.parchment2)
                                            .frame(width: 28, height: 28)
                                        Text("\(index + 1)")
                                            .font(.custom("DM Sans", size: 12))
                                            .foregroundColor(DesignSystem.ink3)
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(exercise.exerciseType.displayName)
                                        .font(.custom("DM Sans", size: 15).weight(.medium))
                                        .foregroundColor(index > currentIndex ? DesignSystem.ink3 : DesignSystem.ink)
                                    
                                    Text(exercise.tidbit.body.prefix(40) + (exercise.tidbit.body.count > 40 ? "..." : ""))
                                        .font(.custom("DM Sans", size: 12))
                                        .foregroundColor(DesignSystem.ink3)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                            }
                        }
                        .listRowBackground(index == currentIndex ? DesignSystem.accentLight : DesignSystem.card)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(DesignSystem.parchment)
            .navigationTitle("Contents")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(DesignSystem.accent)
                }
            }
        }
    }
}

// MARK: - Exercise Icon

struct ExerciseIcon: View {
    let type: ExerciseType
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(iconBackgroundColor)
                .frame(width: 28, height: 28)
            
            Image(systemName: iconName)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(iconForegroundColor)
        }
    }
    
    private var iconName: String {
        switch type {
        case .fillBlank, .wordFill: return "text.append"
        case .linePrompt: return "text.bubble"
        case .textRecall: return "textformat"
        case .coldOpen: return "textformat.abc"
        case .stanzaReconstruct: return "arrow.up.arrow.down"
        case .vocabMatch: return "character.bubble"
        case .quickfire: return "flame"
        case .conceptConnect: return "link"
        case .explainBack: return "bubble.left.and.exclamationmark.bubble.right"
        case .meaningProbe: return "lightbulb"
        case .applyToCase: return "wand.and.rays"
        case .argumentMap: return "text.alignleft"
        case .evidenceFor: return "checkmark.seal"
        case .mnemonicLearn, .mnemonicDecode: return "textformat.abc.dottedunderline"
        case .imageAnchorRead, .imageToConcept: return "photo.on.rectangle.angled"
        case .analogyRead: return "arrow.triangle.2.circlepath"
        case .chunkedRead: return "square.grid.2x2"
        case .connectToPrior: return "link.circle"
        case .findYourCase: return "mappin.and.ellipse"
        }
    }
    
    private var iconBackgroundColor: Color {
        DesignSystem.accentLight
    }
    
    private var iconForegroundColor: Color {
        DesignSystem.accent
    }
}

// MARK: - Encoding Aid Sheet (in-session memory hook)

/// Shown from the hint button's "Give me a way to remember" option. Surfaces the
/// tidbit's existing encoding artifacts (mnemonic, image anchor, analogy) so the
/// user can build the memory trace mid-recall. Mode = encoding, exposure only.
struct EncodingAidSheet: View {
    let tidbit: Tidbit
    @Environment(\.dismiss) private var dismiss
    
    private var artifacts: EncodingArtifacts { tidbit.encodingArtifacts }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(tidbit.concept)
                        .font(DesignSystem.serif(size: 18))
                        .italic()
                        .foregroundColor(DesignSystem.ink)
                    
                    if let mnemonic = artifacts.mnemonic {
                        aidCard(title: "Mnemonic", symbol: "textformat.abc", text: mnemonic)
                    }
                    if let image = artifacts.imageDescription {
                        aidCard(title: "Image anchor", symbol: "photo", text: image)
                    }
                    if let analogy = artifacts.analogy {
                        aidCard(title: "Analogy", symbol: "arrow.triangle.2.circlepath", text: analogy)
                    }
                    if let story = artifacts.story {
                        aidCard(title: "Story", symbol: "book", text: story)
                    }
                    
                    if artifacts.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 36))
                                .foregroundColor(DesignSystem.ink4)
                            Text("No memory aids generated yet")
                                .font(.custom("DM Sans", size: 14))
                                .foregroundColor(DesignSystem.ink3)
                            Text("Use “Encode this” on the tidbit detail to add one.")
                                .font(.custom("DM Sans", size: 12))
                                .foregroundColor(DesignSystem.ink4)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    }
                }
                .padding(20)
            }
            .navigationTitle("Memory aid")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
    
    private func aidCard(title: String, symbol: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 14))
                    .foregroundColor(DesignSystem.accent)
                Text(title)
                    .font(.custom("DM Sans", size: 12).weight(.medium))
                    .foregroundColor(DesignSystem.ink3)
                    .textCase(.uppercase)
            }
            Text(text)
                .font(DesignSystem.serif(size: 16))
                .foregroundColor(DesignSystem.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(DesignSystem.parchment2)
                .cornerRadius(DesignSystem.radius)
        }
    }
}

// MARK: - Feedback Overlay (Kept for backwards compatibility)

struct FeedbackOverlay: View {
    let result: ValidationResult
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            VStack(spacing: 16) {
                Text(result.passed ? "✓" : "✗")
                    .font(.system(size: 48))
                    .foregroundColor(result.passed ? DesignSystem.green : DesignSystem.red)
                
                Text(result.feedback)
                    .font(DesignSystem.serif(size: 22))
                    .foregroundColor(DesignSystem.ink)
            }
            .padding(32)
            .frame(maxWidth: .infinity)
            .background(DesignSystem.card)
            .cornerRadius(DesignSystem.radius)
            .padding(.horizontal, 40)
            
            Button("Continue") {
                onContinue()
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    SessionView(lesson: {
        let lesson = Lesson(name: "Test Poem", contentType: .poem)
        return lesson
    }())
    .modelContainer(for: [Lesson.self, Tidbit.self], inMemory: true)
}
