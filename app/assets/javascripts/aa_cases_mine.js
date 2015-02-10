jQuery(document).ready(function() {
  bind_aa_cases_mine_to_websocket(get_websocket_client());
});

function bind_aa_cases_mine_to_websocket(ws){

  ws.bind('connection_closed', function(){
    new_dispatcher = get_websocket_client();
    bind_aa_cases_mine_to_websocket(new_dispatcher);
  });

  ws.bind('aa_cases.assigned', function(data){
    window.location.reload();
  });
};