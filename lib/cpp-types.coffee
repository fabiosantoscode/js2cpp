yell = require './yell'
assert = require 'assert'
tern = require 'tern/lib/infer'
estraverse = require 'estraverse'

get_fn_type = (func) ->
    scope = func.scope or func.body.scope
    fnType = scope.fnType.getType(false)
    yell fnType, 'Couldn\'t find a type for function', func.originNode
    return fnType

# Use c++ types
# Places a "kind" property in nodes
cpp_types = (ast) ->
    type_of = (node, name) ->
        node.scope_at.hasProp(name).getType(false)

    retype_decl = (node) ->
        decl = node.declarations[0]
        if decl.init && /^Function/.test decl.type
            node.kind = get_fn_type(node)
        else
            node.kind = type_of node, decl.id.name
        yell node.kind, 'couldn\'t find a type for node', node

    retype_fun = (node) ->
        node.kind = get_fn_type(node)
        yell node.kind, 'Couldn\'t find a type for function', node
        for param in node.params
            scope = node.scope or node.body.scope
            param.kind = scope.hasProp(param.name).getType(false) or tern.ANull
            yell param.kind, 'couldn\'t find a kind for function param', param

    estraverse.replace ast,
        enter: (node, parent) ->
            if node.type is 'VariableDeclaration'
                retype_decl node
            if node.type in ['FunctionDeclaration', 'FunctionExpression']
                retype_fun node
            return node

get_type = (node, abstract_val_ok = true) ->
    if node.kind
        # "kind" forced through a property in the object
        return node.kind
    assert node, 'pass a node to get_type!'
    assert node.scope_at, 'the node passed to get_type must have a scope!'
    type = tern.expressionType({ node: node, state: node.scope_at })
    if abstract_val_ok
        return type
    return type.getType(false)

module.exports = cpp_types
module.exports.get_type = get_type

