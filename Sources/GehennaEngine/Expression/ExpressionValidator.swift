// MARK: - Expression Validator
// Validates generated text against the packet's constraints.
// The Expression Layer renders state but never decides truth.
// Validation enforces this boundary.

import Foundation

/// The result of validating an expression output.
public enum ValidationResult: Sendable {
    case valid(String)
    case invalid(String, issues: [String])
}

/// Validates generated text against expression packet constraints.
public struct ExpressionValidator: Sendable {

    public init() {}

    /// Validate generated text against a full packet's constraints.
    public func validate(_ text: String, packet: FullExpressionPacket) -> ValidationResult {
        var issues: [String] = []

        // Empty check — do this first to short-circuit everything else.
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append("Generated text is empty")
            return .invalid(text, issues: issues)
        }

        // Forbidden topic check — word boundaries only.
        // Substring matching causes false positives: "dead" would flag "deadly",
        // "god" would flag "goddess", etc.
        let lowerText = text.lowercased()
        for topic in packet.forbiddenTopics {
            let escaped = NSRegularExpression.escapedPattern(for: topic.lowercased())
            let pattern = "\\b\(escaped)\\b"
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               regex.firstMatch(
                   in: lowerText,
                   range: NSRange(lowerText.startIndex..., in: lowerText)
               ) != nil {
                issues.append("Contains forbidden topic: \(topic)")
            }
        }

        return issues.isEmpty ? .valid(text) : .invalid(text, issues: issues)
    }

    /// Light validation for light packets — just check non-empty.
    public func validate(_ text: String, packet: LightExpressionPacket) -> ValidationResult {
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .invalid(text, issues: ["Generated text is empty"])
        }
        return .valid(text)
    }
}
