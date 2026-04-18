import SwiftUI

struct LinePromptExerciseView: View {
    let exercise: ExerciseInstance
    @Bindable var viewModel: SessionViewModel
    var showDrawer: Bool = true
    
    @State private var previousLine: String?
    
    var body: some View {
        VStack(spacing: 20) {
            // Cue section - show the previous line or starting context
            VStack(spacing: 8) {
                if let cue = previousLine {
                    Text("Previous line:")
                        .font(.custom("DM Sans", size: 13).weight(.medium))
                        .foregroundColor(DesignSystem.ink3)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    
                    Text(cue)
                        .font(DesignSystem.serif(size: 20))
                        .italic()
                        .foregroundColor(DesignSystem.ink2)
                        .multilineTextAlignment(.center)
                } else {
                    // First line - show the actual first line with context
                    Text("Starting line:")
                        .font(.custom("DM Sans", size: 13).weight(.medium))
                        .foregroundColor(DesignSystem.ink3)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    
                    // Show the first line of the poem being tested
                    let firstLine = exercise.tidbit.body.components(separatedBy: "\n").first ?? exercise.tidbit.body
                    Text(firstLine)
                        .font(DesignSystem.serif(size: 20))
                        .italic()
                        .foregroundColor(DesignSystem.ink2)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(DesignSystem.parchment2)
            .cornerRadius(DesignSystem.radius)
            
            // Arrow
            Image(systemName: "arrow.down")
                .font(.system(size: 24))
                .foregroundColor(DesignSystem.ink4)
            
            // Prompt - varies based on position
            Text(previousLine == nil ? "Type this line:" : "Type the next line:")
                .font(.custom("DM Sans", size: 13))
                .foregroundColor(DesignSystem.ink3)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Show result if feedback
            if viewModel.showFeedback, let result = viewModel.lastResult {
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
                
                if result.passed {
                    HStack {
                        Spacer()
                        Label("exact match", systemImage: "checkmark")
                            .font(.custom("DM Sans", size: 12).weight(.medium))
                            .foregroundColor(DesignSystem.green)
                    }
                }
            }
        }
        .onAppear {
            findPreviousLine()
        }
        .onChange(of: exercise.id) { _, _ in
            // Reset when exercise changes
            viewModel.userInput = ""
            previousLine = nil
            findPreviousLine()
        }
    }
    
    private func findPreviousLine() {
        // Find the previous tidbit in sequence from the session's exercise queue
        let currentIndex = exercise.tidbit.sequenceIndex
        guard currentIndex > 0 else {
            previousLine = nil
            return
        }
        
        // Look through the session's exercises to find the previous tidbit
        if let session = viewModel.session {
            let allExercises = session.exerciseQueue
            if let prevExercise = allExercises.first(where: { $0.tidbit.sequenceIndex == currentIndex - 1 }) {
                previousLine = prevExercise.tidbit.body
            } else {
                previousLine = nil
            }
        }
    }
}

// MARK: - Preview

#Preview {
    LinePromptExerciseView(
        exercise: ExerciseInstance(
            tidbit: Tidbit(
                concept: "Line 1",
                body: "Because I could not stop for Death —",
                sourceTitle: "Because I Could Not Stop for Death"
            ),
            exerciseType: .linePrompt
        ),
        viewModel: SessionViewModel()
    )
    .padding()
    .background(DesignSystem.parchment)
}
