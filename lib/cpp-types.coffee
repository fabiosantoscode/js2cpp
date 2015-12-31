assert = require 'assert'
{ gen } = require './gen'
estraverse = require 'estraverse'
{ make_fake_class } = require './fake-classes'

get_fn_type = (func) ->
    scope = func.scope or func.body.scope
    fnType = scope.fnType.getType(false)
    assert fnType, 'Couldn\'t find a type for function ' + gen func
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
            assert node.kind, 'couldn\'t find a type for node' + gen node
        assert node.kind

    retype_fun = (node) ->
        node.kind = get_fn_type(node)
        assert node.kind, 'Couldn\'t find a type for function ' + gen node
        for param in node.params
            scope = node.scope or node.body.scope
            param.kind = scope.hasProp(param.name).getType false
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
                else if parent.type is 'AssignmentExpression' and
                        parent.left.type is 'MemberExpression'
                    # For declaring objects inside closures: _closure_0.someObj = {}
                    # We really need a definitive solution for getting
                    # the kind of something, short of using \.kind.
                    # Tern knows much more than we can infer with
                    # these simple cases, but I can't seem to coerce
                    # it to give me the information.
                    # halp?
                    type = parent.left.kind  # inferred in index.coffee for some reason, but can't be moved here because it must be before this runs.
                    assert type
                    make_fake_class type
                    node.kind = type
                else
                    assert false, 'object is in weird place, cannot find its kind inside a ' + parent.type
            return node

module.exports = cpp_types
