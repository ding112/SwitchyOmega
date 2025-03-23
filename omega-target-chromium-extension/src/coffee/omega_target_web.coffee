angular.module('omegaTarget', []).factory 'omegaTarget', ($q) ->
  decodeError = (obj) ->
    if obj._error == 'error'
      err = new Error(obj.message)
      err.name = obj.name
      err.stack = obj.stack
      err.original = obj.original
      err
    else
      obj
  callBackgroundNoReply = (method, args...) ->
    chrome.runtime.sendMessage({
      method: method
      args: args
      noReply: true
    })
  callBackground = (method, args...) ->
    d = $q['defer']()
    chrome.runtime.sendMessage({
      method: method
      args: args
    }, (response) ->
      if chrome.runtime.lastError?
        d.reject(chrome.runtime.lastError)
        return
      if response.error
        d.reject(decodeError(response.error))
      else
        d.resolve(response.result)
    )
    return d.promise
  connectBackground = (name, message, callback) ->
    port = chrome.runtime.connect({name: name})
    onDisconnect = ->
      port.onDisconnect.removeListener(onDisconnect)
      port.onMessage.removeListener(callback)
    port.onDisconnect.addListener(onDisconnect)

    port.postMessage(message)
    port.onMessage.addListener(callback)
    return

  isChromeUrl = (url) -> url.substr(0, 6) == 'chrome' or
    url.substr(0, 4) == 'moz-' or url.substr(0, 6) == 'about:'

  optionsChangeCallback = []
  requestInfoCallback = null
  prefix = 'omega.local.'
  
  # 判断是否在Service Worker环境
  isServiceWorker = typeof self isnt 'undefined' and
    not self.document and
    self.importScripts
  
  urlParser = null
  
  # 创建URL解析函数
  parseUrl = (url) ->
    if isServiceWorker
      try
        return new URL(url)
      catch
        return null
    else
      urlParser = document.createElement('a') unless urlParser?
      urlParser.href = url
      return urlParser
  
  omegaTarget =
    options: null
    state: (name, value) ->
      if arguments.length == 1
        getValue = (key) -> try JSON.parse(localStorage[prefix + key])
        if Array.isArray(name)
          return $q.when(name.map(getValue))
        else
          value = getValue(name)
      else
        localStorage[prefix + name] = JSON.stringify(value)
      return $q.when(value)
    lastUrl: (url) ->
      name = 'web.last_url'
      if url
        omegaTarget.state(name, url)
        url
      else
        try JSON.parse(localStorage[prefix + name])
    addOptionsChangeCallback: (callback) ->
      optionsChangeCallback.push(callback)
    refresh: (args) ->
      return callBackground('getAll').then (opt) ->
        omegaTarget.options = opt
        for callback in optionsChangeCallback
          callback(omegaTarget.options)
        return args
    renameProfile: (fromName, toName) ->
      callBackground('renameProfile', fromName, toName).then omegaTarget.refresh
    replaceRef: (fromName, toName) ->
      callBackground('replaceRef', fromName, toName).then omegaTarget.refresh
    optionsPatch: (patch) ->
      callBackground('patch', patch).then omegaTarget.refresh
    resetOptions: (opt) ->
      callBackground('reset', opt).then omegaTarget.refresh
    updateProfile: (name, opt_bypass_cache) ->
      callBackground('updateProfile', name, opt_bypass_cache).then((results) ->
        for own key, value of results
          results[key] = decodeError(value)
        results
      ).then omegaTarget.refresh
    getMessage: chrome.i18n.getMessage.bind(chrome.i18n)
    openUrl: (url) ->
      targetUrl = Url.sanitize(url)
      return if not targetUrl?
      chrome.tabs.create {url: targetUrl}
    openOptions: (hash) ->
      options_url = chrome.runtime.getURL('options.html')
      chrome.tabs.query {
        url: [
          'chrome-extension://*/options.html'
          'chrome-extension://*/options.html#*'
        ]
        windowId: chrome.windows.WINDOW_ID_CURRENT
      }, (tabs) ->
        if tabs.length > 0
          chrome.tabs.update tabs[0].id, {active: true}
          if hash?
            if isServiceWorker
              try
                urlObj = new URL(tabs[0]?.url || options_url)
                urlObj.hash = hash
                chrome.tabs.update tabs[0].id, {url: urlObj.href}
              catch
                chrome.tabs.update tabs[0].id, {url: "#{options_url}##{hash}"}
            else
              urlParser = document.createElement('a') unless urlParser?
              urlParser.href = tabs[0]?.url || options_url
              urlParser.hash = hash
              chrome.tabs.update tabs[0].id, {url: urlParser.href}
        else
          chrome.tabs.create {
            url: if hash then "#{options_url}##{hash}" else options_url
          }
    applyProfile: (name) ->
      callBackground('applyProfile', name)
    applyProfileNoReply: (name) ->
      callBackgroundNoReply('applyProfile', name)
    addTempRule: (domain, profileName) ->
      callBackground('addTempRule', domain, profileName)
    addCondition: (condition, profileName) ->
      callBackground('addCondition', condition, profileName)
    addProfile: (profile) ->
      callBackground('addProfile', profile).then omegaTarget.refresh
    setDefaultProfile: (profileName, defaultProfileName) ->
      callBackground('setDefaultProfile', profileName, defaultProfileName)
    getActivePageInfo: ->
      clearBadge = true
      d = $q['defer']()
      chrome.tabs.query {active: true, lastFocusedWindow: true}, (tabs) ->
        if not tabs[0]?.url
          d.resolve(null)
          return
        args = {tabId: tabs[0].id, url: tabs[0].url}
        if tabs[0].id and requestInfoCallback
          connectBackground('tabRequestInfo', args,
            requestInfoCallback)
        d.resolve(callBackground('getPageInfo', args))
      return d.promise.then (info) -> if info?.url then info else null
    refreshActivePage: ->
      d = $q['defer']()
      chrome.tabs.query {active: true, lastFocusedWindow: true}, (tabs) ->
        if tabs[0].url and not isChromeUrl(tabs[0].url)
          chrome.tabs.reload(tabs[0].id, {bypassCache: true})
        d.resolve()
      return d.promise
    openManage: ->
      chrome.tabs.create url: 'chrome://extensions/?id=' + chrome.runtime.id
    openShortcutConfig: ->
      chrome.tabs.create url: 'chrome://extensions/configureCommands'
    setOptionsSync: (enabled, args) ->
      callBackground('setOptionsSync', enabled, args)
    resetOptionsSync: (enabled, args) -> callBackground('resetOptionsSync')
    setRequestInfoCallback: (callback) ->
      requestInfoCallback = callback

  return omegaTarget
