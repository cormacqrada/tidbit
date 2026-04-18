import Foundation
import SwiftUI
import SwiftData

// MARK: - Telemetry Service

enum TelemetryService {
    
    // MARK: - Storage
    
    private static let telemetryKey = "telemetry_events"
    private static let maxStoredEvents = 1000
    
    // MARK: - Logging
    
    /// Log an exercise event
    static func log(event: TelemetryEvent) {
        var events = loadEvents()
        events.append(event)
        
        // Keep only the last N events
        if events.count > maxStoredEvents {
            events = Array(events.suffix(maxStoredEvents))
        }
        
        saveEvents(events)
    }
    
    /// Log from a completed exercise
    static func log(
        session: SessionState,
        exercise: ExerciseInstance,
        completed: CompletedExercise
    ) {
        let event = TelemetryEvent(
            sessionId: session.id,
            tidbitId: completed.tidbitId,
            templateId: completed.exerciseType.rawValue,
            learnerId: UUID(), // Would use actual learner ID
            responseRaw: completed.userResponse,
            score: completed.score,
            responseTimeMs: completed.responseTimeMs,
            hintUsed: completed.hintUsed,
            adaptiveSignal: completed.adaptiveSignal
        )
        
        log(event: event)
    }
    
    // MARK: - Loading & Saving
    
    private static func loadEvents() -> [TelemetryEvent] {
        guard let data = UserDefaults.standard.data(forKey: telemetryKey) else {
            return []
        }
        
        return (try? JSONDecoder().decode([TelemetryEvent].self, from: data)) ?? []
    }
    
    private static func saveEvents(_ events: [TelemetryEvent]) {
        guard let data = try? JSONEncoder().encode(events) else { return }
        UserDefaults.standard.set(data, forKey: telemetryKey)
    }
    
    // MARK: - Export
    
    /// Export all telemetry events as JSON
    static func exportJSON() -> String? {
        let events = loadEvents()
        guard let data = try? JSONEncoder().encode(events) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    /// Export telemetry events as CSV
    static func exportCSV() -> String {
        let events = loadEvents()
        
        var csv = "timestamp,session_id,tidbit_id,exercise_type,score,response_time_ms,hint_used,adaptive_signal\n"
        
        for event in events {
            csv += "\(event.timestamp.ISO8601Format()),"
            csv += "\(event.sessionId),"
            csv += "\(event.tidbitId),"
            csv += "\(event.templateId),"
            csv += "\(event.score),"
            csv += "\(event.responseTimeMs),"
            csv += "\(event.hintUsed),"
            csv += "\(event.adaptiveSignal.rawValue)\n"
        }
        
        return csv
    }
    
    // MARK: - Analytics
    
    /// Get session statistics for a time range
    static func getSessionStats(from startDate: Date, to endDate: Date = Date()) -> SessionStats {
        let events = loadEvents().filter { event in
            event.timestamp >= startDate && event.timestamp <= endDate
        }
        
        return SessionStats(events: events)
    }
    
    /// Get exercise type distribution
    static func getExerciseDistribution() -> [ExerciseType: Int] {
        let events = loadEvents()
        var distribution: [ExerciseType: Int] = [:]
        
        for event in events {
            guard let type = ExerciseType(rawValue: event.templateId) else { continue }
            distribution[type, default: 0] += 1
        }
        
        return distribution
    }
    
    /// Get average scores per exercise type
    static func getAverageScores() -> [ExerciseType: Double] {
        let events = loadEvents()
        var totals: [ExerciseType: (sum: Double, count: Int)] = [:]
        
        for event in events {
            guard let type = ExerciseType(rawValue: event.templateId) else { continue }
            let current = totals[type] ?? (0, 0)
            totals[type] = (current.sum + event.score, current.count + 1)
        }
        
        return totals.mapValues { $0.sum / Double($0.count) }
    }
    
    /// Get learning curve data (average score over time)
    static func getLearningCurve(days: Int = 30) -> [(Date, Double)] {
        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: now) ?? now
        
        let events = loadEvents().filter { $0.timestamp >= startDate }
        
        // Group by day
        var dailyScores: [Date: [Double]] = [:]
        
        for event in events {
            let day = calendar.startOfDay(for: event.timestamp)
            dailyScores[day, default: []].append(event.score)
        }
        
        // Calculate averages
        return dailyScores.map { ($0.key, $0.value.reduce(0, +) / Double($0.value.count)) }
            .sorted { $0.0 < $1.0 }
    }
    
    // MARK: - Cleanup
    
    /// Clear all stored telemetry
    static func clearAll() {
        UserDefaults.standard.removeObject(forKey: telemetryKey)
    }
}

// MARK: - Session Stats

struct SessionStats {
    let totalSessions: Int
    let totalExercises: Int
    let averageScore: Double
    let averageResponseTimeMs: Double
    let hintsUsedCount: Int
    let signalDistribution: [AdaptiveSignal: Int]
    
    init(events: [TelemetryEvent]) {
        // Group by session
        let sessionIds = Set(events.map(\.sessionId))
        self.totalSessions = sessionIds.count
        self.totalExercises = events.count
        
        // Average score
        self.averageScore = events.isEmpty ? 0 : events.map(\.score).reduce(0, +) / Double(events.count)
        
        // Average response time
        self.averageResponseTimeMs = events.isEmpty ? 0 : Double(events.map(\.responseTimeMs).reduce(0, +)) / Double(events.count)
        
        // Hints used
        self.hintsUsedCount = events.filter(\.hintUsed).count
        
        // Signal distribution
        var signals: [AdaptiveSignal: Int] = [:]
        for event in events {
            signals[event.adaptiveSignal, default: 0] += 1
        }
        self.signalDistribution = signals
    }
}

// MARK: - Phase Extension for Display

extension Phase {
    var displayName: String {
        switch self {
        case .learning: return "Learning"
        case .review: return "Review"
        case .maintenance: return "Mastered"
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        Text("Telemetry Service")
            .font(.headline)
        
        Text("CSV Export available")
            .foregroundColor(.green)
        
        Text("Sessions: \(TelemetryService.getSessionStats(from: Date.distantPast).totalSessions)")
    }
    .padding()
}
