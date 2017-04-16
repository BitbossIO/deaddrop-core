_ = require 'lodash'

chaiAsPromised = require 'chai-as-promised'
chai = require 'chai'

chai.use chaiAsPromised

expect = chai.expect

Envelope = require 'ecc-envelope'
ecc = require 'ecc-tools'

Dropstore = require '../src/dropstore'

describe 'Dropstore', ->
  before () ->
    @data = {hello: 'world'}
    @hash = ecc.encode(ecc.checksum(@data))

    @prv = ecc.privateKey()
    @pub = ecc.encode(ecc.publicKey(@prv, true))

    @seed = new Dropstore
      privkey: @prv
      contact:
        address: 'localhost'
        port: 4000

    @dropstore = new Dropstore
      privkey: ecc.privateKey()
      contact:
        address: 'localhost'
        port: 4001
      seed: @seed.contact()

  # it 'should create a node from config', ->
  #   expect(@dropstore).to.be.an.instanceOf(Dropstore)

  # describe 'put', ->
  #   it 'should take data and return a hash', ->
  #     result = @dropstore.connect()
  #     .then () =>  @dropstore.put({hello: 'world'})
  #     expect(result).to.eventually.eql(@hash)

    # it 'should take a private key and data and return the private key', ->
    #   result = @dropstore.put(@prv, @data)
    #   expect(result).to.eventually.eql(@pub)

  # describe 'get', ->
  #   it 'should take a hash and return data', ->
  #     result = @dropstore.put({hello: 'world'})
  #     .then (hash) => @dropstore.get(hash)
  #     expect(result).to.eventually.eql(@data)
  #
  #   it 'should take a private key and return data', ->
  #     result = @dropstore.put(@prv, @data)
  #     .then (pub) => @dropstore.get(pub)
  #     expect(result).to.eventually.eql(@data)

  describe 'status', ->
    it 'should set an retrieve a status', ->
      result = @dropstore.status(@data)
      .then () => @dropstore.status()
      expect(result).to.eventually.eql(@data)

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
        result = @seed.put(ecc.privateKey(), host: @host)
        .then (key) =>
          @seed.resolve('example.com', {com: {example: key}})
        expect(result).to.eventually.eql(@host)

    describe 'lookup', ->
      it 'should lookup a domain from a zone leaf', ->
        result = @seed.lookup('test.example.com', @zone)
        expect(result).to.eventually.eql('0key')

      it 'should lookup a domain from a zone node', ->
        result = @seed.lookup('example.com', @zone)
        expect(result).to.eventually.eql('1key')

      it 'should lookup a domain from a zone status key', ->
        result = @seed.put(@prv, zone: @zone)
        .then (zone) => @seed.lookup('example.com', zone)
        expect(result).to.eventually.eql('1key')
