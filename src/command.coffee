fs = require 'fs'
fs.path = require 'path'
_ = require 'underscore'
_.str = require 'underscore.string'
_.str.identity = _.identity
yaml = require 'js-yaml'
program = require 'commander'
refract = require './'

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
    .option '-H --helpers', 
        'Add in additional JavaScript helper functions.'
    .option '-i --in-place', 
        'Modify the file that contains the original object.'
    .option '-n --normalize <style>', 
        'Normalize field names to a standard style.'
    .option '-p --pretty', 
        'Output pretty indented JSON.'
    .parse process.argv

inputPath = program.args[0]

inputLocation = inputPath or '/dev/stdin'
rawInput = fs.readFileSync (fs.path.resolve inputLocation), encoding: 'utf8'
object = yaml.safeLoad rawInput

if program.template
    rawTemplate = fs.readFileSync (fs.path.resolve program.template), encoding: 'utf8'
    template = yaml.safeLoad rawTemplate
else if program.string
    template = yaml.safeLoad program.string
else if program.apply
    template = _.object program.apply
        .split ','
        .map (instruction) ->
            instruction.split ':'
else
    throw new Error "Specify a --template, --string string or --apply mapping."

if program.helpers
    additionalHelpers = require fs.path.resolve program.helpers

helpers = _.extend {}, additionalHelpers, refract.defaultHelpers

normalizeString = _.str[program.normalize or 'identity']
normalize = (obj) ->
    if obj.constructor is Object
        _.object _.map obj, (value, key) ->
            [(normalizeString key), (normalize value)]
    else
        obj

refractTemplate = _.partial refract, template

if program.each
    refraction = _.map object, (item) ->
        context = _.extend {}, item, helpers
        refractTemplate context
else
    context = _.extend {}, object, helpers
    refraction = refractTemplate context

if program.missing
    refraction = _.defaults object, refraction
else if program.update
    refraction = _.extend object, refraction

normalizedRefraction = normalize refraction
indentation = if program.pretty then 4
serialization = JSON.stringify normalizedRefraction, undefined, indentation

if program.inPlace
    if not inputPath then throw new Error "Cannot edit in-place on stdin."
    fs.writeFileSync inputPath, serialization, encoding: 'utf8'
else
    console.log serialization
