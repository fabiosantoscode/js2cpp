yell = require './yell'
assert = require 'assert'
estraverse = require 'estraverse'
tern = require 'tern/lib/infer'
standard_library_objects = require('./standard-library-objects.json')
{ gen, RAW_C } = require './gen'
{ make_fake_class } = require './fake-classes'

# Dependency loop lol
get_type = (args...) ->
    get_type = require('./cpp-types').get_type
    return get_type(args...)

#############
# Formatting (outputing) our C++!

format = (ast) ->
    estraverse.replace ast,
        leave: (node, parent) ->
            if formatters.hasOwnProperty node.type
                formatters[node.type](node, parent)

# Some formatters
formatters =
    UnaryExpression: (node) ->
        if node.operator is 'typeof'
            arg = node.argument
            if arg.type is 'Identifier' and
                    not node.scope_at.hasProp(arg.name)
                # typical Javascript feature detection
                type_name = if arg.name not in standard_library_objects then 'undefined' else 'object'
                return RAW_C "std::string(\"#{type_name}\")
                    /* was: typeof #{arg.name}*/", { original: node }

            return RAW_C "typeof(#{gen format arg})", { original: node }
    MemberExpression: (node) ->
        [obj, prop] = [gen(format(node.object)), gen(format(node.property))]
        if obj in standard_library_objects
            return RAW_C obj + '.' + prop, { original: node }
        if node.computed
            needs_deref = get_type(node.object) instanceof tern.Arr
            if needs_deref
                obj = "(*#{obj})"
            return RAW_C "#{obj}[#{prop}]", { original: node }
        return RAW_C obj + '->' + prop, { original: node }
    CallExpression: (node) ->
        if node.callee.name is 'BIND'
            function_type = get_type(node.arguments[0], false).getFunctionType()
            args = function_type.argNames.slice(node.arguments.length - 1)
            placeholders = args
                .map((_, i) -> "std::placeholders::_#{i+1}")
                .join(', ')

            if placeholders.length
                placeholders = ', ' + placeholders

            return RAW_C "std::bind(#{
                node.arguments.map((arg) -> gen format arg).join(', ')
            }#{
                placeholders
            })", { original: node }
    NewExpression: (node, parent) ->
        type = get_type(node, false)
        if type and type.name is 'Map' and type.origin is 'ecma6'
            wrap_membex = if parent.type is 'MemberExpression' then (s) -> "(#{s})" else (s) -> s
            return RAW_C wrap_membex("new #{
                    format_type(type, { pointer_if_necessary: false, origin_node: node })
                }()"), { original: node }
    Literal: (node) ->
        if node.raw[0] in ['"', "'"]
            return RAW_C "std::string(#{gen node})", { original: node }
        if typeof node.value is 'number'
            if node.value == Math.floor(node.value)
                # All numbers are doubles. But since c++ can't tell between an int and a bool
                # the console.log representation of an "int" is "true" or "false"
                # To avoid console.log(0) yielding "true", specify the number's type here.
                return RAW_C "#{node.value}.0f", { original: node }
    ArrayExpression: (node, parent) ->
        items = ("#{gen format item}" for item in node.elements)
        types = (get_type(item, false) for item in node.elements)
        array_type = format_type(types[0] or tern.ANull, { origin_node: node })
        yell array_type isnt 'void', 'Creating an array of an unknown type', node
        yell(types.every((type, i) -> format_type(type, { origin_node: node.elements[i] }) is array_type), 'array of mixed types!', node)
        return RAW_C "(new Array<#{ array_type }>({ #{items.join(', ')} }))", { original: node }
    ObjectExpression: (node) ->
        assert !node.properties.length
        fake_class = make_fake_class(get_type(node, false))
        return RAW_C "new #{fake_class.name}()", { original: node }
    VariableDeclaration: (node) ->
        assert node.declarations.length is 1
        decl = node.declarations[0]
        sides = [
            format_decl(get_type(node, false), decl.id.name, { origin_node: node })
        ]
        semicolon = ';'
        semicolon = '' if node.parent.type is 'ForStatement'
        if decl.init
            sides.push "#{gen format decl.init}"
        RAW_C((sides.join(' = ') + semicolon), { original: node })
    FunctionDeclaration: (node) ->
        if node.id.name is 'main'
            return RAW_C("int main (int argc, char* argv[])
                #{gen format node.body}", { original: node })

        return_type = format_type(get_type(node, false).retval.getType(false), { origin_node: node })
        params = node.params

        to_put_before.push """
             #{return_type} #{node.id.name} (#{format_params params});
        """
        return RAW_C("
            #{return_type} #{node.id.name} (#{format_params params}) #{gen format node.body}
        ", { original: node })

format_params = (params) ->
    return params
        .map (param) -> format_decl(get_type(param, false), param.name, { is_param: true, origin_node: param })
        .join ', '

all_equivalent_type = (param_list) ->
    if param_list.length is 1
        return true

    type_strings = param_list.map (t) -> format_type(t)

    return type_strings.every((type) -> type is type_strings[0])

# Takes a tern type and formats it as a c++ type
format_type = (type, { pointer_if_necessary = true, is_param = false, origin_node } = {}) ->
    ptr = if pointer_if_necessary then (s) -> s + ' *' else (s) -> s
    if type instanceof tern.Fn
        ret_type = type.retval.getType(false)
        arg_types = type.args.map((arg) -> format_type(arg.getType(false), { is_param: true, origin_node }))
        return "std::function<#{format_type(ret_type, { origin_node })}
            (#{arg_types.join(', ')})>"
        return type.toString()
    if type instanceof tern.Arr
        arr_types = type.props['<i>'].types
        if all_equivalent_type arr_types.map((t) -> t.getType(false))
            return ptr "Array<#{format_type(arr_types[0].getType(false), { origin_node })}>"
        yell false, 'array contains multiple types of variables. This requires boxed types which are not supported yet.', origin_node

    if type?.origin == 'ecma6'
        assert type.name
        if type.name is 'Map'
            value_t = type.maybeProps?[':value']
            key_t = type.maybeProps?[':key']
            yell key_t and key_t.types.length isnt 0, 'Creating a map of unknown key type', origin_node
            yell key_t and value_t.types.length isnt 0, 'Creating a map of unknown value type', origin_node
            key_types_all_pointers = key_t.types.every (type) ->
                type instanceof tern.Obj and type not instanceof tern.Fn
            if not key_types_all_pointers
                yell key_t.types.length is 1, 'Creating a map of mixed key types', origin_node
            yell all_equivalent_type(value_t.types), 'Creating a map of mixed value types', origin_node
            formatted_type = if key_types_all_pointers then 'void*' else format_type(key_t.getType(false), { origin_node })
            return ptr "Map<#{formatted_type},
                #{format_type(value_t.getType(false), { origin_node })}>"
        yell false, 'Unsupported ES6 type ' + type.name, origin_node

    if type instanceof tern.Obj
        return ptr make_fake_class(type).name

    if type in [tern.ANull, null, undefined] and is_param
        return 'auto'

    type_name = type or 'undefined'

    return {
        string: 'std::string'
        number: 'double'
        undefined: 'void'
        bool: 'bool'
    }[type_name] or yell false, "unknown type #{type_name}", origin_node

# Format a decl.
# Examples: "int main", "(void)(func*)()", etc.
format_decl = (type, name, { is_param = false, origin_node } = {}) ->
    assert type, 'format_decl called without a type!'
    assert name, 'format_decl called without a name!'
    return [format_type(type, { is_param, origin_node }), name].join(' ')

# indent all but the first line by 4 spaces
indent_tail = (s) ->
    indent_arr = ([first, rest...]) -> [first].concat('    ' + line for line in rest)
    indent_arr(s.split('\n')).join('\n')

module.exports = { format_decl, formatters, format }
