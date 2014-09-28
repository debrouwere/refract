evaluate = (require 'coffee-script').eval
_ = require 'underscore'
_.str = require 'underscore.string'

string = (value) ->
    '"' + value + '"'

interpolate = (value, options) ->
    evaluate (string value), options

# single quotes are not interpolated in CoffeeScript, but 
# in a JSON file, "'an #{adjective} string'" looks much nicer 
# than "\"an #{adjective} string\"" so if we see single quotes, 
# we'll turn them into double quotes anyway
requote = (value) ->
    if value.match /^'.*'$/
        string value.slice 1, -1
    else
        value

kv = (key, value) ->
    obj = {}
    obj[key] = value
    obj

updateAt = (obj, segments..., key, value) ->
    for segment in segments
        obj = obj[segment] ?= {}

    _.extend obj, (kv key, value)

module.exports = (template, context, update) ->
    refract = _.partial module.exports, _, context
    update ?= _.partial updateAt, context

    switch template.constructor
        when Object
            _.object _.map template, (value, key) ->
                updateHere = _.partial update, key
                refracted = refract value, updateHere
                [key, refracted]
        when Array
            _.map template, refract
        else
            value = requote template
            try
                refracted = evaluate value, sandbox: context
            catch err
                refracted = interpolate value, sandbox: context
            
            update refracted
            refracted


module.exports.defaultHelpers = _.extend {}, _, _.str
