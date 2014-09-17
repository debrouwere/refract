// Generated by CoffeeScript 1.8.0
(function() {
  var additionalHelpers, context, fs, helpers, indentation, inputLocation, inputPath, object, program, rawInput, rawTemplate, refract, refractTemplate, refraction, serialization, template, templatePath, yaml, _, _ref;

  fs = require('fs');

  fs.path = require('path');

  _ = require('underscore');

  _.str = require('underscore.string');

  yaml = require('js-yaml');

  program = require('commander');

  refract = require('./');

  program.option('-a --add', 'Add refracted fields to the original object.').option('-d --defaults', 'Only refract a field if it is not present in the original object.').option('-e --each [key]', 'Refract each element in an array.').option('-H --helpers', 'Add in additional JavaScript helper functions.').option('-i --in-place', 'Modify the file that contains the original object.').option('-p --pretty', 'Output pretty indented JSON.').parse(process.argv);

  _ref = program.args, templatePath = _ref[0], inputPath = _ref[1];

  inputLocation = inputPath || '/dev/stdin';

  rawInput = fs.readFileSync(fs.path.resolve(inputLocation), {
    encoding: 'utf8'
  });

  object = yaml.safeLoad(rawInput);

  rawTemplate = fs.readFileSync(fs.path.resolve(templatePath), {
    encoding: 'utf8'
  });

  template = yaml.safeLoad(rawTemplate);

  if (program.helpers) {
    additionalHelpers = require(fs.path.resolve(program.helpers));
  }

  helpers = _.extend({}, additionalHelpers, refract.builtinHelpers);

  refractTemplate = _.partial(refract, template);

  if (program.each) {
    refraction = _.map(object, function(item) {
      var context;
      context = _.extend({}, item, helpers);
      return refractTemplate(context);
    });
  } else {
    context = _.extend({}, object, helpers);
    refraction = refractTemplate(context);
  }

  if (program.defaults) {
    refraction = _.defaults(object, refraction);
  } else if (program.add) {
    refraction = _.extend(object, refraction);
  }

  indentation = program.pretty ? 4 : void 0;

  serialization = JSON.stringify(refraction, void 0, indentation);

  if (program.inPlace) {
    if (!inputPath) {
      throw new Error("Cannot edit in-place on stdin.");
    }
    fs.writeFileSync(inputPath, serialization, {
      encoding: 'utf8'
    });
  } else {
    console.log(serialization);
  }

}).call(this);