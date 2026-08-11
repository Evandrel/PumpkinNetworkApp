import SwiftUI

struct AppAmbientBackground: View {
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
            Circle()
                .fill(.green.opacity(0.16))
                .frame(width: 300, height: 300)
                .blur(radius: 70)
                .offset(x: -150, y: -260)
            Circle()
                .fill(.cyan.opacity(0.11))
                .frame(width: 340, height: 340)
                .blur(radius: 85)
                .offset(x: 170, y: 250)
        }
        .ignoresSafeArea()
    }
}

extension View {
    @ViewBuilder
    func liquidGlassSurface(cornerRadius: CGFloat, tint: Color? = nil, interactive: Bool = false) -> some View {
        if #available(iOS 26.0, *) {
            let baseGlass = tint.map { Glass.regular.tint($0) } ?? .regular
            glassEffect(interactive ? baseGlass.interactive() : baseGlass, in: .rect(cornerRadius: cornerRadius))
        } else {
            background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(.white.opacity(0.22), lineWidth: 0.75)
                }
        }
    }

    func primaryGlassButton() -> some View { modifier(PrimaryGlassButtonModifier()) }
    func secondaryGlassButton() -> some View { modifier(SecondaryGlassButtonModifier()) }
}

private struct PrimaryGlassButtonModifier: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) { content.buttonStyle(.glassProminent) }
        else { content.buttonStyle(.borderedProminent) }
    }
}

private struct SecondaryGlassButtonModifier: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) { content.buttonStyle(.glass) }
        else { content.buttonStyle(.borderedProminent) }
    }
}
