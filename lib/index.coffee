
util = require 'util'
assert = require 'assert'
dumbjs = require 'dumbjs/lib/index'

underscore = require 'underscore'
estraverse = require 'estraverse'

{ Server } = require 'tern'
tern = require 'tern/lib/infer'
# tern_defs_ecma5 = require 'tern/defs/ecma5'
tern_defs_ecma6 = require 'tern/defs/ecma6'
tern_add_comments = require 'tern/lib/comment'
require 'tern/plugin/doc_comment'  # adds the doc_comment plugin to tern modules

yell = require './yell'
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

            if node.type is 'Identifier' and is_variable_reference(node, parent)
                prop = cur_scope().hasProp(node.name)
                if prop and !/Function/.test(prop?.originNode?.parent?.type)
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
    dumbJsOptions = underscore.defaults(dumbJsOptions, {
        mainify: {},
        typeConversions: {},
    })

    dumbJsOptions.typeConversions = underscore.defaults(dumbJsOptions.typeConversions, {
        avoidJSAdd: true,
    })

    dumbJsOptions.mainify = underscore.defaults(dumbJsOptions.mainify, {
        prepend: [],
        append: [],
    })

    make_global_call = (name, args = []) -> {
        type: 'ExpressionStatement',
        expression: {
            type: 'CallExpression',
            callee: { type: 'Identifier', name: name },
            arguments: args.map((arg) -> { type: 'Identifier', name: arg }),
        }
    }
    dumbJsOptions.mainify.prepend.push(make_global_call('js2cpp_init_argv', [ 'argc', 'argv' ]))
    js = customDumbJs(js, dumbJsOptions)

    server = new Server({
        defs: [ tern_defs_ecma6 ],
        plugins: {
            doc_comment: { strong: true },
            js2cpp: {},
        },
    })
    # server.addDefs(tern_defs_ecma5)  TODO adding this makes everything fail. Bug?
    server.addFile('<js2cpp input>', js)
    server.reset()
    ctx = server.cx
    tern.withContext ctx, () ->
        global.to_put_before = []
        clear_fake_classes()
        file = server.findFile('<js2cpp input>')
        file.inspect = () -> '<javascript text given to tern>'  # This shows up when I log every node, so no pls.
        ast = file.ast
        global.currentFile = js
        ast = cleanup ast
        tern.analyze ast
        annotate ast
        ast = cpp_types ast
        run_transforms(ast)
        pseudo_c_ast = format ast
        before_c = """
        #include "js2c.h"
        \n
        """
        before_c += get_fake_classes().map(({ name }) -> 'struct ' + name + ';').join('\n') + '\n\n'
        before_c += (global.to_put_before.join '\n') + '\n\n'
        c = gen(pseudo_c_ast)
        return before_c + c

# stolen from dumbjs/lib/declosurify
is_variable_reference = (node, parent) ->
  assert node.type is 'Identifier'
  if /Function/.test parent.type
    # I'm the argument or name of a function
    return false
  if parent.type is 'MemberExpression'
    # Not all identifiers in MemberExpression s are variables, only when:
    return (
      parent.object is node or  # - identifier is the leftmost in the membex
      (parent.computed and parent.property is node)  # - identifier is in square brackets ( foo[x] )
    )
  # Everything else is a variable reference. Probably.
  return true

