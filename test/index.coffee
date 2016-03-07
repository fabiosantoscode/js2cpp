ok = require 'assert'
fs = require 'fs'
sh = require('child_process').execSync
js2cpp = require '..'
dumbjs = require 'dumbjs'
bindifyPrelude = require 'dumbjs/lib/bindify-prelude'

transpile = (program) ->
  fs.writeFileSync '/tmp/js2ctests.js', program
  sh 'bin/js2cpp < /tmp/js2ctests.js > /tmp/js2ctests.cpp'

output_of = (program) ->
  transpile program
  sh([
    process.env['GPP_BINARY'] or 'g++',
    '-std=c++14',
    '/tmp/js2ctests.cpp',
    '-I include/',
    '-I deps/libuv/include',
    '-L deps',
    '-lrt',
    '-lpthread',
    'deps/libuv.a',
    '-O0',
    '-o /tmp/js2ctests.out',
  ].join ' ')
  return ''+sh '/tmp/js2ctests.out'

fakeConsole = '\n' +
  '''
    var output = '';
    var console = {
      log: function() {
        output += [].slice.call(arguments)
          .map(function (s) {
            return typeof s === 'string' ?
              s :
              typeof s === 'number' ? (
                Math.floor(s) === s ? s :
                // TODO do this instead in Console::log
                String(s).split('.').length == 2 && String(s).split('.')[1].length < 6 ? (function addZero(s) { if (s.split('.')[1].length < 6) { return addZero(s + '0') } return s }(String(s))) :
                  // TODO do this autorounding instead in Console::log
                  Math.round(s * 1000000) / 1000000
              ) :
              require('util').inspect(s)
          }).join(' ') + '\\n'
      }
    };
  '''

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
    transpile("""
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

