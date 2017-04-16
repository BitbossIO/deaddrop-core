promise = Promise ? require('es6-promise').Promise
{EventEmitter} = require 'events'
Envelope = require 'ecc-envelope'

kad = require 'kad'
ecc = require 'ecc-tools'
levelup = require 'levelup'
memdown = require 'memdown'
quasar = require 'kad-quasar'
spartacus = require 'kad-spartacus'

class Dropnet extends EventEmitter
  constructor: (@config={}, @_store) ->
    @_db = levelup('/', { db: memdown })

    @_privateKey = @config.privkey
    @_publicKey = ecc.publicKey(@_privateKey)
    @_prv = ecc.bs58check.encode(@_privateKey)
    @_pub = ecc.bs58check.encode(@_publicKey)

    @_contact =
      address: @config.contact.address
      port: @config.contact.port

    @_node = kad
      transport: new kad.HTTPTransport()
      storage: @_db
      contact:
        address: @config.contact.address
        port: @config.contact.port

    @_node.plugin(spartacus(@_keypair))
    @_node.plugin(quasar)



    @register(@_privateKey)

    @on 'drop', (message) => console.log 'Message:', message

    @connect()

  connect: ->
    @_connection ?= new promise (resolve, reject) =>
      # @_node.on 'join', =>
        # @_logger.info("Connected to #{@_node.router.length} peers!")

      console.log 'NET PORT', @config.contact.port
      @_node.listen @config.contact.port, (err) =>
        if err then reject(err)
        else
          console.log 'NET Listening!', @config.contact.port
          if @config.seed?
            console.log 'NET SEED!', @config.seed
            @_node.join @config.seed, (err) =>
              console.log 'NET joined! err?', err
              if err then reject(err)
              else resolve(@)
          else resolve(@)

  contact: -> [@_node.identity.toString('hex'), @_node.contact]

  disconnect: -> @_node.disconnect()

  register: (privateKey) ->
    privateKey = ecc.bs58check.decode(privateKey) if typeof(privateKey) is 'string'
    publicKey = ecc.publicKey(privateKey, true)

    @_node.quasarSubscribe ecc.bs58check.encode(publicKey), (dropHash) =>
      @_store.get(dropHash)
      .then (envelope) => Envelope(decode: envelope, as: 'json').open(privateKey)
      .then (envelope) =>
        envelope.to = ecc.bs58check.encode(envelope.to) if envelope.to?
        envelope.from = ecc.bs58check.encode(envelope.from) if envelope.from?
        @emit('drop', envelope)

  drop: (key, message, topic='drop', session) ->
    key = ecc.bs58check.decode(key) if typeof(key) is 'string'
    data = { topic: topic }
    data[topic] = message
    data.session = session if session?
    Envelope(send: data, to: key, from: @_privateKey).encode('json')
    .then (envelope) => @_store.put(JSON.parse(envelope))
    .then (dropHash) => @_node.quasarPublish ecc.bs58check.encode(key), dropHash


module.exports = Dropnet
