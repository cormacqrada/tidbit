import SwiftUI

// MARK: - Text Recall Exercise

struct TextRecallExerciseView: View {
    let exercise: ExerciseInstance
    @Bindable var viewModel: SessionViewModel
    var showDrawer: Bool = true
    
    var body: some View {
        VStack(spacing: 20) {
            // Prompt - varies by content type
            VStack(spacing: 8) {
                if exercise.tidbit.stanzaIndex != nil {
                    // Poem: show line context
                    Text("Recall this line:")
                        .font(.custom("DM Sans", size: 13).weight(.medium))
                        .foregroundColor(DesignSystem.ink3)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    
                    // Show context: stanza and line position
                    HStack(spacing: 6) {
                        if let stanza = exercise.tidbit.stanzaIndex {
                            Text("Stanza \(stanza + 1)")
                                .font(.custom("DM Sans", size: 11))
                                .foregroundColor(DesignSystem.accent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(DesignSystem.accentLight)
                                .cornerRadius(10)
                        }
                        Text("Line \(exercise.tidbit.sequenceIndex + 1)")
                            .font(.custom("DM Sans", size: 11))
                            .foregroundColor(DesignSystem.ink3)
                    }
                } else {
                    // Prose: show concept
                    Text("Recall this concept:")
                        .font(.custom("DM Sans", size: 13).weight(.medium))
                        .foregroundColor(DesignSystem.ink3)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    
                    Text(exercise.tidbit.concept)
                        .font(DesignSystem.serif(size: 20))
                        .italic()
                        .foregroundColor(DesignSystem.ink)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(DesignSystem.card)
            .cornerRadius(DesignSystem.radius)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.radius)
                    .stroke(DesignSystem.parchment3, lineWidth: 1)
            )
            
            // Show result if feedback
            if viewModel.showFeedback, let result = viewModel.lastResult {
                Text("Type the definition or content:")
                    .font(.custom("DM Sans", size: 13))
                    .foregroundColor(DesignSystem.ink3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(viewModel.userInput)
                    .font(DesignSystem.serif(size: 20))
                    .italic()
                    .foregroundColor(result.passed ? DesignSystem.green : DesignSystem.red)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(DesignSystem.card)
                    .cornerRadius(DesignSystem.radius)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.radius)
                            .stroke(result.passed ? DesignSystem.greenMid : DesignSystem.redMid, lineWidth: 1)
                    )
            }
        }
        .onChange(of: exercise.id) { _, _ in
            viewModel.userInput = ""
        }
    }
}

// MARK: - Cold Open Exercise (Self-Report)

struct ColdOpenExerciseView: View {
    let exercise: ExerciseInstance
    @Bindable var viewModel: SessionViewModel
    var showDrawer: Bool = true
    
    var body: some View {
        VStack(spacing: 20) {
            // Title prompt with first words cue
            VStack(spacing: 8) {
                Text("Recite the full stanza from memory:")
                    .font(.custom("DM Sans", size: 13))
                    .foregroundColor(DesignSystem.ink3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 8) {
                    // Show first 2-3 words as a starting cue
                    let firstWords = getFirstWords(from: exercise.tidbit.body, count: 3)
                    Text(firstWords)
                        .font(DesignSystem.serif(size: 22))
                        .italic()
                        .foregroundColor(DesignSystem.ink)
                    
                    Divider()
                        .frame(width: 40)
                    
                    // Context info below the cue
                    HStack(spacing: 8) {
                        if let stanza = exercise.tidbit.stanzaIndex {
                            Text("Stanza \(stanza + 1)")
                                .font(.custom("DM Sans", size: 11))
                                .foregroundColor(DesignSystem.accent)
                        }
                        
                        if let author = exercise.tidbit.sourceAuthor {
                            Text("by \(author)")
                                .font(.custom("DM Sans", size: 11))
                                .foregroundColor(DesignSystem.ink3)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(DesignSystem.card)
                .cornerRadius(DesignSystem.radius)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.radius)
                        .stroke(DesignSystem.parchment3, lineWidth: 1)
                )
            }
            
            // Show comparison if feedback
            if viewModel.showFeedback {
                // User's answer
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your answer:")
                        .font(.custom("DM Sans", size: 11))
                        .foregroundColor(DesignSystem.ink3)
                        .textCase(.uppercase)
                    
                    Text(viewModel.userInput)
                        .font(DesignSystem.serif(size: 18))
                        .italic()
                        .foregroundColor(DesignSystem.ink2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(DesignSystem.card)
                .cornerRadius(DesignSystem.radiusSm)
                
                // Correct version
                VStack(alignment: .leading, spacing: 8) {
                    Text("Correct version:")
                        .font(.custom("DM Sans", size: 11))
                        .foregroundColor(DesignSystem.ink3)
                        .textCase(.uppercase)
                    
                    Text(exercise.tidbit.body)
                        .font(DesignSystem.serif(size: 18))
                        .italic()
                        .foregroundColor(DesignSystem.ink2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(DesignSystem.parchment2)
                .cornerRadius(DesignSystem.radiusSm)
            }
        }
        .onChange(of: exercise.id) { _, _ in
            viewModel.userInput = ""
        }
    }
    
    /// Get first N words from the stanza body
    private func getFirstWords(from text: String, count: Int) -> String {
        let words = text.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        let firstWords = words.prefix(count).joined(separator: " ")
        return firstWords
    }
}

// MARK: - Confidence Button

enum ConfidenceStyle {
    case easy, okay, hard
}

struct ConfidenceButton: View {
    let label: String
    let subtitle: String
    let style: ConfidenceStyle
    let action: () -> Void
    
    private var backgroundColor: Color {
        switch style {
        case .easy: return DesignSystem.greenLight
        case .okay: return DesignSystem.amberLight
        case .hard: return DesignSystem.redLight
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .easy: return DesignSystem.greenMid
        case .okay: return Color(hex: "#e5b060") ?? DesignSystem.amber
        case .hard: return DesignSystem.redMid
        }
    }
    
    private var labelColor: Color {
        switch style {
        case .easy: return DesignSystem.green
        case .okay: return DesignSystem.amber
        case .hard: return DesignSystem.red
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(label)
                    .font(.custom("DM Sans", size: 12).weight(.medium))
                    .foregroundColor(labelColor)
                
                Text(subtitle)
                    .font(.custom("DM Sans", size: 10))
                    .foregroundColor(DesignSystem.ink3)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(backgroundColor)
            .cornerRadius(DesignSystem.radiusSm)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.radiusSm)
                    .stroke(borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Text Recall") {
    TextRecallExerciseView(
        exercise: ExerciseInstance(
            tidbit: Tidbit(
                concept: "Spaced Repetition",
                body: "A learning technique that schedules review at increasing intervals based on recall strength.",
                sourceTitle: "Learning Techniques"
            ),
            exerciseType: .textRecall
        ),
        viewModel: SessionViewModel()
    )
    .padding()
    .background(DesignSystem.parchment)
}

#Preview("Cold Open") {
    ColdOpenExerciseView(
        exercise: ExerciseInstance(
            tidbit: Tidbit(
                concept: "Stanza 1",
                body: "Because I could not stop for Death —\nHe kindly stopped for me —\nThe Carriage held but just Ourselves —\nAnd Immortality.",
                stanzaIndex: 0,
                sourceTitle: "Because I Could Not Stop for Death",
                sourceAuthor: "Emily Dickinson"
            ),
            exerciseType: .coldOpen
        ),
        viewModel: SessionViewModel()
    )
    .padding()
    .background(DesignSystem.parchment)
}
