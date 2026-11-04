//
//  CurrentTimeHand.swift
//  
//
//  Created by Norikazu Muramoto on 2022/09/16.
//

import SwiftUI

struct CurrentTimeHand: View {
    
    var text: String
    
    var insets: EdgeInsets
    
    public init(_ text: String, insets: EdgeInsets = .init(top: 0, leading: 56, bottom: 0, trailing: 0)) {
        self.text = text
        self.insets = insets
    }
    
    public var body: some View {
        Canvas { context, size in
            let start = insets.leading - 6
            let end = size.width - insets.trailing
            let y = size.height / 2
            let path = Path { path in
                path.addLines([CGPoint(x: start, y: y), CGPoint(x: end, y: y)])
            }
            context.stroke(path, with: .color(.red), lineWidth: 0.5)
            context.fill(Path(ellipseIn: CGRect(x: insets.leading - 2, y: y - 3, width: 6, height: 6)), with: .color(.red))
            let text = Text(text).font(.caption2).foregroundColor(.red)
            context.draw(text, at: CGPoint(x: start - 3, y: y), anchor: .trailing)
        }
    }
}

struct CurrentTimeHand_Previews: PreviewProvider {
    static var previews: some View {
        CurrentTimeHand("20:00")
    }
}
