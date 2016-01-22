mongoose = require 'mongoose'
Schema = mongoose.Schema
ParticleSchema = require('./particle').schema

Snapshot = new Schema
  date: {type: Date, default: Date.now}
  particles: [ParticleSchema]

module.exports = mongoose.model 'Snapshot', Snapshot