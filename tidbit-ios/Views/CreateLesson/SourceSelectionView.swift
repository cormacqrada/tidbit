import SwiftUI

struct SourceSelectionView: View {
    @Bindable var viewModel: CreateLessonViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Step indicator
                StepIndicator(currentStep: .source, label: "Source")
                
                // Title
                Text("What do you want to learn?")
                    .font(DesignSystem.serif(size: 22))
                    .foregroundColor(DesignSystem.ink)
                    .lineSpacing(1.3)
                
                // Subtitle
                Text("Paste a poem, article, or paste a URL and we'll build your lesson.")
                    .font(.custom("DM Sans", size: 13))
                    .foregroundColor(DesignSystem.ink3)
                    .lineSpacing(1.5)
                    .padding(.top, 6)
                    .padding(.bottom, 24)
                
                // Source tabs
                HStack(spacing: 2) {
                    ForEach(SourceTab.allCases, id: \.self) { tab in
                        SourceTabButton(
                            tab: tab,
                            isSelected: viewModel.sourceTab == tab
                        ) {
                            viewModel.sourceTab = tab
                        }
                    }
                }
                .padding(3)
                .background(DesignSystem.parchment2)
                .cornerRadius(8)
                .padding(.bottom, 16)
                
                // Content based on selected tab
                switch viewModel.sourceTab {
                case .text:
                    TextTabContent(viewModel: viewModel)
                case .url:
                    URLTabContent(viewModel: viewModel)
                case .file:
                    FileTabPlaceholder()
                case .voice:
                    VoiceTabPlaceholder()
                }
            }
            .padding(.horizontal, 20)
        }
        .onChange(of: viewModel.pastedText) { _, newValue in
            viewModel.ingestText()
        }
    }
}

// MARK: - Source Tab Button

struct SourceTabButton: View {
    let tab: SourceTab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            Text(tab.displayName)
                .font(.custom("DM Sans", size: 12).weight(.medium))
                .foregroundColor(isSelected ? DesignSystem.violet : DesignSystem.ink3)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(isSelected ? Color.white : Color.clear)
                .cornerRadius(6)
                .shadow(color: isSelected ? Color.black.opacity(0.1) : .clear, radius: 1, y: 1)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Text Tab Content

struct TextTabContent: View {
    @Bindable var viewModel: CreateLessonViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Paste area
            TextEditor(text: $viewModel.pastedText)
                .font(DesignSystem.serif(size: 14))
                .italic()
                .foregroundColor(viewModel.pastedText.isEmpty ? DesignSystem.ink4 : DesignSystem.ink2)
                .frame(minHeight: 130)
                .padding(14)
                .background(DesignSystem.card)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(DesignSystem.parchment3, lineWidth: 1)
                )
                .overlay(alignment: .topLeading) {
                    if viewModel.pastedText.isEmpty {
                        Text("Paste your content here...")
                            .font(DesignSystem.serif(size: 14))
                            .italic()
                            .foregroundColor(DesignSystem.ink4)
                            .padding(14)
                    }
                }
            
            // Detected pill
            if viewModel.ingestionResult != nil {
                DetectedPill(text: viewModel.detectedContentTypeLabel)
                    .padding(.bottom, 16)
            }
            
            // Collection name field
            FieldLabel(text: "Collection name")
            TextField("Enter a name", text: $viewModel.collectionName)
                .font(.custom("DM Sans", size: 14))
                .padding(10)
                .background(DesignSystem.card)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(DesignSystem.parchment3, lineWidth: 1)
                )
            
            // Continue button
            Button("Continue →") {
                viewModel.currentStep = .configure
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!viewModel.canProceedFromSource)
            .padding(.top, 4)
        }
    }
}

// MARK: - URL Tab Content

struct URLTabContent: View {
    @Bindable var viewModel: CreateLessonViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // URL input
            HStack(spacing: 8) {
                TextField("Enter URL", text: $viewModel.urlInput)
                    .font(.custom("DM Sans", size: 13))
                    .foregroundColor(DesignSystem.ink3)
                    .padding(10)
                    .background(DesignSystem.card)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(DesignSystem.parchment3, lineWidth: 1)
                    )
                
                Button("Fetch") {
                    Task {
                        await viewModel.fetchUrl()
                    }
                }
                .font(.custom("DM Sans", size: 13).weight(.medium))
                .foregroundColor(DesignSystem.parchment)
                .padding(10)
                .background(DesignSystem.ink)
                .cornerRadius(8)
            }
            
            // URL preview (if fetched)
            if let result = viewModel.ingestionResult, viewModel.sourceTab == .url {
                URLPreviewCard(title: result.suggestedTitle ?? "Fetched Content", 
                               url: viewModel.urlInput,
                               wordCount: result.estimatedLineCount * 10)
                    .padding(.bottom, 12)
                
                DetectedPill(text: viewModel.detectedContentTypeLabel)
                    .padding(.bottom, 16)
                
                FieldLabel(text: "Collection name")
                TextField("Enter a name", text: $viewModel.collectionName)
                    .font(.custom("DM Sans", size: 14))
                    .padding(10)
                    .background(DesignSystem.card)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(DesignSystem.parchment3, lineWidth: 1)
                    )
                
                Button("Continue →") {
                    viewModel.currentStep = .configure
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!viewModel.canProceedFromSource)
            }
        }
    }
}

// MARK: - Placeholder Tabs

struct FileTabPlaceholder: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("File upload coming soon")
                .font(.custom("DM Sans", size: 14))
                .foregroundColor(DesignSystem.ink3)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }
}

struct VoiceTabPlaceholder: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Voice memo coming soon")
                .font(.custom("DM Sans", size: 14))
                .foregroundColor(DesignSystem.ink3)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }
}

// MARK: - Supporting Views

struct DetectedPill: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .frame(width: 6, height: 6)
                .foregroundColor(DesignSystem.violet)
            
            Text(text)
                .font(.custom("DM Sans", size: 11).weight(.medium))
                .foregroundColor(DesignSystem.violet)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(DesignSystem.violetLight)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(DesignSystem.violetMid, lineWidth: 1)
        )
    }
}

struct FieldLabel: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.custom("DM Sans", size: 11).weight(.medium))
            .foregroundColor(DesignSystem.ink3)
            .tracking(0.5)
            .textCase(.uppercase)
    }
}

struct URLPreviewCard: View {
    let title: String
    let url: String
    let wordCount: Int
    
    var body: some View {
        HStack(spacing: 10) {
            // Thumbnail
            Text("📜")
                .font(.system(size: 18))
                .frame(width: 44, height: 44)
                .background(DesignSystem.violetLight)
                .cornerRadius(6)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.custom("DM Sans", size: 13).weight(.medium))
                    .foregroundColor(DesignSystem.ink)
                    .lineLimit(1)
                
                Text(url)
                    .font(.custom("DM Sans", size: 11))
                    .foregroundColor(DesignSystem.ink3)
                    .lineLimit(1)
                
                Text("✓ \(wordCount) words extracted")
                    .font(.custom("DM Sans", size: 11).weight(.medium))
                    .foregroundColor(DesignSystem.green)
            }
            
            Spacer()
        }
        .padding(12)
        .background(DesignSystem.card)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(DesignSystem.parchment3, lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    SourceSelectionView(viewModel: CreateLessonViewModel())
}
