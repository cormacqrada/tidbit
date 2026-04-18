import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Lesson.createdAt, order: .reverse) private var lessons: [Lesson]
    
    @State private var searchText = ""
    @State private var selectedContentType: ContentType?
    @State private var selectedLesson: Lesson?
    
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
                    
                    // Filter chips
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
                    
                    // Statistics summary
                    if !lessons.isEmpty {
                        LibraryStatsCard(lessons: lessons)
                            .padding(.horizontal, 20)
                    }
                    
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
        }
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
    @State private var selectedTidbit: Tidbit?
    
    var body: some View {
        NavigationStack {
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
            .navigationTitle(lesson.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedTidbit) { tidbit in
                TidbitDetailView(tidbit: tidbit)
            }
        }
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
    let tidbit: Tidbit
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Concept
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Concept")
                            .font(.custom("DM Sans", size: 11).weight(.medium))
                            .foregroundColor(DesignSystem.ink3)
                            .textCase(.uppercase)
                        
                        Text(tidbit.concept)
                            .font(.custom("DM Sans", size: 16).weight(.medium))
                            .foregroundColor(DesignSystem.ink)
                    }
                    
                    // Body
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Content")
                            .font(.custom("DM Sans", size: 11).weight(.medium))
                            .foregroundColor(DesignSystem.ink3)
                            .textCase(.uppercase)
                        
                        Text(tidbit.body)
                            .font(DesignSystem.serif(size: 18))
                            .foregroundColor(DesignSystem.ink)
                    }
                    
                    // Metadata
                    if let meaning = tidbit.meaningNotes {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Meaning Notes")
                                .font(.custom("DM Sans", size: 11).weight(.medium))
                                .foregroundColor(DesignSystem.ink3)
                                .textCase(.uppercase)
                            
                            Text(meaning)
                                .font(.custom("DM Sans", size: 14))
                                .foregroundColor(DesignSystem.ink2)
                        }
                    }
                    
                    // Difficulty
                    HStack {
                        Text("Difficulty")
                            .font(.custom("DM Sans", size: 11).weight(.medium))
                            .foregroundColor(DesignSystem.ink3)
                            .textCase(.uppercase)
                        
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
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Source")
                            .font(.custom("DM Sans", size: 11).weight(.medium))
                            .foregroundColor(DesignSystem.ink3)
                            .textCase(.uppercase)
                        
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
                .padding(20)
            }
            .background(DesignSystem.parchment)
            .navigationTitle("Tidbit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    LibraryView()
        .modelContainer(for: [Lesson.self, Tidbit.self], inMemory: true)
}
