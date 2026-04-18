import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query private var lessons: [Lesson]
    @Query private var learnerStates: [LearnerState]
    
    @AppStorage("dailyStreak") private var dailyStreak: Int = 0
    @AppStorage("lastSessionDate") private var lastSessionDate: Double = 0
    @AppStorage("defaultHintPolicy") private var defaultHintPolicy: String = "always"
    @AppStorage("defaultSessionLength") private var defaultSessionLength: Int = 5
    @AppStorage("appearanceMode") private var appearanceMode: String = "system"
    @AppStorage("showTimer") private var showTimer: Bool = true
    
    @State private var showingSettings = false
    
    var totalTidbits: Int {
        lessons.reduce(0) { $0 + $1.tidbits.count }
    }
    
    var masteredTidbits: Int {
        learnerStates.filter { $0.phase == .maintenance }.count
    }
    
    var learningTidbits: Int {
        learnerStates.filter { $0.phase == .learning }.count
    }
    
    var averageSuccessRate: Double {
        guard !learnerStates.isEmpty else { return 0 }
        return learnerStates.map(\.successRate).reduce(0, +) / Double(learnerStates.count)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Streak card
                    StreakCard(streak: dailyStreak)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    
                    // Stats grid
                    StatsGrid(
                        totalTidbits: totalTidbits,
                        masteredTidbits: masteredTidbits,
                        learningTidbits: learningTidbits,
                        averageSuccessRate: averageSuccessRate
                    )
                    .padding(.horizontal, 20)
                    
                    // Progress section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Learning Progress")
                            .font(.custom("DM Sans", size: 14).weight(.medium))
                            .foregroundColor(DesignSystem.ink3)
                            .textCase(.uppercase)
                            .tracking(0.5)
                        
                        ProgressChart(learnerStates: learnerStates)
                            .frame(height: 200)
                            .background(DesignSystem.card)
                            .cornerRadius(DesignSystem.radius)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.radius)
                                    .stroke(DesignSystem.parchment3, lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 20)
                    
                    // Settings section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Preferences")
                            .font(.custom("DM Sans", size: 14).weight(.medium))
                            .foregroundColor(DesignSystem.ink3)
                            .textCase(.uppercase)
                            .tracking(0.5)
                        
                        VStack(spacing: 0) {
                            SettingsRow(
                                icon: "moon.circle",
                                label: "Appearance",
                                value: appearanceModeDisplayName
                            ) {
                                showingSettings = true
                            }
                            
                            Divider()
                                .background(DesignSystem.parchment3)
                            
                            SettingsRow(
                                icon: "lightbulb",
                                label: "Default Hint Policy",
                                value: defaultHintPolicy.capitalized
                            ) {
                                showingSettings = true
                            }
                            
                            Divider()
                                .background(DesignSystem.parchment3)
                            
                            SettingsRow(
                                icon: "clock",
                                label: "Default Session Length",
                                value: "\(defaultSessionLength) min"
                            ) {
                                showingSettings = true
                            }
                        }
                        .background(DesignSystem.card)
                        .cornerRadius(DesignSystem.radiusSm)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.radiusSm)
                                .stroke(DesignSystem.parchment3, lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // About section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About")
                            .font(.custom("DM Sans", size: 14).weight(.medium))
                            .foregroundColor(DesignSystem.ink3)
                            .textCase(.uppercase)
                            .tracking(0.5)
                        
                        VStack(spacing: 0) {
                            AboutRow(label: "Version", value: "1.0.0")
                            
                            Divider()
                                .background(DesignSystem.parchment3)
                            
                            AboutRow(label: "Feedback", value: "tidbit@app.com")
                            
                            Divider()
                                .background(DesignSystem.parchment3)
                            
                            AboutRow(label: "Privacy Policy", value: nil)
                        }
                        .background(DesignSystem.card)
                        .cornerRadius(DesignSystem.radiusSm)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.radiusSm)
                                .stroke(DesignSystem.parchment3, lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 32)
            }
            .background(DesignSystem.parchment)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Profile")
                        .font(DesignSystem.serif(size: 22))
                        .foregroundColor(DesignSystem.ink)
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(
                    defaultHintPolicy: $defaultHintPolicy,
                    defaultSessionLength: $defaultSessionLength,
                    appearanceMode: $appearanceMode
                )
            }
        }
        .onAppear {
            updateStreak()
        }
    }
    
    var appearanceModeDisplayName: String {
        switch appearanceMode {
        case "light": return "Light"
        case "dark": return "Dark"
        default: return "System"
        }
    }
    
    private func updateStreak() {
        let now = Date()
        let lastDate = Date(timeIntervalSince1970: lastSessionDate)
        
        let calendar = Calendar.current
        let daysSinceLastSession = calendar.dateComponents([.day], from: calendar.startOfDay(for: lastDate), to: calendar.startOfDay(for: now)).day ?? 0
        
        if daysSinceLastSession > 1 {
            // Streak broken
            dailyStreak = 0
        }
    }
}

// MARK: - Streak Card

struct StreakCard: View {
    let streak: Int
    
    var body: some View {
        HStack(spacing: 16) {
            // Flame icon
            ZStack {
                Circle()
                    .fill(streak > 0 ? DesignSystem.amberLight : DesignSystem.parchment2)
                    .frame(width: 56, height: 56)
                
                Text("🔥")
                    .font(.system(size: 28))
            }
            
            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text("\(streak) day streak")
                    .font(DesignSystem.serif(size: 22))
                    .foregroundColor(DesignSystem.ink)
                
                Text(streak > 0 ? "Keep it going!" : "Start your streak today")
                    .font(.custom("DM Sans", size: 13))
                    .foregroundColor(DesignSystem.ink3)
            }
            
            Spacer()
            
            // Streak badge
            if streak >= 7 {
                Text("🏆")
                    .font(.system(size: 32))
            } else if streak >= 3 {
                Text("⭐")
                    .font(.system(size: 28))
            }
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
}

// MARK: - Stats Grid

struct StatsGrid: View {
    let totalTidbits: Int
    let masteredTidbits: Int
    let learningTidbits: Int
    let averageSuccessRate: Double
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            StatBox(value: totalTidbits, label: "Total Tidbits", color: DesignSystem.violet)
            StatBox(value: masteredTidbits, label: "Mastered", color: DesignSystem.green)
            StatBox(value: learningTidbits, label: "Learning", color: DesignSystem.amber)
            StatBox(value: Int(averageSuccessRate * 100), label: "Success %", color: DesignSystem.ink2, suffix: "%")
        }
    }
}

struct StatBox: View {
    let value: Int
    let label: String
    let color: Color
    var suffix: String = ""
    
    var body: some View {
        VStack(spacing: 8) {
            Text("\(value)\(suffix)")
                .font(DesignSystem.serif(size: 32))
                .foregroundColor(color)
            
            Text(label)
                .font(.custom("DM Sans", size: 11))
                .foregroundColor(DesignSystem.ink3)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(DesignSystem.card)
        .cornerRadius(DesignSystem.radiusSm)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.radiusSm)
                .stroke(DesignSystem.parchment3, lineWidth: 1)
        )
    }
}

// MARK: - Progress Chart

struct ProgressChart: View {
    let learnerStates: [LearnerState]
    
    var phaseDistribution: [(Phase, Int)] {
        let learning = learnerStates.filter { $0.phase == .learning }.count
        let review = learnerStates.filter { $0.phase == .review }.count
        let maintenance = learnerStates.filter { $0.phase == .maintenance }.count
        return [(.learning, learning), (.review, review), (.maintenance, maintenance)]
    }
    
    var body: some View {
        VStack {
            if learnerStates.isEmpty {
                VStack(spacing: 12) {
                    Text("No learning data yet")
                        .font(.custom("DM Sans", size: 14))
                        .foregroundColor(DesignSystem.ink3)
                    
                    Text("Complete a session to see your progress")
                        .font(.custom("DM Sans", size: 12))
                        .foregroundColor(DesignSystem.ink4)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HStack(spacing: 20) {
                    // Pie chart visualization
                    ZStack {
                        ForEach(Array(phaseDistribution.enumerated()), id: \.offset) { index, item in
                            Circle()
                                .trim(from: 0, to: CGFloat(item.1) / CGFloat(learnerStates.count))
                                .stroke(phaseColor(item.0), lineWidth: 20)
                                .rotationEffect(.degrees(-90 + Double(index) * 120))
                        }
                    }
                    .frame(width: 100, height: 100)
                    
                    // Legend
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(phaseDistribution, id: \.0) { item in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(phaseColor(item.0))
                                    .frame(width: 10, height: 10)
                                
                                Text("\(item.0.displayName)")
                                    .font(.custom("DM Sans", size: 12))
                                    .foregroundColor(DesignSystem.ink)
                                
                                Spacer()
                                
                                Text("\(item.1)")
                                    .font(.custom("DM Sans", size: 12).weight(.medium))
                                    .foregroundColor(DesignSystem.ink)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(20)
            }
        }
    }
    
    func phaseColor(_ phase: Phase) -> Color {
        switch phase {
        case .learning: return DesignSystem.amber
        case .review: return DesignSystem.violet
        case .maintenance: return DesignSystem.green
        }
    }
}

// MARK: - Settings Row

struct SettingsRow: View {
    let icon: String
    let label: String
    let value: String
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(DesignSystem.violet)
                    .frame(width: 24)
                
                Text(label)
                    .font(.custom("DM Sans", size: 14))
                    .foregroundColor(DesignSystem.ink)
                
                Spacer()
                
                Text(value)
                    .font(.custom("DM Sans", size: 13))
                    .foregroundColor(DesignSystem.ink3)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(DesignSystem.ink4)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - About Row

struct AboutRow: View {
    let label: String
    var value: String?
    
    var body: some View {
        HStack {
            Text(label)
                .font(.custom("DM Sans", size: 14))
                .foregroundColor(DesignSystem.ink)
            
            Spacer()
            
            if let value = value {
                Text(value)
                    .font(.custom("DM Sans", size: 13))
                    .foregroundColor(DesignSystem.ink3)
            }
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(DesignSystem.ink4)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var defaultHintPolicy: String
    @Binding var defaultSessionLength: Int
    @Binding var appearanceMode: String
    
    var body: some View {
        NavigationStack {
            List {
                Section("Appearance") {
                    ForEach(["system", "light", "dark"], id: \.self) { mode in
                        Button {
                            appearanceMode = mode
                        } label: {
                            HStack {
                                Image(systemName: mode == "light" ? "sun.max" : mode == "dark" ? "moon" : "circle.lefthalf.filled")
                                    .foregroundColor(DesignSystem.accent)
                                    .frame(width: 24)
                                
                                Text(mode == "system" ? "System" : mode == "light" ? "Light" : "Dark")
                                    .foregroundColor(DesignSystem.ink)
                                
                                Spacer()
                                
                                if appearanceMode == mode {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(DesignSystem.accent)
                                }
                            }
                        }
                    }
                }
                
                Section("Default Hint Policy") {
                    ForEach(["Always", "Once", "Never"], id: \.self) { policy in
                        Button {
                            defaultHintPolicy = policy.lowercased()
                        } label: {
                            HStack {
                                Text(policy)
                                    .foregroundColor(DesignSystem.ink)
                                
                                Spacer()
                                
                                if defaultHintPolicy.capitalized == policy {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(DesignSystem.accent)
                                }
                            }
                        }
                    }
                }
                
                Section("Default Session Length") {
                    ForEach([3, 5, 10, 15], id: \.self) { length in
                        Button {
                            defaultSessionLength = length
                        } label: {
                            HStack {
                                Text("\(length) minutes")
                                    .foregroundColor(DesignSystem.ink)
                                
                                Spacer()
                                
                                if defaultSessionLength == length {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(DesignSystem.accent)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Settings")
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
    ProfileView()
        .modelContainer(for: [Lesson.self, Tidbit.self, LearnerState.self], inMemory: true)
}
