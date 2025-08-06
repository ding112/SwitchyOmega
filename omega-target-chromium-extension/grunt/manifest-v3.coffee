module.exports =
  copy:
    v3_adapter:
      files: [
        {
          src: 'src/js/background_v3_adapter.js'
          dest: 'build/js/background_adapter.js'
        }
        {
          src: 'overlay/offscreen.html'
          dest: 'build/offscreen.html'
        }
      ]
  
  concat:
    v3_background:
      options:
        banner: '// SwitchyOmega Manifest V3 Service Worker\n'
      files:
        'build/js/background.js': [
          'build/js/background_adapter.js'
          'build/js/log_error.js'
          'build/js/omega_debug.js'
          'build/js/background_preload.js'
          'build/js/omega_pac.min.js'
          'build/js/omega_target.min.js'
          'build/js/omega_target_chromium_extension.min.js'
          'build/js/background_original.js'
        ]
  
  clean:
    v3_cleanup:
      src: ['build/background.html']
