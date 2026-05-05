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

        // Length check
        let wordCount = text.split(separator: " ").count
        if wordCount < packet.allowedLengthMin {
            issues.append("Too short: \(wordCount) words, minimum \(packet.allowedLengthMin)")
        }
        if wordCount > packet.allowedLengthMax {
            issues.append("Too long: \(wordCount) words, maximum \(packet.allowedLengthMax)")
        }

        // Forbidden topic check
        let lowerText = text.lowercased()
        for topic in packet.forbiddenTopics {
            if lowerText.contains(topic.lowercased()) {
                issues.append("Contains forbidden topic: \(topic)")
            }
        }

        // Empty check
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append("Generated text is empty")
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
