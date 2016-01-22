mongoose = require 'mongoose'
Schema = mongoose.Schema
passportLocalMongoose = require 'passport-local-mongoose'
SnapshotSchema = require('./snapshot').schema

Account = new Schema
  username: String
  password: String
  snapshots: [SnapshotSchema]

Account.plugin passportLocalMongoose

module.exports = mongoose.model 'Account', Account