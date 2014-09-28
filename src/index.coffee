_ = require 'underscore'
_.str = require 'underscore.string'
utils = require './utils'
{evaluate, interpolate} = utils

###
Refract uses plain vanilla CoffeeScript for evaluating 
refraction expressions, with two exceptions, encoded in
the `requote` function.

1. Single quotes are not interpolated in CoffeeScript, but 
in a JSON file, "'an #{adjective} string'" looks much nicer 
than "\"an #{adjective} string\"" so if we see single quotes, 
we'll turn them into double quotes anyway.
 
2. While /str/ denotes a regular expression in JavaScript, 
this doesn't make much sense when refracting and instead
probably denote some sort of file path, so we'll interpret 
an expression that starts and ends with a forward slash
as a strings as well.

Note that e.g. `/regexp/.exec 'some string'` and `fn 'a string'`
will not be requoted, we're only checking the first and last 
characters of the expressions.
###

requote = (value) ->
    return value unless typeof value is 'string'

    quoted = value.match /^'.*'$/
    slashes = value.match /^\/.*\/$/

    if quoted
        utils.string value.slice 1, -1
    else if slashes
        utils.string value
    else
        value

updateAt = (obj, segments..., key, value) ->
    for segment in segments
        obj = obj[segment] ?= {}

    _.extend obj, (utils.kv key, value)

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
