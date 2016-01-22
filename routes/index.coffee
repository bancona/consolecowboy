express = require 'express'
passport = require 'passport'
prettyDate = require 'pretty-date'
Account = require '../models/account'
Snapshot = require '../models/snapshot'
Particle = require '../models/particle'

router = express.Router()

# GET home page.
router.get '/', (req, res) ->
  res.render 'index',
    user: req.user
    title: 'IAP Project'
  return

router.get '/register', (req, res) ->
  res.render 'register', {}
  return

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
      return
  )
  return

router.get '/login', (req, res) ->
  res.render 'login', user: req.user
  return

router.post '/login', passport.authenticate('local'), (req, res) ->
  res.redirect '/'
  return

router.get '/logout', (req, res) ->
  req.logout()
  res.redirect '/'
  return

router.get '/snapshots', (req, res) ->
  user = req.user
  if user
  # logged in
    res.render 'snapshots', user: user, prettifyDate: prettyDate.format
  else
  #not logged in
    res.redirect '/'
  return

router.get '/snapshot', (req, res) ->
  unless req.user
    res.redirect '/'
  snapshot = (snapshot for snapshot in req.user.snapshots when snapshot._id+"" is req.query.snapshotid+"")[0]
  if snapshot
    res.render 'snapshot', user: req.user, particles: snapshot.particles
  else
    res.redirect '/'

convertToSnapshotModelInstance = (particles) ->
  particleModelInstances = new Array Object.keys(particles).length
  i = 0
  for id, particle of particles
    particleModelInstances[i] = new Particle
      x: particle[0]
      y: particle[1]
      mass: particle[2]
      vx: particle[3]
      vy: particle[4]
    i += 1
  new Snapshot particles: particleModelInstances

router.post '/takesnapshot', (req, res) ->
  if req.user
  # logged in
    snapshot = convertToSnapshotModelInstance req.body
    Account.findByIdAndUpdate(
      req.user._id,
      $push: {snapshots: snapshot},
      {safe: true, upsert: true},
      (err, model) ->
        if err
          console.log err
          res.send message: 'Snapshot Failed. Please try again'
        else
          res.send message: 'Snapshot Successful!'
        return
    )
  else
  # not logged in
    res.send message: 'Snapshot Failed. Log in and try again'
  return

module.exports = router
