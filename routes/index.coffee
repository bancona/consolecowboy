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

router.post '/login', (req, res, next) ->
  passport.authenticate('local', (err, user, info) ->
    if err
      next err
    else if not user
      res.render 'login', attemptFail: true
    else
      req.login user, (err) ->
        if err
          next err
        else
          res.redirect '/'
  ) req, res, next

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
    res.render 'snapshot', user: req.user, snapshotparticles: snapshot.particles
  else
    res.redirect '/'

convertToSnapshotModelInstance = (particles) ->
  particleModelInstances = new Array particles.xs.length
  for i in [0...particles.xs.length]
    particleModelInstances[i] = new Particle
      x: particles.xs[i]
      y: particles.ys[i]
      mass: particles.masses[i]
      vx: particles.vxs[i]
      vy: particles.vys[i]

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
