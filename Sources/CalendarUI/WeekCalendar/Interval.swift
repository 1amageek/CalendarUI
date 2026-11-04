import Foundation

public enum Interval {
    case hour(Int)
    case minute(Int)
    case second(Int)

    public var value: Int {
        switch self {
        case .hour(let value), .minute(let value), .second(let value): return value
        }
    }

    public var component: Calendar.Component {
        switch self {
        case .hour: return .hour
        case .minute: return .minute
        case .second: return .second
        }
    }

    private var unitsPerDay: Int {
        switch self {
        case .hour: return 24
        case .minute: return 1440
        case .second: return 86400
        }
    }

    var countOfSection: Int {
        precondition(value > 0, "Interval values must be positive.")
        let (whole, remainder) = unitsPerDay.quotientAndRemainder(dividingBy: value)
        return whole + (remainder == 0 ? 0 : 1)
    }

    func time(at section: Int) -> (hour: Int, minute: Int, second: Int) {
        precondition((0..<countOfSection).contains(section), "The section must be inside this interval's day.")
        // A valid section's product is less than unitsPerDay, even for Int.max intervals.
        let units = section * value
        switch self {
        case .hour: return (units, 0, 0)
        case .minute: return (units / 60, units % 60, 0)
        case .second: return (units / 3600, units % 3600 / 60, units % 60)
        }
    }
}
