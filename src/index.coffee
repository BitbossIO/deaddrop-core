promise = Promise ? require('es6-promise').Promise

bip39 = require 'bip39'
coininfo = require 'coininfo'

ecc = require 'ecc-tools'
crypto = require 'crypto'

Dropstore = require './dropstore'
Dropnet = require './dropnet'
HDKey = require 'hdkey'

PURPOSE_CODE = 99
HARDENED_OFFSET = 0x80000000

class DeadDrop
  constructor: (@config={}) ->
    if !(@ instanceof DeadDrop) then return new DeadDrop(@config)
    if typeof(@config) is 'string'
      @path = @config
      @config = require(@path)

    console.log 'config', @config

  connect: (pin) ->
    @connection ?= DeadDrop.decrypt(@config.wallet, pin).then (mnemonic) =>
      console.log 'mnemonic', mnemonic
      throw Error('invalid Mnemonic') unless bip39.validateMnemonic(mnemonic)

      versions = coininfo('BTC')?.versions
      seed = bip39.mnemonicToSeed(mnemonic)
      rootkey = HDKey.fromMasterSeed(seed, versions.bip32)
      hdkey = rootkey.derive("m/#{PURPOSE_CODE}/0'")
      privkey = hdkey.privateKey

      @config.dropstore.privkey = privkey
      @config.dropnet.privkey = privkey

      result = { hdkey: hdkey }
      result.dropstore = new Dropstore(@config.dropstore)
      result.dropnet = new Dropnet(@config.dropnet, result.dropstore)
      result

  contact: ->
    @connection.then (conn) =>
      dropnet: conn.dropnet.contact()
      dropstore: conn.dropstore.contact()

  identity: ->
    @connection.then (conn) -> conn.dropnet._pub

  listener: (cb, topic, session) ->
    (envelope) ->
      if !topic? or topic == envelope.data.topic
        if !session? or session == envelope.data.session
          cb("#{envelope.data.topic}-drop", envelope, topic, session)
          true
        else false
      else false

  subscribe: (cb, topic, session) ->
    @connection.then (conn) =>
      conn.dropnet.on 'drop', @listener(cb, topic, session)
      conn

  unsubscribe: (cb, topic, session) ->
    @connection.then (conn) ->
      conn.dropnet.removeListener 'drop', @listener(cb, topic, session)
      conn

  drop: (key, message, topic, session) ->
    @connection.then (conn) -> conn.dropnet.drop(key, message, topic, session)

  put: (key, value, ttl) ->
    @connection.then (conn) -> conn.dropstore.put(key, value, ttl)

  get: (key) ->
    @connection.then (conn) -> conn.dropstore.get(key)

  status: (status) ->
    @connection.then (conn) -> conn.dropstore.status(status)

  lookup: (domain, zone) ->
    @connection.then (conn) -> conn.dropstore.lookup(domain, zone)

  resolve: (domain, zone) ->
    console.log 'Resolve', domain, zone
    @connection.then (conn) ->
      conn.dropstore.resolve(domain, zone)

  bind: (emitter) ->
    emitter.on 'deaddrop', (event, method, args...) =>
      switch method
        when 'ping'
          event.sender.send('deaddrop-ping', 'pong')
        when 'connect'
          @connect(args[0]).then ->
            event.sender.send('deaddrop-connected', true)
        when 'contact'
          @contact().then (contact) ->
            console.log 'deaddrop-contact', contact
            event.sender.send('deaddrop-contact', contact)
        when 'identity'
          @identity().then (identity) ->
            event.sender.send('deaddrop-identity', identity)
        when 'subscribe'
          @subscribe(((topic, envelope) -> event.sender.send(topic, envelope)), args[0], args[1])
          .then (conn) -> event.sender.send('deaddrop-subscribed', conn.dropnet._pub)
        when 'unsubscribe'
          @unsubscribe(((topic, envelope) -> event.sender.send(topic, envelope)), args[0], args[1])
          .then (conn) -> event.sender.send('deaddrop-unsubscribed', conn.dropnet._pub)
        when 'drop'
          @drop(args[0], args[1], args[2], args[3]).then -> event.sender.send("deaddrop-#{args[2]}-drop-sent", args)




DeadDrop.Dropstore = Dropstore
DeadDrop.Dropnet = Dropnet

DeadDrop.encrypt = (data, pin, alg='aes') ->
  iv = crypto.randomBytes(16)
  key = ecc.sha256(pin)
  ecc.cipher(data, key, iv, alg).then (ciphertext) =>
    iv: ecc.bs58check.encode(iv)
    alg: alg
    ciphertext: ecc.bs58check.encode(ciphertext)

DeadDrop.decrypt = (cipher, pin) ->
  key = ecc.sha256(pin)
  iv = ecc.bs58check.decode(cipher.iv)
  ciphertext = ecc.bs58check.decode(cipher.ciphertext)
  ecc.decipher(ciphertext, key, iv, cipher.alg)

DeadDrop.wallet = (pin='0000', alg='aes') ->
  mnemonic = bip39.generateMnemonic()
  DeadDrop.encrypt(mnemonic, pin, alg)

DeadDrop.ecc = ecc

module.exports = DeadDrop
