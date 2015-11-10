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
      console.log("fib(0)", fib(0))
      console.log("fib(1)", fib(1))
      console.log("fib(4)", fib(4))
      console.log("'ba' + repeat('na', 2)", 'ba' + repeat('na', 2))
      '''
    ),
    '''
    fib(0) 0
    fib(1) 1
    fib(4) 3
    'ba' + repeat('na', 2) banana
    ''' + '\n'
  )

