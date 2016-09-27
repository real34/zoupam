require('./main.css');

var Elm = require('./Main.elm');

var app = Elm.Main.fullscreen();

app.ports.saveConfig.subscribe(function(config) {
  window.localStorage.setItem('config', JSON.stringify(config));
})

app.ports.checkStoredConfig.subscribe(function(arg) {
  var config = window.localStorage.getItem('config');
  config = config ? JSON.parse(config) : []
  app.ports.getStoredConfig.send(config);
})
