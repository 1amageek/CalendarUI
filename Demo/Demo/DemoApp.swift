//
//  DemoApp.swift
//  Demo
//
//  Created by Norikazu Muramoto on 2022/09/19.
//

import SwiftUI

@main
struct DemoApp: App {

    var items: [Item] = {
        let startDate = DateComponents(calendar: .autoupdatingCurrent, timeZone: .autoupdatingCurrent, year: 2023, month: 1, day: 10, hour: 0).date!
        let endDate = DateComponents(calendar: .autoupdatingCurrent, timeZone: .autoupdatingCurrent, year: 2023, month: 2, day: 10, hour: 23, minute: 60).date!
        return stride(from: startDate, to: endDate, by: 15 * 60)
            .map { date in
                return Item(
                    id: UUID().uuidString,
                    startDate: date,
                    endDate: date.addingTimeInterval(15 * 60)
                )
            }
    }()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView(items: items)
            }            
        }
    }
}
