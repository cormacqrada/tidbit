import Foundation
import SwiftData

// MARK: - Tidbit Search Service

/// Full-text search across all tidbits. Searches concept, body, userNotes,
/// meaningNotes, simpleMeaning, and topicTags. Returns results with their
/// parent lesson for collection context.
enum TidbitSearchService {

    struct Result: Identifiable {
        var id: UUID { tidbit.id }
        let tidbit: Tidbit
        let lesson: Lesson?
        let matchedField: String  // which field matched the query
    }

    /// Search all tidbits in the model context. Case-insensitive substring match.
    static func search(query: String, modelContext: ModelContext) -> [Result] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let descriptor = FetchDescriptor<Tidbit>()
        let allTidbits = (try? modelContext.fetch(descriptor)) ?? []

        return allTidbits.compactMap { tidbit in
            let lesson = tidbit.lesson
            let matchedField = firstMatchedField(query: trimmed, tidbit: tidbit)
            guard let field = matchedField else { return nil }
            return Result(tidbit: tidbit, lesson: lesson, matchedField: field)
        }
    }

    /// Determine which field first matches the query (for display context).
    private static func firstMatchedField(query: String, tidbit: Tidbit) -> String? {
        let q = query.lowercased()
        if tidbit.concept.lowercased().contains(q) { return "Concept" }
        if tidbit.body.lowercased().contains(q) { return "Content" }
        if let simple = tidbit.simpleMeaning, simple.lowercased().contains(q) { return "Simple meaning" }
        if let notes = tidbit.meaningNotes, notes.lowercased().contains(q) { return "Notes" }
        if let userNotes = tidbit.userNotes, userNotes.lowercased().contains(q) { return "Your notes" }
        if tidbit.topicTags.contains(where: { $0.lowercased().contains(q) }) { return "Tag" }
        if tidbit.examples.contains(where: { $0.lowercased().contains(q) }) { return "Example" }
        return nil
    }
}
