require('./main.css');

var Elm = require('./Main.elm');

var redmineKey = window.localStorage.getItem('redmine');
var togglKey = window.localStorage.getItem('toggl');
redmineKey = redmineKey ? JSON.parse(redmineKey) : ''
togglKey = togglKey ? JSON.parse(togglKey) : ''
console.log({redmineKey, togglKey})
var app = Elm.Main.fullscreen({redmineKey, togglKey});

app.ports.saveKey.subscribe(function(arg) {
  var [id, key] = arg;
  window.localStorage.setItem(id, JSON.stringify(key));
})
