
var queue = [ function() {} ];

queue.push(function () {
  console.log('Called first item in queue with')
})

queue.push(function () {
  console.log('Called second item in queue')
})

queue.unshift(function () {
  console.log('Called zeroth item in queue')
})

while (queue.length) {
  queue.pop()()
}

