import SwiftUI

struct ProcessingView: View {
    @Bindable var viewModel: CreateLessonViewModel
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Step indicator
            StepIndicator(currentStep: .processing, label: "Building")
                .padding(.horizontal, 20)
            
            // Centered processing UI
            VStack(spacing: 20) {
                // Icon with spinning ring
                ZStack {
                    // Spinning ring
                    if viewModel.isProcessing {
                        Circle()
                            .stroke(DesignSystem.parchment3, lineWidth: 2)
                            .frame(width: 72, height: 72)
                        
                        Circle()
                            .trim(from: 0, to: 0.3)
                            .stroke(DesignSystem.violet, lineWidth: 2)
                            .frame(width: 72, height: 72)
                            .rotationEffect(.degrees(viewModel.isProcessing ? 0 : 360))
                            .animation(
                                .linear(duration: 1.2)
                                .repeatForever(autoreverses: false),
                                value: viewModel.isProcessing
                            )
                    }
                    
                    // Icon container
                    Text("📖")
                        .font(.system(size: 28))
                        .frame(width: 64, height: 64)
                        .background(DesignSystem.violetLight)
                        .cornerRadius(18)
                }
                
                // Title
                Text("Building your lesson…")
                    .font(DesignSystem.serif(size: 18).italic())
                    .foregroundColor(DesignSystem.ink)
                
                // Subtitle
                Text("Parsing the poem and generating tidbits.\nThis takes about 10 seconds.")
                    .font(.custom("DM Sans", size: 13))
                    .foregroundColor(DesignSystem.ink3)
                    .multilineTextAlignment(.center)
                    .lineSpacing(1.5)
            }
            .padding(.top, 32)
            .padding(.bottom, 28)
            
            // Progress steps
            VStack(spacing: 0) {
                ForEach(viewModel.processingSteps) { step in
                    ProgressStepRow(step: step)
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .onChange(of: viewModel.isProcessing) { _, isProcessing in
            if !isProcessing {
                // Processing complete
                onComplete()
            }
        }
    }
}

// MARK: - Progress Step Row

struct ProgressStepRow: View {
    let step: ProcessingStep
    
    var body: some View {
        HStack(spacing: 10) {
            // Status indicator
            StatusIndicator(status: step.status)
            
            // Label and detail
            VStack(alignment: .leading, spacing: 1) {
                Text(step.label)
                    .font(.custom("DM Sans", size: 13).weight(step.status == .active ? .medium : .regular))
                    .foregroundColor(step.status == .active ? DesignSystem.violet : 
                                     step.status == .done ? DesignSystem.ink3 : DesignSystem.ink4)
                
                if let detail = step.detail {
                    Text(detail)
                        .font(.custom("DM Sans", size: 11))
                        .foregroundColor(DesignSystem.ink3)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 10)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(DesignSystem.parchment2),
            alignment: .bottom
        )
    }
}

// MARK: - Status Indicator

struct StatusIndicator: View {
    let status: ProcessingStepStatus
    
    var body: some View {
        Group {
            switch status {
            case .done:
                ZStack {
                    Circle()
                        .fill(DesignSystem.green)
                        .frame(width: 20, height: 20)
                    Text("✓")
                        .font(.custom("DM Sans", size: 10).weight(.bold))
                        .foregroundColor(.white)
                }
            case .active:
                Circle()
                    .stroke(DesignSystem.violet, lineWidth: 2)
                    .frame(width: 20, height: 20)
                    .background(DesignSystem.violetLight)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.violet))
                            .scaleEffect(0.5)
                    )
            case .todo:
                Circle()
                    .fill(DesignSystem.parchment2)
                    .frame(width: 20, height: 20)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ProcessingView(viewModel: {
        let vm = CreateLessonViewModel()
        vm.ingestionResult = IngestionResult(
            text: "Test",
            contentType: .poem,
            detectedLanguage: "English",
            estimatedLineCount: 4,
            suggestedTitle: "Test Poem",
            detectedAuthor: nil
        )
        vm.processingSteps[0].status = .done
        vm.processingSteps[0].detail = "4 lines · 1 stanza detected"
        vm.processingSteps[1].status = .done
        vm.processingSteps[1].detail = "Line breaks, stanza boundaries"
        vm.processingSteps[2].status = .active
        vm.processingSteps[2].detail = "3 of 4 complete…"
        return vm
    }(), onComplete: {})
}
