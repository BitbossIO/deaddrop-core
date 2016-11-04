promise = Promise ? require('es6-promise').Promise
{EventEmitter} = require 'events'

kad = require 'kad'
spartacus = require 'kad-spartacus'

Contact = spartacus.ContactDecorator(kad.contacts.AddressPortContact)
MemStore = require 'kad-memstore'

class Dropstore extends EventEmitter
  constructor: (@config={}) ->
    @_keypair = new spartacus.KeyPair(@config.contact?.privkey)

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

    @_quasar = Quasar(@_router)

    @_quasar.subscribe @_keypair.getPublicKey(), (dropHash) =>
      console.log(infoHash)

    @_node = new kad.Node
      transport: @_transport
      router: @_router
      logger: @_logger
      storage: MemStore()

  connect: (seed) -> new promise (resolve, reject) =>
    @_node.connect seed, (err) =>
      if err then reject(err)
      else resolve(@)

  disconnect: -> @_node.disconnect()

module.exports = Dropstore