import SwiftUI

public struct TimelineBackground: View {
    private let range: ClosedRange<Int>
    private let hideTime: Int?
    private let insets: EdgeInsets
    private var axis: TimeAxis?

    public init(_ range: ClosedRange<Int> = 0...24, hideTime: Int? = nil,
                insets: EdgeInsets = .init(top: 12, leading: 56, bottom: 12, trailing: 0)) {
        precondition(0 <= range.lowerBound && range.lowerBound < range.upperBound && range.upperBound <= 24,
                     "The hour range must satisfy 0 <= lower < upper <= 24.")
        self.range = range
        self.hideTime = hideTime
        self.insets = insets
    }

    init(axis: TimeAxis, insets: EdgeInsets) {
        self.init(axis.range, insets: insets)
        self.axis = axis
    }

    public var body: some View {
        Canvas { context, size in
            let height = max(0, size.height - insets.top - insets.bottom)
            let marks: [(hour: Int, offset: CGFloat)]
            if let axis {
                marks = axis.hourMarks.map { date in
                    let hour = date == axis.period.end ? range.upperBound : axis.calendar.component(.hour, from: date)
                    return (hour, axis.offset(for: date, height: height))
                }
            } else {
                marks = range.map { hour in
                    (hour, CGFloat(hour - range.lowerBound) / CGFloat(range.upperBound - range.lowerBound) * height)
                }
            }
            for mark in marks {
                let y = insets.top + mark.offset
                var path = Path()
                path.move(to: CGPoint(x: insets.leading, y: y))
                path.addLine(to: CGPoint(x: size.width - insets.trailing, y: y))
                context.stroke(path, with: .color(.secondary), lineWidth: 0.5)
                if hideTime != mark.hour {
                    context.draw(Text("\(mark.hour):00").font(.caption).foregroundColor(.secondary),
                                 at: CGPoint(x: insets.leading - 8, y: y), anchor: .trailing)
                }
            }
        }
    }
}
