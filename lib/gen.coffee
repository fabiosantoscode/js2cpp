############
# Deal with escodegen

{ get_type } = require './cpp-types'
escodegen = require 'escodegen'
assert = require 'assert'

# We'll need to generate some code. escodegen_options and RAW_C() allow us to generate raw C with escodegen.
gen = (ast) ->
    assert ast, 'No AST!'
    escodegen.generate(ast, escodegen_options)

raw_c_sentinel = {}

get_type = (args...) ->
    get_type = require('./cpp-types').get_type
    return get_type(args...)

RAW_C = (raw_c, { original } = {}) ->
    assert original, 'call RAW_C with the original node, so as to propagate type information'
    kind = get_type original
    return {
        type: 'Literal',
        value: raw_c_sentinel,  # Escodegen will check this against the value in escode
        raw: raw_c,
        kind: kind
    }


# Using this function we cheat escodegen into giving us raw C code when we say it is "Literal"
# This is because escodegen will parse Literals given to it, and if the raw option is set and the literal has a "raw" property, it will check the literal's "value" property against a parsed "value" property. We can pass it a fake parser that gives a dummy value which will always pass this check as long as we give it the same dummy value on the other end too.
escodegen_fake_parser = () ->
    return {
        type: 'Program',
        body: [{
            expression: {
                type: 'Literal',
                value: raw_c_sentinel  # escodegen will think I'm legit because it's comparing against the value I gave it in in RAW_C
            }
        }]
    }

##############
# Options for escodegen
# This includes the fake parser hack to make it write raw C
# And the option to always write double quotes in string constants.
escodegen_options = { parse: escodegen_fake_parser, raw: true, format: { quotes: 'double' } }

module.exports = { gen, RAW_C }

