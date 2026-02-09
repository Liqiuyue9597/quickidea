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

// MARK: - Glassmorphism 主题（灰黑色调）
struct GlassmorphismTheme: ThemeColors {
    // 深色背景
    var background = Color(hex: "1a1a1a")

    // 半透明次要背景（毛玻璃效果）
    var secondaryBackground = Color(hex: "2a2a2a").opacity(0.6)

    // 半透明卡片背景（毛玻璃效果）
    var cardBackground = Color(hex: "3a3a3a").opacity(0.5)

    // 主文字（白色）
    var primaryText = Color(hex: "ffffff")

    // 次要文字（浅灰）
    var secondaryText = Color(hex: "a0a0a0")

    // 强调色（浅灰蓝）
    var accent = Color(hex: "8b9dc3")

    // 标签颜色（灰色系渐变）
    var tagColors = [
        Color(hex: "8b9dc3"),  // 浅灰蓝
        Color(hex: "9b8bc3"),  // 浅灰紫
        Color(hex: "8bc39b"),  // 浅灰绿
        Color(hex: "c3a88b")   // 浅灰棕
    ]

    // 阴影颜色
    var shadowColor = Color.black.opacity(0.3)

    // 分隔线颜色
    var divider = Color(hex: "4a4a4a")

    // 边框颜色（半透明白色）
    var borderColor = Color.white.opacity(0.2)

    // 模糊程度
    var glassBlur: CGFloat = 20
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

// MARK: - 毛玻璃效果视图修饰符
struct GlassEffect: ViewModifier {
    let theme: ThemeColors

    func body(content: Content) -> some View {
        content
            .background(
                theme.cardBackground
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(theme.borderColor, lineWidth: 1)
                    )
            )
            .cornerRadius(16)
            .shadow(color: theme.shadowColor, radius: 15, y: 5)
    }
}

extension View {
    func glassCard(theme: ThemeColors) -> some View {
        modifier(GlassEffect(theme: theme))
    }
}
