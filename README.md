# Refract

Refract is a command-line utility to reshape objects to a template.

```javascript
// object
{
    "id": "5768", 
    "customer": "Stijn Debrouwere", 
    "subtotal": 200
}
// template
{
    "id": "parseInt id", 
    "uid": "dasherize customer"
    "tax": "subtotal * 0.21"
    "total": "subtotal + tax"
}
// result
{
    "id": 5768, 
    "uid": "stijn-debrouwere", 
    "tax": 42, 
    "total": 242, 
}
```

Think of it as destructuring assignment on steroids.

### Status

Mostly works, but needs some polish and some testing.

### Usage

Refract takes a template object and a data object.

...

By default, only the evaluated fields from the template object will be included in the output. Specify `--add` if you would like to merge this output with the original object. If the template should only be used to fill in missing values, instead use `--defaults`.

Refract prints to `stdout`. If you'd like to modify the original JSON file instead, use `--in-place`. For obvious reasons, this only works if a file was specified on the command line rather than piped in over `stdin`.

Refract can also iterate over an array of objects. Use the `--each` option.

### Expressions

Refract will evaluate every value in the template object as [CoffeeScript](http://coffeescript.org/) code, or if that fails, as a string with [string interpolation](http://coffeescript.org/#strings).

Renaming: 

```coffeescript
```

Math: 

```coffeescript
```

Interpolation: 

```coffeescript
```

Plain strings: 

```coffeescript
```

Arrays:

```coffeescript
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

### Helpers

Available context includes the object itself as well as numerous helper functions loaned from [underscore](http://underscorejs.org/) and [underscore.string](https://github.com/epeli/underscore.string). Please take a look at their documentation to find out which helper functions are available to you.

You can add your own helper functions. This should be a regular `.js` or `.coffee` file that can be `require`'d in node.

```shell
...
```

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

However, if you'd like _all_ fields of an object to adhere to the same standard, this can get tiresome really fast. The `--normalize` option provides a handy shortcut. You can normalize key names using any [underscore.string](https://github.com/epeli/underscore.string) function, e.g. `--normalize underscored`. The most useful ones are probably: 

* titleize
* camelize
* underscored
* dasherize
* humanize
* slugify

### Usage from node.js

...

### Roadmap

It would be kind of cool if `refract` supported CSV input, converting header names into variables, and then back into (new) headers and columns on output. Maybe someday.
