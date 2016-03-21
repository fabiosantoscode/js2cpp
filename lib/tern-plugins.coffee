assert = require 'assert'
tern = require 'tern/lib/infer'
{ registerPlugin } = require 'tern'

timerFuncDefs = {
    "setTimeout": {
        "!type": "fn(f: fn(), ms: number) -> number",
        "!url": "https://developer.mozilla.org/en/docs/DOM/window.setTimeout",
        "!doc": "Calls a function or executes a code snippet after specified delay."
    },
    "clearTimeout": {
        "!type": "fn(timeout: number)",
        "!url": "https://developer.mozilla.org/en/docs/DOM/window.clearTimeout",
        "!doc": "Clears the delay set by window.setTimeout()."
    },
    "setInterval": {
        "!type": "fn(f: fn(), ms: number) -> number",
        "!url": "https://developer.mozilla.org/en/docs/DOM/window.setInterval",
        "!doc": "Calls a function or executes a code snippet repeatedly, with a fixed time delay between each call to that function."
    },
    "clearInterval": {
        "!type": "fn(interval: number)",
        "!url": "https://developer.mozilla.org/en/docs/DOM/window.clearInterval",
        "!doc": "Cancels repeated action which was set up using setInterval."
    },
    "setImmediate": {
        "!type": "fn(f: fn()) -> number",
        "!url": "https://developer.mozilla.org/en/docs/DOM/window.setImmediate",
        "!doc": "Calls a function or executes a code snippet repeatedly, with a fixed time delay between each call to that function."
    },
    "clearImmediate": {
        "!type": "fn(interval: number)",
        "!url": "https://developer.mozilla.org/en/docs/DOM/window.clearInterval",
        "!doc": "Cancels repeated action which was set up using setInterval."
    },
}

module.exports = () ->
    registerPlugin 'js2cpp', (server) ->
        server.addDefs(timerFuncDefs)
        IsBound = tern.constraint({
            construct: (self, target) ->
                this.self = self
                this.target = target
            addType: (fn) ->
                assert fn instanceof tern.Fn
                assert fn.args.length
                boundFunctionType = new tern.Fn(fn.name, tern.ANull, fn.args.slice(1), fn.argNames.slice(1), fn.retval)
                this.target.addType(boundFunctionType)
                this.self.propagate(fn.args[0])
        })
        tern.registerFunction 'dumbjsbindfunc', (_self, args) ->
            assert args.length is 2, 'BIND called with ' + args.length + ' arguments!'
            bound_function = new tern.AVal
            args[0].propagate(new IsBound(args[1], bound_function))
            return bound_function

        server.addDefs({
            'BIND': {
                '!type': 'fn(func: fn(), closure: ?) -> !custom:dumbjsbindfunc',
            }
        })
