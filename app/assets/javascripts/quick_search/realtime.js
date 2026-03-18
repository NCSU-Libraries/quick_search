var realtime_host = window.QuickSearchConfig.realtimeUrl;

var socket = io.connect(realtime_host);
socket.emit('subscribe', {room: 'quicksearch-' + window.QuickSearchConfig.railsEnv});

socket.on('update', function(data){
  console.log(data);
  if ('q' in data) {
    var item = '<li>' + data.q + "</li>";
    $('#realtime_searches ul').prepend(item);
  }
});
