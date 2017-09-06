_ = require 'lodash'

chaiAsPromised = require 'chai-as-promised'
chai = require 'chai'

chai.use chaiAsPromised
expect = chai.expect

DeadDrop = require '../src'

describe 'DeadDrop', ->
  before ->
    @key = DeadDrop.Key()
    @data = {hello: 'world'}
    @document = DeadDrop.Document(@key, @data)

    @document.serialize()
      .then (document) =>
        @documents = {}
        @documents[document.hash] = document
        @deaddrop = DeadDrop('memory', documents: @documents)

  describe 'document', ->
    it 'should return the document body for an encoded hash', ->
      document = @deaddrop.document(@key.encoded('hash'))
      expect(document).to.eventually.deep.equal(@data)

    it 'should return the document body for a hash', ->
      document = @deaddrop.document(@key.hash)
      expect(document).to.eventually.deep.equal(@data)

    it 'should return the document body for a public key', ->
      document = @deaddrop.document(@key.public)
      expect(document).to.eventually.deep.equal(@data)

    it 'should return the document body for a private key', ->
      document = @deaddrop.document(@key.private)
      expect(document).to.eventually.deep.equal(@data)

    it 'should store a document body with a private key', ->
      key = DeadDrop.Key()
      document = @deaddrop.document(key.private, @data)
        .then => @deaddrop.document(key.private)
      expect(document).to.eventually.deep.equal(@data)


  describe 'dns', ->
    before () ->
      @host = '127.0.0.1'
      @zone =
        com:
          example:
            '.': '1key'
            test: '0key'

    describe 'resolve', ->
      it 'should resolve a domain from a zone leaf', ->
        result = @deaddrop.document(DeadDrop.Key(), host: @host)
        .then (key) =>
          @deaddrop.resolve('example.com', {com: {example: key}})
        expect(result).to.eventually.eql(@host)

    describe 'lookup', ->
      it 'should lookup a domain from a zone leaf', ->
        result = @deaddrop.lookup('test.example.com', @zone)
        expect(result).to.eventually.eql('0key')

      it 'should lookup a domain from a zone node', ->
        result = @deaddrop.lookup('example.com', @zone)
        expect(result).to.eventually.eql('1key')

      it 'should lookup a domain from a zone status key', ->
        result = @deaddrop.document(@key, zone: @zone)
        .then (zone) => @deaddrop.lookup('example.com', zone)
        expect(result).to.eventually.eql('1key')
