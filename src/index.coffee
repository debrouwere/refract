evaluate = (require 'coffee-script').eval
_ = require 'underscore'
_.str = require 'underscore.string'


string = (value) ->
    '"' + value + '"'

# single quotes are not interpolated in CoffeeScript, but 
# in a JSON file, "'an #{adjective} string'" looks much nicer 
# than "\"an #{adjective} string\"" so if we see single quotes, 
# we'll turn them into double quotes anyway
requote = (value) ->
    if value.match /^'.*'$/
        string value.slice 1, -1
    else
        value


module.exports = (template, context) ->
    refract = _.partial module.exports, _, context

    switch template.constructor
        when Object
            _.object _.map template, (value, key) ->
                [key, refract value]
        when Array
            _.map template, refract
        else
            value = requote template
            try
                evaluate value, sandbox: context
            catch err
                evaluate (string value), sandbox: context


module.exports.builtinHelpers = _.extend {}, _, _.str
