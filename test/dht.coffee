_ = require 'lodash'

chaiAsPromised = require 'chai-as-promised'
chai = require 'chai'

chai.use chaiAsPromised

expect = chai.expect

Envelope = require 'ecc-envelope'

DHT = require '../src/dht'

describe 'DHT', ->
  before () ->
    @config0 = require('./fixtures/0.json')
    @config1 = require('./fixtures/1.json')

    @dht0 = new DHT(@config0)
    @dht1 = new DHT(@config1)

    # @dht0.connect(@config0.seed).then () =>
    @dht1.connect(@config1.seed)

  after ->
    @dht0.disconnect()
    @dht1.disconnect()

  it 'should create a dht node from config', ->
    expect(@dht0).to.be.an.instanceOf(DHT)

  describe 'publish', ->
