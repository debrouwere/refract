_ = require 'underscore'

exports.applyToKeys = applyToKeys = (obj, fn) ->
    if obj.constructor is Object
        _.object _.map obj, (value, key) ->
            [(fn key), (applyToKeys value, fn)]
    else
        obj