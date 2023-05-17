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

// MARK: Icons
/// Hue Bridge Push Link Icon
struct HueBridgeIcon: View {
    let size: CGFloat
    let version: Int

    var body: some View {
        ZStack(content: {
            RoundedRectangle(cornerRadius: 0.2*size)
                .foregroundColor(.white)
                .frame(width: size, height: size)

            Circle()
                .strokeBorder(Color.blue, lineWidth: 0.03*size)
                .frame(width: 0.4*size, height: 0.4*size)

            HStack(content: {
                ForEach(0..<3, content: { _ in
                    Circle()
                        .foregroundColor(.blue)
                        .frame(width: 0.05*size)
                })
            })
            .offset(y: -0.35*size)

            switch version {
                case 1:
                    Image(systemName: "questionmark")
                        .font(.system(size: 0.6*size))
                        .foregroundColor(.black)
                case 2:
                    Image(systemName: "hand.point.up.left.fill")
                        .foregroundColor(.black)
                        .font(.system(size: 0.6*size))
                        .offset(x: 0.18*size, y: 0.25*size)
                default: EmptyView()
            }
        })
    }
}
struct HueSensorIcon: View {
    let size: CGFloat

    var body: some View {
        ZStack(content: {
            RoundedRectangle(cornerRadius: 0.2*size)
                .foregroundColor(.white)
                .frame(width: size, height: size)

            Rectangle()
                .fill(RadialGradient(colors: [.white, .gray], center: .center, startRadius: 0, endRadius: 0.4*size))
                .frame(width: 0.4*size, height: 0.4*size)
                .cornerRadius(0.2*size)

            Circle()
                .foregroundColor(.black)
                .frame(width: 0.08*size)
            .offset(y: -0.35*size)
        })
    }
}
struct HueBridgeIcon_Previews: PreviewProvider {
    static var previews: some View {
        VStack(content: {
            HueSensorIcon(size: 100)
            HueBridgeIcon(size: 100, version: 0)
        })
    }
}
