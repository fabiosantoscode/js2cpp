
process.nextTick(function() {
  console.log('two');
  clearTimeout(thatWhichShallNotBeRun);
  clearImmediate(thatWhichShallNotBeRun2);
  setTimeout(function () {
    console.log('three')
    proceed()
  }, 500)
})

console.log('one')

var thatWhichShallNotBeRun = setTimeout(function () {
  console.log('fifteen!')
});
var thatWhichShallNotBeRun2 = setImmediate(function () {
  console.log('fifteen!')
});

function proceed() {
  var count = 3;
  var interval = setInterval(function() {
    console.log(count)
    if (!--count) clearInterval(interval)
  }, 1000)
  console.log('counting down using interval number', interval)
}

