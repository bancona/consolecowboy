// Generated by CoffeeScript 1.9.3
(function() {
  var app, express, http, io, ipaddress, port;

  express = require('express');

  app = express();

  http = require('http').Server(app);

  io = require('socket.io')(http);

  process.env.DEBUG = false;

  app.set('view engine', 'jade');

  if (app.get('env' === 'development')) {
    app.locals.pretty = true;
    process.env.DEBUG = true;
  }

  app.use(express["static"]('public'));

  ipaddress = '127.0.0.1';

  port = 8080;

  http.listen(port, ipaddress, function() {
    if (process.env.DEBUG) {
      return console.log("listening on port " + port);
    }
  });

}).call(this);