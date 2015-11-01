assert = require 'assert'
{ gen } = require './gen'
estraverse = require 'estraverse'
{ make_fake_class } = require './fake-classes'

# Use c++ types
# Places a "kind" property in nodes
cpp_types = (ast) ->
    type_of = (node, name) ->
        node.scope_at.hasProp(name).getType(false)

    retype_decl = (node) ->
        decl = node.declarations[0]
        if /^Function/.test decl.init.type
            node.kind = decl.init.body.scope.fnType.getType(false)
            assert node.kind, 'couldnt find a type for function' + gen node
        else
            node.kind = type_of node, decl.id.name
            assert node.kind, 'couldn\'t find a type for node' + gen node
        assert node.kind

    retype_fun = (node) ->
        node.kind = node.body.scope.fnType.getType(false)
        assert node.kind, 'Couldn\'t find a type for function ' + gen node
        for param in node.params
            param.kind = node.body.scope.hasProp(param.name).getType false
            assert param.kind, 'couldn\'t find a kind for function param ' + gen param

    estraverse.replace ast,
        enter: (node, parent) ->
            if node.type is 'VariableDeclaration'
                retype_decl node
            if node.type in ['FunctionDeclaration', 'FunctionExpression']
                retype_fun node
            if node.type is 'Identifier' && node.scope_at.hasProp(node.name)
                node.kind = type_of node, node.name
                assert node.kind, 'couldn\'t find a type for node' + gen node
            if node.type is 'ObjectExpression'
                if parent.type is 'VariableDeclarator'
                    node.kind = type_of node, parent.id.name
                    assert node.kind, 'couldn\'t find a type for variable declarator ' + gen node
                else if parent.type is 'ReturnStatement'
                    type = parent.func_at.kind.retval.getType(false)
                    class_of = make_fake_class type
                    node.kind = type
                else
                    assert false, 'object is in weird place, cannot find its kind'
            return node

module.exports = cpp_types
