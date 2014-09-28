###
These tests are nowhere near comprehensive.
Right now, they serve as a sanity check: to make 
sure I haven't accidentally broken *everything*.
###

fs = require 'fs'
{exec} = require 'child_process'
_ = require 'underscore'
should = require 'should'
refract = require '../src'

describe 'refract: module', ->
    it 'can refract an object according to a template', ->
        original =
            count: '137'
        template =
            count: 'parseInt count'
        refracted = refract template, original
        refracted.count.should.eql 137

    it 'provides easy access to underscore and underscore.string helpers', ->
        original =
            title: 'hello world'
        template =
            title: 'swapCase title'
        context = _.extend {}, original, refract.defaultHelpers
        refracted = refract template, context
        refracted.title.should.eql 'HELLO WORLD'

describe 'refract: command-line interface', ->
    it 'works on the command-line', (done) ->
        path = 'examples/simple/object.json'
        original = JSON.parse fs.readFileSync path, encoding: 'utf8'
        command = "./bin/refract #{path} \
            --template examples/simple/template.yml \
            --normalized slugify \
            --update \
            --pretty"
        exec command, (err, stdout, stderr) ->
            stdout.should.be.an.instanceOf String
            refracted = JSON.parse stdout
            refracted.calculated.total.should.eql original.Subtotal + original.Tax
            refracted.calculated.profit.should.eql refracted.calculated.total * 0.1
            done err
