import SwiftUI

// MARK: - 主题系统
enum AppTheme: String, CaseIterable {
    case glassmorphism = "毛玻璃"

    var colors: ThemeColors {
        switch self {
        case .glassmorphism:
            return GlassmorphismTheme()
        }
    }
}

// MARK: - 主题颜色协议
protocol ThemeColors {
    var background: Color { get }
    var secondaryBackground: Color { get }
    var cardBackground: Color { get }
    var primaryText: Color { get }
    var secondaryText: Color { get }
    var accent: Color { get }
    var tagColors: [Color] { get }
    var shadowColor: Color { get }
    var divider: Color { get }
    var borderColor: Color { get }
    var glassBlur: CGFloat { get }
}

// MARK: - QuickIdea 主题（灵感橙黄配色）
struct GlassmorphismTheme: ThemeColors {
    // 温暖浅米色背景
    var background = Color(hex: "f8f7f4")

    // 纯白次要背景
    var secondaryBackground = Color(hex: "ffffff")

    // 纯白卡片背景
    var cardBackground = Color(hex: "ffffff")

    // 主文字（深灰）
    var primaryText = Color(hex: "333333")

    // 次要文字（中灰）
    var secondaryText = Color(hex: "888888")

    // 强调色（灵感橙黄）
    var accent = Color(hex: "FFB84D")

    // 标签颜色（统一使用橙黄）
    var tagColors = [
        Color(hex: "FFB84D")
    ]

    // 阴影颜色（极浅）
    var shadowColor = Color.black.opacity(0.04)

    // 分隔线颜色
    var divider = Color.black.opacity(0.05)

    // 边框颜色（透明）
    var borderColor = Color.clear

    // 模糊程度（无模糊）
    var glassBlur: CGFloat = 0
}

// MARK: - Color Extension (Hex 支持)
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - 主题环境
class ThemeManager: ObservableObject {
    @Published var currentTheme: AppTheme = .glassmorphism {
        didSet {
            UserDefaults.shared.set(currentTheme.rawValue, forKey: "selectedTheme")
        }
    }

    init() {
        if let saved = UserDefaults.shared.string(forKey: "selectedTheme"),
           let theme = AppTheme(rawValue: saved) {
            currentTheme = theme
        }
    }
}

// MARK: - 卡片效果视图修饰符
struct GlassEffect: ViewModifier {
    let theme: ThemeColors

    func body(content: Content) -> some View {
        content
            .background(theme.cardBackground)
            .cornerRadius(8)
            .shadow(color: theme.shadowColor, radius: 2, y: 1)
    }
}

extension View {
    func glassCard(theme: ThemeColors) -> some View {
        modifier(GlassEffect(theme: theme))
    }
}
