#!/bin/bash

echo "=== SwitchyOmega Manifest V3 快速迁移测试 ==="
echo ""

# 检查环境
echo "1. 检查构建环境..."
if ! command -v npm &> /dev/null; then
    echo "❌ npm 未安装"
    exit 1
fi

if ! command -v grunt &> /dev/null; then
    echo "❌ grunt-cli 未安装，请运行: npm install -g grunt-cli"
    exit 1
fi

echo "✅ 构建环境就绪"
echo ""

# 构建步骤
echo "2. 开始构建..."
cd omega-build
echo "   安装依赖..."
npm install
echo ""

echo "3. 构建 V2 版本..."
grunt
echo ""

echo "4. 应用 V3 迁移..."
cd ../omega-target-chromium-extension

# 备份原始 background.js
if [ -f "build/js/background.js" ]; then
    cp build/js/background.js build/js/background_original.js
fi

# 运行 V3 构建
grunt v3

echo ""
echo "5. 验证构建结果..."
if [ -f "build/manifest.json" ] && [ -f "build/js/background.js" ] && [ -f "build/offscreen.html" ]; then
    echo "✅ V3 构建成功！"
    echo ""
    echo "扩展位置: $(pwd)/build"
    echo ""
    echo "下一步："
    echo "1. 打开 Chrome 浏览器"
    echo "2. 访问 chrome://extensions/"
    echo "3. 启用开发者模式"
    echo "4. 点击'加载已解压的扩展程序'"
    echo "5. 选择 $(pwd)/build 目录"
else
    echo "❌ 构建失败，请检查错误信息"
fi
