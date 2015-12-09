
function inc(start) {
  return function incrementor() {
    return start++
  }
}

function demo() {
var inc0 = inc(0)

console.log(inc0())
console.log(inc0())
console.log(inc0())
}

demo()
