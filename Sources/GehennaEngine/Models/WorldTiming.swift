// MARK: - World Timing
// Environmental and calendrical conditions at the moment of ritual.
// The subtlest input class — rewards long observation.

/// Lunar phase — modulates ritual outcomes.
public enum LunarPhase: String, Codable, Hashable, CaseIterable, Sendable {
    case newMoon
    case waxingCrescent
    case firstQuarter
    case waxingGibbous
    case fullMoon
    case waningGibbous
    case lastQuarter
    case waningCrescent

    /// Resonance bonus from lunar phase. New moon and full moon are strongest.
    public var resonanceModifier: Double {
        switch self {
        case .newMoon:         return 0.2   // darkness aids passage
        case .fullMoon:        return 0.15  // illumination aids clarity
        case .waxingGibbous:   return 0.1
        case .waningGibbous:   return 0.1
        case .firstQuarter:    return 0.05
        case .lastQuarter:     return 0.05
        case .waxingCrescent:  return 0.0
        case .waningCrescent:  return 0.0
        }
    }
}

/// Time of day — night amplifies.
public enum TimeOfDay: String, Codable, Hashable, CaseIterable, Sendable {
    case dawn
    case morning
    case midday
    case afternoon
    case dusk
    case night
    case deepNight  // the small hours — strongest for ritual

    /// Veil modifier — how much the time of day affects Veil permeability.
    public var veilModifier: Double {
        switch self {
        case .deepNight:  return 0.3   // strongest amplification
        case .night:      return 0.2
        case .dusk:       return 0.1
        case .dawn:       return 0.1
        case .morning:    return 0.0
        case .midday:     return -0.1  // daylight suppresses
        case .afternoon:  return -0.05
        }
    }
}

/// The complete timing context for a ritual.
public struct WorldTiming: Codable, Hashable, Sendable {
    public let timeOfDay: TimeOfDay
    public let lunarPhase: LunarPhase

    public init(time: TimeOfDay = .night, lunar: LunarPhase = .newMoon) {
        self.timeOfDay = time
        self.lunarPhase = lunar
    }

    /// Combined timing resonance bonus.
    public var resonanceBonus: Double {
        timeOfDay.veilModifier + lunarPhase.resonanceModifier
    }
}
