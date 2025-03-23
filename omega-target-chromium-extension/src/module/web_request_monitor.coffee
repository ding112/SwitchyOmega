Heap = require('heap')
Url = require('url')

module.exports = class WebRequestMonitor
  constructor: (@getSummaryId) ->
    @_callbacks = []
    @_requests = {}
    @_recentRequests = {}
    @watching = false
    @_timer = -1
    @_tabsInfo = {}
    @tabInfo = @_tabsInfo  # 添加 tabInfo 作为 _tabsInfo 的别名

  watch: (callback) ->
    @_callbacks.push(callback) if callback?
    return if @watching
    @watching = true
    if not chrome.webRequest
      console.log('Request monitor disabled! No webRequest permission.')
      return
    # 非阻塞方式监听请求
    chrome.webRequest.onBeforeRequest.addListener(
      @_requestStart.bind(this)
      {urls: ['<all_urls>'], types: ['main_frame']}
    )
    chrome.webRequest.onHeadersReceived.addListener(
      @_requestHeadersReceived.bind(this)
      {urls: ['<all_urls>'], types: ['main_frame']}
    )
    chrome.webRequest.onBeforeRedirect.addListener(
      @_requestRedirected.bind(this)
      {urls: ['<all_urls>'], types: ['main_frame']}
    )
    chrome.webRequest.onCompleted.addListener(
      @_requestDone.bind(this)
      {urls: ['<all_urls>'], types: ['main_frame']}
    )
    chrome.webRequest.onErrorOccurred.addListener(
      @_requestError.bind(this)
      {urls: ['<all_urls>'], types: ['main_frame']}
    )
    @_timer = setInterval(@_tick.bind(this), 5000)

  _requestStart: (req) ->
    @_requests[req.requestId] = {
      id: req.requestId
      req: req
      startTime: Date.now()
      endTime: null
      events: {}
      eventOrder: []
      eventCategory: {}
    }
    @_addEvent(req.requestId, 'start', req, @eventCategory.start)

  _tick: ->
    now = Date.now()
    oldRequests = []
    for own id, req of @_requests
      if req.endTime and (now - req.endTime > 60000)
        oldRequests.push(id)
    return unless oldRequests.length > 0
    # 清理旧请求
    for id in oldRequests
      delete @_requests[id]
      if @_recentRequests[id]
        delete @_recentRequests[id]

  _requestHeadersReceived: (req) ->
    @_addEvent(req.requestId, 'responseHeaders', req, @eventCategory.headers)

  _requestRedirected: (req) ->
    @_addEvent(req.requestId, 'redirected', req, @eventCategory.redirect)
    @_triggerCallbacks(req.requestId)

  _requestError: (req) ->
    request = @_requests[req.requestId]
    return unless request?

    request.events['error'] = req
    request.eventOrder.push('error')
    request.eventCategory['error'] = @eventCategory.error
    request.failed = true
    request.endTime = Date.now()

    @_triggerCallbacks(req.requestId)

  _triggerCallbacks: (reqId) ->
    request = @_requests[reqId]
    return unless request?
    return unless @_callbacks.length > 0
    return if @_recentRequests[reqId]

    for callback in @_callbacks
      try
        callback(request)
      catch e
        console.error(e)

    @_recentRequests[reqId] = true

  _addEvent: (reqId, name, event, category) ->
    request = @_requests[reqId]
    return unless request?

    request.events[name] = event
    request.eventOrder.push(name)
    request.eventCategory[name] = category ? @eventCategory.none

  _requestDone: (req) ->
    @_addEvent(req.requestId, 'complete', req, @eventCategory.done)
    request = @_requests[req.requestId]
    return unless request?
    request.endTime = Date.now()
    @_triggerCallbacks(req.requestId)

  eventCategory:
    none: 0
    start: 1
    headers: 2
    redirect: 3
    error: 4
    done: 5

  # 添加标签页监控功能的支持
  tabsWatching: false
  _tabCallbacks: null

  watchTabs: (callback) ->
    @_tabCallbacks ?= []
    @_tabCallbacks.push(callback) if callback?
    return if @tabsWatching
    @tabsWatching = true

    @_activeTabId = -1
    @_topFrame = {}
    @_topFrameDetails = {}

    # 在Manifest V3中使用chrome.runtime.onMessage来替代阻塞式请求拦截
    chrome.runtime.onMessage.addListener (message, sender, sendResponse) =>
      if message.action == 'setTabRequestInfo' && message.tabId && message.details
        @setTabRequestInfo(message.tabId, message.details)
        sendResponse({success: true})
      return false

    chrome.tabs.query {active: true}, (tabs) =>
      if tabs?.length > 0
        @_activeTabId = tabs[0].id
      return

    chrome.tabs.onActivated.addListener ({tabId}) =>
      @_activeTabId = tabId
      try
        @_refreshTabInfo()
      catch e
        console.error(e)
      return

    chrome.tabs.onRemoved.addListener (tabId) =>
      delete @_tabsInfo[tabId]
      delete @_topFrame[tabId]
      delete @_topFrameDetails[tabId]
      return

  _newTabInfo: ->
    info =
      startTime: Date.now()
      request: null
      requestStatus: 'unknown'
      byExtension: []
      timeRulesMatched: []
      isSpecialTab: false

  setTabRequestInfo: (tabId, details) ->
    @_tabsInfo[tabId] ?= @_newTabInfo()
    for own key, value of details
      @_tabsInfo[tabId][key] = value

    @_topFrame[tabId] = @_tabsInfo[tabId].request?.url
    @_refreshTabInfo()

  _refreshTabInfo: ->
    return unless @_tabCallbacks?.length > 0
    info = @_tabsInfo[@_activeTabId]
    return unless info?
    for callback in @_tabCallbacks
      try
        callback(@_activeTabId, info)
      catch e
        console.error(e)
    return
