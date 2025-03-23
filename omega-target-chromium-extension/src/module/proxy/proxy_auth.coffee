OmegaTarget = require('omega-target')
OmegaPac = OmegaTarget.OmegaPac
Promise = OmegaTarget.Promise

module.exports = class ProxyAuth
  constructor: (log) ->
    @_requests = {}
    @log = log
    @_rules = []
    @_ruleId = 1

  listening: false
  listen: ->
    return if @listening
    if not chrome.webRequest
      @log.error('Proxy auth disabled! No webRequest permission.')
      return
    
    # 在Manifest V3中，使用非阻塞方式处理请求
    chrome.webRequest.onAuthRequired.addListener(
      @_handleAuthNotBlocking.bind(this)
      {urls: ['<all_urls>']}
    )
    chrome.webRequest.onCompleted.addListener(
      @_requestDone.bind(this)
      {urls: ['<all_urls>']}
    )
    chrome.webRequest.onErrorOccurred.addListener(
      @_requestDone.bind(this)
      {urls: ['<all_urls>']}
    )
    @listening = true

  _keyForProxy: (proxy) -> "#{proxy.host.toLowerCase()}:#{proxy.port}"
  setProxies: (profiles) ->
    @_proxies = {}
    @_fallbacks = []
    for profile in profiles when profile.auth
      for scheme in OmegaPac.Profiles.schemes when profile[scheme.prop]
        auth = profile.auth?[scheme.prop]
        continue unless auth
        proxy = profile[scheme.prop]
        key = @_keyForProxy(proxy)
        list = @_proxies[key]
        if not list?
          @_proxies[key] = list = []
        list.push({
          config: proxy
          auth: auth
          name: profile.name + '.' + scheme.prop
        })

      fallback = profile.auth?['all']
      if fallback?
        @_fallbacks.push({
          auth: fallback
          name: profile.name + '.' + 'all'
        })
    
    # 在规则更新后应用新规则
    @_applyProxyAuthRules()

  # 应用代理认证规则
  _applyProxyAuthRules: ->
    # 清除现有规则
    chrome.declarativeNetRequest?.updateSessionRules?({
      removeRuleIds: @_rules.map((rule) -> rule.id)
    }, => 
      @log.log('ProxyAuth cleared all previous rules')
      @_rules = []
      @_ruleId = 1
      
      # 为每个代理创建认证规则
      for own key, list of @_proxies
        for proxy in list
          @_addProxyAuthRule(key, proxy)
      
      # 应用规则
      if @_rules.length > 0
        chrome.declarativeNetRequest?.updateSessionRules?({
          addRules: @_rules
        }, =>
          @log.log('ProxyAuth applied', @_rules.length, 'rules')
        )
    )

  # 添加一条代理认证规则
  _addProxyAuthRule: (proxyKey, proxy) ->
    # 解析主机和端口
    [host, port] = proxyKey.split(':')
    
    # 创建规则
    rule = {
      id: @_ruleId++
      priority: 1
      action: {
        type: 'modifyHeaders'
        requestHeaders: [
          {
            header: 'Proxy-Authorization'
            operation: 'set'
            value: 'Basic ' + btoa("#{proxy.auth.username}:#{proxy.auth.password}")
          }
        ]
      }
      condition: {
        urlFilter: '*'
        resourceTypes: ['main_frame', 'sub_frame', 'stylesheet', 'script', 'image', 'font', 'object', 'xmlhttprequest', 'ping', 'csp_report', 'media', 'websocket', 'webtransport', 'webbundle']
      }
    }
    
    @_rules.push(rule)
    @log.log('Added auth rule for', proxyKey, 'ID:', rule.id)

  _proxies: {}
  _fallbacks: []
  _requests: null
  
  # 非阻塞方式处理认证请求
  _handleAuthNotBlocking: (details) ->
    return unless details.isProxy
    req = @_requests[details.requestId]
    if not req?
      @_requests[details.requestId] = req = {authTries: 0}

    key = @_keyForProxy(
      host: details.challenger.host
      port: details.challenger.port
    )

    list = @_proxies[key]
    listLen = if list? then list.length else 0
    if req.authTries < listLen
      proxy = list[req.authTries]
    else
      proxy = @_fallbacks[req.authTries - listLen]
    @log.log('ProxyAuth', key, req.authTries, proxy?.name)
    
    req.authTries++
    # 无法直接返回认证信息，但我们已经通过declarativeNetRequest添加了认证头

  # 旧的阻塞方式处理，保留但不再使用
  authHandler: (details) ->
    return {} unless details.isProxy
    req = @_requests[details.requestId]
    if not req?
      @_requests[details.requestId] = req = {authTries: 0}

    key = @_keyForProxy(
      host: details.challenger.host
      port: details.challenger.port
    )

    list = @_proxies[key]
    listLen = if list? then list.length else 0
    if req.authTries < listLen
      proxy = list[req.authTries]
    else
      proxy = @_fallbacks[req.authTries - listLen]
    @log.log('ProxyAuth', key, req.authTries, proxy?.name)

    return {} unless proxy?
    req.authTries++
    return authCredentials: proxy.auth

  _requestDone: (details) ->
    delete @_requests[details.requestId]
