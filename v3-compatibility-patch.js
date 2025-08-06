// 兼容性补丁 - 在现有代码中添加这些补丁
// 将此文件包含在 background_preload.js 之后

// 1. 替换 setTimeout/setInterval 为持久化方案
const originalSetTimeout = setTimeout;
const originalSetInterval = setInterval;

window.setTimeout = function(callback, delay, ...args) {
  if (delay > 30000) { // 超过30秒的使用 alarms
    const alarmName = 'timeout_' + Date.now();
    chrome.alarms.create(alarmName, { delayInMinutes: delay / 60000 });
    chrome.alarms.onAlarm.addListener(function handler(alarm) {
      if (alarm.name === alarmName) {
        chrome.alarms.onAlarm.removeListener(handler);
        callback.apply(this, args);
      }
    });
    return alarmName;
  }
  return originalSetTimeout(callback, delay, ...args);
};

window.setInterval = function(callback, interval, ...args) {
  if (interval > 30000) { // 超过30秒的使用 alarms
    const alarmName = 'interval_' + Date.now();
    chrome.alarms.create(alarmName, { periodInMinutes: interval / 60000 });
    chrome.alarms.onAlarm.addListener(function handler(alarm) {
      if (alarm.name === alarmName) {
        callback.apply(this, args);
      }
    });
    return alarmName;
  }
  return originalSetInterval(callback, interval, ...args);
};

// 2. 状态持久化包装器
window.OmegaStateManager = {
  // 包装全局变量，自动保存到 storage
  createPersistentVar: function(name, defaultValue) {
    let value = defaultValue;
    
    // 从 storage 恢复
    chrome.storage.local.get([name]).then(result => {
      if (result[name] !== undefined) {
        value = result[name];
      }
    });
    
    return {
      get: () => value,
      set: (newValue) => {
        value = newValue;
        chrome.storage.local.set({ [name]: value });
      }
    };
  }
};

// 3. DOM 操作代理到 offscreen document
const originalGetElement = document.getElementById;
document.getElementById = function(id) {
  if (id === 'canvas-icon') {
    // 返回一个代理对象，操作会转发到 offscreen document
    return {
      getContext: function(type) {
        return {
          canvas: this,
          drawImage: (...args) => {
            chrome.runtime.sendMessage({
              type: 'canvas-operation',
              method: 'drawImage',
              args: args
            });
          },
          // 添加其他需要的 canvas 方法...
        };
      }
    };
  }
  return originalGetElement.call(document, id);
};

// 4. XMLHttpRequest 替换为 fetch
const originalXMLHttpRequest = XMLHttpRequest;
window.XMLHttpRequest = function() {
  console.warn('XMLHttpRequest is deprecated in Service Workers, consider using fetch()');
  return new originalXMLHttpRequest();
};

// 5. API 迁移助手
window.chromeApiMigration = {
  // browser_action -> action
  get browserAction() {
    return chrome.action;
  },
  
  // 其他 API 迁移...
};

// 如果在 Service Worker 环境中，应用这些兼容性修复
if (typeof importScripts !== 'undefined') {
  // Service Worker 环境
  console.log('Applying Service Worker compatibility patches');
}

console.log('V3 compatibility patches loaded');
