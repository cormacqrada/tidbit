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

            // Free-text inputs (connect_to_prior / find_your_case)
            if type == .connectToPrior || type == .findYourCase {
                freeTextEditor
            }

            // Mnemonic decode: small answer field
            if type == .mnemonicDecode {
                decodeField
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
        default:
            EmptyView()
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

        // Record encoding exposure (does not touch successRate/nextDue/phase)
        viewModel.recordEncodingExposure(for: exercise)

        viewModel.nextExercise()
    }

    private func prepareForType() {
        if type == .mnemonicDecode || type == .imageToConcept {
            // These ask the user to retrieve; nothing to pre-fill.
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
        default: type.displayName
        }
    }

    private var acknowledgeLabel: String {
        switch type {
        case .connectToPrior, .findYourCase: "Save & continue"
        case .mnemonicDecode, .imageToConcept: "Reveal & continue"
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
