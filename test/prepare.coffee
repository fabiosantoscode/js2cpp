
global.ok = require 'assert'
global.fs = require 'fs'
global.sh = require('child_process').execSync
global.js2cpp = require '../lib/index'
global.dumbjs = require 'dumbjs'
global.cli = require '../lib/cli'
global.bindifyPrelude = require 'dumbjs/lib/bindify-prelude'

global.transpile = (program, options) ->
  return fs.writeFileSync('/tmp/js2ctests.cpp', cli.sync(program, options))

global.output_of = (program, options) ->
  transpile program, options
  sh([
    process.env['GPP_BINARY'] or 'g++',
    '-std=c++14',
    '/tmp/js2ctests.cpp',
    '-I include/',
    '-lrt',
    '-lpthread',
    '-O0',
    '-g',
    '-o /tmp/js2ctests.out',
  ].join ' ')
  return ''+sh '/tmp/js2ctests.out'

global.fakeConsole = '\n' +
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
