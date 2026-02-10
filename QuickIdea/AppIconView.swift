import SwiftUI

struct AppIconView: View {
    // Flomo 绿色
    private let accentColor = Color(hex: "30cf79")
    private let backgroundColor = Color(hex: "f2f2f2")
    
    var body: some View {
        ZStack {
            // 背景
            RoundedRectangle(cornerRadius: 180)
                .fill(
                    LinearGradient(
                        colors: [accentColor, accentColor.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // 主图标元素 - 灯泡 + 标签符号的组合
            VStack(spacing: -20) {
                // 灯泡图标
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 320, weight: .medium))
                    .foregroundStyle(.white)
                
                // 底部标签符号
                HStack(spacing: 8) {
                    Text("#")
                        .font(.system(size: 140, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                }
                .offset(y: -60)
            }
            .offset(y: 20)
        }
        .frame(width: 1024, height: 1024)
    }
}

// 简洁版本 - 纯灯泡
struct AppIconSimpleView: View {
    private let accentColor = Color(hex: "30cf79")
    
    var body: some View {
        ZStack {
            // 纯色背景
            RoundedRectangle(cornerRadius: 180)
                .fill(accentColor)
            
            // 灯泡图标
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 500, weight: .medium))
                .foregroundStyle(.white)
        }
        .frame(width: 1024, height: 1024)
    }
}

// 备选版本 - 便签风格
struct AppIconNoteView: View {
    private let accentColor = Color(hex: "30cf79")
    
    var body: some View {
        ZStack {
            // 背景
            RoundedRectangle(cornerRadius: 180)
                .fill(accentColor)
            
            // 便签卡片
            RoundedRectangle(cornerRadius: 40)
                .fill(.white)
                .frame(width: 600, height: 700)
                .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
            
            // 内容
            VStack(alignment: .leading, spacing: 40) {
                // 标签
                HStack(spacing: 16) {
                    tagPill("想法")
                    tagPill("💡")
                }
                
                // 横线代表文字
                VStack(alignment: .leading, spacing: 24) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 400, height: 24)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 300, height: 24)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 350, height: 24)
                }
            }
        }
        .frame(width: 1024, height: 1024)
    }
    
    private func tagPill(_ text: String) -> some View {
        Text("#\(text)")
            .font(.system(size: 48, weight: .semibold, design: .rounded))
            .foregroundStyle(accentColor)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(accentColor.opacity(0.15))
            .clipShape(Capsule())
    }
}

// 预览
#Preview("图标方案 1 - 灯泡+标签") {
    AppIconView()
        .previewLayout(.sizeThatFits)
}

#Preview("图标方案 2 - 简洁灯泡") {
    AppIconSimpleView()
        .previewLayout(.sizeThatFits)
}

#Preview("图标方案 3 - 便签风格") {
    AppIconNoteView()
        .previewLayout(.sizeThatFits)
}
