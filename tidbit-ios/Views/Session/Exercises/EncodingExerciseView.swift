import SwiftUI

// MARK: - Encoding Exercise View

/// Renders any encoding-mode exercise (mode = .encoding). Encoding exercises have
/// one role: build the memory trace by exposing an artifact the user reads or
/// briefly responds to. They are never scored — a single "Got it" acknowledges
/// exposure and advances. Free-text variants (connect_to_prior, find_your_case)
/// persist the user's answer onto the tidbit's EncodingArtifacts.
struct EncodingExerciseView: View {
    let exercise: ExerciseInstance
    @Bindable var viewModel: SessionViewModel
    var showDrawer: Bool = true

    @State private var freeText: String = ""
    @State private var decodeAnswer: String = ""
    @State private var revealedDecode: Bool = false
    @State private var revealedFill: Bool = false
    @State private var lociCue: String = ""

    private var type: ExerciseType { exercise.exerciseType }
    private var artifacts: EncodingArtifacts { exercise.tidbit.encodingArtifacts }
    private var domain: KnowledgeDomain { exercise.tidbit.knowledgeDomain }

    var body: some View {
        VStack(spacing: 24) {
            // Header label — what this encoding technique is doing
            Text(headerLabel)
                .font(.custom("DM Sans", size: 13).weight(.medium))
                .foregroundColor(DesignSystem.ink3)
                .textCase(.uppercase)
                .tracking(0.5)
                .frame(maxWidth: .infinity, alignment: .leading)

            // The concept anchor (what we're encoding)
            VStack(spacing: 6) {
                Text(exercise.tidbit.concept)
                    .font(DesignSystem.serif(size: 18))
                    .italic()
                    .foregroundColor(DesignSystem.ink)
                if let simple = exercise.tidbit.simpleMeaning, type != .chunkedRead {
                    Text(simple)
                        .font(.custom("DM Sans", size: 12))
                        .foregroundColor(DesignSystem.ink3)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(DesignSystem.card)
            .cornerRadius(DesignSystem.radius)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.radius)
                    .stroke(DesignSystem.parchment3, lineWidth: 1)
            )

            // Per-type content
            contentForType

            Spacer(minLength: 8)

            // Free-text inputs (connect_to_prior / find_your_case / story_gap / loci_recall)
            if type == .connectToPrior || type == .findYourCase || type == .storyGap || type == .lociRecall {
                freeTextEditor
            }

            // Mnemonic decode: small answer field
            if type == .mnemonicDecode {
                decodeField
            }
            
            // Reveal for fill-and-reveal encoding types
            if revealedFill, type == .storyGap || type == .lociRecall {
                revealCard
            }

            // Acknowledge / advance button (never scored)
            Button {
                acknowledge()
            } label: {
                Text(acknowledgeLabel)
                    .font(.custom("DM Sans", size: 16).weight(.medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(DesignSystem.accent)
                    .cornerRadius(DesignSystem.radius)
            }
        }
        .onAppear { prepareForType() }
        .onChange(of: exercise.id) { _, _ in
            freeText = ""
            decodeAnswer = ""
            revealedDecode = false
            revealedFill = false
            lociCue = ""
            prepareForType()
        }
    }

    // MARK: - Per-type content

    @ViewBuilder
    private var contentForType: some View {
        switch type {
        case .mnemonicLearn:
            artifactCard(title: "Mnemonic", body: artifacts.mnemonic ?? placeholder("Mnemonic"), symbol: "textformat.abc")
        case .mnemonicDecode:
            decodeContent
        case .imageAnchorRead:
            artifactCard(title: "Image anchor", body: artifacts.imageDescription ?? placeholder("Image anchor"), symbol: "photo.on.rectangle.angled")
        case .imageToConcept:
            imageToConceptContent
        case .analogyRead:
            artifactCard(title: "Analogy", body: artifacts.analogy ?? placeholder("Analogy"), symbol: "arrow.triangle.2.circlepath")
        case .chunkedRead:
            chunkedContent
        case .connectToPrior:
            promptCard(prompt: "What does this remind you of? Connect it to something you already know.")
        case .findYourCase:
            promptCard(prompt: "Think of a real example from your own life where this applies.")
        case .storyRead:
            artifactCard(title: "Story", body: artifacts.story ?? placeholder("Story"), symbol: "book")
        case .storyGap:
            storyGapContent
        case .lociRead:
            artifactCard(title: "Memory palace", body: artifacts.palace ?? placeholder("Memory palace"), symbol: "mappin.and.ellipse")
        case .lociRecall:
            lociRecallContent
        default:
            EmptyView()
        }
    }
    
    /// Story with the final action blanked; user fills, then reveals the full story.
    private var storyGapContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Story (one action missing):")
                .font(.custom("DM Sans", size: 11))
                .foregroundColor(DesignSystem.ink3)
                .textCase(.uppercase)
            Text(gappedStory.display)
                .font(DesignSystem.serif(size: 17))
                .foregroundColor(DesignSystem.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(DesignSystem.parchment2)
                .cornerRadius(DesignSystem.radius)
            Text("What\u{2019}s the missing action?")
                .font(.custom("DM Sans", size: 13))
                .foregroundColor(DesignSystem.ink3)
        }
    }
    
    /// Memory-palace recall: name the concept that sits at a given spatial cue.
    private var lociRecallContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Palace journey:")
                .font(.custom("DM Sans", size: 11))
                .foregroundColor(DesignSystem.ink3)
                .textCase(.uppercase)
            Text(artifacts.palace ?? placeholder("Memory palace"))
                .font(DesignSystem.serif(size: 16))
                .foregroundColor(DesignSystem.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(DesignSystem.parchment2)
                .cornerRadius(DesignSystem.radius)
            Text("What concept sits at \u{201C}\(lociCue)\u{201D}?")
                .font(.custom("DM Sans", size: 13))
                .foregroundColor(DesignSystem.ink3)
        }
    }
    
    /// Revealed answer for story_gap / loci_recall.
    private var revealCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Revealed:")
                .font(.custom("DM Sans", size: 11))
                .foregroundColor(DesignSystem.ink3)
                .textCase(.uppercase)
            Text(revealText)
                .font(DesignSystem.serif(size: 15))
                .italic()
                .foregroundColor(DesignSystem.ink2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(DesignSystem.card)
                .cornerRadius(DesignSystem.radiusSm)
        }
    }
    
    /// Split the story into sentences and blank the last one for story_gap.
    private var gappedStory: (display: String, answer: String) {
        let story = artifacts.story ?? placeholder("Story")
        let sentences = story.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        guard let last = sentences.last, sentences.count > 1 else {
            return (story, story)
        }
        let prefix = sentences.dropLast().joined(separator: ". ")
        return ("\(prefix)…  _____", last)
    }
    
    /// Text shown in the reveal card after a fill-and-reveal encoding exercise.
    private var revealText: String {
        switch type {
        case .storyGap: return gappedStory.answer
        case .lociRecall: return "\(exercise.tidbit.concept) — \(exercise.tidbit.body)"
        default: return ""
        }
    }

    private var decodeContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mnemonic:")
                .font(.custom("DM Sans", size: 11))
                .foregroundColor(DesignSystem.ink3)
                .textCase(.uppercase)
            Text(artifacts.mnemonic ?? placeholder("Mnemonic"))
                .font(DesignSystem.serif(size: 18))
                .foregroundColor(DesignSystem.ink)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DesignSystem.parchment2)
                .cornerRadius(DesignSystem.radius)

            Text("Pick any letter — what does it stand for?")
                .font(.custom("DM Sans", size: 13))
                .foregroundColor(DesignSystem.ink3)

            if revealedDecode {
                Text("Concept: \(exercise.tidbit.concept) — \(exercise.tidbit.body)")
                    .font(DesignSystem.serif(size: 14))
                    .italic()
                    .foregroundColor(DesignSystem.ink2)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(DesignSystem.card)
                    .cornerRadius(DesignSystem.radiusSm)
            }
        }
    }

    private var imageToConceptContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Image:")
                .font(.custom("DM Sans", size: 11))
                .foregroundColor(DesignSystem.ink3)
                .textCase(.uppercase)
            Text(artifacts.imageDescription ?? placeholder("Image anchor"))
                .font(DesignSystem.serif(size: 17))
                .italic()
                .foregroundColor(DesignSystem.ink)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DesignSystem.parchment2)
                .cornerRadius(DesignSystem.radius)
            Text("Name the concept this image encodes.")
                .font(.custom("DM Sans", size: 13))
                .foregroundColor(DesignSystem.ink3)
        }
    }

    private var chunkedContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            if artifacts.chunks.isEmpty {
                Text("Chunk labels will appear here once generated.")
                    .font(.custom("DM Sans", size: 13))
                    .foregroundColor(DesignSystem.ink3)
            } else {
                ForEach(artifacts.chunks) { chunk in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(chunk.label)
                            .font(DesignSystem.serif(size: 16))
                            .foregroundColor(DesignSystem.ink)
                        Text(chunk.memberConcepts.joined(separator: ", "))
                            .font(.custom("DM Sans", size: 12))
                            .foregroundColor(DesignSystem.ink3)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(DesignSystem.card)
                    .cornerRadius(DesignSystem.radiusSm)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.radiusSm)
                            .stroke(DesignSystem.parchment3, lineWidth: 1)
                    )
                }
            }
        }
    }

    private func artifactCard(title: String, body: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 14))
                    .foregroundColor(DesignSystem.accent)
                Text(title)
                    .font(.custom("DM Sans", size: 12).weight(.medium))
                    .foregroundColor(DesignSystem.ink3)
                    .textCase(.uppercase)
            }
            Text(body)
                .font(DesignSystem.serif(size: 17))
                .foregroundColor(DesignSystem.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(DesignSystem.parchment2)
                .cornerRadius(DesignSystem.radius)
        }
    }

    private func promptCard(prompt: String) -> some View {
        Text(prompt)
            .font(DesignSystem.serif(size: 17))
            .italic()
            .foregroundColor(DesignSystem.ink)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DesignSystem.parchment2)
            .cornerRadius(DesignSystem.radius)
    }

    private var freeTextEditor: some View {
        TextEditor(text: $freeText)
            .font(DesignSystem.serif(size: 16))
            .foregroundColor(DesignSystem.ink)
            .frame(height: 88)
            .padding(12)
            .background(DesignSystem.card)
            .cornerRadius(DesignSystem.radius)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.radius)
                    .stroke(DesignSystem.parchment3, lineWidth: 1)
            )
            .overlay(alignment: .topLeading) {
                if freeText.isEmpty {
                    Text("Type your answer…")
                        .font(DesignSystem.serif(size: 16))
                        .italic()
                        .foregroundColor(DesignSystem.ink4)
                        .padding(12)
                }
            }
    }

    private var decodeField: some View {
        TextField("Type a letter…", text: $decodeAnswer)
            .font(DesignSystem.serif(size: 17))
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .padding(14)
            .background(DesignSystem.card)
            .cornerRadius(DesignSystem.radiusSm)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.radiusSm)
                    .stroke(DesignSystem.parchment3, lineWidth: 1)
            )
    }

    // MARK: - Actions

    /// Acknowledge exposure: emit encoding telemetry (no score) and advance.
    /// For free-text variants, persist the user's answer onto the tidbit.
    private func acknowledge() {
        let tidbit = exercise.tidbit
        // Persist free-text answers onto the encoding artifacts (creates a personal anchor)
        if type == .connectToPrior && !freeText.isEmpty {
            var updated = tidbit.encodingArtifacts
            updated.priorLink = freeText
            tidbit.encodingArtifacts = updated
        } else if type == .findYourCase && !freeText.isEmpty {
            var updated = tidbit.encodingArtifacts
            updated.personalCase = freeText
            tidbit.encodingArtifacts = updated
        }

        // For fill-and-reveal types, first tap reveals; second tap (when revealed) advances.
        if (type == .storyGap || type == .lociRecall) && !revealedFill {
            revealedFill = true
            return
        }

        // Record encoding exposure (does not touch successRate/nextDue/phase)
        viewModel.recordEncodingExposure(for: exercise)

        viewModel.nextExercise()
    }

    private func prepareForType() {
        // Pick a spatial cue for loci_recall from the tidbit's example/simple-meaning,
        // or fall back to a generic room name.
        if type == .lociRecall {
            lociCue = exercise.tidbit.examples.first
                ?? exercise.tidbit.simpleMeaning
                ?? "the kitchen"
        }
    }

    private var headerLabel: String {
        switch type {
        case .mnemonicLearn: "Learn the mnemonic"
        case .mnemonicDecode: "Decode the mnemonic"
        case .imageAnchorRead: "Read the image anchor"
        case .imageToConcept: "Image → concept"
        case .analogyRead: "Read the analogy"
        case .chunkedRead: "Learn the chunks"
        case .connectToPrior: "Connect to prior knowledge"
        case .findYourCase: "Find your own case"
        case .storyRead: "Read the story"
        case .storyGap: "Fill the story gap"
        case .lociRead: "Read the memory palace"
        case .lociRecall: "Recall from the palace"
        default: type.displayName
        }
    }

    private var acknowledgeLabel: String {
        switch type {
        case .connectToPrior, .findYourCase: "Save & continue"
        case .mnemonicDecode, .imageToConcept: "Reveal & continue"
        case .storyGap, .lociRecall: revealedFill ? "Continue" : "Reveal & continue"
        default: "Got it"
        }
    }

    private func placeholder(_ technique: String) -> String {
        "No \(technique.lowercased()) generated yet. Use “Encode this” on the tidbit to add one."
    }
}

// MARK: - Preview

#Preview {
    EncodingExerciseView(
        exercise: ExerciseInstance(
            tidbit: Tidbit(
                concept: "Goodhart's Law",
                body: "When a measure becomes a target, it ceases to be a good measure.",
                sourceTitle: "Notes"
            ),
            exerciseType: .imageAnchorRead
        ),
        viewModel: SessionViewModel()
    )
    .padding()
    .background(DesignSystem.parchment)
}
