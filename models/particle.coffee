mongoose = require 'mongoose'
Schema = mongoose.Schema

Particle = new Schema
  x: Number
  y: Number
  vx: Number
  vy: Number
  mass: Number

module.exports = mongoose.model 'Particle', Particle