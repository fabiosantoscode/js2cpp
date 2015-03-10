'use strict'

function stringRepeat(str, num) {
    var result = '';
    for (var i = 0; i < num; i++) {
        result += str;
    }
    return result;
}


function main() {
    console.log(stringRepeat('Beetlejuice, ', 2) + ' Beetlejuice!')
    console.log('lel', 'I said beetlejuice like', 3, 'times!')
    return 0
}

