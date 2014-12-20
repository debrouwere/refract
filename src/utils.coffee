_ = require 'underscore'


exports.evaluate = evaluate = (require 'coffee-script').eval

exports.string = string = (value) ->
    '"' + value + '"'

exports.interpolate = (value, options) ->
    evaluate (string value), options

exports.applyToKeys = applyToKeys = (obj, fn) ->
    applyFunctionToKeys = _.partial applyToKeys, _, fn

    switch obj.constructor
        when Object
            _.object _.map obj, (value, key) ->
                [(fn key), (applyFunctionToKeys value)]
        when Array
            _.map obj, applyFunctionToKeys
        else
            obj

exports.kv = (key, value) ->
    obj = {}
    obj[key] = value
    obj

exports.splat = (fn) ->
    ->
        fn arguments...

exports.guard = (fn) ->
    ->
        fn arguments[0]