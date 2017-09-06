promise = Promise ? require('es6-promise').Promise
ecc = require 'ecc-tools'

AbstractNode = require './nodes/abstract'
MemoryNode = require './nodes/memory'

NodeTypes =
  abstract: AbstractNode
  memory: MemoryNode

class DeadDrop
  constructor: (@node, @options) ->
    if !(@ instanceof DeadDrop) then return new DeadDrop(@node, @options)
    if typeof(@node) is 'string' then @node = NodeTypes[@node](@options)

  document: (key, value, ttl) ->
    if value?
      doc = DeadDrop.Document(key, value, ttl)
      @_document(key, doc).then (doc) -> doc.hash
    else @_document(key).then (doc) -> doc.body()

  _document: (key, doc) ->
    key = DeadDrop.Key(key).encoded('hash')
    if doc? then @node.putDocument(doc.serialize()).then -> doc
    else
      @node.getDocument(key)
      .then (doc) -> DeadDrop.Document.from(doc)
      .then (doc) ->
        if doc.hash == key then doc else promise.reject(Error('invalid document returned'))

  lookup: (domain, zone=@config.zone) ->
      domain = domain.split('.') if typeof(domain) is 'string'
      if domain.length
        key = domain.pop()
        @_zone(zone).then (zone) =>
          if zone[key]? then @lookup(domain, zone[key])
          else promise.reject(Error('not found'))
      else
        zone = zone['.'] if typeof(zone) is 'object'
        promise.resolve zone

  _zone: (zone) ->
    if typeof(zone) is 'string' then @document(zone).then (status) -> status.zone ? {}
    else promise.resolve zone

  resolve: (domain, zone=@config.zone) ->
    @lookup(domain, zone)
    .then (key) => @document(key)
    .then (status) -> status

  address: (addr) -> @node.getAddress(addr)


DeadDrop.Key = require './key'
DeadDrop.Document = require './document'

DeadDrop.NodeTypes = NodeTypes

module.exports = DeadDrop
