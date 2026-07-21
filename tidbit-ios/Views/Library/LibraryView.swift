import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Lesson.createdAt, order: .reverse) private var lessons: [Lesson]
    
    @State private var searchText = ""
    @State private var selectedContentType: ContentType?
    @State private var selectedLesson: Lesson?
    @State private var searchScope: SearchScope = .lessons
    @State private var tidbitResults: [TidbitSearchService.Result] = []
    @State private var selectedTidbitFromSearch: Tidbit?
    
    enum SearchScope: String, CaseIterable {
        case lessons
        case tidbits
        
        var label: String {
            switch self {
            case .lessons: "Lessons"
            case .tidbits: "Tidbits"
            }
        }
    }
    
    var filteredLessons: [Lesson] {
        var result = lessons
        
        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter { lesson in
                lesson.name.localizedCaseInsensitiveContains(searchText) ||
                lesson.sourceText?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        // Filter by content type
        if let contentType = selectedContentType {
            result = result.filter { $0.contentType == contentType }
        }
        
        return result
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Search bar
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(DesignSystem.ink2)
                        
                        TextField("Search lessons...", text: $searchText)
                            .font(.custom("DM Sans", size: 14))
                        
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(DesignSystem.ink3)
                            }
                        }
                    }
                    .padding(12)
                    .background(DesignSystem.card)
                    .cornerRadius(DesignSystem.radiusSm)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.radiusSm)
                            .stroke(DesignSystem.parchment3, lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    
                    // Search scope toggle (Lessons | Tidbits)
                    if !searchText.isEmpty {
                        HStack(spacing: 0) {
                            ForEach(SearchScope.allCases, id: \.self) { scope in
                                Button {
                                    withAnimation(DesignSystem.springSnappy) {
                                        searchScope = scope
                                    }
                                    if scope == .tidbits {
                                        tidbitResults = TidbitSearchService.search(query: searchText, modelContext: modelContext)
                                    }
                                } label: {
                                    Text(scope.label)
                                        .font(.custom("DM Sans", size: 13).weight(.medium))
                                        .foregroundColor(searchScope == scope ? .white : DesignSystem.ink2)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(searchScope == scope ? DesignSystem.accent : DesignSystem.card)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .cornerRadius(DesignSystem.radiusSm)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.radiusSm)
                                .stroke(DesignSystem.parchment3, lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                    }
                    
                    // Content type filter chips (lessons scope only)
                    if searchScope == .lessons {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                FilterChip(
                                    label: "All",
                                    isSelected: selectedContentType == nil
                                ) {
                                    selectedContentType = nil
                                }
                                
                                ForEach(ContentType.allCases, id: \.self) { type in
                                    FilterChip(
                                        label: type.displayName,
                                        isSelected: selectedContentType == type
                                    ) {
                                        selectedContentType = type
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    // Statistics summary (lessons scope, no search)
                    if searchScope == .lessons && searchText.isEmpty && !lessons.isEmpty {
                        LibraryStatsCard(lessons: lessons)
                            .padding(.horizontal, 20)
                    }
                    
                    // Results: tidbits or lessons
                    if searchScope == .tidbits && !searchText.isEmpty {
                        // Tidbit search results
                        if tidbitResults.isEmpty {
                            EmptyLibraryView(hasFilters: true)
                                .padding(.top, 40)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(tidbitResults) { result in
                                    TidbitSearchResultRow(result: result)
                                        .onTapGesture {
                                            selectedTidbitFromSearch = result.tidbit
                                        }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    } else {
                        // Lessons list
                        if filteredLessons.isEmpty {
                            EmptyLibraryView(hasFilters: !searchText.isEmpty || selectedContentType != nil)
                                .padding(.top, 40)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredLessons) { lesson in
                                    LibraryLessonCard(lesson: lesson)
                                        .onTapGesture {
                                            selectedLesson = lesson
                                        }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
                .padding(.top, 16)
            }
            .background(DesignSystem.parchment)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Library")
                        .font(DesignSystem.serif(size: 22))
                        .foregroundColor(DesignSystem.ink)
                }
            }
            .sheet(item: $selectedLesson) { lesson in
                LessonDetailView(lesson: lesson)
            }
            .sheet(item: $selectedTidbitFromSearch) { tidbit in
                TidbitDetailView(tidbit: tidbit)
            }
            .onChange(of: searchText) { _, newValue in
                if searchScope == .tidbits && !newValue.isEmpty {
                    tidbitResults = TidbitSearchService.search(query: newValue, modelContext: modelContext)
                }
            }
            .onChange(of: searchScope) { _, newScope in
                if newScope == .tidbits && !searchText.isEmpty {
                    tidbitResults = TidbitSearchService.search(query: searchText, modelContext: modelContext)
                }
            }
        }
    }
}

// MARK: - Tidbit Search Result Row

struct TidbitSearchResultRow: View {
    let result: TidbitSearchService.Result
    
    var body: some View {
        HStack(spacing: 12) {
            // Domain icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(DesignSystem.accentLight)
                    .frame(width: 40, height: 40)
                Image(systemName: result.tidbit.knowledgeDomain.iconName)
                    .font(.system(size: 15))
                    .foregroundColor(DesignSystem.accent)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(result.tidbit.concept)
                    .font(DesignSystem.serif(size: 15))
                    .foregroundColor(DesignSystem.ink)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    if let lesson = result.lesson {
                        Text(lesson.name)
                            .font(.custom("DM Sans", size: 11))
                            .foregroundColor(DesignSystem.ink3)
                        Text("·")
                            .foregroundColor(DesignSystem.ink4)
                    }
                    Text(result.matchedField)
                        .font(.custom("DM Sans", size: 11))
                        .foregroundColor(DesignSystem.accent)
                }
                
                Text(result.tidbit.body.prefix(60) + (result.tidbit.body.count > 60 ? "…" : ""))
                    .font(.custom("DM Sans", size: 12))
                    .foregroundColor(DesignSystem.ink2)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(DesignSystem.ink4)
        }
        .padding(12)
        .background(DesignSystem.card)
        .cornerRadius(DesignSystem.radiusSm)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.radiusSm)
                .stroke(DesignSystem.parchment3, lineWidth: 1)
        )
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            Text(label)
                .font(.custom("DM Sans", size: 12).weight(.medium))
                .foregroundColor(isSelected ? .white : DesignSystem.ink2)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? DesignSystem.accent : DesignSystem.parchment2)
                .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Library Stats Card

struct LibraryStatsCard: View {
    let lessons: [Lesson]
    
    var totalTidbits: Int {
        lessons.reduce(0) { $0 + $1.tidbits.count }
    }
    
    var totalSessions: Int {
        // Would track from telemetry in real implementation
        lessons.count
    }
    
    var body: some View {
        HStack(spacing: 0) {
            StatItem(value: lessons.count, label: "Lessons")
                .frame(maxWidth: .infinity)
            
            Divider()
                .frame(height: 40)
                .background(DesignSystem.parchment3)
            
            StatItem(value: totalTidbits, label: "Tidbits")
                .frame(maxWidth: .infinity)
            
            Divider()
                .frame(height: 40)
                .background(DesignSystem.parchment3)
            
            StatItem(value: totalSessions, label: "Sessions")
                .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 16)
        .background(DesignSystem.card)
        .cornerRadius(DesignSystem.radiusSm)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.radiusSm)
                .stroke(DesignSystem.parchment3, lineWidth: 1)
        )
    }
}

struct StatItem: View {
    let value: Int
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(DesignSystem.serif(size: 24))
                .foregroundColor(DesignSystem.ink)
            
            Text(label)
                .font(.custom("DM Sans", size: 11))
                .foregroundColor(DesignSystem.ink2)
        }
    }
}

// MARK: - Library Lesson Card

struct LibraryLessonCard: View {
    let lesson: Lesson
    
    var body: some View {
        HStack(spacing: 12) {
            // Content type icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(contentTypeColor.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: contentTypeIcon)
                    .font(.system(size: 18))
                    .foregroundColor(contentTypeColor)
            }
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(lesson.name)
                    .font(DesignSystem.serif(size: 16))
                    .foregroundColor(DesignSystem.ink)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text("\(lesson.tidbits.count) tidbits")
                    
                    Text("•")
                        .foregroundColor(DesignSystem.ink3)
                    
                    Text("\(lesson.sessionLength) min")
                    
                    Text("•")
                        .foregroundColor(DesignSystem.ink3)
                    
                    Text(lesson.learningGoal.displayName)
                }
                .font(.custom("DM Sans", size: 11))
                .foregroundColor(DesignSystem.ink2)
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(DesignSystem.ink3)
        }
        .padding(12)
        .background(DesignSystem.card)
        .cornerRadius(DesignSystem.radiusSm)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.radiusSm)
                .stroke(DesignSystem.parchment3, lineWidth: 1)
        )
    }
    
    var contentTypeColor: Color {
        switch lesson.contentType {
        case .poem: return DesignSystem.violet
        case .prose: return DesignSystem.amber
        case .factual, .technical: return DesignSystem.green
        default: return DesignSystem.ink2
        }
    }
    
    var contentTypeIcon: String {
        switch lesson.contentType {
        case .poem: return "text.quote"
        case .prose: return "doc.text"
        case .factual: return "brain"
        case .technical: return "gearshape"
        case .list: return "list.bullet"
        case .dialogue: return "bubble.left.and.bubble.right"
        }
    }
}

// MARK: - Empty Library View

struct EmptyLibraryView: View {
    let hasFilters: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            if hasFilters {
                Text("No lessons match your filters")
                    .font(.custom("DM Sans", size: 16))
                    .foregroundColor(DesignSystem.ink2)
                
                Text("Try a different search or filter")
                    .font(.custom("DM Sans", size: 14))
                    .foregroundColor(DesignSystem.ink3)
            } else {
                Text("Your library is empty")
                    .font(.custom("DM Sans", size: 16))
                    .foregroundColor(DesignSystem.ink2)
                
                Text("Create your first lesson to get started")
                    .font(.custom("DM Sans", size: 14))
                    .foregroundColor(DesignSystem.ink3)
            }
        }
    }
}

// MARK: - Lesson Detail View

struct LessonDetailView: View {
    let lesson: Lesson
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTidbit: Tidbit?
    @State private var showingQuickAdd = false
    @State private var mode: DetailMode = .review
    @State private var encodeTarget: Tidbit?
    
    enum DetailMode: String, CaseIterable {
        case encode
        case review
        case source
        var label: String {
            switch self {
            case .encode: "Encode"
            case .review: "Review"
            case .source: "Source"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Mode switcher: Encode | Review | Source
                Picker("View", selection: $mode) {
                    ForEach(DetailMode.allCases, id: \.self) { m in
                        Text(m.label).tag(m)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                
                switch mode {
                case .encode:
                    encodeView
                case .review:
                    tidbitsList
                case .source:
                    sourceView
                }
            }
            .navigationTitle(lesson.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingQuickAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .opacity(mode == .review ? 1 : 0)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedTidbit) { tidbit in
                TidbitDetailView(tidbit: tidbit)
            }
            .sheet(isPresented: $showingQuickAdd) {
                QuickAddTidbitSheet(lesson: lesson)
            }
            .sheet(item: $encodeTarget) { tidbit in
                EncodeThisSheet(tidbit: tidbit)
                    .presentationDetents([.medium])
            }
        }
    }
    
    private var tidbitsList: some View {
        List {
            // Lesson info section
            Section {
                HStack {
                    Text("Content Type")
                    Spacer()
                    Text(lesson.contentType.displayName)
                        .foregroundColor(DesignSystem.ink3)
                }
                
                HStack {
                    Text("Knowledge Domain")
                    Spacer()
                    Text(lesson.primaryKnowledgeDomain.displayName)
                        .foregroundColor(DesignSystem.ink3)
                }
                
                HStack {
                    Text("Learning Goal")
                    Spacer()
                    Text(lesson.learningGoal.displayName)
                        .foregroundColor(DesignSystem.ink3)
                }
                
                HStack {
                    Text("Session Length")
                    Spacer()
                    Text("\(lesson.sessionLength) min")
                        .foregroundColor(DesignSystem.ink3)
                }
                
                HStack {
                    Text("Created")
                    Spacer()
                    Text(lesson.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .foregroundColor(DesignSystem.ink3)
                }
            } header: {
                Text("Configuration")
            }
            
            // Tidbits section
            Section {
                ForEach(lesson.tidbits.sorted(by: { $0.sequenceIndex < $1.sequenceIndex })) { tidbit in
                    TidbitRow(tidbit: tidbit)
                        .onTapGesture {
                            selectedTidbit = tidbit
                        }
                }
            } header: {
                Text("Tidbits (\(lesson.tidbits.count))")
            }
        }
        .listStyle(.insetGrouped)
    }
    
    /// Source mode: read the whole original text the lesson was built from.
    private var sourceView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if let sourceText = lesson.sourceText, !sourceText.isEmpty {
                    Text(sourceText)
                        .font(DesignSystem.serif(size: 16))
                        .foregroundColor(DesignSystem.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                } else if let url = lesson.sourceUrl {
                    Link(url, destination: URL(string: url) ?? URL(string: "https://example.com")!)
                        .font(.custom("DM Sans", size: 14))
                        .foregroundColor(DesignSystem.accent)
                } else {
                    Text("No source text saved with this lesson.")
                        .font(.custom("DM Sans", size: 14))
                        .foregroundColor(DesignSystem.ink3)
                }
            }
            .padding(20)
        }
        .background(DesignSystem.parchment)
    }
    
    /// Encode mode: walk the lesson's tidbits and build memory aids (mnemonic,
    /// image, analogy, story, palace) outside of a scored session. Each row shows
    /// which aids already exist and offers an Encode button.
    private var encodeView: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Build a memory aid for each tidbit. These feed the encoding exercises in your sessions.")
                    .font(.custom("DM Sans", size: 13))
                    .foregroundColor(DesignSystem.ink3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                
                ForEach(lesson.tidbits.sorted(by: { $0.sequenceIndex < $1.sequenceIndex })) { tidbit in
                    EncodeRow(tidbit: tidbit) {
                        encodeTarget = tidbit
                    }
                    .onTapGesture {
                        selectedTidbit = tidbit
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.bottom, 24)
        }
        .background(DesignSystem.parchment)
    }
}

// MARK: - Encode Row

struct EncodeRow: View {
    let tidbit: Tidbit
    let onEncode: () -> Void
    
    private var artifacts: EncodingArtifacts { tidbit.encodingArtifacts }
    
    private var aidTags: [String] {
        var tags: [String] = []
        if artifacts.mnemonic != nil { tags.append("Mnemonic") }
        if artifacts.imageDescription != nil { tags.append("Image") }
        if artifacts.analogy != nil { tags.append("Analogy") }
        if artifacts.story != nil { tags.append("Story") }
        if artifacts.palace != nil { tags.append("Palace") }
        if !artifacts.chunks.isEmpty { tags.append("Chunks") }
        return tags
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(tidbit.concept)
                    .font(DesignSystem.serif(size: 16))
                    .foregroundColor(DesignSystem.ink)
                    .lineLimit(1)
                Spacer()
                Button {
                    onEncode()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "brain.head.profile")
                        Text("Encode")
                    }
                    .font(.custom("DM Sans", size: 12).weight(.medium))
                    .foregroundColor(DesignSystem.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(DesignSystem.accentLight)
                    .cornerRadius(DesignSystem.radiusSm)
                }
                .buttonStyle(.plain)
            }
            
            Text(tidbit.body)
                .font(.custom("DM Sans", size: 12))
                .foregroundColor(DesignSystem.ink2)
                .lineLimit(2)
            
            if aidTags.isEmpty {
                Text("No aids yet")
                    .font(.custom("DM Sans", size: 11))
                    .foregroundColor(DesignSystem.ink4)
            } else {
                HStack(spacing: 6) {
                    ForEach(aidTags, id: \.self) { tag in
                        Text(tag)
                            .font(.custom("DM Sans", size: 10).weight(.medium))
                            .foregroundColor(DesignSystem.accent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(DesignSystem.accentLight)
                            .cornerRadius(10)
                    }
                }
            }
        }
        .padding(14)
        .background(DesignSystem.card)
        .cornerRadius(DesignSystem.radius)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.radius)
                .stroke(DesignSystem.parchment3, lineWidth: 1)
        )
    }
}

// MARK: - Quick Add Tidbit Sheet

struct QuickAddTidbitSheet: View {
    let lesson: Lesson
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var concept = ""
    @State private var bodyText = ""
    @State private var simpleMeaning = ""
    @State private var examples = ""
    @State private var domain: KnowledgeDomain = .concept
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Tidbit") {
                    TextField("Concept name", text: $concept)
                    TextField("Definition / content", text: $bodyText, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Optional") {
                    Picker("Domain", selection: $domain) {
                        ForEach(KnowledgeDomain.allCases, id: \.self) { d in
                            Text(d.displayName).tag(d)
                        }
                    }
                    
                    TextField("Simple meaning", text: $simpleMeaning)
                    TextField("Examples (one per line)", text: $examples, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Add Tidbit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addTidbit()
                    }
                    .disabled(concept.isEmpty || bodyText.isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                domain = lesson.primaryKnowledgeDomain
            }
        }
    }
    
    private func addTidbit() {
        let exampleList = examples.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        let nextIndex = (lesson.tidbits.map { $0.sequenceIndex }.max() ?? -1) + 1
        
        let tidbit = Tidbit(
            concept: concept,
            body: bodyText,
            sequenceIndex: nextIndex,
            sourceTitle: lesson.name,
            difficulty: 2,
            knowledgeDomain: domain,
            simpleMeaning: simpleMeaning.isEmpty ? nil : simpleMeaning,
            examples: exampleList,
            createdBy: .manual,
            lesson: lesson
        )
        modelContext.insert(tidbit)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Tidbit Row

struct TidbitRow: View {
    let tidbit: Tidbit
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(tidbit.concept)
                .font(.custom("DM Sans", size: 13).weight(.medium))
                .foregroundColor(DesignSystem.ink)
            
            Text(tidbit.body)
                .font(DesignSystem.serif(size: 14))
                .foregroundColor(DesignSystem.ink2)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Tidbit Detail View

struct TidbitDetailView: View {
    @Bindable var tidbit: Tidbit
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var isEditing = false
    @State private var editConcept = ""
    @State private var editBody = ""
    @State private var editSimpleMeaning = ""
    @State private var editMeaningNotes = ""
    @State private var editUserNotes = ""
    @State private var editExamples = ""
    @State private var editDifficulty = 2
    
    // On-demand actions
    @State private var showingEncodingSheet = false
    var onPracticeNow: ((Tidbit) -> Void)? = nil
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Knowledge domain badge
                    HStack(spacing: 8) {
                        Image(systemName: tidbit.knowledgeDomain.iconName)
                            .font(.system(size: 12))
                            .foregroundColor(DesignSystem.accent)
                        Text(tidbit.knowledgeDomain.displayName)
                            .font(.custom("DM Sans", size: 12).weight(.medium))
                            .foregroundColor(DesignSystem.accent)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(DesignSystem.accentLight)
                    .cornerRadius(16)
                    
                    if isEditing {
                        editableContent
                    } else {
                        readOnlyContent
                    }
                    
                    // Encoding artifacts (if any)
                    if !tidbit.encodingArtifacts.isEmpty {
                        EncodingArtifactsSection(tidbit: tidbit)
                    }
                }
                .padding(20)
            }
            .background(DesignSystem.parchment)
            .navigationTitle("Tidbit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(isEditing ? "Cancel" : "Done") {
                        if isEditing {
                            // Discard edits
                            loadEditState()
                            isEditing = false
                        } else {
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Save" : "Edit") {
                        if isEditing {
                            saveEdits()
                            isEditing = false
                        } else {
                            loadEditState()
                            isEditing = true
                        }
                    }
                    .fontWeight(.semibold)
                }
            }
            .safeAreaInset(edge: .bottom) {
                // On-demand action bar
                HStack(spacing: 12) {
                    Button {
                        showingEncodingSheet = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "brain.head.profile")
                            Text("Encode")
                        }
                        .font(.custom("DM Sans", size: 14).weight(.medium))
                        .foregroundColor(DesignSystem.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(DesignSystem.accentLight)
                        .cornerRadius(DesignSystem.radius)
                    }
                    
                    Button {
                        onPracticeNow?(tidbit)
                        dismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "play.fill")
                            Text("Practice now")
                        }
                        .font(.custom("DM Sans", size: 14).weight(.medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(DesignSystem.accent)
                        .cornerRadius(DesignSystem.radius)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(DesignSystem.parchment)
            }
            .sheet(isPresented: $showingEncodingSheet) {
                EncodeThisSheet(tidbit: tidbit)
                    .presentationDetents([.medium])
            }
            .onAppear { loadEditState() }
        }
    }
    
    // MARK: - Read-only content
    
    private var readOnlyContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Concept
            fieldLabel("Concept")
            Text(tidbit.concept)
                .font(.custom("DM Sans", size: 16).weight(.medium))
                .foregroundColor(DesignSystem.ink)
            
            // Body / Definition
            fieldLabel(tidbit.knowledgeDomain == .concept ? "Definition" : "Content")
            Text(tidbit.body)
                .font(DesignSystem.serif(size: 18))
                .foregroundColor(DesignSystem.ink)
            
            // Simple meaning
            if let simple = tidbit.simpleMeaning, !simple.isEmpty {
                fieldLabel("Simple meaning")
                Text(simple)
                    .font(.custom("DM Sans", size: 14))
                    .foregroundColor(DesignSystem.ink2)
            }
            
            // Meaning notes
            if let meaning = tidbit.meaningNotes, !meaning.isEmpty {
                fieldLabel("Explanation")
                Text(meaning)
                    .font(.custom("DM Sans", size: 14))
                    .foregroundColor(DesignSystem.ink2)
            }
            
            // Examples
            if !tidbit.examples.isEmpty {
                fieldLabel("Examples")
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(tidbit.examples, id: \.self) { example in
                        Text("• \(example)")
                            .font(.custom("DM Sans", size: 14))
                            .foregroundColor(DesignSystem.ink2)
                    }
                }
            }
            
            // User notes
            if let notes = tidbit.userNotes, !notes.isEmpty {
                fieldLabel("Your notes")
                Text(notes)
                    .font(.custom("DM Sans", size: 14))
                    .foregroundColor(DesignSystem.ink)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(DesignSystem.parchment2)
                    .cornerRadius(DesignSystem.radiusSm)
            }
            
            // Difficulty
            HStack {
                fieldLabel("Difficulty")
                Spacer()
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { level in
                        Circle()
                            .fill(level <= tidbit.difficulty ? DesignSystem.amber : DesignSystem.parchment3)
                            .frame(width: 8, height: 8)
                    }
                }
            }
            
            // Source
            fieldLabel("Source")
            Text(tidbit.sourceTitle)
                .font(DesignSystem.serif(size: 16))
                .foregroundColor(DesignSystem.ink)
            if let author = tidbit.sourceAuthor {
                Text("by \(author)")
                    .font(.custom("DM Sans", size: 12))
                    .foregroundColor(DesignSystem.ink3)
            }
        }
    }
    
    // MARK: - Editable content
    
    private var editableContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            editField(label: "Concept", text: $editConcept)
            editField(label: "Definition", text: $editBody, axis: .vertical)
            editField(label: "Simple meaning", text: $editSimpleMeaning, axis: .vertical)
            editField(label: "Explanation", text: $editMeaningNotes, axis: .vertical)
            editField(label: "Your notes", text: $editUserNotes, axis: .vertical)
            
            // Examples (one per line)
            VStack(alignment: .leading, spacing: 4) {
                Text("Examples (one per line)")
                    .font(.custom("DM Sans", size: 11).weight(.medium))
                    .foregroundColor(DesignSystem.ink3)
                    .textCase(.uppercase)
                TextEditor(text: $editExamples)
                    .font(.custom("DM Sans", size: 14))
                    .foregroundColor(DesignSystem.ink)
                    .frame(height: 80)
                    .padding(8)
                    .background(DesignSystem.card)
                    .cornerRadius(DesignSystem.radiusSm)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.radiusSm)
                            .stroke(DesignSystem.parchment3, lineWidth: 1)
                    )
            }
            
            // Difficulty stepper
            HStack {
                Text("Difficulty")
                    .font(.custom("DM Sans", size: 13))
                    .foregroundColor(DesignSystem.ink2)
                Spacer()
                Stepper("\(editDifficulty)", value: $editDifficulty, in: 1...5)
                    .labelsHidden()
                Text("\(editDifficulty)")
                    .font(.custom("DM Sans", size: 14).weight(.medium))
                    .foregroundColor(DesignSystem.ink)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.custom("DM Sans", size: 11).weight(.medium))
            .foregroundColor(DesignSystem.ink3)
            .textCase(.uppercase)
    }
    
    private func editField(label: String, text: Binding<String>, axis: Axis = .horizontal) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.custom("DM Sans", size: 11).weight(.medium))
                .foregroundColor(DesignSystem.ink3)
                .textCase(.uppercase)
            TextField("", text: text, axis: axis)
                .font(.custom("DM Sans", size: 14))
                .foregroundColor(DesignSystem.ink)
                .padding(10)
                .background(DesignSystem.card)
                .cornerRadius(DesignSystem.radiusSm)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.radiusSm)
                        .stroke(DesignSystem.parchment3, lineWidth: 1)
                )
        }
    }
    
    private func loadEditState() {
        editConcept = tidbit.concept
        editBody = tidbit.body
        editSimpleMeaning = tidbit.simpleMeaning ?? ""
        editMeaningNotes = tidbit.meaningNotes ?? ""
        editUserNotes = tidbit.userNotes ?? ""
        editExamples = tidbit.examples.joined(separator: "\n")
        editDifficulty = tidbit.difficulty
    }
    
    private func saveEdits() {
        tidbit.concept = editConcept
        tidbit.body = editBody
        tidbit.simpleMeaning = editSimpleMeaning.isEmpty ? nil : editSimpleMeaning
        tidbit.meaningNotes = editMeaningNotes.isEmpty ? nil : editMeaningNotes
        tidbit.userNotes = editUserNotes.isEmpty ? nil : editUserNotes
        tidbit.examples = editExamples.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        tidbit.difficulty = editDifficulty
        try? modelContext.save()
    }
}

// MARK: - Encoding Artifacts Section

struct EncodingArtifactsSection: View {
    let tidbit: Tidbit
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Memory aids")
                .font(.custom("DM Sans", size: 11).weight(.medium))
                .foregroundColor(DesignSystem.ink3)
                .textCase(.uppercase)
            
            let artifacts = tidbit.encodingArtifacts
            if let mnemonic = artifacts.mnemonic {
                aidRow(symbol: "textformat.abc", title: "Mnemonic", bodyText: mnemonic)
            }
            if let image = artifacts.imageDescription {
                aidRow(symbol: "photo", title: "Image anchor", bodyText: image)
            }
            if let analogy = artifacts.analogy {
                aidRow(symbol: "arrow.triangle.2.circlepath", title: "Analogy", bodyText: analogy)
            }
            if let story = artifacts.story {
                aidRow(symbol: "book", title: "Story", bodyText: story)
            }
            if let prior = artifacts.priorLink {
                aidRow(symbol: "link", title: "Connect to prior", bodyText: prior)
            }
            if let personalCase = artifacts.personalCase {
                aidRow(symbol: "mappin.and.ellipse", title: "Your case", bodyText: personalCase)
            }
        }
    }
    
    private func aidRow(symbol: String, title: String, bodyText: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 13))
                .foregroundColor(DesignSystem.accent)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.custom("DM Sans", size: 12).weight(.medium))
                    .foregroundColor(DesignSystem.ink3)
                Text(bodyText)
                    .font(DesignSystem.serif(size: 14))
                    .foregroundColor(DesignSystem.ink2)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.card)
        .cornerRadius(DesignSystem.radiusSm)
    }
}

// MARK: - Encode This Sheet (on-demand encoding)

struct EncodeThisSheet: View {
    let tidbit: Tidbit
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Generate a memory aid for \"\(tidbit.concept)\"")
                    .font(DesignSystem.serif(size: 16))
                    .foregroundColor(DesignSystem.ink)
                    .multilineTextAlignment(.center)
                    .padding(.top, 20)
                
                // Technique picker — each generates a placeholder artifact locally.
                // (AI generation is a follow-on; for now we create scaffold artifacts.)
                VStack(spacing: 12) {
                    techniqueButton("Mnemonic", symbol: "textformat.abc") {
                        generateMnemonic()
                    }
                    techniqueButton("Image anchor", symbol: "photo") {
                        generateImage()
                    }
                    techniqueButton("Analogy", symbol: "arrow.triangle.2.circlepath") {
                        generateAnalogy()
                    }
                    techniqueButton("Chunked overview", symbol: "square.grid.2x2") {
                        generateChunks()
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .navigationTitle("Encode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func techniqueButton(_ label: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(.system(size: 16))
                    .foregroundColor(DesignSystem.accent)
                    .frame(width: 32, height: 32)
                    .background(DesignSystem.accentLight)
                    .cornerRadius(8)
                Text(label)
                    .font(.custom("DM Sans", size: 15).weight(.medium))
                    .foregroundColor(DesignSystem.ink)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(DesignSystem.ink4)
            }
            .padding(14)
            .background(DesignSystem.card)
            .cornerRadius(DesignSystem.radius)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.radius)
                    .stroke(DesignSystem.parchment3, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Local scaffold generators (placeholder until AI integration)
    
    private func generateMnemonic() {
        var artifacts = tidbit.encodingArtifacts
        // Scaffold: first letters of each word in the concept
        let letters = tidbit.concept.components(separatedBy: .whitespaces)
            .compactMap { $0.first.map(String.init) }
            .joined()
        artifacts.mnemonic = "\(letters.uppercased()) — \(tidbit.concept)"
        tidbit.encodingArtifacts = artifacts
        try? modelContext.save()
        dismiss()
    }
    
    private func generateImage() {
        var artifacts = tidbit.encodingArtifacts
        artifacts.imageDescription = "Imagine: \(tidbit.concept) as a vivid, bizarre scene you can picture clearly."
        tidbit.encodingArtifacts = artifacts
        try? modelContext.save()
        dismiss()
    }
    
    private func generateAnalogy() {
        var artifacts = tidbit.encodingArtifacts
        artifacts.analogy = "Think of \(tidbit.concept) like a familiar everyday situation you already understand well."
        tidbit.encodingArtifacts = artifacts
        try? modelContext.save()
        dismiss()
    }
    
    private func generateChunks() {
        var artifacts = tidbit.encodingArtifacts
        artifacts.chunks = [EncodingArtifacts.Chunk(label: "Core idea", memberConcepts: [tidbit.concept])]
        tidbit.encodingArtifacts = artifacts
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    LibraryView()
        .modelContainer(for: [Lesson.self, Tidbit.self], inMemory: true)
}
