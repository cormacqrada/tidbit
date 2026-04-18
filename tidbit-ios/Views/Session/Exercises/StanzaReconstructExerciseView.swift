import SwiftUI

struct StanzaReconstructExerciseView: View {
    let exercise: ExerciseInstance
    @Bindable var viewModel: SessionViewModel
    
    @State private var shuffledLines: [ReorderableLine] = []
    @State private var correctOrder: [String] = []
    @State private var hasSubmitted = false
    @State private var stanzaLines: [Tidbit] = []  // All lines from the same stanza
    
    var body: some View {
        VStack(spacing: 24) {
            // Instruction
            VStack(spacing: 8) {
                Text("Reconstruct the stanza:")
                    .font(.custom("DM Sans", size: 14))
                    .foregroundColor(DesignSystem.ink3)
                
                if let stanza = exercise.tidbit.stanzaIndex {
                    Text("Stanza \(stanza + 1) · \(stanzaLines.count) lines")
                        .font(.custom("DM Sans", size: 12).weight(.medium))
                        .foregroundColor(DesignSystem.violet)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(DesignSystem.violetLight)
                        .cornerRadius(12)
                }
            }
            
            // Drag and drop area
            VStack(spacing: 8) {
                ForEach(shuffledLines) { line in
                    DraggableLineView(
                        line: line,
                        isCorrect: isCorrectPosition(for: line)
                    )
                    .onDrag {
                        // Return NSItemProvider with line ID
                        return NSItemProvider(object: line.id.uuidString as NSString)
                    }
                    .onDrop(of: [.text], delegate: ReorderDropDelegate(
                        item: line,
                        items: $shuffledLines,
                        hasSubmitted: hasSubmitted
                    ))
                }
            }
            .padding()
            .background(DesignSystem.card)
            .cornerRadius(DesignSystem.radius)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.radius)
                    .stroke(DesignSystem.parchment3, lineWidth: 1)
            )
            
            // Hint button
            if !viewModel.showFeedback && !viewModel.showHint && exercise.config.hintPolicy != .never {
                Button {
                    viewModel.useHint()
                    // Show first line in correct position
                    if let firstCorrect = correctOrder.first,
                       let index = shuffledLines.firstIndex(where: { $0.text == firstCorrect }) {
                        shuffledLines[index].order = 0
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "lightbulb")
                        Text("Show first line")
                    }
                    .font(.custom("DM Sans", size: 13))
                    .foregroundColor(DesignSystem.violet)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(DesignSystem.violetLight)
                    .cornerRadius(20)
                }
            }
            
            // Submit button
            Button("Submit") {
                calculateScore()
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(hasSubmitted)
            .padding(.top, 8)
        }
        .onAppear {
            prepareLines()
        }
        .onChange(of: exercise.id) { _, _ in
            // Reset when exercise changes
            hasSubmitted = false
            viewModel.userInput = ""
            shuffledLines = []
            correctOrder = []
            stanzaLines = []
            prepareLines()
        }
        .overlay {
            if viewModel.showFeedback, let result = viewModel.lastResult {
                FeedbackOverlay(result: result) {
                    viewModel.nextExercise()
                }
            }
        }
    }
    
    private func prepareLines() {
        // Get the stanza index from this exercise's tidbit
        guard let stanzaIndex = exercise.tidbit.stanzaIndex else {
            // Fall back to single line if not a poem stanza
            let lines = exercise.tidbit.body.components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            correctOrder = lines
            shuffledLines = lines.shuffled().enumerated().map { index, text in
                ReorderableLine(id: UUID(), text: text, order: index)
            }
            return
        }
        
        // Gather all tidbits from the same stanza from the session
        if let session = viewModel.session {
            let allTidbits = session.exerciseQueue.map { $0.tidbit }
            stanzaLines = allTidbits
                .filter { $0.stanzaIndex == stanzaIndex }
                .sorted { $0.sequenceIndex < $1.sequenceIndex }
            
            // Use the body of each tidbit (each line is a separate tidbit)
            correctOrder = stanzaLines.map { $0.body }
        } else {
            // Fallback
            correctOrder = [exercise.tidbit.body]
        }
        
        // Shuffle for display
        let shuffled = correctOrder.shuffled()
        shuffledLines = shuffled.enumerated().map { index, text in
            ReorderableLine(id: UUID(), text: text, order: index)
        }
    }
    
    private func calculateScore() {
        hasSubmitted = true
        
        // Calculate how many lines are in correct position
        var correctCount = 0
        for (index, line) in shuffledLines.sorted(by: { $0.order < $1.order }).enumerated() {
            if line.text == correctOrder[index] {
                correctCount += 1
            }
        }
        
        let score = Double(correctCount) / Double(correctOrder.count)
        
        // Store user's ordering as the answer
        let userAnswer = shuffledLines.sorted(by: { $0.order < $1.order })
            .map(\.text).joined(separator: "\n")
        viewModel.userInput = userAnswer
        
        viewModel.submitAnswer()
    }
    
    private func isCorrectPosition(for line: ReorderableLine) -> Bool? {
        guard hasSubmitted else { return nil }
        guard line.order < correctOrder.count else { return false }
        return correctOrder[line.order] == line.text
    }
}

// MARK: - Reorderable Line Model

struct ReorderableLine: Identifiable, Equatable {
    let id: UUID
    let text: String
    var order: Int
    
    static func == (lhs: ReorderableLine, rhs: ReorderableLine) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Draggable Line View

struct DraggableLineView: View {
    let line: ReorderableLine
    var isCorrect: Bool?
    
    var body: some View {
        HStack(spacing: 12) {
            // Drag handle
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 14))
                .foregroundColor(DesignSystem.ink4)
            
            // Line number
            Text("\(line.order + 1)")
                .font(.custom("DM Sans", size: 11).weight(.medium))
                .foregroundColor(DesignSystem.ink3)
                .frame(width: 20)
            
            // Text
            Text(line.text)
                .font(DesignSystem.serif(size: 16))
                .foregroundColor(DesignSystem.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(backgroundColor)
        .cornerRadius(DesignSystem.radiusSm)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.radiusSm)
                .stroke(borderColor, lineWidth: 1)
        )
    }
    
    var backgroundColor: Color {
        if let correct = isCorrect {
            return correct ? DesignSystem.greenLight : DesignSystem.redLight
        }
        return DesignSystem.parchment2
    }
    
    var borderColor: Color {
        if let correct = isCorrect {
            return correct ? DesignSystem.green : DesignSystem.red
        }
        return DesignSystem.parchment3
    }
}

// MARK: - Drop Delegate

struct ReorderDropDelegate: DropDelegate {
    let item: ReorderableLine
    @Binding var items: [ReorderableLine]
    let hasSubmitted: Bool
    
    func performDrop(info: DropInfo) -> Bool {
        guard !hasSubmitted else { return false }
        return true
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
    
    func dropEntered(info: DropInfo) {
        guard !hasSubmitted else { return }
        
        // Find the item being dragged
        guard let draggedId = info.itemProviders(for: [.text]).first else { return }
        
        // This is a simplified version - full implementation would track drag source
        // For now, we'll use a simpler tap-to-swap approach in a separate view
    }
}

// MARK: - Simplified Tap-to-Swap View (Alternative for MVP)

struct TapToReorderExerciseView: View {
    let exercise: ExerciseInstance
    @Bindable var viewModel: SessionViewModel
    var showDrawer: Bool = true
    
    @State private var lines: [String] = []
    @State private var correctOrder: [String] = []
    @State private var selectedIndex: Int?
    @State private var hasSubmitted = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Instruction
            VStack(spacing: 8) {
                Text("Tap two lines to swap them:")
                    .font(.custom("DM Sans", size: 13))
                    .foregroundColor(DesignSystem.ink3)
                
                Text("Reconstruct the correct order")
                    .font(.custom("DM Sans", size: 12))
                    .foregroundColor(DesignSystem.ink3)
            }
            
            // Lines
            VStack(spacing: 4) {
                ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                    Button {
                        handleTap(at: index)
                    } label: {
                        HStack(spacing: 12) {
                            Text("\(index + 1)")
                                .font(.custom("DM Sans", size: 11).weight(.medium))
                                .foregroundColor(selectedIndex == index ? .white : DesignSystem.ink3)
                                .frame(width: 20)
                            
                            Text(line)
                                .font(DesignSystem.serif(size: 20))
                                .italic()
                                .foregroundColor(selectedIndex == index ? .white : DesignSystem.ink)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 16)
                        .background(selectedIndex == index ? DesignSystem.accent : backgroundColor(for: index))
                        .cornerRadius(DesignSystem.radiusSm)
                    }
                    .buttonStyle(.plain)
                    .disabled(hasSubmitted)
                }
            }
            .padding(16)
            .background(DesignSystem.card)
            .cornerRadius(DesignSystem.radius)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.radius)
                    .stroke(DesignSystem.parchment3, lineWidth: 1)
            )
            
            // Instructions
            if !hasSubmitted {
                Text("Tap a line to select, then tap another to swap")
                    .font(.custom("DM Sans", size: 12))
                    .foregroundColor(DesignSystem.ink4)
            }
        }
        .onAppear {
            prepareLines()
        }
        .onChange(of: exercise.id) { _, _ in
            // Reset when exercise changes
            hasSubmitted = false
            selectedIndex = nil
            viewModel.userInput = ""
            lines = []
            correctOrder = []
            prepareLines()
        }
    }
    
    func backgroundColor(for index: Int) -> Color {
        if !hasSubmitted {
            return DesignSystem.parchment2
        }
        return lines[index] == correctOrder[index] ? DesignSystem.greenLight : DesignSystem.redLight
    }
    
    private func prepareLines() {
        let lineArray = exercise.tidbit.body.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        correctOrder = lineArray
        lines = lineArray.shuffled()
    }
    
    private func handleTap(at index: Int) {
        if let selected = selectedIndex {
            if selected == index {
                // Deselect
                selectedIndex = nil
            } else {
                // Swap
                lines.swapAt(selected, index)
                selectedIndex = nil
            }
        } else {
            selectedIndex = index
        }
    }
    
    private func calculateScore() {
        hasSubmitted = true
        
        var correctCount = 0
        for (index, line) in lines.enumerated() {
            if line == correctOrder[index] {
                correctCount += 1
            }
        }
        
        let score = Double(correctCount) / Double(correctOrder.count)
        viewModel.userInput = lines.joined(separator: "\n")
        viewModel.submitAnswer()
    }
}

// MARK: - Preview

#Preview {
    TapToReorderExerciseView(
        exercise: ExerciseInstance(
            tidbit: Tidbit(
                concept: "Stanza 1",
                body: "Because I could not stop for Death —\nHe kindly stopped for me —\nThe Carriage held but just Ourselves —\nAnd Immortality.",
                stanzaIndex: 0,
                sourceTitle: "Because I Could Not Stop for Death"
            ),
            exerciseType: .stanzaReconstruct
        ),
        viewModel: SessionViewModel()
    )
    .padding()
    .background(DesignSystem.parchment)
}
