assert = require 'assert'
tern = require 'tern/lib/infer'

{ format_decl } = require './format'
{ gen } = require './gen'

_fake_classes = []
_fake_class_exists = ({ decl_strings }) ->
    # avoiding duplicate classes
    for cls in _fake_classes
        if cls.decl_strings.join(';') == decl_strings.join(';')
            return cls


_make_fake_class = (type) ->
    decls = ([type.props[prop].getType(false), prop] for prop in Object.keys type.props)

    decls = decls.sort (a, b) ->
        if a[1] > b[1]
            return 1
        return -1

    decl_strings = decls.map(([type, prop]) -> format_decl(type, prop))

    name = 'FakeClass_' + _fake_classes.length

    properties = decls.map((decl) -> decl[1]).sort()

    types_by_property = {}

    for prop in properties
        types_by_property[prop] = decls.filter(([type, _prop]) -> _prop == prop)[0][0]

    fake_class = { name: name, decls: decls, decl_strings: decl_strings, properties: properties, types_by_property: types_by_property }

    return fake_class


make_fake_class = (type, { assert_exists } = {}) ->
    assert type instanceof tern.Obj

    fake_class = _make_fake_class(type)
    existing = _fake_class_exists fake_class
    if existing
        return existing
    else
        if assert_exists
            assert false, 'a fake class did not exist at format time!'

    { name, decl_strings, decls } = fake_class

    constructor_signature = decl_strings.join(', ')
    constructor_initters = (
        "#{prop}(#{prop})" for [type, prop] in decls
    ).join(',')

    class_body = decl_strings.join(';\n    ')
    if decls.length
        class_body += ';'

    # TODO this is a global variable
    to_put_before.push """
        struct #{name}:public FKClass {
            #{class_body}
            #{name}(EmptyObject _){}
            #{name}(#{constructor_signature}):#{constructor_initters} {}
        };\n\n
    """

    properties = decls.map((decl) -> decl[1]).sort()

    types_by_property = {}

    for prop in properties
        types_by_property[prop] = decls.filter(([type, _prop]) -> _prop == prop)[0][0]

    fake_class = { name: name, decls: decls, decl_strings: decl_strings, properties: properties, types_by_property: types_by_property }

    type.fake_class = fake_class

    _fake_classes.push(fake_class)

    return fake_class



module.exports = { make_fake_class }

