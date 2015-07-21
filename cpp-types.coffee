
estraverse = require 'estraverse'

# Use c++ types
# Places a "kind" property in nodes
cpp_types = (ast) ->
    type_of = (node, name) ->
        node.scope_at.hasProp(name).getType(false)

    retype_decl = (node) ->
        decl = node.declarations[0]
        if /^Function/.test decl.init.type
            node.kind = decl.init.body.scope.fnType.getType(false)
        else
            node.kind = type_of node, decl.id.name

    retype_fun = (node) ->
        node.kind = node.body.scope.fnType.getType(false)
        for param in node.params
            param.kind = node.body.scope.hasProp(param.name).getType false

    estraverse.replace ast,
        enter: (node, parent) ->
            if node.type is 'VariableDeclaration'
                retype_decl node
            if node.type in ['FunctionDeclaration', 'FunctionExpression']
                retype_fun node
            if node.type is 'Identifier' && node.scope_at.hasProp(node.name)
                node.kind = type_of node, node.name
            if node.type is 'ObjectExpression'
                node.kind = type_of node, parent.id.name
            return node

module.exports = cpp_types
