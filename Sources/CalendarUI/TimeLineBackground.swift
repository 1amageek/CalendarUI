//
//  SwiftUIView.swift
//  
//
//  Created by Norikazu Muramoto on 2022/09/15.
//

import SwiftUI

public struct TimelineBackground: View {
        
    var insets: EdgeInsets
    
    var start: Int = 0
    
    var end: Int = 24
    
    var hideTime: Int?
    
    var range: ClosedRange<Int> { start...end }
    
    public init(start: Int = 0, end: Int = 24, hideTime: Int? = nil, insets: EdgeInsets = .init(top: 12, leading: 56, bottom: 12, trailing: 0)) {
        self.start = start
        self.end = end
        self.hideTime = hideTime
        self.insets = insets
    }
    
    public var body: some View {
        Canvas { context, size in
            let height = (size.height - insets.top - insets.bottom) / CGFloat(range.count - 1)
            let start = insets.leading
            let end = size.width - insets.trailing
            range.forEach { index in
                let y = insets.top + height * CGFloat(index)
                let path = Path { path in
                    path.addLines([CGPoint(x: start, y: y), CGPoint(x: end, y: y)])
                }
                context.stroke(path, with: .color(.secondary), lineWidth: 0.5)
                if let hideTime = hideTime, hideTime == index { return }
                let text = Text("\(index):00").font(.caption).foregroundColor(.secondary)
                context.draw(text, at: CGPoint(x: start - 8, y: y), anchor: .trailing)
            }
        }
    }
}

struct TimelineBackground_Previews: PreviewProvider {
    static var previews: some View {
        TimelineBackground(hideTime: 13)
    }
}
