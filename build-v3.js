const fs = require('fs');
const path = require('path');

// 最小改动的 V3 构建脚本
function buildV3() {
  const buildDir = 'build-v3';
  
  // 创建构建目录
  if (!fs.existsSync(buildDir)) {
    fs.mkdirSync(buildDir, { recursive: true });
  }
  
  // 1. 复制现有构建结果
  const currentBuildDir = 'omega-chromium-extension/build';
  if (fs.existsSync(currentBuildDir)) {
    copyRecursive(currentBuildDir, buildDir);
  }
  
  // 2. 替换 manifest.json
  const manifestV3 = fs.readFileSync('manifest-v3-minimal.json', 'utf8');
  fs.writeFileSync(path.join(buildDir, 'manifest.json'), manifestV3);
  
  // 3. 创建新的 background.js
  const serviceWorker = fs.readFileSync('background-service-worker.js', 'utf8');
  fs.writeFileSync(path.join(buildDir, 'js', 'background.js'), serviceWorker);
  
  // 4. 添加 offscreen.html
  const offscreenHtml = fs.readFileSync('offscreen.html', 'utf8');
  fs.writeFileSync(path.join(buildDir, 'offscreen.html'), offscreenHtml);
  
  // 5. 删除不需要的 background.html
  const backgroundHtmlPath = path.join(buildDir, 'background.html');
  if (fs.existsSync(backgroundHtmlPath)) {
    fs.unlinkSync(backgroundHtmlPath);
  }
  
  console.log('Manifest V3 build completed in:', buildDir);
}

function copyRecursive(src, dest) {
  const stats = fs.statSync(src);
  
  if (stats.isDirectory()) {
    if (!fs.existsSync(dest)) {
      fs.mkdirSync(dest, { recursive: true });
    }
    fs.readdirSync(src).forEach(file => {
      copyRecursive(path.join(src, file), path.join(dest, file));
    });
  } else {
    fs.copyFileSync(src, dest);
  }
}

// 运行构建
buildV3();
