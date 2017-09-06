chaiAsPromised = require 'chai-as-promised'
chai = require 'chai'

chai.use chaiAsPromised

expect = chai.expect

RemoteNode = require '../../src/nodes/remote'

describe 'RemoteNode', ->
  before ->
    @node = RemoteNode()

  describe '_info', ->
    it 'should return information about the node',->
      result = @node._info()
      expect(result.kind).to.equal('remote')

  describe '_getAddress', ->
    it 'should take an encoded address and return address information'

  describe '_getTransactions', ->
    it 'should take a txid and return the transaction'

  describe '_putTransactions', ->
    it 'should take a transaction and return the txid'

  describe '_getDocument', ->
    it 'should take a document hash and return the serialized document'

  describe '_putDocument', ->
    it 'should take a serialized document and return the document hash'
