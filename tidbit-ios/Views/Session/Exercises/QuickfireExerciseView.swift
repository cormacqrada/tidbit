import SwiftUI

// MARK: - Quickfire Exercise

struct QuickfireExerciseView: View {
    let exercise: ExerciseInstance
    @Bindable var viewModel: SessionViewModel
    var showDrawer: Bool = true
    
    @State private var currentIndex: Int = 0
    @State private var quickfireItems: [QuickfireItem] = []
    @State private var timeRemaining: Int = 60
    @State private var isTimerRunning: Bool = false
    @State private var score: Int = 0
    @State private var hasStarted: Bool = false
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 24) {
            if !hasStarted {
                // Start screen
                VStack(spacing: 20) {
                    Text("Quickfire Round")
                        .font(DesignSystem.serif(size: 28).bold())
                        .foregroundColor(DesignSystem.ink)
                    
                    Text("You'll have 60 seconds to recall as many lines as possible. Each correct answer scores points!")
                        .font(.custom("DM Sans", size: 14))
                        .foregroundColor(DesignSystem.ink3)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    Button("Start") {
                        hasStarted = true
                        isTimerRunning = true
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.top, 20)
                }
                .padding(32)
            } else if currentIndex < quickfireItems.count && timeRemaining > 0 {
                // Active round
                VStack(spacing: 16) {
                    // Timer and score
                    HStack {
                        // Timer badge
                        HStack(spacing: 6) {
                            Image(systemName: "timer")
                            Text("\(timeRemaining)s")
                        }
                        .font(.custom("DM Sans", size: 14).weight(.medium))
                        .foregroundColor(timeRemaining <= 10 ? DesignSystem.red : DesignSystem.ink3)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(timeRemaining <= 10 ? DesignSystem.redLight : DesignSystem.parchment2)
                        .cornerRadius(20)
                        
                        Spacer()
                        
                        // Score
                        Text("Score: \(score)")
                            .font(.custom("DM Sans", size: 14).weight(.semibold))
                            .foregroundColor(DesignSystem.accent)
                    }
                    
                    // Progress
                    ProgressView(value: Double(currentIndex), total: Double(quickfireItems.count))
                        .tint(DesignSystem.accent)
                    
                    // Current item
                    VStack(spacing: 12) {
                        Text("Line \(currentIndex + 1) of \(quickfireItems.count)")
                            .font(.custom("DM Sans", size: 12))
                            .foregroundColor(DesignSystem.ink3)
                        
                        // Show cue (previous line or context)
                        if let cue = quickfireItems[currentIndex].cue {
                            Text(cue)
                                .font(DesignSystem.serif(size: 18))
                                .italic()
                                .foregroundColor(DesignSystem.ink2)
                                .multilineTextAlignment(.center)
                                .padding(16)
                                .frame(maxWidth: .infinity)
                                .background(DesignSystem.parchment2)
                                .cornerRadius(DesignSystem.radius)
                        }
                        
                        // Prompt
                        Text("Type the next line:")
                            .font(.custom("DM Sans", size: 13))
                            .foregroundColor(DesignSystem.ink3)
                    }
                }
                .onReceive(timer) { _ in
                    if isTimerRunning && timeRemaining > 0 {
                        timeRemaining -= 1
                    }
                }
            } else {
                // End screen
                VStack(spacing: 20) {
                    Text("Time's Up!")
                        .font(DesignSystem.serif(size: 28).bold())
                        .foregroundColor(DesignSystem.ink)
                    
                    VStack(spacing: 8) {
                        Text("Final Score")
                            .font(.custom("DM Sans", size: 13))
                            .foregroundColor(DesignSystem.ink3)
                        
                        Text("\(score)")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(DesignSystem.accent)
                        
                        Text("\(currentIndex) of \(quickfireItems.count) lines")
                            .font(.custom("DM Sans", size: 14))
                            .foregroundColor(DesignSystem.ink3)
                    }
                    
                    Button("Continue") {
                        viewModel.submitAnswer()
                        viewModel.nextExercise()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding(32)
            }
        }
        .onAppear {
            prepareQuickfireItems()
        }
        .onChange(of: exercise.id) { _, _ in
            currentIndex = 0
            timeRemaining = 60
            score = 0
            hasStarted = false
            isTimerRunning = false
            quickfireItems = []
            prepareQuickfireItems()
        }
    }
    
    private func prepareQuickfireItems() {
        // Gather 5 tidbits for quickfire round
        guard let session = viewModel.session else { return }
        
        let allTidbits = session.exerciseQueue.map { $0.tidbit }
        let currentTidbit = exercise.tidbit
        
        // Get tidbits around the current one (same stanza or nearby)
        var selectedTidbits: [Tidbit] = []
        
        // Start with current tidbit's stanza
        if let stanzaIndex = currentTidbit.stanzaIndex {
            let sameStanza = allTidbits
                .filter { $0.stanzaIndex == stanzaIndex }
                .sorted { $0.sequenceIndex < $1.sequenceIndex }
            selectedTidbits = sameStanza
        }
        
        // If we need more, add nearby lines
        if selectedTidbits.count < 5 {
            let nearby = allTidbits
                .filter { !selectedTidbits.contains($0) }
                .sorted { abs($0.sequenceIndex - currentTidbit.sequenceIndex) < abs($1.sequenceIndex - currentTidbit.sequenceIndex) }
            
            for tidbit in nearby {
                if selectedTidbits.count >= 5 { break }
                selectedTidbits.append(tidbit)
            }
        }
        
        // Create quickfire items with cues
        quickfireItems = selectedTidbits.enumerated().map { index, tidbit in
            let cue: String? = if index == 0 {
                "Starting line:"
            } else if let prevTidbit = selectedTidbits[safe: index - 1] {
                prevTidbit.body
            } else {
                nil
            }
            
            return QuickfireItem(
                tidbit: tidbit,
                cue: cue,
                correctAnswer: tidbit.body
            )
        }
    }
    
    private func submitQuickfireAnswer() {
        let item = quickfireItems[currentIndex]
        let result = ValidationResult(
            input: viewModel.userInput,
            target: item.correctAnswer,
            threshold: 0.8
        )
        
        if result.passed {
            score += 10
        }
        
        currentIndex += 1
        viewModel.userInput = ""
        
        if currentIndex >= quickfireItems.count {
            isTimerRunning = false
        }
    }
}

// MARK: - Quickfire Item Model

struct QuickfireItem {
    let tidbit: Tidbit
    let cue: String?
    let correctAnswer: String
}

// MARK: - Array Extension

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Preview

#Preview {
    QuickfireExerciseView(
        exercise: ExerciseInstance(
            tidbit: Tidbit(
                concept: "Line 1",
                body: "Because I could not stop for Death —",
                stanzaIndex: 0,
                sourceTitle: "Because I Could Not Stop for Death"
            ),
            exerciseType: .quickfire
        ),
        viewModel: SessionViewModel()
    )
    .padding()
    .background(DesignSystem.parchment)
}
