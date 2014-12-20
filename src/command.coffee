fs = require 'fs'
fs.path = require 'path'
_ = require 'underscore'
_.str = require 'underscore.string'
_.str.identity = _.identity
yaml = require 'js-yaml'
program = require 'commander'
refract = require './'
utils = require './utils'

parsers = 
    json: JSON.parse
    yml: yaml.safeLoad
    yaml: yaml.safeLoad
    txt: _.identity

program
    .option '-t --template <path>', 
        'Path to a template file.'
    .option '-s --string <template>', 
        'A template string.'
    .option '-a --apply <mapping>', 
        'A mapping that specifies which function to apply to which field.'
    .option '-u --update', 
        'Add refracted fields to the original object.'
    .option '-m --missing', 
        'Only refract a field if it is not present in the original object.'
    .option '-e --each', 
        'Refract each element in an array.'
    .option '-H --helpers <path>', 
        'Add in additional JavaScript helper functions.'
    .option '-M --modules <names>', 
        'Add in additional JavaScript modules as helper functions.'
    .option '-N, --new', 
        'Refract an empty object.'
    .option '-i --in-place', 
        'Modify the file that contains the original object.'
    .option '-n --normalized <style>', 
        'Normalize field names to a standard style.', 'underscored'
    .option '-I --indent [n]', 
        'Output pretty indented JSON.', parseInt, 2
    .parse process.argv

if program.new
    objects = [{}]
else
    inputPath = program.args[0]
    inputLocation = inputPath or '/dev/stdin'
    inputExt = (fs.path.extname inputLocation)[1..]
    parse = parsers[inputExt] or parsers.txt
    rawInput = fs.readFileSync (fs.path.resolve inputLocation), encoding: 'utf8'
    objects = parse rawInput

unless program.each
    objects = [objects]

if program.template
    rawTemplate = fs.readFileSync (fs.path.resolve program.template), encoding: 'utf8'
    templateExt = (fs.path.extname program.template)[1..]
    parse = parsers[templateExt]
    template = parse rawTemplate
else if program.string
    template = yaml.safeLoad program.string
else if program.apply
    template = _.object program.apply
        .split ','
        .map (instruction) ->
            instruction.split ':'
else
    throw new Error "Specify a --template, --string string or --apply mapping."

# TODO: allow helpers to be YAML or JSON, not just CoffeeScript or JavaScript
if program.helpers
    require 'coffee-script/register'
    additionalHelpers = program.helpers.split(',').map (helper) ->
        require fs.path.resolve helper
else
    additionalHelpers = []

helpers = _.extend {}, additionalHelpers..., refract.defaultHelpers

if program.normalized
    normalizer = _.str[program.normalized or 'identity']
    normalize = _.partial utils.applyToKeys, _, normalizer
    normalizedObjects = _.map objects, normalize
else
    normalizedObjects = objects

refractions = _.map normalizedObjects, (item) ->
    context = _.extend {}, item, helpers
    refract template, context

if program.missing or program.update
    if program.missing
        merge = utils.splat _.defaults
    else
        merge = utils.splat _.extend

    pairs = _.zip normalizedObjects, refractions
    refractions = _.map pairs, merge

unless program.each
    refractions = refractions[0]

serialization = JSON.stringify refractions, undefined, program.indent
# if the output is a string, we remove outer quotes
if refractions.constructor is String
    serialization = serialization.slice 1, -1

if program.inPlace
    if not inputPath then throw new Error "Cannot edit in-place on stdin."
    fs.writeFileSync inputPath, serialization, encoding: 'utf8'
else
    console.log serialization
