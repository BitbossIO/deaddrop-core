_ = require 'lodash'

chaiAsPromised = require 'chai-as-promised'
chai = require 'chai'

chai.use chaiAsPromised

expect = chai.expect

DeadDrop = require '../src'

describe 'DeadDrop', ->
  describe 'encrypt', ->
    it 'should encrypt data with a pin', ->
      cipher = DeadDrop.encrypt('hello world', '1234')
      expect(cipher).to.eventually.be.an.object
      expect(cipher).to.eventually.contain.all.keys(['iv','alg','ciphertext'])

  describe 'decrypt', ->
    it 'should decrypt data with a pin', ->
      text = 'hello world'
      pin = '1234'
      result = DeadDrop.encrypt(text, pin)
      .then (cipher) -> DeadDrop.decrypt(cipher, pin)

      expect(result).to.eventually.equal(text)

  describe '@', ->
    before ->
      @config = require('./fixtures/0.json')
      @deaddrop = new DeadDrop @config

    it 'should connect', ->
      result = DeadDrop.wallet()
      .then (wallet) => @config.wallet = wallet
      .then => @deaddrop.connect('0000')
      expect(result).to.eventually.contain.all.keys(['hdkey', 'dropstore', 'dropnet'])

#   it 'should create a network of peers', ->
#     expect(@deaddrop.peers).to.be.an.instanceOf(require '../src/peers')
#
#   it 'should create a datastore', ->
#     expect(@deaddrop.datastore).to.be.an.instanceOf(require '../src/datastore')
#
#   it 'should have a beating heart', (done) ->
#     _.delay =>
#       expect(@deaddrop.heart.age).to.be.greaterThan(0)
#       done()
#     , 100
#
#   it 'should give peers a pulse', ->
#     expect(@deaddrop.peers.pulse).to.exist
#
#   it 'should give datastore a pulse', ->
#     expect(@deaddrop.datastore.pulse).to.exist
