// Service worker for SwitchyOmega
// 导入所需的依赖项
importScripts(
  'js/log_error.js',
  'lib/FileSaver/FileSaver.min.js',
  'js/omega_debug.js',
  'js/background_adapter.js',
  'js/omega_pac.min.js',
  'js/omega_target.min.js',
  'js/omega_target_chromium_extension.min.js',
  'img/icons/draw_omega.js'
);

// 创建离屏canvas用于绘制图标
let offscreenCanvas = new OffscreenCanvas(38, 38);
let drawContext = offscreenCanvas.getContext('2d');

// 本地存储对象，替代localStorage
self.storedLog = '';
self.storedLogLastError = '';

// 服务工作线程激活事件
self.addEventListener('activate', (event) => {
  event.waitUntil(clients.claim());
  console.log('SwitchyOmega service worker activated');
});

// 服务工作线程安装事件
self.addEventListener('install', (event) => {
  event.waitUntil(self.skipWaiting());
  console.log('SwitchyOmega service worker installed');
});

// 绘制图标函数
let iconCache = {};
let drawError = null;

function drawSWIcon(resultColor, profileColor) {
  const cacheKey = `omega+${resultColor || ''}+${profileColor}`;
  const icon = iconCache[cacheKey];
  if (icon) return icon;
  
  try {
    const newIcon = {};
    for (const size of [16, 19, 24, 32, 38]) {
      offscreenCanvas.width = size;
      offscreenCanvas.height = size;
      drawContext.scale(size, size);
      drawContext.clearRect(0, 0, 1, 1);
      
      if (resultColor) {
        drawOmega(drawContext, resultColor, profileColor);
      } else {
        drawOmega(drawContext, profileColor);
      }
      
      drawContext.setTransform(1, 0, 0, 1, 0, 0);
      newIcon[size] = drawContext.getImageData(0, 0, size, size);
      
      if (newIcon[size].data[3] === 255) {
        // Some browsers may replace the image data with a opaque white image to
        // resist fingerprinting. In that case the icon cannot be drawn.
        throw new Error('Icon drawing blocked by privacy.resistFingerprinting.');
      }
    }
    
    iconCache[cacheKey] = newIcon;
    return newIcon;
  } catch (e) {
    if (!drawError) {
      drawError = e;
      console.error(e);
      console.error('Profile-colored icon disabled. Falling back to static icon.');
    }
    return null;
  }
}

// 将函数暴露给全局，以便background.js调用
self.drawSWIcon = drawSWIcon;

// IndexedDB存储类，替代localStorage
class ServiceWorkerStorage {
  constructor(prefix) {
    this.prefix = prefix || '';
    this.cache = {};
  }
  
  async get(key) {
    if (this.cache[key] !== undefined) {
      return this.cache[key];
    }
    
    try {
      const result = await chrome.storage.local.get(this.prefix + key);
      const value = result[this.prefix + key];
      this.cache[key] = value;
      return value;
    } catch (e) {
      console.error('Error getting storage', e);
      return null;
    }
  }
  
  async set(key, value) {
    this.cache[key] = value;
    const data = {};
    data[this.prefix + key] = value;
    return chrome.storage.local.set(data);
  }
  
  async remove(key) {
    delete this.cache[key];
    return chrome.storage.local.remove(this.prefix + key);
  }

  // 模拟localStorage的方法
  clear() {
    this.cache = {};
    // 获取所有以prefix开头的键并删除它们
    chrome.storage.local.get(null, (items) => {
      const keysToRemove = Object.keys(items).filter(key => 
        key.startsWith(this.prefix));
      if (keysToRemove.length > 0) {
        chrome.storage.local.remove(keysToRemove);
      }
    });
  }
}

// 初始化存储对象
const storage = new ServiceWorkerStorage('omega_');
self.localStorage = new ServiceWorkerStorage('');

// 用于记录日志的函数
self._writeLogToStorage = async (content) => {
  try {
    self.storedLog += content;
    await storage.set('log', self.storedLog);
  } catch (_) {
    // Maybe we have reached our limit here. Try trimming it.
    self.storedLog = content;
    await storage.set('log', content);
  }
};

// 重定义日志函数，使其适用于service worker
self.Log = {
  log: async (...args) => {
    console.log(...args);
    const content = args.map(arg => String(arg)).join(' ') + '\n';
    await self._writeLogToStorage(content);
  },
  error: async (...args) => {
    console.error(...args);
    const content = args.map(arg => String(arg)).join(' ');
    self.storedLogLastError = content;
    await storage.set('logLastError', content);
    await self._writeLogToStorage('ERROR: ' + content + '\n');
  },
  str: (obj) => {
    try {
      return JSON.stringify(obj);
    } catch (_) {
      return String(obj);
    }
  }
};

// 导入主要后台脚本
importScripts('js/background.js'); 