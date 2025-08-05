# Manifest V3 升级说明

## 主要变更

### 1. Manifest 版本升级
- 从 `manifest_version: 2` 升级到 `manifest_version: 3`

### 2. 背景脚本变更
- **旧版本**: 使用 `background.page` 指向 `background.html`
- **新版本**: 使用 `background.service_worker` 指向 `background.js`
- 创建了新的 `background.js` service worker 文件

### 3. 浏览器操作变更
- **旧版本**: `browser_action`
- **新版本**: `action`
- 移除了 `browser_style: false` 属性（在MV3中不再需要）

### 4. 权限变更
- 移除了 `webRequestBlocking` 权限（MV3中不再支持）
- 添加了 `declarativeNetRequest` 权限作为替代
- 将URL权限（`http://*/*`, `https://*/*`, `<all_urls>`）移到 `host_permissions` 中

### 5. 命令变更
- **旧版本**: `_execute_browser_action`
- **新版本**: `_execute_action`

### 6. 选项页面变更
- 移除了 `browser_style: false` 属性

## 技术限制和注意事项

### Service Worker 限制
- Service Worker 不能直接访问 DOM
- 不能使用 `localStorage` 直接访问
- 需要使用 `chrome.storage` API
- 不能加载外部脚本文件

### webRequestBlocking 替代方案
- 使用 `declarativeNetRequest` API
- 需要定义规则文件来替代动态拦截
- 功能可能受到一定限制

### 背景脚本简化
- 新的 `background.js` 是一个简化版本
- 主要功能包括：
  - 上下文菜单管理
  - 消息处理
  - 存储访问
  - 日志记录

## 待完成的工作

1. **完整的背景脚本功能**
   - 需要将原始 `background.coffee` 的功能迁移到 service worker
   - 处理图标绘制功能
   - 实现完整的代理管理

2. **declarativeNetRequest 规则**
   - 创建规则文件来替代 webRequestBlocking
   - 定义静态规则集

3. **测试和验证**
   - 测试所有功能在新版本下的表现
   - 验证代理切换功能
   - 检查上下文菜单功能

## 兼容性说明

- 此升级仅适用于 Chrome 88+ 和其他支持 Manifest V3 的浏览器
- Firefox 目前仍使用 Manifest V2，需要保持兼容性
- 建议在 `applications.gecko` 部分保持原有的 Manifest V2 配置

## 构建说明

1. 确保使用支持 Manifest V3 的构建工具
2. 测试 service worker 功能
3. 验证所有权限是否正确配置
4. 检查扩展在 Chrome 88+ 中的表现