/**
 * Manifest V3 Service Worker Adapter for SwitchyOmega
 * 最小改动方案 - 将现有背景页面代码适配为 Service Worker
 */

// 创建一个虚拟的 DOM 环境
self.document = {
  getElementById: function(id) {
    // 模拟 canvas 元素用于图标绘制
    if (id === 'canvas-icon') {
      return {
        getContext: function() {
          console.warn('Canvas operations should be moved to offscreen document');
          return null;
        }
      };
    }
    return null;
  },
  createElement: function(tag) {
    return {
      addEventListener: function() {},
      appendChild: function() {},
      removeChild: function() {}
    };
  }
};

self.window = self;

// 状态持久化管理器
const StateManager = {
  _cache: {},
  _saveTimer: null,
  
  async load() {
    try {
      const data = await chrome.storage.local.get('serviceWorkerState');
      if (data.serviceWorkerState) {
        this._cache = data.serviceWorkerState;
      }
    } catch (e) {
      console.error('Failed to load state:', e);
    }
  },
  
  async save() {
    if (this._saveTimer) {
      clearTimeout(this._saveTimer);
    }
    this._saveTimer = setTimeout(async () => {
      try {
        await chrome.storage.local.set({ serviceWorkerState: this._cache });
      } catch (e) {
        console.error('Failed to save state:', e);
      }
    }, 1000);
  },
  
  get(key) {
    return this._cache[key];
  },
  
  set(key, value) {
    this._cache[key] = value;
    this.save();
  }
};

// Service Worker 启动时加载状态
StateManager.load();

// 兼容性补丁 - 替换 chrome.browserAction 为 chrome.action
if (!chrome.browserAction && chrome.action) {
  chrome.browserAction = chrome.action;
}

// 处理定时器 - 将长时间定时器转换为 alarms
const originalSetTimeout = self.setTimeout;
const originalSetInterval = self.setInterval;

self.setTimeout = function(callback, delay, ...args) {
  // 如果超过5分钟，使用 chrome.alarms
  if (delay > 5 * 60 * 1000) {
    const alarmName = 'timeout_' + Date.now() + '_' + Math.random();
    chrome.alarms.create(alarmName, { delayInMinutes: delay / 60000 });
    chrome.alarms.onAlarm.addListener(function handler(alarm) {
      if (alarm.name === alarmName) {
        chrome.alarms.onAlarm.removeListener(handler);
        callback(...args);
      }
    });
    return alarmName;
  }
  return originalSetTimeout(callback, delay, ...args);
};

self.setInterval = function(callback, interval, ...args) {
  // 如果超过5分钟，使用 chrome.alarms
  if (interval > 5 * 60 * 1000) {
    const alarmName = 'interval_' + Date.now() + '_' + Math.random();
    chrome.alarms.create(alarmName, { 
      delayInMinutes: interval / 60000,
      periodInMinutes: interval / 60000 
    });
    chrome.alarms.onAlarm.addListener(function(alarm) {
      if (alarm.name === alarmName) {
        callback(...args);
      }
    });
    return alarmName;
  }
  return originalSetInterval(callback, interval, ...args);
};

// 导入原有的脚本
try {
  importScripts(
    '../lib/log_error.js',
    '../lib/FileSaver/FileSaver.min.js',
    '../omega_debug.js',
    '../background_preload.js',
    '../omega_pac.min.js',
    '../omega_target.min.js',
    '../omega_target_chromium_extension.min.js',
    '../background.js'
  );
  console.log('SwitchyOmega V3 Service Worker loaded successfully');
} catch (error) {
  console.error('Failed to load scripts:', error);
}

// 创建 Offscreen Document（如果需要）
async function ensureOffscreenDocument() {
  const contexts = await chrome.runtime.getContexts({
    contextTypes: ['OFFSCREEN_DOCUMENT']
  });
  
  if (contexts.length === 0) {
    try {
      await chrome.offscreen.createDocument({
        url: 'offscreen.html',
        reasons: ['DOM_SCRAPING'],
        justification: 'Canvas operations for icon drawing'
      });
    } catch (e) {
      console.warn('Failed to create offscreen document:', e);
    }
  }
}

// 延迟创建 offscreen document，避免启动时的性能影响
setTimeout(() => {
  ensureOffscreenDocument();
}, 5000);

// 监听 Service Worker 生命周期事件
self.addEventListener('install', () => {
  console.log('SwitchyOmega Service Worker installed');
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  console.log('SwitchyOmega Service Worker activated');
  event.waitUntil(clients.claim());
});

// 保持 Service Worker 活跃的心跳机制（仅在必要时使用）
let heartbeatInterval;
function startHeartbeat() {
  // 每20秒更新一次时间戳
  heartbeatInterval = setInterval(async () => {
    await chrome.storage.local.set({ 'last-heartbeat': Date.now() });
  }, 20 * 1000);
}

function stopHeartbeat() {
  if (heartbeatInterval) {
    clearInterval(heartbeatInterval);
    heartbeatInterval = null;
  }
}

// 监听消息，用于处理需要 DOM 的操作
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.type === 'needsDOM') {
    ensureOffscreenDocument().then(() => {
      // 转发到 offscreen document
      chrome.runtime.sendMessage(request, sendResponse);
    });
    return true; // 异步响应
  }
});
