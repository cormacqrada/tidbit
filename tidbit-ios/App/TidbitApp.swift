import SwiftUI
import SwiftData

@main
struct TidbitApp: App {
    @AppStorage("appearanceMode") private var appearanceMode: String = "system"
    
    let modelContainer: ModelContainer
    
    init() {
        modelContainer = Self.makeContainer()
    }
    
    /// Build the SwiftData container. If the on-disk store can't be opened
    /// (e.g. a schema change shipped without a migration plan), we never
    /// silently destroy user data: the unreadable store is moved to a
    /// timestamped backup folder and a fresh store is created so the app
    /// still launches. Recover the backup from Application Support/backups.
    private static func makeContainer() -> ModelContainer {
        do {
            return try ModelContainer(
                for: Lesson.self, Tidbit.self, LearnerState.self,
                configurations: ModelConfiguration()
            )
        } catch {
            #if DEBUG
            print("[Tidbit] ModelContainer init failed: \(error). Rebuilding store.")
            #else
            print("[Tidbit] ModelContainer init failed: \(error). Quarantining unreadable store.")
            #endif
            quarantineStore()
            // A fresh empty store should always succeed; if even this fails the
            // app genuinely cannot function, so a fatal error is appropriate.
            return try! ModelContainer(
                for: Lesson.self, Tidbit.self, LearnerState.self,
                configurations: ModelConfiguration()
            )
        }
    }
    
    /// Move the on-disk SwiftData store aside into a timestamped `backups/`
    /// folder so it can be recovered, instead of deleting it.
    private static func quarantineStore() {
        let fm = FileManager.default
        let supportDir = URL.applicationSupportDirectory
        try? fm.createDirectory(at: supportDir, withIntermediateDirectories: true)
        let storeURL = supportDir.appending(path: "default.store")
        let backupDir = supportDir.appending(path: "backups")
        try? fm.createDirectory(at: backupDir, withIntermediateDirectories: true)
        let stamp = Self.backupTimestamp()
        
        // SQLite companion files use hyphen separators: default.store-wal, default.store-shm
        let variants = [
            storeURL,
            URL(fileURLWithPath: storeURL.path() + "-wal"),
            URL(fileURLWithPath: storeURL.path() + "-shm")
        ]
        for url in variants {
            guard fm.fileExists(atPath: url.path) else { continue }
            let dest = backupDir.appending(path: url.lastPathComponent + "-" + stamp)
            try? fm.removeItem(at: dest)
            do {
                try fm.moveItem(at: url, to: dest)
            } catch {
                // Can't move (e.g. locked) — remove so the fresh store can be created.
                try? fm.removeItem(at: url)
            }
        }
    }
    
    private static func backupTimestamp() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(DesignSystem.accent)
                .preferredColorScheme(colorScheme)
                .handleFirstLaunch()
        }
        .modelContainer(modelContainer)
    }
    
    private var colorScheme: ColorScheme? {
        switch appearanceMode {
        case "light": return .light
        case "dark": return .dark
        default: return nil // System
        }
    }
}

// MARK: - Content View (Root)

struct ContentView: View {
    @State private var selectedTab: Tab = .learn
    
    enum Tab: String, CaseIterable {
        case learn
        case library
        case profile
        
        var label: String {
            switch self {
            case .learn: "Learn"
            case .library: "Library"
            case .profile: "Profile"
            }
        }
        
        var icon: String {
            switch self {
            case .learn: return "book.fill"
            case .library: return "books.vertical"
            case .profile: return "person"
            }
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content
            Group {
                switch selectedTab {
                case .learn:
                    HomeView()
                case .library:
                    LibraryView()
                case .profile:
                    ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DesignSystem.parchment)
            
            // Custom tab bar (Momentum style)
            TabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard)
    }
}

// MARK: - Tab Bar (Momentum Style)

struct TabBar: View {
    @Binding var selectedTab: ContentView.Tab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(ContentView.Tab.allCases, id: \.self) { tab in
                TabBarButton(tab: tab, isSelected: selectedTab == tab) {
                    withAnimation(DesignSystem.springSnappy) {
                        selectedTab = tab
                    }
                }
            }
        }
        .padding(.horizontal, DesignSystem.spacingXl)
        .padding(.vertical, DesignSystem.spacingMd)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

struct TabBarButton: View {
    let tab: ContentView.Tab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            VStack(spacing: DesignSystem.spacingXS) {
                Image(systemName: tab.icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(isSelected ? DesignSystem.accent : DesignSystem.ink4)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                
                Text(tab.label)
                    .font(DesignSystem.sans(size: 11, weight: isSelected ? .medium : .regular))
                    .foregroundStyle(isSelected ? DesignSystem.accent : DesignSystem.ink4)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(DesignSystem.springBouncy, value: isSelected)
    }
}

// MARK: - Placeholder Views

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Lesson.createdAt, order: .reverse) private var lessons: [Lesson]
    @State private var showingCreateLesson = false
    @State private var selectedLesson: Lesson?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Title
                    Text("Your Lessons")
                        .font(DesignSystem.serif(size: 28).bold())
                        .foregroundColor(DesignSystem.ink)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    
                    if lessons.isEmpty {
                        // Empty state
                        VStack(spacing: 16) {
                            Spacer()
                                .frame(height: 60)
                            
                            Text("No lessons yet")
                                .font(DesignSystem.sans(size: 18, weight: .medium))
                                .foregroundColor(DesignSystem.ink2)
                            
                            Text("Create your first lesson plan to start learning")
                                .font(DesignSystem.sans(size: 14))
                                .foregroundColor(DesignSystem.ink3)
                                .multilineTextAlignment(.center)
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        // Lesson cards
                        LazyVStack(spacing: 12) {
                            ForEach(lessons) { lesson in
                                LessonCardView(lesson: lesson) {
                                    selectedLesson = lesson
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .background(DesignSystem.parchment)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreateLesson = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(DesignSystem.accent)
                    }
                }
            }
            .sheet(isPresented: $showingCreateLesson) {
                CreateLessonFlow()
            }
            .fullScreenCover(item: $selectedLesson) { lesson in
                SessionView(lesson: lesson)
            }
        }
    }
}

struct LessonCardView: View {
    @Environment(\.modelContext) private var modelContext
    let lesson: Lesson
    let onStart: () -> Void
    
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        Button {
            onStart()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                // Title
                Text(lesson.name)
                    .font(DesignSystem.serif(size: 18))
                    .foregroundColor(DesignSystem.ink)
                    .lineLimit(2)
                
                // Metadata
                HStack(spacing: 12) {
                    Label(lesson.contentType.displayName, systemImage: "doc.text")
                    
                    Spacer()
                    
                    Text("\(activeExerciseCount) exercises")
                }
                .font(.custom("DM Sans", size: 12))
                .foregroundColor(DesignSystem.ink3)
                
                // Session length badge
                HStack {
                    Text("\(lesson.sessionLength) min")
                        .font(.custom("DM Sans", size: 11).weight(.medium))
                        .foregroundColor(DesignSystem.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(DesignSystem.accentLight)
                        .cornerRadius(12)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Text("Start")
                        Image(systemName: "play.fill")
                    }
                    .font(.custom("DM Sans", size: 13).weight(.medium))
                    .foregroundColor(DesignSystem.accent)
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
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Edit", systemImage: "pencil") {
                showingEditSheet = true
            }
            
            Divider()
            
            Button("Delete", systemImage: "trash", role: .destructive) {
                showingDeleteAlert = true
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditLessonSheet(lesson: lesson)
        }
        .alert("Delete Lesson?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteLesson()
            }
        } message: {
            Text("This will permanently delete \"\(lesson.name)\".")
        }
        .onTapGesture {
            DesignSystem.Haptics.light()
        }
    }
    
    /// Count of active (non-zero weight) exercises in the mix
    private var activeExerciseCount: Int {
        lesson.exerciseMix.filter { $0.weight > 0 }.count
    }
    
    private func deleteLesson() {
        modelContext.delete(lesson)
        try? modelContext.save()
        DesignSystem.Haptics.success()
    }
}

// MARK: - Edit Lesson Sheet

struct EditLessonSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var lesson: Lesson
    
    @State private var name: String = ""
    @State private var sessionLength: Int = 5
    @State private var exerciseMix: [ExerciseWeight] = []
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Lesson Details") {
                    TextField("Name", text: $name)
                }
                
                Section("Session Length") {
                    Picker("Minutes", selection: $sessionLength) {
                        Text("3 min").tag(3)
                        Text("5 min").tag(5)
                        Text("10 min").tag(10)
                        Text("15 min").tag(15)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Exercise Mix") {
                    ForEach($exerciseMix) { $weight in
                        ExerciseRow(
                            type: weight.type,
                            weight: $weight.weight,
                            isEnabled: !weight.type.requiresAI
                        )
                    }
                    
                    // Reset button
                    Button {
                        exerciseMix = ExerciseMixGenerator.generate(
                            contentType: lesson.contentType,
                            learningGoal: lesson.learningGoal
                        )
                    } label: {
                        HStack {
                            Spacer()
                            Text("Reset to recommended")
                                .font(.custom("DM Sans", size: 13))
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Edit Lesson")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        lesson.name = name
                        lesson.sessionLength = sessionLength
                        lesson.exerciseMix = exerciseMix
                        try? modelContext.save()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            name = lesson.name
            sessionLength = lesson.sessionLength
            exerciseMix = lesson.exerciseMix
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
