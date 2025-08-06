#!/bin/bash

# SwitchyOmega Manifest V3 构建脚本
echo "Building SwitchyOmega for Manifest V3..."

# 确保 build 目录存在
mkdir -p build/js

# 复制 V3 适配器作为新的 background.js
echo "Creating V3 background script..."
cat src/js/background_v3_adapter.js > build/js/background.js

# 将原有的背景脚本追加到适配器后
# 注意：这里假设原有的 background.js 已经构建好
if [ -f "build/js/background_original.js" ]; then
  echo "" >> build/js/background.js
  echo "// Original background script" >> build/js/background.js
  cat build/js/background_original.js >> build/js/background.js
fi

# 复制 offscreen.html
echo "Copying offscreen document..."
cp overlay/offscreen.html build/

# 删除不需要的 background.html
if [ -f "build/background.html" ]; then
  echo "Removing background.html..."
  rm build/background.html
fi

echo "Manifest V3 build completed!"
echo "The extension can be loaded from the 'build' directory"
