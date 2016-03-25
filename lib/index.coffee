
util = require 'util'
yell = require './yell'
assert = require 'assert'
dumbjs = require 'dumbjs/lib/index'
tern = require 'tern/lib/infer'
ecma_script_6_tern_defs = require 'tern/defs/ecma6'

{ Server } = require 'tern'
estraverse = require 'estraverse'

{ format } = require('./format')
{ gen } = require('./gen')
run_transforms = require('./transforms/index')
{ clear_fake_classes, get_fake_classes } = require './fake-classes'
cpp_types = require './cpp-types'
register_tern_plugins = require './tern-plugins'

# Annotate the AST with "func_at", "scope_at", "" properties which tell us what function a tree node belongs to
annotate = (ast) ->
    fun_stack = []
    scope_stack = [tern.cx().topScope]
    cur_fun = () -> fun_stack[fun_stack.length - 1]
    cur_scope = () -> scope_stack[scope_stack.length - 1]

    estraverse.traverse ast,
        enter: (node, parent) ->
            Object.defineProperty node, 'parent',
                enumerable: false, get: () -> parent
            node.scope_at = cur_scope()
            if node.type is 'FunctionDeclaration' or
                    node.type is 'FunctionExpression'
                fun_stack.push node
                scope_stack.push(node.scope or node.body.scope or cur_scope())

            if node.type is 'Identifier' and
                    parent isnt cur_fun() and
                    not (parent.type is 'MemberExpression' and parent.property is node)
                prop = cur_scope().hasProp(node.name)
                if prop
                    type = prop.getType(false)
                    yell type, 'Couldn\'t statically determine the type of ' + node.name, node
                    node.kind = type

            if node.type is 'MemberExpression'
                node.kind = cpp_types.get_type(node, false)

            return node
        leave: (node) ->
            if node.type in ['FunctionExpression', 'FunctionDeclaration']
                fun_stack.pop()
                scope_stack.pop()
    return ast

# Cleanup
cleanup = (ast) ->
    estraverse.replace ast, enter: (node) ->
        # Gotta remove expression statements cos they be banned in C!
        if node.type is 'ExpressionStatement' and
                node.expression.type is 'Literal'
            return estraverse.VisitorOption.Remove

        if node.type is 'VariableDeclaration'
            assert node.declarations.length is 1
            if node.declarations[0].init?.type is 'FunctionExpression'
                return {
                    type: 'FunctionDeclaration',
                    id: node.declarations[0].id,
                    body: node.declarations[0].init.body,
                    params: node.declarations[0].init.params,
                }

register_tern_plugins()

global.to_put_before = undefined
module.exports = (js, { customDumbJs = dumbjs, options = {}, dumbJsOptions = {} } = {}) ->
    server = new Server({})
    server.loadPlugin('js2cpp', {})
    server.addDefs(ecma_script_6_tern_defs)
    server.reset()
    ctx = server.cx
    tern.withContext ctx, () ->
        global.to_put_before = []
        clear_fake_classes()
        if dumbJsOptions.mainify is undefined
            dumbJsOptions.mainify = {}
        if dumbJsOptions.mainify.prepend is undefined
            dumbJsOptions.mainify.prepend = []
        if dumbJsOptions.mainify.append is undefined
            dumbJsOptions.mainify.append = []
        dumbJsOptions.mainify.prepend.push({
            type: 'ExpressionStatement',
            expression: {
                type: 'CallExpression',
                callee: {
                    type: 'Identifier',
                    name: 'js2cpp_init_libuv'
                },
                arguments: [],
            }
        })
        dumbJsOptions.mainify.prepend.push({
            type: 'ExpressionStatement',
            expression: {
                type: 'CallExpression',
                callee: {
                    type: 'Identifier',
                    name: 'js2cpp_init_argv'
                },
                arguments: [
                    { type: 'Identifier', name: 'argc' },
                    { type: 'Identifier', name: 'argv' }
                ],
            }
        })
        dumbJsOptions.mainify.append.push({
            type: 'ExpressionStatement',
            expression: {
                type: 'CallExpression',
                callee: {
                    type: 'Identifier',
                    name: 'js2cpp_run_libuv'
                },
                arguments: [],
            }
        })
        js = customDumbJs(js, dumbJsOptions)
        ast = tern.parse(js, {
            locations: true,
        })
        global.currentFile = js
        ast = cleanup ast
        tern.analyze ast
        annotate ast
        ast = cpp_types ast
        run_transforms(ast)
        pseudo_c_ast = format ast
        before_c = """
        #include "js2c.h"
        #include <string>
        \n
        """
        before_c += get_fake_classes().map(({ name }) -> 'struct ' + name + ';').join('\n') + '\n\n'
        before_c += (global.to_put_before.join '\n') + '\n\n'
        c = gen(pseudo_c_ast)
        return before_c + c


