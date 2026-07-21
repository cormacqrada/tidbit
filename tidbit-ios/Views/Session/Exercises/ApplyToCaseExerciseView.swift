import SwiftUI

// MARK: - Apply to Case Exercise

/// Recall (scored via self-report). Given a novel scenario drawn from the tidbit's
/// stored examples (or synthesized from the definition), the user explains whether
/// and how the concept applies. Targets concept transfer + strategic domains.
struct ApplyToCaseExerciseView: View {
    let exercise: ExerciseInstance
    @Bindable var viewModel: SessionViewModel
    var showDrawer: Bool = true

    @State private var hasSubmitted = false
    @State private var confidence: ConfidenceLevel?
    @State private var scenario: String = ""

    var body: some View {
        VStack(spacing: 24) {
            // Instruction
            Text("Apply this concept to a new case:")
                .font(.custom("DM Sans", size: 14))
                .foregroundColor(DesignSystem.ink3)

            // The concept to apply
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

            // The novel scenario
            VStack(alignment: .leading, spacing: 8) {
                Text("Scenario")
                    .font(.custom("DM Sans", size: 11))
                    .foregroundColor(DesignSystem.ink3)
                    .textCase(.uppercase)

                Text(scenario)
                    .font(DesignSystem.serif(size: 16))
                    .foregroundColor(DesignSystem.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(DesignSystem.parchment2)
                    .cornerRadius(DesignSystem.radius)
            }

            Text("Does this concept apply here, and what would happen?")
                .font(.custom("DM Sans", size: 13))
                .foregroundColor(DesignSystem.ink3)
                .frame(maxWidth: .infinity, alignment: .leading)

            // User's explanation (shown after submission)
            if hasSubmitted, !viewModel.userInput.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your answer:")
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
            }

            // Confidence selection (self-reported)
            if hasSubmitted && confidence == nil {
                confidenceRow(prompt: "How well did you apply it?")
            }
        }
        .onAppear {
            hasSubmitted = false
            confidence = nil
            scenario = pickScenario()
        }
        .onChange(of: exercise.id) { _, _ in
            hasSubmitted = false
            confidence = nil
            scenario = pickScenario()
        }
    }

    private func confidenceRow(prompt: String) -> some View {
        VStack(spacing: 12) {
            Text(prompt)
                .font(.custom("DM Sans", size: 13))
                .foregroundColor(DesignSystem.ink3)

            HStack(spacing: 12) {
                ConfidenceButton(label: "Nailed it", subtitle: "Applied it", style: .easy) {
                    reportConfidence(.gotIt)
                }
                ConfidenceButton(label: "Okay", subtitle: "Partial", style: .okay) {
                    reportConfidence(.struggled)
                }
                ConfidenceButton(label: "Hard", subtitle: "Missed it", style: .hard) {
                    reportConfidence(.skipped)
                }
            }
        }
        .padding(.top, 8)
    }

    private func reportConfidence(_ level: ConfidenceLevel) {
        confidence = level
        viewModel.reportConfidence(level)
        viewModel.nextExercise()
    }

    /// Pick a scenario. Prefer stored examples (rendered as a near-novel framing);
    /// fall back to a templated scenario derived from the definition.
    private func pickScenario() -> String {
        if let example = exercise.tidbit.examples.randomElement() {
            return "Consider: \(example)"
        }
        let concept = exercise.tidbit.concept
        let templates = [
            "A team adopts a new metric to evaluate performance. Where might \(concept) show up?",
            "A friend describes a situation at work that reminds you of \(concept). What do you point out?",
            "You see a news headline that looks like an instance of \(concept). What's your read?"
        ]
        return templates.randomElement() ?? templates[0]
    }
}

// MARK: - Preview

#Preview {
    ApplyToCaseExerciseView(
        exercise: ExerciseInstance(
            tidbit: Tidbit(
                concept: "Goodhart's Law",
                body: "When a measure becomes a target, it ceases to be a good measure.",
                sourceTitle: "Notes",
                examples: ["Teachers teaching to standardized tests."]
            ),
            exerciseType: .applyToCase
        ),
        viewModel: SessionViewModel()
    )
    .padding()
    .background(DesignSystem.parchment)
}
