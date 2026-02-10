# QuickIdea - 灵感记录 App

一个简洁的 iOS 应用，支持用 `#标签` 快速记录和整理想法。

## ✨ 功能

### 核心功能
- 📝 快速文字输入（顶部固定输入框）
- 🎤 语音转文字输入
- 📷 图片附件支持（最多 5 张）
- 🏷️ 自由标签系统（`#标签` 语法）
- 🔍 按标签筛选

### 状态管理
- 📊 四种状态：未处理 / 进行中 / 已完成 / 已放弃
- 👆 滑动手势快速切换状态
- 📈 侧栏实时统计

### 提醒系统
- 🔔 定时通知推送（自定义时间）
- 📱 Widget 只显示未处理灵感
- 🎲 随机推送，避免习惯性忽略
- 🎨 三种显示模式（最新/随机/多条）

### 小组件
- 📱 锁屏和主屏小组件（5 种尺寸）
- 💡 只显示未处理的灵感
- 🔢 实时显示未处理数量

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
   - **首次运行需添加新文件**（见下方）
   - 按 Cmd+R 运行

### 添加新功能文件（首次必需）

项目包含 4 个新功能文件需要手动添加到 Xcode：

1. 右键点击左侧 `QuickIdea` 文件夹
2. 选择 "Add Files to QuickIdea..."
3. 多选以下文件：
   - `SpeechRecognizer.swift` (语音识别)
   - `SpeechInputView.swift` (语音界面)
   - `NotificationManager.swift` (通知管理)
   - `NotificationSettingsView.swift` (通知设置)
4. 确保勾选 `QuickIdea` Target
5. 点击 "Add"
6. Clean Build Folder (Shift+Cmd+K)
7. Build (Cmd+B)

3. **测试构建**
   ```bash
   ./test-build.sh
   ```

## 📱 使用方法

### 快速输入

**文字输入**：主界面顶部输入框，回车保存

**语音输入**：
1. 点击麦克风图标 🎤
2. 授权麦克风和语音识别权限（首次）
3. 说出想法，实时转文字
4. 点击完成

**添加图片**：
1. 在添加/编辑界面点击"添加图片"
2. 从相册选择（最多 5 张）
3. 可预览和删除

### 记录想法

```
完成项目文档 #工作 #待办
学习 SwiftUI #学习 #编程
周末去爬山 #生活
```

- 支持多个标签
- 自动提取 `#标签`
- 点击建议标签快速添加

### 状态管理

**手势操作**：
- 右滑：标记为已完成 ✅
- 左滑：标记为进行中 ➡️
- 长按：显示更多状态选项

**状态类型**：
- 💡 未处理（橙黄色）
- ➡️ 进行中（蓝色）
- ✅ 已完成（绿色）
- 📦 已放弃（灰色）

### 添加小组件

**主屏小组件**：长按主屏幕 → 点击 + → 搜索 "QuickIdea"

**锁屏小组件**：长按锁屏 → 自定义 → 添加小组件

### 配置显示

**小组件显示方式**（侧栏设置）：
- 最新一条（默认）
- 随机一条（避免习惯性忽略）
- 显示多条（2-3 条）

**通知提醒**（侧栏设置）：
1. 打开侧栏 → 通知提醒
2. 开启通知开关
3. 添加提醒时间（可多个）
4. 默认时间：9:00 / 15:00 / 20:00

## 🏗️ 项目结构

```
QuickIdea/
├── QuickIdea/                      # 主应用
│   ├── AppDelegate.swift           # App 入口
│   ├── Idea.swift                  # 数据模型（含图片支持）
│   ├── ContentView.swift           # 主界面（含快速输入栏）
│   ├── IdeaListView.swift          # 想法列表（含手势操作）
│   ├── AddIdeaView.swift           # 添加想法（含图片选择）
│   ├── SpeechRecognizer.swift      # 语音识别引擎
│   ├── SpeechInputView.swift       # 语音输入界面
│   ├── NotificationManager.swift   # 通知管理器
│   ├── NotificationSettingsView.swift  # 通知设置
│   ├── Theme.swift                 # 主题配色
│   └── SettingsView.swift          # 设置
│
└── QuickIdeaWidgetExtension/       # 小组件
    └── QuickIdeaWidget.swift       # 小组件实现
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
- SwiftData - 数据持久化（支持外部存储）
- WidgetKit - 小组件
- Speech Framework - 语音识别
- AVFoundation - 音频采集
- PhotosUI - 相册选择
- UserNotifications - 通知推送
- App Groups - 数据共享

## 🎨 设计特点

- **配色方案**：灵感橙黄 (#FFB84D) 主题
- **交互方式**：滑动手势 + 点击操作
- **输入优先**：顶部固定输入框，极速记录
- **防遗忘**：Widget + 通知双重提醒

## 📄 License

MIT License
