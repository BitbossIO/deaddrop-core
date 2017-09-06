_ = require 'lodash'

chai = require 'chai'
express = require 'express'
request = require 'supertest'

addresses = require './fixtures/addresses.json'
transactions = require './fixtures/transactions.json'
documents = require './fixtures/documents.json'

missing = '16taLdoYLKqkRnVrKYxPZX8PVwaBgSt5Vo'
address = '1YHZyJGaC9FrRJRUMgxQtsudLKo1rEeKJDwLmn'
txid = '16e3509d655c52dd21f18cd1a8f3410b6fb4d6513849181edf233168666c1ca9'

document = documents[address]
transaction = transactions[txid]

API = require '../src'
MemoryNode = require('deaddrop-core').MemoryNode(
  addresses: addresses,
  transactions: transactions,
  documents: documents
)

api = API(express(), MemoryNode)

describe '/deaddrop', ->
  describe '/info', ->
    describe 'GET /info', ->
      it 'should respond with json', ->
        request(api.app).get('/deaddrop/info')
          .expect('Content-Type', /json/)
          .expect(200)

  describe '/addresses', ->
    describe 'GET /addresses/{id}', ->
      it 'should respond with the address', ->
        request(api.app).get('/deaddrop/addresses/' + address)
          .expect('Content-Type', /json/)
          .expect(200, addresses[address])

      it 'should respond with 404 when not found', ->
        request(api.app).get('/deaddrop/addresses/' + missing)
          .expect('Content-Type', /json/)
          .expect(404)

  describe '/transactions', ->
    describe 'GET /transactions/{id}', ->
      it 'should respond with the transaction', ->
        request(api.app).get('/deaddrop/transactions/' + txid)
          .expect('Content-Type', /json/)
          .expect(200, transaction)

      it 'should respond with 404 when not found', ->
        request(api.app).get('/deaddrop/transactions/' + missing)
          .expect('Content-Type', /json/)
          .expect(404)

    describe 'POST /transactions', ->
      it 'should create the transaction', ->
        request(api.app).post('/deaddrop/transactions')
          .send(transaction)
          .expect('Content-Type', /json/)
          .expect(201, {txid: txid})

  describe '/documents', ->
    describe 'GET /documents/{id}', ->
      it 'should respond with the document', ->
        request(api.app).get('/deaddrop/documents/' + address)
          .expect('Content-Type', /json/)
          .expect(200, document)

      it 'should respond with 404 when not found', ->
        request(api.app).get('/deaddrop/documents/' + missing)
          .expect('Content-Type', /json/)
          .expect(404)

    describe 'POST /documents', ->
      it 'should create the document', ->
        request(api.app).post('/deaddrop/documents')
          .send(document)
          .expect('Content-Type', /json/)
          .expect(201, {address: address})
