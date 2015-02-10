jQuery(document).ready(function() {
  $("#user_login").keypress(function(e){
    if(e.which == 13){
      $("#user_password").focus();
      return false;
    }
  });

  $("#user_password").keypress(function(e){
    if(e.which == 13){
      $("#new_user").submit();
    }
  });
});