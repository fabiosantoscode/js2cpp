assert = require 'assert'
tern = require 'tern/lib/infer'

{ format_decl } = require './format'

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

    # TODO this is a global variable
    to_put_before.push """
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


module.exports = make_fake_class
