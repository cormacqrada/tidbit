import SwiftUI

// MARK: - Concept Connect Exercise

struct ConceptConnectExerciseView: View {
    let exercise: ExerciseInstance
    @Bindable var viewModel: SessionViewModel
    var showDrawer: Bool = true
    
    @State private var connections: [ConnectionPair] = []
    @State private var leftItems: [ConnectionItem] = []
    @State private var rightItems: [ConnectionItem] = []
    @State private var selectedLeft: ConnectionItem?
    @State private var selectedRight: ConnectionItem?
    @State private var madeConnections: [UUID: UUID] = [:]  // leftID -> rightID
    @State private var hasSubmitted = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Instruction
            VStack(spacing: 8) {
                Text("Connect the related lines:")
                    .font(.custom("DM Sans", size: 14))
                    .foregroundColor(DesignSystem.ink3)
                
                Text("Tap a line on the left, then its match on the right")
                    .font(.custom("DM Sans", size: 12))
                    .foregroundColor(DesignSystem.ink4)
            }
            
            // Connection area
            HStack(alignment: .top, spacing: 16) {
                // Left column
                VStack(spacing: 8) {
                    ForEach(leftItems) { item in
                        ConnectionItemView(
                            item: item,
                            isSelected: selectedLeft?.id == item.id,
                            isConnected: madeConnections.keys.contains(item.id),
                            isCorrect: isConnectionCorrect(for: item.id),
                            hasSubmitted: hasSubmitted,
                            onTap: {
                                if !hasSubmitted, !madeConnections.keys.contains(item.id) {
                                    selectedLeft = item
                                    checkForMatch()
                                }
                            }
                        )
                    }
                }
                .frame(maxWidth: .infinity)
                
                // Connection lines indicator
                VStack {
                    Spacer()
                    Image(systemName: "arrow.left.and.right")
                        .font(.system(size: 20))
                        .foregroundColor(DesignSystem.ink4)
                    Spacer()
                }
                
                // Right column
                VStack(spacing: 8) {
                    ForEach(rightItems) { item in
                        ConnectionItemView(
                            item: item,
                            isSelected: selectedRight?.id == item.id,
                            isConnected: madeConnections.values.contains(item.id),
                            isCorrect: isRightConnectionCorrect(for: item.id),
                            hasSubmitted: hasSubmitted,
                            onTap: {
                                if !hasSubmitted, !madeConnections.values.contains(item.id) {
                                    selectedRight = item
                                    checkForMatch()
                                }
                            }
                        )
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(16)
            .background(DesignSystem.card)
            .cornerRadius(DesignSystem.radius)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.radius)
                    .stroke(DesignSystem.parchment3, lineWidth: 1)
            )
            
            // Progress
            Text("\(madeConnections.count) of \(leftItems.count) connected")
                .font(.custom("DM Sans", size: 12))
                .foregroundColor(DesignSystem.ink3)
            
            // Submit button (manual)
            if madeConnections.count == leftItems.count && !hasSubmitted {
                Button("Submit") {
                    hasSubmitted = true
                    calculateScore()
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .onAppear {
            prepareConnections()
        }
        .onChange(of: exercise.id) { _, _ in
            hasSubmitted = false
            connections = []
            leftItems = []
            rightItems = []
            selectedLeft = nil
            selectedRight = nil
            madeConnections = [:]
            prepareConnections()
        }
    }
    
    private func isConnectionCorrect(for leftId: UUID) -> Bool? {
        guard hasSubmitted, let rightId = madeConnections[leftId],
              let pair = connections.first(where: { $0.left.id == leftId }) else { return nil }
        return pair.right.id == rightId
    }
    
    private func isRightConnectionCorrect(for rightId: UUID) -> Bool? {
        guard hasSubmitted,
              let leftId = madeConnections.first(where: { $0.value == rightId })?.key,
              let pair = connections.first(where: { $0.right.id == rightId }) else { return nil }
        return pair.left.id == leftId
    }
    
    private func prepareConnections() {
        guard let session = viewModel.session else { return }
        
        let allTidbits = session.exerciseQueue.map { $0.tidbit }
        let currentTidbit = exercise.tidbit
        
        // For poems: connect lines from adjacent stanzas or related themes
        // For prose: connect concepts that share themes
        
        if let stanzaIndex = currentTidbit.stanzaIndex {
            // Poem: connect lines from this stanza with next stanza
            let currentStanzaLines = allTidbits
                .filter { $0.stanzaIndex == stanzaIndex }
                .sorted { $0.sequenceIndex < $1.sequenceIndex }
            
            let nextStanzaLines = allTidbits
                .filter { $0.stanzaIndex == stanzaIndex + 1 }
                .sorted { $0.sequenceIndex < $1.sequenceIndex }
            
            // Match by position in stanza (line 1 → line 1, etc.)
            let matchCount = min(currentStanzaLines.count, nextStanzaLines.count, 4)
            
            for i in 0..<matchCount {
                let leftItem = ConnectionItem(
                    id: UUID(),
                    text: currentStanzaLines[i].body,
                    tidbitId: currentStanzaLines[i].id
                )
                
                let rightItem = ConnectionItem(
                    id: UUID(),
                    text: nextStanzaLines[i].body,
                    tidbitId: nextStanzaLines[i].id
                )
                
                connections.append(ConnectionPair(left: leftItem, right: rightItem))
            }
        } else {
            // Prose: connect paragraphs by theme/concept
            // Simple approach: consecutive paragraphs
            let paragraphs = allTidbits.prefix(4)
            let paragraphsArray = Array(paragraphs)
            
            for i in 0..<(paragraphsArray.count - 1) {
                let leftItem = ConnectionItem(
                    id: UUID(),
                    text: String(paragraphsArray[i].body.prefix(50)) + "...",
                    tidbitId: paragraphsArray[i].id
                )
                
                let rightItem = ConnectionItem(
                    id: UUID(),
                    text: String(paragraphsArray[i + 1].body.prefix(50)) + "...",
                    tidbitId: paragraphsArray[i + 1].id
                )
                
                connections.append(ConnectionPair(left: leftItem, right: rightItem))
            }
        }
        
        leftItems = connections.map { $0.left }.shuffled()
        rightItems = connections.map { $0.right }.shuffled()
    }
    
    private func checkForMatch() {
        guard let left = selectedLeft, let right = selectedRight else { return }
        
        madeConnections[left.id] = right.id
        selectedLeft = nil
        selectedRight = nil
    }
    
    private func calculateScore() {
        var correctCount = 0
        for pair in connections {
            if let connectedRight = madeConnections[pair.left.id],
               connectedRight == pair.right.id {
                correctCount += 1
            }
        }
        
        let score = Double(correctCount) / Double(connections.count)
        viewModel.userInput = "\(correctCount)/\(connections.count) correct"
        viewModel.submitAnswer()
    }
}

// MARK: - Connection Models

struct ConnectionPair {
    let left: ConnectionItem
    let right: ConnectionItem
}

struct ConnectionItem: Identifiable {
    let id: UUID
    let text: String
    let tidbitId: UUID
}

// MARK: - Connection Item View

struct ConnectionItemView: View {
    let item: ConnectionItem
    var isSelected: Bool
    var isConnected: Bool
    var isCorrect: Bool?
    var hasSubmitted: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(item.text)
                .font(DesignSystem.serif(size: 14))
                .italic()
                .foregroundColor(textColor)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(backgroundColor)
                .cornerRadius(DesignSystem.radiusSm)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.radiusSm)
                        .stroke(borderColor, lineWidth: isSelected ? 2 : 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(hasSubmitted)
    }
    
    var backgroundColor: Color {
        if let correct = isCorrect {
            return correct ? DesignSystem.greenLight : DesignSystem.redLight
        }
        if isSelected { return DesignSystem.accentLight }
        if isConnected { return DesignSystem.parchment2 }
        return DesignSystem.card
    }
    
    var borderColor: Color {
        if let correct = isCorrect {
            return correct ? DesignSystem.green : DesignSystem.red
        }
        if isSelected { return DesignSystem.accent }
        return DesignSystem.parchment3
    }
    
    var textColor: Color {
        if isSelected { return DesignSystem.accent }
        return DesignSystem.ink
    }
}

// MARK: - Preview

#Preview {
    ConceptConnectExerciseView(
        exercise: ExerciseInstance(
            tidbit: Tidbit(
                concept: "Stanza 1",
                body: "Because I could not stop for Death —",
                stanzaIndex: 0,
                sourceTitle: "Because I Could Not Stop for Death"
            ),
            exerciseType: .conceptConnect
        ),
        viewModel: SessionViewModel()
    )
    .padding()
    .background(DesignSystem.parchment)
}
