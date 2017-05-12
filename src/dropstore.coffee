promise = Promise ? require('es6-promise').Promise
{EventEmitter} = require 'events'
Envelope = require 'ecc-envelope'

kad = require 'kad'
ecc = require 'ecc-tools'
bunyan = require 'bunyan'
levelup = require 'levelup'
memdown = require 'memdown'
quasar = require 'kad-quasar'
traverse = require 'kad-traverse'
spartacus = require 'kad-spartacus'

util = {
  encodeKey: (key) ->
    key = ecc.decode(key) if typeof(key) is 'string'
    return false unless key.length == 32 || key.length == 33
    result = ecc.rmd160(key)
    result[19] = (result[19] & 254) + (util.isMutable(key) + 0)
    result

  isMutable: (key) ->
    key = ecc.decode(key) if typeof(key) is 'string'
    if key.length == 20 then !!(key[19] & 1)
    else if key.length == 33 then true
    else false
}

class Dropstore extends EventEmitter
  constructor: (@config={}) ->
    @_db = levelup('/', { db: memdown })

    @_privateKey = @config.privkey
    @_publicKey = ecc.publicKey(@_privateKey, true)
    @_prv = ecc.encode(@_privateKey)
    @_pub = ecc.encode(@_publicKey)

    @_node = kad
      transport: new kad.HTTPTransport()
      storage: @_db
      contact: @config.contact
      logger: bunyan.createLogger({ name: 'deaddrop' });

    @_node.plugin(spartacus(@_privateKey))
    @_node.plugin(traverse([
      # new traverse.UPNPStrategy(),
      # new traverse.NATPMPStrategy(),
      new traverse.ReverseTunnelStrategy({remoteAddress: 'darkweb.io'})
    ]))
    @_node.plugin(quasar)

    @_node.use 'STORE', (request, response, next) =>
      [key, val] = request.params
      console.log 'STORE', key, val
      key = Buffer(key, 'hex')
      # console.log 'Request', request
      if util.isMutable(key)
        console.log 'store mutable'
      else
        hash = util.encodeKey(ecc.checksum(val.value))
        console.log 'store immutable', key, hash
      #   return next(new Error('Key must be the RMD-160 hash of value'))

      next()

    @register(@_privateKey)

    @on 'drop', (message) => console.log 'Message:', message

    @connect()


  connect: ->
    @_connection ?= new promise (resolve, reject) =>
      # @_node.on 'join', =>
        # @_logger.info("Connected to #{@_node.router.length} peers!")

      console.log 'PORT', @config.contact.port
      @_node.listen @config.contact.port, (err) =>
        if err then reject(err)
        else
          console.log 'Listening!', @config.contact.port
          if @config.seed?
            console.log 'SEED!', @config.seed
            @_node.join @config.seed, (err) =>
              console.log 'joined! err?', err
              if err then reject(err)
              else resolve(@)
          else resolve(@)

  contact: -> [@_node.identity.toString('hex'), @_node.contact]

  register: (privateKey) ->
    privateKey = ecc.bs58check.decode(privateKey) if typeof(privateKey) is 'string'
    publicKey = ecc.publicKey(privateKey, true)

    @_node.quasarSubscribe ecc.bs58check.encode(publicKey), (dropHash) =>
      @get(dropHash)
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
    .then (envelope) => @put(JSON.parse(envelope))
    .then (dropHash) => @_node.quasarPublish ecc.bs58check.encode(key), dropHash

  put: (key, value, ttl=3600) ->
    console.log 'Put'
    if value?
      console.log 'mutable'
      key = ecc.decode(key) if typeof(key) is 'string'
      data = {
        headers: {
          timestamp: Date.now(),
          ttl: ttl
        },
        body: value
      }
      Envelope(send: data, from: key).encode('json').then (envelope) =>
        key = ecc.encode(ecc.publicKey(key, true))
        envelope = JSON.parse(envelope)
        console.log 'put encoded envelope', envelope
        @_put key, envelope
    else
      value = key
      key = ecc.encode(ecc.checksum(value))
      console.log 'immutable', key, value
      @_put key, value

  _put: (key, value) ->
    new Promise (resolve, reject) =>
      @_node.iterativeStore util.encodeKey(key).toString('hex'), value, (err, stored) ->
        console.log 'Stored', stored
        if err then reject(err)
        else resolve(key)

  get: (key) ->
    console.log 'Get', key
    @_get(key).then (item) ->
      if util.isMutable(key)
        console.log 'mutable', key, item
        Envelope(decode: item.value, as: 'json').open()
        .then (envelope) => envelope?.data?.body
      else
        console.log 'immutable', key, item
        item.value

  _get: (key) ->
    new Promise (resolve, reject) =>
      if key = util.encodeKey(key)
        @_node.storage.get key.toString('hex'), { valueEncoding: 'json' }, (err, item) =>
          if err?.notFound?
            @_node.iterativeFindValue key.toString('hex'), (err, item) ->
              if err then reject(err)
              else if Array.isArray(item) then reject('item not found')
              else resolve(item)
          else if err? then reject(err)
          else resolve(item)
      else reject('invalid key length should be 32 or 33 bytes')

  status: (status, ttl) ->
    if status? then @put(@_privateKey, status, ttl)
    else @get(@_publicKey)

  lookup: (domain, zone=@config.zone) ->
      domain = domain.split('.') if typeof(domain) is 'string'
      if domain.length
        key = domain.pop()
        console.log 'lookup', domain, key
        @_zone(zone)
        .then (zone) =>
          if zone[key]? then @lookup(domain, zone[key])
          else Promise.reject('not found')
      else
        zone = zone['.'] if typeof(zone) is 'object'
        console.log 'lookup found', domain, zone
        Promise.resolve zone

  _zone: (zone) ->
    if typeof(zone) is 'string'
      console.log 'ZONE', zone
      @get(zone).then (status) -> status.zone ? {}
    else Promise.resolve zone

  resolve: (domain, zone=@config.zone) ->
    @lookup(domain, zone)
    .then (key) => @get(key)
    .then (status) -> status?.host


Dropstore.util = util

module.exports = Dropstore
