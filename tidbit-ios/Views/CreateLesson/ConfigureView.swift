import SwiftUI

struct ConfigureView: View {
    @Bindable var viewModel: CreateLessonViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Step indicator
                StepIndicator(currentStep: .configure, label: "Configure")
                
                // Title
                Text("Shape your lesson")
                    .font(DesignSystem.serif(size: 22))
                    .foregroundColor(DesignSystem.ink)
                
                // Subtitle
                Text("Tell us how you want to learn this.")
                    .font(.custom("DM Sans", size: 13))
                    .foregroundColor(DesignSystem.ink3)
                    .padding(.top, 6)
                    .padding(.bottom, 18)
                
                // Learning goal
                ConfigRow(label: "Learning goal") {
                    ChipSelector(
                        items: LearningGoal.allCases,
                        selected: viewModel.learningGoal,
                        getLabel: { $0.displayName }
                    ) { viewModel.learningGoal = $0 }
                }
                
                Divider()
                    .background(DesignSystem.parchment3)
                    .padding(.vertical, 18)
                
                // Session length
                ConfigRow(label: "Session length", trailing: Text("\(viewModel.sessionLength) min").foregroundColor(DesignSystem.violet)) {
                    ChipSelector(
                        items: [3, 5, 10, 15],
                        selected: viewModel.sessionLength,
                        getLabel: { "\($0) min" }
                    ) { viewModel.sessionLength = $0 }
                }
                
                Divider()
                    .background(DesignSystem.parchment3)
                    .padding(.vertical, 18)
                
                // Difficulty ramp
                ConfigRow(label: "Difficulty ramp", trailing: Text(viewModel.difficultyRamp <= 0.33 ? "Gradual" : viewModel.difficultyRamp <= 0.66 ? "Moderate" : "Steep").foregroundColor(DesignSystem.violet)) {
                    DifficultySlider(value: $viewModel.difficultyRamp)
                }
                
                Divider()
                    .background(DesignSystem.parchment3)
                    .padding(.vertical, 18)
                
                // Hint policy
                ConfigRow(label: "Hint policy") {
                    ChipSelector(
                        items: HintPolicy.allCases,
                        selected: viewModel.hintPolicy,
                        getLabel: { $0.displayName }
                    ) { viewModel.hintPolicy = $0 }
                }
                
                Divider()
                    .background(DesignSystem.parchment3)
                    .padding(.vertical, 18)
                
                // Modality
                ConfigRow(label: "Modality") {
                    ChipSelector(
                        items: Modality.allCases,
                        selected: viewModel.modality,
                        getLabel: { $0.displayName }
                    ) { viewModel.modality = $0 }
                }
                
                // Continue button
                Button("Continue →") {
                    viewModel.generateExerciseMix()
                    viewModel.currentStep = .exerciseMix
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 18)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Config Row

struct ConfigRow<Content: View, Trailing: View>: View {
    let label: String
    var trailing: Trailing
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.custom("DM Sans", size: 11).weight(.medium))
                    .foregroundColor(DesignSystem.ink3)
                    .tracking(0.06)
                    .textCase(.uppercase)
                
                Spacer()
                
                trailing
                    .font(.custom("DM Sans", size: 12))
            }
            
            content()
        }
    }
}

extension ConfigRow where Trailing == EmptyView {
    init(label: String, @ViewBuilder content: @escaping () -> Content) {
        self.label = label
        self.trailing = EmptyView()
        self.content = content
    }
}

// MARK: - Chip Selector

struct ChipSelector<T: Hashable>: View where T: Equatable {
    let items: [T]
    let selected: T
    let getLabel: (T) -> String
    let onSelect: (T) -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(items, id: \.self) { item in
                Button {
                    onSelect(item)
                } label: {
                    Text(getLabel(item))
                        .chip(selected: item == selected)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Difficulty Slider

struct DifficultySlider: View {
    @Binding var value: Double
    @State private var trackWidth: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 6) {
            // Track
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 2)
                    .fill(DesignSystem.parchment3)
                    .frame(height: 4)
                    .background(
                        GeometryReader { geometry in
                            Color.clear.onAppear { trackWidth = geometry.size.width }
                        }
                    )
                
                // Fill
                RoundedRectangle(cornerRadius: 2)
                    .fill(DesignSystem.violet)
                    .frame(width: trackWidth * value, height: 4)
                
                // Thumb
                Circle()
                    .fill(DesignSystem.violet)
                    .frame(width: 18, height: 18)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                    )
                    .offset(x: trackWidth * value - 9)
                    .shadow(color: DesignSystem.violet.opacity(0.4), radius: 2, y: 1)
            }
            .frame(height: 18)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let newValue = max(0, min(1, gesture.location.x / max(trackWidth, 1)))
                        value = newValue
                    }
            )
            
            // Labels
            HStack {
                Text("Gradual")
                Spacer()
                Text("Steep")
            }
            .font(.custom("DM Sans", size: 10))
            .foregroundColor(DesignSystem.ink4)
        }
    }
}

// MARK: - Preview

#Preview {
    ConfigureView(viewModel: {
        let vm = CreateLessonViewModel()
        vm.ingestionResult = IngestionResult(
            text: "Test",
            contentType: .poem,
            detectedLanguage: "English",
            estimatedLineCount: 4,
            suggestedTitle: "Test Poem",
            detectedAuthor: nil
        )
        return vm
    }())
}
