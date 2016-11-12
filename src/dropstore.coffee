promise = Promise ? require('es6-promise').Promise
{EventEmitter} = require 'events'
ecc = require 'ecc-tools'

kad = require 'kad'
spartacus = require 'kad-spartacus'

Contact = spartacus.ContactDecorator(kad.contacts.AddressPortContact)
MemStore = require 'kad-memstore'

class Dropstore extends EventEmitter
  constructor: (@config={}) ->
    @_keypair = new spartacus.KeyPair(@config.privkey)

    @_logger = kad.Logger(@config.loglevel ? 2)
    @_contact = Contact
      address: @config.contact.address
      port: @config.contact.port
      pubkey: @_keypair.getPublicKey()
    @_transport = kad.transports.TCP @_contact, logger: @_logger

    @_transport.before('serialize', spartacus.hooks.sign(@_keypair))
    @_transport.before('receive', spartacus.hooks.verify(@_keypair))

    @_router = kad.Router
      transport: @_transport
      logger: @_logger

    @_node = new kad.Node
      transport: @_transport
      router: @_router
      logger: @_logger
      storage: MemStore()
      validator: (key, value, cb) -> cb(key == ecc.bs58check.encode(ecc.checksum(value)))

    @connect(@config.seed) if @config.seed?

  connect: (seed) -> new promise (resolve, reject) =>
    @_node.connect seed, (err) =>
      if err then reject(err)
      else resolve(@)

  disconnect: -> @_node.disconnect()

  put: (value) ->
    new Promise (resolve, reject) =>
      key = ecc.bs58check.encode(ecc.checksum(value))
      @_node.put key, value, (err) ->
        if err then reject(err)
        else resolve(key)

  get: (key) ->
    new Promise (resolve, reject) =>
      @_node.get key, (err, value) ->
        if err then reject(err)
        else resolve(value)

module.exports = Dropstore
