#!/usr/bin/env coffee

child_process = require 'child_process'
path = require 'path'
fs = require 'fs'

js2cpp = require './index'

cli = (inpt, outp = null, cb) ->
    read_string_or_stream(inpt)
        .then (js_code) ->
            cpp_code = js2cpp js_code
            if outp
                outp.write cpp_code + '\n'
            return cpp_code

cli.sync = (inpt, options) ->
    return js2cpp inpt, options

cli.run = (inpt, run_args) ->
    binary_path = process.cwd() + '/a.out'
    cli(inpt)
    .then (cpp_code) ->
        compile_command = process.env['GPP_BINARY'] or 'g++'

        relative = (pt) -> path.join(__dirname, '..', pt)
        args = [
            '-std=c++11',
            '-x', 'c++',  # Take an input c++ file as STDIN
            '-'
            '-x', 'none',  # And the following files aren't c++, start autodetecting pls
            '-I', relative('include/'),
            '-lrt',
            '-lpthread',
            '-o', binary_path,
        ]

        return new Promise (resolve, reject) ->
            compiler = child_process.spawn(compile_command, args)
            compiler.stderr.pipe(process.stderr)
            compiler.stdin.write(cpp_code + '\n')
            compiler.stdin.end()
            compiler.on 'exit', (status_code) ->
                compiler.stderr.unpipe(process.stderr)
                if status_code is 0
                    resolve()
                else
                    reject({ status_code })
    .then () ->
        return new Promise (resolve) ->
            if process.env['RUN_VALGRIND']
                run_args = [binary_path].concat(run_args)
                binary_path = 'valgrind'
            program = child_process.spawn(binary_path, run_args or [])
            promiseForEndedStreams = new Promise (resolve) ->
                stdoutEnded = false
                stderrEnded = false
                tryFinish = () ->
                    if stdoutEnded and stderrEnded
                        resolve()
                program.stderr.on('end', () -> stderrEnded = true; tryFinish())
                program.stdout.on('end', () -> stdoutEnded = true; tryFinish())
                program.stderr.on('error', () -> stderrEnded = true; tryFinish())
                program.stdout.on('error', () -> stdoutEnded = true; tryFinish())
            program.stderr.pipe(process.stderr)
            program.stdout.pipe(process.stdout)
            process.stdin.pipe(program.stdin)
            program.on 'exit', (status_code) ->
                try
                    fs.unlinkSync binary_path
                promiseForEndedStreams.then () ->
                    resolve({ status_code })

module.exports = cli

read_string_or_stream = (string_or_stream, cb) ->
    return new Promise (resolve, reject) ->
        if typeof string_or_stream == 'string'
            return resolve(string_or_stream)
        data = ''
        string_or_stream.on 'data', (d) ->
            data += d
        string_or_stream.on 'error', (err) ->
            reject(err)
        string_or_stream.on 'end', () ->
            resolve(data)

