assert = require 'assert'
estraverse = require 'estraverse'
tern = require 'tern/lib/infer'
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
        if !node.properties.length
            return RAW_C 'empty_object'

        { make_fake_class } = require './fake-classes'
        fake_class = make_fake_class node.kind, { assert_exists: true }

        names_initting = (prop.key.name for prop in node.properties)
        missing_names = fake_class.properties.slice()

        values_initting = {}
        for prop in node.properties
            missing_names.splice(missing_names.indexOf(prop.key.name), 1)
            values_initting[prop.key.name] = prop.value

        constructor_arguments = []

        for name in fake_class.properties
            if name in missing_names
                type = fake_class.types_by_property[name]
                if type.name is 'string'
                    constructor_arguments.push 'std::string("")'
                if type.name is 'number'
                    constructor_arguments.push '0.0'
            if name in names_initting
                constructor_arguments.push(gen values_initting[name])

        return RAW_C "#{ fake_class.name }(#{ constructor_arguments })"
    VariableDeclaration: (node) ->
        decl = node.declarations[0]
        sides = [
            "#{format_decl node.kind, decl.id.name}"]
        semicolon = ';'
        semicolon = '' if node.parent.type is 'ForStatement'
        if decl.init
            sides.push "#{gen format decl.init}#{semicolon}"
        RAW_C sides.join ' = '
    FunctionDeclaration: (node) ->
        params = format_params node.params
        return_type = format_type node.kind.retval.getType(false)
        if node.id.name is 'main' and return_type is 'double'
            return_type = 'int'
        RAW_C "#{return_type} #{node.id.name}
            (#{params})
            #{gen format node.body}"
    FunctionExpression: (node) ->
        RAW_C "[&](#{format_params node.params})
            -> #{format_type node.kind.retval.getType(false)}
            #{gen format node.body}"

format_params = (params) ->
    (format_decl param.kind, param.name for param in params).join ', '

# Formats a type.
# Examples: "number" -> "int", "undefined" -> "void"
format_type = (type) ->
    if type instanceof tern.Fn
        ret_type = type.retval.getType()
        arg_types = type.args.map (arg) -> 'ARG_TYPE_OF'+arg
        return "#{format_type ret_type}
            (*)
            (#{arg_types.join(', ')})"
        return type.toString()
    if type instanceof tern.Arr
        arr_types = type.props['<i>'].types
        if arr_types.length == 1
            return "SimpleArray<#{format_type arr_types}>"
        return "BoxArray"

    if type instanceof tern.Obj
        { make_fake_class } = require './fake-classes'
        return make_fake_class(type, { assert_exists: true }).name

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
    if type instanceof tern.Fn
        ret_type = format_type type.retval.getType(false)
        if name is 'main'
            ret_type = 'int'
        if type.args.length
            arg_decls = (
                format_decl type.args[i].getType(false), type.argNames[i] for i in [0..type.args.length-1])
        else
            arg_decls = [] 
        # Declaring a function pointer: void(*foo)(int bar)
        return "#{ret_type}(*#{name})(#{arg_decls.join(', ')})"
    else
        return "#{format_type type} #{name}" 

# indent all but the first line by 4 spaces
indent_tail = (s) ->
    indent_arr = ([first, rest...]) -> [first].concat('    ' + line for line in rest)
    indent_arr(s.split('\n')).join('\n')

module.exports = { format_decl, formatters, format_type, format, format_params }
