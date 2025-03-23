OmegaTarget = require('omega-target')
OmegaPac = OmegaTarget.OmegaPac
Promise = OmegaTarget.Promise

module.exports = class Inspect
  _enabled: false
  constructor: (onInspect) ->
    @onInspect = onInspect

  enable: ->
    return unless chrome.contextMenus?
    # We don't need this API. However its presence indicates that Chrome >= 35,
    # which provides the menuItemId we need in contextMenu callback.
    # https://developer.chrome.com/extensions/contextMenus
    return unless chrome.i18n.getUILanguage?

    return if @_enabled

    webResource = [
      "http://*/*"
      "https://*/*"
      "ftp://*/*"
    ]

    ### Not so useful...
    chrome.contextMenus.create({
      id: 'inspectPage'
      title: chrome.i18n.getMessage('contextMenu_inspectPage')
      contexts: ['page']
      documentUrlPatterns: webResource
    })
    ###

    chrome.contextMenus.create({
      id: 'inspectFrame'
      title: chrome.i18n.getMessage('contextMenu_inspectFrame')
      contexts: ['frame']
      documentUrlPatterns: webResource
    })

    chrome.contextMenus.create({
      id: 'inspectLink'
      title: chrome.i18n.getMessage('contextMenu_inspectLink')
      contexts: ['link']
      targetUrlPatterns: webResource
    })

    chrome.contextMenus.create({
      id: 'inspectElement'
      title: chrome.i18n.getMessage('contextMenu_inspectElement')
      contexts: [
        'image'
        'video'
        'audio'
      ]
      targetUrlPatterns: webResource
    })
    
    # 使用 onClicked 事件监听器处理菜单点击
    chrome.contextMenus.onClicked.addListener (info, tab) =>
      if info.menuItemId in ['inspectFrame', 'inspectLink', 'inspectElement']
        @inspect(info, tab)

    @_enabled = true

  disable: ->
    return unless @_enabled
    for own menuId of @propForMenuItem
      try chrome.contextMenus.remove(menuId)
    @_enabled = false

  propForMenuItem:
    'inspectPage': 'pageUrl'
    'inspectFrame': 'frameUrl'
    'inspectLink': 'linkUrl'
    'inspectElement': 'srcUrl'

  inspect: (info, tab) ->
    return unless info.menuItemId
    url = info[@propForMenuItem[info.menuItemId]]
    if not url and info.menuItemId == 'inspectPage'
      url = tab.url
    return unless url

    @onInspect(url, tab)
