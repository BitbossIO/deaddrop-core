_ = require 'lodash'
promise = Promise ? require('es6-promise').Promise
io = require 'socket.io-client'

Envelope = require './envelope'

# {PrivateKey, PublicKey, Address} = bitcore

class DeadDrop
  constructor: (@config={}) ->
    @_socket = io(@config.host)

DeadDrop.envelope = Envelope

module.exports = DeadDrop
