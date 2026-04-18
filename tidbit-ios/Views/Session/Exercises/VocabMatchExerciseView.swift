import SwiftUI

// MARK: - Vocab Match Exercise

struct VocabMatchExerciseView: View {
    let exercise: ExerciseInstance
    @Bindable var viewModel: SessionViewModel
    var showDrawer: Bool = true
    
    @State private var vocabItems: [VocabItem] = []
    @State private var selectedWord: VocabItem?
    @State private var hasSubmitted = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Instruction
            VStack(spacing: 8) {
                Text("Match the word to its context:")
                    .font(.custom("DM Sans", size: 14))
                    .foregroundColor(DesignSystem.ink3)
            }
            
            // The word to match
            if let word = selectedWord {
                VStack(spacing: 12) {
                    Text(word.word)
                        .font(DesignSystem.serif(size: 24))
                        .italic()
                        .foregroundColor(DesignSystem.ink)
                    
                    Text("Where does this word appear?")
                        .font(.custom("DM Sans", size: 13))
                        .foregroundColor(DesignSystem.ink3)
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(DesignSystem.card)
                .cornerRadius(DesignSystem.radius)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.radius)
                        .stroke(DesignSystem.parchment3, lineWidth: 1)
                )
            }
            
            // Answer choices
            if !hasSubmitted {
                VStack(spacing: 8) {
                    ForEach(vocabItems) { item in
                        Button {
                            selectAnswer(item)
                        } label: {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.context)
                                        .font(DesignSystem.serif(size: 14))
                                        .italic()
                                        .foregroundColor(DesignSystem.ink)
                                        .lineLimit(2)
                                    
                                    if let author = item.author {
                                        Text("— \(author)")
                                            .font(.custom("DM Sans", size: 11))
                                            .foregroundColor(DesignSystem.ink3)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                if item == selectedWord {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(DesignSystem.green)
                                }
                            }
                            .padding(12)
                            .background(item == selectedWord ? DesignSystem.greenLight : DesignSystem.parchment2)
                            .cornerRadius(DesignSystem.radiusSm)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.radiusSm)
                                    .stroke(item == selectedWord ? DesignSystem.green : DesignSystem.parchment3, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            // Show result after submission
            if hasSubmitted {
                VStack(spacing: 12) {
                    // Show correct answer
                    if let correctItem = vocabItems.first(where: { $0.isCorrect }) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Correct context:")
                                .font(.custom("DM Sans", size: 11))
                                .foregroundColor(DesignSystem.ink3)
                                .textCase(.uppercase)
                            
                            Text(correctItem.context)
                                .font(DesignSystem.serif(size: 14))
                                .italic()
                                .foregroundColor(DesignSystem.ink2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(DesignSystem.greenLight)
                        .cornerRadius(DesignSystem.radiusSm)
                    }
                }
            }
        }
        .onAppear {
            prepareVocabItems()
        }
        .onChange(of: exercise.id) { _, _ in
            hasSubmitted = false
            selectedWord = nil
            vocabItems = []
            prepareVocabItems()
        }
    }
    
    private func prepareVocabItems() {
        guard let session = viewModel.session else { return }
        
        let allTidbits = session.exerciseQueue.map { $0.tidbit }
        let currentTidbit = exercise.tidbit
        
        // Extract significant words from current tidbit
        let significantWords = extractSignificantWords(from: currentTidbit.body)
        guard let targetWord = significantWords.randomElement() else { return }
        
        // Create the correct item
        let correctItem = VocabItem(
            id: UUID(),
            word: targetWord,
            context: currentTidbit.body,
            author: currentTidbit.sourceAuthor,
            isCorrect: true
        )
        
        // Create distractor items from other tidbits
        let otherTidbits = allTidbits.filter { $0.id != currentTidbit.id }.shuffled()
        let distractors = otherTidbits.prefix(3).map { tidbit in
            VocabItem(
                id: UUID(),
                word: targetWord,
                context: tidbit.body,
                author: tidbit.sourceAuthor,
                isCorrect: false
            )
        }
        
        selectedWord = correctItem
        vocabItems = ([correctItem] + distractors).shuffled()
    }
    
    private func extractSignificantWords(from text: String) -> [String] {
        let commonWords = ["the", "and", "but", "for", "was", "were", "been", "have", "has", "had", "will", "would", "could", "should", "may", "might", "must", "shall", "can", "need", "dare", "ought", "used", "to", "of", "in", "it", "is", "a", "an", "as", "at", "be", "by", "he", "she", "his", "her", "its", "my", "your", "their", "our", "on", "or", "that", "this", "with", "not", "no", "yes", "all", "any", "some", "each", "every", "from", "into", "out", "up", "down", "over", "under", "again", "further", "then", "once", "here", "there", "when", "where", "why", "how", "what", "which", "who", "whom", "whose"]
        
        let words = text.components(separatedBy: .whitespaces)
            .map { $0.trimmingCharacters(in: .punctuation) }
            .filter { $0.count > 4 && !commonWords.contains($0.lowercased()) }
        
        return Array(Set(words)) // Unique words
    }
    
    private func selectAnswer(_ item: VocabItem) {
        hasSubmitted = true
        viewModel.userInput = item.context
        
        let score: Double = item.isCorrect ? 1.0 : 0.0
        viewModel.submitAnswer()
    }
}

// MARK: - Vocab Item Model

struct VocabItem: Identifiable, Equatable {
    let id: UUID
    let word: String
    let context: String
    let author: String?
    let isCorrect: Bool
    
    static func == (lhs: VocabItem, rhs: VocabItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Preview

#Preview {
    VocabMatchExerciseView(
        exercise: ExerciseInstance(
            tidbit: Tidbit(
                concept: "Line 1",
                body: "Because I could not stop for Death —",
                sourceTitle: "Because I Could Not Stop for Death",
                sourceAuthor: "Emily Dickinson"
            ),
            exerciseType: .vocabMatch
        ),
        viewModel: SessionViewModel()
    )
    .padding()
    .background(DesignSystem.parchment)
}
