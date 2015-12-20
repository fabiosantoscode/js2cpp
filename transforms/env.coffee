estraverse = require 'estraverse'
{ format } = require('../lib/format')
{ gen, RAW_C } = require('../lib/gen')

module.exports = (ast) ->
    estraverse.replace ast,
        leave: (node, parent) ->
            if node.type is 'AssignmentExpression' and
                    node.left.type is 'MemberExpression' and
                    node.left.object.type is 'MemberExpression' and
                    gen(node.left.object) == 'process.env'
                varname = gen format node.left.property
                if node.left.type is 'Identifier'
                    varname = "std::string(#{JSON.stringify(node.left.name)}"
                return RAW_C "process.env.setenv(#{gen format node.left.property}, #{gen format node.right})"

            # Turns process.env.FOO into process.env['FOO']
            if node.type is 'MemberExpression' and
                    node.object.type is 'MemberExpression' and
                    gen(node.object) == 'process.env' and
                    node.property.type is 'Identifier'
                return RAW_C "process.env[std::string(#{JSON.stringify node.property.name})]"
    return ast

