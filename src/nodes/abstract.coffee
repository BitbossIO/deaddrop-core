promise = Promise ? require('es6-promise').Promise

NotOverridden = Error('super class not overridden')

class AbstractNode
  constructor: ->
    if !(@ instanceof AbstractNode) then return new AbstractNode()

  info: -> promise.resolve(@_info())

  getAddress: (address) ->
    promise.resolve(@_getAddress(address)).then (document) ->
      if document? then document
      else promise.reject(Error('not found'))

  getTransaction: (txid) ->
    promise.resolve(@_getTransaction(txid)).then (transaction) ->
      if transaction? then transaction
      else promise.reject(Error('not found'))

  putTransaction: (transaction) -> promise.resolve(@_putTransaction(transaction))

  getDocument: (hash) ->
    promise.resolve(@_getDocument(hash)).then (document) ->
      if document? then document
      else promise.reject(Error('not found'))

  putDocument: (document) ->
    promise.resolve(document)
    .then (doc) => promise.resolve(@_putDocument(doc))

  # Override in subclass
  _info: -> { kind: 'abstract' }

  _getAddress: (address) -> throw NotOverridden

  _getTransaction: (txid) -> throw NotOverridden
  _putTransaction: (transaction) -> throw NotOverridden

  _getDocument: (hash) -> throw NotOverridden
  _putDocument: (document) -> throw NotOverridden

module.exports = AbstractNode
