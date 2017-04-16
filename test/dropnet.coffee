_ = require 'lodash'

chaiAsPromised = require 'chai-as-promised'
chai = require 'chai'

chai.use chaiAsPromised

expect = chai.expect

Envelope = require 'ecc-envelope'

Dropnet = require '../src/dropnet'

describe 'Dropnet', ->
  before () ->
    @config0 = require('./fixtures/0.json').dropnet
    @config1 = require('./fixtures/1.json').dropnet

    @dht0 = new Dropnet(@config0)
    @dht1 = new Dropnet(@config1)

    # @dht0.connect(@config0.seed).then () =>
    @dht1.connect(@config1.seed)

  after ->
    @dht0.disconnect()
    @dht1.disconnect()

  it 'should create a dht node from config', ->
    expect(@dht0).to.be.an.instanceOf(Dropnet)
