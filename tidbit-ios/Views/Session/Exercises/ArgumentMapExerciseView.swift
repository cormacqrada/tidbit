import SwiftUI

// MARK: - Argument Map Exercise

/// Recall (scored via self-report). The user reconstructs the thesis and its
/// supporting arguments from memory. Targets the thesis domain. A free-text
/// reconstruction graded by the learner's own confidence — the deterministic
/// version reveals the stored structure for self-comparison.
struct ArgumentMapExerciseView: View {
    let exercise: ExerciseInstance
    @Bindable var viewModel: SessionViewModel
    var showDrawer: Bool = true

    @State private var hasSubmitted = false
    @State private var confidence: ConfidenceLevel?
    @State private var revealedStructure: String = ""

    var body: some View {
        VStack(spacing: 24) {
            // Instruction
            Text("Reconstruct the argument:")
                .font(.custom("DM Sans", size: 14))
                .foregroundColor(DesignSystem.ink3)

            // The source / context
            VStack(spacing: 8) {
                Text(exercise.tidbit.sourceTitle)
                    .font(DesignSystem.serif(size: 18))
                    .foregroundColor(DesignSystem.ink)

                Text("State the thesis, then name each supporting argument and its evidence.")
                    .font(.custom("DM Sans", size: 12))
                    .foregroundColor(DesignSystem.ink3)
                    .multilineTextAlignment(.center)
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(DesignSystem.card)
            .cornerRadius(DesignSystem.radius)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.radius)
                    .stroke(DesignSystem.parchment3, lineWidth: 1)
            )

            // User's reconstruction (shown after submission)
            if hasSubmitted, !viewModel.userInput.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your reconstruction:")
                        .font(.custom("DM Sans", size: 11))
                        .foregroundColor(DesignSystem.ink3)
                        .textCase(.uppercase)

                    Text(viewModel.userInput)
                        .font(DesignSystem.serif(size: 16))
                        .italic()
                        .foregroundColor(DesignSystem.ink2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(DesignSystem.card)
                .cornerRadius(DesignSystem.radiusSm)

                // Reveal the stored structure for self-comparison
                VStack(alignment: .leading, spacing: 8) {
                    Text("The argument:")
                        .font(.custom("DM Sans", size: 11))
                        .foregroundColor(DesignSystem.ink3)
                        .textCase(.uppercase)

                    Text(revealedStructure)
                        .font(DesignSystem.serif(size: 15))
                        .foregroundColor(DesignSystem.ink2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(DesignSystem.parchment2)
                .cornerRadius(DesignSystem.radiusSm)
            }

            // Confidence selection (self-reported)
            if hasSubmitted && confidence == nil {
                VStack(spacing: 12) {
                    Text("How completely did you capture it?")
                        .font(.custom("DM Sans", size: 13))
                        .foregroundColor(DesignSystem.ink3)

                    HStack(spacing: 12) {
                        ConfidenceButton(label: "Nailed it", subtitle: "Full tree", style: .easy) {
                            reportConfidence(.gotIt)
                        }
                        ConfidenceButton(label: "Okay", subtitle: "Some gaps", style: .okay) {
                            reportConfidence(.struggled)
                        }
                        ConfidenceButton(label: "Hard", subtitle: "Missed core", style: .hard) {
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
            revealedStructure = buildStructure()
        }
        .onChange(of: exercise.id) { _, _ in
            hasSubmitted = false
            confidence = nil
            revealedStructure = buildStructure()
        }
    }

    private func reportConfidence(_ level: ConfidenceLevel) {
        confidence = level
        viewModel.reportConfidence(level)
        viewModel.nextExercise()
    }

    /// Build the revealed structure from the tidbit's stored facets.
    private func buildStructure() -> String {
        var parts: [String] = []
        parts.append("Thesis: \(exercise.tidbit.concept)")
        if !exercise.tidbit.body.isEmpty {
            parts.append("Claim: \(exercise.tidbit.body)")
        }
        if let simple = exercise.tidbit.simpleMeaning {
            parts.append("In short: \(simple)")
        }
        if !exercise.tidbit.examples.isEmpty {
            parts.append("Evidence: " + exercise.tidbit.examples.joined(separator: "; "))
        }
        if let notes = exercise.tidbit.meaningNotes {
            parts.append("Support: \(notes)")
        }
        return parts.joined(separator: "\n")
    }
}

// MARK: - Preview

#Preview {
    ArgumentMapExerciseView(
        exercise: ExerciseInstance(
            tidbit: Tidbit(
                concept: "Metrics corrupt under pressure",
                body: "Once people are judged on a measure, behavior shifts to maximize the number.",
                sourceTitle: "Goodhart & Campbell",
                examples: ["Teachers teaching to tests.", "Devs closing tickets over fixing problems."]
            ),
            exerciseType: .argumentMap
        ),
        viewModel: SessionViewModel()
    )
    .padding()
    .background(DesignSystem.parchment)
}
