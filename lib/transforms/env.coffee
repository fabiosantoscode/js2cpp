estraverse = require 'estraverse'
{ format } = require('../format')
{ gen, RAW_C } = require('../gen')

module.exports = (ast) ->
    estraverse.replace ast,
        enter: (node, parent) ->
            if node.type is 'AssignmentExpression' and
                    node.left.type is 'MemberExpression' and
                    node.left.object.type is 'MemberExpression' and
                    gen(node.left.object) == 'process.env'
                as_string = gen format node.left.property
                if node.left.property.type is 'Identifier'
                    as_string = "String(#{JSON.stringify(node.left.property.name)})"
                return RAW_C("process.env.setenv(#{as_string}, String(#{gen format node.right}))", { original: node })

            # Turns process.env.FOO into process.env['FOO']
            if node.type is 'MemberExpression' and
                    node.object.type is 'MemberExpression' and
                    gen(node.object) == 'process.env' and
                    node.property.type is 'Identifier'
                return RAW_C("process.env[String(#{JSON.stringify node.property.name})]", { original: node })
    return ast

