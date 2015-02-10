jQuery(document).ready(function() {

  if (notify.permissionLevel() != notify.PERMISSION_GRANTED){
    $("#desktop_notify_setting_stats").show();
  }

  $("#allow_notify").click(function(){
    notify.requestPermission(function(){
      if (notify.permissionLevel() == notify.PERMISSION_GRANTED){
        $("#desktop_notify_setting_stats").hide();
      }
    });
  });

});