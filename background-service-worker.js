// Service Worker for SwitchyOmega Manifest V3
// 最小改动版本 - 将现有背景脚本包装为 Service Worker

// 导入现有的模块 (使用 importScripts)
importScripts(
  'lib/FileSaver/FileSaver.min.js',
  'js/omega_debug.js',
  'js/background_preload.js',
  'js/omega_pac.min.js',
  'js/omega_target.min.js',
  'js/omega_target_chromium_extension.min.js'
);

// 全局状态存储在 chrome.storage 中
let globalState = {};

// Service Worker 启动时恢复状态
self.addEventListener('activate', async () => {
  console.log('SwitchyOmega Service Worker activated');
  await restoreState();
});

// 从存储恢复状态
async function restoreState() {
  try {
    const stored = await chrome.storage.local.get('globalState');
    if (stored.globalState) {
      globalState = stored.globalState;
    }
    
    // 重新初始化核心功能
    if (typeof OmegaTargetChromeExtension !== 'undefined') {
      await OmegaTargetChromeExtension.initialize();
    }
  } catch (error) {
    console.error('Failed to restore state:', error);
  }
}

// 定期保存状态
async function saveState() {
  try {
    await chrome.storage.local.set({ globalState });
  } catch (error) {
    console.error('Failed to save state:', error);
  }
}

// 替换定时器为 chrome.alarms
function createAlarm(name, delayInMinutes) {
  chrome.alarms.create(name, { delayInMinutes });
}

chrome.alarms.onAlarm.addListener((alarm) => {
  console.log('Alarm triggered:', alarm.name);
  // 处理定时任务
});

// 消息处理 - 兼容现有代码
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  // 转发到原有的消息处理逻辑
  if (typeof handleMessage !== 'undefined') {
    return handleMessage(message, sender, sendResponse);
  }
});

// 扩展图标点击事件
chrome.action.onClicked.addListener((tab) => {
  // 如果有弹出页面，这个事件不会触发
  // 保持原有逻辑
});

// 保存状态的定时器
setInterval(() => {
  saveState();
}, 30000); // 每30秒保存一次状态

// 创建 offscreen document 用于 DOM 操作 (如绘制图标)
async function createOffscreenDocument() {
  const existingContexts = await chrome.runtime.getContexts({
    contextTypes: ['OFFSCREEN_DOCUMENT']
  });
  
  if (existingContexts.length === 0) {
    await chrome.offscreen.createDocument({
      url: 'offscreen.html',
      reasons: ['DOM_SCRAPING'],
      justification: 'Need DOM API for icon drawing'
    });
  }
}

// 如果需要 DOM 操作，创建 offscreen document
if (typeof drawIcon !== 'undefined') {
  createOffscreenDocument();
}

console.log('SwitchyOmega Service Worker loaded');
