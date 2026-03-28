import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

enum AppearancePreference: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum LawTheme {
    typealias RGBA = (Double, Double, Double, Double)

    static let background = dynamic(light: (0.965, 0.945, 0.910, 1.0), dark: (0.086, 0.078, 0.071, 1.0))
    static let sidebar = dynamic(light: (0.922, 0.882, 0.816, 1.0), dark: (0.129, 0.114, 0.098, 1.0))
    static let card = dynamic(light: (0.992, 0.978, 0.950, 1.0), dark: (0.154, 0.133, 0.114, 1.0))
    static let cardAlt = dynamic(light: (0.925, 0.953, 0.969, 1.0), dark: (0.118, 0.180, 0.224, 1.0))
    static let accent = dynamic(light: (0.180, 0.353, 0.467, 1.0), dark: (0.647, 0.761, 0.839, 1.0))
    static let accentSoft = dynamic(light: (0.827, 0.890, 0.925, 1.0), dark: (0.219, 0.333, 0.423, 1.0))
    static let success = dynamic(light: (0.380, 0.576, 0.459, 1.0), dark: (0.545, 0.733, 0.604, 1.0))
    static let warning = dynamic(light: (0.741, 0.475, 0.255, 1.0), dark: (0.859, 0.627, 0.408, 1.0))
    static let neutral = dynamic(light: (0.760, 0.714, 0.655, 1.0), dark: (0.427, 0.388, 0.349, 1.0))
    static let text = dynamic(light: (0.180, 0.149, 0.122, 1.0), dark: (0.952, 0.914, 0.858, 1.0))
    static let secondaryText = dynamic(light: (0.416, 0.365, 0.322, 1.0), dark: (0.777, 0.720, 0.655, 1.0))

    static func font(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("Times New Roman", size: size).weight(weight)
    }

    static let body = font(18)
    static let bodySmall = font(16)
    static let title = font(32, weight: .bold)
    static let sectionTitle = font(24, weight: .semibold)
    static let cardTitle = font(21, weight: .semibold)
    static let metric = font(20, weight: .semibold)
    static let caption = font(13, weight: .semibold)

    static private func color(_ rgba: RGBA) -> Color {
        Color(red: rgba.0, green: rgba.1, blue: rgba.2, opacity: rgba.3)
    }

    static private func dynamic(light: RGBA, dark: RGBA) -> Color {
        #if canImport(UIKit)
        return Color(UIColor { traits in
            let useDark = traits.userInterfaceStyle == .dark
            let source = useDark ? dark : light
            return UIColor(red: source.0, green: source.1, blue: source.2, alpha: source.3)
        })
        #elseif canImport(AppKit)
        return Color(NSColor(name: nil) { appearance in
            let useDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            let source = useDark ? dark : light
            return NSColor(calibratedRed: source.0, green: source.1, blue: source.2, alpha: source.3)
        })
        #else
        return color(light)
        #endif
    }
}

struct AppChromeModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(LawTheme.body)
            .foregroundStyle(LawTheme.text)
            .tint(LawTheme.accent)
            .controlSize(.large)
    }
}

extension View {
    func appChrome() -> some View {
        modifier(AppChromeModifier())
    }
}
