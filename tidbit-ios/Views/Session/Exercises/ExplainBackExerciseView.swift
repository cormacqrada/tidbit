import SwiftUI

// MARK: - Explain Back Exercise

struct ExplainBackExerciseView: View {
    let exercise: ExerciseInstance
    @Bindable var viewModel: SessionViewModel
    var showDrawer: Bool = true
    
    @State private var hasSubmitted = false
    @State private var confidence: ConfidenceLevel?
    
    var body: some View {
        VStack(spacing: 24) {
            // Instruction
            VStack(spacing: 8) {
                Text("Explain in your own words:")
                    .font(.custom("DM Sans", size: 14))
                    .foregroundColor(DesignSystem.ink3)
            }
            
            // The line or concept to explain
            VStack(spacing: 8) {
                if exercise.tidbit.stanzaIndex != nil {
                    // Poem line
                    Text(exercise.tidbit.body)
                        .font(DesignSystem.serif(size: 20))
                        .italic()
                        .foregroundColor(DesignSystem.ink)
                } else {
                    // Prose concept
                    Text(exercise.tidbit.concept)
                        .font(DesignSystem.serif(size: 20))
                        .italic()
                        .foregroundColor(DesignSystem.ink)
                    
                    Text(exercise.tidbit.body)
                        .font(.custom("DM Sans", size: 14))
                        .foregroundColor(DesignSystem.ink2)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
            }
            .multilineTextAlignment(.center)
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(DesignSystem.card)
            .cornerRadius(DesignSystem.radius)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.radius)
                    .stroke(DesignSystem.parchment3, lineWidth: 1)
            )
            
            // Prompt
            Text(exercise.tidbit.stanzaIndex != nil
                 ? "What does this line mean to you? Explain it in your own words."
                 : "Explain this concept in your own words.")
                .font(.custom("DM Sans", size: 13))
                .foregroundColor(DesignSystem.ink3)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // User's explanation (shown after submission)
            if hasSubmitted, let userAnswer = viewModel.userInput, !userAnswer.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your explanation:")
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
                    Text("How well did you explain it?")
                        .font(.custom("DM Sans", size: 13))
                        .foregroundColor(DesignSystem.ink3)
                    
                    HStack(spacing: 12) {
                        ConfidenceButton(
                            label: "Nailed it",
                            subtitle: "Captured essence",
                            style: .easy
                        ) {
                            reportConfidence(.gotIt)
                        }
                        
                        ConfidenceButton(
                            label: "Okay",
                            subtitle: "Partial grasp",
                            style: .okay
                        ) {
                            reportConfidence(.struggled)
                        }
                        
                        ConfidenceButton(
                            label: "Hard",
                            subtitle: "Struggled",
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
            hasSubmitted = false
            confidence = nil
        }
        .onChange(of: exercise.id) { _, _ in
            hasSubmitted = false
            confidence = nil
        }
    }
    
    private func reportConfidence(_ level: ConfidenceLevel) {
        confidence = level
        viewModel.reportConfidence(level)
        viewModel.nextExercise()
    }
}

// MARK: - Preview

#Preview {
    ExplainBackExerciseView(
        exercise: ExerciseInstance(
            tidbit: Tidbit(
                concept: "Spaced Repetition",
                body: "A learning technique that schedules review at increasing intervals based on recall strength.",
                sourceTitle: "Learning Techniques"
            ),
            exerciseType: .explainBack
        ),
        viewModel: SessionViewModel()
    )
    .padding()
    .background(DesignSystem.parchment)
}
