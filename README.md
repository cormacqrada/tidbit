Tidbit is a closed-loop personal learning engine. Users feed it raw material — articles, notes, PDFs, voice memos — and it converts that material into structured, repeatable learning sessions. The system trains you on your own knowledge, not generic content.
The mental model: NotebookLM × Duolingo. Your knowledge becomes searchable and explainable (NotebookLM). Your learning becomes habitual and measurable (Duolingo). Together: your knowledge becomes a training loop that upgrades your thinking daily.

Core Concepts

Tidbit (atomic unit): A single idea, extracted from source material, structured for learning. One concept, one definition, one source. The irreducible unit of the system.

Lessons: A named group of tidbits around a topic or source. The user-facing organizational layer. Analogous to a deck, but richer — collections carry metadata, dependency graphs, and learning state.

Session: A daily learning loop of 5–10 exercises drawn from due tidbits. Mixed exercise types, scored in real time.

Exercise: A renderer + validator pair instantiated from a template against a tidbit. The composable primitive.

Adaptive Engine: The scheduler that decides which tidbits to surface, in what order, using what exercise type, based on telemetry history.

Product Goals
Composable: Exercise types are building blocks — prompt, answer, validation, feedback, scoring — each independently swappable.
Extensible: Third parties can author new exercise templates against a published schema.
Configurable: Educators and learners can tune frequency, difficulty, modality, and hint policy per collection or session.
Trackable: Every exercise attempt emits a standardized telemetry event. The adaptive engine consumes nothing else.

User Flows
Cold Start

User opens app, sees Your Lessons title and empty state in content body.
Plus button in the corner which triggers a "Create a lesson plan".
Names a topic, optionally pastes seed material or a URL


Daily Loop

Home screen shows search and all your available lesson plans as cards.
Tap "Start session"  on card aand exercise runner



 Exercise Types
text_recall — Show concept, user types definition. Fuzzy-match scored. No AI required for scoring. Configurable: fuzzy_threshold, hint_policy.
vocab_match — Show definition, pick concept from N choices. Distractor generation requires AI (paid) or static distractor list (free). Configurable: num_choices, distractor_strategy.
fill_blank — Definition shown with concept blanked out. Deterministic. No AI required. Configurable: blank_position, hint_chars.
explain_back — Show concept, user explains in own words. Requires Claude grading (paid only). Configurable: scoring_rubric, min_length.
concept_connect — Drag-and-drop link related tidbits. Fully deterministic from dependency graph. No AI required.
quickfire — Timed recall across 5 tidbits. Deterministic scoring. Configurable: timelimit, scoring_threshold.
line_prompt — Show the preceding line as cue, user types the next line. The workhorse of sequential memorization. Fuzzy-match scored (punctuation-tolerant). No AI required.
word_fill — Show a complete line with one or more words blanked. User fills the gap. Deterministic. Difficulty knob controls how many words are blanked and whether they're high-frequency or semantically loaded words. No AI required.
stanza_reconstruct — Show a stanza with lines shuffled. User drag-reorders them into correct sequence. Fully deterministic from the source poem. No AI required. Variant of concept_connect but order-aware.
cold_open — Show only the poem title and stanza number. User types the entire stanza from memory. Hardest mode. Fuzzy-scored line by line, returns a per-line breakdown. No AI required for scoring.
meaning_probe — Show a line or image from the poem. Claude asks a question about meaning, tone, or imagery. User responds in free text. Claude grades against the poem's context. AI required (paid). This is the comprehension layer — stops rote memorization from being hollow.
rhythm_tap (stretch) — User taps the rhythm of a line against a metronome. Validates syllable count and stress pattern. No AI, but requires audio/haptic infrastructure. Probably v2.

Adaptive Engine
Inputs

Learner attempt history (success, response time, confidence signal)
Tidbit metadata (difficulty, last_seen, success_rate, dependency_ids)
Session config (duration, modality preferences)

v1 Algorithm
Weighted priority queue. Each tidbit gets a score:
priority = recency_weight × time_since_last_seen
         + difficulty_weight × (1 - success_rate)
         + dependency_weight × dependencies_mastered_ratio
SM-2 / FSRS interval scheduling for tidbits in "maintenance" phase (success_rate > 0.85). No AI required.
Adaptive Hook Signals
Every exercise emits one of: got_it · struggled · skipped · hint_used. The engine adjusts the tidbit's next interval based on the signal, not raw score alone.

Data Schemas
Tidbit
json{
  "id": "uuid",
  "collection_id": "uuid",
  "concept": "Spaced repetition",
  "definition": "A learning technique that schedules review at increasing intervals based on recall strength.",
  "source_excerpt": "...original passage...",
  "source_url": "https://...",
  "topic_tags": ["learning-science", "memory"],
  "difficulty": 2,
  "dependency_ids": ["uuid-of-memory-consolidation-tidbit"],
  "created_at": "ISO8601",
  "created_by": "ai" | "manual",
  "visibility": "private" | "team" | "public"
}

0r maybe {
  "id": "uuid",
  "collection_id": "uuid",
  "content_type": "poem_line",
  "concept": "Line 3, Stanza 1",
  "body": "Because I could not stop for Death —",
  "sequence_index": 3,
  "stanza_index": 1,
  "source_title": "Because I Could Not Stop for Death",
  "source_author": "Emily Dickinson",
  "difficulty": 1,
  "dependency_ids": ["line-2-uuid"],
  "meaning_notes": "Death personified as a courteous gentleman..."
}


Exercise Template
json{
  "template_id": "text_recall_v1",
  "type": "text_recall",
  "display_name": "Recall",
  "ai_required": false,
  "config_schema": {
    "fuzzy_threshold": { "type": "float", "default": 0.8, "min": 0.5, "max": 1.0 },
    "hint_policy": { "type": "enum", "values": ["none", "first_letter", "word_count"], "default": "none" }
  },
  "prompt_template": "What is {{concept}}?",
  "answer_field": "definition",
  "validator": "fuzzy_match",
  "adaptive_hook": "standard_recall"
}
Telemetry Event
json{
  "event_id": "uuid",
  "session_id": "uuid",
  "tidbit_id": "uuid",
  "template_id": "text_recall_v1",
  "learner_id": "uuid",
  "timestamp": "ISO8601",
  "response_raw": "...",
  "score": 0.92,
  "response_time_ms": 4200,
  "hint_used": false,
  "adaptive_signal": "got_it" | "struggled" | "skipped" | "hint_used",
  "exercise_config": { "fuzzy_threshold": 0.8, "hint_policy": "none" }
}
Learner State (per tidbit)
json{
  "tidbit_id": "uuid",
  "learner_id": "uuid",
  "attempts": 7,
  "success_rate": 0.71,
  "last_seen": "ISO8601",
  "next_due": "ISO8601",
  "interval_days": 3,
  "phase": "learning" | "review" | "maintenance",
  "adaptive_signal_history": ["got_it", "struggled", "got_it", "got_it"]
}


Weekend MVP with poem use case
MVP (build this weekend):
Step 1 — text tab only. Paste area, auto-detect poem vs prose, collection name field. No URL fetch, no file, no voice yet.
Step 2 — configure: learning goal chips, session length chips, hint policy. Three dials, all tap-selectable, no sliders.
Step 2b — exercise mix: show the list with frequency dots, but hardcode the defaults based on content_type × learning_goal. No user adjustment yet — just show them what they're getting. Meaning probe locked with the AI badge.
Step 3 — processing: the progress steps list, but steps 1–2 are instant (no spinner needed for text parsing), only step 3 (tidbit generation) has the active state. Honest about what's happening.

