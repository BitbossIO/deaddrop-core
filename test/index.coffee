# _ = require 'lodash'
#
# chai = require 'chai'
# expect = chai.expect
#
# memdown = require 'memdown'
# levelup = require 'levelup'
#
# DeadDrop = require '../src'
#
# describe 'DeadDrop', ->
#   before ->
#     @options = require('./fixtures/config.json')
#     @options.heartRate = 100
#
#     @deaddrop = new DeadDrop memdown, @options
#
#   after -> @deaddrop.heart.kill()
#
#   it 'should create a node from options', ->
#     expect(@deaddrop.node).to.be.an.instanceOf(require '../src/node')
#
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
