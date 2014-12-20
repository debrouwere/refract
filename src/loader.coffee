_ = require 'underscore'
fs = require 'fs'
fs.path = require 'path'
yaml = require 'js-yaml'
utils = require './utils'


codeParsers =
    js: require
    coffee: (path) ->
        require 'coffee-script/register'
        require path

parsers = 
    json: JSON.parse
    yml: yaml.safeLoad
    yaml: yaml.safeLoad
    txt: _.identity


exports.load = (path, options={}) ->
    extension = fs.path.extname path
    options.type ?= extension[1..]
    fullPath = fs.path.resolve path
    name = (fs.path.basename path).slice 0, -extension.length

    if parse = codeParsers[options.type]
        try
            value = parse path
        catch
            value = parse fullPath
    else
        parse = parsers[options.type] or parsers.txt
        raw = fs.readFileSync (fs.path.resolve path), encoding: 'utf8'
        value = parse raw

    if options.namespace
        utils.kv name, value
    else
        value