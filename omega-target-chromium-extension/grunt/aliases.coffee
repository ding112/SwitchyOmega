module.exports =
  default: [
    'coffeelint'
    'browserify'
    'coffee'
    'copy'
    'po2crx'
  ]
  test: ['mochaTest']
  release: ['default', 'chromium-manifest', 'compress']
  v3: [
    'default'
    'copy:v3_adapter'
    'concat:v3_background'
    'clean:v3_cleanup'
  ]
