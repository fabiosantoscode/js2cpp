for (var i = 99 ; i > 0 ; i--) {
  var j = i - 1;
  var icase
  var jcase
  if (i != 1) {
    icase = "bottles";
  } else {
    icase = "bottle";
  }
  if (j != 1) {
    jcase = "bottles";
  } else {
    jcase = "bottle";
  }
  console.log(String(i) + " " + icase + " of beer on the wall,");
  console.log(String(i) + " " + icase + " of beer,");
  console.log("Take 1 down, pass it around,");
  if (j != 0) {
    console.log(String(j) + " " + jcase + " of beer on the wall.");
  } else {
    console.log("No more bottles of beer on the wall!");
  }
}
