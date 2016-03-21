'use strict'

module.exports = function (condition, message, node) {
    if (condition) { return }
    var err = new Error(message)
    // TODO use deep binding for this
    if (node.loc && global.currentFile) {
        var lineText = getLine(global.currentFile, node.loc.end.line) + '\n'
        var arrow = Array(node.loc.end.column).join(' ') + '^' + '\n'
        err.stack = lineText + arrow + err.stack;
    }
    throw err;
}

function getLine(source, line) {
    return source.split(/\r?\n/g)[line]
}

