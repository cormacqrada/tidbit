import SwiftUI

struct ExerciseMixView: View {
    @Bindable var viewModel: CreateLessonViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Step indicator
                StepIndicator(currentStep: .exerciseMix, label: "Exercises")
                
                // Title
                Text("Exercise mix")
                    .font(DesignSystem.serif(size: 22))
                    .foregroundColor(DesignSystem.ink)
                
                // Subtitle
                Text("Tuned for ")
                    .font(.custom("DM Sans", size: 13))
                    .foregroundColor(DesignSystem.ink3) +
                Text("\(viewModel.contentType.displayName.lowercased()) · \(viewModel.learningGoal.displayName.lowercased())")
                    .font(.custom("DM Sans", size: 13).italic())
                    .foregroundColor(DesignSystem.violet) +
                Text(". Adjust freely.")
                    .font(.custom("DM Sans", size: 13))
                    .foregroundColor(DesignSystem.ink3)
                
                // Exercise list
                VStack(spacing: 8) {
                    ForEach($viewModel.exerciseMix) { $weight in
                        ExerciseRow(
                            type: weight.type,
                            weight: $weight.weight,
                            isEnabled: !weight.type.requiresAI
                        )
                    }
                    
                    // AI badge note
                    HStack(spacing: 6) {
                        Text("AI")
                            .font(.custom("DM Sans", size: 9).weight(.bold))
                            .foregroundColor(DesignSystem.violet)
                            .frame(width: 16, height: 16)
                            .background(DesignSystem.violetLight)
                            .cornerRadius(4)
                        
                        Text("Meaning probe, explain back, vocab match require AI")
                            .font(.custom("DM Sans", size: 11))
                            .foregroundColor(DesignSystem.ink3)
                    }
                    .padding(.top, 6)
                }
                .padding(.top, 16)
                
                // Reset button
                Button {
                    viewModel.generateExerciseMix()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset to recommended")
                    }
                    .font(.custom("DM Sans", size: 13))
                    .foregroundColor(DesignSystem.violet)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(DesignSystem.violetLight)
                    .cornerRadius(DesignSystem.radius)
                }
                .padding(.top, 12)
                
                // Generate button
                Button("Generate lesson →") {
                    Task {
                        await viewModel.startProcessing()
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 16)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Exercise Row

struct ExerciseRow: View {
    let type: ExerciseType
    @Binding var weight: Int
    let isEnabled: Bool
    
    var body: some View {
        HStack(spacing: 10) {
            // Checkbox for enable/disable
            Button {
                if weight > 0 {
                    weight = 0  // Disable
                } else {
                    weight = 3  // Enable with default weight
                }
            } label: {
                Image(systemName: weight > 0 ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(weight > 0 ? DesignSystem.accent : DesignSystem.ink4)
            }
            .buttonStyle(.plain)
            .disabled(!isEnabled)
            
            // Icon
            ExerciseIcon(type: type)
            
            // Name and subtitle
            VStack(alignment: .leading, spacing: 1) {
                Text(type.displayName)
                    .font(.custom("DM Sans", size: 13).weight(.medium))
                    .foregroundColor(DesignSystem.ink)
                
                Text(type.subtitle)
                    .font(.custom("DM Sans", size: 11))
                    .foregroundColor(DesignSystem.ink3)
            }
            
            Spacer()
            
            // Frequency dots or AI badge
            if type.requiresAI {
                // AI badge for exercises that require AI
                Text("AI")
                    .font(.custom("DM Sans", size: 9).weight(.bold))
                    .foregroundColor(DesignSystem.violet)
                    .frame(width: 20, height: 16)
                    .background(DesignSystem.violetLight)
                    .cornerRadius(4)
            } else {
                // Tappable frequency dots
                FrequencyDots(count: weight, onTap: {
                    // Cycle: 0 → 1 → 2 → 3 → 4 → 5 → 0
                    weight = (weight + 1) % 6
                })
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(DesignSystem.card)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(DesignSystem.parchment3, lineWidth: 1)
        )
        .opacity(isEnabled && (type.requiresAI || weight > 0) ? 1 : 0.5)
    }
}

// MARK: - Frequency Dots

struct FrequencyDots: View {
    let count: Int
    var onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 3) {
                ForEach(0..<5, id: \.self) { index in
                    Circle()
                        .frame(width: 8, height: 8)
                        .foregroundColor(index < count ? DesignSystem.violet : DesignSystem.parchment3)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ExerciseMixView(viewModel: {
        let vm = CreateLessonViewModel()
        vm.ingestionResult = IngestionResult(
            text: "Test",
            contentType: .poem,
            detectedLanguage: "English",
            estimatedLineCount: 4,
            suggestedTitle: "Test Poem",
            detectedAuthor: nil
        )
        vm.learningGoal = .memorizeVerbatim
        vm.generateExerciseMix()
        return vm
    }())
}
