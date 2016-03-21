assert = require 'assert'
tern = require 'tern/lib/infer'

{ gen } = require './gen'

_fake_classes = []
_find_fake_lass_with_decls = (decls) ->
    # avoiding duplicate classes
    for cls in _fake_classes
        all_equal = decls.length == cls.decls.length and
            decls.every (decl, i) ->
                decl[0] is cls.decls[i][0] and decl[1] is cls.decls[i][1]
        if all_equal
            return cls

get_fake_classes = () -> Object.freeze _fake_classes

clear_fake_classes = () ->
    _fake_classes = []

_make_decls = (type) ->
    decls = ([type.props[prop].getType(false), prop] for prop in Object.keys type.props)

    decls = decls.sort (a, b) ->
        if a[1] > b[1]
            return 1
        return -1

    return decls


make_fake_class = (type, { origin_node } = {}) ->
    assert type instanceof tern.Obj

    decls = _make_decls(type)
    existing = _find_fake_lass_with_decls(decls)
    if existing
        return existing

    name = 'FakeClass_' + _fake_classes.length

    wip_fake_class = { decls, name }
    _fake_classes.push(wip_fake_class)  # Avoids infinite recursion in cases where 2 classes reference each other's names.

    # resolve dependency loop
    { format_decl } = require './format'
    decl_strings = decls.map(([type, prop]) -> format_decl(type, prop, { origin_node }))

    class_body = decl_strings.join(';\n    ')
    if decls.length
        class_body += ';'

    # TODO this is a global variable
    to_put_before.push """
        struct #{name} {
            #{class_body}
            #{name}(){}
        };\n\n
    """

    fake_class = { name: name, decls: decls }

    type.fake_class = fake_class

    _fake_classes.splice(_fake_classes.indexOf(wip_fake_class), 1)
    _fake_classes.push(fake_class)

    return fake_class



module.exports = { make_fake_class, get_fake_classes, clear_fake_classes }

