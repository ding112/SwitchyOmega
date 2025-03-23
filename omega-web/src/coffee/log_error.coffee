try
  targetObj = self
  storageObj = 'storedLog'
  hasLocalStorage = false
catch
  targetObj = window
  storageObj = 'log'
  hasLocalStorage = true

targetObj.onerror = (message, url, line, col, err) ->
  log = if hasLocalStorage
    localStorage[storageObj] || ''
  else
    targetObj[storageObj] || ''
  
  if err?.stack
    log += err.stack + '\n\n'
  else
    log += "#{url}:#{line}:#{col}:\t#{message}\n\n"
  
  if hasLocalStorage
    localStorage[storageObj] = log
  else
    targetObj[storageObj] = log
    targetObj._writeLogToStorage?(log)
  return
