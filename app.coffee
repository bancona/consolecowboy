path = require 'path'
logger = require 'morgan'
express = require 'express'
mongoose = require 'mongoose'
passport = require 'passport'
favicon = require 'serve-favicon'
bodyParser = require 'body-parser'
cookieParser = require 'cookie-parser'
expressSession = require 'express-session'
LocalStrategy = require('passport-local').Strategy

Account = require './models/account'
routes = require './routes/index'
app = express()

io = require('socket.io')()
app.io = io

# view engine setup
app.set 'views', path.join __dirname, 'views'
app.set 'view engine', 'jade'

# uncomment after placing your favicon in /public
#app.use favicon(path.join(__dirname, 'public', 'favicon.ico'))
app.use logger 'dev'
app.use bodyParser.json limit: '50mb'
app.use bodyParser.raw limit: '50mb'
app.use bodyParser.text limit: '50mb'
app.use bodyParser.urlencoded extended: false, limit: '50mb'
app.use cookieParser()
app.use expressSession
  secret: 'mysecretthingy'
  resave: false
  saveUninitialized: false

app.use express.static path.join __dirname, 'public'

# passport config
app.use passport.initialize()
app.use passport.session()
passport.use new LocalStrategy Account.authenticate()
passport.serializeUser Account.serializeUser()
passport.deserializeUser Account.deserializeUser()

# mongoose
dburl = process.env.dburl ? require './dburl'
mongoose.connect dburl

app.use '/', routes

# catch 404 and forward to error handler
app.use (req, res, next) ->
  err = new Error 'Not Found'
  err.status = 404
  next err

# error handlers

# development error handler
# will print stacktrace
if app.get('env') is 'development'
  app.use (err, req, res, next) ->
    res.status err.status || 500
    res.render 'error',
      message: err.message
      error: err

# production error handler
# no stacktraces leaked to user
app.use (err, req, res, next) ->
  res.status err.status || 500
  res.render 'error',
    message: err.message
    error: {}

module.exports = app
