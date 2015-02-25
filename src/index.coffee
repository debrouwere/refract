_ = require 'underscore'
helpers = require './helpers'
#math = require 'mathjs'
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
as a string as well.

Note that e.g. `/regexp/.exec 'some string'` and `fn 'a string'`
will not be requoted, we're only checking the first and last 
characters of the expressions.
###

requote = (value) ->
    quoted = value.match /^'.*'$/
    slashes = value.match /^\/.*\/$/

    if quoted
        utils.string value.slice 1, -1
    else if slashes
        utils.string value
    else
        value

extractKeys = (key) ->
    rawKey = key
    match = key.match /(\w+)(\[(\w+)(\:(\w+))?\])?/
    matches = (_.compact match).length
    if matches > 5
        [__, key, __, namespace, __, source] = match
    else
        [__, key, __, source] = match
        source ?= key
        namespace = no
    {rawKey, key, namespace, source}

updateAt = (obj, segments..., key, value) ->
    for segment in segments
        obj = obj[segment] ?= {}

    _.extend obj, (utils.kv key, value)

module.exports = refract = (template, context, update) ->
    update ?= _.partial updateAt, context

    switch template?.constructor
        when Object
            _.object _.map template, (value, key) ->
                if (iterationOptions = key.slice -1) is ']'
                    rawKey = key
                    {key, namespace, source} = extractKeys rawKey
                    subTemplate = template[rawKey]
                    # IMPROVE: won't work if we have to traverse
                    # multiple levels for `source`, of course
                    refracted = []
                    for i in _.range context[source].length
                        subObj = context[source][i]
                        if namespace
                            subObj = utils.kv namespace, subObj
                        subContext = _.extend {}, context, subObj
                        refracted.push refract subTemplate, subContext
                    update key, refracted
                    [key, refracted]
                else
                    updateHere = _.partial update, key
                    refracted = refract value, context, updateHere
                    [key, refracted]
        when Array
            refractValue = _.partial refract, _, context, _.noop
            refracted = _.map template, refractValue
            update refracted
            refracted
        when String
            value = requote template
            try
                refracted = evaluate value, sandbox: context
            catch err
                refracted = interpolate value, sandbox: context
            
            update refracted
            refracted
        else
            template

module.exports.defaultHelpers = _.extend {refract}, _, _.str
