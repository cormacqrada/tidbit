import SwiftUI

// MARK: - Evidence For Exercise

/// Recall (scored via self-report). Given a sub-claim, the user names its
/// supporting evidence from memory, then compares to the stored evidence.
/// Targets the thesis domain.
struct EvidenceForExerciseView: View {
    let exercise: ExerciseInstance
    @Bindable var viewModel: SessionViewModel
    var showDrawer: Bool = true

    @State private var hasSubmitted = false
    @State private var confidence: ConfidenceLevel?

    var body: some View {
        VStack(spacing: 24) {
            // Instruction
            Text("Name the evidence for this claim:")
                .font(.custom("DM Sans", size: 14))
                .foregroundColor(DesignSystem.ink3)

            // The claim
            VStack(spacing: 8) {
                Text(exercise.tidbit.concept)
                    .font(DesignSystem.serif(size: 20))
                    .italic()
                    .foregroundColor(DesignSystem.ink)

                if let simple = exercise.tidbit.simpleMeaning {
                    Text(simple)
                        .font(.custom("DM Sans", size: 13))
                        .foregroundColor(DesignSystem.ink3)
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

            // User's evidence (shown after submission)
            if hasSubmitted, !viewModel.userInput.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your evidence:")
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

                // Reveal stored evidence for self-comparison
                if !exercise.tidbit.examples.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Supporting evidence:")
                            .font(.custom("DM Sans", size: 11))
                            .foregroundColor(DesignSystem.ink3)
                            .textCase(.uppercase)

                        ForEach(exercise.tidbit.examples, id: \.self) { example in
                            Text("• \(example)")
                                .font(DesignSystem.serif(size: 15))
                                .foregroundColor(DesignSystem.ink2)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(DesignSystem.parchment2)
                    .cornerRadius(DesignSystem.radiusSm)
                }
            }

            // Confidence selection (self-reported)
            if hasSubmitted && confidence == nil {
                VStack(spacing: 12) {
                    Text("Did you name the right evidence?")
                        .font(.custom("DM Sans", size: 13))
                        .foregroundColor(DesignSystem.ink3)

                    HStack(spacing: 12) {
                        ConfidenceButton(label: "Nailed it", subtitle: "Right evidence", style: .easy) {
                            reportConfidence(.gotIt)
                        }
                        ConfidenceButton(label: "Okay", subtitle: "Partial", style: .okay) {
                            reportConfidence(.struggled)
                        }
                        ConfidenceButton(label: "Hard", subtitle: "Blanked", style: .hard) {
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
    EvidenceForExerciseView(
        exercise: ExerciseInstance(
            tidbit: Tidbit(
                concept: "Goodhart's Law",
                body: "When a measure becomes a target, it ceases to be a good measure.",
                sourceTitle: "Notes",
                examples: ["Teachers teaching to standardized tests."]
            ),
            exerciseType: .evidenceFor
        ),
        viewModel: SessionViewModel()
    )
    .padding()
    .background(DesignSystem.parchment)
}
