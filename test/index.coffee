
describe 'js2cpp', () ->
  it 'Can run some functions', () ->
    javascript_code = '''
      function fib(n) {
        return n == 0 ? 0 :
          n == 1 ? 1 :
                fib(n - 1) + fib(n - 2)
      }
      function repeat(s, n) {
        var out = ''
        while (n--) out += s
        return out
      }
      function inc(n) {
        return function() {
          return n++
        }
      }
      console.log("fib(0)", fib(0))
      console.log("fib(1)", fib(1))
      console.log("fib(4)", fib(4))
      console.log("'ba' + repeat('na', 2)", 'ba' + repeat('na', 2))
      var incrementor = inc(0)
      console.log(incrementor())
      console.log(incrementor())
      console.log(incrementor())
      var x = [1,2,3]
      console.log([1,2,3], x, x[0], [1,2,3][1])
      console.log('Math.floor(Math.PI * 100) / 100:', Math.floor(Math.PI * 100) / 100)
      console.log('Math.imul(3, 2):', Math.imul(3, 2))
      console.log('Math.pow(2, 10):', Math.pow(2, 10))
      console.log('Math.log(Math.E):', Math.log(Math.E))
      console.log('Math.ceil(Math.LOG10E):', Math.ceil(Math.LOG10E))
      console.log('Math.round(0.1), Math.round(0.5), Math.round(0.6):', Math.round(0.1), Math.round(0.5), Math.round(0.6))
      console.log('Math.sin(90):', Math.sin(90))
      console.log('Math.sqrt(4):', Math.sqrt(4))
      console.log('Math.tan(45):', Math.tan(45))
      console.log('Math.trunc(2.000001):', Math.trunc(2.000001))
      console.log('Math.max(1):', Math.max(1))
      console.log('Math.max(1, 2):', Math.max(1, 2))
      console.log('Math.max(1, 2, -1):', Math.max(1, 2, -1))
      console.log('Math.max(1):', Math.max(1))
      console.log('Math.max(1, 2):', Math.max(1, 2))
      console.log('Math.max(1, 2, -1):', Math.max(1, 2, -1))
      console.log('Math.random() != Math.random()', Math.random() != Math.random())
      console.log('Math.random() <= 1 && Math.random() >= 0', Math.random() <= 1 && Math.random() >= 0)
      console.log('NaN', NaN)
      console.log('isNaN(NaN)', isNaN(NaN))
      console.log('isNaN(10)', isNaN(10))
      console.log('isNaN("10")', isNaN("10"))
      console.log('isNaN("10NaN")', isNaN("10NaN"))
      console.log('isNaN("lel")', isNaN("lel"))
      console.log('FOO=bar', process.env['FOO'] = 'bar')
      console.log('process.env[\\'FOO\\']', process.env['FOO'])
      console.log('process.env.FOO', process.env.FOO)
      function maker(start) {
        start = start + 2
        return {
          increment: function () {
            start++
          },
          getValue: function () {
            return start
          }
        }
      }
      var obj = maker(5)
      obj.increment()
      console.log('obj.getValue()', obj.getValue())
      console.log('Number(3)', Number(3))
      console.log('Number(NaN)', Number(NaN))
      console.log('Number("NaN")', Number("NaN"))
      console.log('Number("32")', Number("32"))
      console.log('Number("0x32")', Number("0x32"))
      console.log('Number("010")', Number("010"))
      console.log('String("foo")', String("foo"))
      console.log('String(10)', String(10))
      console.log('String(Math.PI)', String(Math.PI))
      console.log('String(NaN)', String(NaN))
      console.log('String(undefined)', String(undefined))
      console.log('String([1,2,3])', String([1,2,3]))

      console.log('\\n---\\n')

      var arr = [ 1 ]
      arr.push(2)
      console.log('arr.indexOf(0)', arr.indexOf(0))
      console.log('arr.indexOf(1)', arr.indexOf(1))
      console.log('arr.indexOf(2)', arr.indexOf(2))

      console.log('\\n--- typeof\\n')

      console.log('typeof "lel"', typeof "lel")
      console.log('typeof 4', typeof 4)
      console.log('typeof 0', typeof 0)
      console.log('typeof undefined', typeof undefined)
      console.log('typeof {}', typeof {})
      console.log('typeof process', typeof process)
      console.log('typeof window', typeof window)
      console.log('typeof function () {}', typeof function () {})
      console.log('typeof function () {arr;}', typeof function () {arr;})

      console.log('\\n--- Map\\n')

      var mapObj = new Map()
      var key1 = {}
      var key2 = {}
      mapObj.set(key1, 5).set(key2, 4)
      console.log('mapObj.has(key1)', mapObj.has(key1))
      console.log('mapObj.has(key2)', mapObj.has(key2))
      console.log('mapObj.has({})', mapObj.has({}))
      console.log('mapObj.get(key2)', mapObj.get(key2))

      console.log('\\n--- function equivalence\\n')

      var functions = [
        function (x) { console.log('function one got', x) },
        function (x) { console.log('function two got', x) },
      ];
      for (var i = 0; i < functions.length; i++) {
        functions[i](i + 1)
      }

      console.log('\\n--- immutable strings\\n')

      var ex = 'lel';
      var why = ex;
      why += '1';
      console.log('x, y', ex, why)
      console.log('"1".charAt(0)', "1".charAt(0))
      console.log('"1".charAt(1)', "1".charAt(1))
      console.log('"1".charAt(-1)', "1".charAt(-1))
      console.log('"".split()', "".split())
      console.log('"".split("")', "".split(""))
      console.log('"".split("a")', "".split("a"))
      console.log('"abc".split("")', "abc".split(""))
      console.log('"some thing".split(" ")', "some thing".split(" "))
      console.log('"some thing".split(" thin")', "some thing".split(" thin"))
      console.log('"some thing".split(" thing")', "some thing".split(" thing"))
      console.log('"1".split(1)', "1".split(1))
      console.log('"1 1 1".split(1, 2)', "1 1 1".split(1, 2))
      console.log('"one".concat("two")', "one".concat("two"))
      console.log('"one".concat(2)', "one".concat(2))
      console.log('"lel".substring(1)', "lel".substring(1))
      console.log('"lel".substring(1, 2)', "lel".substring(1, 2))
      console.log('"lel".substring(2, 1)', "lel".substring(2, 1))
      console.log('"lel".substr(1)', "lel".substr(1))
      console.log('"lel".substr(-1)', "lel".substr(-1))
      console.log('"lel".substr(1, 1)', "lel".substr(1, 1))
      console.log('"lel".substr(-1, 1)', "lel".substr(-1, 1))
      '''

    expected_result =
      '''
      fib(0) 0
      fib(1) 1
      fib(4) 3
      'ba' + repeat('na', 2) banana
      0
      1
      2
      [ 1, 2, 3 ] [ 1, 2, 3 ] 1 2
      Math.floor(Math.PI * 100) / 100: 3.140000
      Math.imul(3, 2): 6
      Math.pow(2, 10): 1024
      Math.log(Math.E): 1
      Math.ceil(Math.LOG10E): 1
      Math.round(0.1), Math.round(0.5), Math.round(0.6): 0 1 1
      Math.sin(90): 0.893997
      Math.sqrt(4): 2
      Math.tan(45): 1.619775
      Math.trunc(2.000001): 2
      Math.max(1): 1
      Math.max(1, 2): 2
      Math.max(1, 2, -1): 2
      Math.max(1): 1
      Math.max(1, 2): 2
      Math.max(1, 2, -1): 2
      Math.random() != Math.random() true
      Math.random() <= 1 && Math.random() >= 0 true
      NaN NaN
      isNaN(NaN) true
      isNaN(10) false
      isNaN("10") false
      isNaN("10NaN") true
      isNaN("lel") true
      FOO=bar bar
      process.env['FOO'] bar
      process.env.FOO bar
      obj.getValue() 8
      Number(3) 3
      Number(NaN) NaN
      Number("NaN") NaN
      Number("32") 32
      Number("0x32") 50
      Number("010") 10
      String("foo") foo
      String(10) 10
      String(Math.PI) 3.141592653589793
      String(NaN) NaN
      String(undefined) undefined
      String([1,2,3]) 1,2,3

      ---

      arr.indexOf(0) -1
      arr.indexOf(1) 0
      arr.indexOf(2) 1

      --- typeof

      typeof "lel" string
      typeof 4 number
      typeof 0 number
      typeof undefined undefined
      typeof {} object
      typeof process object
      typeof window undefined
      typeof function () {} function
      typeof function () {arr;} function

      --- Map

      mapObj.has(key1) true
      mapObj.has(key2) true
      mapObj.has({}) false
      mapObj.get(key2) 4

      --- function equivalence

      function one got 1
      function two got 2

      --- immutable strings

      x, y lel lel1
      "1".charAt(0) 1
      "1".charAt(1) 
      "1".charAt(-1) 
      "".split() [ '' ]
      "".split("") []
      "".split("a") [ '' ]
      "abc".split("") [ 'a', 'b', 'c' ]
      "some thing".split(" ") [ 'some', 'thing' ]
      "some thing".split(" thin") [ 'some', 'g' ]
      "some thing".split(" thing") [ 'some', '' ]
      "1".split(1) [ '', '' ]
      "1 1 1".split(1, 2) [ '', ' ' ]
      "one".concat("two") onetwo
      "one".concat(2) one2
      "lel".substring(1) el
      "lel".substring(1, 2) e
      "lel".substring(2, 1) e
      "lel".substr(1) el
      "lel".substr(-1) l
      "lel".substr(1, 1) e
      "lel".substr(-1, 1) l
      ''' + '\n'

    ok.equal(eval(
      bindifyPrelude +
      fakeConsole +
      dumbjs(javascript_code) + '\n' +
      'main()' + '\n' +
      'output'
    ),
    expected_result,
    'sanity check: javascript runs in regular eval using util.inspect to log stuff and still has expected result.')

    ok.equal(output_of(javascript_code), expected_result)

  describe 'functions that take `auto`', () ->
    it 'Can be generated', () ->
      javascript_code = """
        function x(a) {
          return typeof a
        }
        console.log(x(1));
        console.log(x("lel"));
      """

      expected_result = """
        number
        string

      """

      ok.equal(eval(
        bindifyPrelude +
        fakeConsole +
        dumbjs(javascript_code) + '\n' +
        'main()' + '\n' +
        'output'
      ),
      expected_result,
      'sanity check: javascript runs in regular eval using util.inspect to log stuff and still has expected result.')

      ok.equal(output_of(javascript_code), expected_result)

    it 'Can use closures and be called immediately', () ->
      javascript_code = """
        var prefix = '-'
        function x(a) {
          return prefix + typeof a
        }
        console.log(x(1));
        console.log(x("lel"));
      """

      expected_result = """
        -number
        -string

      """

      ok.equal(eval(
        bindifyPrelude +
        fakeConsole +
        dumbjs(javascript_code) + '\n' +
        'main()' + '\n' +
        'output'
      ),
      expected_result,
      'sanity check: javascript runs in regular eval using util.inspect to log stuff and still has expected result.')

      ok.equal(output_of(javascript_code), expected_result)

    it.skip 'TODO: Can use closures and be stored', () ->
      javascript_code = """
        var prefix = '-'
        function x(a) {
          return prefix + typeof a
        }
        var y = x;
        console.log(y(1));
        console.log(y("lel"));
      """

      expected_result = """
        -number
        -string

      """

      ok.equal(eval(
        bindifyPrelude +
        fakeConsole +
        dumbjs(javascript_code) + '\n' +
        'main()' + '\n' +
        'output'
      ),
      expected_result,
      'sanity check: javascript runs in regular eval using util.inspect to log stuff and still has expected result.')

      ok.equal(output_of(javascript_code), expected_result)

  describe 'jsdoc integration', () ->
    it 'allows you to create variables of unknown types', () ->
      javascript_code = cli.sync '/** @type {string} **/ var x;'
      ok /String x/.test(javascript_code), javascript_code

    it 'allows you to create arrays of unknown types', () ->
      javascript_code = cli.sync '/** @type {number[]} **/ var x = [];'
      ok /Array<double>/.test(javascript_code), javascript_code

  it 'can use this (lite)', () ->
    javascript_code = """
      var identity = function() { return this }
      console.log(typeof identity.call(function(){ return 6 }))
      var object = {
        foo: 6,
        method: function (bar) { return this.foo + bar },
      };
      console.log(object.method(1))
    """

    expected_result = """
      function
      7

    """

    ok.equal(eval(
      bindifyPrelude +
      fakeConsole +
      dumbjs(javascript_code) + '\n' +
      'main()' + '\n' +
      'output'
    ),
    expected_result,
    'sanity check: javascript runs in regular eval using util.inspect to log stuff and still has expected result.')

    ok.equal(output_of(javascript_code), expected_result)

  it.skip 'TODO: can use this', () ->
    javascript_code = """
      var callMe = function() { return this() }
      var identity = function() { return this }
      console.log(callMe.call(function(){ return 6 }))
      console.log([identity][0]())
      var x = { y: { zed: identity } }
      console.log(x, x.y.zed())
      var foo = function (x) {
        return this + x;
      }
      console.log(foo.call(1, 4));
      function bar() {
        return this
      }
      console.log(bar.call(50))
    """

    expected_result = """
      6
      [ [Function] ]
      { y: { zed: [Function] } } { zed: [Function] }
      5
      50

    """

    ok.equal(eval(
      bindifyPrelude +
      fakeConsole +
      dumbjs(javascript_code) + '\n' +
      'main()' + '\n' +
      'output'
    ),
    expected_result,
    'sanity check: javascript runs in regular eval using util.inspect to log stuff and still has expected result.')

    ok.equal(output_of(javascript_code), expected_result)

  it 'can transpile code that\'s been through the browserify machinery back in dumbjs', () ->
    javascript_code = """
      console.log(require(#{JSON.stringify(__dirname + '/some.js')})())
    """

    expected_result = "xfoo\n"

    ok.equal(eval(
      bindifyPrelude +
      fakeConsole +
      dumbjs(javascript_code) + '\n' +
      'main()' + '\n' +
      'output'
    ),
    expected_result,
    'sanity check: javascript runs in regular eval using util.inspect to log stuff and still has expected result.')

    ok.equal(output_of(javascript_code), expected_result)

  it 'regression: cannot transpile functions with arguments', () ->
    return cli.sync("""
      function x() {
        return 6
      }

      x()
    """)

describe 'libuv integration', () ->
  it 'calls libuv_init before code starts', () ->
    opt = undefined
    fake_dumbjs = (_, _opt) -> opt = _opt ; return ''
    js2cpp '', { customDumbJs: fake_dumbjs }
    ok.deepEqual(opt.mainify.prepend, [
      {
        type: 'ExpressionStatement',
        expression: {
          type: 'CallExpression',
          callee: {
            type: 'Identifier',
            name: 'js2cpp_init_libuv'
          },
          arguments: [],
        }
      },
      {
        type: 'ExpressionStatement',
        expression: {
          type: 'CallExpression',
          callee: {
            type: 'Identifier',
            name: 'js2cpp_init_argv'
          },
          arguments: [
            { type: 'Identifier', name: 'argc' },
            { type: 'Identifier', name: 'argv' },
          ],
        }
      }
    ])

  describe 'functional tests', () ->
    it 'timeouts', () ->
      javascript_code = '''
        process.nextTick(function() {
          console.log('two');
          clearTimeout(thatWhichShallNotBeRun);
          setTimeout(function () {
            console.log('three')
            proceed()
          }, 100)
        })

        console.log('one')

        var thatWhichShallNotBeRun = setTimeout(function () {
          console.log('fifteen!')
        })

        function proceed() {
          var count = 3;
          var interval = setInterval(function() {
            console.log(count)
            if (!--count) clearInterval(interval)
          })
        }
      '''

      expected_result = '''
      one
      two
      three
      3
      2
      1
      ''' + '\n'

      ok.equal(output_of(javascript_code), expected_result)

