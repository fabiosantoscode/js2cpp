#!/usr/bin/env coffee

js2cpp = require '../index'
fs = require 'fs'

cli = (inpt, outp = null, cb) ->
    read_string_or_stream(inpt)
        .then (js_code) ->
            cpp_code = js2cpp js_code
            if outp
                outp.write cpp_code + '\n'
            return cpp_code

cli.sync = (inpt) ->
    return js2cpp inpt

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

