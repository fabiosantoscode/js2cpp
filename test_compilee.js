'use strict'

function stringRepeat(str, num) {
    var result = '';
    for (var i = 0; i < num; i++) {
        result += str;
    }
    return result;
}

// Call fn with a random number
function withRand(fn) {
    return fn(4 /* chosen by fair dice roll. guaranteed to be random */)
}

function main() {
    console.log(stringRepeat('Beetlejuice, ', 2) + ' Beetlejuice!')
    console.log('lel', 'I said beetlejuice like', 3, 'times!')

    var object = { x: 1 }
    object.y = 6
    console.log('x', object.x, 'y', object.y)

    console.log('a func called with a random number', withRand(function(rand) {
        return rand
    }))
    return 0
}

