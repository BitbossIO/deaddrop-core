promise = Promise ? require('es6-promise').Promise
{EventEmitter} = require 'events'

kad = require 'kad'
Quasar = require('kad-quasar').Protocol

Ajv = require 'ajv'
MemStore = require 'kad-memstore'
Envelope = require 'ecc-envelope'

Schemas =
  registration:
    title: "Registration Schema"
    type: "object"
    properties:
      status:
        type: "string"
        enum: ['online', 'offline']
    required: ["status"]

ajv = new Ajv()
validator = ajv.compile(Schemas.registration)

class Directory extends EventEmitter
  constructor: (@config={}) ->
    @_logger = kad.Logger(@config.loglevel ? 2)
    @_contact = kad.contacts.AddressPortContact(@config.contact)
    @_transport = kad.transports.UDP @_contact, logger: @_logger

    @_router = kad.Router
      transport: @_transport
      logger: @_logger

    @_quasar = Quasar(@_router)

    @_node = new kad.Node
      transport: @_transport
      router: @_router
      logger: @_logger
      storage: MemStore()

  connect: (seed) -> new promise (resolve, reject) =>
    @_node.connect seed, (err) ->
      if err then reject(err)
      else resolve(@)

  disconnect: -> @_node.disconnect()

  publish: (key, message) ->
    @_quasar.publish key, message

  subscribe: (key, handler) ->
    new promise (resolve, reject) =>
      resolve @_quasar.subscribe key, handler

  register: (registration, handler=->) ->
    envelope = Envelope(decode: registration)
    envelope.open().then (envelope) =>
      if validator(envelope.data)
        new promise (resolve, reject) =>
          key = Envelope.encode(envelope.from)
          @_node.put key, registration, (err) =>
            if err then reject(err)
            else
              @_quasar.subscribe key, handler
              resolve(registration)
      else promise.reject(new Error('Data does not match schema'))

  status: (key) -> new promise (resolve, reject) =>
    @_node.get key, (err, value) ->
      if err then reject(err)
      else resolve(value)

  verify: (message) ->
    envelope = Envelope(decode: message)
    envelope.verify().then (valid) =>
      if valid then promise.resolve(envelope)
      else promise.reject(new Error('Could not verify message'))

  send: (message) -> @verify(message).then (envelope) =>
    key = Envelope.encode(envelope._to.public)
    console.log 'Send Key', key, message
    @_quasar.publish(key, 'cccd6ba01d737a27444914e37bdbe448668bf487')

module.exports = Directory
