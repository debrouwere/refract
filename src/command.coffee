fs = require 'fs'
_ = require 'underscore'
_.str = require 'underscore.string'
_.str.identity = _.identity
program = require 'commander'
refract = require './'
{load} = require './loader'
utils = require './utils'


program
    .option '-t --template <path>', 
        'Path to a template file.'
    .option '-s --string <template>', 
        'Interpolate a string, in lieu of using a template.'
    .option '-T --template-string <template>', 
        'Describe a YAML template on the command-line.'
    .option '-a --apply <mapping>', 
        'A mapping that specifies which function to apply to which field.'
    .option '-u --update', 
        'Add refracted fields to the original object.'
    .option '-m --missing', 
        'Only refract a field if it is not present in the original object.'
    .option '-e --each', 
        'Refract each element in an array.'
    .option '-H --helpers <path>', 
        'Add in additional JavaScript helper functions and data.'
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
    if not inputPath
        inputPath = '/dev/stdin'
        type = 'yaml'
    objects = load inputPath, {type}

unless program.each
    objects = [objects]

if program.template
    template = load program.template
else if program.string
    template = program.string
else if program.templateString
    template = yaml.safeLoad program.string
else if program.apply
    template = _.object program.apply
        .split ','
        .map (instruction) ->
            instruction.split ':'
else
    throw new Error "Specify a --template, --string, --template-string or --apply mapping."

additionalHelpers = (program.helpers?.split(',') or []).map (path) -> load path, {namespace: yes}
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

# TODO: consider a more advanced merge which also 
# goes through (objects in) arrays
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
