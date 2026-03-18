// jQuery 4.0 compatibility polyfill for older libraries
// Restores methods that were removed in jQuery 4.0 but are still used by legacy plugins
//
// This polyfill provides:
// - $.isFunction() - removed in jQuery 4.0, now use: typeof obj === "function"
// - $.parseJSON() - removed in jQuery 4.0, now use: JSON.parse()
// - $.isArray() - removed in jQuery 4.0, now use: Array.isArray()

if (typeof jQuery !== 'undefined') {
  if (!jQuery.isFunction) {
    jQuery.isFunction = function(obj) {
      return typeof obj === "function";
    };
  }
  
  if (!jQuery.parseJSON) {
    jQuery.parseJSON = function(data) {
      return JSON.parse(data);
    };
  }
  
  if (!jQuery.isArray) {
    jQuery.isArray = Array.isArray;
  }
}
