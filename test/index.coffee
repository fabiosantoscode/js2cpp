ok = require 'assert'
fs = require 'fs'
sh = require('child_process').execSync

transpile = (program) ->
  fs.writeFileSync '/tmp/js2ctests.js', program
  sh 'bin/js2cpp < /tmp/js2ctests.js > /tmp/js2ctests.cpp'

output_of = (program) ->
  transpile program
  sh([
    'g++-4.8 -std=c++0x',
    '-I include/',
    '-O0',
    '-o /tmp/js2ctests.out',
    '/tmp/js2ctests.cpp',
  ].join ' ')
  return ''+sh '/tmp/js2ctests.out'

it 'Can run some functions', () ->
  ok.equal(
    output_of('''
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
      '''
    ),
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
    ''' + '\n'
  )



it 'regression: cannot transpile functions with arguments', () ->
    transpile("""
        function x() {
            return 6
        }

        x()
    """)

