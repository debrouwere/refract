// Generated by CoffeeScript 1.8.0
(function() {
  exports.underscore = require('underscore');

  exports.underscore.str = require('underscore.string');

  exports.custom = {
    ifelse: function(predicate, a, b) {
      if (predicate.constructor === Function) {
        predicate = predicate();
      }
      if (predicate) {
        return a;
      } else {
        return b;
      }
    },
    get: function(key, defaultValue) {
      if (global[key] != null) {
        return global[key];
      } else {
        return defaultValue;
      }
    }
  };

}).call(this);