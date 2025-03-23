// 适配器脚本，在background.js前加载，用于将环境适配到service worker

(function() {
  // 创建一个虚拟canvas元素，因为service worker中无法使用DOM
  if (typeof document === 'undefined') {
    self.document = {
      getElementById: function(id) {
        if (id === 'canvas-icon') {
          return {
            getContext: function() {
              return self.drawContext;
            }
          };
        }
        return null;
      },
      addEventListener: function() {},
      removeEventListener: function() {}
    };
  }

  // 在background.js使用drawIcon函数时转向使用service worker提供的drawSWIcon
  if (typeof self.drawSWIcon === 'function') {
    self.drawIcon = self.drawSWIcon;
  }

  // 对chrome.extension API的适配
  if (typeof chrome !== 'undefined') {
    if (!chrome.extension) {
      chrome.extension = {};
    }
    if (!chrome.extension.getURL) {
      chrome.extension.getURL = chrome.runtime.getURL;
    }
  }

  // 为chrome.browserAction添加兼容层，将操作重定向到chrome.action
  if (typeof chrome !== 'undefined') {
    if (!chrome.browserAction) {
      chrome.browserAction = {
        setIcon: function(details, callback) {
          if (chrome.action && chrome.action.setIcon) {
            return chrome.action.setIcon(details, callback);
          }
        },
        setTitle: function(details) {
          if (chrome.action && chrome.action.setTitle) {
            return chrome.action.setTitle(details);
          }
        },
        setBadgeText: function(details) {
          if (chrome.action && chrome.action.setBadgeText) {
            return chrome.action.setBadgeText(details);
          }
        },
        setBadgeBackgroundColor: function(details) {
          if (chrome.action && chrome.action.setBadgeBackgroundColor) {
            return chrome.action.setBadgeBackgroundColor(details);
          }
        },
        setPopup: function(details) {
          if (chrome.action && chrome.action.setPopup) {
            return chrome.action.setPopup(details);
          }
        },
        onClicked: {
          addListener: function(callback) {
            if (chrome.action && chrome.action.onClicked) {
              return chrome.action.onClicked.addListener(callback);
            }
          },
          hasListener: function(callback) {
            if (chrome.action && chrome.action.onClicked) {
              return chrome.action.onClicked.hasListener(callback);
            }
            return false;
          },
          removeListener: function(callback) {
            if (chrome.action && chrome.action.onClicked) {
              return chrome.action.onClicked.removeListener(callback);
            }
          }
        }
      };
    }
  }
})(); 