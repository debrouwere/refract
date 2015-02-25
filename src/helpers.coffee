exports.underscore = require 'underscore'
exports.underscore.str = require 'underscore.string'
exports.custom =
    ifelse: (predicate, a, b) ->
        if predicate.constructor is Function then predicate = predicate()
        if predicate then a else b
    get: (key, defaultValue) ->
        if global[key]? then global[key] else defaultValue
