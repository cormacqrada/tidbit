import SwiftUI

struct FillBlankExerciseView: View {
    let exercise: ExerciseInstance
    @Bindable var viewModel: SessionViewModel
    var showDrawer: Bool = true
    
    // Store blank info for display - matches footer logic
    @State private var blankedWord: String = ""
    @State private var blankedIndex: Int = 0
    @State private var originalWords: [String] = []
    
    var body: some View {
        VStack(spacing: 20) {
            // Instruction
            Text("Complete the line:")
                .font(.custom("DM Sans", size: 13))
                .foregroundColor(DesignSystem.ink3)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if viewModel.showFeedback, let result = viewModel.lastResult {
                // Show result with filled-in line
                resultContent(result)
            } else {
                // Show line with blank
                exerciseContent
            }
        }
        .onAppear {
            loadFromConfig()
        }
        .onChange(of: exercise.id) { _, _ in
            loadFromConfig()
        }
    }
    
    // MARK: - Exercise Content (before submission)
    
    @ViewBuilder
    private var exerciseContent: some View {
        // Display line with blank
        Text(displayLineWithBlank())
            .font(DesignSystem.serif(size: 20))
            .italic()
            .foregroundColor(DesignSystem.ink)
            .multilineTextAlignment(.center)
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(DesignSystem.card)
            .cornerRadius(DesignSystem.radius)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.radius)
                    .stroke(DesignSystem.parchment3, lineWidth: 1)
            )
    }
    
    // MARK: - Result Content (after submission)
    
    @ViewBuilder
    private func resultContent(_ result: ValidationResult) -> some View {
        // Display line with result
        Text(displayLineWithResult(result))
            .font(DesignSystem.serif(size: 20))
            .italic()
            .foregroundColor(DesignSystem.ink)
            .multilineTextAlignment(.center)
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(DesignSystem.card)
            .cornerRadius(DesignSystem.radius)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.radius)
                    .stroke(DesignSystem.parchment3, lineWidth: 1)
            )
        // Chips are shown in the footer with coloring
    }
    
    // MARK: - Display Line Helpers
    
    private func displayLineWithBlank() -> AttributedString {
        var result = AttributedString()
        for (i, w) in originalWords.enumerated() {
            if i > 0 { result.append(AttributedString(" ")) }
            
            if i == blankedIndex {
                var blank = AttributedString("_____")
                blank.foregroundColor = DesignSystem.accent
                blank.font = DesignSystem.serif(size: 20).bold()
                result.append(blank)
            } else {
                var attrWord = AttributedString(w)
                attrWord.font = DesignSystem.serif(size: 20)
                result.append(attrWord)
            }
        }
        return result
    }
    
    private func displayLineWithResult(_ result: ValidationResult) -> AttributedString {
        var attrResult = AttributedString()
        
        for (i, w) in originalWords.enumerated() {
            if i > 0 { attrResult.append(AttributedString(" ")) }
            
            if i == blankedIndex {
                if result.passed {
                    // Correct - green highlight
                    var correctWord = AttributedString(result.userAnswer)
                    correctWord.font = DesignSystem.serif(size: 20)
                    correctWord.foregroundColor = Color(hex: "#1a5c3a")
                    correctWord.backgroundColor = Color(hex: "#c5ecd8")
                    attrResult.append(correctWord)
                } else {
                    // Wrong - show struck-through wrong answer then correct answer
                    var wrongWord = AttributedString(result.userAnswer)
                    wrongWord.font = DesignSystem.serif(size: 20)
                    wrongWord.foregroundColor = Color(hex: "#8b1a14")
                    wrongWord.backgroundColor = Color(hex: "#f5c4c0")
                    wrongWord.strikethroughStyle = .single
                    attrResult.append(wrongWord)
                    
                    attrResult.append(AttributedString(" "))
                    
                    var correctWord = AttributedString(result.correctAnswer)
                    correctWord.font = DesignSystem.serif(size: 20)
                    correctWord.foregroundColor = Color(hex: "#1a5c3a")
                    correctWord.backgroundColor = Color(hex: "#c5ecd8")
                    attrResult.append(correctWord)
                }
            } else {
                var attrWord = AttributedString(w)
                attrWord.font = DesignSystem.serif(size: 20)
                attrWord.foregroundColor = DesignSystem.ink
                attrResult.append(attrWord)
            }
        }
        
        return attrResult
    }
    
    // MARK: - Chip Styling
    
    private func chipColor(for word: String) -> Color {
        viewModel.userInput == word ? .white : DesignSystem.ink2
    }
    
    private func chipBackground(for word: String) -> Color {
        viewModel.userInput == word ? DesignSystem.accent : DesignSystem.card
    }
    
    private func chipBorder(for word: String) -> Color {
        viewModel.userInput == word ? DesignSystem.accentMid : DesignSystem.parchment3
    }
    
    // Chip styling with result
    private func chipColor(for word: String, result: ValidationResult) -> Color {
        if word == result.correctAnswer {
            return DesignSystem.green
        } else if word == result.userAnswer && !result.passed {
            return DesignSystem.red
        }
        return DesignSystem.ink2
    }
    
    private func chipBackground(for word: String, result: ValidationResult) -> Color {
        if word == result.correctAnswer {
            return DesignSystem.greenLight
        } else if word == result.userAnswer && !result.passed {
            return DesignSystem.redLight
        }
        return DesignSystem.card
    }
    
    private func chipBorder(for word: String, result: ValidationResult) -> Color {
        if word == result.correctAnswer {
            return DesignSystem.greenMid
        } else if word == result.userAnswer && !result.passed {
            return DesignSystem.redMid
        }
        return DesignSystem.parchment3
    }
    
    private func loadFromConfig() {
        // Load blank data from exercise config (prepared by viewModel)
        blankedWord = exercise.config.correctAnswer ?? ""
        blankedIndex = exercise.config.blankedIndex
        originalWords = exercise.tidbit.body.components(separatedBy: " ")
    }
}

// MARK: - Preview

#Preview {
    FillBlankExerciseView(
        exercise: ExerciseInstance(
            tidbit: Tidbit(
                concept: "Line 1",
                body: "Because I could not stop for Death —",
                sourceTitle: "Because I Could Not Stop for Death"
            ),
            exerciseType: .fillBlank
        ),
        viewModel: SessionViewModel()
    )
    .padding()
    .background(DesignSystem.parchment)
}
