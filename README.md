# Refract

[![Build Status](https://travis-ci.org/debrouwere/refract.svg)](https://travis-ci.org/debrouwere/refract)

Refract is a command-line utility to reshape objects to a template.

```javascript
// object
{
    "id": "5768", 
    "customer": "Stijn Debrouwere", 
    "subtotal": 200, 
    "handling": 10 
}
// template
{
    "id": "parseInt id", 
    "uid": "dasherize customer", 
    "tax": "subtotal * 0.21", 
    "total": "subtotal + handling + tax"
}
// result
{
    "id": 5768, 
    "uid": "stijn-debrouwere", 
    "tax": 42, 
    "total": 252
}
```

Think of it as destructuring assignment on steroids.

## Installation

Install `refract` using the [NPM](https://www.npmjs.org/) package manager which comes bundled with [node.js](http://nodejs.org/).

```shell
npm install refract-cli -g
```

This will make the `refract` command globally available on your system. You can also use the `refract-cli` module in node.js, as detailed below.

## Usage

Refract takes data and modifies it according to a template.

Templates are JSON or YAML objects containing keys and expressions. Each expression will be evaluated and the resulting object will be returned.

There are many ways to specify a template:

| option              | description                            | example
| ------------------- | -------------------------------------- | -------
| `--template`        | a path to a YAML or JSON template file | `--template template.yml`
| `--string`          | a string with interpolations           | `--string 'hello #{name}'`
| `--template-string` | a template string                      | `--template-string 'head: uppercase title'`
| `--apply`           | a list of mapping functions            | `--apply title:uppercase`

While `--template` is recommended for most purposes, `--apply` works really well for quick refractions, as do `--string` and `--template-string`. They save you the bother of needing to have a refraction template on disk.

### --template

```shell
refract order.json --template template.json
```

### --string

With `--string` you pass a simple string. Output can become dynamic by including placeholders for interpolation.

```shell
refract bio.json --string 'Hello #{name}! You are #{age - 20} years over twenty.'
```

### --template-string

With `--template-string`, you pass the actual template as a string of YAML of JSON instead of a path to a template file.

```shell
refract order.json --template-string 'total: subtotal + tax'
```

```json
{
    "total": ..., 
}
```

### --apply

Use `--apply` to apply a helper function to a field. The helper function will receive the current value of the field as its only argument.

```shell
refract order.json --apply total:parseInt,title:titleize
```

Mapping fields with `--apply` is considerably less flexible than using templates, but when all you need to do is clean up or modify a couple of fields in a straightforward way, it does the trick.

Use `--update` to keep fields that were not transformed in the output.

## Expressions

Refract will evaluate every value in the template object as [CoffeeScript](http://coffeescript.org/) code, or if that fails, as a string with [string interpolation](http://coffeescript.org/#strings). Every expression is then replaced with its result.

Variables: 

```coffeescript
book.author
```

Math: 

```coffeescript
handling + subtotal * 1.21
```

String interpolation: 

```coffeescript
Dr. #{name.first} #{name.last}
```

Plain strings: 

```coffeescript
Hello world.
```

Explicit strings:

```coffeescript
'Hello world.'
```

Arrays:

```coffeescript
[1, 2, 3]
```

Methods:

```coffeescript
participants.join ', '
```

Functions:

```coffeescript
titleize permalink
```

Because, in this limited environment, almost all valid JavaScript is also valid CoffeeScript, you can  get away with just writing expressions in JavaScript if you'd prefer: 

```javascript
{
    // CoffeeScript
    "slug": "(slugify title).toUpperCase()", 
    // JavaScript
    "slug": "slugify(title).toUpperCase();"
}
```

## Helpers

Available context includes the object itself as well as numerous helper functions loaned from [underscore](http://underscorejs.org/) and [underscore.string](https://github.com/epeli/underscore.string). Please take a look at their documentation to find out which helper functions are available to you.

Because the keys of your data object can sometimes override helpers (for example, you might have a `where` key that clashes with underscore's `where` function), underscore functions are also available under the `_` namespace, underscore.string functions under the `_.str` namespace.

```javascript
// template that calls titleize with and without namespacing
{
    "slug": "dr-livingstone-i-presume", 
    "title": "titleize slug", 
    "alternative-title": "_.str.titleize slug"
}
// resulting in two identical titles
{
    "title": "Dr Livingstone I Presume", 
    "alternative-title": "Dr Livingstone I Presume"
}
```

## Additional features

### Merging the refraction with the original object

By default, only the evaluated fields from the template object will be included in the output. Specify `--update` if you would like to merge this output with the original object. If the template should only be used to fill in missing values, instead use `--missing`.

### Editing JSON in-place

Refract prints to `stdout`. If you'd like to modify the original JSON file instead, use `--in-place`. For obvious reasons, this only works if a file was specified on the command line rather than piped in over `stdin`.

### Iterating over multiple objects

Refract can also iterate over an array of objects. Use the `--each` option.

### Normalizing keys

Renaming the fields of an object is easy: 

```javascript
// object
{
    "firstName": "Belle"
}
// template
{
    "first-name": "firstName"
}
```

However, if you'd like _all_ fields of an object to adhere to the same standard, this field-per-field approach gets cumbersome really fast. The `--normalized` option provides a handy shortcut. You can normalize key names using any [underscore.string](https://github.com/epeli/underscore.string) function, e.g. `--normalized underscored`. The most useful ones are probably: 

* titleize
* camelize
* underscored
* dasherize
* humanize
* slugify

Normalization happens before refraction, so refraction expressions should refer to variables by their new normalized names, not their original ones.

### Custom helper functions

You can add your own helper functions. This should be a regular `.js` or `.coffee` file that can be `require`'d in node.

For example, your `helpers.js` might look like:

```javascript
exports.toCelcius = function (fahrenheit) {
    return (fahrenheit - 32) * 5 / 9;
}
```

And then you can use that helper with

```shell
refract data.json \
    --apply temperature:toCelcius \
    --helpers helpers.js
```

## Usage from node.js

```javascript
var refract = require('refract-cli');

var obj = {
    count: '137'
}
var template = {
    count: 'parseInt count'
}

// refract with only JavaScript builtin functions
// like `parseInt` and `Math.max` as helpers
var newObj = refract(template, obj);

// include underscore and underscore.string
// as helpers
var _ = require('underscore');
var context = _.extend({}, obj, refract.defaultHelpers)
var newObj = refract(template, context);

// keep original fields too, not just refracted ones
_.extend(newObj, obj);
```

## Future

* It would be kind of cool if `refract` supported CSV input, converting header names into variables, and then back into (new) headers and columns on output. Maybe someday.
* It might be useful to support not just JavaScript functions as helpers, but also shell commands. (It wouldn't be terribly efficient, because you'd have to have a bunch of child processes running to manage this, but that's another matter.)
