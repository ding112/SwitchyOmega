Storage = require('./storage')
Promise = require('bluebird')

class BrowserStorage extends Storage
  constructor: (@storage, @prefix = '') ->
    # 初始化，不需要获取原型
    @storageType = if @storage? then typeof @storage else 'undefined'
    console.log("[BrowserStorage] 初始化存储: #{@storageType}")
    
  # 安全地访问存储
  _safeGetItem: (key) ->
    try
      return @storage[key] if @storage?
    catch e
      console.error("Error in _safeGetItem", e)
    return null
    
  _safeSetItem: (key, value) ->
    try
      @storage[key] = value if @storage?
      return true
    catch e
      console.error("Error in _safeSetItem", e)
    return false
    
  _safeRemoveItem: (key) ->
    try
      delete @storage[key] if @storage?
      return true
    catch e
      console.error("Error in _safeRemoveItem", e)
    return false
    
  _safeClear: ->
    try
      if typeof @storage.clear == 'function'
        @storage.clear()
      else
        # 如果clear不可用，尝试遍历并删除
        for own key of @storage
          delete @storage[key]
      return true
    catch e
      console.error("Error in _safeClear", e)
    return false
    
  _safeKey: (index) ->
    try
      if typeof @storage.key == 'function'
        return @storage.key(index)
      else
        # 如果key不可用，尝试获取对象键
        keys = Object.keys(@storage)
        return keys[index] if index < keys.length
    catch e
      console.error("Error in _safeKey", e)
    return null

  get: (keys) ->
    map = {}
    if typeof keys == 'string'
      map[keys] = undefined
    else if Array.isArray(keys)
      for key in keys
        map[key] = undefined
    else if typeof keys == 'object'
      map = keys
    for own key of map
      try
        value = JSON.parse(@_safeGetItem(@prefix + key))
      map[key] = value if value?
      if typeof map[key] == 'undefined'
        delete map[key]
    Promise.resolve map

  set: (items) ->
    for own key, value of items
      value = JSON.stringify(value)
      @_safeSetItem(@prefix + key, value)
    Promise.resolve items

  remove: (keys) ->
    if not keys?
      if not @prefix
        @_safeClear()
      else
        index = 0
        while true
          key = @_safeKey(index)
          break if key == null
          if key.substr(0, @prefix.length) == @prefix
            @_safeRemoveItem(key)
          else
            index++
    else if typeof keys == 'string'
      @_safeRemoveItem(@prefix + keys)
    else
      for key in keys
        @_safeRemoveItem(@prefix + key)

    Promise.resolve()

module.exports = BrowserStorage
