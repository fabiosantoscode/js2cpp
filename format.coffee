assert = require 'assert'
estraverse = require 'estraverse'
tern = require 'tern/lib/infer'
standard_library_objects = require('./standard-library-objects.json')
{ gen, RAW_C } = require './gen'

#############
# Formatting (outputing) our C++!

format = (ast) ->
    estraverse.replace ast,
        leave: (node, parent) ->
            if formatters.hasOwnProperty node.type
                formatters[node.type](node, parent)

# Some formatters
formatters =
    AssignmentExpression: (node) ->
        left = node.left
        if left.type is 'MemberExpression' and node.scope_at.hasProp(left.object.name) and
                left.computed and typeof left.property.value is 'number' and
                left.object.kind instanceof tern.Arr
            # array member assignment.
            return RAW_C "#{ gen format node.left.object }" +
                ".subscript_assign(" +
                "#{ gen format node.left.property }, " +
                "#{ gen format node.right})"

        if node.operator in ['|=']
            name = left.name
            shorter_op = node.operator[0]  # For example, &= becomes &
            return RAW_C "(#{name} = (int)
                #{name} #{shorter_op} #{gen format node.right})"
    MemberExpression: (node) ->
        [obj, prop] = [gen(format(node.object)), gen(format(node.property))]
        if obj in standard_library_objects
            return RAW_C obj + '.' + prop
        if node.parent.type is 'CallExpression' and node.parent.callee is node
            # We're surely calling a function pointer.
            # TODO Standard library objects' functions aren't pointers yet so wtf should we do?
            return RAW_C "(*#{obj}->#{prop})"
        return RAW_C obj + '->' + prop
    Literal: (node) ->
        if node.raw[0] in ['"', "'"]
            RAW_C "std::string(#{gen node})"
    BinaryExpression: (node) ->
        if node.operator in ['&']
            node.left = RAW_C "((int) #{gen format node.left})"
            return node
    ArrayExpression: (node, parent) ->
        items = ("#{gen format item}" for item in node.elements)

        if node.parent.parent.type == 'VariableDeclaration'
            arr_types = node.parent.parent.kind.props['<i>'].types
            if arr_types.length == 1
                return RAW_C "array_from_items<#{format_type arr_types[0]}>(#{items.join ', '})"
            else
                assert false, 'this array contains more than one type!'
        else
            assert false, 'don\'t know what types this array contains!'
    ObjectExpression: (node) ->
        assert !node.properties.length, 'dumbjs doesn\'t know how to remove properties from an object? sorry :('
        return RAW_C 'empty_object'
    VariableDeclaration: (node) ->
        decl = node.declarations[0]
        sides = [
            "#{format_decl node.kind, decl.id.name}"]
        semicolon = ';'
        semicolon = '' if node.parent.type is 'ForStatement'
        if decl.init
            if node.kind instanceof tern.Obj
                { make_fake_class } = require './fake-classes'
                fake_class = make_fake_class(node.kind)
                sides.push "new #{fake_class.name}()"
            else
                sides.push "#{gen format decl.init}"
        RAW_C(sides.join(' = ') + semicolon)
    FunctionDeclaration: (node) ->
        return_type = format_type node.kind.retval.getType(false)
        if node.id.name is 'main'
            return_type = 'int'
            return RAW_C "#{return_type} #{node.id.name}
                (#{format_params node.params})
                #{gen format node.body}"

        params = node.params
        closure_name = params.shift()
        closure_decl = format_decl closure_name.kind, closure_name.name
        RAW_C """
            struct #{node.id.name} {
                #{closure_decl};
                #{node.id.name}(#{closure_decl}):_closure(_closure) { }
                #{return_type} operator() (#{format_params params}) #{indent_tail gen format node.body}
            };
        """

format_params = (params) ->
    (format_decl param.kind, param.name for param in params).join ', '

boundfns_ive_seen = []
# Formats a type.
# Examples: "number" -> "int", "undefined" -> "void"
format_type = (type) ->
    if type instanceof tern.Fn
        ret_type = type.retval.getType(false)
        arg_types = type.args.map((arg) -> format_type(arg.getType(false)))
        if /^boundFn\(/.test(type.name)
            functorName = type.name.replace(/^boundFn\((.*?)\)$/, '$1')
            if functorName not in boundfns_ive_seen
                to_put_before.push("struct #{functorName};")
                boundfns_ive_seen.push(functorName)
            return functorName + ' *'
        return "std::function<#{format_type ret_type}
            (#{arg_types.join(', ')})>"
        return type.toString()
    if type instanceof tern.Arr
        arr_types = type.props['<i>'].types
        if arr_types.length == 1
            return "SimpleArray<#{format_type arr_types}>"
        return "BoxArray"

    if type instanceof tern.Obj
        { make_fake_class } = require './fake-classes'
        return make_fake_class(type).name + ' *'

    type_name = type or 'undefined'

    return {
        string: 'std::string'
        number: 'double'
        undefined: 'void'
    }[type_name] or assert false, "unknown type #{type_name}"

# Format a decl.
# Examples: "int main", "(void)(func*)()", etc.
format_decl = (type, name) ->
    assert name, 'format_decl called without a name!'
    return [format_type(type), name].join(' ')

# indent all but the first line by 4 spaces
indent_tail = (s) ->
    indent_arr = ([first, rest...]) -> [first].concat('    ' + line for line in rest)
    indent_arr(s.split('\n')).join('\n')

module.exports = { format_decl, formatters, format_type, format, format_params }
