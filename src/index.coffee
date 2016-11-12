Dropstore = require './dropstore'
Dropnet = require './dropnet'

class DeadDrop
  constructor: (@config={}) ->
    @dropstore = new Dropstore(@config.dropstore)
    @dropnet = new Dropnet(@config.dropnet, @dropstore)

DeadDrop.Dropstore = Dropstore
DeadDrop.Dropnet = Dropnet

module.exports = DeadDrop
