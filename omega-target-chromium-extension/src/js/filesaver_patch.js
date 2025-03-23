// 修复FileSaver.js在Service Worker环境中的问题
(function() {
  try {
    // 检查是否在Service Worker环境中
    if (typeof self !== 'undefined' && !self.window && self.importScripts) {
      // Service Worker环境
      self.window = self; // 提供window对象以便FileSaver.js可以使用
      
      // 模拟一些FileSaver.js可能需要的DOM API
      if (!self.document) {
        self.document = {
          createElementNS: function() {
            return {
              style: {},
              setAttribute: function() {},
              getElementsByTagName: function() { return []; },
              appendChild: function() {}
            };
          },
          implementation: {
            createHTMLDocument: function() {
              return self.document;
            }
          },
          createElement: function() {
            return {
              style: {},
              setAttribute: function() {},
              getElementsByTagName: function() { return []; },
              appendChild: function() {}
            };
          }
        };
      }
      
      // 模拟URL API
      if (!self.URL || !self.URL.createObjectURL) {
        self.URL = {
          createObjectURL: function(blob) {
            // Service Worker无法真正创建URL，但我们可以返回一个占位符
            return "blob:" + blob.type + ":" + Math.random();
          },
          revokeObjectURL: function() {}
        };
      }
      
      console.log('[SwitchyOmega] FileSaver.js patched for Service Worker environment');
    }
  } catch (e) {
    console.error('[SwitchyOmega] Failed to patch FileSaver.js:', e);
  }
})(); 