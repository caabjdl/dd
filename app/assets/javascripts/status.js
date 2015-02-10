status_hash = {
                "在线": "ready",
                "离开": "away",
                "繁忙": "busy",
                "离线": "offline" 
              };

jQuery(document).ready(function() {
  $('#username_area').attr('class', 'status_' + status_hash[$('#online_status').html()]);
  
  window.ws = get_websocket_client()
  bind_status_to_websocket(ws);
  if ($('#online_status').html() == "离线"){
    change_status("离开", ws);
  }

  // var timer = $.timer(function() {
  //   console.debug(ws.state)
  //   if (ws.state == 'disconnected') {
  //     ws.reconnect()
  //     // bind_status_to_websocket(ws);
  //   };
  //   ws.trigger('users.heart_beat','ping');
  // });
  // timer.set({ time : 3000, autostart : true });
});

function change_status(online_status, ws){
  var status = { status: online_status }
  ws.trigger('users.change_status', status);
  // console.debug(ws.state);
  // console.debug(ws.connection_established);
  // console.debug(ws.connection_stale);
}

function bind_status_to_websocket(ws){

  ws.bind('users.status_changed', function(data) {
    $('#online_status').html(data.status);
    $('#username_area').attr('class', 'status_' + status_hash[data.status]);
  });

  ws.bind('users.offline', function(data){
    window.open('','_self','');
    window.close();
  });

  ws.bind('aa_cases.assigned', function(data){
    notify.createNotification("有新任务被分配给你.", { body: "有任务被分配给你,请注意查看.", icon: "/favicon.ico" });
    $('#new_task_assign').remove();
    $('body').append('<audio id="new_task_assign" src="/assets/sounds/new_task_assign.wav" autoplay="autoplay"></audio>');
  });

  ws.bind('connection_closed', function(){
    console.debug("CONNECTION CLOSE");
    window.ws = get_websocket_client();
    bind_status_to_websocket(window.ws);
  });

  // ws.bind('connection_error', function(){
  //   console.debug("CONNECTION ERROR");
  //   ws = get_websocket_client();
  //   bind_status_to_websocket(new_dispatcher);
  // });

  $("#online_link").click(function(){
    change_status("在线", ws);
  });

  $("#away_link").click(function(){
    change_status("离开", ws);
  });

  $("#busy_link").click(function(){
    change_status("繁忙", ws);
  });

}