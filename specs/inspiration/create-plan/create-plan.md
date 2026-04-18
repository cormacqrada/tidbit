The two jobs this screen does

Ingest — get the raw material into the system cleanly regardless of source format
Configure — let the user express their intent so the system can generate the right curriculum shape

These are distinct enough that they probably deserve two sub-steps within the flow: first resolve the source, then configure the plan.

Ingestion paths and what each requires
Paste raw text — simplest. Strip leading/trailing whitespace, detect if it's a poem (line breaks, stanza gaps, short lines) vs prose vs a list. Detection heuristics: average line length, blank line frequency, whether lines end mid-sentence. Poem detection unlocks poem-specific exercise models.
URL — fetch page HTML, run through Readability (Mozilla's library, open source) to extract main content, strip nav/footer/ads. For YouTube URLs: pull transcript via youtube-transcript or ytdl-core. For PDFs served via URL: fetch as binary, extract text via pdf.js. The extracted text then enters the same pipeline as pasted text.
Markdown / file upload — parse headings as section boundaries, which become natural tidbit groupings. Code blocks flagged separately (different exercise type candidate). Bold/italic text flagged as high-salience candidates for tidbits.
Voice memo — transcribe via Whisper API, then treat as raw text. Asynchronous — show a processing state.
In all cases the output of ingestion is the same: a single clean text string with detected metadata (content_type, estimated_line_count, detected_language, source_structure).

The dials
Content type (auto-detected, user can override)
poem · prose · factual · technical · list · dialogue
This is the most important signal — it determines which exercise models are even eligible.
Learning goal (user selects one)
memorize verbatim · understand deeply · recall key ideas · exam prep
Verbatim = heavy line_prompt + fill_blank, light meaning_probe. Understand deeply = heavy meaning_probe + concept_connect, light fill_blank.
Session length
3 / 5 / 10 minutes. Controls how many exercises per session and how many tidbits are introduced per day.
Difficulty ramp
Slider: gradual → steep. Gradual = many easy exercises before introducing cold_open. Steep = harder exercises sooner.
Hint policy
always available · available once · never. Affects all exercise types.
Modality preference
typing · tapping · mixed. Typing-heavy for serious study, tapping for casual review. Affects whether fill_blank uses chips or text input.

Exercise model frequency matrix
This is the core of curriculum generation. Given content_type × learning_goal, what's the relative frequency of each exercise type?
ExercisePoem + MemorizePoem + UnderstandProse + RecallProse + Understandline_prompt●●●●●●●○○○——fill_blank●●●●○●●○○○●●○○○●○○○○word_fill●●●○○●○○○○●●●○○●●○○○stanza_reconstruct●●●○○●●●○○——cold_open●●○○○●○○○○●○○○○○○○○○meaning_probe●○○○○●●●●●●●○○○●●●●●concept_connect—●●●○○●●●○○●●●●○quickfire●●○○○○○○○○●●●○○●○○○○
These weights feed directly into the session scheduler — not just which exercises appear, but in what ratio across the curriculum lifetime.
Sequencing rule on top of frequency: within a session, always order exercises from lower to higher cognitive demand. Fill_blank before line_prompt before cold_open. Meaning_probe always last in a session (requires recall to be warm first).

Other dials worth having
Auto-advance vs manual unlock — does the system automatically unlock new tidbits as you master earlier ones, or does the user manually decide when to add more? Default auto for poems (sequential dependency is clear), manual for prose (user knows their own pace).
Mastery threshold — what success_rate triggers a tidbit moving from "learning" to "maintenance" phase. Default 0.85, adjustable 0.70–1.0. Power users want 1.0 (perfect recall). Casual users might set 0.75.
Review interval multiplier — how aggressively the SM-2 spacing grows. Compress for exam prep (more frequent review), extend for long-term retention.
Meaning notes — toggle whether Claude generates a one-line contextual note per tidbit during ingestion (costs an API call but adds the meaning_probe grounding layer).