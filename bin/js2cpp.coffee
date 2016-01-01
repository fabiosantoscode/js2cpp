#!/usr/bin/env coffee

es = require 'event-stream'
js2cpp = require '../index'
fs = require 'fs'

inpt = process.stdin
if process.argv.length > 2
    inpt = fs.createReadStream process.argv[2]

# Wait for input in stdin
inpt.pipe es.wait (err, js) ->
    if err
        console.error err
        return
    cpp = js2cpp js
    process.stdout.write cpp + '\n'
