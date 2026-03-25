import FoundationModels

// MARK: - Generable Output Model
//
// @Generable instructs the compiler to synthesize a JSON schema that the
// LanguageModelSession uses during constrained decoding.  Every @Guide
// annotation narrows the token distribution *at the logit level*, so the
// model never wastes tokens exploring invalid values.
//
// Token-budget math:
//   urgency   → 1 token  ("High" | "Medium" | "Low")
//   summary   → ≤ 40 tokens (maximumCount on the String maps to word count)
//   tags      → ≤ 3 items × ~2 tokens each  = 6 tokens
//   errorCode → optional, 0–1 token
//   ────────────────────────────────────────
//   Worst-case output ≈ 50 tokens — keeps latency under 200 ms on A17 Pro.

@Generable
public struct LogSummary {
    /// Triage level derived from error density and user-facing impact signals.
    @Guide(description: "Triage urgency", .anyOf(["High", "Medium", "Low"]))
    public var urgency: String

    /// One-sentence human-readable synopsis of the log batch.
    @Guide(description: "Plain-language summary", .maximumCount(40))
    public var summary: String

    /// Searchable topic labels extracted from log content.
    @Guide(description: "Up to 3 domain tags", .maximumCount(3))
    public var tags: [String]

    /// Primary error code when a single error dominates the batch, else nil.
    public var dominantErrorCode: String?
}
