_ = require 'lodash'

chaiAsPromised = require 'chai-as-promised'
chai = require 'chai'

chai.use chaiAsPromised

expect = chai.expect

Envelope = require 'ecc-envelope'

DHT = require '../src/dht'

describe 'DHT', ->
  before () ->
    @alicePrivateKey = Envelope.et.privateKey()
    @alicePublicKey = Envelope.et.publicKey(@alicePrivateKey)

    @bobPrivateKey = Envelope.et.privateKey()
    @bobPublicKey = Envelope.et.publicKey(@bobPrivateKey)

    @config0 = require('./fixtures/0.json')
    @config1 = require('./fixtures/1.json')

    @dht0 = new DHT(@config0)
    @dht1 = new DHT(@config1)

    @dht1.connect(@config1.seed).then () =>
      Envelope(send: {status: 'online'}, from: @alicePrivateKey).encode('base64').then (registration) =>
        @validRegistration = registration
        Envelope(send: {status: 'unknown'}, from: @alicePrivateKey).encode('base64').then (registration) =>
          @invalidRegistration = registration
          Envelope(send: {type: 'message', body: 'blah'}, to: @alicePublicKey, from: @bobPrivateKey).encode('base64').then (message) =>
            @message = message

  after ->
    @dht0.disconnect()
    @dht1.disconnect()

  it 'should create a dht node from config', ->
    expect(@dht0).to.be.an.instanceOf(DHT)

  describe 'register', ->
    # it 'should save valid registrations', ->
    #   result = @dht0.register(@validRegistration)
    #   expect(result).to.eventually.equal(@validRegistration)
    #
    # it 'should reject registrations with an invalid schema', ->
    #   result = @dht0.register(@invalidRegistration)
    #   expect(result).to.be.rejected

  describe 'status', ->
    # it 'should return the registration', (done) ->
    #   @dht0.register @validRegistration, (message) =>
    #     @dht1.status Envelope.encode(@alicePublicKey)
    #     .then (registration) =>
    #       expect(result).to.eventually.resolve

  describe 'verify', ->
    # it 'should return message on a valid message', ->
    #   result = @dht0.verify(@validRegistration)
    #   expect(result).to.eventually.resolve

  describe 'send', ->
    # it 'should send a message to the registered user', ->
    #   @dht0.register @validRegistration, (message) =>
    #     expect(message).to.eql(@message)
    #   .then => @dht1.send @message

  describe 'subscribe', ->
    it 'should subscribe to a key', ->
      @dht0.subscribe 'hello', (message) =>
        console.log 'Message', message
        expect(message).to.eql('world')
      .then =>
        console.log 'Publishing'
        @dht1.publish 'hello', 'world'


  describe 'publish', ->
