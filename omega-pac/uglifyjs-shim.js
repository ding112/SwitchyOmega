// 设置 UglifyJS_NoUnsafeEval = true 以避免使用 eval 和 new Function
if (typeof global !== 'undefined') {
  global.UglifyJS_NoUnsafeEval = true;
}

if (typeof self !== 'undefined') {
  self.UglifyJS_NoUnsafeEval = true;
}

if (typeof window !== 'undefined') {
  window.UglifyJS_NoUnsafeEval = true;
}

require('uglify-js-real');
module.exports = UglifyJS;
