jQuery(document).ready(function() {
  bind_aa_cases_notify_to_websocket(get_websocket_client());
});

function bind_aa_cases_notify_to_websocket(ws){
  var channel = ws.subscribe('aa_cases');
  channel.bind('created', function(data) {
    notify.createNotification("有新任务.", { body: "有新任务,请注意查看.", icon: "/favicon.ico" });
    // $('#new_task_in').remove();
    // $('body').append('<audio id="new_task_in" src="/assets/sounds/new_task_in.wav" autoplay="autoplay"></audio>');
  });

  ws.bind('connection_closed', function(){
    new_dispatcher = get_websocket_client();
    bind_aa_cases_notify_to_websocket(new_dispatcher);
  });
};