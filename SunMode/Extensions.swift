// 05.04.23, Swift 5.0, macOS 13.1, Xcode 12.4
// Copyright © 2023 amaider. All rights reserved.

import Foundation
import SwiftUI

// MARK: Extensions

// MARK: Formatter
struct Formatter {
    static let decimal: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
    
    static let relativeDateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()
}



// MARK: Blur
struct Blur: NSViewRepresentable {
    func makeNSView(context: Context) -> some NSVisualEffectView {
        let blur = NSVisualEffectView()
        blur.wantsLayer = true
        blur.blendingMode = .behindWindow
        blur.material = .hudWindow
        blur.state = .active
        blur.isEmphasized = false
        return blur
    }
    
    func updateNSView(_ nsView: NSViewType, context: Context) { }
}
// MARK: TextField
struct CustomTextField: TextFieldStyle {
    let alignment: TextAlignment
    
    func _body(configuration: TextField<_Label>) -> some View {
        configuration
            .labelsHidden()
            .multilineTextAlignment(alignment)
            .textFieldStyle(.plain)
    }
}
extension TextFieldStyle where Self == CustomTextField {
    static var custom: CustomTextField { CustomTextField(alignment: .trailing) }
    static func custom(_ alignment: TextAlignment) -> CustomTextField {
        CustomTextField(alignment: alignment)
    }
}
