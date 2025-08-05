// SwitchyOmega Background Service Worker for Manifest V3
// This is a simplified version of the original background script

// Initialize storage
const storage = {
  local: chrome.storage.local,
  sync: chrome.storage.sync
};

// Initialize state
const state = {
  get: (key) => {
    return new Promise((resolve) => {
      chrome.storage.local.get(key, (result) => {
        resolve(result[key]);
      });
    });
  },
  set: (data) => {
    return new Promise((resolve) => {
      chrome.storage.local.set(data, resolve);
    });
  },
  remove: (key) => {
    return new Promise((resolve) => {
      chrome.storage.local.remove(key, resolve);
    });
  }
};

// Logging functionality
const Log = {
  log: (...args) => {
    console.log(...args);
  },
  error: (...args) => {
    console.error(...args);
  },
  str: (obj) => {
    return JSON.stringify(obj);
  }
};

// Initialize context menus for Manifest V3
function initializeContextMenus() {
  // Remove existing context menus
  chrome.contextMenus.removeAll(() => {
    // Create new context menu items
    chrome.contextMenus.create({
      id: 'enableQuickSwitch',
      title: chrome.i18n.getMessage('contextMenu_enableQuickSwitch') || 'Enable Quick Switch',
      type: 'checkbox',
      checked: false,
      contexts: ['action']
    });

    chrome.contextMenus.create({
      title: chrome.i18n.getMessage('popup_reportIssues') || 'Report Issues',
      contexts: ['action'],
      onclick: () => {
        // Handle report issues
        console.log('Report issues clicked');
      }
    });

    chrome.contextMenus.create({
      title: chrome.i18n.getMessage('popup_errorLog') || 'Error Log',
      contexts: ['action'],
      onclick: () => {
        // Handle error log download
        console.log('Error log clicked');
      }
    });
  });
}

// Handle context menu clicks
chrome.contextMenus.onClicked.addListener((info, tab) => {
  if (info.menuItemId === 'enableQuickSwitch') {
    // Handle quick switch toggle
    console.log('Quick switch toggled:', info.checked);
  }
});

// Handle extension installation
chrome.runtime.onInstalled.addListener((details) => {
  console.log('Extension installed:', details);
  initializeContextMenus();
});

// Handle extension startup
chrome.runtime.onStartup.addListener(() => {
  console.log('Extension started');
  initializeContextMenus();
});

// Handle messages from popup and content scripts
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  console.log('Message received:', request);
  
  if (!request || !request.method) {
    sendResponse({ error: { reason: 'invalidRequest' } });
    return;
  }

  // Handle different message types
  switch (request.method) {
    case 'getState':
      state.get(request.args?.[0]).then(result => {
        sendResponse({ result });
      }).catch(error => {
        sendResponse({ error });
      });
      break;
      
    case 'setState':
      state.set(request.args?.[0]).then(() => {
        sendResponse({ result: true });
      }).catch(error => {
        sendResponse({ error });
      });
      break;
      
    default:
      sendResponse({ error: { reason: 'noSuchMethod' } });
  }

  return true; // Keep message channel open for async response
});

// Handle alarms (for periodic tasks)
chrome.alarms.onAlarm.addListener((alarm) => {
  console.log('Alarm triggered:', alarm.name);
  // Handle periodic tasks here
});

// Initialize when service worker starts
console.log('SwitchyOmega background service worker started');
initializeContextMenus();