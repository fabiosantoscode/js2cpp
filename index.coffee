
util = require 'util'
assert = require 'assert'
dumbjs = require 'dumbjs/index'
bindifyPrelude = require 'dumbjs/lib/bindify-prelude'
tern = require 'tern/lib/infer'
{ Server } = require 'tern'
estraverse = require 'estraverse'
es = require 'event-stream'

{ format } = require('./lib/format')
{ gen } = require('./lib/gen')
run_transforms = require('./transforms/index')
{ make_fake_class } = require './lib/fake-classes'
cpp_types = require './lib/cpp-types'
register_tern_plugins = require './lib/tern-plugins'

# Annotate the AST with "func_at", "scope_at", "" properties which tell us what function a tree node belongs to
annotate = (ast) ->
    fun_stack = []
    var_stack = []
    scope_stack = [tern.cx().topScope]
    cur_fun = () -> fun_stack[fun_stack.length - 1]
    cur_scope = () -> scope_stack[scope_stack.length - 1]
    unroll_member_expression_into_array = (membex) ->
        if membex.object.type is 'MemberExpression'
            res = unroll_member_expression_into_array(membex.object)
            if res is undefined
                return res
            return res.concat([membex.property])
        else if membex.object.type is 'Identifier'
            return [membex.object, membex.property]
        else
            return undefined

    member_expression_kind = (membex) ->
        identifiers = unroll_member_expression_into_array(membex)

        if identifiers is undefined
            return

        return identifiers.reduce((accum, ident) ->
            if accum is undefined
                return undefined
            prop = accum.hasProp(
                if ident.type is 'Identifier' then ident.name else '<i>'
            )?.getType(false)
            return prop or undefined
        , cur_scope())
    estraverse.traverse ast,
        enter: (node, parent) ->
            node.func_at = cur_fun()
            Object.defineProperty node, 'parent',
                enumerable: false, get: () -> parent
            node.scope_at = cur_scope()
            if node.type is 'VariableDeclaration'
                var_stack.push node
            if node.type is 'FunctionDeclaration' or
                    node.type is 'FunctionExpression'
                fun_stack.push node
                scope_stack.push(node.scope or node.body.scope or cur_scope())
                node.closure = cur_scope()

            if node.type is 'Identifier' and
                    parent isnt cur_fun() and
                    not (parent.type is 'MemberExpression' and parent.property is node)
                prop = cur_scope().hasProp(node.name)
                if prop
                    type = prop.getType(false)
                    assert type, 'Couldn\'t statically determine the type of ' + node.name
                    node.kind = type

            if node.type is 'Literal'
                if typeof node.value is 'number'
                    node.kind = tern.cx().num
                if typeof node.value is 'string'
                    node.kind = tern.cx().str

            if node.type is 'MemberExpression'
                node.kind = member_expression_kind(node)

            return node
        leave: (node) ->
            if node.type is 'VariableDeclaration'
                var_stack.pop()
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

# deal with dumbjs's bindify
bindify = (ast) ->
    current_function = null
    estraverse.replace ast, enter: (node, parent) ->
        if node.type is 'CallExpression' and node.callee.name is 'BIND'
            assert node.arguments.length is 2
            assert node.arguments[0].kind, "couldn\'t stactically determine the type of #{gen format node.arguments[0]}"
            funcType = node.arguments[0].kind
            if funcType.original
                funcType = funcType.original
            functions_that_need_bind.push(funcType)
            return {
                type: 'NewExpression',
                callee: node.arguments[0],
                arguments: node.arguments.slice(1),
                scope_at: node.scope_at,
                func_at: node.func_at,
            }

global.to_put_before = undefined
global.functions_that_need_bind = undefined
global.boundfns_ive_seen = undefined
module.exports = (js, { customDumbJs = dumbjs, options = {}, dumbJsOptions = {} } = {}) ->
    server = new Server({})
    server.loadPlugin('js2cpp', {})
    server.reset()
    ctx = server.cx
    tern.withContext ctx, () ->
        global.to_put_before = []
        global.functions_that_need_bind = []
        global.boundfns_ive_seen = []
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
        ast = tern.parse(js, {})
        ast = cleanup ast
        tern.analyze ast
        annotate ast
        ast = bindify ast
        ast = cpp_types ast
        run_transforms(ast)
        pseudo_c_ast = format ast
        before_c = """
        #include "js2c.h"
        #include <string>
        \n
        """
        before_c += (global.to_put_before.join '\n') + '\n\n'
        c = gen(pseudo_c_ast)
        return before_c + c


