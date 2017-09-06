promise = Promise ? require('es6-promise').Promise

AbstractNode = require './abstract'

class MemoryNode extends AbstractNode
  constructor: (@store = {}) ->
    if !(@ instanceof MemoryNode) then return new MemoryNode(@store)
    @store.info ?= { kind: 'memory' }
    @store.addresses ?= {}
    @store.transactions ?= {}
    @store.documents ?= {}

  _info: -> @store.info

  _getAddress: (address) -> @store.addresses[address]

  _getTransaction: (txid) -> @store.transactions[txid]
  _putTransaction: (transaction) -> @store.transactions[transaction.txid] = transaction

  _getDocument: (hash) -> @store.documents[hash]
  _putDocument: (document) -> @store.documents[document.hash] = document

module.exports = MemoryNode
