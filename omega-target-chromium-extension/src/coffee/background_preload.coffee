window.UglifyJS_NoUnsafeEval = true

# 检测是否在Service Worker环境中
isServiceWorker = typeof self isnt 'undefined' and not self.document and self.importScripts

# 在Service Worker中，使用self而不是window
if isServiceWorker
  self.OmegaContextMenuQuickSwitchHandler = -> null
  target = self
else
  localStorage['log'] = ''
  localStorage['logLastError'] = ''
  window.OmegaContextMenuQuickSwitchHandler = -> null
  target = window

# 设置菜单项
if chrome.contextMenus?
  # 创建快速切换菜单
  chrome.contextMenus.create({
    id: 'enableQuickSwitch'
    title: chrome.i18n.getMessage('contextMenu_enableQuickSwitch')
    type: 'checkbox'
    checked: false
    contexts: ["action"]
  }, -> 
    # 忽略重复创建的错误
    if chrome.runtime.lastError
      console.log('Context menu may already exist:', chrome.runtime.lastError.message)
  )

  # 创建错误日志和问题报告菜单
  chrome.contextMenus.create({
    id: 'reportIssues',
    title: chrome.i18n.getMessage('popup_reportIssues')
    contexts: ["action"]
  }, -> 
    # 忽略重复创建的错误
    if chrome.runtime.lastError
      console.log('Context menu may already exist:', chrome.runtime.lastError.message)
  )

  chrome.contextMenus.create({
    id: 'errorLog',
    title: chrome.i18n.getMessage('popup_errorLog')
    contexts: ["action"]
  }, ->
    # 忽略重复创建的错误
    if chrome.runtime.lastError
      console.log('Context menu may already exist:', chrome.runtime.lastError.message)
  )

  # 在Service Worker环境中，我们需要使用onClicked事件
  chrome.contextMenus.onClicked.addListener (info) ->
    if info.menuItemId == 'reportIssues'
      OmegaDebug.reportIssue(info)
    else if info.menuItemId == 'errorLog'
      OmegaDebug.downloadLog(info)
    else if info.menuItemId == 'enableQuickSwitch'
      if typeof self isnt 'undefined' and not self.document and self.importScripts
        self.OmegaContextMenuQuickSwitchHandler(info)
      else
        window.OmegaContextMenuQuickSwitchHandler(info)
