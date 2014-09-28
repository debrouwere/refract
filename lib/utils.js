// Generated by CoffeeScript 1.8.0
(function() {
  var applyToKeys, _;

  _ = require('underscore');

  exports.applyToKeys = applyToKeys = function(obj, fn) {
    if (obj.constructor === Object) {
      return _.object(_.map(obj, function(value, key) {
        return [fn(key), applyToKeys(value, fn)];
      }));
    } else {
      return obj;
    }
  };

}).call(this);