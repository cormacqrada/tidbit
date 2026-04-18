import SwiftUI
import SwiftData

struct CreateLessonFlow: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var viewModel = CreateLessonViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                DesignSystem.parchment
                    .ignoresSafeArea()
                
                // Content based on current step
                Group {
                    switch viewModel.currentStep {
                    case .source:
                        SourceSelectionView(viewModel: viewModel)
                    case .configure:
                        ConfigureView(viewModel: viewModel)
                    case .exerciseMix:
                        ExerciseMixView(viewModel: viewModel)
                    case .processing:
                        ProcessingView(viewModel: viewModel, onComplete: completeLesson)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.reset()
                        dismiss()
                    }
                    .foregroundColor(DesignSystem.ink3)
                }
            }
            .toolbarBackground(DesignSystem.parchment, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
    
    private func completeLesson() {
        // Create and save the lesson
        _ = viewModel.createLesson(modelContext: modelContext)
        
        // Reset and dismiss
        viewModel.reset()
        dismiss()
    }
}

// MARK: - Step Indicator

struct StepIndicator: View {
    let currentStep: CreateLessonStep
    let label: String
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(CreateLessonStep.allCases, id: \.self) { step in
                if step.rawValue <= currentStep.rawValue {
                    RoundedRectangle(cornerRadius: 3)
                        .frame(width: step == currentStep ? 20 : 6, height: 6)
                        .foregroundColor(step == currentStep ? DesignSystem.violet : DesignSystem.parchment3)
                } else {
                    Circle()
                        .frame(width: 6, height: 6)
                        .foregroundColor(DesignSystem.parchment3)
                }
            }
            
            Text(label)
                .font(.custom("DM Sans", size: 11).weight(.medium))
                .foregroundColor(DesignSystem.ink3)
                .tracking(0.6)
                .textCase(.uppercase)
                .padding(.leading, 2)
        }
        .padding(.vertical, 16)
    }
}

// MARK: - Preview

#Preview {
    CreateLessonFlow()
        .modelContainer(for: [Lesson.self, Tidbit.self], inMemory: true)
}
