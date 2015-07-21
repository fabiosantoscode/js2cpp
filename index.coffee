
util = require 'util'
assert = require 'assert'
tern = require 'tern/lib/infer'
escodegen = require 'escodegen'
estraverse = require 'estraverse'
es = require 'event-stream'

cpp_types = require './cpp-types'

# We'll need to generate some code. escodegen_options and RAW_C() allow us to generate raw C with escodegen.
gen = (ast) ->
    assert ast, 'No AST!'
    escodegen.generate(ast, escodegen_options)

# Annotate the AST with "func_at", "scope_at", "" properties which tell us what function a tree node belongs to
annotate = (ast) ->
    cur_fun = null
    cur_var = null
    cur_scope = tern.cx().topScope
    estraverse.traverse ast,
        enter: (node, parent) ->
            node.func_at = cur_fun
            Object.defineProperty node, 'parent',
                enumerable: false, get: () -> parent
            node.scope_at = cur_scope
            node.cur_var = cur_var
            if node.type is 'VariableDeclaration'
                cur_var = node
            if node.type is 'FunctionDeclaration' or
                    node.type is 'FunctionExpression'
                cur_fun = node
                cur_scope = node.body.scope or cur_scope
            return node
        leave: (node) ->
            if node.type is 'VariableDeclaration'
                cur_var = null
    return ast

annotate_fake_classes = (ast) ->
    estraverse.traverse ast,
        enter: (node) ->
            if node.type is 'ObjectExpression'
                make_fake_class node.kind
                return undefined
    return ast

# These types are passed by value. All the others, by reference.
simple_types = ['int', 'double']
constant_types = ['std::string']

# Flatten things which are expressions in JS, but statements in C
flatten = (ast) ->
    counter = 0
    gen_name = () -> 'flatten_' + counter++
    current_function = () -> fnstack[fnstack.length - 1]
    fnstack = []

    #put_in_top = (node) ->
    #    generated_name = name()
    #    ast.body.unshift node
    #    return { type: 'Identifier', name: generated_name }

    put_in_function = (node, {is_func, global_ok, name} = {}) ->
        insertion = node.func_at?.body
        if (not insertion) and global_ok
            insertion = ast
        generated_name = name or gen_name()
        if not is_func
            decl =
                type: "VariableDeclaration",
                kind: 'var'
                declarations: [
                    type: "VariableDeclarator",
                    id: type: "Identifier", name: generated_name
                    init: node ]
        else
            decl = node
            decl.type = 'FunctionDeclaration'
            decl.id = { type: 'Identifier', name: generated_name }
        insertion.body.unshift decl
        return { type: 'Identifier', name: generated_name }

    innermost_var = null
    estraverse.replace ast,
        leave: (node, parent) ->
            if node.type is 'VariableDeclaration'
                the_var = node
                the_func = null
                estraverse.traverse node, enter: (node, parent) ->
                    if node.type in ["FunctionExpression", "FunctionDeclaration"] and
                            parent.parent is the_var
                        assert not the_func, '(SANITY) two functions are direct children of this var statement? wtfmen'
                        the_func = node

                if the_func
                    the_func.type = 'FunctionDeclaration'
                    the_func.id = the_var.declarations[0].id

                return the_func if the_func


# Cleanup
cleanup = (ast) ->
    estraverse.replace ast, enter: (node) ->
        # Gotta remove expression statements cos they be banned in C!
        if node.type is 'ExpressionStatement' and
                node.expression.type is 'Literal'
            return estraverse.VisitorOption.Remove

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
        if node.operator in ['|=']
            name = node.left.name
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
    ArrayExpression: (node) ->
        items = ("#{gen format item}" for item in node.elements)
        RAW_C "{ #{items.join ', '} }"
    ObjectExpression: (node) ->
        if !node.properties.length
            return RAW_C 'empty_object'

        fake_class = make_fake_class node.kind

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
    type_name = type or 'undefined'

    if type instanceof tern.Fn
        ret_type = type.retval.getType()
        arg_types = type.args.map (arg) -> 'ARG_TYPE_OF'+arg
        return "#{format_type ret_type}
            (*)
            (#{arg_types.join(', ')})"
        return type.toString()

    if type instanceof tern.Obj
        return make_fake_class(type).name

    return {
        string: 'std::string'
        number: 'double'
        undefined: 'void'
    }[type_name] or assert false, "unknown type #{type_name}"


_fake_classes = []
make_fake_class = (type) ->
    assert type instanceof tern.Obj

    if type.fake_class
        return type.fake_class.name

    class_decls = ([type.props[prop].getType(false), prop] for prop in Object.keys type.props)

    class_decls = class_decls.sort (a, b) ->
        if a[1] > b[1]
            return 1
        return -1

    decl_strings = class_decls.map(([type, prop]) -> format_decl(type, prop))

    # avoiding duplicate classes
    for cls in _fake_classes
        if cls.decl_strings.join(';') == decl_strings.join(';')
            return cls

    name = 'FakeClass_' + _fake_classes.length

    class_body = decl_strings.join(';\n    ')

    if class_decls.length
        class_body += ';'

    constructor_signature = decl_strings.join(', ')
    constructor_initters = (
        "#{prop}(#{prop})" for [type, prop] in class_decls
    ).join(',')

    to_put_before.body.push RAW_C """
        struct #{name}:public FKClass {
            #{class_body}
            #{name}(EmptyObject _){}
            #{name}(#{constructor_signature}):#{constructor_initters} {}
        };\n\n
    """

    properties = class_decls.map((decl) -> decl[1]).sort()

    types_by_property = {}

    for prop in properties
        types_by_property[prop] = class_decls.filter(([type, _prop]) -> _prop == prop)[0][0]

    fake_class = { name: name, decls: class_decls, decl_strings: decl_strings, properties: properties, types_by_property: types_by_property }

    type.fake_class = fake_class

    _fake_classes.push(fake_class)

    return fake_class

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

ctx = new tern.Context

to_put_before = undefined
module.exports = (js) ->
    tern.withContext ctx, () ->
        to_put_before =
            type: 'Program'
            body: []
        ast = tern.parse js
        ast = cleanup ast
        tern.analyze ast
        annotate ast
        ast = cpp_types ast
        annotate_fake_classes ast
        pseudo_c_ast = format ast
        before_c = gen(to_put_before)
        c = gen(pseudo_c_ast)
        return before_c + c


##############
# Here be dragons.
# Below this comment lies the hack which makes escodegen output C

raw_c_sentinel = {}


RAW_C = (raw_c) ->
    type: 'Literal'
    value: raw_c_sentinel  # Escodegen will check this against the value in escodegen_fake_parser
    raw: raw_c

# Using this function we cheat escodegen into giving us raw C code when we say it is "Literal"
# This is because escodegen will parse Literals given to it, and if the raw option is set and the literal has a "raw" property, it will check the literal's "value" property against a parsed "value" property. We can pass it a fake parser that gives a dummy value which will always pass this check as long as we give it the same dummy value on the other end too.
escodegen_fake_parser = () ->
    return {
        type: 'Program',
        body: [{
            expression: {
                type: 'Literal',
                value: raw_c_sentinel  # escodegen will think I'm legit because it's comparing against the value I gave it in in RAW_C
            }
        }]
    }

##############
# Options for escodegen
# This includes the fake parser hack to make it write raw C
# And the option to always write double quotes in string constants.
escodegen_options = { parse: escodegen_fake_parser, raw: true, format: { quotes: 'double' } }
