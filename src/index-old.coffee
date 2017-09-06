promise = Promise ? require('es6-promise').Promise

coininfo = require 'coininfo'

ecc = require 'ecc-tools'
crypto = require 'crypto'

class DeadDrop
  constructor: (@privateKey, @node) ->
    if !(@ instanceof DeadDrop) then return new DeadDrop(@privateKey, @node)

    # if typeof(@node) is 'string'

    @_publicKey = ecc.publicKey(@_privateKey, true)

    console.log 'config', @config

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
      conn.dropstore.on 'drop', @listener(cb, topic, session)
      conn

  unsubscribe: (cb, topic, session) ->
    @connection.then (conn) ->
      conn.dropstore.removeListener 'drop', @listener(cb, topic, session)
      conn

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

  _put: (key, value) -> @node.put(key, value)

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

  _get: (key, value) -> @node.get(key, value)

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

DeadDrop.ecc = ecc

DeadDrop.AbstractNode = require './nodes/abstract'
DeadDrop.MemoryNode = require './nodes/memory'
DeadDrop.RemoteNode = require './nodes/remote'

module.exports = DeadDrop
