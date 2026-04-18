import Foundation
import SwiftUI
import SwiftData

// MARK: - Adaptive Engine Service

enum AdaptiveEngineService {
    
    // MARK: - SM-2 Parameters
    
    private static let minEaseFactor: Double = 1.3
    private static let defaultEaseFactor: Double = 2.5
    
    // MARK: - Session Composition
    
    /// Select tidbits for a learning session based on adaptive scheduling
    static func composeSession(
        lesson: Lesson,
        modelContext: ModelContext,
        maxTidbits: Int = 10
    ) -> [Tidbit] {
        let allTidbits = lesson.tidbits.sorted { $0.sequenceIndex < $1.sequenceIndex }
        
        // Get learner states for these tidbits
        let tidbitIds = allTidbits.map(\.id)
        let descriptor = FetchDescriptor<LearnerState>(
            predicate: #Predicate { state in
                tidbitIds.contains(state.tidbitId)
            }
        )
        let learnerStates = (try? modelContext.fetch(descriptor)) ?? []
        let stateMap = Dictionary(uniqueKeysWithValues: learnerStates.map { ($0.tidbitId, $0) })
        
        // Calculate priority for each tidbit
        var prioritized: [(tidbit: Tidbit, priority: Double)] = []
        
        for tidbit in allTidbits {
            let state = stateMap[tidbit.id]
            let priority = calculatePriority(tidbit: tidbit, state: state, lesson: lesson)
            prioritized.append((tidbit, priority))
        }
        
        // Sort by priority (highest first)
        prioritized.sort { $0.priority > $1.priority }
        
        // Return top N
        return prioritized.prefix(maxTidbits).map(\.tidbit)
    }
    
    // MARK: - Priority Calculation
    
    private static func calculatePriority(
        tidbit: Tidbit,
        state: LearnerState?,
        lesson: Lesson
    ) -> Double {
        var priority: Double = 0
        
        // If no state (new tidbit), high priority
        guard let state = state else {
            return 100.0
        }
        
        // Recency weight: time since last seen
        if let lastSeen = state.lastSeen {
            let hoursSinceSeen = Date().timeIntervalSince(lastSeen) / 3600
            let recencyWeight = min(hoursSinceSeen / 24.0, 10.0) // Cap at 10 days equivalent
            priority += recencyWeight * 0.4
        } else {
            // Never seen - highest priority
            priority += 10.0
        }
        
        // Difficulty weight: harder tidbits get higher priority
        let difficultyWeight = Double(tidbit.difficulty) / 5.0
        priority += difficultyWeight * 0.2
        
        // Success rate weight: lower success rate = higher priority
        let successWeight = 1.0 - state.successRate
        priority += successWeight * 0.3
        
        // Phase weight: learning phase items get higher priority
        let phaseWeight: Double
        switch state.phase {
        case .learning: phaseWeight = 1.0
        case .review: phaseWeight = 0.7
        case .maintenance: phaseWeight = 0.3
        }
        priority += phaseWeight * 0.1
        
        return priority
    }
    
    // MARK: - SM-2 Interval Scheduling
    
    /// Calculate next review interval using SM-2 algorithm
    static func calculateNextInterval(
        currentInterval: Int,
        easeFactor: Double,
        quality: Int // 0-5 scale
    ) -> (interval: Int, easeFactor: Double) {
        // Quality: 0-5 where 0 = complete failure, 5 = perfect recall
        // Map our adaptive signal to quality
        
        var newEaseFactor = easeFactor + (0.1 - Double(5 - quality) * (0.08 + Double(5 - quality) * 0.02))
        newEaseFactor = max(minEaseFactor, newEaseFactor)
        
        let newInterval: Int
        if quality < 3 {
            // Failed - reset to 1 day
            newInterval = 1
        } else if currentInterval < 1 {
            // First successful review
            newInterval = 1
        } else if currentInterval == 1 {
            // Second successful review
            newInterval = 6
        } else {
            // Subsequent reviews - multiply by ease factor
            newInterval = Int(Double(currentInterval) * newEaseFactor)
        }
        
        return (newInterval, newEaseFactor)
    }
    
    // MARK: - Update Learner State
    
    /// Update learner state after an exercise attempt
    static func updateLearnerState(
        state: LearnerState,
        score: Double,
        hintUsed: Bool,
        responseTimeMs: Int
    ) {
        let signal = AdaptiveSignal.from(score: score, hintUsed: hintUsed)
        
        // Update attempts and success rate
        let newAttempts = state.attempts + 1
        let currentSuccesses = Int(Double(state.attempts) * state.successRate)
        let newSuccesses = currentSuccesses + (score >= 0.8 ? 1 : 0)
        let newSuccessRate = Double(newSuccesses) / Double(newAttempts)
        
        state.attempts = newAttempts
        state.successRate = newSuccessRate
        state.lastSeen = Date()
        
        // Update signal history
        var history = state.signalHistory
        history.append(signal)
        // Keep last 10 signals
        if history.count > 10 {
            history = Array(history.suffix(10))
        }
        state.signalHistory = history
        
        // Update interval using SM-2
        let quality = mapScoreToQuality(score: score, hintUsed: hintUsed)
        // Note: We'd need to store easeFactor in LearnerState for full SM-2
        // For now, use a simplified version
        let newInterval = calculateSimplifiedInterval(
            currentInterval: state.intervalDays,
            quality: quality,
            phase: state.phase
        )
        state.intervalDays = newInterval
        state.nextDue = Calendar.current.date(byAdding: .day, value: newInterval, to: Date()) ?? Date()
        
        // Update phase based on success rate
        if state.successRate >= 0.85 && state.attempts >= 5 {
            state.phase = .maintenance
        } else if state.successRate >= 0.7 && state.attempts >= 3 {
            state.phase = .review
        } else {
            state.phase = .learning
        }
    }
    
    // MARK: - Helpers
    
    private static func mapScoreToQuality(score: Double, hintUsed: Bool) -> Int {
        // Map 0-1 score to 0-5 quality scale
        if hintUsed {
            return score >= 0.9 ? 4 : score >= 0.7 ? 3 : 2
        }
        
        if score >= 0.95 { return 5 }
        if score >= 0.85 { return 4 }
        if score >= 0.7 { return 3 }
        if score >= 0.5 { return 2 }
        if score >= 0.3 { return 1 }
        return 0
    }
    
    private static func calculateSimplifiedInterval(
        currentInterval: Int,
        quality: Int,
        phase: Phase
    ) -> Int {
        switch phase {
        case .learning:
            if quality < 3 { return 1 }
            if quality >= 4 { return min(currentInterval + 1, 3) }
            return currentInterval
        case .review:
            if quality < 3 { return max(1, currentInterval - 1) }
            if quality >= 4 { return min(currentInterval * 2, 7) }
            return currentInterval
        case .maintenance:
            if quality < 3 { return max(7, currentInterval / 2) }
            if quality >= 4 { return min(currentInterval + 7, 30) }
            return currentInterval
        }
    }
}

// MARK: - Session Statistics

struct SessionStatistics {
    let totalExercises: Int
    let correctCount: Int
    let averageScore: Double
    let averageResponseTimeMs: Int
    let hintsUsedCount: Int
    let skippedCount: Int
    
    var accuracy: Double {
        guard totalExercises > 0 else { return 0 }
        return Double(correctCount) / Double(totalExercises)
    }
    
    init(completedExercises: [CompletedExercise]) {
        self.totalExercises = completedExercises.count
        self.correctCount = completedExercises.filter { $0.score >= 0.8 }.count
        self.averageScore = completedExercises.isEmpty ? 0 : completedExercises.map(\.score).reduce(0, +) / Double(completedExercises.count)
        self.averageResponseTimeMs = completedExercises.isEmpty ? 0 : completedExercises.map(\.responseTimeMs).reduce(0, +) / completedExercises.count
        self.hintsUsedCount = completedExercises.filter(\.hintUsed).count
        self.skippedCount = completedExercises.filter { $0.score == 0 && $0.userResponse.isEmpty }.count
    }
}

// MARK: - Preview

#Preview {
    Text("Adaptive Engine Service")
}
