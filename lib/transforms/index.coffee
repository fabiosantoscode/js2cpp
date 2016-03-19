
module.exports = (ast) ->
    apply = (accum, func) -> func(accum)
    [
        require('./env')
    ].reduce(apply, ast)
