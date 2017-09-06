promise = Promise ? require('es6-promise').Promise

Envelope = require 'ecc-envelope'
Key = require './key'

class Document
  constructor: (@_key, @_value, @_ttl=3600, @_timestamp=Date.now) ->
    if !(@ instanceof Document) then return new Document(@_key, @_value, @_ttl, @_timestamp)

    if (@_key instanceof Envelope)
      @_envelope = @_key
      @_key = @_envelope._from.public

    @key = Key(@_key)
    @hash = @key.encoded('hash')

    if @key.private
      @_envelope = Envelope
        send:
          headers:
            ttl: @_ttl
            timestamp: @_timestamp?() ? @_timestamp
          body: @_value
        from: @key.private

  envelope: (encoding) ->
    if encoding
      if encoding == 'object'
        @envelope()?.encode('json')
        .then (envelope) -> JSON.parse(envelope)
      else @envelope()?.encode(encoding)
    else @_envelope

  raw: -> @_raw ?= @envelope().open()

  from: -> @_from ?= @raw().then (raw) -> Key(raw.from)

  data: -> @raw().then (raw) -> raw?.data

  headers: -> @data().then (data) -> data?.headers

  ttl: -> @headers().then (headers) -> headers.ttl

  timestamp: -> @headers().then (headers) -> headers.timestamp

  body: -> @data().then (data) -> data?.body

  serialize:  ->
    @envelope('object')
    .then (envelope) =>
      version: @key.version
      hash: @hash
      envelope: envelope

Document.from = (doc) -> Document(Envelope(decode: doc.envelope, as: 'json'))

Document.Envelope = Envelope
Document.Key = Key

module.exports = Document
