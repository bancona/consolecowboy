express = require 'express'
passport = require 'passport'
Account = require '../models/account'
router = express.Router()

# GET home page.
router.get '/', (req, res) ->
  res.render 'index',
    user: req.user
    title: 'IAP Project'

router.get '/register', (req, res) ->
  res.render 'register', {}

router.post '/register', (req, res) ->
  Account.register(
    new Account(username: req.body.username),
    req.body.password,
    (err, account) ->
      if err
        res.render 'register', account: account
      else
        passport.authenticate('local') req, res, ->
          res.redirect '/'
        null
  )

router.get '/login', (req, res) ->
  res.render 'login', user: req.user

router.post '/login', passport.authenticate('local'), (req, res) ->
  res.redirect '/'

router.get '/logout', (req, res) ->
  req.logout()
  res.redirect '/'

router.get '/ping', (req, res) ->
  res.status(200).send 'pong!'

module.exports = router
