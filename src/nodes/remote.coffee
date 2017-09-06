promise = Promise ? require('es6-promise').Promise

AbstractNode = require './abstract'

class RemoteNode extends AbstractNode
  constructor: (@store = {}) ->
    if !(@ instanceof RemoteNode) then return new RemoteNode(@store)
    @store.info ?= { kind: 'memory' }
    @store.addresses ?= {}
    @store.transactions ?= {}
    @store.documents ?= {}

  _info: -> kind: 'remote'

  _getAddress: (address) -> @store.addresses[address]

  _getTransaction: (txid) -> @store.transactions[txid]
  _putTransaction: (transaction) -> @store.transactions[transaction.txid] = transaction

  _getDocument: (hash) -> @store.documents[hash]
  _putDocument: (document) -> @store.documents[document.hash] = document

module.exports = RemoteNode

