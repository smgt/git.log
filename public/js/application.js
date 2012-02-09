$(document).ready(function() {

  $(".message-short .btn").bind("click", function() {
    var target = $(this).closest("td").find("span.message");
    target.toggle();
    return false;
  });

});
