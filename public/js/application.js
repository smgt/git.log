$(document).ready(function() {

  $(".message-short .btn").bind("click", function() {
    var target = $(this).parent().parent().find(".message");
    target.toggle();
    return false;
  });

});
