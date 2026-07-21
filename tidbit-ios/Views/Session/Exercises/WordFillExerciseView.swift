import SwiftUI

// MARK: - Word Fill Exercise (Multiple Blanks)

struct WordFillExerciseView: View {
    let exercise: ExerciseInstance
    @Bindable var viewModel: SessionViewModel
    var showDrawer: Bool = true
    
    @State private var blanks: [BlankWord] = []
    @State private var availableWords: [String] = []
    @State private var selectedWords: [String?] = []
    @State private var hasSubmitted = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Instruction
            VStack(spacing: 8) {
                Text("Fill in the missing words:")
                    .font(.custom("DM Sans", size: 14))
                    .foregroundColor(DesignSystem.ink3)
            }
            
            // Line with blanks
            VStack(spacing: 12) {
                // Show the line with blank indicators
                Text(displayText)
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
                
                // Number of blanks indicator
                Text("\(blanks.count) words missing")
                    .font(.custom("DM Sans", size: 12))
                    .foregroundColor(DesignSystem.ink3)
            }
            
            // Selected words (answers)
            if !selectedWords.isEmpty {
                VStack(spacing: 8) {
                    Text("Your answer:")
                        .font(.custom("DM Sans", size: 12))
                        .foregroundColor(DesignSystem.ink3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: 8) {
                        ForEach(Array(selectedWords.enumerated()), id: \.offset) { index, word in
                            if let word = word {
                                Text(word)
                                    .font(.custom("DM Sans", size: 14).weight(.medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(colorForBlank(at: index))
                                    .cornerRadius(16)
                            } else {
                                Text("___")
                                    .font(.custom("DM Sans", size: 14))
                                    .foregroundColor(DesignSystem.ink4)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(DesignSystem.parchment2)
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(.white.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [3]))
                                    )
                            }
                        }
                    }
                }
            }
            
            // Available word chips
            if !hasSubmitted && !viewModel.showFeedback {
                VStack(spacing: 8) {
                    Text("Tap to select:")
                        .font(.custom("DM Sans", size: 12))
                        .foregroundColor(DesignSystem.ink3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    FlowLayout(spacing: 8) {
                        ForEach(availableWords, id: \.self) { word in
                            Button {
                                selectWord(word)
                            } label: {
                                Text(word)
                                    .font(.custom("DM Sans", size: 14))
                                    .foregroundColor(DesignSystem.ink)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(DesignSystem.parchment2)
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(DesignSystem.parchment3, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            
            // Show correct answer if feedback
            if viewModel.showFeedback {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Correct answer:")
                        .font(.custom("DM Sans", size: 11))
                        .foregroundColor(DesignSystem.ink3)
                        .textCase(.uppercase)
                    
                    HStack(spacing: 8) {
                        ForEach(blanks) { blank in
                            Text(blank.word)
                                .font(.custom("DM Sans", size: 14).weight(.medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(DesignSystem.green)
                                .cornerRadius(16)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(DesignSystem.parchment2)
                .cornerRadius(DesignSystem.radiusSm)
            }
        }
        .onAppear {
            prepareBlanks()
        }
        .onChange(of: exercise.id) { _, _ in
            hasSubmitted = false
            blanks = []
            availableWords = []
            selectedWords = []
            prepareBlanks()
        }
    }
    
    private var displayText: String {
        let words = exercise.tidbit.body.components(separatedBy: " ")
        var result: [String] = []
        var blankIndex = 0
        
        for word in words {
            if blanks.contains(where: { $0.word == word.trimmingCharacters(in: .punctuationCharacters) }) {
                let filledWord = selectedWords[safe: blankIndex] ?? "_____"
                result.append(filledWord.map { word.hasSuffix(",") ? $0 + "," : $0 } ?? "_____")
                blankIndex += 1
            } else {
                result.append(word)
            }
        }
        
        return result.joined(separator: " ")
    }
    
    private func colorForBlank(at index: Int) -> Color {
        guard hasSubmitted else { return DesignSystem.accent }
        guard index < selectedWords.count,
              index < blanks.count,
              let selected = selectedWords[index] else { return DesignSystem.red }
        let blank = blanks[index]
        
        let normalizedSelected = selected.trimmingCharacters(in: .punctuationCharacters).lowercased()
        let normalizedBlank = blank.word.lowercased()
        
        return normalizedSelected == normalizedBlank ? DesignSystem.green : DesignSystem.red
    }
    
    private func prepareBlanks() {
        let words = exercise.tidbit.body.components(separatedBy: " ")
        let cleanWords = words.map { $0.trimmingCharacters(in: .punctuationCharacters) }
        
        // Select 2-3 significant words to blank out
        // Prefer longer words (>4 chars) and avoid common words
        let commonWords = ["the", "and", "but", "for", "was", "were", "been", "have", "has", "had", "will", "would", "could", "should", "may", "might", "must", "shall", "can", "need", "dare", "ought", "used", "to", "of", "in", "it", "is", "a", "an", "as", "at", "be", "by", "he", "she", "his", "her", "its", "my", "your", "their", "our", "on", "or", "that", "this", "with"]
        
        let significantIndices = cleanWords.enumerated()
            .filter { $0.element.count > 4 && !commonWords.contains($0.element.lowercased()) }
            .map { $0.offset }
        
        // Pick 2-3 blanks (or fewer if not enough significant words)
        let blankCount = min(3, max(2, significantIndices.count))
        let selectedIndices = Array(significantIndices.shuffled().prefix(blankCount)).sorted()
        
        blanks = selectedIndices.map { index in
            BlankWord(word: cleanWords[index], index: index, partOfSpeech: PartOfSpeech.classify(cleanWords[index]))
        }
        
        // Create available words with distractors
        var wordPool = blanks.map { $0.word }
        
        // Add distractors matching part of speech
        if let session = viewModel.session {
            let allWords = session.exerciseQueue
                .flatMap { $0.tidbit.body.components(separatedBy: " ") }
                .map { $0.trimmingCharacters(in: .punctuationCharacters) }
                .filter { $0.count > 4 && !commonWords.contains($0.lowercased()) }
            
            // Get unique words with their parts of speech
            var distractorsByPOS: [PartOfSpeech: [String]] = [:]
            for word in Set(allWords) {
                let pos = PartOfSpeech.classify(word)
                if pos != .other {
                    distractorsByPOS[pos, default: []].append(word)
                }
            }
            
            // For each blank, find distractors of same part of speech
            for blank in blanks {
                if let sameTypeWords = distractorsByPOS[blank.partOfSpeech] {
                    let distractors = sameTypeWords
                        .filter { $0 != blank.word }
                        .shuffled()
                        .prefix(2)
                    wordPool.append(contentsOf: distractors)
                }
            }
        }
        
        availableWords = Array(Set(wordPool)).shuffled()
        selectedWords = Array(repeating: nil, count: blanks.count)
    }
    
    private func selectWord(_ word: String) {
        // Find first empty slot
        guard let emptyIndex = selectedWords.firstIndex(where: { $0 == nil }) else { return }
        selectedWords[emptyIndex] = word
        
        // Remove from available
        availableWords.removeAll { $0 == word }
        
        // Check if all blanks filled
        if !selectedWords.contains(nil) {
            submitAnswer()
        }
    }
    
    private func submitAnswer() {
        hasSubmitted = true
        // Score against the correct blank words in order (not the whole body).
        let correct = blanks.map { $0.word }.joined(separator: " ")
        viewModel.userInput = selectedWords.compactMap { $0 }.joined(separator: " ")
        viewModel.submitAnswer(correctAnswer: correct)
    }
}

// MARK: - Blank Word Model

struct BlankWord: Identifiable {
    let id = UUID()
    let word: String
    let index: Int
    let partOfSpeech: PartOfSpeech
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth, x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}

// MARK: - Preview

#Preview {
    WordFillExerciseView(
        exercise: ExerciseInstance(
            tidbit: Tidbit(
                concept: "Line 1",
                body: "Because I could not stop for Death —",
                sourceTitle: "Because I Could Not Stop for Death"
            ),
            exerciseType: .wordFill
        ),
        viewModel: SessionViewModel()
    )
    .padding()
    .background(DesignSystem.parchment)
}
