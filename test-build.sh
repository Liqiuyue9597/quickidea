#!/bin/bash

# QuickIdea 自动构建测试脚本
# 用于在代码修改后快速验证构建状态

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🚀 QuickIdea 构建测试"
echo "===================="
echo ""

# 项目配置
PROJECT="QuickIdea.xcodeproj"
SCHEME="QuickIdea"
SDK="iphonesimulator"
DESTINATION="platform=iOS Simulator,name=iPhone 15"

# 检查是否在项目目录
if [ ! -f "$PROJECT/project.pbxproj" ]; then
    echo -e "${RED}❌ 错误: 未找到 $PROJECT${NC}"
    echo "请在项目根目录运行此脚本"
    exit 1
fi

# 清理构建
echo "🧹 清理构建目录..."
xcodebuild -scheme "$SCHEME" -sdk "$SDK" \
    -destination "$DESTINATION" \
    clean > /dev/null 2>&1

echo "✅ 清理完成"
echo ""

# 构建项目
echo "🏗️  开始构建..."
BUILD_LOG=$(mktemp)

xcodebuild -scheme "$SCHEME" -sdk "$SDK" \
    -destination "$DESTINATION" \
    build 2>&1 | tee "$BUILD_LOG"

echo ""
echo "📊 构建统计"
echo "===================="

# 统计错误和警告
ERRORS=$(grep -c "error:" "$BUILD_LOG" 2>/dev/null || echo "0")
WARNINGS=$(grep -c "warning:" "$BUILD_LOG" 2>/dev/null || echo "0")
BUILD_SUCCESS=$(grep -c "BUILD SUCCEEDED" "$BUILD_LOG" 2>/dev/null || echo "0")

echo "错误数量: $ERRORS"
echo "警告数量: $WARNINGS"
echo ""

# 显示结果
if [ $BUILD_SUCCESS -eq 1 ] && [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✅ 构建成功！${NC}"

    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}⚠️  存在 $WARNINGS 个警告${NC}"
        echo ""
        echo "警告详情:"
        grep "warning:" "$BUILD_LOG" | head -5
    fi

    rm "$BUILD_LOG"
    exit 0
else
    echo -e "${RED}❌ 构建失败！${NC}"
    echo ""
    echo "错误详情:"
    grep "error:" "$BUILD_LOG" | head -10
    echo ""
    echo "完整日志已保存到: $BUILD_LOG"
    exit 1
fi
