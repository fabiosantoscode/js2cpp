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
    MemberExpression: (node) ->
        [obj, prop] = [gen(format(node.object)), gen(format(node.property))]
        if obj in standard_library_objects
            return RAW_C obj + '.' + prop
        if node.parent.type is 'CallExpression' and
                node.parent.callee is node and
                node.kind
            if node.kind in functions_that_need_bind or node.kind.original in functions_that_need_bind
                # Calling one of our functors
                return RAW_C "(*#{obj}->#{prop})"
        if node.computed
            return RAW_C "#{obj}[#{prop}]"
        return RAW_C obj + '->' + prop
    Identifier: (node) ->
        if node.parent.type is 'CallExpression' and node.kind
            if node.parent.callee.type is 'Identifier' and node.parent.callee.kind in functions_that_need_bind or node.parent.callee.kind?.original in functions_that_need_bind
                # Calling one of our functors again
                return RAW_C "(*#{node.parent.callee.name})"
    Literal: (node) ->
        if node.raw[0] in ['"', "'"]
            RAW_C "std::string(#{gen node})"
    ArrayExpression: (node, parent) ->
        items = ("#{gen format item}" for item in node.elements)
        return RAW_C "std::vector<double>({ #{items.join(', ')} })"
    ObjectExpression: (node) ->
        assert !node.properties.length, 'dumbjs doesn\'t do object expression properties yet, sorry :('
        { make_fake_class } = require './fake-classes'
        fake_class = make_fake_class(node.kind)
        return RAW_C "new #{fake_class.name}()"
    VariableDeclaration: (node) ->
        decl = node.declarations[0]
        sides = [
            "#{format_decl node.kind, decl.id.name}"]
        semicolon = ';'
        semicolon = '' if node.parent.type is 'ForStatement'
        if decl.init
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
        if /^_closure/.test(params[0]?.name)
            closure_name = params.shift()
            closure_decl = format_decl closure_name.kind, closure_name.name
            to_put_before.push """
                struct #{node.id.name} {
                    #{closure_decl};
                    #{node.id.name}(#{closure_decl}):_closure(_closure) { }
                    #{return_type} operator() (#{format_params params});
                };
            """
            return RAW_C "
                #{return_type} #{node.id.name}::operator() (#{format_params params}) #{gen format node.body}
            "
        else
            return RAW_C "
                #{return_type} #{node.id.name} (#{format_params params}) #{gen format node.body}
            "

format_params = (params) ->
    (format_decl param.kind, param.name for param in params).join ', '

# Formats a type.
# Examples: "number" -> "int", "undefined" -> "void"
format_type = (type) ->
    if type instanceof tern.Fn
        ret_type = type.retval.getType(false)
        arg_types = type.args.map((arg) -> format_type(arg.getType(false)))
        if type.isBoundFn
            if type.name not in boundfns_ive_seen
                to_put_before.push("struct #{type.name};")
                boundfns_ive_seen.push(type.name)
            return type.name + ' *'
        return "std::function<#{format_type ret_type}
            (#{arg_types.join(', ')})>"
        return type.toString()
    if type instanceof tern.Arr
        arr_types = type.props['<i>'].types
        if arr_types.length == 1
            return "std::vector<#{format_type arr_types}>"
        throw new Error 'Some array contains multiple types of variables. This requires boxed types which are not supported yet.'

    if type instanceof tern.Obj
        { make_fake_class } = require './fake-classes'
        return make_fake_class(type).name + ' *'

    type_name = type or 'undefined'

    return {
        string: 'std::string'
        number: 'double'
        undefined: 'void'
        bool: 'bool'
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
