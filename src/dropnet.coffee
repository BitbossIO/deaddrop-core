promise = Promise ? require('es6-promise').Promise
{EventEmitter} = require 'events'
Envelope = require 'ecc-envelope'
ecc = require 'ecc-tools'

kad = require 'kad'
spartacus = require 'kad-spartacus'

Contact = spartacus.ContactDecorator(kad.contacts.AddressPortContact)
Quasar = require('kad-quasar').Protocol
MemStore = require 'kad-memstore'

class Dropnet extends EventEmitter
  constructor: (@config={}, @_store) ->
    @_keypair = new spartacus.KeyPair(@config.privkey)
    @_privateKey = new Buffer(@_keypair.getPrivateKey(), 'hex')
    @_publicKey = new Buffer(@_keypair.getPublicKey(), 'hex')
    @_priv = ecc.bs58check.encode(@_privateKey)
    @_pub = ecc.bs58check.encode(@_publicKey)

    @_logger = kad.Logger(@config.loglevel ? 2)
    @_contact = Contact
      address: @config.contact.address
      port: @config.contact.port
      pubkey: @_keypair.getPublicKey()
    @_transport = kad.transports.UDP @_contact, logger: @_logger

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

    @_quasar = Quasar(@_router)

    @register(@_privateKey)

    @on 'drop', (message) => console.log 'Message:', message

    @connect(@config.seed) if @config.seed?

  connect: (seed) -> new promise (resolve, reject) =>
    @_node.connect seed, (err) =>
      if err then reject(err)
      else resolve(@)

  disconnect: -> @_node.disconnect()

  register: (privateKey) ->
    privateKey = ecc.bs58check.decode(privateKey) if typeof(privateKey) is 'string'
    publicKey = ecc.publicKey(privateKey, true)

    @_quasar.subscribe ecc.bs58check.encode(publicKey), (dropHash) =>
      @_store.get(dropHash)
      .then (envelope) => Envelope(decode: envelope).open(privateKey)
      .then (envelope) =>
        envelope.to = ecc.bs58check.encode(envelope.to) if envelope.to?
        envelope.from = ecc.bs58check.encode(envelope.from) if envelope.from?
        @emit('drop', envelope)

  drop: (key, message) ->
    key = ecc.bs58check.decode(key) if typeof(key) is 'string'
    Envelope(send: message, to: key, from: @_privateKey).encode()
    .then (envelope) => @_store.put(envelope)
    .then (dropHash) => @_quasar.publish ecc.bs58check.encode(key), dropHash


module.exports = Dropnet
