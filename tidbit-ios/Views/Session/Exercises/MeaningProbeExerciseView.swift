import SwiftUI

// MARK: - Meaning Probe Exercise

struct MeaningProbeExerciseView: View {
    let exercise: ExerciseInstance
    @Bindable var viewModel: SessionViewModel
    var showDrawer: Bool = true
    
    @State private var question: String = ""
    @State private var hasSubmitted = false
    @State private var confidence: ConfidenceLevel?
    
    var body: some View {
        VStack(spacing: 24) {
            // Instruction
            VStack(spacing: 8) {
                Text("Interpret the line:")
                    .font(.custom("DM Sans", size: 14))
                    .foregroundColor(DesignSystem.ink3)
            }
            
            // The line being analyzed
            Text(exercise.tidbit.body)
                .font(DesignSystem.serif(size: 20))
                .italic()
                .foregroundColor(DesignSystem.ink)
                .multilineTextAlignment(.center)
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(DesignSystem.card)
                .cornerRadius(DesignSystem.radius)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.radius)
                        .stroke(DesignSystem.parchment3, lineWidth: 1)
                )
            
            // Question
            VStack(spacing: 8) {
                Text("Question:")
                    .font(.custom("DM Sans", size: 12))
                    .foregroundColor(DesignSystem.ink3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(question)
                    .font(.custom("DM Sans", size: 16).weight(.medium))
                    .foregroundColor(DesignSystem.ink)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(DesignSystem.parchment2)
                    .cornerRadius(DesignSystem.radius)
            }
            
            // User's explanation (shown after submission)
            if hasSubmitted, let userAnswer = viewModel.userInput, !userAnswer.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your interpretation:")
                        .font(.custom("DM Sans", size: 11))
                        .foregroundColor(DesignSystem.ink3)
                        .textCase(.uppercase)
                    
                    Text(userAnswer)
                        .font(DesignSystem.serif(size: 16))
                        .italic()
                        .foregroundColor(DesignSystem.ink2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(DesignSystem.card)
                .cornerRadius(DesignSystem.radiusSm)
            }
            
            // Confidence selection (self-reported)
            if hasSubmitted && confidence == nil {
                VStack(spacing: 12) {
                    Text("How confident were you?")
                        .font(.custom("DM Sans", size: 13))
                        .foregroundColor(DesignSystem.ink3)
                    
                    HStack(spacing: 12) {
                        ConfidenceButton(
                            label: "Got it",
                            subtitle: "Felt confident",
                            style: .easy
                        ) {
                            reportConfidence(.gotIt)
                        }
                        
                        ConfidenceButton(
                            label: "Okay",
                            subtitle: "Some doubt",
                            style: .okay
                        ) {
                            reportConfidence(.struggled)
                        }
                        
                        ConfidenceButton(
                            label: "Hard",
                            subtitle: "Unsure",
                            style: .hard
                        ) {
                            reportConfidence(.skipped)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .onAppear {
            generateQuestion()
        }
        .onChange(of: exercise.id) { _, _ in
            hasSubmitted = false
            confidence = nil
            question = ""
            generateQuestion()
        }
    }
    
    private func generateQuestion() {
        // Use pre-generated question from meaningNotes if available
        if let notes = exercise.tidbit.meaningNotes, !notes.isEmpty {
            question = notes
            return
        }
        
        // Otherwise generate from templates
        let line = exercise.tidbit.body
        
        // Template questions based on line content
        let templates = [
            "What does this line mean to you?",
            "What image or feeling does this line evoke?",
            "How does this line connect to the theme of the \(exercise.tidbit.sourceTitle)?",
            "What might the author be expressing through this line?",
            "What emotion do you sense in these words?"
        ]
        
        // Look for specific patterns to create more targeted questions
        if line.contains("—") {
            question = "What effect does the dash (—) create in this line?"
        } else if line.contains("?") {
            question = "Why might the author pose this as a question rather than a statement?"
        } else if line.contains("!") {
            question = "What emotion or emphasis does the exclamation convey?"
        } else if hasCapitalizedWords(line) {
            let caps = extractCapitalizedWords(line)
            if let word = caps.first {
                question = "Why might \"\(word)\" be significant in this line?"
            } else {
                question = templates.randomElement() ?? templates[0]
            }
        } else if hasMetaphorIndicators(line) {
            question = "What metaphor or comparison do you see in this line?"
        } else {
            question = templates.randomElement() ?? templates[0]
        }
    }
    
    private func hasCapitalizedWords(_ text: String) -> Bool {
        let words = text.components(separatedBy: .whitespaces)
        return words.contains { word in
            word.first?.isUppercase == true && word.count > 1
        }
    }
    
    private func extractCapitalizedWords(_ text: String) -> [String] {
        let words = text.components(separatedBy: .whitespaces)
        return words.filter { word in
            word.first?.isUppercase == true && word.count > 1
        }
    }
    
    private func hasMetaphorIndicators(_ text: String) -> Bool {
        let indicators = ["like", "as if", "as though", "seems", "appears"]
        let lowercased = text.lowercased()
        return indicators.contains { lowercased.contains($0) }
    }
    
    private func reportConfidence(_ level: ConfidenceLevel) {
        confidence = level
        viewModel.reportConfidence(level)
        viewModel.nextExercise()
    }
}

// MARK: - Confidence Level

enum ConfidenceLevel: String, Codable {
    case gotIt = "got_it"
    case struggled
    case skipped
}

// MARK: - Preview

#Preview {
    MeaningProbeExerciseView(
        exercise: ExerciseInstance(
            tidbit: Tidbit(
                concept: "Line 1",
                body: "Because I could not stop for Death —",
                sourceTitle: "Because I Could Not Stop for Death"
            ),
            exerciseType: .meaningProbe
        ),
        viewModel: SessionViewModel()
    )
    .padding()
    .background(DesignSystem.parchment)
}
