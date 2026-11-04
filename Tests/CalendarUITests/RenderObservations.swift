#if os(macOS)
import AppKit
import SwiftUI

@MainActor final class RenderObservations {
    var placeholders: Set<Date> = []
    var events: Set<String> = []
    var frames: [String: CGRect] = [:]
    var viewport: CGRect = .zero
    var headers: Set<Date> = []
}
#endif
