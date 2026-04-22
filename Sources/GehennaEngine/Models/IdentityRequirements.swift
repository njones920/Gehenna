// MARK: - Identity Requirements
// The Zero-Trust Cosmology verification layer.
// Defines the standards a practitioner must meet for a spirit or epoch to manifest.

import Foundation

/// Criteria a practitioner must meet to pass a spirit's identity verification.
public struct IdentityRequirements: Codable, Hashable, Sendable {

    /// Specific taboos the practitioner must not have broken.
    /// If empty, the spirit does not care about taboos.
    public let forbiddenTaboos: Set<Taboo>

    /// Relational or hardware tokens the practitioner must possess.
    /// e.g. "Authorized Cupbearer" or "Priestly Seal".
    public let requiredTokens: Set<String>

    /// The minimum required effective purity to manifest this entity.
    public let minimumPurity: Double?

    /// If true, the practitioner must have completely Clean Hands (The Noob Catalyst).
    /// Typically used for very rare, pure, or ancient epochs that will only speak to the uncorrupted.
    public let requiresCleanHands: Bool

    public init(
        forbiddenTaboos: Set<Taboo> = [],
        requiredTokens: Set<String> = [],
        minimumPurity: Double? = nil,
        requiresCleanHands: Bool = false
    ) {
        self.forbiddenTaboos = forbiddenTaboos
        self.requiredTokens = requiredTokens
        self.minimumPurity = minimumPurity
        self.requiresCleanHands = requiresCleanHands
    }

    /// Evaluates a practitioner profile against these requirements.
    /// Returns an error message if verification fails, or nil if it passes.
    public func evaluate(_ profile: PractitionerProfile) -> String? {
        if requiresCleanHands && !profile.cleanHands {
            return "The entity demands a vessel unburdened by past workings. Your hands are not clean."
        }

        if let minPurity = minimumPurity, profile.tokens.effectivePurity < minPurity {
            return "Your spiritual contamination offends the entity. Purity is insufficient."
        }

        for taboo in forbiddenTaboos {
            if profile.taboosBroken.contains(taboo) {
                return "The entity recognizes your past transgression: \(taboo.rawValue). It refuses you."
            }
        }

        for token in requiredTokens {
            let hasHardware = profile.tokens.hardwareTokens.contains(token)
            let hasRelational = profile.tokens.relationalTokens.keys.contains(token)
            if !hasHardware && !hasRelational {
                return "You lack the authority token required to bind this entity: \(token)."
            }
        }

        return nil
    }
}
