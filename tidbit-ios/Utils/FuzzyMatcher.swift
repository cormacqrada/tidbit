import Foundation
import SwiftUI

// MARK: - Fuzzy Matcher

enum FuzzyMatcher {
    
    /// Score similarity between input and target strings
    /// Returns a value between 0.0 and 1.0
    static func score(_ input: String, against target: String) -> Double {
        let normalizedInput = normalize(input)
        let normalizedTarget = normalize(target)
        
        // Exact match
        if normalizedInput == normalizedTarget {
            return 1.0
        }
        
        // Empty input
        if normalizedInput.isEmpty {
            return 0.0
        }
        
        // Calculate Levenshtein distance
        let distance = levenshteinDistance(normalizedInput, normalizedTarget)
        let maxLength = max(normalizedInput.count, normalizedTarget.count)
        
        // Convert to similarity score
        return maxLength > 0 ? 1.0 - Double(distance) / Double(maxLength) : 1.0
    }
    
    /// Check if score meets threshold
    static func matches(_ input: String, against target: String, threshold: Double = 0.8) -> Bool {
        return score(input, against: target) >= threshold
    }
    
    /// Normalize string for comparison
    /// - Lowercase
    /// - Strip punctuation
    /// - Normalize whitespace
    static func normalize(_ text: String) -> String {
        let lowercased = text.lowercased()
        
        // Remove punctuation except apostrophes within words
        var result = ""
        var previousWasSpace = false
        
        for char in lowercased {
            if char.isLetter || char.isNumber {
                result.append(char)
                previousWasSpace = false
            } else if char == "'" && !result.isEmpty {
                // Keep apostrophes that are within words
                result.append(char)
                previousWasSpace = false
            } else if char.isWhitespace || char == "-" {
                // Convert hyphens and whitespace to single space
                if !previousWasSpace {
                    result.append(" ")
                    previousWasSpace = true
                }
            }
            // Skip other punctuation
        }
        
        return result.trimmingCharacters(in: .whitespaces)
    }
    
    /// Calculate Levenshtein distance between two strings
    /// Using dynamic programming approach
    static func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let a = Array(s1)
        let b = Array(s2)
        
        let m = a.count
        let n = b.count
        
        // Edge cases
        if m == 0 { return n }
        if n == 0 { return m }
        
        // Create distance matrix
        var dp = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)
        
        // Initialize first row and column
        for i in 0...m { dp[i][0] = i }
        for j in 0...n { dp[0][j] = j }
        
        // Fill in the rest
        for i in 1...m {
            for j in 1...n {
                let cost = a[i - 1] == b[j - 1] ? 0 : 1
                dp[i][j] = min(
                    dp[i - 1][j] + 1,      // deletion
                    dp[i][j - 1] + 1,      // insertion
                    dp[i - 1][j - 1] + cost // substitution
                )
            }
        }
        
        return dp[m][n]
    }
}

// MARK: - Validation Result

struct ValidationResult {
    let score: Double
    let passed: Bool
    let feedback: String
    let correctAnswer: String
    let userAnswer: String
    
    init(score: Double, passed: Bool, feedback: String, correctAnswer: String, userAnswer: String) {
        self.score = score
        self.passed = passed
        self.feedback = feedback
        self.correctAnswer = correctAnswer
        self.userAnswer = userAnswer
    }
    
    init(input: String, target: String, threshold: Double = 0.8) {
        let score = FuzzyMatcher.score(input, against: target)
        self.score = score
        self.passed = score >= threshold
        self.correctAnswer = target
        self.userAnswer = input
        
        if score >= 0.99 {
            self.feedback = "Perfect!"
        } else if score >= threshold {
            self.feedback = "Close enough!"
        } else if score >= threshold - 0.1 {
            self.feedback = "Almost..."
        } else {
            self.feedback = "Not quite"
        }
    }
}

// MARK: - Adaptive Signal Helper

extension AdaptiveSignal {
    static func from(score: Double, hintUsed: Bool) -> AdaptiveSignal {
        if hintUsed {
            return .hintUsed
        } else if score >= 0.9 {
            return .gotIt
        } else if score >= 0.5 {
            return .struggled
        } else {
            return .skipped
        }
    }
}

// MARK: - Confidence Level (for self-report exercises)

enum ConfidenceLevel {
    case gotIt, close, missed
}

// MARK: - Preview / Test

#Preview("Fuzzy Matcher Tests") {
    VStack(alignment: .leading, spacing: 12) {
        Text("Fuzzy Matcher Tests")
            .font(.headline)
        
        Group {
            Text("Exact: \(FuzzyMatcher.score("hello", against: "hello"))") // 1.0
            Text("Case: \(FuzzyMatcher.score("Hello", against: "hello"))") // 1.0
            Text("Punct: \(FuzzyMatcher.score("Hello!", against: "hello"))") // 1.0
            Text("Typo: \(FuzzyMatcher.score("helo", against: "hello"))") // ~0.8
            Text("Missing: \(FuzzyMatcher.score("hell", against: "hello"))") // ~0.8
            Text("Wrong: \(FuzzyMatcher.score("world", against: "hello"))") // ~0.0
        }
        .font(.system(.body, design: .monospaced))
    }
    .padding()
}
