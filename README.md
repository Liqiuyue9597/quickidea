# QuickIdea - 灵感记录 App

一个简洁的 iOS 应用，支持用 `#标签` 快速记录和整理想法。

## ✨ 功能

- 📝 快速记录想法
- 🏷️ 自由标签系统（`#标签` 语法）
- 🔍 按标签筛选
- ✓ 完成标记
- 📱 锁屏和主屏小组件（5 种尺寸）
- 🎨 三种显示模式（最新/随机/多条）

## 🚀 快速开始

### 环境要求

- Xcode 15.0+
- iOS 17.0+
- macOS 运行 Xcode

### 安装运行

1. **打开项目**
   ```bash
   cd /Users/elissali/github/other/QuickIdea
   open QuickIdea.xcodeproj
   ```

2. **在 Xcode 中**
   - 选择模拟器或真机
   - 在 Signing & Capabilities 中选择开发团队
   - 按 Cmd+R 运行

3. **测试构建**
   ```bash
   ./test-build.sh
   ```

## 📱 使用方法

### 记录想法

```
完成项目文档 #工作 #待办
学习 SwiftUI #学习 #编程
周末去爬山 #生活
```

- 支持多个标签
- 自动提取 `#标签`
- 点击建议标签快速添加

### 添加小组件

**主屏小组件**：长按主屏幕 → 点击 + → 搜索 "QuickIdea"

**锁屏小组件**：长按锁屏 → 自定义 → 添加小组件

### 配置显示

设置 → 选择显示方式：
- 最新一条（默认）
- 随机一条
- 显示多条

## 🏗️ 项目结构

```
QuickIdea/
├── QuickIdea/                  # 主应用
│   ├── AppDelegate.swift       # App 入口
│   ├── Idea.swift             # 数据模型
│   ├── ContentView.swift      # 主界面
│   ├── IdeaListView.swift     # 想法列表
│   ├── AddIdeaView.swift      # 添加想法
│   └── SettingsView.swift     # 设置
│
└── QuickIdeaWidgetExtension/  # 小组件
    └── QuickIdeaWidget.swift   # 小组件实现
```

## 🔧 配置

- **Bundle ID**: `com.quickidea.app`
- **Widget Bundle ID**: `com.quickidea.app.widget`
- **App Group**: `group.com.quickidea.app`
- **部署目标**: iOS 17.0+

## 🐛 故障排查

### 构建失败
```bash
# Clean 并重新构建
Cmd + Shift + K
Cmd + B
```

### 运行时崩溃（数据迁移错误）
- 删除 App 重新安装
- 或等待自动清理旧数据

### Widget 不显示
- 确认已在主 App 中添加想法
- 重新添加 Widget

## 📝 开发规范

开发者请参考 `.ai-dev-rules.md`

## 🎯 技术栈

- SwiftUI - 声明式 UI
- SwiftData - 数据持久化
- WidgetKit - 小组件
- App Groups - 数据共享

## 📄 License

MIT License
