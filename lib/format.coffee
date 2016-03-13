assert = require 'assert'
estraverse = require 'estraverse'
tern = require 'tern/lib/infer'
standard_library_objects = require('./standard-library-objects.json')
{ gen, RAW_C } = require './gen'

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
    MemberExpression: (node) ->
        [obj, prop] = [gen(format(node.object)), gen(format(node.property))]
        if obj in standard_library_objects
            return RAW_C obj + '.' + prop, { original: node }
        if node.parent.type is 'CallExpression' and
                node.parent.callee is node and
                get_type(node, false)
            if get_type(node, false) in functions_that_need_bind or get_type(node, false).original in functions_that_need_bind
                # Calling one of our functors
                return RAW_C "(*#{obj}->#{prop})", { original: node }
        if node.computed
            needs_deref = get_type(node.object) instanceof tern.Arr
            if needs_deref
                obj = "(*#{obj})"
            return RAW_C "#{obj}[#{prop}]", { original: node }
        return RAW_C obj + '->' + prop, { original: node }
    CallExpression: (node) ->
        if node.callee.type is 'NewExpression' and
                /^_flatten/.test(gen(node.callee.callee))
            return RAW_C "(*#{gen node.callee})(#{node.arguments.map(gen).join(', ')})", { original: node }
    Identifier: (node) ->
        if node.parent.type is 'CallExpression' and get_type(node, false)
            callee = node.parent.callee
            if callee.type is 'Identifier' and get_type(callee, false) in functions_that_need_bind or get_type(callee, false)?.original in functions_that_need_bind
                # Calling one of our functors again
                return RAW_C "(*#{node.parent.callee.name})", { original: node }
    Literal: (node) ->
        if node.raw[0] in ['"', "'"]
            return RAW_C "std::string(#{gen node})", { original: node }
    ArrayExpression: (node, parent) ->
        items = ("#{gen format item}" for item in node.elements)
        types = (get_type(item, false) for item in node.elements)
        array_type = types[0] or tern.ANull
        assert array_type isnt undefined, 'Creating an array of an unknown type'
        assert(types.every((type) -> type is array_type), 'array of mixed types!')
        return RAW_C "(new Array<#{ format_type array_type }>({ #{items.join(', ')} }))", { original: node }
    ObjectExpression: (node) ->
        assert !node.properties.length, 'dumbjs doesn\'t do object expression properties yet, sorry :('
        { make_fake_class } = require './fake-classes'
        fake_class = make_fake_class(get_type(node, false))
        return RAW_C "new #{fake_class.name}()", { original: node }
    VariableDeclaration: (node) ->
        assert node.declarations.length is 1
        decl = node.declarations[0]
        sides = [
            "#{format_decl get_type(node, false), decl.id.name}"]
        semicolon = ';'
        semicolon = '' if node.parent.type is 'ForStatement'
        if decl.init
            sides.push "#{gen format decl.init}"
        RAW_C((sides.join(' = ') + semicolon), { original: node })
    FunctionDeclaration: (node) ->
        return_type = format_type get_type(node, false).retval.getType(false)
        if node.id.name is 'main'
            return_type = 'int'
            return RAW_C("#{return_type} #{node.id.name}
                (#{format_params node.params})
                #{gen format node.body}", { original: node })

        params = node.params
        if /^_closure/.test(params[0]?.name)
            closure_name = params.shift()
            closure_decl = format_decl(get_type(closure_name, false), closure_name.name)
            # TODO check if functions actually need forward declarations first. Maybe.
            to_put_before.push """
                struct #{node.id.name} {
                    #{closure_decl};
                    #{node.id.name}(#{closure_decl}):_closure(_closure) { }
                    #{return_type} operator() (#{format_params params});
                };
            """
            return RAW_C("
                #{return_type} #{node.id.name}::operator() (#{format_params params}) #{gen format node.body}
            ", { original: node })
        else
            # TODO check if functions actually need forward declarations first. Maybe.
            to_put_before.push """
                 #{return_type} #{node.id.name} (#{format_params params});
            """
            return RAW_C("
                #{return_type} #{node.id.name} (#{format_params params}) #{gen format node.body}
            ", { original: node })

format_params = (params) ->
    (format_decl get_type(param, false), param.name for param in params).join ', '

# Takes a tern type and formats it as a c++ type
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
            return "Array<#{format_type arr_types}> *"
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
    assert type, 'format_decl called without a type!'
    assert name, 'format_decl called without a name!'
    return [format_type(type), name].join(' ')

# indent all but the first line by 4 spaces
indent_tail = (s) ->
    indent_arr = ([first, rest...]) -> [first].concat('    ' + line for line in rest)
    indent_arr(s.split('\n')).join('\n')

module.exports = { format_decl, formatters, format_type, format, format_params }
