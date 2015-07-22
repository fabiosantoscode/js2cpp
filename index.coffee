
util = require 'util'
assert = require 'assert'
tern = require 'tern/lib/infer'
estraverse = require 'estraverse'
es = require 'event-stream'

{ needs_closure } = require './queries'
{ format } = require('./format')
{ gen } = require('./gen')
{ make_fake_class } = require './fake-classes'
cpp_types = require './cpp-types'

# Annotate the AST with "func_at", "scope_at", "" properties which tell us what function a tree node belongs to
annotate = (ast) ->
    fun_stack = []
    var_stack = []
    scope_stack = [tern.cx().topScope]
    cur_fun = () -> fun_stack[fun_stack.length - 1]
    cur_var = () -> var_stack[var_stack.length - 1]
    cur_scope = () -> scope_stack[scope_stack.length - 1]
    estraverse.traverse ast,
        enter: (node, parent) ->
            node.func_at = cur_fun()
            Object.defineProperty node, 'parent',
                enumerable: false, get: () -> parent
            node.scope_at = cur_scope()
            node.cur_var = cur_var()
            if node.type is 'VariableDeclaration'
                var_stack.push node
            if node.type is 'FunctionDeclaration' or
                    node.type is 'FunctionExpression'
                fun_stack.push node
                scope_stack.push(node.body.scope or cur_scope())
                node.closure = cur_scope()
            return node
        leave: (node) ->
            if node.type is 'VariableDeclaration'
                var_stack.pop()
            if node.type in ['FunctionExpression', 'FunctionDeclaration']
                fun_stack.pop()
                scope_stack.pop()
    return ast

annotate_fake_classes = (ast) ->
    estraverse.traverse ast,
        enter: (node) ->
            if node.type is 'ObjectExpression'
                make_fake_class node.kind
                return undefined
    return ast

# These types are passed by value. All the others, by reference.
simple_types = ['int', 'double']
constant_types = ['std::string']

# Flatten things which are expressions in JS, but statements in C
flatten = (ast) ->
    counter = 0
    gen_name = () -> 'flatten_' + counter++
    current_function = () -> fnstack[fnstack.length - 1]
    fnstack = []

    #put_in_top = (node) ->
    #    generated_name = name()
    #    ast.body.unshift node
    #    return { type: 'Identifier', name: generated_name }

    put_in_function = (node, {is_func, global_ok, name} = {}) ->
        insertion = node.func_at?.body
        if (not insertion) and global_ok
            insertion = ast
        generated_name = name or gen_name()
        if not is_func
            decl =
                type: "VariableDeclaration",
                kind: 'var'
                declarations: [
                    type: "VariableDeclarator",
                    id: type: "Identifier", name: generated_name
                    init: node ]
        else
            decl = node
            decl.type = 'FunctionDeclaration'
            decl.id = { type: 'Identifier', name: generated_name }
        insertion.body.unshift decl
        return { type: 'Identifier', name: generated_name }

    innermost_var = null
    estraverse.replace ast,
        leave: (node, parent) ->
            if node.type is 'VariableDeclaration'
                the_var = node
                the_func = null
                estraverse.traverse node, enter: (node, parent) ->
                    if node.type in ["FunctionExpression", "FunctionDeclaration"] and
                            parent.parent is the_var
                        assert not the_func, '(SANITY) two functions are direct children of this var statement? wtfmen'
                        the_func = node

                if the_func
                    the_func.type = 'FunctionDeclaration'
                    the_func.id = the_var.declarations[0].id

                return the_func if the_func


# Cleanup
cleanup = (ast) ->
    estraverse.replace ast, enter: (node) ->
        # Gotta remove expression statements cos they be banned in C!
        if node.type is 'ExpressionStatement' and
                node.expression.type is 'Literal'
            return estraverse.VisitorOption.Remove



ctx = new tern.Context

global.to_put_before = undefined
module.exports = (js) ->
    tern.withContext ctx, () ->
        global.to_put_before = []
        ast = tern.parse js
        ast = cleanup ast
        tern.analyze ast
        annotate ast
        ast = cpp_types ast
        annotate_fake_classes ast
        pseudo_c_ast = format ast
        before_c = (global.to_put_before.join '\n') + '\n\n'
        c = gen(pseudo_c_ast)
        return before_c + c


